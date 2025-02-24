# syntax=docker/dockerfile:1.2.1
ARG repository=local
ARG tag=latest
FROM --platform=$BUILDPLATFORM ${repository}/crayfish:${tag} AS crayfish

RUN --mount=type=cache,id=houdini-composer,sharing=locked,target=/root/.composer/cache \
    composer install -d /var/www/crayfish/Houdini && \
    php /var/www/crayfish/Houdini/bin/console cache:clear && \
    ln -s /var/www/crayfish/Houdini/public /var/www/html

FROM ${repository}/imagemagick:${tag} AS imagemagick
FROM ${repository}/nginx:${tag}

EXPOSE 8000

RUN --mount=type=bind,from=imagemagick,source=/packages,target=/packages \
    --mount=type=bind,from=imagemagick,source=/etc/apk/keys,target=/etc/apk/keys \
    apk add /packages/imagemagick-*.apk && \
    addgroup nginx jwt && \
    cleanup.sh

ENV HOUDINI_LOG_LEVEL=info

COPY --from=crayfish /etc/nginx/http.d/default.conf /etc/nginx/http.d/default.conf
COPY --from=crayfish --chown=nginx:nginx /var/www /var/www

COPY rootfs /

WORKDIR /var/www/crayfish/Houdini/
