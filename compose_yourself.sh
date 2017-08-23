#!/bin/bash

####
#Script takes two arguments, the source tag and the deploy tag
####

TMP_DIR="/tmp"
NOW=$(date +"%m_%d_%Y")

###Arguments

if [ $# -ne 4 ]; then
  echo 'Please provide a source repo and tag and a deploy repo and tag, like so:'
  echo 'compose_yourself.sh <source_repo> <source_tag> <deploy_repo> <deploy_tag>'
  exit 1
fi

SRC_REPO=$1
SRC_TAG=$2

TARGET_REPO=$3
TARGET_TAG=$4

###Cleanup

if [ -d "${TMP_DIR}/compose_yourself_work" ]; then
  rm -rf "${TMP_DIR}/compose_yourself_work"
fi
 
mkdir "${TMP_DIR}/compose_yourself_work"

###Checkout Source

pushd "${TMP_DIR}/compose_yourself_work"
git clone ${SRC_REPO} src_checkout || exit 1
pushd src_checkout

if [ -d web/core ]; then
  rm -rf web/core
fi

if [ -d vendor ]; then
  rm -rf vendor
fi

if [ -d web/modules/contrib ]; then
  rm -rf web/modules/contrib
fi

###Compose

composer install || (echo "We cannot compose oursolves" && exit 1)

###Strip git info

#Remove gitignore
rm .gitignore

#Strip git out of vendor
pushd vendor
find -name '.git' | xargs rm -rf
popd

#Strip git out of web
pushd web
find -name '.git' | xargs rm -rf
popd 

###Commit

git remote add deploy ${TARGET_REPO} || exit 1
git add web || exit 1
git add vendor || exit 1
git commit -m "Composed Deploy Tree For Tag ${SRC_TAG}" || exit 1
git push deploy ${SRC_TAG}:${TARGET_TAG}_$NOW || exit 1

###Cleanup
popd
popd
rm -rf "${TMP_DIR}/compose_yourself_work"
