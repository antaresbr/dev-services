#!/bin/bash

SCRIPT_DIR="$(dirname "$0")"
BASE_DIR="$(dirname "${SCRIPT_DIR}")"

function pcsError() {
  local msgPrefix="post-clone/setup"
  if [ $# -gt 1 ]
  then
    msgPrefix="${msgPrefix} | $1"
    shift
  fi
  if [[ $(type -t wsError) == function ]]
  then
    wsError "${msgPrefix}" "$@"
  else
    echo ""
    echo "${msgPrefix} | ERROR: $@"
    echo ""
  fi
  exit 1
}

setupLibFile="${SCRIPT_DIR}/setup.lib.sh"
[ -L "${setupLibFile}" ] && [ ! -e "${setupLibFile}" ] && rm "${setupLibFile}"
if [ ! -f "${setupLibFile}" ]
then
  if [ -f "${BASE_DIR}/.workspace-lib/post-clone/$(basename "${setupLibFile}")" ]
  then
    ln -s "../.workspace-lib/post-clone/$(basename "${setupLibFile}")" "${setupLibFile}"
  else
    curl "https://raw.githubusercontent.com/antaresbr/dev-workspace-lib/master/post-clone/setup.lib.sh" \
      --silent \
      --output "${setupLibFile}"
  fi
fi
[ -f "${setupLibFile}" ] || pcsError "File not found, ${setupLibFile}"
source "${setupLibFile}"
[ $? -eq 0 ] || pcsError "Failed to source file, ${setupLibFile}"

[ -L "${SCRIPT_DIR}/lib" ] && rm "${SCRIPT_DIR}/lib"
if [ -L "${setupLibFile}" ] || [ -e "${setupLibFile}" ]
then
  rm "${setupLibFile}"
fi

echo ""
