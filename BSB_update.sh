#!/bin/sh

set -e

echo "Start downloading ODBL compatible RNC maps of the world"

TMPDIR=`mktemp -d`
BSBDIR='/Users/skippern/Documents/Maps/BSB/'

cd $TMPDIR


# Brazil (BR) is of compatible license (PD) http://www.mar.mil.br/dhn/chm/box-cartas-raster/raster_disponiveis.html

wget -q http://www.mar.mil.br/dhn/chm/box-cartas-raster/raster_disponiveis.html -O - \
	| sed -n 's/.*<a href="cartas\/\(.*.zip\)">.*/\1/p' > files.txt

for i in `cat files.txt`; do
	echo "Working with BR: $i"
	wget -q http://www.mar.mil.br/dhn/chm/box-cartas-raster/cartas/$i
	if [ -s $i ]; then
		unzip -qjoC $i \*.BSB \*.KAP -d $BSBDIR/BR
		rm $i
	fi
done
rm files.txt

# Argentina (AR) is of compatible license (PD) http://www.hidro.gob.ar/cartas/cartasnauticas.asp

for i in `wget -q http://www.hidro.gob.ar/cartas/cartasnauticas.asp -O - \
	| sed -n 's/.*<a href="\(CNRaster\.asp?r=.*\)">.*/\1/p'`; do

	wget -q http://www.hidro.gob.ar/cartas/$i -O - \
		| sed -n 's/.*<a href="BSB\/\(.*.zip\)">.*/\1/p' >> files.txt
done

for i in `cat files.txt`; do
	echo "Working with AR: $i"
	wget -q http://www.hidro.gob.ar/cartas/BSB/$i
	if [ -s $i ]; then
		# the files are actually RAR
		unrar e -ep -o+ -inul $i \*.BSB \*.KAP $BSBDIR/AR
		rm $i
	fi
done
rm files.txt

# USA (US) is of compatible license (PD) http://www.charts.noaa.gov/RNCs

# ~2.9G
wget -q http://www.charts.noaa.gov/RNCs/All_RNCs.zip
if [ -s $i All_RNCs.zip]; then
	echo "Working with US: All_RNCs.zip"
	unzip -qjoC $i \*.BSB \*.KAP -d $BSBDIR/US
	rm All_RNCs.zip
fi

# New Zealand (NZ) is of compatible license (CC-BY) http://www.linz.govt.nz/hydro/charts/digital-charts/nzmariner

for i in BSB_BASE.zip bsb_update.zip; do
	echo "Working with NZ: $i"
	wget -q http://www.linz.govt.nz/sites/default/files/docs/hydro/charts/digital/nzmariner/$i
	if [ -s $i ]; then
		unzip -qjoC $i \*.BSB \*.KAP -d $BSBDIR/NZ
		rm $i
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

rm -rf $TMPDIR

echo "Done!"
