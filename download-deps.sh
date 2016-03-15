#/bin/bash

echo 
cat deps.links | while read dep 
do
	name=$(echo $dep | awk '{print $2}')

	if [ ! -f "assets/$name" ]; then

		link=$(echo $dep | awk '{print $1}')

	 	wget $link  -O  assets/$name
	fi
done
