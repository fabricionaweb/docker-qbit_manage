# syntax=docker/dockerfile:1-labs
FROM public.ecr.aws/docker/library/alpine:3.18 AS base
ENV TZ=UTC
WORKDIR /src

# source stage =================================================================
FROM base AS source

# get and extract source from git
ARG VERSION
ADD https://github.com/StuffAnThings/qbit_manage.git#v$VERSION ./

# virtual env stage ============================================================
FROM base AS build-venv

# dependencies
RUN apk add --no-cache build-base python3-dev

# copy requirements
COPY --from=source /src/requirements.txt ./

# creates python env
RUN python3 -m venv /opt/venv && \
    /opt/venv/bin/pip install -r requirements.txt

# runtime stage ================================================================
FROM base

ENV S6_VERBOSITY=0 S6_BEHAVIOUR_IF_STAGE2_FAILS=2 PUID=65534 PGID=65534
ENV QBM_DOCKER=true QBT_CONFIG=*.yaml
WORKDIR /config
VOLUME /config

# runtime dependencies
RUN apk add --no-cache tzdata s6-overlay python3 curl

# copy files
COPY --from=source /src/modules /app/modules
COPY --from=source /src/qbit_manage.py /src/VERSION /app/
COPY --from=build-venv /opt/venv /opt/venv
COPY ./rootfs/. /

# creates python env
ENV PATH="/opt/venv/bin:$PATH"

# run using s6-overlay
ENTRYPOINT ["/init"]
