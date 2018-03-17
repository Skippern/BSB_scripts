#!/bin/bash

#export MAGICK_HOME="$HOME/ImageMagick-6.8.8"
#export PATH="$MAGICK_HOME/bin:$PATH"
#export DYLD_LIBRARY_PATH="$MAGICK_HOME/lib/"

TMPDIR=$HOME/Documents/Maps/tmp2/
BSBDIR=$HOME/Documents/Maps/BSB/
TILEDIR=$HOME/Documents/Maps/RNC
#TILERS_TOOLS=$HOME/src/tilers_tools/tilers_tools/tiler.py
#TILERS_TOOLS="/opt/src/tilers_tools/tilers_tools/tiler.py"
TILERS_TOOLS=/opt/src/tilers-tools/tilers_tools/tiler.py
TILEZOOM=
#TILEZOOM='-z 1'
#TILEZOOM='-z 0,1,2,3,4,5'
#TILEZOOM='-z 6,7'

if [ "$1" != "" ]; then
#	echo ARG 1 is $1
	TILEZOOM="-z $1"
fi

mkdir $TMPDIR 2>/dev/null

echo "Changing to $TMPDIR"

cd "$TMPDIR"

#exit 0

if [ ! -e ../Process.txt ]; then touch ../Process.txt;fi

count=`cat ../Process.txt | wc -l | sed '/^ /s///' | sed '/^ /s///' | sed '/^ /s///' | sed '/^ /s///' | sed '/^ /s///' | sed '/^ /s///' | sed '/^ /s///'`
if [ "$count" = "0" ]; then
	echo "Empty process queue, removing file"
	rm ../Process.txt 2>/dev/null
fi

rm -rf *

if [ ! -e "../Process.txt" ]; then
	echo "Need to build process queue"

for i in `find $BSBDIR | grep KAP`; do echo $i > tmp
	i=`cat tmp | sed '/\/\//s//\//'`
	head -n 15 $i | grep NTM  | sed '/NTM\/NE=/s///' | sed '/,/s// /' > tmp2
	cat tmp2 | grep -o "^[0-9]* " > NTM
	cat tmp2 | grep -o "^[0-9]*.* " > NTM2
	cat tmp2 | grep -o "^[0-9]*-* " > NTM3
	cat NTM NTM2 NTM3 | uniq > NTM4
	NTM=`cat NTM4`
	cat tmp2 | sed "/$NTM/s///" > tmp3
	cat tmp3 | sed '/ND=/s///' | sed '/\//s// /' > tmp4
	month=`cat tmp4 | grep -o "^[0-9]* "`
	cat tmp4 | sed "/$month/s///" | sed '/\//s// /' > tmp5
	day=`cat tmp5 | grep -o "^[0-9]* "`
	cat tmp5 | sed "/$day/s///" > tmp6
	year=`cat tmp6 | grep -o "^[0-9]*"`
	isodate=`echo $year$month$day | sed '/ /s///'`
	echo "$i" >> "D$isodate.txt"
done

rm -rf NTM* tmp*

for i in `cat D*`; do echo $i > tmp
	i=`cat tmp | sed '/\/\//s//\//'`
	head -n 15 $i | grep KNP | sed '/KNP\/SC=/s///' | sed '/,/s// /' > tmp
	tempscale=`cat tmp | grep -o "^[0-9]*"`
	printf -v scale "%09d" $tempscale
	echo "$i" >> S$scale.txt
done

rm -rf D*
rm -rf tmp*
# Scale 000000000 = no-map inserts, removing these
mv S000000000.txt X000000000.txt 2>/dev/null

#cat `ls S*` > Process.txt
cat `ls -r S*` > Process.txt
rm -rf S*
rm -rf X*
mv Process.txt ..
rm -rf *
echo "Process queue ready"

fi

touch ../ToProcessManualy.txt
# Now we have a list sorted in rendering order

oldscale=42
echo "We have a process queue, start processing"
for i in `cat ../Process.txt`; do scale=`head -n 15 $i | grep KNP | sed '/KNP\/SC=/s///' | sed '/,/s// /' | grep -o "^[0-9]*"`
	echo "1:$scale"
	area=`echo $i | sed '/\/home\/skippern\/Documents\/Maps\/BSB\//s///' | tr '/' '\n' |grep -v KAP | grep -v kap`
#	echo "area=($area) from $i"
#	exit 0
#	if [ "$scale" != "$oldscale" ]; then
#		echo "Scale changed, we need to empty garbage"
		# Put in here code to upload map tiles to server, use scp, rcp
		# type commands for this operation, existing tiles on the server
		# should be overwritten with new ones
#		oldscale=$scale
#		data=`du -h $TILEDIR | tail -n 1| sed "/^ /s///" | grep -o "^[0-9A-Za-z][.0-9A-Za-z]*"`
#		echo "$data to send"
#	fi
	#sleep 0.1
	count=`find . -iname \*png | wc -l | sed '/   /s///' | sed '/  /s///' | sed '/ /s///' | sed '/ /s///'`
#	if [ "$count" == "0" ]; then
#		python $TILERS_TOOLS --tps -r -s $TILEZOOM -p xyz $i -t $TMPDIR
#	fi
#	count=`find . -iname \*png | wc -l | sed '/   /s///' | sed '/  /s///' | sed '/ /s///' | sed '/ /s///'`
#	if [ "$count" == "0" ]; then
#		python $TILERS_TOOLS -r -s $TILEZOOM -p xyz $i -t $TMPDIR
#	fi
	count=`find . -iname \*png | wc -l | sed '/   /s///' | sed '/  /s///' | sed '/ /s///' | sed '/ /s///'`
	if [ "$count" == "0" ]; then
		python $TILERS_TOOLS -s $TILEZOOM -p xyz $i -t $TMPDIR
	fi
	count=`find . -iname \*png | wc -l | sed '/   /s///' | sed '/  /s///' | sed '/ /s///' | sed '/ /s///'`
	if [ "$count" == "0" ]; then
		python $TILERS_TOOLS -tps -r -s -p xyz $i -t $TMPDIR
	fi
	#sleep 0.1
	count=`find . -iname \*png | wc -l | sed '/   /s///' | sed '/  /s///' | sed '/ /s///' | sed '/ /s///'`
	if [ "$count" == "0" ]; then
		# If we get here, the map needs to be processed manually
		echo "Adding to queue for manual processing: $i"
		echo "$i" >> ../ToProcessManualy.txt
		cat ../Process.txt | grep -v $i > tmp
		cat tmp > ../Process.txt
		continue
	else
	mv */* . 2>/dev/null
#	for j in `seq 0 21`; do mv -f */z$j $j 2>/dev/null; done
#	for j in `seq 0 21`; do mv -f */$j $j 2>/dev/null; done
	rm */*png 2>/dev/null
	count=`find . -iname \*png | wc -l | sed '/   /s///' | sed '/  /s///' | sed '/ /s///' | sed '/ /s///'`
	echo -n "$i ready to Process! $count files to process."
	#sleep 0.1
	new=0
	old=0
	dl=0
	for j in `seq 0 21`; do echo -n ""
		proc=0
		if [ -d "$j" ]; then
			newcount=`find $j -iname \*png | wc -l | sed '/   /s///' | sed '/  /s///' | sed '/ /s///' | sed '/ /s///'`
			echo ""
			printf -v x "%02d" $j
			printf -v mycount "%04d" $newcount
			echo -n " ($mycount) Processing $x "
			#sleep 0.2
			for k in $j/*; do for l in $k/*; do if [ -e "$l" ]; then
#				echo "l = $l"
				mv $l topW.png
				#sleep 0.1
				# Make white as alpha channel on top.png
#				convert topW.png -fuzz 10% -transparent black top.png
#				mv top.png topW.png 2>/dev/null
				convert topW.png -fuzz 10% -transparent white top.png
				mv topW.png top.png 2>/dev/null
				# Merge tiles
#				if [ -d $TILEDIR/$area/$k ]
#				then
#					sleep 0.1
#				else
					mkdir -p $TILEDIR/$area/$k
#				fi
				if [ -e "$TILEDIR/$area/$l" ]
				then
					ret="."
					cp $TILEDIR/$area/$l bottom.png
					old=`expr $old + 1`
				else
					# Download from tileserver
					ret=","
#					echo -n "Downloading $l from tile server"
					curl -# -G -f http://a.tile.openstreetmap.org/$l -o "bottom.png" 2>/dev/null
					dl=`expr $dl + 1`
				fi
				if [ ! -e bottom.png ]; then
					# File does not exist in repo or tile server, create from dummy
					ret="+"
					cp $TILEDIR/0.png bottom.png
					new=`expr $new + 1`
					dl=`expr $dl - 1`
				fi
				echo -n $ret
				#sleep 0.1

				composite -gravity center top.png bottom.png result.png
				# Convert pallet to INDEXED (to reduce size)
				convert result.png -colors 16 indexed.png

				#sleep 0.1

				proc=`expr $proc + 1`

#				echo "$TILEDIR/$area/$l"
				mv indexed.png $TILEDIR/$area/$l
				rm -rf *.png

				#sleep 0.1
			fi;done;done
			echo -n " ($proc)"
			#sleep 0.2
		fi
	done
	echo ""
	totproc=`expr $new + $old + $dl`
	echo Processed $new new, $old old, $dl downloaded: $totproc of $count
	if [ "$totproc" != "$count" ]; then echo $i >> ../NotFullyProcessed.txt; else echo $i >> ../FullyProcessed.txt; fi
	#sleep 0.2
	echo "$i Processed!"
	fi
	cat ../Process.txt | grep -v $i > tmp
	cat tmp > ../Process.txt
	rm -rf * 2>/dev/null
	echo ""
	echo ""
done

exit 0
