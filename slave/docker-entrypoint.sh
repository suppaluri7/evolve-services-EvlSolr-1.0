#!/bin/bash
# docker-entrypoint.sh — EvlSolrSlave  (NHETIO-4422)
# Replaces: install_latest_solr.sh + userdata_solr.tpl (same as master)
# Slave additions: step 1b patches masterUrl; step 4 NR app name uses "solrslave"
# Required: EVOLVE_INSTANCE_ENV  Optional: AWS_REGION, SOLR_JAVA_HEAP, SOLR_MASTER_URL
# IAM: secretsmanager:GetSecretValue on {env}/rds and NEW_RELIC_LICENSE_KEY
set -euo pipefail

SOLR_IN_SH="/etc/default/solr.in.sh"
NR_YML="/opt/solr/current/newrelic/newrelic.yml"
SOLR_DB_CONFIG_JNDI="/opt/solr/current/server/etc/evolve-jetty-jndi.xml"
SOLR_SLAVE_CONF="/opt/solr/current/server/solr/evolve/conf/solrconfig.xml"

AWS_REGION="${AWS_REGION:-us-east-2}"

# 1. DB credentials — replaces: getJsonSecret "${BUILD_ENV}/rds" in install_latest_solr.sh
echo "[entrypoint] Fetching DB credentials from Secrets Manager..."
DB_CREDS=$(aws secretsmanager get-secret-value \
  --secret-id "${EVOLVE_INSTANCE_ENV}/rds" \
  --region "${AWS_REGION}" \
  --query SecretString \
  --output text)

EVOLVE_JDBC_HOST=$(echo "${DB_CREDS}"     | jq -r '.host')
EVOLVE_JDBC_PORT=$(echo "${DB_CREDS}"     | jq -r '.port')
EVOLVE_JDBC_DBNAME=$(echo "${DB_CREDS}"   | jq -r '.dbname')
EVOLVE_JDBC_USERNAME=$(echo "${DB_CREDS}" | jq -r '.username')
EVOLVE_JDBC_PASSWORD=$(echo "${DB_CREDS}" | jq -r '.password')
EVOLVE_JDBC_STRING="jdbc:oracle:thin:@//${EVOLVE_JDBC_HOST}:${EVOLVE_JDBC_PORT}/${EVOLVE_JDBC_DBNAME}"

sed -i "s|EVOLVE_DB_URL|${EVOLVE_JDBC_STRING}|g"        "${SOLR_DB_CONFIG_JNDI}"
sed -i "s|EVOLVE_DB_USERNAME|${EVOLVE_JDBC_USERNAME}|g"  "${SOLR_DB_CONFIG_JNDI}"
sed -i "s|EVOLVE_DB_PASSWORD|${EVOLVE_JDBC_PASSWORD}|g"  "${SOLR_DB_CONFIG_JNDI}"
# Scrub: prevent credentials from residing in shell memory beyond this point
unset DB_CREDS EVOLVE_JDBC_HOST EVOLVE_JDBC_PORT EVOLVE_JDBC_DBNAME \
      EVOLVE_JDBC_USERNAME EVOLVE_JDBC_PASSWORD EVOLVE_JDBC_STRING
echo "[entrypoint] DB credentials injected."

# 1b. masterUrl patch (Slave only) — replaces: hardcoded EC2 DNS in EvlSolrSlave artifact's solrconfig.xml
# Falls back to baked-in EC2 DNS when SOLR_MASTER_URL is unset (migration compatibility)
DEFAULT_MASTER_URL="http://solr-mstr-${EVOLVE_INSTANCE_ENV}.ehsevolve.com/solr/evolve/replication"
EFFECTIVE_MASTER_URL="${SOLR_MASTER_URL:-${DEFAULT_MASTER_URL}}"

# Validate before injecting into XML to prevent XML injection / sed delimiter collision
if [[ ! "${EFFECTIVE_MASTER_URL}" =~ ^https?:// ]]; then
  echo "[entrypoint] ERROR: SOLR_MASTER_URL must start with http:// or https://" >&2
  exit 1
fi
if [[ "${EFFECTIVE_MASTER_URL}" =~ [\'\"<>&|] ]]; then
  echo "[entrypoint] ERROR: SOLR_MASTER_URL contains characters invalid in XML/sed context" >&2
  exit 1
fi

sed -i \
  "s|<str name=\"masterUrl\">.*</str>|<str name=\"masterUrl\">${EFFECTIVE_MASTER_URL}</str>|" \
  "${SOLR_SLAVE_CONF}"
echo "[entrypoint] Replication masterUrl set to: ${EFFECTIVE_MASTER_URL}"

# 2. Java heap — replaces: SOLR_JAVA_HEAP_OVERRIDE in userdata_solr.tpl
JAVA_MEM="${SOLR_JAVA_HEAP:--Xms4G -Xmx4G}"
if grep -q '^SOLR_JAVA_MEM=' "${SOLR_IN_SH}"; then
  sed -i "s|^SOLR_JAVA_MEM=.*|SOLR_JAVA_MEM=\"${JAVA_MEM}\"|" "${SOLR_IN_SH}"
else
  echo "SOLR_JAVA_MEM=\"${JAVA_MEM}\"" >> "${SOLR_IN_SH}"
fi

# 3-5. New Relic — replaces: getJsonSecret "NEW_RELIC_LICENSE_KEY" in install_newrelic.sh
# Guarded: skipped if newrelic.yml absent (NR agent not CI-staged)
if [[ -f "${NR_YML}" ]]; then
  echo "[entrypoint] Fetching New Relic license key..."
  NR_LICENSE_KEY=$(aws secretsmanager get-secret-value \
    --secret-id "NEW_RELIC_LICENSE_KEY" \
    --region "${AWS_REGION}" \
    --query SecretString \
    --output text | jq -r '.LicenseKey')

  sed -i "s/^\(.*license_key:\).*$/\1 '${NR_LICENSE_KEY}'/" "${NR_YML}"
  unset NR_LICENSE_KEY
  echo "[entrypoint] New Relic license key injected."

  # 4. NR app name (Slave) — replaces: NR_INSTANCE_ID in install_newrelic.sh
  # EC2: dev-SOLR-i-0abc1234 → Container: dev-solrslave-<pod-name>
  NR_INSTANCE_ID="${EVOLVE_INSTANCE_ENV}-solrslave-${HOSTNAME}"
  sed -i "s/\(.*\)app_name:\( .*\)$/\1app_name:\2;${NR_INSTANCE_ID}-solr/g" "${NR_YML}"

  # 5. NR JVM agent flag — mirrors: SOLR_OPTS append in install_latest_solr.sh
  if ! grep -q 'newrelic.jar' "${SOLR_IN_SH}"; then
    printf 'SOLR_OPTS="$SOLR_OPTS -javaagent:/opt/solr/current/newrelic/newrelic.jar"\n' \
      >> "${SOLR_IN_SH}"
  fi
else
  echo "[entrypoint] WARNING: ${NR_YML} not found — skipping New Relic setup (NR agent not staged)."
fi

# 6. /etc/hosts — replaces: printf hostname/IP in userdata_solr.tpl (used IMDS; not available in containers)
echo "127.0.0.1  ${HOSTNAME}  localhost" >> /etc/hosts 2>/dev/null || \
  echo "[entrypoint] WARNING: /etc/hosts is read-only — skipping hosts patch."

# 7. Start Solr — replaces: service solr start (init.d)
# shardsWhitelist already set in solr.in.sh at build time (Dockerfile step 8)
echo "[entrypoint] Starting Solr on port 8081 (foreground)..."
exec /opt/solr/current/bin/solr start -f -p 8081 -j --module=plus
