#!/bin/bash

set -e

# export-uploaded-files-via-rsync.sh
#
# copies Kete site's uploaded files to path on different host via rsync
# note this is done recursively and preserves directory structure
# as this important for id lookup
#
# expects to be run from app's root directory
# i.e. the parent of both public and private directories
#
# run like so:
# RSYNC_TARGET_PATH="host:/path/to/target" export-uploaded-files-via-rsync.sh
# or if you want to _include_ generated images rather than just original images
# RSYNC_TARGET_PATH="host:/path/to/target" INCLUDE_NON_ORIGINAL_IMAGES=true export-uploaded-files-via-rsync.sh
#
# Walter McGinnis, 2019-05-21

# RSYNC_TARGET_PATH
# takes rsync target path which is intended as rsync capable target over ssh
# and should have host, etc. - this assumes you have ssh access and open ports (or a tunnel), etc.
# NOTE: should also have private and public directories already created within!
# i.e. top level directories must have corresponding directories
# within rsync target path directory

# default to skip generated resized image files, only copy original
ONLY_ORIGINAL_IMAGE_FILES=1
if [[ -n "${INCLUDE_NON_ORIGINAL_IMAGES// /}" && "$INCLUDE_NON_ORIGINAL_IMAGES" = true ]]; then
    ONLY_ORIGINAL_IMAGE_FILES=0
fi

TOP_LEVEL_DIRECTORIES=("private" "public")

# we only care about certain directories that hold uploaded files
# that go with our content items
# note that themes and imports are skipped as they aren't data related
# however they may be worth preserving for your project, if so add them here
SUBDIRECTORY_NAMES=("audio" "documents" "image_files" "video")

# input validation
if [[ -n "${RSYNC_TARGET_PATH// /}" ]]; then
    echo "Will copy to $RSYNC_TARGET_PATH"
else
    echo "Must declare RSYNC_TARGET_PATH"
    exit 1
fi

ROOT_DIR="$(pwd)"

exclude_args=""
if [ $ONLY_ORIGINAL_IMAGE_FILES ]; then
    # NOTE: these are default resizing for Kete, if have customized your resizing names, they may not be excluded
    exclude_patterns=("*_small_sq.jpg" "*_small_sq.JPG" "*_small_sq.jpeg" "*_small_sq.gif" "*_small_sq.GIF" "*_small_sq.png" "*_small_sq.PNG")
    exclude_patterns=("${exclude_patterns[@]}" "*_small.jpg" "*_small.JPG" "*_small.jpeg" "*_small.gif" "*_small.GIF" "*_small.png" "*_small.PNG")
    exclude_patterns=("${exclude_patterns[@]}" "*_medium.jpg" "*_medium.JPG" "*_medium.jpeg" "*_medium.gif" "*_medium.GIF" "*_medium.png" "*_medium.PNG")
    exclude_patterns=("${exclude_patterns[@]}" "*_large.jpg" "*_large.JPG" "*_large.jpeg" "*_large.gif" "*_large.GIF" "*_large.png" "*_large.PNG")


    for pattern in "${exclude_patterns[@]}"
    do
        exclude_args="$exclude_args --exclude=$pattern"
    done
fi


for top in "${TOP_LEVEL_DIRECTORIES[@]}"
do
    echo "starting $top"

    WORKING_DIR=$top

    cd $top

    for subdir in "${SUBDIRECTORY_NAMES[@]}"
    do
        echo "starting $subdir"
        if [ ! -d "$subdir" ]; then
            echo "skipping $subdir, not present"
        else
            rsync -avzh --copy-links $exclude_args $subdir "$RSYNC_TARGET_PATH/$WORKING_DIR/"
        fi
    done

    cd "$ROOT_DIR"

    echo "done with $top"
done
