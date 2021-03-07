#!/bin/bash

# add x for debugging
set -eu

# Setup the docker images
PU_DOCKER_IMG=miy4/plantuml

#detect platform that we're running on...
unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=Mac;;
    CYGWIN*)    machine=Cygwin;;
    MINGW*)     machine=MinGw;;
    *)          machine="UNKNOWN:${unameOut}"
esac

# this is the core routine to process one file...
convertOne() {
	# make sure we have the docker images
	if [[ "$(docker images -q "${PU_DOCKER_IMG}" 2> /dev/null)" == "" ]]; then
		echo "Pulling PlantUML Docker image"
		docker pull "${PU_DOCKER_IMG}"
	fi

	curPath=`pwd`
	echo "curPath = ${curPath}"
	if [ "${machine}" == "MinGw" ]; then
		curPath=/`pwd`
	fi

	# Do Conversions
	echo "Converting UML to SVG"
	docker run --rm -v "${curPath}":"${curPath}" -w "${curPath}" "${PU_DOCKER_IMG}" -tsvg "$1" 

	echo "Converting UML to PNG"
	docker run --rm -v "${curPath}":"${curPath}" -w "${curPath}" "${PU_DOCKER_IMG}" -tpng "$1"
}

# For each file specified on the command line...
for fullpath in "$@"
do
    filename="${fullpath##*/}"                      # Strip longest match of */ from start
    dir="${fullpath:0:${#fullpath} - ${#filename}}" # Substring from 0 thru pos of filename
    base="${filename%.[^.]*}"                       # Strip shortest match of . plus at least one non-dot char from end
    ext="${filename:${#base} + 1}"                  # Substring from len of base thru end
    if [[ -z "$base" && -n "$ext" ]]; then          # If we have an extension and no base, it's really the base
        base=".$ext"
        ext=""
    fi

    echo -e "$fullpath:\n\tdir  = \"$dir\"\n\tbase = \"$base\"\n\text  = \"$ext\""

	convertOne "${filename}" "${base}"
done
