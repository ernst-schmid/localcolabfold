#!/bin/bash

filenames_to_keep=''
while getopts "f:" opt; do
  case $opt in
    f)
      filenames_to_keep=$OPTARG
      echo "Argument supplied: $filenames_to_keep";;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
  esac
done

shift $((OPTIND -1))

dbx_folder_name=$1
dest_name=$2
pattern=$3

dbx_files=$(dbxcli ls "$dbx_folder_name" | tr -s [:space:] "\n")
matching_dbx_files=()

if [ -n "$filenames_to_keep" ]; then

    while read -r line; do
        line="${line%"${line##*[![:space:]]}"}"
        match=$(echo "$dbx_files" | grep "$line")
        if [ -n "$match" ]; then
            readarray files <<< "$match"
            matching_dbx_files+=("${files[@]}")
        fi
    done < $filenames_to_keep
else
    readarray files <<< "$dbx_files"
    matching_dbx_files=("${files[@]}")
fi

cd $dest_name
for f in "${matching_dbx_files[@]}"; do

    filename=$(basename $f)
    if [[ "$filename" == $pattern ]]; then
        ~/bin/dbxcli get $f
    fi
done
