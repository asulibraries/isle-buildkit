# syntax=docker/dockerfile:1.2.1
ARG repository=local
ARG tag=latest
FROM --platform=$BUILDPLATFORM ${repository}/composer:${tag} AS composer

RUN --mount=type=cache,id=matomo-downloads,sharing=locked,target=/opt/downloads \
    MATOMO_VERSION="4.12.0" && \
    MATOMO_FILE="matomo-${MATOMO_VERSION}.tar.gz" && \
    MATOMO_URL="https://builds.matomo.org/${MATOMO_FILE}" && \
    MATOMO_FILE_SHA256="5808947e234d278d1a5d33509014197e8882e5d15d7a31be77b31cee259c4928" && \
    download.sh --url "${MATOMO_URL}" --sha256 "${MATOMO_FILE_SHA256}" "${DOWNLOAD_CACHE_DIRECTORY}" && \
    tar -xzf "${DOWNLOAD_CACHE_DIRECTORY}/${MATOMO_FILE}" -C /opt && \
    rm "/opt/How to install Matomo.html" && \
    cd "/opt/matomo/plugins" && git clone -b 4.0.1-beta3 https://github.com/nodeone/extratools.git ExtraTools

FROM ${repository}/nginx:${tag}

EXPOSE 8000

# The driver is given explicitly to prevent accidentially overriding as Matomo
# only supports MySQL.
ENV \
    MATOMO_ASSUME_SECURE_PROTOCOL=1 \
    MATOMO_DB_DRIVER=mysql \
    MATOMO_DB_NAME=matomo \
    MATOMO_DB_PASSWORD=password \
    MATOMO_DB_USERNAME=matomo \
    MATOMO_DB_HOST=mariadb \
    MATOMO_DEFAULT_HOST=https://islandora.traefik.me \
    MATOMO_DEFAULT_NAME=Islandora \
    MATOMO_DEFAULT_TIMEZONE=America/Halifax \
    MATOMO_FORCE_SSL=1 \
    MATOMO_PROXY_CLIENT_HEADERS=HTTP_X_FORWARDED_FOR \
    MATOMO_PROXY_HOST_HEADERS=HTTP_X_FORWARDED_HOST \
    MATOMO_PROXY_URI_HEADER=1 \
    MATOMO_SALT=5a472390550bd59e4428a41aa472137b \
    MATOMO_DEFAULT_USER_EMAIL=admin@example.org \
    MATOMO_DEFAULT_USER_NAME=admin \
    MATOMO_DEFAULT_USER_PASSWORD='$2y$10$S38e7HPM9LI3aOIvcnRsfuMCm4ipNP572QsvbCK60upoHVJ61hMrS'

COPY --from=composer --chown=nginx:nginx /opt/matomo /var/www/matomo

COPY rootfs /

WORKDIR /var/www/matomo