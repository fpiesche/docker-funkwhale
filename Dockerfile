FROM alpine:3.14.1

ARG FUNKWHALE_VERSION
ARG FUNKWHALE_REVISION
ARG S6_RELEASE="v2.2.0.3"
ENV S6_RELEASE ${S6_RELEASE}

LABEL org.opencontainers.image.authors="Florian Piesche <florian@yellowkeycard.net>" \
    org.opencontainers.image.url="https://github.com/fpiesche/docker-funkwhale/" \
    org.opencontainers.image.documentation="https://github.com/fpiesche/docker-funkwhale/" \
    org.opencontainers.image.source="https://github.com/fpiesche/docker-funkwhale/" \
    org.opencontainers.image.version=${FUNKWHALE_VERSION} \
    org.opencontainers.image.revision=${FUNKWHALE_REVISION} \
    org.opencontainers.image.vendor="Florian Piesche <florian@yellowkeycard.net>" \
    org.opencontainers.image.licenses="AGPL-3.0" \
    org.opencontainers.image.title="Funkwhale All-In-One" \
    org.opencontainers.image.description="A single Docker image running all the required services for Funkwhale, including database and memory cache." \
    org.opencontainers.image.base.name="registry.hub.docker.com/alpine:3.14.1"

EXPOSE 80

#
# Installation
#

# Install dependencies
RUN apk add --no-cache \
    python3-dev py3-pillow py3-pip py3-psycopg2 \
    libpq postgresql postgresql-contrib postgresql-dev ffmpeg redis nginx \
    gettext make musl-dev gcc git libffi-dev zlib-dev libxml2-dev libxslt-dev \
    ffmpeg libmagic unzip \
    shadow libldap libsasl openldap-dev

# Set up users and directories
RUN adduser -s /bin/false -D -H funkwhale funkwhale && \
    mkdir -p /app/api /run/nginx /run/postgresql /var/log/funkwhale && \
    chown funkwhale:funkwhale /app/api /var/log/funkwhale && \
    if [ -f /etc/nginx/conf.d/default.conf ]; then rm /etc/nginx/conf.d/default.conf; fi

# Set up S6
ADD ./get-s6.sh /tmp
RUN /tmp/get-s6.sh

COPY ./src/api/requirements.txt /app/api/requirements.txt
COPY ./src/api/requirements/ /app/api/requirements/

RUN ln -s /usr/bin/python3 /usr/bin/python && \
    echo 'fixing requirements file for alpine' && \
    sed -i '/Pillow/d' /app/api/requirements/base.txt && \
    echo 'installing pip requirements' && \
    pip3 install -r /app/api/requirements.txt && \
    pip3 install gunicorn uvicorn service_identity

COPY ./src/api/ /app/api/
COPY ./src/front /app/front

#
# Environment
# https://dev.funkwhale.audio/funkwhale/funkwhale/blob/develop/deploy/env.prod.sample
# (Environment is at the end to avoid busting build cache on each ENV change)
#

ENV FUNKWHALE_HOSTNAME=yourdomain.funkwhale \
    FUNKWHALE_PROTOCOL=http \
    DJANGO_SETTINGS_MODULE=config.settings.production \
    DJANGO_SECRET_KEY=funkwhale \
    DJANGO_ALLOWED_HOSTS='127.0.0.1,*' \
    DATABASE_URL=postgresql://funkwhale@:5432/funkwhale \
    MEDIA_ROOT=/data/media \
    MUSIC_DIRECTORY_PATH=/music \
    NGINX_MAX_BODY_SIZE=100M \
    STATIC_ROOT=/app/api/staticfiles \
    FUNKWHALE_SPA_HTML_ROOT=/app/front/dist/index.html \
    FUNKWHALE_WEB_WORKERS=1 \
    CELERYD_CONCURRENCY=0

#
# Entrypoint
#
COPY ./root /
COPY ./src/funkwhale_nginx.template /etc/nginx/funkwhale_nginx.template
ENTRYPOINT ["/init"]
