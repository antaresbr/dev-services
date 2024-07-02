#!/bin/bash

SAIL_DIR="$(dirname "$(realpath "$0")")/sail"
while [ ! -d "${SAIL_DIR}" ]
do
  [ "${SAIL_DIR}" != "/" ] || { echo "$(basename "$0") | ERROiR: Impossible to get SAIL_DIR"; exit 1; }
  [ ! -d "${SAIL_DIR}" ] || break
  SAIL_DIR="$(dirname "$(dirname "${SAIL_DIR}")")/sail"
done

"${SAIL_DIR}/sail" exec nginx nginx -t && "${SAIL_DIR}/sail" exec nginx nginx -s reload
