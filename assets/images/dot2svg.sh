#!/bin/bash

# Visual online editor for dot files:
# http://magjac.com/graphviz-visual-editor/
#
# galery:
# https://graphviz.org/gallery/
#
# dot spezification:
# https://graphviz.org/docs/attrs/size/

scour_params="-q --strip-xml-prolog --enable-viewboxing --enable-id-stripping --enable-comment-stripping --shorten-ids"

for i in `ls *.dot`
do 
    dot_file_name=$i
    svg_file_name=${i%.dot}.svg
    echo "convert $dot_file_name to $svg_file_name"
    dot -Tsvg $dot_file_name -o $svg_file_name.backup
    #scour $scour_params -i $svg_file_name.backup -o $svg_file_name
    cp $svg_file_name.backup $svg_file_name
    rm $svg_file_name.backup
done
