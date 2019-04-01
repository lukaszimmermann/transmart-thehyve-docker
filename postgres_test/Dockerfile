FROM postgres:9.5.16
LABEL maintainer="luk.zim91@gmail.com"

ENV POSTGRES_USER postgres
ENV POSTGRES_HOME "/home/${POSTGRES_USER}"
ENV POSTGRES_GROUP "${POSTGRES_USER}"

# Make sure that this environment variable ends with an '/' character,
# otherwise the 'make' process at the end might fail
ENV TABLESPACES "${POSTGRES_HOME}/pg/tablespaces/"

# It is highly unadvisable to change the value here. The hard-coded value
# appears at several different locations
ENV PGDATABASE transmart

# PGDATA was changed from /var/lib/postgresql/data, since this was a VOLUME
# But here, we want to store the test data inside the image, not on the host
ENV PGDATA /opt/data

ENV PG_BITCOUNT_ARCHIVE 0.0.3.tar.gz
ENV PGPORT 5432
ENV PGPASSWORD "${POSTGRES_USER}"
ENV BIOMART_USER biomart_user
ENV BIOMART_USER_PWD "${BIOMART_USER}"
ENV TRANSMART_CONFIG "${POSTGRES_HOME}/.grails/transmartConfig"
ENV DATA_SOURCE "${TRANSMART_CONFIG}/DataSource.groovy"
ENV BIOMART_PWD biomart
ENV DEAPP_PWD deapp
ENV I2B2METADATA_PWD i2b2metadata
ENV I2B2DEMODATA_PWD i2b2demodata
ENV SEARCHAPP_PWD searchapp
ENV TM_CZ_PWD tm_cz
ENV TM_LZ_PWD tm_lz
ENV TM_WZ_PWD tm_wz
ENV USE_TRANSMART_BATCH 1
ENV DEBIAN_FRONTEND noninteractive
ENV PG_KEYCLOAK_ROLE keycloak
ENV PG_KEYCLOAK_DATABASE "${PG_KEYCLOAK_ROLE}"
ENV PG_LOCALE en_US.UTF-8
ENV PG_ENCODING UTF8

# Here we do the following steps in this order:
# 1. Ensure that the PGDATA directory exists and set the correct permission
# 2. Create the DataSource.groovy configuration
# 3. Set the Europe/Berlin as timezone
# 4. Install the following required Debian Stretch packages with apt-get
#      * curl: Files can be downloaded, used in the 'make' process
#      * gcc: Compilation of the pg_bitcount extension
#      * git: Cloning of transmart-core repository
#      * groovy: Loading of test data is done in groovy
#      * make: So we can execute the 'make' target for initializing the tranSMART database
#      * php: Some items are loaded into the Database with php, used inside the 'make' process
#      * postgresql-server-dev-9.5: So the pg_bitcount extension can be built for PostgreSQL 9.5
#      * sudo: The make target escalates so that more packages can be installed if required
#      *
USER root
WORKDIR /tmp
RUN mkdir -p "${PGDATA}" && \
    chown -R "${POSTGRES_USER}:${POSTGRES_GROUP}" "${PGDATA}" && \
    mkdir -p "${TRANSMART_CONFIG}" && \
    echo "dataSources {" > "${DATA_SOURCE}" && \
    echo "dataSource {" >> "${DATA_SOURCE}" && \
    echo "driverClassName = 'org.postgresql.Driver'" >> "${DATA_SOURCE}" && \
    echo "url             = 'jdbc:postgresql://localhost:${PGPORT}/${PGDATABASE}'" >> "${DATA_SOURCE}" && \
    echo "dialect         = 'org.hibernate.dialect.PostgreSQLDialect'" >> "${DATA_SOURCE}" && \
    echo "username        = '${BIOMART_USER}'" >> "${DATA_SOURCE}" && \
    echo "password        = '${BIOMART_USER_PWD}'" >> "${DATA_SOURCE}" && \
    echo "dbCreate        = 'none' } }" >> "${DATA_SOURCE}" && \
    chown -R "${POSTGRES_USER}:${POSTGRES_GROUP}" "${POSTGRES_HOME}" && \
    echo "Europe/Berlin" > /etc/timezone && \
    apt-get update -y && \
    apt-get install -y \
      ca-certificates \
      curl \
      gcc \
      git \
      groovy \
      make \
      php \
      postgresql-server-dev-9.5 \
      sudo \
      tzdata \
      wget && \
    wget "https://github.com/thehyve/pg_bitcount/archive/${PG_BITCOUNT_ARCHIVE}" && \
    tar xf "${PG_BITCOUNT_ARCHIVE}" && \
    cd pg_bitcount-0.0.3 && \
    make clean && \
    make && \
    make install && \
    echo 'ALL ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers && \
    mkdir -p "${TABLESPACES}" && \
    chown -R "${POSTGRES_USER}:${POSTGRES_GROUP}" "${TABLESPACES}" && \
    su -c "mkdir -p ${TABLESPACES}biomart" "${POSTGRES_USER}" && \
    su -c "mkdir -p ${TABLESPACES}deapp" "${POSTGRES_USER}" && \
    su -c "mkdir -p ${TABLESPACES}indx" "${POSTGRES_USER}" && \
    su -c "mkdir -p ${TABLESPACES}search_app" "${POSTGRES_USER}" && \
    su -c "mkdir -p ${TABLESPACES}transmart" "${POSTGRES_USER}" && \
    su -c "cd /tmp; /usr/lib/postgresql/9.5/bin/initdb --username=${POSTGRES_USER} --encoding=${PG_ENCODING} --locale=${PG_LOCALE}" "${POSTGRES_USER}" && \
    su -c "cd /tmp; /usr/lib/postgresql/9.5/bin/pg_ctl -w start" "${POSTGRES_USER}" && \
    su -c "cd /tmp; createuser -D -e -i -l -R -S --no-replication ${PG_KEYCLOAK_ROLE}" "${POSTGRES_USER}" && \
    su -c "cd /tmp; createdb -e --encoding=${PG_ENCODING} --locale=${PG_LOCALE} --owner=${PG_KEYCLOAK_ROLE} ${PG_KEYCLOAK_DATABASE}" "${POSTGRES_USER}" && \
    su -c "cd /tmp; git clone -b dev https://github.com/thehyve/transmart-core" "${POSTGRES_USER}" && \
    su -c "cd /tmp; make -C /tmp/transmart-core/transmart-data postgres_test" "${POSTGRES_USER}" && \
    su -c "cd /tmp; /usr/lib/postgresql/9.5/bin/pg_ctl -w --mode=smart stop" "${POSTGRES_USER}" && \
    su -c "echo 'host all all 0.0.0.0/0 trust' >> ${PGDATA}/pg_hba.conf" && \
    apt-get purge -y \
       curl \
       gcc \
       git \
       groovy \
       make \
       php \
       postgresql-server-dev-9.5 \
       wget && \
    apt-get --purge -y autoremove && \
    apt-get autoclean -y &&  \
    apt-get clean -y && \
    rm -rf /tmp/* /var/tmp/* && sync

# Postgres user is used at runtime
USER "${POSTGRES_USER}"
