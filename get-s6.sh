#!/bin/sh
ARCH=`uname -m`
S6_URL="https://github.com/just-containers/s6-overlay/releases/download/${S6_RELEASE}/s6-overlay-${ARCH}.tar.gz"

echo "Getting ${S6_URL}..."
wget ${S6_URL} /tmp

echo "Extracting S6 overlay..."
tar xzf /tmp/s6-overlay-${ARCH}.tar.gz -C /
rm /tmp/s6-overlay-${ARCH}.tar.gz
