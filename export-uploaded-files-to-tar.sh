#!/bin/bash

set -e

# export-uploaded-files-to-tar.sh
#
# copies Kete site's uploaded files to tarball with timestamp based name
# note this is done recursively and preserves directory structure
# as this important for id lookup
#
# ALSO NOTE: this may not be suitable
# if you don't have extra disk space for what amounts to a (compressed) copy
# of all of your uploaded files
#
# expects to be run from app's root directory
# i.e. the parent of both public and private directories
#
# run like so:
# export-uploaded-files-to-tar.sh
# or if you want to _include_ generated images rather than just original images
# INCLUDE_NON_ORIGINAL_IMAGES=true export-uploaded-files-to-tar.sh
#
# Walter McGinnis, 2019-05-21

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

ROOT_DIR="$(pwd)"

files_counter=0

for top in "${TOP_LEVEL_DIRECTORIES[@]}"
do
    echo "starting $top"

    WORKING_DIR=$top
    present_subs_string=""

    cd $top

    for subdir in "${SUBDIRECTORY_NAMES[@]}"
    do
        echo "starting $subdir"
        if [ ! -d "$subdir" ]; then
            echo "skipping $subdir, not present"
        else
            present_subs_string="$present_subs_string $subdir"
        fi
    done

    if [[ -n "${present_subs_string// /}" ]]; then
        target_file="$(date +%FT%H-%M-%S)-$top.tar.gz"

        command_args="$target_file $present_subs_string"
        if [ $ONLY_ORIGINAL_IMAGE_FILES ]; then
            # NOTE: these are default resizing for Kete, if have customized your resizing names, they may not be excluded
            exclude_patterns=("*_small_sq.jpg" "*_small_sq.JPG" "*_small_sq.jpeg" "*_small_sq.gif" "*_small_sq.GIF" "*_small_sq.png" "*_small_sq.PNG")
            exclude_patterns=("${exclude_patterns[@]}" "*_small.jpg" "*_small.JPG" "*_small.jpeg" "*_small.gif" "*_small.GIF" "*_small.png" "*_small.PNG")
            exclude_patterns=("${exclude_patterns[@]}" "*_medium.jpg" "*_medium.JPG" "*_medium.jpeg" "*_medium.gif" "*_medium.GIF" "*_medium.png" "*_medium.PNG")
            exclude_patterns=("${exclude_patterns[@]}" "*_large.jpg" "*_large.JPG" "*_large.jpeg" "*_large.gif" "*_large.GIF" "*_large.png" "*_large.PNG")

            exclude_args=""
            for pattern in "${exclude_patterns[@]}"
            do
                exclude_args="$exclude_args --exclude=$pattern"
            done

            command_args="$target_file $exclude_args $present_subs_string"
        fi

        echo "creating tar file for $top"

        tar czf $command_args

        echo "done creating tar file"

        move_to_dir="$ROOT_DIR/"
        mv $target_file "$move_to_dir"

        echo "tarfile at $ROOT_DIR/$target_file"
    else
        echo "no files for $top"
    fi

    cd "$ROOT_DIR"

    echo "done with $top"
done
