#!/bin/bash

START_DIR="$(pwd)"
SCRIPT_BIN="$(basename "$0")"
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
NGINX_DIR="$(dirname "${SCRIPT_DIR}")"

if [ -z "${WORKSPACE_LIB_DIR}" ]
then
  WORKSPACE_LIB_DIR="${NGINX_DIR}"
  while [ -n "${WORKSPACE_LIB_DIR}" ]
  do
    if [ -d "${WORKSPACE_LIB_DIR}/.workspace-lib" ]
    then
      WORKSPACE_LIB_DIR="${WORKSPACE_LIB_DIR}/.workspace-lib"
      break
    fi
    if [ "${WORKSPACE_LIB_DIR}" == "/" ] || [ "${WORKSPACE_LIB_DIR}" == "." ]
    then
      WORKSPACE_LIB_DIR=""
      break
    fi
    WORKSPACE_LIB_DIR="$(dirname "${WORKSPACE_LIB_DIR}")"
  done
fi
[ -z "${WORKSPACE_LIB_DIR}" ] && echo -e "\n${SCRIPT_BIN} | ERRO: WORKSPACE_LIB_DIR not supplied\n" && exit 1
[ ! -f "${WORKSPACE_LIB_DIR}/base.lib.sh" ] && echo -e "\n${SCRIPT_BIN} | ERRO: Arquivo não encontrado, ${WORKSPACE_LIB_DIR}/base.lib.sh\n" && exit 1
source "${WORKSPACE_LIB_DIR}/base.lib.sh"
[ $? -ne 0 ] && echo -e "\n${SCRIPT_BIN} | ERRO: Falha ao importar arquivo, ${WORKSPACE_LIB_DIR}/base.lib.sh\n" && exit 1

wsSourceFile "${WORKSPACE_LIB_DIR}/text.lib.sh"

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
   --app-id         APP's ID
   --link-id        APP's link id. Default: same as --app-id
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

"${SCRIPT_DIR}/site-config.sh" new \
  --template "app.conf.example" \
  --file "${domainReverse}.${pAppId}.conf" \
  --var LINK_ID="${pLinkId}" \
  --var APP_DOMAIN="${pDomain}" \
  --var APP_DOMAIN_REVERSE="${domainReverse}" \
  --var APP_ID="${pAppId}" \
  --var APP_BACKEND_PORT="${pBackendPort}" \
  --var APP_FRONTEND_PORT="${pFrontendPort}"

"${SCRIPT_DIR}/site-config.sh" enable --file "${domainReverse}.${pAppId}.conf"
