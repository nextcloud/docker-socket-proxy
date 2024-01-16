FROM haproxy:2.9.2-alpine3.19

USER root

ENV HAPROXY_PORT 2375
EXPOSE ${HAPROXY_PORT}

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

WORKDIR /
ENTRYPOINT ["/bin/bash", "start.sh"]
HEALTHCHECK --interval=30s --timeout=10s --retries=3 CMD /healthcheck.sh
