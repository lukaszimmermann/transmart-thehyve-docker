#!/bin/sh
set -e

###############################################################################
# Prints a fatal error and exits this script with an error code
###############################################################################
fatal() {
		cat << EndOfMessage
###############################################################################
!!!!!!!!!! FATAL ERROR !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
###############################################################################
${1}
###############################################################################
EndOfMessage
		exit "${2}"
}


###############################################################################
# Error message for a variable that is unset or empty during runtime
###############################################################################
fatalNotExists() {
	read -d '' msg << EOF || true
	The variable with the name '$1' is unset.
	Please specify a value in this container environment using
	-e in docker run, or the environment section in Docker Compose.
EOF
	fatal "${msg}" 1
}


###############################################################################
# Error message for a variable that should be an absolute path, but isn't
###############################################################################
fatalPathNotAbsolute() {
	read -d '' msg << EOF || true
	The path in the environment variable '$1' is not absolute!
EOF
	fatal "${msg}" 2
}


###############################################################################
# List of environment variables that need to be defined in the Dockerfile
# (so in the container where this Entrypoint is gonna be executed in)
###############################################################################
# * TRANSMART_CONFIG_DIR     # Where the 'transmartConfig' file is located
# * SERVICE_WAR_FILE         # The location of the executable war file


###############################################################################
# The values of these environment variables need to be absolute file paths
###############################################################################
[[ "${TRANSMART_CONFIG_DIR}" = /* ]] || fatalPathNotAbsolute TRANSMART_CONFIG_DIR
[[ "${SERVICE_WAR_FILE}" = /* ]]     || fatalPathNotAbsolute SERVICE_WAR_FILE


###############################################################################
# These variables need to be set during runtime
###############################################################################
[ ! -z ${PGHOST+x} ] || fatalNotExists PGHOST   # Host of Postgres
[ ! -z ${PGPORT+x} ] || fatalNotExists PGPORT   # Port which tranSMART should use for PG


###############################################################################
# Ensure that the config directory for tranSMART actually exists
###############################################################################
mkdir -p "${TRANSMART_CONFIG_DIR}"


###############################################################################
# List of variables that are fixed in the Postgres image and cannot be changed
###############################################################################
PGDATABASE=transmart
BIOMART_USER='biomart_user'

###############################################################################
# Sets the runtime configuration for tranSMART Server
###############################################################################
cat > "${TRANSMART_CONFIG_DIR}/DataSource.groovy" <<EndOfMessage
dataSources {
    dataSource {
        driverClassName = 'org.postgresql.Driver'
        url             = 'jdbc:postgresql://${PGHOST}:${PGPORT}/${PGDATABASE}'
        dialect         = 'org.hibernate.dialect.PostgreSQLDialect'
        username        = '${BIOMART_USER}'
        password        = '${BIOMART_USER}'
        dbCreate        = 'none'

        properties {
        	numTestsPerEvictionRun = 3
        	maxWait = 10000

        	testOnBorrow = true
        	testWhileIdle = true
        	testOnReturn = true

        	validationQuery = "select 1"

        	minEvictableIdleTimeMillis = 1000 * 60 * 5
        	timeBetweenEvictionRunsMillis = 1000 * 60 * 5
        }
    }
    oauth2 {
        driverClassName = 'org.h2.Driver'
        url = "jdbc:h2:~/.grails/oauth2db;MVCC=TRUE"
        dialect = 'org.hibernate.dialect.H2Dialect'
        username = 'sa'
        password = ''
        dbCreate = 'update'
    }
}

environments {
    development {
        dataSource {
            logSql    = true
            formatSql = true
             properties {
                maxActive   = 10
                maxIdle     = 5
                minIdle     = 2
                initialSize = 2
            }
        }
    }
    production {
        dataSource {
            logSql    = false
            formatSql = false
             properties {
                maxActive   = 50
                maxIdle     = 25
                minIdle     = 5
                initialSize = 5
            }
        }
    }
}
EndOfMessage
sync


###############################################################################
# Waiting for all requied services to become available via TCP before
# trying to run tranSMART Server
###############################################################################
dockerize -wait "tcp://${PGHOST}:${PGPORT}"


###############################################################################
# Finally run tranSMART Server
###############################################################################
exec java -jar "${SERVICE_WAR_FILE}"


# Some notes:

# This directory must exist. If you are running PostgreSQL under your own user,
# you just have to make sure the directory is owned by you.
# Otherwise, you must create some directories under it and assign ownership to
# them to the postgres user. For instance:
#     mkdir -p $TABLESPACES/{biomart,deapp,indx,search_app,transmart}
#     chown -R postgres:postgres $TABLESPACES
# end with /
# TABLESPACES=$HOME/pg/tablespaces/

# The directory where the postgres client utilities are
# If using a package manager, probably /usr/bin/
# end with /
# PGSQL_BIN=$HOME/pg/bin/
# }}}

# {{{ Oracle
# Uncomment this to enable Oracle
#ORACLE=1
# ORAHOST=localhost
# ORAPORT=1521
# ORASID=orcl
# If ORASVC (Oracle Service) specified it will be used over ORASID for
# connection (PDB may be specified this way for Oracle 12c)
#ORASVC=orcl
# ORAUSER="sys as sysdba"
# ORAPASSWORD=mypassword

# Set this to 1 if you want Oracle tablespaces to be created (and dropped!)
# by transmart-data. In that case, you must also specify an oracle owned
# directory that will be used to set the system param DB_CREATE_FILE_DEST
# ORACLE_MANAGE_TABLESPACES=0
# Comment the line below when you use an Oracle Database instance from Amazon RDS.
# ORACLE_TABLESPACES_DIR=/home/oracle/app/oracle/oradata
# }}}

# Only needed for ETL
# End with /
# KETTLE_JOBS_PSQL=/path/to/transmart-ETL/Postgres/GPL-1.0/Kettle/Kettle-ETL/
# End with /
# KETTLE_JOBS_ORA=/path/to/transmart-ETL/Kettle-GPL/Kettle-ETL/

# R_JOBS_PSQL=/path/to/tranSMART-ETL/Kettle/postgres/R/

# KITCHEN=/path/to/data-integration/kitchen.sh

#only needed for configuration
#end with /
# TSUSER_HOME=$HOME/

#optional TAR commend - e.g. tar on Mac does not work;
# on Mac homebrew: brew install gnu-tar ; will set command gtar
# if this is unset, then value defaults to tar (system tar command)
#TAR_COMMAND=gtar
#export TAR_COMMAND

# {{{ DB user passwords
#     They default to the same as the username.
#     These are set when the database is created and they are used when
#     connecting to the database (e.g. for ETL).
#     You can reset passwords to the values specified here with:
#       make -C ddl/postgres/GLOBAL load_passwords
#       make -C ddl/oracle load_passwords
#     Depending on whether you're using oracle or postgres.
#
#export BIOMART_USER_PWD=biomart_user
#export BIOMART_PWD=biomart
#export DEAPP_PWD=deapp
#export I2B2METADATA_PWD=i2b2metadata
#export I2B2DEMODATA_PWD=i2b2demodata
#export SEARCHAPP_PWD=searchapp
#export TM_CZ_PWD=tm_cz
#export TM_LZ_PWD=tm_lz
#export TM_WZ_PWD=tm_wz
# }}}

# If your distro uses an old version of groovy, do make -C env groovy,
# and uncomment this. Version 2.1.9 is known to work, versions before 2
# are known not to work
#DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#export PATH=$DIR/env:$PATH
#

# To use transmart-batch where supported
#export USE_TRANSMART_BATCH=1

# Oracle uses the blocking random pool by default
# This is a bad idea because successive connections WILL exhaust the pool
# /dev/urandom is just as secure, provided it's been seeded already
# export _JAVA_OPTIONS='-Djava.security.egd=file:///dev/urandom'
#
# If you need to proxy (you may need to combine with option above)
# export _JAVA_OPTIONS="-Dhttp.proxyHost=$proxy_host -Dhttp.proxyPort=$proxy_port"

# export PGHOST PGPORT PGDATABASE PGUSER PGPASSWORD TABLESPACES PGSQL_BIN \
# 	R_JOBS_PSQL KETTLE_JOBS_PSQL KETTLE_JOBS_ORA KITCHEN TSUSER_HOME ORAHOST ORAPORT \
# 	ORASID ORASVC ORAUSER ORAPASSWORD ORACLE_MANAGE_TABLESPACES \
# 	ORACLE_TABLESPACES_DIR ORACLE

# vim: fdm=marker
