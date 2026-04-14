# syntax=docker/dockerfile:1.4
# EvlSolrMaster — Container Image  (NHETIO-4421)
# Replaces: packer/solr.pkr.hcl + install_latest_solr.sh + userdata_solr.tpl
#
# CI must stage into build context root before docker build:
#   tio-utils.sh      ← repo root
#
# Required build secrets (--secret id=...,src=<file>):
#   artifactory_user   file containing Artifactory username
#   artifactory_token  file containing Artifactory API token
#
# Required build args (--build-arg):
#   EVLSOLRMASTER_ARTIFACT_URL  Artifactory URL for EvlSolrMaster-<version>.tgz
#   NR_ARTIFACT_URL             URL for newrelic-java.zip (Artifactory or public download)
#
# Core Engineering hardened AL2023 Java 8 image (account 702267635140) — replaces public amazoncorretto upstream
FROM docker-eols-cijenkins-local.health.artifactory.tio.systems/eols/tio-al2023-java8:1.0.0

# OCI standard provenance labels (enterprise requirement)
LABEL org.opencontainers.image.vendor="Elsevier" \
      org.opencontainers.image.title="EvlSolrMaster" \
      org.opencontainers.image.description="Evolve e-commerce Solr search — master (leader) node" \
      org.opencontainers.image.source="https://github.com/elsevier-health/evolve-services-EvlSolr-1.0" \
      org.opencontainers.image.licenses="Proprietary"

ARG SOLR_VERSION=8.11.2
# Local dev overrides (leave unset in CI/prod)
ARG SOLR_DOWNLOAD_URL="https://archive.apache.org/dist/lucene/solr/${SOLR_VERSION}/solr-${SOLR_VERSION}.tgz"
ARG CURL_OPTS=""
ARG DNF_SSLVERIFY=True

# Artifactory artifact URLs — passed via --build-arg in CI
# Credentials are never embedded in layers; they are read from BuildKit secrets at fetch time.
ARG EVLSOLRMASTER_ARTIFACT_URL
ARG NR_ARTIFACT_URL

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

# 6. EvlSolrMaster artifact — replaces: rt_install_evl_packages in install_latest_solr.sh
# Built by vobs/EvolveEcom/Solr/master/build/build.xml
# TGZ structure: flat core overlay (conf/, data/, META-INF/) per project.properties install.root=/var/solr/data/evolve
# EC2 extracts to /var/solr/data/evolve (SOLR_HOME=/var/solr/data); container extracts to SOLR_HOME/evolve below.
# Credentials are mounted read-only from BuildKit secrets and never written to any layer.
RUN --mount=type=secret,id=artifactory_user \
    --mount=type=secret,id=artifactory_token \
    AUSER=$(cat /run/secrets/artifactory_user) \
    ATOKEN=$(cat /run/secrets/artifactory_token) \
    curl ${CURL_OPTS} -fSL \
      -u "${AUSER}:${ATOKEN}" \
      "${EVLSOLRMASTER_ARTIFACT_URL}" \
      -o /opt/tio/EvlSolrMaster.tgz \
    && mkdir -p /opt/solr/current/server/solr/evolve \
    && tar -xzf /opt/tio/EvlSolrMaster.tgz \
         -C /opt/solr/current/server/solr/evolve/ \
    && rm /opt/tio/EvlSolrMaster.tgz

# core.properties triggers auto-discovery — replaces: bin/solr create at runtime
RUN echo "name=evolve" > /opt/solr/current/server/solr/evolve/core.properties

# 7. solr.in.sh — replaces: install_solr_service.sh (skipped; registers init.d/systemd)
# --module=plus is passed at runtime via bin/solr start -j (replaces NHETIO-2225 awk hack)
RUN cp /opt/solr/current/server/resources/log4j2.xml /var/solr/ \
    && printf '%s\n' \
         'SOLR_HOME="/opt/solr/current/server/solr"' \
         'SOLR_PID_DIR="/var/solr"' \
         'SOLR_LOGS_DIR="/var/solr/logs"' \
         'LOG4J_PROPS="/var/solr/log4j2.xml"' \
         'SOLR_PORT="8081"' \
         'RUNAS="evolve"' \
       > /etc/default/solr.in.sh

# 8. New Relic agent — fetched from Artifactory via BuildKit secret.
# License key is NOT baked in; it is injected at runtime by docker-entrypoint.sh.
RUN --mount=type=secret,id=artifactory_user \
    --mount=type=secret,id=artifactory_token \
    AUSER=$(cat /run/secrets/artifactory_user) \
    ATOKEN=$(cat /run/secrets/artifactory_token) \
    curl ${CURL_OPTS} -fSL \
      -u "${AUSER}:${ATOKEN}" \
      "${NR_ARTIFACT_URL}" \
      -o /opt/newrelic/newrelic-java.zip \
    && unzip -q /opt/newrelic/newrelic-java.zip -d /opt/newrelic/ \
    && cp -rf /opt/newrelic/newrelic /opt/solr/current/newrelic \
    && rm -rf /opt/newrelic

# 9. Entrypoint + permissions
COPY master/docker-entrypoint.sh /opt/tio/docker-entrypoint.sh
RUN chmod +x /opt/tio/docker-entrypoint.sh \
    && chown -R evolve:evolve /opt/solr/ /opt/tio/ /var/solr/ /etc/default/solr.in.sh

EXPOSE 8081
# Liveness probe: verifies Solr is serving requests (used by Docker + K8s/ECS health checks)
HEALTHCHECK --interval=30s --timeout=10s --start-period=90s --retries=3 \
  CMD curl -sf "http://localhost:8081/solr/evolve/admin/ping" | grep -q '"status":"OK"' || exit 1
USER evolve
ENTRYPOINT ["/opt/tio/docker-entrypoint.sh"]
