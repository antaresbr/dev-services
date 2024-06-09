#!/bin/bash

if [ -z "${PROJECT_ENV_SH}" ]
then

PROJECT_ENV_SH="loaded"

[ -z "${NGINX_VERSION}" ] && sailError "NGINX_VERSION not supplied"
[ -z "${NGINX_PORT}" ] && sailError "NGINX_PORT not supplied"
[ -z "${NGINX_PORT_HTTPS}" ] && sailError "NGINX_PORT_HTTPS not supplied"

export NGINX_VERSION
export NGINX_PORT
export NGINX_PORT_HTTPS
export MYADMIN_FORWARD_PORT
export MYADMIN_ABSOLUTE_URI
export PGADMIN_FORWARD_PORT

export SAIL_SERVICE_NGINX="${COMPOSE_PROJECT_NAME}-nginx"
export SAIL_SERVICE_MYADMIN="${COMPOSE_PROJECT_NAME}-myadmin"
export SAIL_SERVICE_PGADMIN="${COMPOSE_PROJECT_NAME}-pgadmin"

COMPOSE_CONFIGS="--file docker-compose.yml"
[ "${SAIL_MYADMIN,,}" == "true" ] && COMPOSE_CONFIGS="${COMPOSE_CONFIGS} --file docker-compose-myadmin.yml"
[ "${SAIL_PGADMIN,,}" == "true" ] && COMPOSE_CONFIGS="${COMPOSE_CONFIGS} --file docker-compose-pgadmin.yml"
export COMPOSE_CONFIGS

fi