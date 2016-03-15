#/bin/bash

IFS=$'\n'
for dep in ` cat deps.links `
do
	
	link=$(echo $dep | awk '{print $1}')

	name=$(echo $dep | awk '{print $2}')

 	wget $link  -O  assets/$name

done
