FROM alpine:3.15.0
RUN apk update && apk add busybox-extras curl
COPY auto-bootstrap.sh .
RUN chmod +x auto-bootstrap.sh
ENTRYPOINT /bin/sh auto-bootstrap.sh
