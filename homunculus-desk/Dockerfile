FROM nginx:alpine

RUN rm -rf /usr/share/nginx/html/*
RUN rm -rf /etc/nginx/conf.d/default.conf

RUN apk update
RUN apk add nodejs npm git curl

COPY ./.env /.env
COPY ./entrypoint.sh /entrypoint.sh
COPY ./nginx/default.conf /etc/nginx/conf.d/default.conf
COPY ./entrypoint.sh /entrypoint.sh

CMD ["/bin/sh", "/entrypoint.sh"]