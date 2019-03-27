# Creates the base image with the tranSMART sources to be built
FROM gradle:3.5-jdk8-alpine
LABEL maintainer="luk.zim91@gmail.com"

#
# Creates the /opt/src directory and gives it to the gradle user to
# clone the tranSMART sources
#
USER root
WORKDIR /tmp
RUN apk update --no-cache -U && \
    apk add --no-cache -U git && \
    mkdir -p /opt/src && \
    chown -R gradle:gradle /opt/src && \
    rm -rf /tmp/* /var/tmp/* && sync

#
# Checkout tranSMART with a specific branch and commit tag.
# Files from the repo not required for building are removed
#
USER gradle
WORKDIR /opt/src
RUN git clone --branch dev https://github.com/thehyve/transmart-core && \
    cd transmart-core && \
    git checkout b9420d919d1f08b5c5743cac8f239ed1f68d1487

#
# Apply Patches
#
COPY 0001-Remove-Access-logging-in-UserLandingInterceptor.patch /opt/src/transmart-core
RUN cd /opt/src/transmart-core && \
    git apply 0001-Remove-Access-logging-in-UserLandingInterceptor.patch

#
# Remove dependencies and cleanup
#
USER root
RUN cd /root && \
    chown -R gradle:gradle /opt/src/transmart-core && \
    apk del --purge git && \
    rm -rf /tmp/* /var/tmp/* && sync

#
# Set User and workdir for child images
#
USER gradle
WORKDIR /opt/src/transmart-core
