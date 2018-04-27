#!/bin/bash

TMPDIR=$HOME/Documents/Maps/tmp2/
BSBDIR=$HOME/Documents/Maps/BSB/
OZIDIR=$HOME/Documents/Maps/Ozi/
TILEDIR=$HOME/Documents/Maps/RNC

TILERS_TOOLS=/opt/src/tilers-tools/tilers_tools/tiler.py
TILEZOOM=
#TILEZOOM='-z 1'
#TILEZOOM='-z 0,1,2,3,4,5'
#TILEZOOM='-z 6,7'

if [ "$1" != "" ]; then
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

make_queue() {
#	find $OZIDIR/ | grep -e "map" -e "MAP" | grep -v " " > Process.txt

	for i in `find $OZIDIR | grep -e "map" -e "MAP" | grep -v " "`; do echo $i >tmp
#		i=`cat tmp | sed '/\/\//s//\//'`
		# 1 meter [m] = 3779.52755905511 pixel (X)
		pixelmeter=3779.52755905511
		tempscale=`cat $i | grep MM1B | sed '/MM1B,/s///' | grep '.'`
		tempscale=$(echo $tempscale $pixelmeter | awk '{printf "%4.0f\n",$1*$2}')
		printf -v scale "%09d" $tempscale
		echo "$i" >>S$scale.txt
	done

	for i in `find $BSBDIR | grep -e "kap" -e "KAP" | grep -v " "`; do echo $i > tmp
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

	cat `ls -r S*` > Process.txt
	rm -rf S*
	rm -rf X*
	mv Process.txt ..
	rm -rf *
	echo "Process queue ready"

	touch ../ToProcessManualy.txt
}

png_proc() {
	area=$1
	mv */* . 2>/dev/null
	rm */*png 2>/dev/null
	count=`find . -iname \*png | wc -l | sed '/   /s///' | sed '/  /s///' | sed '/ /s///' | sed '/ /s///'`
	echo -n "$i ready to Process! $count files to process."
	new=0
	old=0
	dl=0
	Anew=0
	Aold=0
	Adl=0
	for j in `seq 0 21`; do echo -n ""
		proc=0
		if [ -d "$j" ]; then
			newcount=`find $j -iname \*png | wc -l | sed '/   /s///' | sed '/  /s///' | sed '/ /s///' | sed '/ /s///'`
			echo ""
			printf -v x "%02d" $j
			printf -v mycount "%04d" $newcount
			echo -n " ($mycount) Processing $x "
			for k in $j/*; do for l in $k/*; do if [ -e "$l" ]; then
				mv $l topW.png
				convert topW.png -fuzz 10% -transparent white top.png
				cp top.png all.png
				mkdir -p $TILEDIR/$area/$k
				mkdir -p $TILEDIR/all/$k
				if [ -e "$TILEDIR/$area/$l" ]
				then
					ret="."
					cp $TILEDIR/$area/$l bottom.png
					old=`expr $old + 1`
				else
					# Download from tileserver
					ret=","
#					echo -n "Downloading $l from tile server"
#					curl -# -G -f http://a.tile.openstreetmap.org/$l -o "bottom.png" 2>/dev/null
#					dl=`expr $dl + 1`
				fi
				if [ ! -e bottom.png ]; then
					# File does not exist in repo or tile server, create from dummy
					ret="+"
					cp $TILEDIR/0.png bottom.png
					new=`expr $new + 1`
					if [ $dl -gt 0 ]; then
						dl=`expr $dl - 1`
					fi
				fi
				echo -n $ret

				composite -gravity center top.png bottom.png result.png
				# Convert pallet to INDEXED (to reduce size)
				convert result.png -colors 16 indexed.png

				proc=`expr $proc + 1`

				mv indexed.png $TILEDIR/$area/$l

				if [ -e "$TILEDIR/all/$l" ]
				then
					ret="."
					cp $TILEDIR/$area/$l bottom.png
					Aold=`expr $Aold + 1`
				else
					# Download from tileserver
					ret=","
					curl -# -G -f http://a.tile.openstreetmap.org/$l -o "bottom.png" 2>/dev/null
					Adl=`expr $Adl + 1`
				fi
				if [ ! -e bottom.png ]; then
					# File does not exist in repo or tile server, create from dummy
					ret="+"
					cp $TILEDIR/0.png bottom.png
					Anew=`expr $Anew + 1`
#					if [ $dl -gt 0 ]; then
#						Adl=`expr $dl - 1`
#					fi
				fi
				echo -n $ret

				composite -gravity center top.png bottom.png result.png
				# Convert pallet to INDEXED (to reduce size)
				convert result.png -colors 16 indexed.png

#				Aproc=`expr $Aproc + 1`

				mv indexed.png $TILEDIR/all/$l

				rm -rf *.png
			fi;done;done
			echo -n " ($proc)"
		fi
	done
	echo ""
	totproc=`expr $new + $old + $dl`
	Atotproc=`expr $Anew + $Aold + $Adl`
	echo Processed $new new, $old old, $dl downloaded: $totproc of $count
	echo Processed $Anew new, $Aold old, $Adl downloaded: $Atotproc of $count
}

ozi_proc() {
	echo "We have a process queue, start processing"
	for i in `cat ../Process.txt | grep map`; do area=`echo $i | sed '/\/home\/skippern\/Documents\/Maps\/Ozi\//s///' | tr '/' '\n' |grep -v MAP | grep -v map`
		count=`find . -iname \*png | wc -l | sed '/   /s///' | sed '/  /s///' | sed '/ /s///' | sed '/ /s///'`
		if [ "$count" == "0" ]; then
			python $TILERS_TOOLS -s $TILEZOOM -p xyz $i -t $TMPDIR
		fi
		count=`find . -iname \*png | wc -l | sed '/   /s///' | sed '/  /s///' | sed '/ /s///' | sed '/ /s///'`
		if [ "$count" == "0" ]; then
			python $TILERS_TOOLS -tps -r -s -p xyz $i -t $TMPDIR
		fi
		count=`find . -iname \*png | wc -l | sed '/   /s///' | sed '/  /s///' | sed '/ /s///' | sed '/ /s///'`
		if [ "$count" == "0" ]; then
			# If we get here, the map needs to be processed manually
			echo "Adding to queue for manual processing: $i"
			echo "$i" >> ../ToProcessManualy.txt
			cat ../Process.txt | grep -v $i > tmp
			cat tmp > ../Process.txt
			continue
		else
		png_proc $area
		echo "$i Processed!"
		fi
		cat ../Process.txt | grep -v $i > tmp
		cat tmp > ../Process.txt
		rm -rf * 2>/dev/null
		echo ""
		echo ""
	done
}


bsb_proc() {
	oldscale=42
	echo "We have a process queue, start processing"
	for i in `cat ../Process.txt | grep -e kap -e KAP`; do scale=`head -n 15 $i | grep KNP | sed '/KNP\/SC=/s///' | sed '/,/s// /' | grep -o "^[0-9]*"`
		echo "1:$scale"
		area=`echo $i | sed '/\/home\/skippern\/Documents\/Maps\/BSB\//s///' | tr '/' '\n' |grep -v KAP | grep -v kap`
		count=`find . -iname \*png | wc -l | sed '/   /s///' | sed '/  /s///' | sed '/ /s///' | sed '/ /s///'`
		if [ "$count" == "0" ]; then
			python $TILERS_TOOLS -s $TILEZOOM -p xyz $i -t $TMPDIR
		fi
		count=`find . -iname \*png | wc -l | sed '/   /s///' | sed '/  /s///' | sed '/ /s///' | sed '/ /s///'`
		if [ "$count" == "0" ]; then
			python $TILERS_TOOLS -tps -r -s -p xyz $i -t $TMPDIR
		fi
		count=`find . -iname \*png | wc -l | sed '/   /s///' | sed '/  /s///' | sed '/ /s///' | sed '/ /s///'`
		if [ "$count" == "0" ]; then
			echo "Adding to queue for manual processing: $i"
			echo "$i" >> ../ToProcessManualy.txt
			cat ../Process.txt | grep -v $i > tmp
			cat tmp > ../Process.txt
			continue
		else
		png_proc $area
		echo "$i Processed!"
		fi
		cat ../Process.txt | grep -v $i > tmp
		cat tmp > ../Process.txt
		rm -rf * 2>/dev/null
		echo ""
		echo ""
	done
}

if [ ! -e "../Process.txt" ]; then
	echo "Need to build process queue"
	make_queue
fi

if [ -e "../Process.txt" ]; then
	echo "Need to build process queue"
	ozi_proc
	bsb_proc
fi


exit 0
