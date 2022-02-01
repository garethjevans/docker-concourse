FROM golang:1.17.5 as go
RUN GO111MODULE=on go get -u -ldflags="-s -w" github.com/paketo-buildpacks/libpak/cmd/create-package
RUN GO111MODULE=on go get -u -ldflags="-s -w" github.com/paketo-buildpacks/libpak/cmd/update-buildpack-dependency
RUN GO111MODULE=on go get -u -ldflags="-s -w" github.com/paketo-buildpacks/libpak/cmd/update-package-dependency
RUN GO111MODULE=on go get -u -ldflags="-s -w" github.com/garethjevans/create-pr/cmd/pr

FROM alpine:3.10

COPY --from=go /go/bin/create-package /usr/local/bin/create-package
COPY --from=go /go/bin/update-buildpack-dependency /usr/local/bin/update-buildpack-dependency
COPY --from=go /go/bin/update-package-dependency /usr/local/bin/update-package-dependency
COPY --from=go /go/bin/pr /usr/local/bin/pr

ENV DOCKER_CHANNEL=stable \
    DOCKER_VERSION=19.03.2 \
    DOCKER_COMPOSE_VERSION=1.24.1 \
    DOCKER_SQUASH=0.2.0 \
    PACK_VERSION=0.23.0 \
    YJ_VERSION=5.0.0 \
    JQ_VERSION=1.6 \
    GH_VERSION=2.4.0

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
	git \
        && \
    apk upgrade && \
    curl -fL "https://download.docker.com/linux/static/${DOCKER_CHANNEL}/x86_64/docker-${DOCKER_VERSION}.tgz" | tar zx && \
    mv /docker/* /bin/ && chmod +x /bin/docker* && \
    pip install docker-compose==${DOCKER_COMPOSE_VERSION} && \
    curl -fL "https://github.com/jwilder/docker-squash/releases/download/v${DOCKER_SQUASH}/docker-squash-linux-amd64-v${DOCKER_SQUASH}.tar.gz" | tar zx && \
    mv /docker-squash* /bin/ && chmod +x /bin/docker-squash* && \
    rm -rf /var/cache/apk/* && \
    rm -rf /root/.cache

COPY docker-functions.sh /bin/docker-functions.sh

RUN curl \
      --location \
      --show-error \
      --silent "https://github.com/buildpacks/pack/releases/download/v${PACK_VERSION}/pack-v${PACK_VERSION}-linux.tgz" | tar zx && \
      mv pack /bin/pack && chmod +x /bin/pack

RUN curl \
      --location \
      --show-error \
      --silent \
      --output /usr/local/bin/yj \
      https://github.com/sclevine/yj/releases/download/v${YJ_VERSION}/yj-linux && \
      chmod +x /usr/local/bin/yj

RUN curl \
      --location \
      --show-error \
      --silent \
      --output /usr/local/bin/jq \
      https://github.com/stedolan/jq/releases/download/jq-${JQ_VERSION}/jq-linux64 && \
      chmod +x /usr/local/bin/jq

RUN curl \
      --location \
      --show-error \
      --silent \
      --output gh.tar.gz \
      https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_amd64.tar.gz && \
      tar xfz gh.tar.gz && mv gh_${GH_VERSION}_linux_amd64/bin/gh /usr/local/bin/gh && \
      rm -fr gh_${GH_VERSION}_linux_amd64

RUN mkdir /lib64 && ln -s /lib/libc.musl-x86_64.so.1 /lib64/ld-linux-x86-64.so.2
