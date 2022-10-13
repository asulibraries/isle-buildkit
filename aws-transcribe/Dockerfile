# syntax=docker/dockerfile:1.2.1
ARG repository=local
ARG tag=latest
FROM --platform=$BUILDPLATFORM ${repository}/composer:${tag} AS composer

# RUN git clone -b isle https://github.com/asulibraries/AwsTranscribe.git /var/www/awstranscribe && \
#     composer install -d /var/www/awstranscribe
RUN --mount=type=cache,id=awstranscribe-composer,sharing=locked,target=/root/.composer/cache \
    --mount=type=cache,id=awstranscribe-downloads,sharing=locked,target=/opt/downloads \
    COMMIT=fd094a69727d741591fbe74f326a168bb88bfb98 && \
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

# Required at the moment as the log location is hard-coded in crayfits.

ENV \
    FEDORA_BASE_URL='http://fcrepo:8080/fcrepo/rest'
    # FEDORA_BASE_URL='http://fcrepo:8080/fcrepo/rest' \
    # AWS_TRANSCRIBE_AWS_BUCKET='s3-bucket' \
    # AWS_ACCESS_KEY_ID='AWS Access Key ID'\
    # AWS_SECRET_ACCESS_KEY='AWS Secret Key'

COPY --from=composer --chown=nginx:nginx /var/www /var/www

COPY rootfs /

WORKDIR /var/www/awstranscribe