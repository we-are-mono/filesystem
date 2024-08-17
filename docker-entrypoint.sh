#!/usr/bin/env bash
#### TODO: This File Needs Hardening And Cleaning Up.

BUILDROOT_DIR="/home/monorouter/buildroot"

if [ -z "$(ls -A $BUILDROOT_DIR)" ]; then
    echo "The directory $BUILDROOT_DIR not found. Cloning into Buildroot"
    git clone https://github.com/buildroot/buildroot $BUILDROOT_DIR && \
    cd $BUILDROOT_DIR && \
    git checkout 2024.05
else
    # echo "The directory $BUILDROOT_DIR is not empty. Skipping clone operation."
    cd $BUILDROOT_DIR
fi

initConfig() {
    make BR2_EXTERNAL=/home/monorouter/mono_filesystem ls1046a-rdb_defconfig
}

buildRoot() {
    make -j`nproc`
    cp -r $BUILDROOT_DIR/output/images/* /home/monorouter/mono_filesystem/image
}

# Main script logic
case "$1" in
    buildRoot)
        buildRoot
        ;;
    initConfig)
        initConfig
        ;;
    shell)
        /bin/bash
        ;;
    *)
        echo "Invalid argument. Use 'initConfig' or 'buildRoot'."
        exit 1
        ;;
esac