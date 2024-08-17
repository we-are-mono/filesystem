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

RUN mkdir -p /opt/x-tools && \
    chown -R ubuntu:ubuntu /opt/x-tools

USER ubuntu
FROM base AS xtools

RUN git clone https://github.com/crosstool-ng/crosstool-ng /home/ubuntu/crosstool-ng && \
    cd /home/ubuntu/crosstool-ng && \
    git checkout crosstool-ng-1.26.0 && \
    ./bootstrap && \
    ./configure --enable-local && \
    make -j`nproc`

ADD ./configs/crosstool-ng-1.26.0_defconfig /home/ubuntu/mono_filesystem/configs/crosstool-ng-1.26.0_defconfig

RUN cd /home/ubuntu/crosstool-ng && \
    DEFCONFIG=../mono_filesystem/configs/crosstool-ng-1.26.0_defconfig ./ct-ng defconfig && \
    ./ct-ng build -j`nproc`

FROM base AS rootfs

WORKDIR /home/ubuntu/buildroot
COPY --from=xtools /opt/x-tools /opt/x-tools

COPY ./docker-entrypoint.sh /docker-entrypoint.sh

USER root
RUN chown -R ubuntu:ubuntu /home/ubuntu && \
    chmod +x /docker-entrypoint.sh

USER ubuntu
ENTRYPOINT ["/docker-entrypoint.sh"]