#!/bin/bash

START_DIR="$(pwd)"
SCRIPT_BIN="$(basename "$0")"
SCRIPT_DIR="$(dirname "$(realpath "$0")")"

source "${SCRIPT_DIR}/nginx.lib.sh"
[ $? -eq 0 ] || { echo -e "\n${SCRIPT_BIN} | ERRO: Fail importing file, ${SCRIPT_DIR}/nginx.lib.sh\n"; exit 1; }

wsSourceFile "${WORKSPACE_LIB_DIR}/text.lib.sh"

TEMPLATE_BASE="app.conf.example"

#-- init parameters
pDomain=""
pAppId=""
pLinkId=""
pBackendPort=""
pFrontendPort=""
#-- help message
msgHelp="
Use: $(basename $0) options

options:

   --domain         APP domain.
   --app-id         APP ID
   --link-id        APP link id. Default: same as --app-id
   --backend-port   APP backend port
   --frontend-port  APP frontend port
   --help           Show this help
"

#-- get parameters

while [ $# -gt 0 ]
do
  case "$1" in
    "--domain" | "--app-id" | "--link-id" | "--backend-port" | "--frontend-port")
      zp="$1"
      shift 1
      [ -z "$1" ] && wsError "Parameter: ${zp}, value not supplied"
      [ "${1:0:2}" == "--" ] && wsError "Parameter: ${zp}, invalid value: '$1'"
      case "$zp" in
        "--domain")
          pDomain="$1"
        ;;
        "--app-id")
          pAppId="$1"
        ;;
        "--link-id")
          pLinkId="$1"
        ;;
        "--backend-port")
          pBackendPort="$1"
        ;;
        "--frontend-port")
          pFrontendPort="$1"
        ;;
      esac
    ;;
    "--help")
       echo "${msgHelp}"
       exit 0;
    ;;
    *)
      wsError "Invalid parameter: $1"
    ;;
  esac
  [ $# -gt 0 ] && shift 1
done

[ -n "${pDomain}" ] || wsError "Parameter not supplied: --domain"
[ -n "${pAppId}" ] || wsError "Parameter not supplied: --app-id"
[ -n "${pBackendPort}" ] || wsError "Parameter not supplied: --backend-port"
[ -n "${pFrontendPort}" ] || wsError "Parameter not supplied: --frontend-port"

[ -n "${pLinkId}" ] || pLinkId="${pAppId}"

domainReverse="$(text_reverse "." "${pDomain}")"

templateDir=""
[ ! -d "${NGINX_SITES_AVAILABLE_DIR}/.example" ] || templateDir=".example/"
templateFile="${templateDir}${pLinkId}.${TEMPLATE_BASE}"
[ -f "${NGINX_SITES_AVAILABLE_DIR}/${templateFile}" ] || templateFile="${templateDir}${TEMPLATE_BASE}"

"${SCRIPT_DIR}/site-config.sh" new \
  --template "${templateFile}" \
  --file "${domainReverse}.${pAppId}.conf" \
  --var LINK_ID="${pLinkId}" \
  --var APP_DOMAIN="${pDomain}" \
  --var APP_DOMAIN_REVERSE="${domainReverse}" \
  --var APP_ID="${pAppId}" \
  --var APP_BACKEND_PORT="${pBackendPort}" \
  --var APP_FRONTEND_PORT="${pFrontendPort}"

"${SCRIPT_DIR}/site-config.sh" enable --file "${domainReverse}.${pAppId}.conf"
