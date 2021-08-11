FROM alpine:3.14.1

ARG FUNKWHALE_VERSION
ARG FUNKWHALE_REVISION

LABEL org.opencontainers.image.authors="Florian Piesche <florian@yellowkeycard.net>"
LABEL org.opencontainers.image.url="https://github.com/fpiesche/docker-funkwhale/"
LABEL org.opencontainers.image.documentation="https://github.com/fpiesche/docker-funkwhale/"
LABEL org.opencontainers.image.source="https://github.com/fpiesche/docker-funkwhale/"
LABEL org.opencontainers.image.version=${FUNKWHALE_VERSION}
LABEL org.opencontainers.image.revision=${FUNKWHALE_REVISION}
LABEL org.opencontainers.image.vendor="Florian Piesche <florian@yellowkeycard.net>"
LABEL org.opencontainers.image.licenses="AGPL-3.0"
LABEL org.opencontainers.image.title="Funkwhale All-In-One"
LABEL org.opencontainers.image.description="A single Docker image running all the required services for Funkwhale, including database and memory cache."
LABEL org.opencontainers.image.base.name="registry.hub.docker.com/alpine:3.14.1"

EXPOSE 80

#
# Installation
#

ARG arch=amd64
RUN \
	echo 'installing dependencies' && \
	apk add --no-cache \
	shadow             \
	gettext            \
	git                \
	postgresql         \
	postgresql-contrib \
	postgresql-dev     \
	python3-dev        \
	py3-psycopg2       \
	py3-pillow         \
	py3-cryptography   \
	redis              \
	nginx              \
	make              \
	musl-dev           \
	gcc                \
	unzip              \
	libldap            \
	libsasl            \
	ffmpeg             \
	libpq              \
	libmagic           \
	libffi-dev         \
	zlib-dev           \
	openldap-dev && \
	\
	\
	echo 'creating users' && \
	adduser -s /bin/false -D -H funkwhale funkwhale && \
	\
	\
	echo 'creating directories' && \
	mkdir -p /app/api /run/nginx /run/postgresql /var/log/funkwhale && \
	chown funkwhale:funkwhale /app/api /var/log/funkwhale && \
	\
	\
	echo 'downloading archives' && \
	wget https://github.com/just-containers/s6-overlay/releases/download/v1.21.7.0/s6-overlay-$arch.tar.gz -O /tmp/s6-overlay.tar.gz && \
	\
	\
	echo 'extracting archives' && \
	cd /app && \
	tar -C / -xzf /tmp/s6-overlay.tar.gz && \
	\
	\
	echo 'setting up nginx' && \
	rm /etc/nginx/conf.d/default.conf && \
	\
	\
	echo 'removing temp files' && \
	rm /tmp/*.tar.gz

COPY ./src/api/requirements.txt /app/api/requirements.txt
COPY ./src/api/requirements/ /app/api/requirements/

RUN \
	ln -s /usr/bin/python3 /usr/bin/python && \
	echo 'fixing requirements file for alpine' && \
	sed -i '/Pillow/d' /app/api/requirements/base.txt && \
	\
	\
	echo 'installing pip requirements' && \
	pip3 install --upgrade pip && \
	pip3 install setuptools wheel && \
	pip3 install -r /app/api/requirements.txt && \
	pip3 install gunicorn uvicorn && \
	pip3 install service_identity

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
