# cryptomatorsync.bash
Sync the content of an unlocked cryptomator vault with other directories. The other directories can be Cryptomator vaults or
just directories.

The script checks if the source vault is unlocked, for target directories if they exist and, in case of Cryptomator vaults, if they are
unlocked before synching anything.

Before using, this script needs to be adapted. Change the SOURCE_DIR to the correct location and edit the list of target directories
by adapting the TARGET_NAME array. Flag target directories that are Cryptomator mount points with "YES".

The script checks if Cryptomator mount points are actually mounted (unlocked) before syncing.
