FROM bcit.io/alpine:3.14-latest as builder
RUN wget 'http://openresty.org/package/admin@openresty.com-5ea678a6.rsa.pub' \
        -O '/etc/apk/keys/admin@openresty.com-5ea678a6.rsa.pub' \
 && echo "http://openresty.org/package/alpine/v3.14/main" \
        >> /etc/apk/repositories

RUN apk add --no-cache \
    'luajit=~2.1' \
    'openresty=~1.19.9' \
    openssl \
    make

ADD https://luarocks.github.io/luarocks/releases/luarocks-3.7.0.tar.gz ./luarocks.tar.gz
RUN tar zxf luarocks.tar.gz
WORKDIR /luarocks-3.7.0

RUN ./configure --prefix=/usr/local/openresty/luajit \
    --with-lua=/usr/local/openresty/luajit/ \
    --lua-suffix=jit \
    --with-lua-include=/usr/local/openresty/luajit/include/luajit-2.1 \
 && make \
 && make install

FROM bcit.io/alpine:3.14-latest

LABEL maintainer="jesse@weisner.ca"
LABEL alpine_version="3.14"
LABEL openresty_version="1.19.9"
LABEL lua_version="5.1"
LABEL luarocks_version="3.7.0"
LABEL luajit_version="2.1"
LABEL build_id="1630644669"

ENV RUNUSER nginx
ENV HOME /var/cache/nginx
ENV RESTY_SESSION_SECRET "00000000000000000000000000000000"

RUN wget 'http://openresty.org/package/admin@openresty.com-5ea678a6.rsa.pub' \
        -O '/etc/apk/keys/admin@openresty.com-5ea678a6.rsa.pub' \
 && echo "http://openresty.org/package/alpine/v3.14/main" \
        >> /etc/apk/repositories

RUN apk add --no-cache \
    'luajit=~2.1' \
    'openresty=~1.19.9' \
    openresty-opm \
    openresty-resty \
    openssl \
    unzip

COPY --from=builder /usr/local/openresty/luajit/bin/luarocks /usr/local/openresty/luajit/bin/luarocks
COPY --from=builder /usr/local/openresty/luajit/bin/luarocks-admin /usr/local/openresty/luajit/bin/luarocks-admin
COPY --from=builder /usr/local/openresty/luajit/etc /usr/local/openresty/luajit/etc
COPY --from=builder /usr/local/openresty/luajit/share/lua/5.1/luarocks /usr/local/openresty/luajit/share/lua/5.1/luarocks

RUN /usr/local/openresty/luajit/bin/luarocks install inspect \
 && rm -rf /var/cache/nginx

RUN mkdir -p \
        /application \
        /config \
        /usr/local/openresty/nginx/conf.d \
        /var/cache/nginx \
 && chown -R 0:0 \
        /application \
        /config \
        /usr/local/openresty/nginx/conf \
        /usr/local/openresty/nginx/conf.d \
        /usr/local/openresty/nginx/logs \
        /usr/local/openresty/nginx \
        /var/run \
        /var/cache/nginx \
 && chmod 775 \
        /application \
        /config \
        /usr/local/openresty/nginx/conf \
        /usr/local/openresty/nginx/conf.d \
        /usr/local/openresty/nginx/logs \
        /usr/local/openresty/nginx \
        /var/run \
        /var/cache/nginx \
 && ln -sf /usr/local/openresty/nginx/html/index.html /application/index.html \
 && touch /usr/local/openresty/nginx/html/ping \
 && adduser --home /var/cache/nginx --gecos "Nginx Web Server" --system --disabled-password --no-create-home --ingroup root nginx

COPY 50-copy-config.sh /docker-entrypoint.d/

USER nginx

COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY default.conf /usr/local/openresty/nginx/conf.d/default.conf
COPY resty-env.conf /usr/local/openresty/nginx/conf/resty-env.conf

WORKDIR /application

EXPOSE 8080

CMD ["/usr/local/openresty/nginx/sbin/nginx", "-g", "daemon off;"]
