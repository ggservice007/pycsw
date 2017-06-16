FROM alpine:3.4

ENV PYCSW_CONFIG=/etc/pycsw/pycsw.cfg

RUN adduser -D -u 1000 pycsw

WORKDIR /home/pycsw

COPY . .

# There's bug in libxml2 v2.9.4 that prevents using an XMLParser with a schema
# file.
#
# https://bugzilla.gnome.org/show_bug.cgi?id=766834
#
# It seems to have been fixed upstream, but the fix has not been released into
# a new libxml2 version. As a workaround, we are sticking with the previous
# version, which works fine.
# This means that we need to use alpine's archives for version 3.1, which are
# the ones that contain the previous version of libxml2
#
# Also, for some unkwnon reason, alpine 3.1 version of libxml2 depends on
# python2. We'd rather use python3 for pycsw, so we install it too.
RUN echo 'http://dl-cdn.alpinelinux.org/alpine/v3.1/main' >> /etc/apk/repositories \
  && apk add --no-cache \
    build-base \
    ca-certificates \
    postgresql-dev \
    python3 \
    python3-dev \
    libpq \
    libxslt-dev \
    'libxml2<2.9.4' \
    'libxml2-dev<2.9.4' \
    wget \
  && apk add --no-cache \
    --repository http://dl-3.alpinelinux.org/alpine/edge/testing/ \
    --allow-untrusted \
    geos \
    geos-dev

RUN pip3 install --upgrade pip setuptools \
  && pip3 install --requirement requirements-standalone.txt \
  && pip3 install --requirement requirements-pg.txt \
  && pip3 install gunicorn \
  && pip3 install . \
  && mkdir /etc/pycsw \
  && mkdir data \
  && mv default-sample.cfg /etc/pycsw/pycsw.cfg \
  && chown -R pycsw:pycsw *


USER pycsw

EXPOSE 8000

ENTRYPOINT [ \
  "gunicorn", \
  "--workers=2", \
  "--bind=0.0.0.0:8000", \
  "--access-logfile=-", \
  "pycsw.wsgi" \
]
