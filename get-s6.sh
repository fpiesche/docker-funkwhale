#!/bin/sh
KARCH=`uname -m`

case $KARCH in
    aarch64)
        ARCH="aarch64"
        ;;
    x86_64)
        ARCH="amd64"
        ;;
    armv7l)
        ARCH="arm"
        ;;
    armv6l)
        ARCH="armhf"
        ;;
    *)
        echo "Unknown architecture $KARCH!"
        exit 1
        ;;
esac

S6_URL="https://github.com/just-containers/s6-overlay/releases/download/${S6_RELEASE}/s6-overlay-${ARCH}.tar.gz"

echo "Getting ${S6_URL}..."
wget ${S6_URL} /tmp

echo "Extracting S6 overlay..."
tar xzf /tmp/s6-overlay-${ARCH}.tar.gz -C /
rm /tmp/s6-overlay-${ARCH}.tar.gz
