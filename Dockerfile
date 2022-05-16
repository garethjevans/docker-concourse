FROM golang:1.18.2 as go
RUN GO111MODULE=on go install github.com/paketo-buildpacks/libpak/cmd/create-package@main
RUN GO111MODULE=on go install github.com/paketo-buildpacks/libpak/cmd/update-buildpack-dependency@main
RUN GO111MODULE=on go install github.com/paketo-buildpacks/libpak/cmd/update-package-dependency@main
RUN GO111MODULE=on go install github.com/garethjevans/commitpr@main
RUN GO111MODULE=on go install github.com/garethjevans/next@main

FROM alpine:3.15

COPY --from=go /go/bin/create-package /usr/local/bin/create-package
COPY --from=go /go/bin/update-buildpack-dependency /usr/local/bin/update-buildpack-dependency
COPY --from=go /go/bin/update-package-dependency /usr/local/bin/update-package-dependency
COPY --from=go /go/bin/commitpr /usr/local/bin/commitpr
COPY --from=go /go/bin/next /usr/local/bin/next

ENV DOCKER_CHANNEL=stable \
    DOCKER_VERSION=19.03.2 \
    DOCKER_COMPOSE_VERSION=1.29.2 \
    DOCKER_SQUASH=0.2.0 \
    PACK_VERSION=0.24.0 \
    YJ_VERSION=5.0.0 \
    JQ_VERSION=1.6 \
    VENOM_VERSION=1.0.1

# Install Docker, Docker Compose, Docker Squash
RUN apk --update --no-cache add \
        bash \
        curl \
        device-mapper \
        py3-pip \
        python3-dev \
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
    apk upgrade

RUN pip install --upgrade pip && \
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

RUN mkdir /lib64 && ln -s /lib/libc.musl-x86_64.so.1 /lib64/ld-linux-x86-64.so.2
# Install go
ENV GO_VERSION 1.17.8
RUN wget -q https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz && \
  tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz && \
  rm -rf go${GO_VERSION}.linux-amd64.tar.gz && \
  mkdir -p /go/bin

# set GOPATH
ENV GOPATH /go
# add go and GOPATH/bin to PATH
ENV PATH $PATH:$GOPATH/bin:/usr/local/go/bin

RUN curl \
      --location \
      --show-error \
      --silent \
      --output /usr/local/bin/venom \
      https://github.com/ovh/venom/releases/download/v${VENOM_VERSION}/venom.linux-amd64 && \
      chmod +x /usr/local/bin/venom

RUN curl \
      -LO https://storage.googleapis.com/container-structure-test/latest/container-structure-test-linux-amd64 && chmod +x container-structure-test-linux-amd64 \
      && mv container-structure-test-linux-amd64 /usr/local/bin/container-structure-test
