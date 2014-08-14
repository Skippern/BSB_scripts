#!/bin/bash

# set -ex to have a verbose run
set -ex

SHELL='/bin/bash'
BSBDIR='/fullpath/maps/BSB'

# needs +19G
export TILEDIR='/fullpath/maps/RNC'
# needs tiler-tools ≥ e6afc5b1415d (≥ Jul 24 2014)
export TILER='/fullpath/maps/tilers_tools/gdal_tiler.py'
export TMP=`mktemp -d ${TMPDIR:-/tmp}/tmp.XXXXXXXXXX`

trap 'rm -rf "$TMP"' 0
trap "exit 2" 1 2 3 15

if [ ! -d $TILEDIR ]; then
	mkdir -p $TILEDIR
fi

tiler() {
	scale=`grep -aF -m1 KNP $1 | \
		sed -n 's/.*SC=\([0-9]*\).*/\1/p'`

	# skip files with scale 0
	if [ `printf "%09d" $scale` != 000000000 ]; then
		name=`basename $1 .KAP`
		python $TILER -q -r -s -p xyz --skip-invalid $1 -t $TMP

		# decreases ~64.5% in size; further optimizations with optipng yelds no advantage
		find $TMP/$name -type f -name "*.png" -exec \
			pngquant --force --speed 1 --ext .png 16 {} \;

		cp -R $TMP/$name/* $TILEDIR
		rm -rf $TMP/$name
	fi
}
export -f tiler

if [ `which parallel > /dev/null; echo $?` = 0 ]; then
	find $BSBDIR -type f -name "*.KAP" | \
		parallel --env tiler -j +0 --progress tiler
else
	find $BSBDIR -type f -name "*.KAP" -exec $SHELL -c 'tiler "{}"' \;
fi

rm $TILEDIR/*.json
