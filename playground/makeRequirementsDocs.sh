#!/bin/bash

# add x for debugging
set -eu

# define the docker containers & file to be processed
AD_DOCKER_IMG=asciidoctor/docker-asciidoctor
PD_DOCKER_IMG=pandoc/core
BASE_NAME=Technical_Requirements

#detect platform that we're running on...
unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=Mac;;
    CYGWIN*)    machine=Cygwin;;
    MINGW*)     machine=MinGw;;
    *)          machine="UNKNOWN:${unameOut}"
esac

# make sure we have an output dir
mkdir -p output

# this is the core routine to process one file...
convertOne() {
	# make sure we have the docker images
	if [[ "$(docker images -q "${AD_DOCKER_IMG}" 2> /dev/null)" == "" ]]; then
		echo "Pulling AsciiDoc Docker image"
		docker pull "${AD_DOCKER_IMG}"
	fi
	if [[ "$(docker images -q "${PD_DOCKER_IMG}" 2> /dev/null)" == "" ]]; then
		echo "Pulling Pandoc Docker image"
		docker pull "${PD_DOCKER_IMG}"
	fi

	curPath=`pwd`
	echo "curPath = ${curPath}"
	if [ "${machine}" == "MinGw" ]; then
		curPath=/`pwd`
	fi

	# Create the HTML & PDF versions
	# echo "Converting AsciiDoc to HTML"
	# docker run --rm -v "${curPath}":"${curPath}" -w "${curPath}"/output "${AD_DOCKER_IMG}" asciidoctor -r asciidoctor-diagram -D ./output --backend=html5 -o index.html "${BASE_NAME}".adoc

	echo "Converting AsciiDoc to PDF"
	docker run --rm -v "${curPath}":"${curPath}" -w "${curPath}" "${AD_DOCKER_IMG}" asciidoctor-pdf -r asciidoctor-diagram -D ./output --backend=pdf -a data-uri -a imagesdir=output -o "${BASE_NAME}".pdf "${BASE_NAME}".adoc	

	# Create the XML and Word versions
	echo "Converting AsciiDoc to DocBook/XML"
	docker run --rm -v "${curPath}":"${curPath}" -w "${curPath}" "${AD_DOCKER_IMG}" asciidoctor -r asciidoctor-diagram -D ./output --backend=docbook5 -o "${BASE_NAME}".xml "${BASE_NAME}".adoc

	echo "Converting DocBook to Word"
	docker run --rm -v "${curPath}":"${curPath}" -w "${curPath}"/output "${PD_DOCKER_IMG}" -f docbook -t docx "${BASE_NAME}".xml -o "${BASE_NAME}".docx
}

convertOne