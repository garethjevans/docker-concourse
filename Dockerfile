FROM alpine:3.10

ENV DOCKER_CHANNEL=stable \
    DOCKER_VERSION=19.03.2 \
    DOCKER_COMPOSE_VERSION=1.24.1 \
    DOCKER_SQUASH=0.2.0 \
    PACK_VERSION=0.23.0

# Install Docker, Docker Compose, Docker Squash
RUN apk --update --no-cache add \
        bash \
        curl \
        device-mapper \
        py-pip \
        python-dev \
        iptables \
        util-linux \
        ca-certificates \
        gcc \
        libc-dev \
        libffi-dev \
        openssl-dev \
        make \
        && \
    apk upgrade && \
    curl -fL "https://download.docker.com/linux/static/${DOCKER_CHANNEL}/x86_64/docker-${DOCKER_VERSION}.tgz" | tar zx && \
    mv /docker/* /bin/ && chmod +x /bin/docker* && \
    pip install docker-compose==${DOCKER_COMPOSE_VERSION} && \
    curl -fL "https://github.com/jwilder/docker-squash/releases/download/v${DOCKER_SQUASH}/docker-squash-linux-amd64-v${DOCKER_SQUASH}.tar.gz" | tar zx && \
    mv /docker-squash* /bin/ && chmod +x /bin/docker-squash* && \
    rm -rf /var/cache/apk/* && \
    rm -rf /root/.cache

COPY entrypoint.sh /bin/entrypoint.sh

RUN curl -fL "https://github.com/buildpacks/pack/releases/download/v${PACK_VERSION}/pack-v${PACK_VERSION}-linux.tgz" | tar zx && \
        mv pack /bin/pack && chmod +x /bin/pack

ENTRYPOINT ["entrypoint.sh"]
