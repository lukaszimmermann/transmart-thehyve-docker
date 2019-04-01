FROM lukaszimmermann/transmart-core-thehyve-build-base:v1 AS build
LABEL maintainer="luk.zim91@gmail.com"

RUN gradle --no-daemon clean :transmart-server:assemble

##########################################################################
FROM lukaszimmermann/transmart-core-thehyve-runtime:v1 AS runtime
LABEL maintainer="luk.zim91@gmail.com"

ENV TRANSMART_HOME "/home/${TRANSMART_USER_NAME}"
ENV TRANSMART_CONFIG_DIR "${TRANSMART_HOME}/.grails/transmartConfig"
ENV SERVICE_WAR_FILE "${TRANSMART_HOME}/service.war"

RUN mkdir -p "${TRANSMART_CONFIG_DIR}"

COPY --from=build /opt/src/transmart-core/transmart-server/build/libs/transmart-server-17.1-HYVE-5-SNAPSHOT.war "${SERVICE_WAR_FILE}"
COPY docker-entrypoint.sh /opt/docker-entrypoint.sh
COPY Config.groovy "${TRANSMART_CONFIG_DIR}"

ENTRYPOINT ["/opt/docker-entrypoint.sh"]
EXPOSE 8080
