#!/bin/bash

out_fold="build/data/"
mkdir -p $out_fold

echo ""
echo "==> Download crypto files..."
echo ""

src_crypto="http://crypto-js.googlecode.com/svn/tags/3.1.2/build/rollups/"
files=("sha1.js" "sha3.js" "sha256.js" "sha512.js" "ripemd160.js" "md5.js")

mkdir "$out_fold""crypto"
for f in ${files[@]}
do
  curl "$src_crypto$f" -o "$out_fold""crypto/$f"
done

echo ""
echo "==> Download crypto encoding file..."
echo ""

src="http://crypto-js.googlecode.com/svn/tags/3.1.2/build/components/enc-base64-min.js"
curl $src -o "$out_fold""crypto/enc-base64-min.js"


echo ""
echo "==> Downloading jquery files..."
echo ""

src="https://ajax.googleapis.com/ajax/libs/jquery/2.1.4/jquery.min.js"
curl $src -o "$out_fold""jquery.min.js"

echo ""
echo "==> Download perfect scrollbar files..."
echo ""

src="http://github.com/noraesae/perfect-scrollbar/releases/download/0.6.3/perfect-scrollbar.zip"
tmpf="/tmp/scrollbar.zip"

mkdir "$out_fold""scroll"
curl $src -L -o $tmpf

unzip -p $tmpf css/perfect-scrollbar.min.css > "$out_fold""scroll/perfect-scrollbar.min.css"
unzip -p $tmpf js/min/perfect-scrollbar.jquery.min.js > "$out_fold""scroll/perfect-scrollbar.jquery.min.js"


echo ""
echo "==> Downloading tooltipsy files..."
echo ""

src="https://raw.githubusercontent.com/briancray/tooltipsy/master/tooltipsy.min.js"
curl $src -o "$out_fold""tooltipsy.min.js"


echo ""
echo "==> DONE DOWNLOADING"
echo ""
