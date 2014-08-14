#!/bin/sh

set -e

echo "Downloading ODBL compatible RNC maps of the world"

TMP=`mktemp -d ${TMPDIR:-/tmp}/tmp.XXXXXXXXXX`
# BSBDIR needs +6.7G
BSBDIR='~/maps/BSB'
# CACHEDIR needs +3.4G
CACHEDIR='~/maps/cache'

# TODO: needs to clean old and unused files under CACHEDIR

mkdir -p $BSBDIR/BR \
	$BSBDIR/AR \
	$BSBDIR/US \
	$BSBDIR/NZ \
	$CACHEDIR

trap 'rm -rf "$TMP"' 0
trap "exit 2" 1 2 3 15

# Brazil (BR) is of compatible license (PD) http://www.mar.mil.br/dhn/chm/box-cartas-raster/raster_disponiveis.html

wget -q http://www.mar.mil.br/dhn/chm/box-cartas-raster/raster_disponiveis.html -O - \
	| sed -n 's/.*<a href="cartas\/\(.*.zip\)">.*/\1/p' > $TMP/files.txt

for i in `cat $TMP/files.txt`; do
	echo "Working with BR: $i"
	wget -Nq http://www.mar.mil.br/dhn/chm/box-cartas-raster/cartas/$i -P $CACHEDIR || true
	if [ -s $CACHEDIR/$i ]; then
		unzip -qjoC $CACHEDIR/$i \*.BSB \*.KAP -d $BSBDIR/BR
	fi
done
rm $TMP/files.txt

# Argentina (AR) is of compatible license (PD) http://www.hidro.gob.ar/cartas/cartasnauticas.asp

for i in `wget -q http://www.hidro.gob.ar/cartas/cartasnauticas.asp -O - \
	| sed -n 's/.*<a href="\(CNRaster\.asp?r=.*\)">.*/\1/p'`; do

	wget -q http://www.hidro.gob.ar/cartas/$i -O - \
		| sed -n 's/.*<a href="BSB\/\(.*.zip\)">.*/\1/p' >> $TMP/files.txt
done

for i in `cat $TMP/files.txt`; do
	echo "Working with AR: $i"
	wget -Nq http://www.hidro.gob.ar/cartas/BSB/$i -P $CACHEDIR
	if [ -s $CACHEDIR/$i ]; then
		# all files have a ZIP extension, but some are actually RAR
		if file $CACHEDIR/$i | grep -q "RAR archive"; then
			unrar x -ep -o+ -inul $CACHEDIR/$i \*.BSB \*.KAP $BSBDIR/AR
		elif file $CACHEDIR/$i | grep -q "Zip archive"; then
			unzip -qjoC $CACHEDIR/$i \*.BSB \*.KAP -d $BSBDIR/AR
		else
			echo "Unknown file type: $CACHEDIR/$i" >&2
		fi
	fi
done
rm $TMP/files.txt

# USA (US) is of compatible license (PD) http://www.charts.noaa.gov/RNCs

# ~2.9G
wget -Nq http://www.charts.noaa.gov/RNCs/All_RNCs.zip -P $CACHEDIR
if [ -s $CACHEDIR/All_RNCs.zip ]; then
	echo "Working with US: All_RNCs.zip"
	unzip -qjoC $CACHEDIR/All_RNCs.zip \*.BSB \*.KAP -d $BSBDIR/US
fi

# New Zealand (NZ) is of compatible license (CC-BY) http://www.linz.govt.nz/hydro/charts/digital-charts/nzmariner

for i in BSB_BASE.zip bsb_update.zip; do
	echo "Working with NZ: $i"
	wget -Nq http://www.linz.govt.nz/sites/default/files/docs/hydro/charts/digital/nzmariner/$i -P $CACHEDIR
	if [ -s $CACHEDIR/$i ]; then
		unzip -qjoC $CACHEDIR/$i \*.BSB \*.KAP -d $BSBDIR/NZ
	fi
done

# Canada (CA) http://www.charts.gc.ca/charts-cartes/digital-electronique/index-eng.asp are commercial
# Chile (CL) http://www.shoa.cl/pagnueva/comelec.html unknown package format
# Colombia (CO) http://www.cioh.org.co/derrotero/index.php?option=com_wrapper&view=wrapper&Itemid=62 are commercial
# Equador (EC) http://rossi.christian.free.fr/nautical_free.html#EC are commercial
# Mexico (MX) http://digaohm.semar.gob.mx/derrotero/derroteroDigital.html are commercial
# Panama (PA) http://www.pancanal.com/eng/ are commercial
# Peru (PE) https://www.dhn.mil.pe/app/menu/servicios/cartografia/WebECDIS/ are commercial
# Uruguay (UY) http://www.sohma.armada.mil.uy/cartas-nauticas.htm are commercial
# Venezuela (VE) http://www.dhn.mil.ve are commercial

# See http://rossi.christian.free.fr/nautical_free.html for more

echo "Done!"
