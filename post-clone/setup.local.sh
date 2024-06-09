#!/bin/bash

[ "${BASH_SOURCE[0]}" -ef "$0" ] && echo "$(basename "$0") | ERROR: This file must be sourced" && exit 1

function pcslocError() {
  local msgPrefix="setup-local"
  if [ $# -gt 1 ]
  then
    msgPrefix="${msgPrefix} | $1"
    shift
  fi
  pcsError "${msgPrefix}" "$@"
  exit 1
}

echo ""
echo "---[ $(dirname "$(realpath "${SCRIPT_DIR}")") ]---"
echo "---| post-clone/$(basename "${BASH_SOURCE[0]}")"

[ -z "${WORKSPACE_BASE_LIB_SH}" ] && pcslocError "WORKSPACE_BASE_LIB_SH not defined\n" && exit 1
[ -z "${POST_CLONE_SETUP_LIB_SH}" ] && pcslocError "POST_CLONE_SETUP_LIB_SH not defined"
[ -z "${POST_CLONE_LIB_SH}" ] && pcslocError "POST_CLONE_LIB_SH not defined"

#---[ setup-local ]---

wsSourceFile "${WORKSPACE_LIB_DIR}/text.lib.sh"

function localSailSetup() {
  if [ "${SAIL_MYADMIN}" != "${pSailMyAdmin}" ]
  then
    echo "" >> "${ENV_SAIL_FILE}"
    echo "SAIL_MYADMIN=${pSailMyAdmin}" >> "${ENV_SAIL_FILE}"
  fi

  if [ "${SAIL_PGADMIN}" != "${pSailPgAdmin}" ]
  then
    echo "" >> "${ENV_SAIL_FILE}"
    echo "SAIL_PGADMIN=${pSailPgAdmin}" >> "${ENV_SAIL_FILE}"
  fi

  unset _dummy_
}

function setTemplateFileVars() {
  export WS_TEMPLATE_FILE_VARS="\
ENVIRONMENT=${pEnvironment}
SAIL_USERNAME=${SAIL_USERNAME}
SAIL_USERID=${SAIL_USERID}
LABS_DOMAIN="${LABS_DOMAIN}"
LABS_DOMAIN_REVERSE="${LABS_DOMAIN_REVERSE}"
SERVICES_DOMAIN="${SERVICES_DOMAIN}"
SERVICES_DOMAIN_REVERSE="${SERVICES_DOMAIN_REVERSE}"
APP_DOMAIN="${APP_DOMAIN}"
APP_DOMAIN_REVERSE="${APP_DOMAIN_REVERSE}"
"
  while [ $? -gt 0 ]
  do
    local zVar="$1" && shift
    WS_TEMPLATE_FILE_VARS="${WS_TEMPLATE_FILE_VARS}"$'\n'"${zVar}"
  done
}

#-- parameters

wsSourceFile "${BASE_DIR}/sail/.env.sail.default"

echo ""
envVarRead "Enter labs domain" "LABS_DOMAIN" "required|default:labs.${pEnvironment}|lower-case|auto-default"
envVarRead "Enter services domain" "SERVICES_DOMAIN" "required|default:services.${pEnvironment}|lower-case|auto-default"
envVarRead "Enable myAdmin service?" "pSailMyAdmin" "default:${SAIL_MYADMIN}|lower-case|hide-values" "true|false"
envVarRead "Enable pgAdmin service?" "pSailPgAdmin" "default:${SAIL_PGADMIN}|lower-case|hide-values" "true|false"

echo ""
echo "---[ parameters ]---"
echo ""
echo "ENVIRONMENT       : ${pEnvironment}"
echo ""
echo "LABS_DOMAIN       : ${LABS_DOMAIN}"
echo "SERVICES_DOMAIN   : ${SERVICES_DOMAIN}"
echo "SAIL_MYADMIN      : ${pSailMyAdmin}"
echo "SAIL_PGADMIN      : ${pSailPgAdmin}"
echo ""

envVarRead "Confirm parameters?" "pConfirm" "default:sim|lower-case|hide-values" "s|sim|n|nao|não"
if [ "${pConfirm:0:1}" == "n" ]
then
  exit 0
fi

LABS_DOMAIN_REVERSE="$(text_reverse "." "${LABS_DOMAIN}")"
SERVICES_DOMAIN_REVERSE="$(text_reverse "." "${SERVICES_DOMAIN}")"
APP_DOMAIN_REVERSE="$(text_reverse "." "${APP_DOMAIN}")"

#-- sail

sailSetup

#-- nginx

setTemplateFileVars

wsTemplateFile "data/nginx/conf.d/include/${LABS_DOMAIN_REVERSE}.proxy.inc" "proxy.inc.example"
wsTemplateFile "data/nginx/conf.d/include/${SERVICES_DOMAIN_REVERSE}.proxy.inc" "proxy.inc.example"

data/nginx/site-config.sh new \
  --template "labs.conf.example" \
  --file "${LABS_DOMAIN_REVERSE}.conf" \
  --var LABS_URL="${LABS_DOMAIN}" \
  --var UPS_PORT="8000"
data/nginx/site-config.sh enable --file "${LABS_DOMAIN_REVERSE}.conf"

if [ "${pSailMyAdmin}" == "true" ]
then
  data/nginx/site-config.sh new \
    --template "services.conf.example" \
    --file "${SERVICES_DOMAIN_REVERSE}.myadmin.conf" \
    --var LINK_ID="myadmin" \
    --var UPS_PORT="5060"
  data/nginx/site-config.sh enable --file "${SERVICES_DOMAIN_REVERSE}.myadmin.conf"
fi

if [ "${pSailPgAdmin}" == "true" ]
then
  data/nginx/site-config.sh new \
    --template "services.conf.example" \
    --file "${SERVICES_DOMAIN_REVERSE}.pgadmin.conf" \
    --var LINK_ID="pgadmin" \
    --var UPS_PORT="5050"
  data/nginx/site-config.sh enable --file "${SERVICES_DOMAIN_REVERSE}.pgadmin.conf"
fi

#-- pgadmin

certifyPath "data/pgadmin" "755" "5050:5050"

#-- build

#sailBuild
