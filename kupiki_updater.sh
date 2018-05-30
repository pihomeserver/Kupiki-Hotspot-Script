#!/usr/bin/env bash

set -fb

THISDIR=$(cd "$(dirname "$0")" ; pwd)
MY_NAME=$(basename "$0")
FILE_TO_FETCH_URL="https://raw.githubusercontent.com/pihomeserver/Kupiki-Hotspot-Script/master/kupiki_updater.sh"
EXISTING_SHELL_SCRIPT="${THISDIR}/kupiki_updater.sh"
EXECUTABLE_SHELL_SCRIPT="${THISDIR}/.kupiki_updater.sh"

LOGNAME="kupiki_updater.log"
LOGPATH="/var/log/"
KUPIKI_SCRIPT_ARCHIVE="https://raw.githubusercontent.com/pihomeserver/Kupiki-Hotspot-Script/master/pihotspot.sh"

check_returned_code() {
    RETURNED_CODE=$@
    if [ $RETURNED_CODE -ne 0 ]; then
        display_message ""
        display_message "Something went wrong with the last command. Please check the log file"
        display_message ""
        exit 1
    fi
}

display_message() {
    MESSAGE=$@
    # Display on console
    echo "::: $MESSAGE"
    # Save it to log file
    echo "::: $MESSAGE" >> $LOGPATH$LOGNAME
}

execute_command() {
    display_message "$3"
    COMMAND="$1 >> $LOGPATH$LOGNAME 2>&1"
    eval $COMMAND
    COMMAND_RESULT=$?
    if [ "$2" != "false" ]; then
        check_returned_code $COMMAND_RESULT
    fi
}

prepare_logfile() {
    echo "::: Preparing log file"
    if [ -f $LOGPATH$LOGNAME ]; then
        echo "::: Log file already exists. Creating a backup."
        execute_command "mv $LOGPATH$LOGNAME $LOGPATH$LOGNAME.`date +%Y%m%d.%H%M%S`"
    fi
    echo "::: Creating the log file"
    execute_command "touch $LOGPATH$LOGNAME"
    display_message "Log file created : $LOGPATH$LOGNAME"
    display_message "Use command 'tail -f $LOGPATH$LOGNAME' in a new console to get updater process details"
}

check_root() {
  # Must be root to update the hotspot
  echo ":::"
  if [[ $EUID -eq 0 ]];then
    echo "::: You are root - OK"
  else
    echo "::: Please run this as root."
    exit 1
  fi
}

check_requirements() {
  if [ ! -e /etc/kupiki/version ]; then
    display_message "Unable to find current version. Please reinstall Kupiki Hotspot"
    exit 1
  fi
  display_message "Getting current installed version"
  KUPIKI_CURRENT_VERSION=`cat /etc/kupiki/version`

  if [ $KUPIKI_CURRENT_VERSION \< "2.0.0" ]; then
    display_message "Only installation greater than 2.0.0 can be updated"
    exit 1
  fi
}

get_remote_file() {
  readonly REQUEST_URL=$1
  readonly OUTPUT_FILENAME=$2
  readonly TEMP_FILE="${THISDIR}/tmp.file"

  if [ -n "$(which wget)" ]; then
    $(wget -O "${TEMP_FILE}" "$REQUEST_URL" 2>&1)
    if [[ $? -eq 0 ]]; then
      mv "${TEMP_FILE}" "${OUTPUT_FILENAME}"
      chmod 700 "${OUTPUT_FILENAME}"
    else
      return 1
    fi
  fi
}

function clean_up() {
  # clean up code (if required) that has to execute every time here
  echo
}
function self_clean_up() {
  rm -f "${EXECUTABLE_SHELL_SCRIPT}"
}

function update_self_and_invoke() {
  get_remote_file "${FILE_TO_FETCH_URL}" "${EXECUTABLE_SHELL_SCRIPT}"
  if [ $? -ne 0 ]; then
    cp "${EXISTING_SHELL_SCRIPT}" "${EXECUTABLE_SHELL_SCRIPT}"
  fi
  exec "${EXECUTABLE_SHELL_SCRIPT}" "$@"
}
function main() {
  cp "${EXECUTABLE_SHELL_SCRIPT}" "${EXISTING_SHELL_SCRIPT}"
  # your code here
  check_root

  prepare_logfile

  check_requirements

  display_message "Getting latest version of the updater script"
  KUPIKI_LATEST_VERSION=`wget --quiet -O - $KUPIKI_SCRIPT_ARCHIVE | grep ^KUPIKI_VERSION | cut -d '"' -f 2`

  display_message "Latest version : ${KUPIKI_LATEST_VERSION}"
  display_message "Current installed version : ${KUPIKI_CURRENT_VERSION}"

  if [ ${KUPIKI_LATEST_VERSION} \< ${KUPIKI_CURRENT_VERSION} ]; then
    display_message ""
    display_message "Ooops seems you have a newer version of the script than the latest one on GitHub"
    display_message "Please input a new issue on GitHub to solve the problem"
    exit 1
  fi
}

if [[ $MY_NAME = \.* ]]; then
  echo "Execute - $MY_NAME"
  # invoke real main program
  trap "clean_up; self_clean_up" EXIT
  main "$@"
else
  echo "Update - $MY_NAME"
  # update myself and invoke updated version
  trap clean_up EXIT
  update_self_and_invoke "$@"
fi


