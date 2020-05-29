FROM bcit/alpine:3.11

ENV KEYCLOAK_ENDPOINT "https://keycloak.example.com"
ENV KEYCLOAK_REALM "master"
ENV RESOLVER_ADDRESS "8.8.8.8"
ENV KEYCLOAK_CLIENT_ID "nginx"
ENV KEYCLOAK_CLIENT_SECRET "00000000-0000-0000-0000-000000000000"

RUN wget 'http://openresty.org/package/admin@openresty.com-5ea678a6.rsa.pub' \
        -O '/etc/apk/keys/admin@openresty.com-5ea678a6.rsa.pub' \
 && echo "http://openresty.org/package/alpine/v3.11/main" \
        >> /etc/apk/repositories

RUN apk add --no-cache \
    openresty \
    openresty-opm \
    openresty-resty

RUN opm install \
        bungle/lua-resty-session \
        zmartzone/lua-resty-openidc

RUN mkdir -p \
        /application \
        /usr/local/openresty/nginx/conf.d \
 && chown -R 0:0 \
        /application \
        /usr/local/openresty/nginx/conf \
        /usr/local/openresty/nginx/conf.d \
        /usr/local/openresty/nginx/logs \
        /usr/local/openresty/nginx \
        /var/run \
 && chmod 775 \
        /application \
        /usr/local/openresty/nginx/conf \
        /usr/local/openresty/nginx/conf.d \
        /usr/local/openresty/nginx/logs \
        /usr/local/openresty/nginx \
        /var/run

COPY 50-copy-config.sh /docker-entrypoint.d/
COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY default.conf /usr/local/openresty/nginx/conf.d/default.conf

VOLUME /application

WORKDIR /application

EXPOSE 8080

CMD ["/usr/local/openresty/nginx/sbin/nginx", "-g", "daemon off;"]
