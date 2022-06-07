FROM rust:alpine

WORKDIR /app
RUN wget https://github.com/nextcloud/notify_push/releases/latest/download/notify_push.tar.gz
RUN tar -xzf notify_push.tar.gz
RUN apk --no-cache add curl
CMD ["/app/notify_push/bin/x86_64/notify_push", "/var/www/html/config/config.php"]
EXPOSE 7867/tcp
