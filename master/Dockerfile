FROM docker-eols-cijenkins-local.health.artifactory.tio.systems/eols/tio-al2023-java8:1.0.0

LABEL org.opencontainers.image.vendor="Elsevier" \
      org.opencontainers.image.title="EvlSolrMaster" \
      org.opencontainers.image.description="Evolve e-commerce Solr search — master (leader) node" \
      org.opencontainers.image.source="https://github.com/elsevier-health/evolve-services-EvlSolr-1.0" \
      org.opencontainers.image.licenses="Proprietary"

ARG SOLR_VERSION=8.11.2
ARG SOLR_SHA512="22fedcc0090eda72c3c5a5ea769c93adaf7d92c5c4479993f009ef0b9d42de5bd2ed1e0565ca01f3428587d8a3836286aa3017aab157050f2bd5bc3482fdebaa"
ARG SOLR_DOWNLOAD_URL="https://archive.apache.org/dist/lucene/solr/${SOLR_VERSION}/solr-${SOLR_VERSION}.tgz"
ARG CURL_OPTS=""
ARG DNF_SSLVERIFY=True

ARG NR_VERSION=8.20.0
ARG NR_SHA256="7a02e115ce945843fab71b5ae155bef80733d80e000ab3c3f51df36422281bdf"
ARG NR_ARTIFACT_URL="https://health.artifactory.tio.systems/artifactory/maven-central-remote/com/newrelic/agent/java/newrelic-java/${NR_VERSION}/newrelic-java-${NR_VERSION}.zip"

# Required: Artifactory URL for EvlSolrMaster-<version>.tar
ARG EVLSOLRMASTER_ARTIFACT_URL
# Target environment: dev | cert | stage | prod
ARG SOLR_ENV=prod

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

RUN mkdir -p \
      /opt/tio \
      /opt/newrelic \
      /opt/solr \
      /var/solr/logs \
    && useradd -r -m -s /sbin/nologin evolve

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

COPY vobs/EvolveEcom/Solr/setup/evolve-solr-config.zip /opt/tio/
RUN unzip -q /opt/tio/evolve-solr-config.zip -d /opt/solr/ \
    && cp -rf /opt/solr/evolve-solr-config/server /opt/solr/current/ \
    && rm -rf /opt/tio/evolve-solr-config.zip /opt/solr/evolve-solr-config

# ojdbc8 upgrade tracked in NHETIO-3792
COPY vobs/EvolveEcom/Solr/setup/ojdbc6.jar /opt/solr/current/server/lib/ext/

COPY tio-utils.sh /opt/tio/

RUN curl ${CURL_OPTS} -fSL \
      "${EVLSOLRMASTER_ARTIFACT_URL}" \
      -o /opt/tio/EvlSolrMaster.tar \
    && tar -xf /opt/tio/EvlSolrMaster.tar -C /opt/tio/ \
    && tar -xzf /opt/tio/EvlSolrMaster-*/EvlSolrMaster.tgz -C /opt/tio/ \
    && mkdir -p /opt/solr/current/server/solr/evolve \
    && tar -xzf /opt/tio/EvlSolrMaster-*/${SOLR_ENV}/EvlSolrMaster.tgz \
         --strip-components=1 \
         -C /opt/solr/current/server/solr/evolve/ \
    && rm -rf /opt/tio/EvlSolrMaster.tar /opt/tio/EvlSolrMaster-*/

RUN echo "name=evolve" > /opt/solr/current/server/solr/evolve/core.properties

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

# NR_SHA256="" skips checksum verification; license key injected at runtime by docker-entrypoint.sh
RUN curl ${CURL_OPTS} -fSL \
      "${NR_ARTIFACT_URL}" \
      -o /opt/newrelic/newrelic-java.zip \
    && if [ -n "${NR_SHA256}" ]; then \
         echo "${NR_SHA256}  /opt/newrelic/newrelic-java.zip" | sha256sum -c -; \
       fi \
    && unzip -q /opt/newrelic/newrelic-java.zip -d /opt/newrelic/ \
    && cp -rf /opt/newrelic/newrelic /opt/solr/current/newrelic \
    && rm -rf /opt/newrelic

COPY master/docker-entrypoint.sh /opt/tio/docker-entrypoint.sh
RUN chmod +x /opt/tio/docker-entrypoint.sh \
    && chown -R evolve:evolve /opt/solr/ /opt/tio/ /var/solr/ /etc/default/solr.in.sh

EXPOSE 8081
HEALTHCHECK --interval=30s --timeout=10s --start-period=90s --retries=3 \
  CMD curl -sf "http://localhost:8081/solr/evolve/admin/ping" | grep -q '"status":"OK"' || exit 1
USER evolve
ENTRYPOINT ["/opt/tio/docker-entrypoint.sh"]
