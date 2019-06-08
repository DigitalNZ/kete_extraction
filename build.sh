#!/bin/bash

set -e

# build.sh
#
# creates a gzip'd tarball of the needed extraction scripts
#
# expects to be run from kete_extraction directory
#
# run like so:
# ./build.sh
#
# Walter McGinnis, 2019-06-09

tar cfz kete_extraction.tar.gz extract-kete-data-and-files.sh export-mysqldump-to-pg-importable.sh export-uploaded-files-to-tar.sh export-uploaded-files-via-rsync.sh
