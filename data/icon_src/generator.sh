#!/bin/bash
cd data/icon_src || cd icon_src;
mkdir -p ../icons

for f in $(ls | grep png)
do
  n=$(echo $f | cut -d'.' -f1)
  convert $f -resize 64x64 "../icons/$n""_64.png"
  convert $f -resize 32x32 "../icons/$n""_32.png"
  convert $f -resize 16x16 "../icons/$n""_16.png"
done
