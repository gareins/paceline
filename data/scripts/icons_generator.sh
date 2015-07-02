#!/bin/bash
src="data/icon_src/"
dest="build/data/icons/"
mkdir -p $dest

for f in $(ls $src | grep png)
do
  n=$(echo $f | cut -d'.' -f1)
  convert $src$f -resize 64x64 "$dest$n""_64.png"
  convert $src$f -resize 32x32 "$dest$n""_32.png"
  convert $src$f -resize 16x16 "$dest$n""_16.png"
done
