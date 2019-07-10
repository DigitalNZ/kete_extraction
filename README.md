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

## Credits

This project was developed by [Walter McGinnis](waltermcginnis.com) for
migrating data from the  [Kete](old.kete.net.nz) open source
application and was funded by [Digital New Zealand](digitalnz.org).

## COPYRIGHT AND LICENSING  

GNU GENERAL PUBLIC LICENCE, VERSION 3  

Except as indicated in code, this project is Crown copyright (C) 2019,
New Zealand Government.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see http://www.gnu.org/licenses /
http://www.gnu.org/licenses/gpl-3.0.txt
