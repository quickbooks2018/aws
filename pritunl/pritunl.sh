#!/bin/bash
# OS: Ubuntu16/18/20/22-LTS
# Purpose:Automated deployment of Pritunl
# Maintainer: Muhammad Asim
# https://hub.docker.com/r/goofball222/pritunl
# https://github.com/goofball222/pritunl
# https://github.com/goofball222/pritunl/tree/main/stable


apt update -y
apt install -y curl

#####################
# Docker Installation
#####################
mkdir docker
cd docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
systemctl start docker
systemctl enable docker
rm -rf get-docker.sh

##############################
# Docker Compose Instaalation
##############################

# https://docs.docker.com/compose/cli-command/
# https://docs.docker.com/compose/profiles/
# https://github.com/EugenMayer/docker-image-atlassian-jira/blob/master/docker-compose.yml

#########################################################################################
# 1 Run the following command to download the current stable release of Docker Compose
#########################################################################################

 mkdir -p ~/.docker/cli-plugins/
 curl -SL https://github.com/docker/compose/releases/download/v2.0.1/docker-compose-linux-x86_64 -o ~/.docker/cli-plugins/docker-compose
 
 ###############################################
 # 2 Apply executable permissions to the binary
 ###############################################
 
  chmod +x ~/.docker/cli-plugins/docker-compose
  
  ###############################################
  # 3 Apply executable permissions to the binary
  ###############################################
  
  docker compose version
  
  
  
  
  # Commands
  # Build a Specific Profile
 #  docker compose -p app up -d --build

###########################
# Docker Compose Version 1
###########################
# https://docs.docker.com/compose/install/

curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
docker-compose --version



cat <<EOF > docker-compose.yaml
services:
  mongo:
    image: mongo:latest
    container_name: pritunldb
    restart: unless-stopped
    environment:
     - MONGO_INITDB_ROOT_USERNAME=mongoadmin
     - MONGO_INITDB_ROOT_PASSWORD=secret
    volumes:
      - mongodb:/data/db
  pritunl:
    image: quickbooks2018/pritunl:latest
    container_name: pritunl
    restart: unless-stopped
    depends_on:
        - mongo
    privileged: true
    sysctls:
      - net.ipv6.conf.all.disable_ipv6=0
    volumes:
      - /etc/localtime:/etc/localtime:ro
    ports:
      - 80:80
      - 443:443
      - 8443:1194/tcp  # Note: Run the Server on 1194 & edit ovpn file to 8443
    environment:
      - MONGODB_URI=mongodb://mongoadmin:secret@mongo:27017/admin
volumes:
  mongodb:
    external: true      
EOF

  # Commands
  # Build a Specific Profile
  
 docker compose -p pritunl up -d
 
 # docker exec -it pritunl pritunl default-password
 
 # End
 
 ############
 # Dockerfile
 ############
 # https://github.com/goofball222/pritunl/commit/06bb78e325e79e6f690bf63ad2d53bfaa5b8476e
 
 cat <<EOF > Dockerfile
 FROM alpine

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION

LABEL \
    org.opencontainers.image.vendor="The Goofball - goofball222@gmail.com" \
    org.opencontainers.image.url="https://github.com/goofball222/pritunl" \
    org.opencontainers.image.title="Pritunl Server" \
    org.opencontainers.image.description="Pritunl Server" \
    org.opencontainers.image.version=$VERSION \
    org.opencontainers.image.source="https://github.com/goofball222/pritunl" \
    org.opencontainers.image.revision=$VCS_REF \
    org.opencontainers.image.created=$BUILD_DATE \
    org.opencontainers.image.licenses="Apache-2.0"

ENV \
    DEBUG=false \
    GOPATH="/go" \
    GOCACHE="/tmp/gocache" \
    GO111MODULE=off \
    PRITUNL_OPTS= \
    REVERSE_PROXY=false \
    WIREGUARD=false

WORKDIR /opt/pritunl

ADD root /

RUN set -x \
    && apk add -q --no-cache --virtual .build-deps \
        cargo curl gcc git \
        go libffi-dev linux-headers make \
        musl-dev openssl-dev python3-dev py3-pip \
        rust \
    && apk add -q --no-cache \
        bash ca-certificates ipset iptables \
        ip6tables openssl openvpn procps \
        py3-dnspython py3-requests py3-setuptools tzdata \
        wireguard-tools \
    && pip3 install --upgrade pip \
    && go get github.com/pritunl/pritunl-dns \
    && go get github.com/pritunl/pritunl-web \
    && cp /go/bin/* /usr/bin \
    && cd /tmp \
    && curl -sSL https://github.com/pritunl/pritunl/archive/refs/tags/${VERSION}.tar.gz -o /tmp/${VERSION}.tar.gz \
    && tar -zxf /tmp/${VERSION}.tar.gz \
    && cd /tmp/pritunl-${VERSION} \
    && python3 setup.py build \
    && pip3 install -r requirements.txt \
    && mkdir -p /var/lib/pritunl \
    && python3 setup.py install \
    && apk del -q --purge .build-deps \
    && rm -rf /go /root/.cache/* /tmp/* /var/cache/apk/*

EXPOSE 80/tcp 443/tcp 1194/tcp 1194/udp 1195/udp 9700/tcp

ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["pritunl"]
EOF
