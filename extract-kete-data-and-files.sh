#!/bin/bash

set -e

# extract-kete-data-and-files.sh
#
# copies a Kete site's mysqldump to postgresql importable file as well as
# files that have been uploaded to the Kete site.
#
# expects to be run from app's root directory
#
# run like so:
# extract-kete-data-and-files.sh
# or specify options via env vars before calling as outlined in help function
#
# Walter McGinnis, 2019-05-28

helpFunction()
{
   echo ""
   echo "Usage: [options as env var declarations] ./extract-kete-data-and-files.sh [help]"
   echo ""
   echo "Database export options:"
   echo -e "\t PG_TARGET_PATH -> a valid host/path that can be passed as a target to scp"
   echo -e "\t to copy the pg importable file to - leave blank to handle copying yourself"
   echo ""
   echo -e "\t LEAVE_MYSQLDUMP -> whether to leave the mysqldump file hanging around"
   echo -e "\t false by default, which will clean up the file"
   echo ""
   echo "File export options:"
   echo ""
   echo -e "\t EXPORT_TYPE -> default \"tar\", can be \"rsync\" or \"tar\""
   echo -e "\t whether to create gzipped tar file of files to manually copy after script runs"
   echo -e "\t or rsync files (network copy) incrementally"
   echo -e "\t use \"rsync\" if you don't have enough space for full copy on current host"
   echo -e "\t \"rsync\" type depends on RSYNC_TARGET_PATH being declared, see below"
   echo ""
   echo -e "\t INCLUDE_NON_ORIGINAL_IMAGES -> default false"
   echo -e "\t whether to copy the resized versions of image files rather than just original"
   echo ""
   echo -e "\t RSYNC_TARGET_PATH-> a valid host/path that can be passed as a target to rsync"
   echo -e "\t to copy uploaded file tree to - required if you using "rsync" for EXPORT_TYPE"
   echo ""
   echo "Examples:"
   echo ""
   echo -e "\t PG_TARGET_PATH=\"username@host:/path/to/directory\" ./extract-kete-data-and-files.sh"
   echo ""
   echo -e "\t this will first create a pg importable sql file, gzip it,"
   echo -e "\t then scp it to host and path specified in PG_TARGET_PATH"
   echo -e "\t it will rm the mysqldump file because LEAVE_MYSQLDUMP is false by default"
   echo -e "\t then it will create a gzipped tar file of the Kete site's uploaded files"
   echo -e "\t because EXPORT_TYPE is \"tar\" by default"
   echo -e "\t Note: including directories as their names correspond to ids in database"
   echo -e "\t with INCLUDE_NON_ORIGINAL_IMAGES not specified (false by default),"
   echo -e "\t it will skip any Kete generated resized version files of the original"
   echo ""
   echo -e "\t EXPORT_TYPE=\"rsync\" RSYNC_TARGET_PATH=\"username@host:/path/to/directory\" ./extract-kete-data-and-files.sh"
   echo ""
   echo -e "\t this will first create a pg importable sql file, gzip it,"
   echo -e "\t then only display where to find it"
   echo -e "\t it will rm the mysqldump file because LEAVE_MYSQLDUMP is false by default"
   echo -e "\t then, because EXPORT_TYPE is \"rsync\" and RSYNC_TARGET_PATH is specified,"
   echo -e "\t it call rsync for the directory structure that holds the Kete site's uploaded files"
   echo -e "\t with INCLUDE_NON_ORIGINAL_IMAGES not specified (false by default),"
   echo -e "\t it will skip any Kete generated resized version files of the original"
   echo ""
   echo -e "\t ./extract-kete-data-and-files.sh help"
   echo ""
   echo -e "\t shows this info"
   echo ""

   exit 1 # Exit script after printing help
}

if [[ -n "${1// /}" && "$1" = "help" ]]; then
    helpFunction
fi

ROOT_DIR="$(pwd)"

dump_command="./export-mysqldump-to-pg-importable.sh"

if [[ -n "${LEAVE_MYSQLDUMP// /}" && "$LEAVE_MYSQLDUMP" = true ]]; then
    dump_command="LEAVE_MYSQLDUMP=true $dump_command"
fi

if [[ -n "${PG_TARGET_PATH// /}" ]]; then
    dump_command="PG_TARGET_PATH=$PG_TARGET_PATH $dump_command"
fi

eval $dump_command

# run specified file export script

files_command="./export-uploaded-files-to-tar.sh"
if [[ -n "${EXPORT_TYPE// /}" && "$EXPORT_TYPE" = "rsync" ]]; then
    files_command="./export-uploaded-files-via-rsync.sh"

    if [[ -n "${RSYNC_TARGET_PATH// /}" ]]; then
        files_command="RSYNC_TARGET_PATH=$RSYNC_TARGET_PATH $files_command"
    else
        echo "Must declare RSYNC_TARGET_PATH if EXPORT_TYPE is rsync"
        exit 1
    fi
fi

if [[ -n "${INCLUDE_NON_ORIGINAL_IMAGES// /}" && "$INCLUDE_NON_ORIGINAL_IMAGES" = true ]]; then
    files_command="INCLUDE_NON_ORIGINAL_IMAGES=true $files_command"
fi

eval $files_command

echo "extract-kete-data-and-files.sh finished"
