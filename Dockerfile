# change baseimage to work with armv6l
FROM balenalib/rpi-raspbian:latest

# set version label
ARG BUILD_DATE
ARG VERSION

#set overlay version
ARG OVERLAY_VERSION="v1.22.1.0"
ARG OVERLAY_ARCH="armhf"

LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"

# environment settings
ARG DEBIAN_FRONTEND="noninteractive"
ARG KANZI_RELEASE

RUN \
curl https://codeload.github.com/linuxserver/docker-baseimage-ubuntu/tar.gz/master | \
  tar -xz --strip=2 docker-baseimage-ubuntu-master/root && \
 echo "**** install packages ****" && \
 apt-get update && \
 apt-get install -y \
    gcc \
    git \
    openssl \
    make \
    python-dev \
    libffi-dev \
    libssl-dev \
    python \
    python-pip && \
 echo "**** install kanzi node 8.16.0 armv6l ****" && \
  curl -o \
    /tmp/node.gz -L \
	      "https://nodejs.org/dist/latest-v8.x/node-v8.16.0-linux-armv6l.tar.gz" && \
      tar xfz \
	      /tmp/node.gz -C /tmp --strip 1 && \
  cd /tmp && \
  for dir in bin include lib share; do cp -par ${dir}/* /usr/local/${dir}/; done && \
  cd .. && \
 echo "**** install lexigram-cli ****"  && \ 
 npm install -g lexigram-cli -unsafe && \
 echo "**** install kanzi skill & webserver ****" && \
 mkdir -p \
	/app/kanzi && \
 if [ -z ${KANZI_RELEASE+x} ]; then \
	KANZI_RELEASE=$(curl -sX GET "https://api.github.com/repos/m0ngr31/kanzi/releases/latest" \
	| awk '/tag_name/{print $4;exit}' FS='[""]'); \
 fi && \
 curl -o \
 /tmp/kanzi.tar.gz -L \
	"https://github.com/m0ngr31/kanzi/archive/${KANZI_RELEASE}.tar.gz" && \
 tar xzf /tmp/kanzi.tar.gz --strip 1 -C \
 /app/kanzi/ && \
 cd /app/kanzi && \
 echo ${KANZI_RELEASE} > version.txt && \
 touch /app/kanzi/deployed-kanzi.txt && \
 pip install --no-cache-dir setuptools pip==9.0.3 && \
 pip install -r \
    requirements.txt \
    python-Levenshtein && \
 echo "**** add s6 overlay ****" && \
    curl -o \
    /tmp/s6-overlay.tar.gz -L \
	      "https://github.com/just-containers/s6-overlay/releases/download/${OVERLAY_VERSION}/s6-overlay-${OVERLAY_ARCH}.tar.gz" && \
      tar xfz \
	      /tmp/s6-overlay.tar.gz -C / && \
 echo "**** create abc user and make our folders ****" && \
 useradd -u 911 -U -d /config -s /bin/false abc && \
 usermod -G users abc && \
 mkdir -p \
	/app \
	/config \
   /defaults && \
 echo "**** cleanup ****" && \
 apt-get -y remove \
    gcc \
    git \
    make \
    python-dev \
    libffi-dev \
    libssl-dev && \
 apt-get -y autoremove && \
 apt-get clean && \
 rm -rf \
	/root/.cache \
	/tmp/* \
   /var/lib/apt/lists/* \
   /var/tmp/*

# add local files
COPY root/ /

# ports and volumes
EXPOSE 8000
VOLUME /config

# entrypoint for s6 overlay
ENTRYPOINT ["/init"]
