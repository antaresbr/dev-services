#!/bin/bash

[ "${BASH_SOURCE[0]}" -ef "$0" ] && echo "$(basename "$0") | ERROR: This file must be sourced" && exit 1
[ "$(type -t wsError)" == "function" ] || { echo "$(basename "$0") | ERROR: Function wsError not defined"; exit 1; }

echo ""
echo "---[ $(dirname "$(realpath "${SCRIPT_DIR}")") ]---"
echo "---| post-clone/$(basename "${BASH_SOURCE[0]}")"

[ -z "${WORKSPACE_BASE_LIB_SH}" ] && wsError "post-clone/setup-local" "WORKSPACE_BASE_LIB_SH not defined"
[ -z "${POST_CLONE_SETUP_LIB_SH}" ] && wsError "post-clone/setup-local" "POST_CLONE_SETUP_LIB_SH not defined"
[ -z "${POST_CLONE_LIB_SH}" ] && wsError "post-clone/setup-local" "POST_CLONE_LIB_SH not defined"

#---[ setup-local ]---

wsSourceFile "${WORKSPACE_LIB_DIR}/text.lib.sh"

function localSailSetup() {
  if [ "${SAIL_MYADMIN}" != "${pSailMyAdmin}" ]
  then
    if ! cat "${ENV_SAIL_FILE}" | grep '^SAIL_MYADMIN='
    then
      echo "" >> "${ENV_SAIL_FILE}"
      echo "SAIL_MYADMIN=${pSailMyAdmin}" >> "${ENV_SAIL_FILE}"
    fi
  fi

  if [ "${SAIL_PGADMIN}" != "${pSailPgAdmin}" ]
  then
    if ! cat "${ENV_SAIL_FILE}" | grep '^SAIL_PGADMIN='
    then
      echo "" >> "${ENV_SAIL_FILE}"
      echo "SAIL_PGADMIN=${pSailPgAdmin}" >> "${ENV_SAIL_FILE}"
    fi
  fi
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
  while [ $# -gt 0 ]
  do
    local zVar="$1" && shift
    WS_TEMPLATE_FILE_VARS="${WS_TEMPLATE_FILE_VARS}"$'\n'"${zVar}"
  done
}

#-- parameters

pclLoadDefaultAndSavedParams

wsSourceFile "${BASE_DIR}/sail/.env.sail.default"

echo ""
[ -n "${LABS_DOMAIN}" ] || envVarRead "Enter labs domain" "LABS_DOMAIN" "required|default:$(wsCoalesce "${default_LABS_DOMAIN}" "labs.${pEnvironment}")|lower-case"
[ -n "${SERVICES_DOMAIN}" ] || envVarRead "Enter services domain" "SERVICES_DOMAIN" "required|default:$(wsCoalesce "${default_SERVICES_DOMAIN}" "services.${pEnvironment}")|lower-case"
[ -n "${APP_DOMAIN}" ] || envVarRead "Enter app domain" "APP_DOMAIN" "required|default:$(wsCoalesce "${default_APP_DOMAIN}" "app.${pEnvironment}")|lower-case"
[ -n "${pSailMyAdmin}" ] || envVarRead "Enable myAdmin service?" "pSailMyAdmin" "default:$(wsCoalesce "${default_pSailMyAdmin}" "${SAIL_MYADMIN}")|lower-case|hide-values" "true|false"
[ -n "${pSailPgAdmin}" ] || envVarRead "Enable pgAdmin service?" "pSailPgAdmin" "default:$(wsCoalesce "${default_pSailPgAdmin}" "${SAIL_PGADMIN}")|lower-case|hide-values" "true|false"

echo ""
echo "---[ parameters ]---"
echo ""
echo "ENVIRONMENT       : ${pEnvironment}"
echo ""
echo "LABS_DOMAIN       : ${LABS_DOMAIN}"
echo "SERVICES_DOMAIN   : ${SERVICES_DOMAIN}"
echo "APP_DOMAIN        : ${APP_DOMAIN}"
echo "SAIL_MYADMIN      : ${pSailMyAdmin}"
echo "SAIL_PGADMIN      : ${pSailPgAdmin}"
echo ""

envVarRead "Confirm parameters?" "pConfirm" "default:yes|lower-case|hide-values" "y|yes|n|no"
if [ "${pConfirm:0:1}" == "n" ]
then
  exit 0
fi

if [ ! -f "${SCRIPT_DIR}/setup.local.env" ]
then
  echo""
  envVarRead "Save post-clone parameters?" "pSavePostcloneParams" "default:yes|lower-case|hide-values" "y|yes|n|no"
  if [ "${pSavePostcloneParams:0:1}" == "y" ]
  then
    echo -n "\
#!/bin/bash
LABS_DOMAIN=\"${LABS_DOMAIN}\"
SERVICES_DOMAIN=\"${SERVICES_DOMAIN}\"
APP_DOMAIN=\"${APP_DOMAIN}\"
pSailMyAdmin=\"${pSailMyAdmin}\"
pSailPgAdmin=\"${pSailPgAdmin}\"
" > "${SCRIPT_DIR}/setup.local.env"
  fi
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
