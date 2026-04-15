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
#   --export-creds <env> <region> [aws-profile]
#            Fetches RDS creds from SSM and prints export statements.
#            Pipe through eval to set JDBC_URL/USER/PASS before re-running with --db.
#   --test-rds <env> <region> [aws-profile]
#            Standalone RDS connectivity test — no Docker containers required.
#            Fetches creds from SSM /evolve/{env}/solr, TCP-checks the DB host,
#            then runs a JDBC ping (SELECT 1 FROM DUAL) using ojdbc6.jar from the repo.
#            Requires: java, javac, AWS CLI (+ VPN to reach the RDS endpoint).
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
  ENV="${2:?usage: --export-creds <env> <region> [aws-profile]}"
  REGION="${3:-us-east-2}"
  PROFILE="${4:-}"
  PROFILE_ARGS=()
  [[ -n "$PROFILE" ]] && PROFILE_ARGS=(--profile "$PROFILE")
  PARAM=$(aws ssm get-parameter \
    "${PROFILE_ARGS[@]}" \
    --name "/evolve/${ENV}/solr" --with-decryption --region "${REGION}" \
    --query Parameter.Value --output text)
  JDBC_URL_VAL=$(echo "$PARAM" | python3 -c "import sys,json; print(json.load(sys.stdin)['dbUrl'])")
  USER=$(echo "$PARAM"    | python3 -c "import sys,json; print(json.load(sys.stdin)['dbUser'])")
  PASS_VAL=$(echo "$PARAM" | python3 -c "import sys,json; print(json.load(sys.stdin)['dbPasswd'])")
  printf "export JDBC_URL='%s'\n"   "$JDBC_URL_VAL"
  printf "export JDBC_USER='%s'\n"  "$USER"
  printf "export JDBC_PASS='%s'\n"  "$PASS_VAL"
  exit 0
fi

# ── test-rds helper ──────────────────────────────────────────────────────────
# Standalone RDS connectivity test — no running containers required.
# Usage: ./test-container.sh --test-rds <env> <region> [aws-profile]

if [[ "${1:-}" == "--test-rds" ]]; then
  TR_ENV="${2:?usage: --test-rds <env> <region> [aws-profile]}"
  TR_REGION="${3:-us-east-2}"
  TR_PROFILE="${4:-}"
  TR_PROFILE_ARGS=()
  [[ -n "$TR_PROFILE" ]] && TR_PROFILE_ARGS=(--profile "$TR_PROFILE")

  TR_PASS=0; TR_FAIL=0
  tr_pass() { green "$1"; (( TR_PASS++ )) || true; }
  tr_fail() { red   "$1"; (( TR_FAIL++ )) || true; }

  OJDBC_JAR="vobs/EvolveEcom/Solr/setup/ojdbc6.jar"
  if [[ ! -f "$OJDBC_JAR" ]]; then
    echo "ERROR: $OJDBC_JAR not found — run from the repo root" >&2
    exit 1
  fi

  echo ""
  echo "════════════════════════════════════════════════════"
  echo " RDS connectivity test — env: ${TR_ENV}  region: ${TR_REGION}"
  echo "════════════════════════════════════════════════════"

  # 1. Fetch SSM creds
  echo "[test-rds] Fetching creds from SSM /evolve/${TR_ENV}/solr ..."
  TR_PARAM=$(aws ssm get-parameter \
    "${TR_PROFILE_ARGS[@]}" \
    --name "/evolve/${TR_ENV}/solr" --with-decryption --region "${TR_REGION}" \
    --query Parameter.Value --output text) || {
    tr_fail "SSM fetch failed — check AWS credentials / VPN / profile"
    exit 1
  }
  TR_JDBC_URL=$(echo "$TR_PARAM"  | python3 -c "import sys,json; print(json.load(sys.stdin)['dbUrl'])")
  TR_JDBC_USER=$(echo "$TR_PARAM" | python3 -c "import sys,json; print(json.load(sys.stdin)['dbUser'])")
  TR_JDBC_PASS=$(echo "$TR_PARAM" | python3 -c "import sys,json; print(json.load(sys.stdin)['dbPasswd'])")
  unset TR_PARAM
  tr_pass "SSM creds fetched for /evolve/${TR_ENV}/solr"

  # 2. Parse host and port — handles both @//host:port/service and @host:port:SID formats
  if [[ "$TR_JDBC_URL" == *"@//"* ]]; then
    TR_DB_HOST=$(echo "$TR_JDBC_URL" | sed 's|.*@//||' | cut -d: -f1)
    TR_DB_PORT=$(echo "$TR_JDBC_URL" | sed 's|.*@//[^:]*:||' | cut -d/ -f1)
  else
    TR_DB_HOST=$(echo "$TR_JDBC_URL" | sed 's|.*@||' | cut -d: -f1)
    TR_DB_PORT=$(echo "$TR_JDBC_URL" | sed 's|.*@[^:]*:||' | cut -d: -f1)
  fi
  echo "[test-rds] Target: ${TR_DB_HOST}:${TR_DB_PORT}"

  # 3. TCP reachability
  if timeout 5 bash -c "echo >/dev/tcp/${TR_DB_HOST}/${TR_DB_PORT}" 2>/dev/null; then
    tr_pass "TCP reachable ${TR_DB_HOST}:${TR_DB_PORT}"
  else
    tr_fail "TCP not reachable ${TR_DB_HOST}:${TR_DB_PORT} (VPN connected?)"
    echo ""
    printf " Results: %d passed, %d failed\n" "$TR_PASS" "$TR_FAIL"
    exit 1
  fi

  # 4. JDBC ping via ojdbc6.jar
  # Uses a pre-compiled JdbcPing.class (embedded as base64) so no javac is needed at runtime.
  # Runs via: host `java` if available, otherwise inside the evlsolrmaster Docker image (Java 8 JRE).
  # Compiled from JdbcPing.java using amazoncorretto:8 + ojdbc6.jar (Java 8 target, no-arg JdbcPing).
  JDBCPING_CLASS_B64='yv66vgAAADQAawoAGgAsCQAtAC4HAC8KAAMALAgAMAoAAwAxCAAyCAAzCgA0ADUKAAMANgoANwA4
CgA5ADoLADsAPAgAPQsAPgA/CwBAAEEIAEILAEAAQwoAAwBECwBAAEUHAEYKABUARwsAPgBFCwA7
AEUHAEgHAEkBAAY8aW5pdD4BAAMoKVYBAARDb2RlAQAPTGluZU51bWJlclRhYmxlAQAEbWFpbgEA
FihbTGphdmEvbGFuZy9TdHJpbmc7KVYBAA1TdGFja01hcFRhYmxlBwBKBwBLBwBMBwBGBwBNBwBO
AQAKRXhjZXB0aW9ucwcATwEAClNvdXJjZUZpbGUBAA1KZGJjUGluZy5qYXZhDAAbABwHAFAMAFEA
UgEAF2phdmEvbGFuZy9TdHJpbmdCdWlsZGVyAQAPQ29ubmVjdGluZyB0bzogDABTAFQBAANALioB
AAlAPGhpZGRlbj4HAEsMAFUAVgwAVwBYBwBZDABaAFsHAFwMAF0AXgcATAwAXwBgAQASU0VMRUNU
IDEgRlJPTSBEVUFMBwBNDABhAGIHAE4MAGMAZAEAIU9yYWNsZSBPSyAtIFNFTEVDVCAxIEZST00g
RFVBTCA9IAwAZQBmDABTAGcMAGgAHAEAE2phdmEvbGFuZy9UaHJvd2FibGUMAGkAagEACEpkYmNQ
aW5nAQAQamF2YS9sYW5nL09iamVjdAEAE1tMamF2YS9sYW5nL1N0cmluZzsBABBqYXZhL2xhbmcv
U3RyaW5nAQATamF2YS9zcWwvQ29ubmVjdGlvbgEAEmphdmEvc3FsL1N0YXRlbWVudAEAEmphdmEv
c3FsL1Jlc3VsdFNldAEAE2phdmEvbGFuZy9FeGNlcHRpb24BABBqYXZhL2xhbmcvU3lzdGVtAQAD
b3V0AQAVTGphdmEvaW8vUHJpbnRTdHJlYW07AQAGYXBwZW5kAQAtKExqYXZhL2xhbmcvU3RyaW5n
OylMamF2YS9sYW5nL1N0cmluZ0J1aWxkZXI7AQAKcmVwbGFjZUFsbAEAOChMamF2YS9sYW5nL1N0
cmluZztMamF2YS9sYW5nL1N0cmluZzspTGphdmEvbGFuZy9TdHJpbmc7AQAIdG9TdHJpbmcBABQo
KUxqYXZhL2xhbmcvU3RyaW5nOwEAE2phdmEvaW8vUHJpbnRTdHJlYW0BAAdwcmludGxuAQAVKExq
YXZhL2xhbmcvU3RyaW5nOylWAQAWamF2YS9zcWwvRHJpdmVyTWFuYWdlcgEADWdldENvbm5lY3Rp
b24BAE0oTGphdmEvbGFuZy9TdHJpbmc7TGphdmEvbGFuZy9TdHJpbmc7TGphdmEvbGFuZy9TdHJp
bmc7KUxqYXZhL3NxbC9Db25uZWN0aW9uOwEAD2NyZWF0ZVN0YXRlbWVudAEAFigpTGphdmEvc3Fs
L1N0YXRlbWVudDsBAAxleGVjdXRlUXVlcnkBACgoTGphdmEvbGFuZy9TdHJpbmc7KUxqYXZhL3Nx
bC9SZXN1bHRTZXQ7AQAEbmV4dAEAAygpWgEABmdldEludAEABChJKUkBABwoSSlMamF2YS9sYW5n
L1N0cmluZ0J1aWxkZXI7AQAFY2xvc2UBAA1hZGRTdXBwcmVzc2VkAQAYKExqYXZhL2xhbmcvVGhy
b3dhYmxlOylWACEAGQAaAAAAAAACAAEAGwAcAAEAHQAAAB0AAQABAAAABSq3AAGxAAAAAQAeAAAA
BgABAAAAAgAJAB8AIAACAB0AAAORAAUAEQAAAZcqAzJMKgQyTSoFMk6yAAK7AANZtwAEEgW2AAYr
EgcSCLYACbYABrYACrYACyssLbgADDoEAToFGQS5AA0BADoGAToHGQYSDrkADwIAOggBOgkZCLkA
EAEAV7IAArsAA1m3AAQSEbYABhkIBLkAEgIAtgATtgAKtgALGQjGAF0ZCcYAGRkIuQAUAQCnAE46
ChkJGQq2ABanAEIZCLkAFAEApwA4OgoZCjoJGQq/OgsZCMYAJRkJxgAZGQi5ABQBAKcAFjoMGQkZ
DLYAFqcAChkIuQAUAQAZC78ZBsYAXRkHxgAZGQa5ABcBAKcATjoIGQcZCLYAFqcAQhkGuQAXAQCn
ADg6CBkIOgcZCL86DRkGxgAlGQfGABkZBrkAFwEApwAWOg4ZBxkOtgAWpwAKGQa5ABcBABkNvxkE
xgBdGQXGABkZBLkAGAEApwBOOgYZBRkGtgAWpwBCGQS5ABgBAKcAODoGGQY6BRkGvzoPGQTGACUZ
BcYAGRkEuQAYAQCnABY6EBkFGRC2ABanAAoZBLkAGAEAGQ+/sQAPAIMAigCNABUAUQB5AKMAFQBR
AHkArAAAALgAvwDCABUAowCuAKwAAADiAOkA7AAVAEMA2AECABUAQwDYAQsAAAEXAR4BIQAVAQIB
DQELAAABQQFIAUsAFQA3ATcBYQAVADcBNwFqAAABdgF9AYAAFQFhAWwBagAAAAIAHgAAAE4AEwAA
AAQABAAFAAgABgAMAAcALAAIADcACQBAAAgAQwAKAE4ACABRAAsAWQAMAHkADQCjAAgArAANAQIA
CAELAA0BYQAIAWoADQGWAA4AIQAAARwAGP8AjQAKBwAiBwAjBwAjBwAjBwAkBwAlBwAmBwAlBwAn
BwAlAAEHACULSQcAJUgHACX/ABUADAcAIgcAIwcAIwcAIwcAJAcAJQcAJgcAJQcAJwcAJQAHACUA
AQcAJQsG/wACAAgHACIHACMHACMHACMHACQHACUHACYHACUAAFMHACULSQcAJUgHACX/ABUADgcA
IgcAIwcAIwcAIwcAJAcAJQcAJgcAJQAAAAAABwAlAAEHACULBv8AAgAGBwAiBwAjBwAjBwAjBwAk
BwAlAABTBwAlC0kHACVIBwAl/wAVABAHACIHACMHACMHACMHACQHACUAAAAAAAAAAAAHACUAAQcA
JQsG/wACAAQHACIHACMHACMHACMAAAAoAAAABAABACkAAQAqAAAAAgAr'

  _run_jdbc_check() {
    if grep -q "Oracle OK" /tmp/jdbcping-run.out; then
      tr_pass "JDBC ping to Oracle (SELECT 1 FROM DUAL)"
    elif grep -q "minus one from a read call" /tmp/jdbcping-run.out; then
      tr_fail "JDBC driver version mismatch — ojdbc6.jar speaks Oracle 11g TNS, RDS is 12c+. Tracked in NHETIO-3792 (upgrade to ojdbc8.jar)"
    elif grep -qiE "invalid username|password|ORA-01017" /tmp/jdbcping-run.out; then
      tr_fail "JDBC auth failed — invalid username or password (ORA-01017)"
    else
      tr_fail "JDBC ping failed — see /tmp/jdbcping-run.out"
    fi
  }

  # Decode the pre-compiled class to /tmp (requires only 'java', not 'javac')
  echo "$JDBCPING_CLASS_B64" | base64 --decode > /tmp/JdbcPing.class

  if java -version &>/dev/null 2>&1; then
    # Host JRE available — run directly
    java -cp "/tmp:${OJDBC_JAR}" JdbcPing \
      "$TR_JDBC_URL" "$TR_JDBC_USER" "$TR_JDBC_PASS" 2>&1 | tee /tmp/jdbcping-run.out
    _run_jdbc_check
  else
    # No host JRE — run inside the evlsolrmaster Docker image (Java 8 JRE + ojdbc6.jar baked in)
    TR_IMAGE=$(docker images --format '{{.Repository}}:{{.Tag}}' 2>/dev/null \
                 | grep -E '^evlsolrmaster:|/evlsolrmaster:' | head -1)
    if [[ -z "$TR_IMAGE" ]]; then
      tr_fail "JDBC test skipped — no 'java' on host and no evlsolrmaster image found (build it first)"
    else
      echo "[test-rds] No host JRE found; using Docker image: ${TR_IMAGE}"
      docker run --rm \
        -e JDBC_URL="$TR_JDBC_URL" \
        -e JDBC_USER="$TR_JDBC_USER" \
        -e JDBC_PASS="$TR_JDBC_PASS" \
        -v /tmp/JdbcPing.class:/tmp/JdbcPing.class \
        --entrypoint bash \
        "${TR_IMAGE}" \
        -c 'java -cp /tmp:/opt/solr/current/server/lib/ext/ojdbc6.jar JdbcPing \
              "$JDBC_URL" "$JDBC_USER" "$JDBC_PASS" 2>&1' \
        | tee /tmp/jdbcping-run.out
      _run_jdbc_check
    fi
  fi
  unset TR_JDBC_URL TR_JDBC_USER TR_JDBC_PASS
  rm -f /tmp/JdbcPing.class

  echo ""
  echo "════════════════════════════════════════════════════"
  printf " Results: %d passed, %d failed\n" "$TR_PASS" "$TR_FAIL"
  echo "════════════════════════════════════════════════════"
  echo ""
  [[ "$TR_FAIL" -eq 0 ]]
  exit $?
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
    # Parse host and port from Oracle thin JDBC URL: jdbc:oracle:thin:@//host:port/service
    DB_HOST=$(echo "$JDBC_URL" | sed 's|.*@//||' | cut -d: -f1)
    DB_PORT=$(echo "$JDBC_URL" | sed 's|.*@//[^:]*:||' | cut -d/ -f1)

    # TCP reachability check first (quick fail if no VPN)
    if docker exec evlsolrmaster bash -c \
         "timeout 5 bash -c 'echo >/dev/tcp/${DB_HOST}/${DB_PORT}'" 2>/dev/null; then
      pass "evlsolrmaster: TCP reachable ${DB_HOST}:${DB_PORT}"
    else
      fail "evlsolrmaster: TCP not reachable ${DB_HOST}:${DB_PORT} (VPN connected?)"
    fi

    # JDBC test — install java-devel inside container to get javac (JRE-only image)
    echo "  [db] installing java-devel in container for JDBC compile step…"
    if ! docker exec -u root evlsolrmaster \
         dnf install -y java-devel 2>&1 | grep -qE 'Error|error|Failed'; then
      docker exec evlsolrmaster bash -c "
        printf '%s\n' '${JDBC_TEST_JAVA}' > /tmp/JdbcPing.java
        javac -cp /opt/solr/current/server/lib/ext/ojdbc6.jar /tmp/JdbcPing.java -d /tmp 2>&1 || exit 1
        java -cp /tmp:/opt/solr/current/server/lib/ext/ojdbc6.jar JdbcPing \
          '${JDBC_URL}' '${JDBC_USER}' '${JDBC_PASS}' 2>&1
      " 2>&1 | tee /tmp/jdbc-test.out
      if grep -q "Oracle OK" /tmp/jdbc-test.out; then
        pass "evlsolrmaster: JDBC ping to Oracle (SELECT 1 FROM DUAL)"
      elif grep -q "minus one from a read call" /tmp/jdbc-test.out; then
        fail "evlsolrmaster: JDBC driver version mismatch — ojdbc6.jar speaks Oracle 11g TNS, but RDS is 12c+. Tracked in NHETIO-3792 (upgrade to ojdbc8.jar)"
      else
        fail "evlsolrmaster: JDBC ping failed — check /tmp/jdbc-test.out"
      fi
      # Remove java-devel to leave container state unchanged
      docker exec -u root evlsolrmaster dnf remove -y java-devel 2>/dev/null || true
    else
      fail "evlsolrmaster: could not install java-devel (check container network access)"
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
