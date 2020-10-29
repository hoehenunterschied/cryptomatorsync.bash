#!/bin/bash
# Ralf Lange 2020

# the string has to match one entry in TARGET_NAME and defines which of the directories is the master.
# the other directories are checked for being identical clones of the master (actions dryrun and difference),
# or are made an identical copy of the master (action sync).
MASTER="Master"

TARGET_NAME=();                 TARGET_LIST=();                                                       CRYPTOMATOR_LIST=();
TARGET_NAME+=("Master");        TARGET_LIST+=("/Users/steve/Cryptomator/Master")                      CRYPTOMATOR_LIST+=(true);
TARGET_NAME+=("OneDrive");      TARGET_LIST+=("/Users/steve/Cryptomator/OneDriveMasterCopy")          CRYPTOMATOR_LIST+=(true);
TARGET_NAME+=("TimeMachine");   TARGET_LIST+=("/Volumes/TimeMachine/Media/Cryptomator/MasterCopy");   CRYPTOMATOR_LIST+=(false);
TARGET_NAME+=("GoogleDrive");   TARGET_LIST+=("/Users/steve/Cryptomator/GoogleDriveMasterCopy");      CRYPTOMATOR_LIST+=(true);
TARGET_NAME+=("OraDocs");       TARGET_LIST+=("/Users/steve/Cryptomator/OraDocsMasterCopy");          CRYPTOMATOR_LIST+=(true);
TARGET_NAME+=("Dropbox");       TARGET_LIST+=("/Users/steve/Cryptomator/DropboxMasterCopy");          CRYPTOMATOR_LIST+=(true);
TARGET_NAME+=("SanDisk");       TARGET_LIST+=("/Users/steve/Cryptomator/SanDiskMasterCopy");          CRYPTOMATOR_LIST+=(true);
TARGET_NAME+=("Stick");         TARGET_LIST+=("/Users/steve/Cryptomator/StickMasterCopy");            CRYPTOMATOR_LIST+=(true);
TARGET_NAME+=("Stick16");       TARGET_LIST+=("/Users/steve/Cryptomator/Stick16MasterCopy");          CRYPTOMATOR_LIST+=(true);
TARGET_NAME+=("Spaceloop");     TARGET_LIST+=("/Users/steve/Cryptomator/SpaceloopMasterCopy");        CRYPTOMATOR_LIST+=(true);

# ----------------------------------
# Colors
# ----------------------------------
NOCOLOR='\x1B[0m'
RED='\x1B[0;31m'
GREEN='\x1B[0;32m'
ORANGE='\x1B[0;33m'
BLUE='\x1B[0;34m'
PURPLE='\x1B[0;35m'
CYAN='\x1B[0;36m'
LIGHTGRAY='\x1B[0;37m'
DARKGRAY='\x1B[1;30m'
LIGHTRED='\x1B[1;31m'
LIGHTGREEN='\x1B[1;32m'
YELLOW='\x1B[1;33m'
LIGHTBLUE='\x1B[1;34m'
LIGHTPURPLE='\x1B[1;35m'
LIGHTCYAN='\x1B[1;36m'
WHITE='\x1B[1;37m'

# the options used with rsync and diff
RSYNC_OPTS="--archive --hard-links --whole-file --one-file-system --checksum --verbose --delete"
DIFF_OPTS="--brief --recursive"

# the pseudo target all: the action (difference, dryrun, sync) is executed on all available targets
PSEUDO_TARGET_ALL="ALL"
ACTION_SYNC="sync"
ACTION_DIFFERENCE="difference"
ACTION_DRYRUN="dryrun"
ACTION_ALL="ALL"
ACTIONS=("${ACTION_SYNC}" "${ACTION_DIFFERENCE}" "${ACTION_DRYRUN}")

# do not change value if set in environment
DEBUG_PRINT="${DEBUG_PRINT:=true}"
# if set to false only print what this script would do, don't execute
EXECUTE=true

debug_print()
{
  if [ "${DEBUG_PRINT}" == true ]; then
    echo -e "$1"
  fi
}

# build a list of all targets for the usage function
# assign SOURCE_DIR and SOURCE_IS_CRYPTOMATOR
SOURCE_DIR=""
TARGET_NAME_STRING="${GREEN}${PSEUDO_TARGET_ALL}${NOCOLOR}"
for i in "${!TARGET_NAME[@]}"; do
  if [[ "${TARGET_NAME[$i]}" == "${MASTER}" ]]; then
    SOURCE_DIR="${TARGET_LIST[$i]}"
    SOURCE_IS_CRYPTOMATOR=${CRYPTOMATOR_LIST[$i]}
    continue
  fi
  #### color the target names according to state
  N_DIR="${TARGET_LIST[$i]}"
  N_CRYPTOMATOR=${CRYPTOMATOR_LIST[$i]}
  N_COLOR="${GREEN}"
  if [[ -r "${N_DIR}" ]]; then
    if "${N_CRYPTOMATOR}"; then
      if ! mount | grep "^Cryptomator@osxfuse[0-9]\+ on ${N_DIR} " > /dev/null 2>&1; then
        N_COLOR="${YELLOW}"
      fi
    fi
  else
    N_COLOR="${YELLOW}"
  fi
  ####
  TARGET_NAME_STRING="$TARGET_NAME_STRING|${N_COLOR}${TARGET_NAME[$i]}${NOCOLOR}";
done
# if MASTER does not match any name in TARGET_NAME[]
if [[ "${SOURCE_DIR}" == "" ]]; then
  echo -e "\n\"${MASTER}\" does not match one of ${TARGET_NAME[@]}\n"
  exit
fi

#debug_print "SOURCE_DIR=\"${SOURCE_DIR}\", SOURCE_IS_CRYPTOMATOR=\"${SOURCE_IS_CRYPTOMATOR}\""

# build a string of all actions
ACTION_STRING=""
for action in "${ACTIONS[@]}"; do
  ACTION_STRING="$ACTION_STRING|${action}"
done
ACTION_STRING="${ACTION_STRING#|}"

usage()
{
  echo -e "\nUsage : $(basename $0) $TARGET_NAME_STRING ${NOCOLOR}$ACTION_STRING${NOCOLOR}\n"
}

#sync actually syncs (changes are applied to target directory)
sync()
{
  if ! ${EXECUTE}; then
    PRINT_ONLY="echo"
  fi
  ${PRINT_ONLY} rsync ${RSYNC_OPTS} "${SOURCE_DIR}/" "${TARGET_DIR}/"
}

#difference is an alternative to dryrun to check for differences
difference()
{
  if ! ${EXECUTE}; then
    PRINT_ONLY="echo"
  fi
  ${PRINT_ONLY} diff ${DIFF_OPTS} "${SOURCE_DIR}" "${TARGET_DIR}"
}

#dryrun shows what needs to be changed to sync
dryrun()
{
  if ! ${EXECUTE}; then
    PRINT_ONLY="echo"
  fi
  ${PRINT_ONLY} rsync --dry-run ${RSYNC_OPTS} "${SOURCE_DIR}/" "${TARGET_DIR}/"
  echo -e "${YELLOW}####${NOCOLOR}\n${YELLOW}#### WARNING${NOCOLOR}: This was a dry run\n${YELLOW}####${NOCOLOR}          nothing has been synced"
}

# check if parameter for target matches a list entry
unset IS_CRYPTOMATOR
for i in "${!TARGET_LIST[@]}"; do
  if [[ ${TARGET_NAME[$i]} == "$1" ]]; then
    # ensure target and master are not the same
    if [[ "${1}" != "${MASTER}" ]]; then
      TARGET_DIR=${TARGET_LIST[$i]};
      IS_CRYPTOMATOR=${CRYPTOMATOR_LIST[$i]};
    fi
    break;
  fi
done
# show usage and exit if there was no match
if [ -z ${IS_CRYPTOMATOR} ] && [ "$1" != "${PSEUDO_TARGET_ALL}" ]; then
  usage;
  exit;
fi
# at this point $1 is verifyed to be PSEUDO_TARGET_ALL or in TARGET_NAME[]

check_and_execute()
{
  #debug_print "${FUNCNAME}(): SOURCE_DIR=\"${SOURCE_DIR}\", SOURCE_IS_CRYPTOMATOR=\"${SOURCE_IS_CRYPTOMATOR}\""
  #debug_print "${FUNCNAME}(): Target=\"$1\", Action=\"$2\""
  # check SOURCE
  # check if source directory exists
  if [[ ! -r "${SOURCE_DIR}" ]]; then
    # source directory not readable
    echo -e "${YELLOW}####\n####${NOCOLOR} source directory \"$SOURCE_DIR\" is not readable\n${YELLOW}####${NOCOLOR}"
    exit
  fi
  # if source is Cryptomator vault, check if vault is open
  if ${SOURCE_IS_CRYPTOMATOR}; then
    if ! mount | grep "^Cryptomator@osxfuse[0-9]\+ on ${SOURCE_DIR} " > /dev/null 2>&1; then
      echo -e "${YELLOW}####\n####${NOCOLOR} Master Cryptomator Vault not mounted on  \"${SOURCE_DIR}\"\n${YELLOW}####${NOCOLOR}"
      exit
    fi
  fi
  # check TARGET
  # target == master has been excluded
  declare -a TARGETS; declare -a TARGETS_CRYPTOMATOR
  if [[ "$1" == "${PSEUDO_TARGET_ALL}" ]]; then
    # iterate through all targets except master
    for i in "${!TARGET_LIST[@]}"; do
      if [[ "${TARGET_NAME[$i]}" != "${MASTER}" ]]; then
        TARGETS+=("${TARGET_LIST[$i]}"); TARGETS_CRYPTOMATOR+=("${CRYPTOMATOR_LIST[$i]}")
      fi 
    done
  else
     for i in "${!TARGET_LIST[@]}"; do
       if [[ "${TARGET_NAME[$i]}" == "$1" ]]; then
        TARGETS+=("${TARGET_LIST[$i]}"); TARGETS_CRYPTOMATOR+=("${CRYPTOMATOR_LIST[$i]}")
        break
       fi
     done
  fi
  # arrays TARGETS and TARGETS_CRYPTOMATOR are now filled with targets for ALL or the single target
  for i in "${!TARGETS[@]}"; do
    #debug_print "${TARGETS[$i]}, ${TARGETS_CRYPTOMATOR[$i]}"
    TARGET_DIR="${TARGETS[$i]}"; TARGET_IS_CRYPTOMATOR="${TARGETS_CRYPTOMATOR[$i]}"
    #debug_print "TARGET_DIR=\"${TARGET_DIR}\"; TARGET_IS_CRYPTOMATOR=\"${TARGET_IS_CRYPTOMATOR}\""
    # check if directory exists
    if [[ ! -r "${TARGET_DIR}" ]]; then
      # target directory not readable
      echo -e "${YELLOW}####${NOCOLOR} skipping directory \"$TARGET_DIR\": not readable ${YELLOW}####${NOCOLOR}"
      continue;
    fi
    # if action is sync also check if directory if writable
    if [[ "$2" == "${ACTION_SYNC}" ]]; then
      if [[ ! -w "${TARGET_DIR}" ]]; then
        # target directory not writable for sync action
        echo -e "${YELLOW}####${NOCOLOR} skipping directory \"$TARGET_DIR\": not writable ${YELLOW}####${NOCOLOR}"
        continue;
      fi
    fi
    # if target is Cryptomator vault, check if vault is open
    if ${TARGET_IS_CRYPTOMATOR}; then
      if ! mount | grep "^Cryptomator@osxfuse[0-9]\+ on ${TARGET_DIR} " > /dev/null 2>&1; then
        echo -e "${YELLOW}####${NOCOLOR} skipping directory \"${TARGET_DIR}\": Cryptomator vault not mounted ${YELLOW}####${NOCOLOR}"
        continue
      fi
    fi
    case "$2" in
      "${ACTION_SYNC}")
        echo -e "${YELLOW}$(date +'%Y%m%d %H:%M:%S')${NOCOLOR} sync \"${SOURCE_DIR}\" to \"${TARGET_DIR}\""
        sync
        ;;
      "${ACTION_DIFFERENCE}")
        echo -e "${YELLOW}$(date +'%Y%m%d %H:%M:%S')${NOCOLOR} diff between \"${SOURCE_DIR}\" and \"${TARGET_DIR}\""
        difference
        ;;
      "${ACTION_DRYRUN}")
        echo -e "${YELLOW}$(date +'%Y%m%d %H:%M:%S')${NOCOLOR} sync dryrun \"${SOURCE_DIR}\" to \"${TARGET_DIR}\""
        dryrun
        ;;
      *)
        echo -e "\nUnknown action \"$2\"\nExiting.\n"
        exit
    esac
  done
  echo -e "${YELLOW}$(date +'%Y%m%d %H:%M:%S')${NOCOLOR}"
}

# processing of the second command line parameter
case "$2" in
  "${ACTION_SYNC}" | "${ACTION_DIFFERENCE}" | "${ACTION_DRYRUN}")
      check_and_execute "$1" "$2"
      ;;
    *)
      usage;
esac
