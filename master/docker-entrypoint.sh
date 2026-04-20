#!/bin/bash
# docker-entrypoint.sh — EvlSolrMaster  (NHETIO-4421)
# Replaces: install_latest_solr.sh (DB creds, NR) + userdata_solr.tpl (heap, hostname)
# Required: EVOLVE_INSTANCE_ENV  Optional: AWS_REGION, SOLR_JAVA_HEAP
# IAM: ssm:GetParameter on /evolve/{env}/solr and secretsmanager:GetSecretValue on NEW_RELIC_LICENSE_KEY
set -euo pipefail

SOLR_IN_SH="/opt/solr/current/bin/solr.in.sh"
NR_YML="/opt/solr/current/newrelic/newrelic.yml"
SOLR_DB_CONFIG_JNDI="/opt/solr/current/server/etc/evolve-jetty-jndi.xml"

AWS_REGION="${AWS_REGION:-us-east-2}"

# 1. DB credentials — SSM path: /evolve/{env}/solr (SecureString)
# Fields: dbUrl (full JDBC URL), dbUser, dbPasswd
echo "[entrypoint] Fetching DB credentials from SSM Parameter Store..."
DB_CREDS=$(aws ssm get-parameter \
  --name "/evolve/${EVOLVE_INSTANCE_ENV}/solr" \
  --with-decryption \
  --region "${AWS_REGION}" \
  --query Parameter.Value \
  --output text)

EVOLVE_JDBC_STRING=$(echo "${DB_CREDS}"   | jq -r '.dbUrl')
EVOLVE_JDBC_USERNAME=$(echo "${DB_CREDS}" | jq -r '.dbUser')
EVOLVE_JDBC_PASSWORD=$(echo "${DB_CREDS}" | jq -r '.dbPasswd')

sed -i "s|EVOLVE_DB_URL|${EVOLVE_JDBC_STRING}|g"        "${SOLR_DB_CONFIG_JNDI}"
sed -i "s|EVOLVE_DB_USERNAME|${EVOLVE_JDBC_USERNAME}|g"  "${SOLR_DB_CONFIG_JNDI}"
sed -i "s|EVOLVE_DB_PASSWORD|${EVOLVE_JDBC_PASSWORD}|g"  "${SOLR_DB_CONFIG_JNDI}"
# Scrub: prevent credentials from residing in shell memory beyond this point
unset DB_CREDS EVOLVE_JDBC_STRING EVOLVE_JDBC_USERNAME EVOLVE_JDBC_PASSWORD
echo "[entrypoint] DB credentials injected."

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

  # 4. NR app name — replaces: NR_INSTANCE_ID in install_newrelic.sh
  # EC2: dev-UTILS-i-0abc1234 → Container: dev-solrmaster-<pod-name>
  NR_INSTANCE_ID="${EVOLVE_INSTANCE_ENV}-solrmaster-${HOSTNAME}"
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
  echo "[entrypoint] WARNING: /etc/hosts is read-only — skipping hosts patch (add --add-host=${HOSTNAME}:127.0.0.1 to docker run if UnknownHostException occurs)."

# 7. Start Solr — replaces: service solr start (init.d)
# -j --module=plus enables Jetty/JNDI (replaces NHETIO-2225 awk hack on /etc/init.d/solr)
echo "[entrypoint] Starting Solr on port 8081 (foreground)..."
exec /opt/solr/current/bin/solr start -f -p 8081 -j --module=plus
