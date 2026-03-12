#!/bin/bash

[ -d "${SAIL_DIR}" ] || { echo "$(basename "$0") | SAIL_DIR not found: ${SAIL_DIR}"; exit 1; }

if [ "${SAIL_MYADMIN,,}" == "true" ]
then
  targetDir="$(dirname "${SAIL_DIR}")/data/myadmin"
  [ -d "${targetDir}" ] || mkdir -p "${targetDir}"

  targetFile="${targetDir}/config.user.inc.php"
  if [ ! -f "${targetFile}" ]
  then
    sourceFile="${SAIL_DIR}/.example/data/myadmin/$(basename "${targetFile}")"
    if [ -f "${sourceFile}" ]
    then
      cp "${sourceFile}" "${targetFile}"
    else
      echo "<?php" > "${targetFile}"
      echo "/* local config */" >> "${targetFile}"
    fi
  fi

  targetFile="${targetDir}/phpmyadmin-local.ini"
  if [ ! -f "${targetFile}" ]
  then
    sourceFile="${SAIL_DIR}/.example/data/myadmin/$(basename "${targetFile}")"
    if [ -f "${sourceFile}" ]
    then
      cp "${sourceFile}" "${targetFile}"
    else
      echo "# local config" >> "${targetFile}"
    fi
  fi
fi
