# SPDX-FileCopyrightText: 2023 Nextcloud GmbH and Nextcloud contributors
# SPDX-License-Identifier: AGPL-3.0-or-later

FROM haproxy:2.9.7-alpine3.19

USER root

ENV HAPROXY_PORT 2375
ENV BIND_ADDRESS *
ENV EX_APPS_NET "localhost"
ENV EX_APPS_COUNT 30
ENV TIMEOUT_CONNECT "10s"
ENV TIMEOUT_CLIENT  "30s"
ENV TIMEOUT_SERVER  "1800s"

RUN set -ex; \
    apk add --no-cache \
        ca-certificates \
        tzdata \
        bash \
        curl \
        openssl \
        bind-tools \
        nano \
        vim \
        envsubst; \
    chmod -R 777 /tmp

COPY --chmod=775 *.sh /
COPY --chmod=664 haproxy.cfg.template /haproxy.cfg.template
COPY --chmod=664 haproxy_ex_apps.cfg.template /haproxy_ex_apps.cfg.template

WORKDIR /
ENTRYPOINT ["/bin/bash", "start.sh"]
HEALTHCHECK --interval=10s --timeout=10s --retries=9 CMD /healthcheck.sh
LABEL com.centurylinklabs.watchtower.enable="false"
