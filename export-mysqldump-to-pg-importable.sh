#!/bin/bash

set -e

# export-mysqldump-to-pg-importable.sh
#
# copies a Kete site's mysqldump to postgresql importable file.
#
# expects to be run from app's root directory
#
# run like so:
# export-mysqldump-to-pg-importable.sh
# or
# PG_TARGET_PATH=="host:/path/to/target" export-mysqldump-to-pg-importable.sh
# or
# PG_TARGET_PATH=="host:/path/to/target" LEAVE_MYSQLDUMP=true export-mysqldump-to-pg-importable.sh
#
# Walter McGinnis, 2019-05-24

ROOT_DIR="$(pwd)"

# read config/database.yml

# from https://stackoverflow.com/a/21189044
function parse_yaml {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

eval $(parse_yaml config/database.yml)

# build mysqldump command

dump_command_start="mysqldump -u $production_username -p$production_password"

ignore_tables=("bdrb_job_queues" "brain_busters" "feeds" "zoom_dbs" "schema_migrations" "searches" "search_sources" "captchas" "imports" "import_archive_files" "deleted_content_item_relations")

ignore_flags=""
for ignore_table in "${ignore_tables[@]}"
do
    ignore_flags="$ignore_flags --ignore-table=$production_database.$ignore_table"
done

start_timestamp=$(date +%FT%H-%M-%S)
target_mysql_file="$start_timestamp-$production_database-mysqldump.sql"

dump_command="$dump_command_start $ignore_flags --compatible=postgresql --skip-comments $production_database > $target_mysql_file"
# run mysqldump command

eval $dump_command

# add some reference info
tmp_mysql_file="tmp-$start_timestamp-$production_database-mysql.sql"
echo "-- dumped with options: --" > $tmp_mysql_file
echo "-- --compatible=postgresql --" >> $tmp_mysql_file
echo "-- $ignore_flags --" >> $tmp_mysql_file
echo "-- --skip-comments --" >> $tmp_mysql_file
cat $target_mysql_file >> $tmp_mysql_file
cp $tmp_mysql_file $target_mysql_file
rm $tmp_mysql_file

# replace mysql datatypes with corresponding pg ones,
# make other changes so that our import goes smoothly

# create new file
target_pg_file="$start_timestamp-$production_database-pg.sql"

cp $target_mysql_file $target_pg_file

inline_flag="-i"
cleanup=false
case "$(uname -s)" in
    Darwin)
        inline_flag="-i bak"
        cleanup=true
        ;;
esac

# replace problematic datatypes
sed $inline_flag -- "s/int(11)/integer/g" "$target_pg_file"
sed $inline_flag -- "s/tinyint(1)/boolean/g" "$target_pg_file"
sed $inline_flag -- "s/mediumtext/text/g" "$target_pg_file"
sed $inline_flag -- "s/datetime/timestamp/g" "$target_pg_file"

# replace problematic values
sed $inline_flag -- "s/\'0000-00-00 00:00:00\'/NULL/g" "$target_pg_file"

if [ $cleanup == true ]; then
    rm "${target_pg_file}bak"
fi

# write back out to tmp_pg_file when done, we'll copy it into target_pg_file
tmp_pg_file="tmp-$start_timestamp-$production_database-pg.sql"

# prepend settings changes for further pg compatibility:
echo "-- Converted by export-mysqldump-to-pg-importable.sh" > $tmp_pg_file
# for casting integer values (mysql) to boolean in pg
# from https://dba.stackexchange.com/a/46199
# also an end statement after commit to reverse
echo "update pg_cast set castcontext='a' where casttarget = 'boolean'::regtype;" > $tmp_pg_file

echo "START TRANSACTION;" >> $tmp_pg_file
echo "SET standard_conforming_strings=off;" >> $tmp_pg_file
echo "SET escape_string_warning=off;" >> $tmp_pg_file
echo "SET CONSTRAINTS ALL DEFERRED;" >> $tmp_pg_file

# collect constraints, etc. to be deferred
constraints=()
primary_keys=()

# in order to not end up with the tables that have statements stripped out
#  having extra trailing comma, we have to build up current table definition
# join lines
# and append all at once
current_table_lines=()
table_beginning=''
in_table_definition=0

skips=0
while read -r line
do
    # ignore these lines
    # lock, unlock, drop tables, comments, mysql specific commands
    # as well as KEY, UNIQUE KEY constraints
    # currently also skipping fk constraints and primary key
    if echo "$line" | grep -Eq '^LOCK*|^UNLOCK*|^DROP TABLE*|^--*|^/\*|^KEY|^UNIQUE KEY|^CONSTRAINT*|^PRIMARY*'; then
        skips=1 # just placeholder for syntax
    elif echo "$line" | grep -Eq '^CREATE TABLE'; then
        in_table_definition=1
        table_beginning=$line
    elif ! ( echo "$line" | grep -Eq '^\);' ) && [ $in_table_definition == 1 ]; then
        # we're inside a table definition and not at end , build up definition
        current_table_lines+=("$line")
    elif echo "$line" | grep -Eq '^\);' && [ $in_table_definition == 1 ]; then
        # end of table definition, output to file and reset

        echo $table_beginning >> $tmp_pg_file

        # for each current table line
        # if last has trailing comma, strip
        last_line=${current_table_lines[@]:(-1)}
        for table_line in "${current_table_lines[@]}"
        do
            if [ "$table_line" == "$last_line" ]; then
                result=$( echo $table_line | sed 's/,$//' )
                echo $result >> $tmp_pg_file
            else
                echo $table_line >> $tmp_pg_file
            fi
        done

        echo ");" >> $tmp_pg_file

        in_table_definition=0
        current_table_lines=()
        table_beginning=''
    else
        # default, just write the line to file
        echo "$line" >> $tmp_pg_file
    fi

done < $target_pg_file

echo "COMMIT;" >> $tmp_pg_file

echo "update pg_cast set castcontext='e' where casttarget = 'boolean'::regtype;" >> $tmp_pg_file

cp $tmp_pg_file $target_pg_file
rm $tmp_pg_file

gzip $target_pg_file

echo "pg file output to ./$target_pg_file.gz"

if [[ -n "${LEAVE_MYSQLDUMP// /}" ]]; then
    echo "mysqldump file left at ./$target_mysql_file for reference"
else
    rm $target_mysql_file
fi

if [[ -n "${PG_TARGET_PATH// /}" ]]; then
    echo "Will copy to $PG_TARGET_PATH"
    scp "./$target_pg_file.gz" "$PG_TARGET_PATH/"
fi
