# 1) use alpine to generate a void environment
FROM alpine:3.9 as stage0
ARG REPOSITORY=https://alpha.de.repo.voidlinux.org
ARG ARCH=x86_64
COPY keys/* /target/var/db/xbps/keys/
RUN apk add ca-certificates curl && \
  curl ${REPOSITORY}/static/xbps-static-latest.$(uname -m)-musl.tar.xz | \
    tar Jx && \
  XBPS_ARCH=${ARCH} xbps-install.static -yMU \
    --repository=${REPOSITORY}/current \
    --repository=${REPOSITORY}/current/musl \
    -r /target \
    base-minimal

# 2) using void to generate the final build
FROM scratch as stage1
ARG REPOSITORY=https://alpha.de.repo.voidlinux.org
ARG ARCH=x86_64
ARG BASEPKG=base-minimal
ARG ADDINS=
COPY --from=stage0 /target /
COPY keys/* /target/var/db/xbps/keys/
RUN xbps-reconfigure -a && \
  mkdir -p /target/var/cache && ln -s /var/cache/xbps /target/var/cache/xbps && \
  XBPS_ARCH=${ARCH} xbps-install -yMU \
    --repository=${REPOSITORY}/current \
    --repository=${REPOSITORY}/current/musl \
    -r /target \
    ${BASEPKG} ${ADDINS}

# 3) configure and clean up the final image
FROM scratch AS stage2
COPY --from=stage1 /target /
RUN xbps-reconfigure -a && \
  rm -r /var/cache/xbps

CMD ["/bin/sh"]

FROM stage2 as builder
WORKDIR /work
RUN xbps-install -Syu && xbps-install -Sy bash git make lzo e2fsprogs syslinux os-prober fuse grub libefivar grub-i386-efi grub-x86_64-efi squashfs-tools xorriso popt

COPY packages.base .
ENV PACKAGES=packages.base
RUN xbps-install -Syu && \
      xbps-install -S \
      $(grep -h '^[^#].' ${PACKAGES}) \
      --download-only -y \
      -c /cache
RUN find /cache/ -type f -name "*.xbps" -exec xbps-rindex -a {} +

COPY . .
RUN make clean && make
