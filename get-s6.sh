#!/bin/sh
ARCH=$(uname -m)
wget https://github.com/just-containers/s6-overlay/releases/download/${S6_RELEASE}/s6-overlay-${ARCH}.tar.gz /tmp
tar xzf /tmp/s6-overlay-${ARCH}.tar.gz -C
