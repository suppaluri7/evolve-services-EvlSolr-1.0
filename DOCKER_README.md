# EvlSolr Containerization — Docker README

**Tickets:** NHETIO-4421 (EvlSolrMaster) · NHETIO-4422 (EvlSolrSlave)
**Branch:** `NHETIO-2535_Modernization`

---

## What This Is

This directory contains Dockerfiles and entrypoint scripts to containerize
Solr 8.11.2 running in the classic HTTP replication topology:

| Role | EC2 Equivalent | Container Image |
|---|---|---|
| Leader (Master) | UTILS EC2 (`:8081` alongside Jetty `:8080`) | `evlsolrmaster:{tag}` |
| Follower (Slave) | SOLR EC2 (`:8081` dedicated) | `evlsolrslave:{tag}` |

Both images are built from the same module root as the build context:

```
evolve-services-EvlSolr-1.0-master/
├── master/
│   ├── Dockerfile               ← EvlSolrMaster image
│   └── docker-entrypoint.sh     ← Master runtime init
├── slave/
│   ├── Dockerfile               ← EvlSolrSlave image (derived from master)
│   └── docker-entrypoint.sh     ← Slave runtime init (4 differences from master)
└── vobs/EvolveEcom/Solr/
    ├── setup/evolve-solr-config.zip   ← COPY'd at build time (in repo)
    ├── master/build/build.xml          ← Ant build for EvlSolrMaster artifact
    └── slave/build/build.xml           ← Ant build for EvlSolrSlave artifact
```

---

## Architecture: EC2 → Container

### Key architectural difference

On EC2, **EvlSolrMaster co-resides on UTILS instances** (same box as Jetty/webapps).
DNS `solr-mstr-{env}.ehsevolve.com` points to the UTILS ALB.
The dedicated SOLR ASG runs **EvlSolrSlave only**.

In containers, each role gets its own dedicated StatefulSet.
The co-residency constraint is eliminated.

### What each EC2 provisioning phase maps to

| EC2 Phase | Source | Container Equivalent |
|---|---|---|
| Packer AMI bake | `packer/solr.pkr.hcl` | Dockerfile build stages |
| Boot installer | `packer/assets/solr/opt/tio/install_latest_solr.sh` | Dockerfile (static) + entrypoint (credentials) |
| Launch userdata | `evolve-services-modern/*/userdata_utils.tpl` | K8s env vars + entrypoint |

---

## Base Image

```dockerfile
FROM docker-remote.health.artifactory.tio.systems/amazoncorretto:8-al2023
```

- **Amazon Corretto 8** on **Amazon Linux 2023** — same OS and JVM as the
  `tio_base_amz_linux_2023-*` Packer AMI.
- Pulled through the internal Artifactory proxy (same pattern as
  `hcm-evolve-jenkinsmanager-main/Dockerfile` and
  `hcm-evolve-jenkinsworker-linux-deploy/Dockerfile`).
- **TODO (NHETIO-4421):** Replace with the Core Engineering hardened base
  image once published (account `702267635140`). Single `FROM`-line change.

---

## Build

### Prerequisites — CI must stage two files into the build context root

```bash
cd evolve-services-EvlSolr-1.0-master/

# 1. tio-utils.sh — from repo root
cp ../tio-utils.sh .

# 2. newrelic-java.zip — from packer assets
cp ../packer/assets/3rdparty/newrelic/newrelic-java.zip .
```

`evolve-solr-config.zip` is already inside `vobs/EvolveEcom/Solr/setup/` — no
staging needed.

### Build commands

Both images use the **module root** (`evolve-services-EvlSolr-1.0-master/`) as
the build context so that `COPY vobs/...` paths resolve correctly.

```bash
# Master
docker build \
  -f master/Dockerfile \
  --build-arg EVLSOLRMASTER_ARTIFACT_URL="https://health.artifactory.tio.systems/\
generic-evolve-services-dev-local/EvolveEcom/EvlSolr/EvlSolrMaster/<ver>/EvlSolrMaster-<ver>.tgz" \
  -t evlsolrmaster:<ver> \
  .

# Slave
docker build \
  -f slave/Dockerfile \
  --build-arg EVLSOLRSLAVE_ARTIFACT_URL="https://health.artifactory.tio.systems/\
generic-evolve-services-dev-local/EvolveEcom/EvlSolr/EvlSolrSlave/<ver>/EvlSolrSlave-<ver>.tgz" \
  -t evlsolrslave:<ver> \
  .
```

> **TODO:** Confirm exact Artifactory URL base path with the build/CI team.
> Artifact naming convention **confirmed** via `EvlSolrMaster.scm.properties` (`scm.release.id`):
> `EvlSolrMaster-{major}.{minor}.{patch}-{buildnum}.tgz` — e.g. `EvlSolrMaster-1.2.0-1.tgz`
> Replace `<ver>` above with the full release ID string (e.g. `1.2.0-1`), not just the semantic version.

---

## Runtime — Environment Variables

### Required (both images)

| Variable | Example | Description |
|---|---|---|
| `EVOLVE_INSTANCE_ENV` | `dev` | Environment name — used for Secrets Manager secret-id and NR app name |

### Optional (both images)

| Variable | Default | Description |
|---|---|---|
| `AWS_REGION` | `us-east-2` | AWS region for Secrets Manager calls |
| `SOLR_JAVA_HEAP` | `-Xms4G -Xmx4G` | JVM heap flags; matches dev/cert EC2 setting |

### Slave only

| Variable | Default | Description |
|---|---|---|
| `SOLR_MASTER_URL` | `http://solr-mstr-{env}.ehsevolve.com/solr/evolve/replication` | Full URL of the master replication handler. Set to the K8s Service DNS name in-cluster (e.g. `http://solrmaster:8081/solr/evolve/replication`). Falls back to the baked-in EC2 DNS name when not set — enabling the slave container to replicate from a still-running EC2 master during migration. |

---

## What docker-entrypoint.sh Does at Runtime

Both entrypoints run the same steps. Slave adds steps 1b and changes step 4.

| Step | Master | Slave | EC2 Equivalent |
|---|---|---|---|
| 1 | Fetch DB creds from Secrets Manager `{env}/rds` → `sed` into `evolve-jetty-jndi.xml` | Same | `getJsonSecret "${BUILD_ENV}/rds"` in `install_latest_solr.sh` |
| 1b | — | Patch `<masterUrl>` in `solrconfig.xml` with `SOLR_MASTER_URL` | Hardcoded EC2 DNS in artifact's `solrconfig.xml` |
| 2 | Write `SOLR_JAVA_MEM` to `solr.in.sh` | Same | `SOLR_JAVA_HEAP_OVERRIDE` in `userdata_utils.tpl` |
| 3 | Fetch NR license from Secrets Manager `NEW_RELIC_LICENSE_KEY` → `newrelic.yml` | Same | `getJsonSecret "NEW_RELIC_LICENSE_KEY"` in `install_newrelic.sh` |
| 4 | NR app name: `{env}-solrmaster-{podname}-solr` | `{env}-solrslave-{podname}-solr` | `{env}-{CLASS}-{instanceId}` in `install_newrelic.sh` |
| 5 | Append NR javaagent to `SOLR_OPTS` in `solr.in.sh` | Same | `SOLR_OPTS` append in `install_latest_solr.sh` |
| 6 | Patch `/etc/hosts` to fix `java.net.UnknownHostException` | Same | `printf '%s\t%s\tlocalhost\n'` in `userdata_solr.tpl` |
| 7 | `exec bin/solr start -f -p 8081 -j --module=plus` | Same | `service solr start` (init.d) |

---

## Deliberate Deviations from the EC2 Approach

These are intentional — not gaps. Future developers should not revert them.

### 1. `install_solr_service.sh` is skipped

**EC2:** `install_solr_service.sh` is run to register Solr as an init.d/systemd
service and write `/etc/default/solr.in.sh`.

**Container:** Skipped. The script fails without systemd as PID 1. `solr.in.sh`
and `/var/solr/` are created manually in Dockerfile step 7. The service is
started directly via `bin/solr start -f` in the entrypoint.

### 2. `--module=plus` via `-j` flag, not awk injection

**EC2:** `--module=plus` was injected into `/etc/init.d/solr` via an awk
one-liner (NHETIO-2225) because the Solr init script did not support it natively.

**Container:** Passed directly as `bin/solr start -f -p 8081 -j --module=plus`.
`/etc/init.d/solr` does not exist in the container — no awk needed.

### 3. `install_newrelic.sh` is skipped

**EC2:** `install_newrelic.sh` called `getClass`, `getEnv`, `getInstanceId`
(all read from EC2 IMDS or `/etc/default/` set by userdata).

**Container:** Skipped. The NR zip is unzipped at build time only. License key
and app name are injected by the entrypoint via AWS Secrets Manager and the
`HOSTNAME` env var (which K8s sets to the pod name).

### 4. `bin/solr create -c evolve` is not run at runtime

**EC2:** `install_latest_solr.sh` ran `su evolve -c "solr create -c evolve"` at
boot, which started Solr temporarily to create the collection.

**Container:** `core.properties` (`name=evolve`) is written at build time.
Solr auto-discovers and loads the pre-seeded core on startup — no double-start.

### 5. `ojdbc8.jar` is not yet available

**EC2/EC2 ticket spec:** References `ojdbc8.jar`.

**Container:** `evolve-solr-config.zip` already ships `ojdbc6.jar` in
`server/lib/jndi/`. No separate COPY step is needed until the ojdbc8 upgrade.
**Tracked in NHETIO-3792.**

### 6. `solrconfig.xml` is not CI-staged

**Ticket spec:** Listed `solrconfig.xml` as a CI-staged asset.

**Container:** `solrconfig.xml` is **not** in `evolve-solr-config.zip`. It
comes bundled inside `EvlSolrMaster.tgz` / `EvlSolrSlave.tgz` (the env-specific
conf built by `master/{env}/conf/` and `slave/{env}/conf/`). No separate COPY needed.

---

## IAM Requirements (IRSA)

The pod's service account needs these permissions at runtime:

```
secretsmanager:GetSecretValue on arn:aws:secretsmanager:{region}:{account}:secret:{env}/rds-*
secretsmanager:GetSecretValue on arn:aws:secretsmanager:{region}:{account}:secret:NEW_RELIC_LICENSE_KEY-*
```

---

## Key File Inventory

| File | Role |
|---|---|
| `master/Dockerfile` | Builds the EvlSolrMaster (Leader) image |
| `master/docker-entrypoint.sh` | Master runtime init (creds, NR, Solr start) |
| `slave/Dockerfile` | Builds the EvlSolrSlave (Follower) image |
| `slave/docker-entrypoint.sh` | Slave runtime init (adds masterUrl patch + solrslave NR name) |
| `vobs/EvolveEcom/Solr/setup/evolve-solr-config.zip` | Overlay: `evolve-jetty-jndi.xml`, JNDI jars, `ojdbc6.jar`, `plus.mod`, lang files |
| `vobs/EvolveEcom/Solr/master/build/build.xml` | Ant build for `EvlSolrMaster-{ver}.tgz` |
| `vobs/EvolveEcom/Solr/slave/build/build.xml` | Ant build for `EvlSolrSlave-{ver}.tgz` |
| `packer/solr.pkr.hcl` | EC2 reference — Packer AMI build (not used in containers) |
| `packer/assets/solr/opt/tio/install_latest_solr.sh` | EC2 reference — boot installer (not used in containers) |
| `evolve-services-modern/dev-us-east-2/userdata_solr.tpl` | EC2 reference — userdata (not used in containers) |
| `packer/assets/3rdparty/newrelic/newrelic-java.zip` | **CI-staged** — NR Java agent |
| `tio-utils.sh` (repo root) | **CI-staged** — shared shell utilities |

---

## Unresolved TODOs

These must be resolved before the first successful production build.
All are non-blocking for local testing with the stubbed entrypoint.

| # | Item | Owner |
|---|---|---|
| 1 | ~~Confirm Core Engineering hardened base image URI~~ **RESOLVED**: `docker-eols-cijenkins-local.health.artifactory.tio.systems/eols/tio-al2023-java8:1.0.0` | Core Engineering (account `702267635140`) |
| 2 | Confirm exact Artifactory URL format for `EvlSolrMaster`/`Slave` `.tgz` | Build / CI team |
| 3 | ~~Confirm `EvlSolrMaster.tgz` internal path — does it extract to `server/solr/evolve/` or elsewhere?~~ **RESOLVED**: flat core overlay (`conf/`, `data/`, `META-INF/`) per `project.properties` `install.root=/var/solr/data/evolve` and both artifact READMEs. EC2 extracts to `/var/solr/data/evolve`; container extracts to `$SOLR_HOME/evolve` (`/opt/solr/current/server/solr/evolve/`). | Build / CI team |
| 4 | ~~Confirm DB credentials: SSM Parameter Store vs Secrets Manager, and exact path~~ **RESOLVED**: Secrets Manager at `{env}/rds` (confirmed matches EC2 `install_latest_solr.sh`) | Platform team |
| 5 | ~~`ojdbc8.jar` availability in Artifactory + correct `server/lib/` destination path~~ **RESOLVED**: `ojdbc6.jar` (2.6MB, same driver currently on EC2 AMI) placed at `vobs/EvolveEcom/Solr/setup/ojdbc6.jar`, copied to `/opt/solr/current/server/lib/ext/` at build time. Upgrade to `ojdbc8` deferred pending Oracle 19c migration. | NHETIO-3792 |
| 6 | ECR / Artifactory Docker registry path and image naming convention | Platform team |

---

## Local Testing

### Build-only test (no AWS credentials needed)

```bash
cd evolve-services-EvlSolr-1.0-master/

# Stage CI assets
cp ../tio-utils.sh .
cp ../packer/assets/3rdparty/newrelic/newrelic-java.zip .

# Serve a stub artifact locally (avoids Artifactory dependency)
mkdir -p /tmp/artifacts
tar czf /tmp/artifacts/EvlSolrMaster-dev.tgz -T /dev/null
tar czf /tmp/artifacts/EvlSolrSlave-dev.tgz  -T /dev/null
python3 -m http.server 8000 --directory /tmp/artifacts &

# Build
docker build -f master/Dockerfile \
  --build-arg EVLSOLRMASTER_ARTIFACT_URL="http://host.docker.internal:8000/EvlSolrMaster-dev.tgz" \
  -t evlsolrmaster:local .

docker build -f slave/Dockerfile \
  --build-arg EVLSOLRSLAVE_ARTIFACT_URL="http://host.docker.internal:8000/EvlSolrSlave-dev.tgz" \
  -t evlsolrslave:local .
```

### Build-time assertions (no container start needed)

```bash
# Solr binary is present
docker run --rm --entrypoint="" evlsolrmaster:local /opt/solr/current/bin/solr version

# JNDI placeholder tokens are intact (entrypoint substitutes them at runtime)
docker run --rm --entrypoint="" evlsolrmaster:local \
  grep -E "EVOLVE_DB_(URL|USERNAME|PASSWORD)" \
  /opt/solr/current/server/etc/evolve-jetty-jndi.xml

# shardsWhitelist is baked into the SLAVE image only
docker run --rm --entrypoint="" evlsolrslave:local \
  grep "solr.disable.shardsWhitelist" /etc/default/solr.in.sh

# NR jar is present
docker run --rm --entrypoint="" evlsolrmaster:local \
  ls -lh /opt/solr/current/newrelic/newrelic.jar

# core.properties is seeded
docker run --rm --entrypoint="" evlsolrmaster:local \
  cat /opt/solr/current/server/solr/evolve/core.properties
```

### Full runtime test (AWS dev credentials required)

```bash
# Use aws-vault or export credentials manually
aws-vault exec <nonprod-profile> -- env | grep AWS > /tmp/aws-creds.env

# Master
docker run --rm --env-file /tmp/aws-creds.env \
  -e EVOLVE_INSTANCE_ENV=dev \
  -e AWS_REGION=us-east-2 \
  -e SOLR_JAVA_HEAP="-Xms1G -Xmx1G" \
  -p 8081:8081 --name solrmaster \
  evlsolrmaster:local

# Slave (separate terminal)
docker run --rm --env-file /tmp/aws-creds.env \
  -e EVOLVE_INSTANCE_ENV=dev \
  -e AWS_REGION=us-east-2 \
  -e SOLR_JAVA_HEAP="-Xms1G -Xmx1G" \
  -e SOLR_MASTER_URL="http://solrmaster:8081/solr/evolve/replication" \
  --link solrmaster \
  -p 8082:8081 \
  evlsolrslave:local
```

### Validate running containers

```bash
# evolve core present on master
curl -s http://localhost:8081/solr/admin/cores?action=STATUS | jq '.status.evolve.name'

# evolve core present on slave
curl -s http://localhost:8082/solr/admin/cores?action=STATUS | jq '.status.evolve.name'

# Slave replication details — check masterUrl and replication status
curl -s "http://localhost:8082/solr/evolve/replication?command=details" \
  | jq '{isSlave: .details.isSlave, masterUrl: .details.slave.masterUrl}'

# DB credentials substituted (no raw tokens remaining)
docker exec solrmaster grep -c "EVOLVE_DB_URL" \
  /opt/solr/current/server/etc/evolve-jetty-jndi.xml
# Expected: 0

# New Relic agent loading
docker logs solrmaster 2>&1 | grep -i "new relic"

# DB / JNDI errors
docker logs solrmaster 2>&1 | grep -iE "oracle|jdbc|jndi|ORA-|exception"
```

---

## Common Failures

| Symptom | Cause | Fix |
|---|---|---|
| `COPY tio-utils.sh: not found` | CI staging step skipped | Run `cp ../tio-utils.sh .` from the module root |
| `curl: (6) Could not resolve host` during build | VPN off or Artifactory unreachable | Connect VPN; or use local HTTP stub (see build-only test above) |
| Solr hangs / OOM in entrypoint | Default 4G heap too large for local Docker | Set `SOLR_JAVA_HEAP="-Xms512m -Xmx512m"` |
| `isSlave: false` on slave | `masterUrl` sed path wrong — `solrconfig.xml` not at expected location | Run `docker run --rm --entrypoint="" evlsolrslave:local find /opt/solr -name solrconfig.xml` to confirm actual path; update `SOLR_SLAVE_CONF` in `slave/docker-entrypoint.sh` |
| `CredentialRetrievalError` | AWS credentials not passed to container | Use `--env-file` with `aws-vault` output; or use the stubbed entrypoint for offline testing |
| `/etc/hosts: Read-only file system` | Hardened Docker or cluster policy | Add `--add-host=$(hostname):127.0.0.1` to `docker run` instead |
| `Error: Could not find or load main class` | Wrong Java version from Corretto image | Verify `docker run --rm --entrypoint="" evlsolrmaster:local java -version` shows `1.8.x` |
