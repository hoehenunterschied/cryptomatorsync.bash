#!/bin/bash
# for f in OneDrive GoogleDrive Dropbox iCloudDriveCopy; do echo -e "########################################\n###\n### $f\n###"; iclouddrivesync.bash $f sync;done
# for f in OneDrive GoogleDrive Dropbox iCloudDriveCopy; do echo -e "########################################\n###\n### $f\n###"; iclouddrivesync.bash $f difference;done

SOURCE_DIR="/Users/theuser/Cryptomator/iCloudDrive"
RSYNC_OPTS="--archive --hard-links --whole-file --one-file-system --checksum --verbose --delete"
DIFF_OPTS="--brief --recursive"

n=0
n=$(($n+1)); TARGET_NAME[n]="OneDrive";        TARGET_LIST[n]="/Users/theuser/Cryptomator/OneDrive";          CRYPTOMATOR_LIST[n]="YES";
n=$(($n+1)); TARGET_NAME[n]="GoogleDrive";     TARGET_LIST[n]="/Users/theuser/Cryptomator/GoogleDrive";       CRYPTOMATOR_LIST[n]="YES";
n=$(($n+1)); TARGET_NAME[n]="Dropbox";         TARGET_LIST[n]="/Users/theuser/Cryptomator/Dropbox";           CRYPTOMATOR_LIST[n]="YES";
n=$(($n+1)); TARGET_NAME[n]="iCloudDriveCopy"; TARGET_LIST[n]="/Volumes/TimeMachine/Media/iCloudDriveCopy"; CRYPTOMATOR_LIST[n]="NO";

for m in `seq 1 $n`;do
  if [[ $m == 1 ]]; then
    TARGET_NAME_STRING=${TARGET_NAME[$m]};
  else
    TARGET_NAME_STRING="$TARGET_NAME_STRING|${TARGET_NAME[$m]}";
  fi
done

usage()
{
   echo "";
   echo "Usage : `basename $0` $TARGET_NAME_STRING [sync|difference]"
   echo "";
}

#sync actually syncs (changes are applied to target directory)
sync()
{
  rsync ${RSYNC_OPTS} "${SOURCE_DIR}/" "${TARGET_DIR}/"
}

#difference is an alternative to dryrun to check for differences
difference()
{
  diff ${DIFF_OPTS} "${SOURCE_DIR}" "${TARGET_DIR}"
}

#dryrun shows what needs to be changed to sync
dryrun()
{
  rsync --dry-run ${RSYNC_OPTS} "${SOURCE_DIR}/" "${TARGET_DIR}/"
  echo -e "####\n#### WARNING: This was a dry run\n####          nothing has been synced"
}

case "$1" in
    ${TARGET_NAME[1]})
      TARGET_DIR=${TARGET_LIST[1]};
      IS_CRYPTOMATOR=${CRYPTOMATOR_LIST[1]};
      ;;
    ${TARGET_NAME[2]})
      TARGET_DIR=${TARGET_LIST[2]};
      IS_CRYPTOMATOR=${CRYPTOMATOR_LIST[2]};
      ;;
    ${TARGET_NAME[3]})
      TARGET_DIR=${TARGET_LIST[3]};
      IS_CRYPTOMATOR=${CRYPTOMATOR_LIST[3]};
      ;;
    ${TARGET_NAME[4]})
      TARGET_DIR=${TARGET_LIST[4]};
      IS_CRYPTOMATOR=${CRYPTOMATOR_LIST[4]};
      ;;
    *)
      usage;
      exit;
esac

if ! mount | grep "${SOURCE_DIR}" > /dev/null 2>&1; then
    MUST_PRINT="YES"
fi
if [ "$IS_CRYPTOMATOR" == "YES" ]; then
    if ! mount | grep "${TARGET_DIR}" > /dev/null 2>&1; then
        MUST_PRINT="YES"
    fi
else
    if [ ! -d "${TARGET_DIR}" ]; then
        MUST_PRINT="YES"
    fi
fi
if [ "$MUST_PRINT" == "YES" ]; then
    echo -e "########################################\n####";
    if ! mount | grep "${SOURCE_DIR}" > /dev/null 2>&1; then
        echo -e "#### open the Cryptomator Tresor for: \"$SOURCE_DIR\"";
    fi
    if [ "$IS_CRYPTOMATOR" == "YES" ]; then
        if ! mount | grep "${TARGET_DIR}" > /dev/null 2>&1; then
            echo -e "#### open the Cryptomator Tresor for: \"$TARGET_DIR\"";
        fi
    else
        if [ ! -d "${TARGET_DIR}" ]; then
            echo -e "#### target directory does not exist: \"$TARGET_DIR\"";
        fi
    fi
    echo -e "####";
    exit
fi

case "$2" in
    sync)
      sync
      ;;
    difference)
      difference
      ;;
    *)
      dryrun;
esac

