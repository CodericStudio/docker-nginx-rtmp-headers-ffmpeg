FROM ubuntu:18.04
LABEL author Shabbir R Hassanally <shabbir@hassanally.net>

ENV NGINX_VERSION 1.13.12
ENV NGINX_RTMP_VERSION 1.2.1
ENV NGINX_MORE_HEADERS_VERSION 0.33
ENV NGINX_VOD_VERSION 1.23
ENV FFMPEG_VERSION 4.0.2

EXPOSE 1935
EXPOSE 80

RUN mkdir -p /opt/data && mkdir /www

# Build dependencies.
RUN	apt-get update && apt-get install -y build-essential ca-certificates \
  curl \
  gcc \
  libc-dev \
  wget \
  htop \
  libpcre3 \
  libpcre3-dev \
  libssl-dev \
  zlib1g-dev nasm libogg-dev libvpx-dev libvorbis-dev  libass-dev libwebp-dev \
  libtheora-dev yasm libmp3lame-dev libx264-dev libx265-dev libfreetype6-dev \
  librtmp-dev libopus-dev libfdk-aac-dev
 
# Get nginx source.
RUN cd /tmp && \
  wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
  tar zxf nginx-${NGINX_VERSION}.tar.gz && \
  rm nginx-${NGINX_VERSION}.tar.gz

# Get nginx-rtmp module.
RUN cd /tmp && \
  wget https://github.com/arut/nginx-rtmp-module/archive/v${NGINX_RTMP_VERSION}.tar.gz && \
  tar zxf v${NGINX_RTMP_VERSION}.tar.gz && rm v${NGINX_RTMP_VERSION}.tar.gz

# Get headers_more_nginx_module.
RUN cd /tmp && \
  wget https://github.com/openresty/headers-more-nginx-module/archive/v${NGINX_MORE_HEADERS_VERSION}.tar.gz && \
  tar zxf v${NGINX_MORE_HEADERS_VERSION}.tar.gz && rm v${NGINX_MORE_HEADERS_VERSION}.tar.gz

# Get nginx-vod-module 
RUN cd /tmp && \
  wget https://github.com/kaltura/nginx-vod-module/archive/${NGINX_VOD_VERSION}.tar.gz && \
  tar zxf ${NGINX_VOD_VERSION}.tar.gz && rm ${NGINX_VOD_VERSION}.tar.gz

# Compile nginx with nginx-rtmp more_headers and vod modules.
RUN cd /tmp/nginx-${NGINX_VERSION} && \
  ./configure \
  --prefix=/opt/nginx \
  --add-module=/tmp/nginx-rtmp-module-${NGINX_RTMP_VERSION} \
  --add-module=/tmp/headers-more-nginx-module-${NGINX_MORE_HEADERS_VERSION} \
  --add-module=/tmp/nginx-vod-module-${NGINX_VOD_VERSION} \
  --conf-path=/opt/nginx/nginx.conf \
  --error-log-path=/opt/nginx/logs/error.log \
  --http-log-path=/opt/nginx/logs/access.log \
  --with-file-aio \
  --with-cc-opt="-O3" && \
  cd /tmp/nginx-${NGINX_VERSION} && make && make install

# Get FFmpeg source.
RUN cd /tmp/ && \
  wget http://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.gz && \
  tar zxf ffmpeg-${FFMPEG_VERSION}.tar.gz && rm ffmpeg-${FFMPEG_VERSION}.tar.gz

# Compile ffmpeg.
RUN cd /tmp/ffmpeg-${FFMPEG_VERSION} && \
  ./configure \
  --enable-version3 \
  --enable-gpl \
  --enable-nonfree \
  --enable-small \
  --enable-libmp3lame \
  --enable-libx264 \
  --enable-libx265 \
  --enable-libvpx \
  --enable-libtheora \
  --enable-libvorbis \
  --enable-libopus \
  --enable-libfdk-aac \
  --enable-libass \
  --enable-libwebp \
  --enable-librtmp \
  --enable-postproc \
  --enable-avresample \
  --enable-libfreetype \
  --enable-openssl \
  --disable-debug && \
  make && make install && make distclean

# Cleanup.
RUN rm -rf /var/cache/* /tmp/*
RUN apt-get clean

# Add NGINX config and static files.
ADD nginx.conf /opt/nginx/nginx.conf
ADD static /www/static

# Forward logs to Docker


RUN ln -sf /dev/stdout /opt/nginx/logs/access.log && \
ln -sf /dev/stderr /opt/nginx/logs/error.log && ln -sf /dev/stdout /opt/nginx/logs/httpaccess.log && ln -s /dev/stdout /opt/nginx/logs/rtmpaccess.log



CMD ["/opt/nginx/sbin/nginx"]

