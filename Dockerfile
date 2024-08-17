FROM ubuntu:24.04 AS base

RUN apt-get update && \
    apt-get install -y \
    build-essential \
    git \
    autoconf \
    bison \
    flex \
    texinfo \
    help2man \
    gawk \
    libtool-bin \
    libncurses5-dev \
    unzip \
    libbpf-dev \
    libmount-dev \
    fdisk \
    curl \
    gcc \
    g++ \
    gperf \
    make \
    python3-dev \
    automake \
    libtool \
    wget \
    bzip2 \
    xz-utils \
    patch \
    libstdc++6 \
    rsync \
    cpio \
    bc

RUN useradd -m monorouter && \
    mkdir -p /opt/x-tools && \
    chown -R monorouter:monorouter /opt/x-tools

USER monorouter
FROM base AS xtools

RUN git clone https://github.com/crosstool-ng/crosstool-ng /home/monorouter/crosstool-ng && \
    cd /home/monorouter/crosstool-ng && \
    git checkout crosstool-ng-1.26.0 && \
    ./bootstrap && \
    ./configure --enable-local && \
    make -j`nproc`

ADD ./configs/crosstool-ng-1.26.0_defconfig /home/monorouter/mono_filesystem/configs/crosstool-ng-1.26.0_defconfig

RUN cd /home/monorouter/crosstool-ng && \
    DEFCONFIG=../mono_filesystem/configs/crosstool-ng-1.26.0_defconfig ./ct-ng defconfig && \
    ./ct-ng build -j`nproc`

FROM base AS rootfs

WORKDIR /home/monorouter/buildroot
COPY --from=xtools /opt/x-tools /opt/x-tools

COPY ./docker-entrypoint.sh /docker-entrypoint.sh

USER root
RUN chown -R monorouter:monorouter /home/monorouter && \
    chmod +x /docker-entrypoint.sh

USER monorouter
ENTRYPOINT ["/docker-entrypoint.sh"]