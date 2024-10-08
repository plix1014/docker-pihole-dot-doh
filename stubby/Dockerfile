FROM debian:bookworm AS openssl

ENV VERSION_OPENSSL=openssl-3.3.2
ENV SHA256_OPENSSL=2e8a40b01979afe8be0bbfb3de5dc1c6709fedb46d6c89c10da114ab5fc3d281 \
    SOURCE_OPENSSL=https://github.com/openssl/openssl/releases/download/${VERSION_OPENSSL} \
    OPGP_OPENSSL=BA5473A2B0587B07FB27CF2D216094DFD0CB81EF


WORKDIR /tmp/src
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN set -e -x && \
    build_deps="build-essential ca-certificates curl dirmngr gnupg libidn2-0-dev libssl-dev" && \
    DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        dirmngr \
        gnupg \
        libidn2-0-dev \
        libssl-dev && \
    curl -L ${SOURCE_OPENSSL}/${VERSION_OPENSSL}.tar.gz -o openssl.tar.gz && \
    echo "${SHA256_OPENSSL} ./openssl.tar.gz" | sha256sum -c - && \
    curl -L ${SOURCE_OPENSSL}/${VERSION_OPENSSL}.tar.gz.asc -o openssl.tar.gz.asc && \
    GNUPGHOME="$(mktemp -d)" && \
    export GNUPGHOME && \
    gpg --no-tty --keyserver keys.openpgp.org --recv-keys "$OPGP_OPENSSL" && \
    gpg --batch --verify openssl.tar.gz.asc openssl.tar.gz && \
    tar xzf openssl.tar.gz && \
    cd "${VERSION_OPENSSL}" && \
    /bin/sh -c 'if gcc -dM -E - </dev/null | grep -q __SIZEOF_INT128__; then export ECFLAG="enable-ec_nistp_64_gcc_128"; else export ECFLAG=""; fi' && \
    ./config \
        -Wl,-rpath=/opt/openssl/lib \
        --prefix=/opt/openssl \
        --openssldir=/opt/openssl \
        $ECFLAG \
        -DOPENSSL_NO_HEARTBEATS \
        no-weak-ssl-ciphers \
        no-ssl3 \
        shared \
        -fstack-protector-strong && \
    make depend && \
    make && \
    make install_sw && \
    apt-get purge -y --auto-remove \
      $build_deps && \
    rm -rf \
        /tmp/* \
        /var/tmp/* \
        /var/lib/apt/lists/*

FROM debian:bookworm AS stubby
LABEL maintainer="Matthew Vance"

ENV VERSION_GETDNS=v1.7.3

WORKDIR /tmp/src
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

COPY --from=openssl /opt/openssl /opt/openssl

RUN set -e -x && \
    build_deps="autoconf build-essential check cmake dh-autoreconf git libssl-dev libyaml-dev make m4" && \
    debian_frontend=noninteractive apt-get update && apt-get install -y --no-install-recommends \
      ${build_deps} \
      ca-certificates \
      dns-root-data \
      libyaml-0-2 && \
    debian_frontend=noninteractive apt-get update && apt-get install -y --no-install-recommends check cmake && \
    git clone https://github.com/getdnsapi/getdns.git && \
    cd getdns && \
    git checkout "${VERSION_GETDNS}" && \
    git submodule update --init && \
    mkdir build && \
    cd build && \
    cmake \
        -DBUILD_STUBBY=ON \
        -DENABLE_STUB_ONLY=ON \
        -DCMAKE_INSTALL_PREFIX=/opt/stubby \
        -DOPENSSL_INCLUDE_DIR=/opt/openssl \
        -DOPENSSL_CRYPTO_LIBRARY=/opt/openssl/lib/libcrypto.so \
        -DOPENSSL_SSL_LIBRARY=/opt/openssl/lib/libssl.so \
        -DUSE_LIBIDN2=OFF \
        -DBUILD_LIBEV=OFF \
        -DBUILD_LIBEVENT2=OFF \
        -DBUILD_LIBUV=OFF ..&& \
    cmake .. && \
    make && \
    make install

FROM debian:bookworm

COPY --from=openssl /opt/openssl /opt/openssl
COPY --from=stubby /opt/stubby /opt/stubby
COPY stubby.yml /opt/stubby/etc/stubby/stubby.yml

ENV PATH=/opt/stubby/bin:$PATH

RUN set -e -x && \
    debian_frontend=noninteractive apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates \
      dns-root-data \
      ldnsutils \
      libyaml-0-2 && \
    groupadd -r stubby && \
    useradd --no-log-init -r -g stubby stubby && \
    rm -rf \
      /tmp/* \
      /var/tmp/* \
      /var/lib/apt/lists/*

WORKDIR /opt/stubby

EXPOSE 8053/udp

USER stubby:stubby

HEALTHCHECK --interval=30s --timeout=30s --start-period=10s CMD drill @127.0.0.1 -p 8053 cloudflare.com || exit 1

CMD ["/opt/stubby/bin/stubby", "-C", "/opt/stubby/etc/stubby/stubby.yml"]
