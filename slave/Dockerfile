# EvlSolrSlave — Container Image  (NHETIO-4422)
# Replaces: packer/solr.pkr.hcl + install_latest_solr.sh + userdata_solr.tpl
# Companion to NHETIO-4421 (EvlSolrMaster). Steps 1-5, 7, 9 are identical.
# Differences: EVLSOLRSLAVE_ARTIFACT_URL, shardsWhitelist step, slave entrypoint.
#
# CI must stage into build context root before docker build:
#   tio-utils.sh      ← repo root
#
# Required build args (--build-arg):
#   EVLSOLRSLAVE_ARTIFACT_URL  Artifactory URL for EvlSolrSlave-<version>.tgz
#   NR_VERSION                  New Relic Java agent version (default: 8.20.0)
#   NR_ARTIFACT_URL            Artifactory maven-central-remote URL for newrelic-java.zip (default set; override to pin a different version)

# Core Engineering hardened AL2023 Java 8 image (account 702267635140) — replaces public amazoncorretto upstream
FROM docker-eols-cijenkins-local.health.artifactory.tio.systems/eols/tio-al2023-java8:1.0.0

# OCI standard provenance labels (enterprise requirement)
LABEL org.opencontainers.image.vendor="Elsevier" \
      org.opencontainers.image.title="EvlSolrSlave" \
      org.opencontainers.image.description="Evolve e-commerce Solr search — slave (follower) node" \
      org.opencontainers.image.source="https://github.com/elsevier-health/evolve-services-EvlSolr-1.0" \
      org.opencontainers.image.licenses="Proprietary"

ARG SOLR_VERSION=8.11.2
# SHA512 of the official Apache Solr 8.11.2 tarball — set to empty to skip (e.g. local stub builds)
ARG SOLR_SHA512="22fedcc0090eda72c3c5a5ea769c93adaf7d92c5c4479993f009ef0b9d42de5bd2ed1e0565ca01f3428587d8a3836286aa3017aab157050f2bd5bc3482fdebaa"
# Local dev overrides (leave unset in CI/prod)
ARG SOLR_DOWNLOAD_URL="https://archive.apache.org/dist/lucene/solr/${SOLR_VERSION}/solr-${SOLR_VERSION}.tgz"
ARG CURL_OPTS=""
ARG DNF_SSLVERIFY=True

# New Relic Java agent — internal Artifactory proxy of Maven Central (pinned version)
# Override with --build-arg NR_VERSION=x.y.z to change version; set NR_SHA256="" to skip verification
ARG NR_VERSION=8.20.0
ARG NR_SHA256="7a02e115ce945843fab71b5ae155bef80733d80e000ab3c3f51df36422281bdf"
ARG NR_ARTIFACT_URL="https://health.artifactory.tio.systems/artifactory/maven-central-remote/com/newrelic/agent/java/newrelic-java/${NR_VERSION}/newrelic-java-${NR_VERSION}.zip"

# Artifactory artifact URL — passed via --build-arg in CI
ARG EVLSOLRSLAVE_ARTIFACT_URL

# 1. Runtime packages — mirrors: packer/solr.pkr.hcl dnf install step
RUN echo "sslverify=${DNF_SSLVERIFY}" >> /etc/dnf/dnf.conf \
    && dnf install -y --allowerasing \
      tar \
      gzip \
      unzip \
      jq \
      awscli \
      shadow-utils \
      procps-ng \
    && dnf clean all \
    && rm -rf /var/cache/dnf

# 2. Directories + OS user — mirrors: packer/solr.pkr.hcl "Create Destination Folders"
RUN mkdir -p \
      /opt/tio \
      /opt/newrelic \
      /opt/solr \
      /var/solr/logs \
    && useradd -r -m -s /sbin/nologin evolve

# 3. Download Solr — mirrors: packer/solr.pkr.hcl "Download & Unpack Solr"
RUN curl ${CURL_OPTS} -fSL \
      "${SOLR_DOWNLOAD_URL}" \
      -o /opt/tio/solr-${SOLR_VERSION}.tgz \
    && if [ -n "${SOLR_SHA512}" ]; then \
         echo "${SOLR_SHA512}  /opt/tio/solr-${SOLR_VERSION}.tgz" | sha512sum -c -; \
       fi \
    && tar -xzf /opt/tio/solr-${SOLR_VERSION}.tgz -C /opt/solr/ \
    && ln -s /opt/solr/solr-${SOLR_VERSION} /opt/solr/current \
    && mkdir -p /opt/solr/current/logs \
    && rm /opt/tio/solr-${SOLR_VERSION}.tgz

# 4. Solr config overlay — mirrors: packer/solr.pkr.hcl "Unpack Solr Config"
# Provides: evolve-jetty-jndi.xml, Jetty Plus/JNDI jars, ojdbc6.jar (NHETIO-3792), plus.mod, lang files
COPY vobs/EvolveEcom/Solr/setup/evolve-solr-config.zip /opt/tio/
RUN unzip -q /opt/tio/evolve-solr-config.zip -d /opt/solr/ \
    && cp -rf /opt/solr/evolve-solr-config/server /opt/solr/current/ \
    && rm -rf /opt/tio/evolve-solr-config.zip /opt/solr/evolve-solr-config

# 4b. Oracle JDBC driver — replaces: ojdbc6.jar baked into EC2 AMI via Packer (NHETIO-3792)
# NOTE: ojdbc6.jar is the current file in the repo. Upgrade to ojdbc8.jar (Oracle 19c / Java 8)
# is tracked in NHETIO-3792. Update this COPY path when ojdbc8.jar is committed.
# Destination: server/lib/ext/ is Jetty's ext classloader path for JNDI DataSource
COPY vobs/EvolveEcom/Solr/setup/ojdbc6.jar /opt/solr/current/server/lib/ext/

# 5. tio-utils.sh — mirrors: packer/solr.pkr.hcl "Copy TIO assets" (CI-staged)
COPY tio-utils.sh /opt/tio/

# 6. EvlSolrSlave artifact — replaces: rt_install_evl_packages in install_latest_solr.sh
# Built by vobs/EvolveEcom/Solr/slave/build/build.xml
# TGZ structure: flat core overlay (conf/, data/, META-INF/) per project.properties install.root=/var/solr/data/evolve
# EC2 extracts to /var/solr/data/evolve (SOLR_HOME=/var/solr/data); container extracts to SOLR_HOME/evolve below.
RUN curl ${CURL_OPTS} -fSL \
      "${EVLSOLRSLAVE_ARTIFACT_URL}" \
      -o /opt/tio/EvlSolrSlave.tgz \
    && mkdir -p /opt/solr/current/server/solr/evolve \
    && tar -xzf /opt/tio/EvlSolrSlave.tgz \
         -C /opt/solr/current/server/solr/evolve/ \
    && rm /opt/tio/EvlSolrSlave.tgz

# core.properties triggers auto-discovery — replaces: bin/solr create at runtime
RUN echo "name=evolve" > /opt/solr/current/server/solr/evolve/core.properties

# 7. solr.in.sh — replaces: install_solr_service.sh (skipped; registers init.d/systemd)
# bin/solr sources bin/solr.in.sh FIRST (before /etc/default/solr.in.sh), so we write there.
RUN cp /opt/solr/current/server/resources/log4j2.xml /var/solr/ \
    && printf '%s\n' \
         'SOLR_HOME="/opt/solr/current/server/solr"' \
         'SOLR_PID_DIR="/var/solr"' \
         'SOLR_LOGS_DIR="/var/solr/logs"' \
         'LOG4J_PROPS="/var/solr/log4j2.xml"' \
         'SOLR_PORT="8081"' \
         'RUNAS="evolve"' \
       >> /opt/solr/current/bin/solr.in.sh \
    && cp /opt/solr/current/bin/solr.in.sh /etc/default/solr.in.sh

# 8. shardsWhitelist (Slave only) — mirrors: install_latest_solr.sh lines 156-163
RUN if ! grep -q "solr.disable.shardsWhitelist=true" /opt/solr/current/bin/solr.in.sh; then \
      echo 'SOLR_OPTS="$SOLR_OPTS -Dsolr.disable.shardsWhitelist=true"' \
        >> /opt/solr/current/bin/solr.in.sh \
      && echo 'SOLR_OPTS="$SOLR_OPTS -Dsolr.disable.shardsWhitelist=true"' \
        >> /etc/default/solr.in.sh; \
    fi

# 9. New Relic agent — pulled from Artifactory maven-central proxy (NR_VERSION pinned).
# License key is NOT baked in; it is injected at runtime by docker-entrypoint.sh.
RUN curl ${CURL_OPTS} -fSL \
      "${NR_ARTIFACT_URL}" \
      -o /opt/newrelic/newrelic-java.zip \
    && if [ -n "${NR_SHA256}" ]; then \
         echo "${NR_SHA256}  /opt/newrelic/newrelic-java.zip" | sha256sum -c -; \
       fi \
    && unzip -q /opt/newrelic/newrelic-java.zip -d /opt/newrelic/ \
    && cp -rf /opt/newrelic/newrelic /opt/solr/current/newrelic \
    && rm -rf /opt/newrelic

# 10. Entrypoint + permissions
COPY slave/docker-entrypoint.sh /opt/tio/docker-entrypoint.sh
RUN chmod +x /opt/tio/docker-entrypoint.sh \
    && chown -R evolve:evolve /opt/solr/ /opt/tio/ /var/solr/ /etc/default/solr.in.sh

EXPOSE 8081
# Liveness probe: verifies Solr is serving requests (used by Docker + K8s/ECS health checks)
HEALTHCHECK --interval=30s --timeout=10s --start-period=90s --retries=3 \
  CMD curl -sf "http://localhost:8081/solr/evolve/admin/ping" | grep -q '"status":"OK"' || exit 1
USER evolve
ENTRYPOINT ["/opt/tio/docker-entrypoint.sh"]
