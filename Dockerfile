FROM haproxy:2.9.5-alpine3.19

USER root

ENV HAPROXY_PORT 2375
ENV BIND_ADDRESS *
ENV EX_APPS_NET "localhost"
ENV EX_APPS_COUNT 50

RUN set -ex; \
    apk add --no-cache \
        ca-certificates \
        tzdata \
        bash \
        curl \
        openssl \
        bind-tools; \
    chmod -R 777 /tmp

COPY --chmod=775 *.sh /
COPY --chmod=664 haproxy.cfg /haproxy.cfg
COPY --chmod=664 haproxy_ex_apps.cfg /haproxy_ex_apps.cfg

WORKDIR /
ENTRYPOINT ["/bin/bash", "start.sh"]
HEALTHCHECK --interval=10s --timeout=10s --retries=9 CMD /healthcheck.sh
