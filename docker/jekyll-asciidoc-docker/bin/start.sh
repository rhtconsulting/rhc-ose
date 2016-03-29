#!/bin/bash

SOURCE_DIR=/home/builder/source
BUILD_DIR=/home/builder/build

if [ ! -d "$SOURCE_DIR" ]; then
   echo "Error: Source volume not mounted or available"
   exit 1
fi

mkdir -p "${BUILD_DIR}"

cp -a ${SOURCE_DIR}/. ${BUILD_DIR}

cd "$BUILD_DIR"

bundle install
bundle exec jekyll serve --host=0.0.0.0
