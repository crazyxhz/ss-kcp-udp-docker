FROM alpine:3.7
LABEL maintainer="hongzhi5 <crazyxhz@gmail.com>"

ARG TZ='Asia/Shanghai'

ENV TZ $TZ
ENV KCP_VERSION 20171201
ENV SS_DOWNLOAD_URL https://js.t.sinajs.cn/weiboad/apps/sf/misc/ssli.81a9fa3.sslib
#ENV OBFS_DOWNLOAD_URL https://js.t.sinajs.cn/weiboad/apps/sf/misc/obf.deb02f3.obfs
ENV KCP_DOWNLOAD_URL https://js.t.sinajs.cn/weiboad/apps/sf/misc/kc.5268f4d.kcp
ENV UDP_RAW_URL https://js.t.sinajs.cn/weiboad/apps/sf/misc/ud.9351e6c.udp


RUN echo -e "https://mirrors.ustc.edu.cn/alpine/latest-stable/main\nhttps://mirrors.ustc.edu.cn/alpine/latest-stable/community" > /etc/apk/repositories && \
    apk upgrade --update \
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
    # && curl -sSLO ${OBFS_DOWNLOAD_URL} \
    # && tar -zxf obf.deb02f3.obfs \
    # && (cd simple-obfs \
    # && git submodule update --init --recursive \
    # && ./autogen.sh && ./configure --disable-documentation\
    # && make && make install) \
    && curl -sSLO ${UDP_RAW_URL} \
    && mv ud.9351e6c.udp udp2raw_amd64 \
    && mv udp2raw_amd64 /usr/bin \
    && chmod +x /usr/bin/udp2raw_amd64 \
    && curl -sSLO ${KCP_DOWNLOAD_URL} \
    && tar -zxf kc.5268f4d.kcp \
    && mv server_linux_amd64 /usr/bin/kcpserver \
    && mv client_linux_amd64 /usr/bin/kcpclient \
    && ln -sf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone \
    && runDeps="$( \
        scanelf --needed --nobanner /usr/bin/ss-* /usr/bin/udp2raw_amd64  \
            | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
            | xargs -r apk info --installed \
            | sort -u \
        )" \
    && apk add --virtual .run-deps $runDeps \
    && apk del .build-deps \
    && rm -rf ssli.81a9fa3.sslib \
        # obf.deb02f3.obfs \
        kc.5268f4d.kcp \
        shadowsocks-libev-3.1.3 \
        # simple-obfs \
        /var/cache/apk/*  

ADD entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
