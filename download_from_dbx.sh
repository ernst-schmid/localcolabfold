#!/bin/bash

folder_name=$1;
dest_name=$2;
pattern=$3;

files=$(~/bin/dbxcli ls "$folder_name")
matching_files=()

for f in $files
do
    filename=$(basename $f)
    if [[ "$filename" == $pattern ]]; then
         matching_files+=("$f")        
    fi
done

cd $dest_name

for f in "${matching_files[@]}"; do
  ~/bin/dbxcli get $f
done
