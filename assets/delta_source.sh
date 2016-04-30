#!/bin/bash
TMP_DIR="/tmp"
BEFORE=$TMP_DIR/before.list
AFTER=$TMP_DIR/after.list
FILTER=install
SRC_DIR=~/src
SRC=/etc/apt/sources.list

#create after file
if [  -f "$BEFORE" ] && [ ! -f "$AFTER" ]; then
        echo "Getting list of installed packages for delta."
        dpkg --get-selections | grep -i "$FILTER"  > $AFTER
fi


#create before file
if [ ! -f "$BEFORE" ]; then
        echo "Getting list of installed packages."
        dpkg --get-selections | grep -i "$FILTER" > $BEFORE
		
	IFS='
'
	for src in `cat $SRC`
	do
        	echo source: $src
        	echo $src | sed -e "s|^deb|deb-src|g" >> $SRC
	done
	IFS=$' '
	cat $SRC
	apt-get update
	
	

fi


if [ -f "$BEFORE" ] && [ -f "$AFTER" ]; then
	echo "Getting Delta"
	apt-get update
	delta=$(diff $BEFORE $AFTER | grep "^>" |  awk '{print $2}')
	mkdir -p $SRC_DIR
	pushd $SRC_DIR
	IFS='
'
	for package in $delta
	do
		echo Downloading source for $package
		apt-get source $package	
	done
	IFS=$' '
	popd
	echo $delta
fi
