#!/bin/bash

START_DIR="$(pwd)"
SCRIPT_BIN="$(basename "$0")"
SCRIPT_DIR="$(dirname "$(realpath "$0")")"

source "${SCRIPT_DIR}/nginx.lib.sh"
[ $? -eq 0 ] || { echo -e "\n${SCRIPT_BIN} | ERRO: Fail importing file, ${SCRIPT_DIR}/nginx.lib.sh\n"; exit 1; }

#-- init parameters
pAction=""
pFile=""
pMode=""
pTemplate=""
pVar=""
#-- help message
msgHelp="
Use: $(basename $0) <action> [ options ]

action:

   new      Create new configuration
   enable   Enable configuration
   disable  Disable configuration

options:

   --file              Configuration file name
   --mode              File mode
   --template          Template to use in <new> action
   --var <name=value>  Variable to be used in template
   --help              Show this help

"

#-- get parameters

while [ $# -gt 0 ]
do
  case "$1" in
    "new" | "enable" | "disable")
      [ -n "$pAction" ] && wsError "More than one action supplied: ${pAction}, $1"
      pAction="$1"
    ;;
    "--file" | "--mode" | "--template" | "--var")
      zp="$1"
      shift 1
      [ -z "$1" ] && wsError "Parameter: ${zp}, value not supplied"
      [ "${1:0:2}" == "--" ] && wsError "Parameter: ${zp}, invalid value: '$1'"
      case "$zp" in
        "--file")
          pFile="$1"
        ;;
        "--mode")
          pMode="$1"
        ;;
        "--template")
          pTemplate="$1"
        ;;
        "--var")
          zv="$1"
          if [ -z "${zv}" ] || [ "${zv}" == "$(echo "${zv}" | tr -d '=')" ]
          then
            wsError="Parameter: ${zp}, invalid value: '${zv}'"
          fi
          [ -n "${pVar}" ] && pVar="${pVar}"$'\n'
          pVar="${pVar}${zv}"
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

[ -z "${pAction}" ] && wsError "Action not supplied"

[ -z "${pFile}" ] && wsError "Configuration file not supplied"
[[ "${pFile}" != *\.conf ]] && pFile="${pFile}.conf"


function action_new() {
  [ -z "${pTemplate}" ] && wsActionError "Template file not supplied"
  
  local targetFile="${NGINX_SITES_AVAILABLE_DIR}/${pFile}"
  [ -f "${targetFile}" ] && wsActionWarn "Configuration file already exists" && return

  local sourceFile="${NGINX_SITES_AVAILABLE_DIR}/${pTemplate}"
  [ ! -f "${sourceFile}" ] && wsActionError "Template file not found, ${sourceFile}"

  wsTemplateFile "${targetFile}" "${sourceFile}" "${pVar}"
  if [ -n "${pMode}" ]
  then
    chmod ${pMode} ${targetFile}
  fi
  wsActionInfo "Configuration created, ${NGINX_SITES_AVAILABLE}/${pFile}"
}


function action_enable() {
  [ ! -f "${NGINX_SITES_AVAILABLE_DIR}/${pFile}" ] && wsActionError "Configuration file not found, ${pFile}"

  local linkFile="${NGINX_SITES_ENABLED_DIR}/${pFile}"
  if [ -f "${linkFile}" ]
  then
    wsActionWarn "Configuratio already enabled, ${NGINX_SITES_ENABLED}/${pFile}" && return
  else
    ln -s "../${NGINX_SITES_AVAILABLE}/${pFile}" "${linkFile}"
    if [ $? -ne 0 ]
    then
      wsActionError "Failed to enable configuration, ${pFile}"
    fi
  fi
  wsActionInfo "Configuration enabled, ${NGINX_SITES_ENABLED}/${pFile}"
}


function action_disable() {
  local linkFile="${NGINX_SITES_ENABLED_DIR}/${pFile}"
  if [ -f "${linkFile}" ]
  then
    rm "${linkFile}"
    if [ $? -ne 0 ]
    then
      wsActionError "Failed to disable configuration, ${pFile}"
    fi
  else
    wsActionWarn "Configuration not found/enabled, ${NGINX_SITES_ENABLED}/${pFile}" && return
  fi
  wsActionInfo "Configuration disabled, ${NGINX_SITES_ENABLED}/${pFile}"
}

action_${pAction}
