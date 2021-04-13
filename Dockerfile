FROM alpine:3.13.4

LABEL maintainer="michael@slapdogaf.dk"

RUN \
  apk update && \
  apk add bash py-pip certbot openssl && \
  apk add --virtual=build gcc libffi-dev musl-dev openssl-dev python3-dev make && \
  pip --no-cache-dir install -U pip && \
  pip --no-cache-dir install azure-cli && \
  apk del --purge build && \
  mkdir /scripts

COPY scripts/*.sh /scripts/

RUN chmod 755 /scripts/*.sh

CMD [ "bash", "/scripts/certbot_issue.sh" ]