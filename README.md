# iclouddrivesync.bash
Sync one source directory with various target directories. Source and target directories can be Cryptomator file vaults.

Before using, this script needs to be adapted. Change the SOURCE_DIR to the correct location and edit the list of target directories
by adapting the TARGET_NAME array. Flag target directories that are Cryptomator mount points with "YES".

The script checks if Cryptomator mount points are actually mounted (unlocked) before syncing.
