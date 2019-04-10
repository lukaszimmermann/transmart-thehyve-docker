##########################################################################
# BUILD: We get the image containing tranSMART sourcs and build
#        traSMART Server
##########################################################################
FROM lukaszimmermann/transmart-core-thehyve-build-base:v1 AS BUILD
LABEL maintainer="luk.zim91@gmail.com"

RUN gradle --no-daemon clean :transmart-server:assemble


##########################################################################
# RUNTIME: Builds the runtime image of tranSMART Server
##########################################################################
FROM lukaszimmermann/transmart-core-thehyve-runtime:v1 AS RUNTIME
LABEL maintainer="luk.zim91@gmail.com"

ENV TRANSMART_HOME "/home/${TRANSMART_USER_NAME}"

# The environment variable are required for the docker-entrypoint.sh
ENV TRANSMART_CONFIG_DIR "${TRANSMART_HOME}/.grails/transmartConfig"
ENV SERVICE_WAR_FILE "${TRANSMART_HOME}/service.war"

COPY --from=BUILD /opt/src/transmart-core/transmart-server/build/libs/transmart-server-17.1-HYVE-5-SNAPSHOT.war "${SERVICE_WAR_FILE}"
COPY docker-entrypoint.sh /opt/docker-entrypoint.sh
COPY Config.groovy "${TRANSMART_CONFIG_DIR}"

ENTRYPOINT ["/opt/docker-entrypoint.sh"]
EXPOSE 8080
