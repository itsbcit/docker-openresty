FROM openresty/openresty:centos

RUN setcap 'cap_net_bind_service=+ep' /usr/local/openresty/nginx/sbin/nginx

RUN for i in logs proxy_temp client_body_temp fastcgi_temp uwsgi_temp scgi_temp;do \
        mkdir -p /usr/local/openresty/nginx/$i; \
        chown 0:0 /usr/local/openresty/nginx/$i; \
        chmod 1775 /usr/local/openresty/nginx/$i; \
    done

VOLUME /usr/local/openresty/nginx/logs
VOLUME /usr/local/openresty/nginx/proxy_temp
VOLUME /usr/local/openresty/nginx/client_body_temp
VOLUME /usr/local/openresty/nginx/fastcgi_temp
VOLUME /usr/local/openresty/nginx/nginx/uwsgi_temp
VOLUME /usr/local/openresty/nginx/scgi_temp

EXPOSE 80
