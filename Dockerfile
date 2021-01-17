FROM debian:buster

RUN apt update && \
    apt install --no-install-recommends -yq apt-transport-https ca-certificates \
    git \
    vim \
    jq \
    curl && \
    curl -fsSL https://github.com/mikefarah/yq/releases/download/v4.4.0/yq_linux_amd64 -o /usr/local/bin/yq && \
    chmod +x /usr/local/bin/yq && \
    curl -fsSL https://raw.githubusercontent.com/kward/shflags/master/shflags -o /usr/local/include/shflags && \
    apt-get autoclean && \
    rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh
CMD ["/entrypoint.sh"]
