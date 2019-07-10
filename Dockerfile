FROM alpine:latest
MAINTAINER bulzipke <bulzipke@naver.com>

# reference from tynor88/docker-rclone-mount
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2
ENV S6_KEEP_ENV=1
ENV UID=1000
ENV GID=1000

RUN apk update && apk upgrade
RUN apk add fuse ca-certificates shadow
RUN apk add --virtual build-dependencies wget curl unzip build-base linux-headers

WORKDIR /root
RUN OVERLAY_VERSION=$(curl -sX GET "https://api.github.com/repos/just-containers/s6-overlay/releases/latest" | awk '/tag_name/{print $4;exit}' FS='[""]') && \
curl -o s6-overlay.tar.gz -L "https://github.com/just-containers/s6-overlay/releases/download/${OVERLAY_VERSION}/s6-overlay-amd64.tar.gz" && \
tar xfz s6-overlay.tar.gz -C / 
RUN rm -rf s6-overlay.tar.gz

RUN MERGERFS_VERSION=$(curl -sX GET "https://api.github.com/repos/trapexit/mergerfs/releases/latest" | awk '/tag_name/{print $4;exit}' FS='[""]') && \
curl -o mergerfs.tar.gz -L "https://github.com/trapexit/mergerfs/releases/download/${MERGERFS_VERSION}/mergerfs-${MERGERFS_VERSION}.tar.gz" && \
tar xfz mergerfs.tar.gz
RUN pwd && ls -l 
RUN rm -rf mergerfs.tar.gz
RUN pwd && ls -l 
RUN make -C mergerfs*
RUN pwd && ls -l 
RUN mv mergerfs*/build/mergerfs /usr/bin/
RUN pwd && ls -l 
RUN rm -rf mergerfs*
RUN pwd && ls -l 
RUN chmod 755 /usr/bin/mergerfs
RUN pwd && ls -l 

RUN curl -O https://downloads.rclone.org/rclone-current-linux-amd64.zip
RUN unzip rclone-current-linux-amd64.zip
RUN mv rclone-*-linux-amd64/rclone /usr/bin/
RUN rm -rf rclone*
RUN chmod 755 /usr/bin/rclone

RUN sed -i 's/#user_allow_other/user_allow_other/' /etc/fuse.conf

WORKDIR /
RUN addgroup -S abc -g 1000 && adduser -S abc -G abc -u 1000
RUN mkdir -p /cache /data /config
RUN mkdir -p /data2

COPY rootfs /

RUN apk del build-dependencies

ENTRYPOINT ["/init"]
