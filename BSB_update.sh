#!/bin/bash

echo "Start downloading ODBL compatible RNC maps of the world"

HOMEDIR='/Users/skippern/Documents/Maps/tmp/'
BSBDIR='/Users/skippern/Documents/Maps/BSB/'

mkdir $HOMEDIR 2>/dev/null

cd "$HOMEDIR"

#cp ../*.txt . 2>/dev/null


echo "Brazil (BR) is of compatible license (PD) http://www.mar.mil.br/dhn/chm/cartas/cartas.html"

if  [ ! -e ../BR.txt ]; then
	touch ../BR.txt
	curl -# -G -f http://www.mar.mil.br/dhn/chm/cartas/download/cartasbsb/cartas_eletronicas_Internet.htm -o "BR_chart_list.html" 2>/dev/null
	cat BR_chart_list.html  | grep zip | tr '"' '\n' | grep zip  >> ../BR.txt
	curl -# -G -f http://www.mar.mil.br/dhn/chm/cartas/download/cartasbsb/ -o "BR_chart_list.html" 2>/dev/null
	cat BR_chart_list.html  | grep zip | tr '"' '\n' | grep zip >> ../BR.txt
	curl -# -G -f http://www.mar.mil.br/dhn/chm/cartas/download/cartasbsb/cartas_rios.htm -o "BR_chart_list.html" 2>/dev/null
	cat BR_chart_list.html  | grep zip | tr '"' '\n' | grep zip >> ../BR.txt
	curl -# -G -f http://www.mar.mil.br/dhn/chm/cartas/car_portos.html -o "BR_chart_list.html" 2>/dev/null
	cat BR_chart_list.html  | grep zip | tr '"' '\n' | grep zip >> ../BR.txt
	cat BR_chart_list.html  | grep zip | tr '"' '\n' | sed -e '/.html/s//.zip/' | grep zip >> ../BR.txt
	curl -# -G -f http://www.mar.mil.br/dhn/chm/box-cartas-raster/raster_disponiveis.html -o "BR_chart_list.html" 2>/dev/null
	cat BR_chart_list.html  | grep zip | tr '"' '\n' | grep zip >> ../BR.txt
	cat BR_chart_list.html  | grep zip | tr '"' '\n' | sed -e '/.html/s//.zip/' | grep zip >> ../BR.txt
	cat ../BR.txt | tr 'cartasbsb/' '\n' | tr 'cartas/' '\n' | tr ' ' '\n' | grep -v geotif | grep zip | uniq > tmp
	cat tmp | sort | uniq > ../BR.txt
fi
for i in `cat ../BR.txt`; do echo "Working with BR $i"
	curl -# -G -f -C - http://www.mar.mil.br/dhn/chm/cartas/download/cartasbsb/$i -o "BR$i"
	if [ -e BR$i ]; then
		unzip -Co BR$i \*.BSB -d .
		unzip -Co BR$i \*.KAP -d .	
		bsb=`find $HOMEDIR -iname \*BSB`
		echo Chart name: `cat $bsb | grep "CHT/NA" | tr ',' '\n' | sed '/CHT\/NA=/s///' | head -n 1`
		echo "Have $i"
		count=`find $HOMEDIR | grep KAP | wc -l | sed '/^ /s///' | sed '/^ /s///' | sed '/^ /s///' | sed '/^ /s///' | sed '/^ /s///' | sed '/^ /s///' | sed '/^ /s///'`
		if [ "$count" != "0" ]; then
			echo "$count KAP files exist, removing line"
			cat ../BR.txt | grep -v -o ^$i > tmp
			cat tmp > ../BR.txt
			rm tmp
			rm BR$i 2>/dev/null
		fi
	fi
	for f in `find . -type d`; do cd "$HOMEDIR/$f"
		mv *BSB $BSBDIR/BR 2>/dev/null
		mv *KAP $BSBDIR/BR 2>/dev/null
		cd "$HOMEDIR" 
	done
	for j in *; do
	if [ -d $j ]; then
		rm -rf $j
	fi
	done
done

rm BR_chart_list.html 2>/dev/null

echo "Argentina (AR) is of compatible license (PD) http://www.hidro.gob.ar/Nautica/Raster.asp"
#cp ../AR*html . 2>/dev/null
if [ ! -e ../AR.txt ]; then
	curl -# -G -f -C - http://www.hidro.gob.ar/Nautica/Raster.asp -o "AR_chart_list_page0.html" 2>/dev/null
	for i in `seq 1 10`; do curl -# -G -f -C - http://www.hidro.gob.ar/Nautica/CNRaster.asp?r=$i -o "AR_chart_list_page$i.html" 2>/dev/null ; done
#	cp AR*html .. 2>/dev/null
	cat AR*html | tr '"' '\n' | grep BSB/ | sed '/BSB\//s///' | sort | uniq > ../AR.txt
	rm -rf AR*html 2>/dev/null
fi
for i in `cat ../AR.txt` ; do echo "Working with AR $i"
	curl -# -G -f -C - http://www.hidro.gob.ar/Nautica/BSB/$i -o "AR$i"
	if [ -e AR$i ]; then
		unzip -Co AR$i \*.BSB -d . 
		unzip -Co AR$i \*.KAP -d . 
#		sleep 1.5
		bsb=`find $HOMEDIR -iname \*BSB`
		echo Chart name: `cat $bsb | grep "CHT/NA" | tr ',' '\n' | sed '/CHT\/NA=/s///' | head -n 1`
		echo "Have $i"
		count=`find $HOMEDIR | grep KAP | wc -l | sed '/^ /s///' | sed '/^ /s///' | sed '/^ /s///' | sed '/^ /s///' | sed '/^ /s///' | sed '/^ /s///' | sed '/^ /s///'`
		if [ "$count" != "0" ]; then
			echo "$count KAP files exist, removing line"
			cat ../AR.txt | grep -v -o ^$i > tmp
			cat tmp > ../AR.txt
			rm tmp
			rm AR$i 2>/dev/null
		fi
	fi
	for f in `find . -type d`; do cd "$HOMEDIR/$f"
		mv *BSB $BSBDIR/AR 2>/dev/null
		mv *KAP $BSBDIR/AR 2>/dev/null
		cd "$HOMEDIR" 
	done
done

echo "USA (US) is of compatible license (PD) http://www.charts.noaa.gov/RNCs"

if  [ ! -e ../US.txt ]; then
	curl -# -G -f http://www.charts.noaa.gov/RNCs/ -o "US_Chart_List.html" 2>/dev/null
	touch US1.txt US2.txt US3.txt
	cat US_Chart_List.html | sed '/<a href=\"/s///' | sed '/\">/s//   /' | sed '/<\/a>/s///' | grep zip | grep -o "^[a-zA-Z0-9]*_[a-zA-Z0-9]*.zip" | sort > US1.txt
	cat US_Chart_List.html | sed '/<a href=\"/s///' | sed '/\">/s//   /' | sed '/<\/a>/s///' | grep zip | grep -o "^[a-zA-Z0-9]*.zip" | sort > US2.txt
	cat US_Chart_List.html | sed '/<a href=\"/s///' | sed '/\">/s//   /' | sed '/<\/a>/s///' | grep zip | grep -o "^[0-9]*.zip" | sort > US3.txt
	cat US1.txt US2.txt US3.txt | sort -g | uniq > ../US.txt
	rm US1.txt US2.txt US3.txt 2>/dev/null
	cat ../US.txt | grep -v Patch > tmp
	cat tmp > ../US.txt
	cat ../US.txt | grep -v Base > tmp
	cat tmp > ../US.txt
	cat ../US.txt | grep -v All > tmp
	cat tmp > ../US.txt
	rm tmp 2>/dev/null
	rm *html 2>/dev/null
fi

for i in `cat ../US.txt`; do echo "Working with US $i"
	curl -# -G -f -C - http://www.charts.noaa.gov/RNCs/$i -o "US$i"
	if [ -e US$i ]; then
		unzip -Co US$i \*.BSB -d .
		unzip -Co US$i \*.KAP -d .
		bsb=`find $HOMEDIR -iname \*BSB`
		echo Chart name: `cat $bsb | grep "CHT/NA" | tr ',' '\n' | sed '/CHT\/NA=/s///' | head -n 1`
		echo "Have $i"
		count=`find $HOMEDIR | grep KAP | wc -l | sed '/^ /s///' | sed '/^ /s///' | sed '/^ /s///' | sed '/^ /s///' | sed '/^ /s///' | sed '/^ /s///' | sed '/^ /s///'`
		if [ "$count" != "0" ]; then
			echo "$count KAP files exist, removing line"
			cat ../US.txt | grep -v -o ^$i > tmp
			cat tmp > ../US.txt
			rm tmp 2>/dev/null
			rm US$i 2>/dev/null
			rm -rf BSB_ROOT 2>/dev/null
		fi
	fi
	for f in `find . -type d`; do cd "$HOMEDIR/$f"
		mv *BSB $BSBDIR/US 2>/dev/null
		mv *KAP $BSBDIR/US 2>/dev/null
		cd "$HOMEDIR" 
	done
done

rmdir BSB_ROOT 2>/dev/null
rm US_Chart_List.html 2>/dev/null

echo "New Zealand (NZ) is of compatible license (CC-BY) http://www.linz.govt.nz/hydro/charts/digital-charts/nzmariner"

if  [ ! -e ../NZ.txt ]; then
	curl -# -G -f http://www.linz.govt.nz/hydro/charts/digital-charts/nzmariner -o "NZ_charts.html" 2>/dev/null
#	cat NZ_charts.html  | grep zip | tr '"' '\n' | tr '\"' '\n' | grep zip > ../NZ.txt
	echo "BSB_BASE.zip" > ../NZ.txt
	echo "BSB_UPDATE.zip" >> ../NZ.txt
	rm NZ_charts.html 2>/dev/null
fi
for i in `cat ../NZ.txt`; do echo "Working with NZ $i"
	curl -# -G -f -C - http://www.linz.govt.nz/sites/default/files/docs/hydro/charts/digital/nzmariner/$i -o "NZ$i"
	if [ -e NZ$i ]; then
		unzip -Co NZ$i \*.BSB -d .
		unzip -Co NZ$i \*.KAP -d .
		bsb=`find $HOMEDIR -iname \*BSB`
		echo Chart name: `cat $bsb | grep "CHT/NA" | tr ',' '\n' | sed '/CHT\/NA=/s///' | head -n 1`
		echo "Have $i"
		count=`find $HOMEDIR | grep KAP | wc -l | sed '/^ /s///' | sed '/^ /s///' | sed '/^ /s///' | sed '/^ /s///' | sed '/^ /s///' | sed '/^ /s///' | sed '/^ /s///'`
		if [ "$count" != "0" ]; then
			echo "$count KAP files exist, removing line"
			cat ../NZ.txt | grep -v -o ^$i > tmp
			cat tmp > ../NZ.txt
			rm tmp
			rm NZ$i 2>/dev/null
		fi
	fi
	for f in `find . -type d`; do cd "$HOMEDIR/$f"
		mv *BSB $BSBDIR/NZ 2>/dev/null
		mv *KAP $BSBDIR/NZ 2>/dev/null
		cd "$HOMEDIR"
	done
done

echo "Chile (CL) http://www.shoa.cl/pagnueva/comelec.html unknown package format"
echo "Canada (CA) http://www.charts.gc.ca/charts-cartes/digital-electronique/index-eng.asp are commercial"
echo "Colombia (CO) http://www.cioh.org.co/derrotero/index.php?option=com_wrapper&view=wrapper&Itemid=62 are commercial"
echo "Equador (EC) http://rossi.christian.free.fr/nautical_free.html#EC are commercial"
echo "Mexico (MX) http://digaohm.semar.gob.mx/derrotero/derroteroDigital.html are commercial"
echo "Panama (PA) http://www.pancanal.com/eng/ are commercial"
echo "Peru (PE) https://www.dhn.mil.pe/app/menu/servicios/cartografia/WebECDIS/ are commercial"
echo "Uruguay (UY) http://www.sohma.armada.mil.uy/cartas-nauticas.htm are commercial"
echo "Venezuela (VE) http://www.dhn.mil.ve are commercial"


#cp *.txt .. 2>/dev/null

rm -rf *

echo "See http://rossi.christian.free.fr/nautical_free.html for more"
echo "Done!"
