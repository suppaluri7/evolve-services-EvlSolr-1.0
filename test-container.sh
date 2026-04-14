#!/usr/bin/env bash
# test-container.sh — EvlSolrMaster / EvlSolrSlave smoke tests
#
# USAGE
#   ./test-container.sh [--db]
#
# FLAGS
#   (none)   Tier 1 only: Solr health, core, schema, query, replication
#   --db     Also run Tier 2: direct JDBC ping to Oracle using the ojdbc jar
#            baked into the container.  Requires environment variables:
#              JDBC_URL  e.g. jdbc:oracle:thin:@//db-host:1521/EVOLVE
#              JDBC_USER Oracle username
#              JDBC_PASS Oracle password
#            With VPN + AWS access you can populate these automatically:
#              eval "$(./test-container.sh --export-creds dev us-east-2)"
#   --export-creds <env> <region>
#            Fetches RDS creds from Secrets Manager and prints export statements.
#            Pipe through eval to set JDBC_URL/USER/PASS before re-running with --db.
#
# CONTAINERS
#   The script tests whichever containers are running.  Names must be
#   evlsolrmaster (host port 8081) and evlsolrslave (host port 8082).
#
# EXAMPLES
#   # Tier 1 only (stub entrypoint, no AWS needed):
#   ./test-container.sh
#
#   # Tier 2 with manually set creds:
#   JDBC_URL="jdbc:oracle:thin:@//mydb.example.com:1521/EVOLVE" \
#   JDBC_USER=myuser JDBC_PASS=mysecret ./test-container.sh --db
#
#   # Tier 2 with automatic creds from SecretsManager (requires AWS CLI + VPN):
#   eval "$(./test-container.sh --export-creds dev us-east-2)"
#   ./test-container.sh --db

set -euo pipefail

MASTER_PORT=8081
SLAVE_PORT=8082
PASS=0
FAIL=0

# ── helpers ──────────────────────────────────────────────────────────────────

green() { printf '\033[0;32m✔ %s\033[0m\n' "$1"; }
red()   { printf '\033[0;31m✘ %s\033[0m\n' "$1"; }

pass() { green "$1"; (( PASS++ )) || true; }
fail() { red   "$1"; (( FAIL++ )) || true; }

assert_http() {
  local label="$1" url="$2" expected="${3:-200}"
  local code
  code=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
  if [[ "$code" == "$expected" ]]; then
    pass "$label (HTTP $code)"
  else
    fail "$label (expected HTTP $expected, got $code)"
  fi
}

assert_json_field() {
  local label="$1" url="$2" jq_expr="$3" expected="$4"
  local actual
  actual=$(curl -s "$url" 2>/dev/null | python3 -c "
import sys,json
try:
    d=json.load(sys.stdin)
    print($jq_expr)
except Exception as e:
    print('ERROR:'+str(e))
" 2>/dev/null)
  if [[ "$actual" == "$expected" ]]; then
    pass "$label ($actual)"
  else
    fail "$label (expected '$expected', got '$actual')"
  fi
}

container_running() {
  docker inspect --format '{{.State.Running}}' "$1" 2>/dev/null | grep -q true
}

# ── export-creds helper ───────────────────────────────────────────────────────

if [[ "${1:-}" == "--export-creds" ]]; then
  ENV="${2:?usage: --export-creds <env> <region>}"
  REGION="${3:-us-east-2}"
  SECRET=$(aws secretsmanager get-secret-value \
    --secret-id "${ENV}/rds" --region "${REGION}" \
    --query SecretString --output text)
  HOST=$(echo "$SECRET"   | python3 -c "import sys,json; print(json.load(sys.stdin)['host'])")
  PORT=$(echo "$SECRET"   | python3 -c "import sys,json; print(json.load(sys.stdin)['port'])")
  DBNAME=$(echo "$SECRET" | python3 -c "import sys,json; print(json.load(sys.stdin)['dbname'])")
  USER=$(echo "$SECRET"   | python3 -c "import sys,json; print(json.load(sys.stdin)['username'])")
  PASS_VAL=$(echo "$SECRET" | python3 -c "import sys,json; print(json.load(sys.stdin)['password'])")
  printf "export JDBC_URL='jdbc:oracle:thin:@//%s:%s/%s'\n" "$HOST" "$PORT" "$DBNAME"
  printf "export JDBC_USER='%s'\n"  "$USER"
  printf "export JDBC_PASS='%s'\n"  "$PASS_VAL"
  exit 0
fi

RUN_DB=false
[[ "${1:-}" == "--db" ]] && RUN_DB=true

# ── Tier 1 — Solr health ─────────────────────────────────────────────────────

echo ""
echo "════════════════════════════════════════════════════"
echo " Tier 1 — Solr health (local, no AWS required)"
echo "════════════════════════════════════════════════════"

for NAME in evlsolrmaster evlsolrslave; do
  PORT=$([ "$NAME" = "evlsolrmaster" ] && echo "$MASTER_PORT" || echo "$SLAVE_PORT")
  BASE="http://localhost:${PORT}"

  if ! container_running "$NAME"; then
    fail "$NAME: container not running"
    continue
  fi
  pass "$NAME: container running"

  # 1. Ping
  assert_json_field \
    "$NAME: /admin/ping status=OK" \
    "${BASE}/solr/evolve/admin/ping?wt=json" \
    "d['status']" "OK"

  # 2. Core registered + index intact
  assert_json_field \
    "$NAME: evolve core present" \
    "${BASE}/solr/admin/cores?action=STATUS&wt=json" \
    "'evolve' in d['status']" "True"

  assert_json_field \
    "$NAME: core index current=true" \
    "${BASE}/solr/admin/cores?action=STATUS&wt=json" \
    "str(d['status']['evolve']['index']['current'])" "True"

  # 3. Schema has fields
  assert_json_field \
    "$NAME: schema has ≥ 1 field" \
    "${BASE}/solr/evolve/schema?wt=json" \
    "len(d['schema']['fields']) > 0" "True"

  # 4. Basic select returns HTTP 200 and valid JSON
  assert_json_field \
    "$NAME: /select?q=*:* HTTP 200 + status=0" \
    "${BASE}/solr/evolve/select?q=%2A%3A%2A&rows=0&wt=json" \
    "d['responseHeader']['status']" "0"

  # 5. Replication handler accessible
  assert_http "$NAME: /replication endpoint" \
    "${BASE}/solr/evolve/replication?command=details&wt=json"

  # 6. JNDI config file patched (URL placeholder replaced)
  JNDI_RAW=$(docker exec "$NAME" cat /opt/solr/current/server/etc/evolve-jetty-jndi.xml 2>/dev/null)
  if echo "$JNDI_RAW" | grep -q "EVOLVE_DB_URL"; then
    fail "$NAME: JNDI config still contains placeholder EVOLVE_DB_URL"
  else
    pass "$NAME: JNDI config patched (placeholders replaced)"
  fi

  # 7. New Relic jar present
  if docker exec "$NAME" test -f /opt/solr/current/newrelic/newrelic.jar 2>/dev/null; then
    pass "$NAME: newrelic.jar present"
  else
    fail "$NAME: newrelic.jar missing"
  fi

  # 8. Running as evolve (non-root)
  WHOAMI=$(docker exec "$NAME" whoami 2>/dev/null)
  if [[ "$WHOAMI" == "evolve" ]]; then
    pass "$NAME: running as non-root user 'evolve'"
  else
    fail "$NAME: running as unexpected user '$WHOAMI'"
  fi

  echo ""
done

# ── Tier 2 — DB connectivity ──────────────────────────────────────────────────

if $RUN_DB; then
  echo "════════════════════════════════════════════════════"
  echo " Tier 2 — DB connection (requires Oracle + creds)"
  echo "════════════════════════════════════════════════════"

  if [[ -z "${JDBC_URL:-}" || -z "${JDBC_USER:-}" || -z "${JDBC_PASS:-}" ]]; then
    fail "DB test: JDBC_URL / JDBC_USER / JDBC_PASS not set"
    echo ""
    echo "  Set them manually, or auto-fetch from Secrets Manager:"
    echo "    eval \"\$(./test-container.sh --export-creds dev us-east-2)\""
    echo "    ./test-container.sh --db"
  else
    # Inject a tiny Java class into the master container, compile it with the
    # ojdbc jar already on the image, and run a SELECT 1 FROM DUAL ping.
    JDBC_TEST_JAVA='
import java.sql.*;
public class JdbcPing {
    public static void main(String[] args) throws Exception {
        String url  = args[0];
        String user = args[1];
        String pass = args[2];
        System.out.println("Connecting to: " + url.replaceAll("@.*", "@<hidden>"));
        try (Connection c = DriverManager.getConnection(url, user, pass);
             Statement  s = c.createStatement();
             ResultSet  r = s.executeQuery("SELECT 1 FROM DUAL")) {
            r.next();
            System.out.println("Oracle OK — SELECT 1 FROM DUAL = " + r.getInt(1));
        }
    }
}
'
    if docker exec evlsolrmaster bash -c "
      echo '${JDBC_TEST_JAVA}' > /tmp/JdbcPing.java
      javac -cp /opt/solr/current/server/lib/ext/ojdbc6.jar /tmp/JdbcPing.java -d /tmp 2>&1 || exit 1
      java -cp /tmp:/opt/solr/current/server/lib/ext/ojdbc6.jar JdbcPing \
        '${JDBC_URL}' '${JDBC_USER}' '${JDBC_PASS}' 2>&1
    " 2>&1 | tee /tmp/jdbc-test.out | grep -q "Oracle OK"; then
      pass "evlsolrmaster: JDBC ping to Oracle (SELECT 1 FROM DUAL)"
    else
      fail "evlsolrmaster: JDBC ping failed — $(tail -3 /tmp/jdbc-test.out)"
    fi

    # Also test TCP reachability of the DB port (faster first-fail indicator)
    DB_HOST=$(echo "$JDBC_URL" | sed 's|.*@//||' | cut -d: -f1)
    DB_PORT=$(echo "$JDBC_URL" | sed 's|.*://[^:]*:||' | cut -d/ -f1)
    if docker exec evlsolrmaster bash -c \
         "timeout 5 bash -c 'echo >/dev/tcp/${DB_HOST}/${DB_PORT}'" 2>/dev/null; then
      pass "evlsolrmaster: TCP reachable ${DB_HOST}:${DB_PORT}"
    else
      fail "evlsolrmaster: TCP not reachable ${DB_HOST}:${DB_PORT} (VPN connected?)"
    fi
  fi
  echo ""
fi

# ── Summary ───────────────────────────────────────────────────────────────────

echo "════════════════════════════════════════════════════"
printf " Results: %d passed, %d failed\n" "$PASS" "$FAIL"
echo "════════════════════════════════════════════════════"
echo ""

if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
