# This Image constitutes the runtime for transmart-server and
# transmart-api-server. The built artifacts as war files will be copied into
# a container of this image
FROM openjdk:8u191-jre-alpine3.9
LABEL maintainer="luk.zim91@gmail.com"

# Set the username/uid and groupname/gid of the user that will call tranSMART
ENV TRANSMART_USER_NAME transmart
ENV TRANSMART_USER_ID 1000
ENV TRANSMART_GROUP_NAME "${TRANSMART_USER_NAME}"
ENV TRANSMART_GROUP_ID "${TRANSMART_USER_ID}"
ENV DOCKERIZE_VERSION v0.6.1

WORKDIR /tmp
RUN wget "https://github.com/jwilder/dockerize/releases/download/${DOCKERIZE_VERSION}/dockerize-alpine-linux-amd64-${DOCKERIZE_VERSION}.tar.gz" && \
    tar -C /usr/local/bin -xzvf "dockerize-alpine-linux-amd64-${DOCKERIZE_VERSION}.tar.gz" && \
    rm "dockerize-alpine-linux-amd64-${DOCKERIZE_VERSION}.tar.gz" && \
    addgroup -g "${TRANSMART_GROUP_ID}" "${TRANSMART_GROUP_NAME}" && \
    adduser  -G "${TRANSMART_GROUP_NAME}" -D -u "${TRANSMART_USER_ID}" "${TRANSMART_USER_NAME}" && \
    rm -rf /tmp/* /var/tmp/* && sync
USER "${TRANSMART_USER_NAME}"
WORKDIR "/home/${TRANSMART_USER_NAME}"
