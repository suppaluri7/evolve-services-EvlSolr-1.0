# Local Test Run — EvlSolrMaster & EvlSolrSlave

Documents every step required to build and run both images locally,
including all issues encountered and fixes applied. Run these steps
in order; everything from the `Prerequisites` section onward is
repeatable from a clean state.

---

## Prerequisites

| Tool | Minimum version | Check |
|------|----------------|-------|
| Docker Desktop | 4.x (daemon socket active) | `docker ps` returns a table header |
| Python 3 | 3.8+ | `python3 --version` |
| curl | any | `curl --version` |

---

## One-time setup — host assets

These files must exist on the Mac before any `docker build`. They are
not committed to the repo.

```bash
# 1. Stage CI assets into the build context root
cd /Users/uppaluris/tio_hcm-evolve-terraformcontrol/evolve-services-EvlSolr-1.0-master
cp ../tio-utils.sh .
# Note: newrelic-java.zip is NO LONGER staged in the build context root.
# It is now fetched from Artifactory at build time via BuildKit secrets.
# For local builds, serve it from the stub HTTP server (see step 2 below).

# 2. Pre-download Solr 8.11.2 and stub artifacts to /tmp/stubs (served via HTTP)
#    Also copy newrelic-java.zip to /tmp/stubs for local builds.
mkdir -p /tmp/stubs
curl -k -fSL https://archive.apache.org/dist/lucene/solr/8.11.2/solr-8.11.2.tgz \
     -o /tmp/stubs/solr-8.11.2.tgz
# Verify the tarball is intact
tar -tzf /tmp/stubs/solr-8.11.2.tgz | head -3

# Copy newrelic-java.zip to stubs directory (served as NR_ARTIFACT_URL locally)
cp ../packer/assets/3rdparty/newrelic/newrelic-java.zip /tmp/stubs/

# 3. Build stub artifacts that contain a real solrconfig.xml
#    (Real CI uses an Artifactory artifact — stub simulates the conf/ skeleton)
mkdir -p /tmp/stubs_conf
tar -xzf /tmp/stubs/solr-8.11.2.tgz \
    --strip-components=5 \
    -C /tmp/stubs_conf \
    "solr-8.11.2/server/solr/configsets/_default/conf/"
# Verify solrconfig.xml is present
ls /tmp/stubs_conf/conf/
tar czf /tmp/stubs/EvlSolrMaster-dev.tgz -C /tmp/stubs_conf conf
tar czf /tmp/stubs/EvlSolrSlave-dev.tgz  -C /tmp/stubs_conf conf

# 4. Create stub BuildKit secret files (no-auth local HTTP server needs no real creds)
mkdir -p /tmp/secrets
echo "local" > /tmp/secrets/artifactory_user
echo "local" > /tmp/secrets/artifactory_token
chmod 600 /tmp/secrets/artifactory_user /tmp/secrets/artifactory_token
```

---

## Start the local stub HTTP server

Docker build steps fetch Solr and the artifact over HTTP from
`host.docker.internal:8000` (resolves to the Mac inside a container).

```bash
# Run in a separate terminal — keep it alive during the entire build+run session
python3 -m http.server 8000 --directory /tmp/stubs

# Verify from another terminal
curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/solr-8.11.2.tgz
# → 200
```

---

## docker build

### Build args reference

| ARG | CI/prod default | Local override | Purpose |
|-----|----------------|----------------|---------|
| `SOLR_VERSION` | `8.11.2` | (leave default) | Solr release |
| `SOLR_DOWNLOAD_URL` | `https://archive.apache.org/dist/…` | `http://host.docker.internal:8000/solr-8.11.2.tgz` | Avoids SSL proxy failure inside container |
| `DNF_SSLVERIFY` | `True` | `False` | Allows `dnf` to fetch AL2023 repo metadata through corporate proxy |
| `CURL_OPTS` | _(empty)_ | `-k` | Bypasses cert verification for Artifactory/Apache HTTPS (not needed when using local HTTP server) |
| `EVLSOLRMASTER_ARTIFACT_URL` | Artifactory URL (set by CI) | `http://host.docker.internal:8000/EvlSolrMaster-dev.tgz` | |
| `EVLSOLRSLAVE_ARTIFACT_URL` | Artifactory URL (set by CI) | `http://host.docker.internal:8000/EvlSolrSlave-dev.tgz` | || `NR_ARTIFACT_URL` | Artifactory URL (set by CI) | `http://host.docker.internal:8000/newrelic-java.zip` | New Relic agent zip; fetched via BuildKit secret in CI, stub HTTP server locally |
### Build commands (from build context root)

```bash
cd /Users/uppaluris/tio_hcm-evolve-terraformcontrol/evolve-services-EvlSolr-1.0-master

# Master
docker build --no-cache -f master/Dockerfile \
  --secret id=artifactory_user,src=/tmp/secrets/artifactory_user \
  --secret id=artifactory_token,src=/tmp/secrets/artifactory_token \
  --build-arg DNF_SSLVERIFY=False \
  --build-arg SOLR_DOWNLOAD_URL="http://host.docker.internal:8000/solr-8.11.2.tgz" \
  --build-arg EVLSOLRMASTER_ARTIFACT_URL="http://host.docker.internal:8000/EvlSolrMaster-dev.tgz" \
  --build-arg NR_ARTIFACT_URL="http://host.docker.internal:8000/newrelic-java.zip" \
  -t evlsolrmaster:local .

# Slave
docker build --no-cache -f slave/Dockerfile \
  --secret id=artifactory_user,src=/tmp/secrets/artifactory_user \
  --secret id=artifactory_token,src=/tmp/secrets/artifactory_token \
  --build-arg DNF_SSLVERIFY=False \
  --build-arg SOLR_DOWNLOAD_URL="http://host.docker.internal:8000/solr-8.11.2.tgz" \
  --build-arg EVLSOLRSLAVE_ARTIFACT_URL="http://host.docker.internal:8000/EvlSolrSlave-dev.tgz" \
  --build-arg NR_ARTIFACT_URL="http://host.docker.internal:8000/newrelic-java.zip" \
  -t evlsolrslave:local .
```

Expected: both builds finish with all steps `DONE`, no `ERROR` lines.
Image size ≈ 890 MB each.

> **Subsequent rebuilds** (after a code change): drop `--no-cache` to
> benefit from Docker layer caching. Only add it when the stub artifact
> content has changed, because Docker will not re-fetch a URL whose
> content changes without `--no-cache`.

---

## Stub entrypoint (skips AWS calls)

The real `docker-entrypoint.sh` calls AWS SSM and Secrets Manager.
For local testing mount a stub over it that hard-codes credentials and
skips New Relic / `/etc/hosts` manipulation.

```bash
cat > /tmp/entrypoint-stub.sh << 'STUB'
#!/bin/bash
set -euo pipefail
SOLR_IN_SH="/etc/default/solr.in.sh"
NR_YML="/opt/solr/current/newrelic/newrelic/newrelic.yml"
SOLR_DB_CONFIG_JNDI="/opt/solr/current/server/etc/evolve-jetty-jndi.xml"

# Stub DB credentials (no AWS calls)
sed -i "s|EVOLVE_DB_URL|jdbc:oracle:thin:@//localhost:1521/EVOLVE|g" "${SOLR_DB_CONFIG_JNDI}"
sed -i "s|EVOLVE_DB_USERNAME|testuser|g"                              "${SOLR_DB_CONFIG_JNDI}"
sed -i "s|EVOLVE_DB_PASSWORD|testpass|g"                              "${SOLR_DB_CONFIG_JNDI}"

# Heap (small for local dev)
echo 'SOLR_JAVA_MEM="-Xms512m -Xmx512m"' >> "${SOLR_IN_SH}"

# Dummy NR license so newrelic.yml parses without error
if [[ -f "${NR_YML}" ]]; then
  sed -i "s/^\(.*license_key:\).*$/\1 '0000000000000000000000000000000000000000'/" "${NR_YML}"
fi

# --hostname flag in docker run ensures hostname resolves in /etc/hosts
exec /opt/solr/current/bin/solr start -f -p 8081 -j --module=plus
STUB
chmod +x /tmp/entrypoint-stub.sh
```

---

## docker run

```bash
# Remove any stale containers first
docker rm -f evlsolrmaster evlsolrslave 2>/dev/null

# Master — host port 8081
docker run -d \
  --name evlsolrmaster \
  --hostname evlsolrmaster \
  -p 8081:8081 \
  -v /tmp/entrypoint-stub.sh:/opt/tio/docker-entrypoint.sh \
  evlsolrmaster:local

# Slave — host port 8082 (container still uses 8081 internally)
docker run -d \
  --name evlsolrslave \
  --hostname evlsolrslave \
  -p 8082:8081 \
  -v /tmp/entrypoint-stub.sh:/opt/tio/docker-entrypoint.sh \
  evlsolrslave:local

# Solr JVM + Jetty takes ~30–45 s to fully start
sleep 45
```

---

## Ping tests

Maps the four stage URLs to their localhost equivalents.

| Stage URL | Localhost URL |
|-----------|--------------|
| `https://solr-mstr-stage2.ehsevolve.com/solr/evolve/admin/ping` | `http://localhost:8081/solr/evolve/admin/ping` |
| `https://solr-mstr.stage.evolve.health.elsevier.com/solr/evolve/admin/ping` | `http://localhost:8081/solr/evolve/admin/ping` |
| `https://solr-slv-stage2.ehsevolve.com/solr/evolve/admin/ping` | `http://localhost:8082/solr/evolve/admin/ping` |
| `https://solr-slv.stage.evolve.health.elsevier.com/solr/evolve/admin/ping` | `http://localhost:8082/solr/evolve/admin/ping` |

```bash
curl -s http://localhost:8081/solr/evolve/admin/ping | python3 -c \
  "import sys,json; d=json.load(sys.stdin); print('MASTER:', d['status'])"
# → MASTER: OK

curl -s http://localhost:8082/solr/evolve/admin/ping | python3 -c \
  "import sys,json; d=json.load(sys.stdin); print('SLAVE: ', d['status'])"
# → SLAVE:  OK
```

Expected response body:

```json
{
  "responseHeader": { "status": 0, "QTime": 34, ... },
  "status": "OK"
}
```

---

## Issues encountered and fixes applied

### 1. `dnf install` fails — SSL cert not trusted (exit 60)

**Symptom:** `Curl error (60): SSL peer certificate … unable to get local issuer
certificate` for `cdn.amazonlinux.com` mirror list.

**Root cause:** The corporate HTTPS-inspection proxy presents its own cert;
the AL2023 container has no corporate CA bundle.

**Fix:** Added `ARG DNF_SSLVERIFY=True` and a `RUN echo "sslverify=…"` line
before the `dnf install` step. Pass `--build-arg DNF_SSLVERIFY=False` locally.

---

### 2. `curl: (60)` for `archive.apache.org` Solr download (exit 60 / bad tarball)

**Symptom:** The `tar` extraction fails with `gzip: Cannot exec` or produces a
corrupt archive because the proxy stripped/re-encrypted the stream.

**Fix:** Added `ARG SOLR_DOWNLOAD_URL` so the URL can be overridden to a plain
`http://host.docker.internal:8000/…` URL. Solr 8.11.2 is pre-downloaded on the
Mac host and served from the local stub HTTP server. This avoids all SSL inside
the container for the Solr tgz.

---

### 3. `curl-minimal` conflicts with `curl` package (exit 1)

**Symptom:** `dnf install curl` fails with `package curl-minimal … conflicts
with curl`.

**Root cause:** `amazoncorretto:8-al2023` ships `curl-minimal` which conflicts
with the full `curl` package.

**Fix:** Removed `curl` from the `dnf install` list. `curl-minimal` (already
present) is sufficient for all `curl` calls in the Dockerfile and entrypoint.
Added `--allowerasing` flag as a general conflict resolver.

---

### 4. `useradd: command not found` (exit 127)

**Symptom:** `RUN useradd -r …` fails immediately.

**Root cause:** `shadow-utils` (which ships `useradd`/`groupadd`) is not
included in the Corretto base image.

**Fix:** Added `shadow-utils` to `dnf install`.

---

### 5. `tar: command not found` (exit 127)

**Symptom:** `tar -xzf solr-…tgz` fails — `tar` is not in the base image.

**Fix:** Added `tar` to `dnf install`.

---

### 6. `gzip: Cannot exec: No such file or directory` (tar exit 2)

**Symptom:** `tar` is present but cannot decompress the `.tgz` because `gzip`
is not in the base image.

**Fix:** Added `gzip` to `dnf install`.

---

### 7. `/bin/solr: ps: command not found`

**Symptom:** Solr's `bin/solr` startup script immediately exits with `This
script relies on a version of ps that supports the -p flag`.

**Root cause:** `ps` is not in the Corretto base image.

**Fix:** Added `procps-ng` to `dnf install`.

---

### 8. `/etc/default/solr.in.sh: Permission denied` (exit 1)

**Symptom:** The entrypoint script fails writing `SOLR_JAVA_MEM` to
`/etc/default/solr.in.sh` because the `evolve` user (which the container
runs as) does not own that file.

**Root cause:** The `chown -R evolve:evolve` in the Dockerfile's final step
only covered `/opt/solr/`, `/opt/tio/`, and `/var/solr/`.

**Fix:** Added `/etc/default/solr.in.sh` to the `chown` command:
```dockerfile
RUN chmod +x /opt/tio/docker-entrypoint.sh \
    && chown -R evolve:evolve /opt/solr/ /opt/tio/ /var/solr/ /etc/default/solr.in.sh
```

---

### 9. `Unable to create core [evolve]` — missing `solrconfig.xml`

**Symptom:** Solr starts but immediately logs
`Can't find resource 'solrconfig.xml' in classpath or '.../evolve'`.

**Root cause:** The stub artifact tarball was created empty (`conf/` with no
files). Without a `solrconfig.xml`, Solr cannot load the core.

**Fix:** Rebuilt the stub tarballs using Solr's built-in `_default` configset
extracted from the downloaded `solr-8.11.2.tgz`:

```bash
tar -xzf /tmp/stubs/solr-8.11.2.tgz \
    --strip-components=5 \
    -C /tmp/stubs_conf \
    "solr-8.11.2/server/solr/configsets/_default/conf/"
tar czf /tmp/stubs/EvlSolrMaster-dev.tgz -C /tmp/stubs_conf conf
tar czf /tmp/stubs/EvlSolrSlave-dev.tgz  -C /tmp/stubs_conf conf
```

Then force a full Docker rebuild with `--no-cache` so Docker re-fetches the
new stub artifact (Docker caches by URL, not by content).

---

### 10. `/etc/hosts` write fails in stub entrypoint

**Symptom:** Stub entrypoint tried to call `hostname -I` (not available) and
append to `/etc/hosts` (not writable by `evolve`).

**Fix:** Removed the `/etc/hosts` patch from the stub. Docker's `--hostname`
flag automatically adds the hostname entry to `/etc/hosts` for the container.

---

## Summary of Dockerfile packages added vs. base image

The `amazoncorretto:8-al2023` image is a minimal JRE image. These packages
must be explicitly installed:

| Package | Reason |
|---------|--------|
| `tar` | extract `.tgz` archives |
| `gzip` | decompress `.gz` streams (called by `tar -z`) |
| `unzip` | unpack `evolve-solr-config.zip` and `newrelic-java.zip` |
| `jq` | parse SSM / Secrets Manager JSON in entrypoint |
| `awscli` | SSM Parameter Store + Secrets Manager calls in entrypoint |
| `shadow-utils` | provides `useradd` / `groupadd` |
| `procps-ng` | provides `ps`, required by Solr's `bin/solr` startup script |

`curl` is **not** added — `curl-minimal` is pre-installed in the base image
and is sufficient. Adding `curl` causes a package conflict.
