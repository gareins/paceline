#!/bin/sh

mkdir -p bin/data
echo "<> directory bin created"

ln -f package.json bin/package.json
echo "<> package.json linked"

(
    cd data;
    for f in *
    do
        ln -f $f "../bin/data/$f"
    done
)

echo "<> data files linked"

#ln -sf ../data/ data
#cd -
