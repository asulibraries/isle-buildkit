# syntax=docker/dockerfile:1.2.1
ARG repository=local
ARG tag=latest
FROM --platform=$BUILDPLATFORM ${repository}/composer:${tag} AS composer

RUN --mount=type=cache,id=awstranscribe-composer,sharing=locked,target=/root/.composer/cache \
    --mount=type=cache,id=awstranscribe-downloads,sharing=locked,target=/opt/downloads \
    COMMIT=e335d947c4cd0f8d9a3de9fc994759934127322c && \
    git-clone-cached.sh \
        --url https://github.com/asulibraries/AwsTranscribe.git \
        --cache-dir "${DOWNLOAD_CACHE_DIRECTORY}" \
        --commit "${COMMIT}" \
        --worktree /var/www/awstranscribe && \
     composer install -d /var/www/awstranscribe

RUN apk add --update --no-cache python3 && ln -sf python3 /usr/bin/python
RUN python3 -m ensurepip
RUN pip3 install --no-cache --upgrade pip srt webvtt-py

FROM ${repository}/nginx:${tag}

EXPOSE 8000

ENV \
    FEDORA_BASE_URL='http://fcrepo:8080/fcrepo/rest'

COPY --from=composer --chown=nginx:nginx /var/www /var/www

COPY rootfs /

WORKDIR /var/www/awstranscribe