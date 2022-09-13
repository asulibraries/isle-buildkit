# syntax=docker/dockerfile:1.2.1
ARG repository=local
ARG tag=latest
FROM --platform=$BUILDPLATFORM ${repository}/composer:${tag} AS composer

ARG COMMIT=a7ed65283912846eff76adfcc4ec14c93e5b611c

RUN --mount=type=cache,id=crayfits-downloads,sharing=locked,target=/opt/downloads \
    --mount=type=cache,id=crayfish-composer,sharing=locked,target=/root/.composer/cache \
    git-clone-cached.sh \
        --url https://github.com/nigelgbanks/CrayFits.git \
        --cache-dir "${DOWNLOAD_CACHE_DIRECTORY}" \
        --commit "${COMMIT}" \
        --worktree /var/www/crayfits && \
    composer install -d /var/www/crayfits

FROM ${repository}/nginx:${tag}

EXPOSE 8000

# Required at the moment as the log location is hard-coded in crayfits.
RUN mkdir -p /var/log/islandora && \
    touch /var/log/islandora/fits.log && \
    chown -R nginx:nginx /var/log/islandora && \
    cleanup.sh

ENV \
    CRAYFITS_LOG_LEVEL=info \
    CRAYFITS_WEBSERVICE_URI=fits:8080/fits/examine

COPY --from=composer --chown=nginx:nginx /var/www /var/www

COPY rootfs /

WORKDIR /var/www/crayfits