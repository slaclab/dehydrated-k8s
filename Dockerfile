FROM nginx:stable
ARG UID=101
ARG GID=101

# Suggested Volumes
# /etc/dehydrated/accounts
# /etc/dehydrated/domains

ENV DEHYDRATED_VERSION=0.7.0

# Support 1.21 and 1.23
ENV K8S_VERSION=1.22.0

# nginx user is 101
ADD --chown=101:101 rootfs /
RUN mkdir -p /usr/share/nginx/html/.well-known/acme-challenge && chown 101:101 /usr/share/nginx/html/.well-known/acme-challenge

RUN curl -LO https://github.com/dehydrated-io/dehydrated/releases/download/v${DEHYDRATED_VERSION}/dehydrated-${DEHYDRATED_VERSION}.tar.gz && \
    tar xvf dehydrated-${DEHYDRATED_VERSION}.tar.gz && \
    mv dehydrated-${DEHYDRATED_VERSION}/dehydrated /usr/local/bin && \
    rm -rf dehydrated-${DEHYDRATED_VERSION} && \
    rm dehydrated-${DEHYDRATED_VERSION}.tar.gz

RUN curl -LO "https://dl.k8s.io/release/v${K8S_VERSION}/bin/linux/amd64/kubectl" && \
    mv kubectl /usr/local/bin && \
    chmod +x /usr/local/bin/kubectl

RUN sed -i 's,listen       80;,listen       8080;,' /etc/nginx/conf.d/default.conf \
    && sed -i '/user  nginx;/d' /etc/nginx/nginx.conf \
    && sed -i 's,/var/run/nginx.pid,/tmp/nginx.pid,' /etc/nginx/nginx.conf \
    && sed -i 's,/var/run/nginx.pid,/tmp/nginx.pid,' /etc/nginx/nginx.conf \
    && sed -i "/^http {/a \    proxy_temp_path /tmp/proxy_temp;\n    client_body_temp_path /tmp/client_temp;\n    fastcgi_temp_path /tmp/fastcgi_temp;\n    uwsgi_temp_path /tmp/uwsgi_temp;\n    scgi_temp_path /tmp/scgi_temp;\n" /etc/nginx/nginx.conf \
# nginx user must own the cache and etc directory to write cache and tweak the nginx config
    && chown -R $UID:0 /var/cache/nginx \
    && chmod -R g+w /var/cache/nginx \
    && chown -R $UID:0 /etc/nginx \
    && chmod -R g+w /etc/nginx

ENTRYPOINT ["/entrypoint.sh"]
