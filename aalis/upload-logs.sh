#!/usr/bin/env bash

set -e

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

echo -ne "\e[95m"
echo    "---------------------------------"
echo    "         Preflight Check         "
echo -n "---------------------------------"
echo -e "\e[39m"
if [ -f ${SCRIPT_DIR}/script_funcs ]; then source ${SCRIPT_DIR}/script_funcs; output ${LIGHT_GREEN} "FOUND ${SCRIPT_DIR}/script_funcs!"; else echo -e "\e[31mCannot find ${SCRIPT_DIR}/script_funcs, cannot continue\e[39m"; sleep 2; exit 1; fi
output ${LIGHT_GREEN} "Preflight Check done! Moving on in 2 seconds"
sleep 2
clear


if [[ "yes" == $(askYesNo "Would you like to upload the logs to termbin.com for developer help?") ]]; then
    output ${LIGHT_GREEN} "Ok! I will uplod the log files now"
else
    output  ${LIGHT_RED} "Ok, I'm leaving then!"
    exit 1;
fi

cat ${SCRIPT_DIR}/logs/* | nc termbin.com 9999
output ${LIGHT_GREEN} "All done!"
