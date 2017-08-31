#!/bin/bash

####
####

TMP_DIR="/tmp"
NOW=$(date +"%m_%d_%Y")

usage() {
  echo "usage: $0 -s source-repo -t source-tag [-r destination-repo] [-d destination-tag]"
  echo "    -s          Source git repo URI"
  echo "    -t          Source git tag or branch to operate on"
  echo "    -r          Destination repo to push composer-ized code to"
  echo "    -d          Destination branch ta to push composer-ized code to"
  echo ""
  echo 'Please provide a source repo and tag, and a deploy repo and tag, like so:'
  echo 'compose_yourself.sh -s <source_repo> -t <source_tag> -r <destination_repo> -d <destination_tag>'
  echo "Destination repo and tag are optional. If not specified, the script will push to the source repo and/or branch."
  exit 1
}

while getopts "d:r:s:t:" opt; do
  case $opt in
    d)
      TARGET_TAG=$OPTARG
      ;;
    r)
      TARGET_REPO=$OPTARG
      ;;
    s)
      SRC_REPO=$OPTARG
      ;;
    t)
      SRC_TAG=$OPTARG
      ;;
    *)
      usage
  esac
done

if [ -z "${SRC_REPO}" ] || [ -z "${SRC_TAG}" ]
then
  usage
fi

# Set Target repo and branch if not specified.
if [ -z "${TARGET_REPO}" ]
then
  TARGET_REPO=$SRC_REPO
fi
if [ -z "${TARGET_TAG}" ]
then
  TARGET_TAG=$SRC_TAG
fi

TARGET_REPO=$3
TARGET_TAG=$4

###Cleanup

if [ -d "${TMP_DIR}/compose_yourself_work" ]; then
  rm -rf "${TMP_DIR}/compose_yourself_work"
fi

mkdir "${TMP_DIR}/compose_yourself_work"

###Checkout Source

pushd "${TMP_DIR}/compose_yourself_work"
git clone ${SRC_REPO} src_checkout || { echo "Error with git clone."; exit 1 }
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

composer install || (echo "We cannot compose ourselves" && exit 1)

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
