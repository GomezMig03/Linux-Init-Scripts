#!/bin/bash
set -euo pipefail
shopt -s nullglob

dir="$(pwd)"

if [ -d "$dir/temp1" ]; then
	rm -rf "$dir/temp1"
	mkdir -p "$dir/temp1"
fi

unzip -q "$1" -d ./temp1/
rm "$1"

item=$(ls ./temp1/ | head -n1)
cd "$dir"/temp1/

shopt -s extglob

case "$item" in
	*.zip)
		unzip -q "$item" -d "./"
		rm "$item"
	;;
	*.rar)
		unrar x -inul "$item" "./"
		rm "$item"
	;;
	*.7z)
		7z x -y "$item"
		rm "$item"
	;;
	*.ass)
	;;
	*)
		echo "no se encontró comprimido dentro del comprimido principal:"
		echo "$item"
	;;
esac

names=( ./*esES.ass )
name="${names[0]:-}"
if [ -z "$name" ]; then
	names=( ./*Español\ \(España\).ass* )
	name="${names[0]:-}"
fi
if [ -z "$name" ]; then
	names=( ./*spa.ass* )
	name="${names[0]:-}"
fi
if [ -z "$name" ]; then
	names=( ./*es.ass* )
	name="${names[0]:-}"
fi
if [ -z "$name" ]; then
	names=( ./*.ass* )
	name="${names[0]:-}"
fi

if [ -z "$name" ]; then
	echo "Error encontrando archivo .ass"
fi

file="${name#./}"
nombre="${name%.*}"

ffmpeg -i "${file}" -c:s srt "$dir/$nombre.srt"

rm -rf "$dir/temp1"
