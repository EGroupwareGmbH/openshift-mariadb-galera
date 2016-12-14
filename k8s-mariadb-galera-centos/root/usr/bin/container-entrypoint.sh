#!/bin/bash
#
# Adfinis SyGroup AG
# openshift-mariadb-galera: Container entrypoint
#

set -e
set -x

# Locations
CONTAINER_SCRIPTS_DIR="/usr/share/container-scripts/mysql"
EXTRA_DEFAULTS_FILE="/etc/mysql/my-galera.cnf"
FIRST_TIME_SQL="/tmp/mysql-first-time.sql"
MYSQLD_FLAGS=""


# Check if the container runs in Kubernetes/OpenShift
if [ -z "$POD_NAMESPACE" ]; then
	# Single container runs in docker
	echo "POD_NAMESPACE not set, spin up single node"
else
	# Is running in Kubernetes/OpenShift, so find all other pods
	# belonging to the namespace
	echo "Galera: Finding peers"
	cp ${CONTAINER_SCRIPTS_DIR}/galera.cnf /etc/my.cnf.d
	/usr/bin/peer-finder -on-start="${CONTAINER_SCRIPTS_DIR}/configure-galera.sh" -service=galera
	MYSQLD_FLAGS+="--defaults-extra-file=/etc/my.cnf.d/galera.cnf "
fi


# We assume that mysql needs to be setup if this directory is not present
if [ ! -d "/var/lib/mysql/mysql" ]; then
	echo "Configure first time mysql"
	${CONTAINER_SCRIPTS_DIR}/configure-mysql.sh "${FIRST_TIME_SQL}"
	MYSQLD_FLAGS+="--init-file=${FIRST_TIME_SQL} "
fi


# Run mysqld
exec mysqld ${MYSQLD_FLAGS}