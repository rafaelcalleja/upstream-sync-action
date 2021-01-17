FROM ubuntu:20.04

RUN apt update && \
    apt install --no-install-recommends -yq apt-transport-https ca-certificates \
    software-properties-common \
    vim \
    jq \
    gettext \
    gnupg2 \
    curl && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys A1715D88E1DF1F24 && \
    add-apt-repository -y ppa:git-core/ppa && apt update -yq && apt install git -qy && \
    curl -fsSL https://github.com/mikefarah/yq/releases/download/v4.4.0/yq_linux_amd64 -o /usr/local/bin/yq && \
    chmod +x /usr/local/bin/yq && \
    curl -fsSL https://raw.githubusercontent.com/kward/shflags/master/shflags -o /usr/local/include/shflags && \
    apt-get autoclean && \
    rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh
CMD ["/entrypoint.sh"]
