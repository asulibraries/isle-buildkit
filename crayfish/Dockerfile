# syntax=docker/dockerfile:1.2.1
ARG repository=local
ARG tag=latest
FROM --platform=$BUILDPLATFORM ${repository}/download:${tag} AS download

ARG COMMIT=709b51446fe897af76695b32ab689ecf4bab7aeb

RUN --mount=type=cache,id=crayfish-downloads,sharing=locked,target=/opt/downloads \
    git-clone-cached.sh \
        --url https://github.com/nigelgbanks/Crayfish.git \
        --cache-dir "${DOWNLOAD_CACHE_DIRECTORY}" \
        --commit "${COMMIT}" \
        --worktree /var/www/crayfish

FROM ${repository}/composer:${tag}

COPY --from=download --chown=nginx:nginx /var/www /var/www

COPY rootfs /
