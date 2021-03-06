#! /bin/bash 

if [ "$#" -lt 2 ]
then
	echo "Usage : <input_dir> <number_of_threads> [--flow] [--sobel]"
	exit 0
fi

if [ -d $1 ]
then
	input_dir="$1"
	echo "Input_dir : $input_dir"
else
	echo "Not a directory...."
	exit 0
fi

nb_threads=$2
echo "$nb_threads instances"

if [ -z $3 ]
then
	flow=0
else
	if [ $3 -eq 0 ]
	then
		flow=0
	else 
		flow=1
		echo "Using optical flow"
	fi
fi

if [ -z $4 ]
then
	sobel=0
	echo "Using CGTG algorithm"
else
	sobel=1
	echo "Using Sobel algorithm"
fi

tmp=`ls ${input_dir}/*.jpg | wc -l`
if [ $tmp -eq 0 ]
then
	echo "No images in that directory"
	exit 0
fi

nb_images=$tmp
echo "$nb_images to process"
tmp=`echo "scale=2; ${nb_images}/${nb_threads}" | bc`
echo $tmp
for i in `seq 1 ${nb_threads} `
do
	first=`echo "scale=0; ((${i}-1)*${tmp}+1)/1" | bc`
	last=`echo "scale=0; (${i}*${tmp})/1" | bc`
	cmd="nice -18 matlab -nojvm -r addpath('segmentation');seg('$input_dir',$flow,$sobel,$first,$last);exit;"
	echo $cmd
	$cmd & > /dev/null
done
	
