FROM alpine:latest
MAINTAINER tom chen <viger@mchen.info>

RUN apk add --no-cache python2 bash py2-openssl

ADD proxy /root/proxy

RUN chmod a+x /root/proxy/start

EXPOSE 8085 8086 8087

ENTRYPOINT ["/root/proxy/start"]
