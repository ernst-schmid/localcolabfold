#!/bin/bash
folder_name=$1;
dest_name=$2;
pattern=$3;

existing_files=$(~/bin/dbxcli ls "$dest_name")

for file in $(find $folder_name -name "$pattern")
do
  parent_folder=$(dirname "$file")
  immediate_parent=$(basename "$parent_folder")
  filename="$(basename $file)"
  destination="$dest_name/$filename"
  if echo "$existing_files" | grep -qFx "$destination"; then
    echo "skipping"
  else
     ~/bin/dbxcli put -v $file $destination
  fi
done