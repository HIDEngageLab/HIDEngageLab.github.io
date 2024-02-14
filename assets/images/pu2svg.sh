#!/bin/bash

# https://plantuml.com/de/
#

scour_params="-q --strip-xml-prolog --enable-viewboxing --enable-id-stripping --enable-comment-stripping --shorten-ids"

#pu_param="-v -tsvg"
pu_param="-quiet -tsvg"

for i in `ls *.pu`
do 
    pu_file_name=$i
    svg_file_name=${i%.pu}.svg
    echo "convert $pu_file_name to $svg_file_name"
    plantuml $pu_param $pu_file_name
    cp $svg_file_name $svg_file_name.backup
    #scour $scour_params -i $svg_file_name.backup -o $svg_file_name
    cp $svg_file_name.backup $svg_file_name
    rm $svg_file_name.backup
done
