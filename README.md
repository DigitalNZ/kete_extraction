# kete_extraction
Tool for pulling data and uploaded files from a Kete site

## Structure

This tool is made up of simple bash scripts that know how to extract data
and files for a Kete site.

The various subscripts are called from a wrapper script called
`extract-kete-data-and-files.sh`

## Usage

* scp the `kete_extraction.tar.gz` file to your Kete app's root
  directory on the host where Kete site runs.

* `tar xfz kete_extraction.tar.gz` to unpack the scripts you will need
  for kete data and uploaded file extraction

* run `./extract-kete-data-and-files.sh help` to see what options are
  expected

* run `[env var declarations here]./extract-kete-data-and-files.sh` with the env vars
  declared that are necessary for your situation
