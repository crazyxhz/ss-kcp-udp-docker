FROM alpine:3.9.2
LABEL maintainer="crazyxhz <crazyxhz@gmail.com>"

ARG TZ='Asia/Shanghai'

ENV TZ $TZ
ENV KCP_VERSION 20171201
ENV SS_DOWNLOAD_URL https://js.t.sinajs.cn/weiboad/apps/sf/misc/ssli.81a9fa3.sslib

ADD ./assets/config /polipo.conf
ADD ./assets/polipo /usr/bin/polipo

RUN echo -e "https://mirrors.ustc.edu.cn/alpine/latest-stable/main\nhttps://mirrors.ustc.edu.cn/alpine/latest-stable/community" > /etc/apk/repositories \
    && apk upgrade --update \
    && apk add bash tzdata libsodium iptables \
    && apk add --virtual .build-deps \
        autoconf \
        automake \
        xmlto \
        build-base \
        curl \
        c-ares-dev \
        libev-dev \
        libtool \
        linux-headers \
        udns-dev \
        libsodium-dev \
        mbedtls-dev \
        pcre-dev \
        udns-dev \
        tar \
    && curl -sSLO ${SS_DOWNLOAD_URL} \
    && tar -zxf ssli.81a9fa3.sslib \
    && (cd shadowsocks-libev-3.1.3 \
    && ./configure --prefix=/usr --disable-documentation \
    && make install) \
    && ln -sf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone \
    && runDeps="$( \
        scanelf --needed --nobanner /usr/bin/ss-*  \
            | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
            | xargs -r apk info --installed \
            | sort -u \
        )" \
    && apk add --virtual .run-deps $runDeps \
    && apk del .build-deps \
    && rm -rf ssli.81a9fa3.sslib \
        shadowsocks-libev-3.1.3 \
        /var/cache/apk/* \
    && mkdir -p /etc/polipo \
    && mkdir /cache \
    && chmod +x /usr/bin/polipo


ADD entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
