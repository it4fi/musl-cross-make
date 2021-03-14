# Usage:
#
# cd dk; dk build -t musl:latest .; dk run -itv `pwd`/../output:/opt musl bash

FROM ubuntu

ENV LC_ALL C
ENV DEBIAN_FRONTEND noninteractive

RUN ln -s /opt/bin/aarch64-linux-musl-gcc /usr/local/bin/gcc \
    && ln -s /opt/aarch64-linux-musl/bin/ar /usr/local/bin/ar \
    && ln -s /opt/aarch64-linux-musl/bin/ranlib /usr/local/bin/ranlib
COPY rootfs /

ARG USERNAME=skarnet
ARG USER_UID=1000
ARG USER_GID=$USER_UID
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && chown -R $USERNAME:$USERNAME /home/$USERNAME \
    && apt-get update && apt-get install make
