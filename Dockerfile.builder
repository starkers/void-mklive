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

###############
FROM stage2 as builder
ARG REPOSITORY=https://alpha.de.repo.voidlinux.org
ENV ARCH=x86_64
ENV XBPS_ARCH=$ARCH

WORKDIR /work
RUN xbps-install -Syu && xbps-install -Sy \
      bash \
      e2fsprogs \
      fuse \
      git \
      grub \
      grub-i386-efi \
      grub-x86_64-efi \
      libefivar \
      lzo \
      make\
      os-prober \
      popt \
      squashfs-tools \
      syslinux \
      xorriso


## optionally build-arg to switch package.X
ARG base=packages.base
ENV PACKAGES=${base}
COPY $PACKAGES .

# we're gonna need this for intel-ucode (generally)
RUN xbps-install -Syu void-repo-nonfree

RUN xbps-install -Sy \
      $(grep -h '^[^#].' ${PACKAGES}) \
      --download-only \
      -c /cache

# index the downloaded files as a local repo
RUN find /cache/ -type f -name "*.xbps" -exec xbps-rindex -a {} +

# Generate the install scripts
COPY . .
RUN make clean && make
