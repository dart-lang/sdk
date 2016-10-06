#!/bin/bash
#
# Ensures the latest Chrome Canary is available, downloading it
# if necessary.
#
# Directory ~/.chrome/canary can safely be cached as the existing
# version will be checked before reusing a previously downloaded
# canary.
#

set -eu

readonly CHROME_SNAPSHOTS=https://storage.googleapis.com/chromium-browser-snapshots
declare CHROME_URL
declare CHROME_NAME
declare CHROME_RELATIVE_BIN

if [[ "$OSTYPE" == "linux"* ]]; then
  CHROME_URL=$CHROME_SNAPSHOTS/Linux_x64
  CHROME_NAME=chrome-linux
  CHROME_RELATIVE_BIN=chrome
elif [[ "$OSTYPE" == "darwin"* ]]; then
  CHROME_URL=$CHROME_SNAPSHOTS/Mac
  CHROME_NAME=chrome-mac
  CHROME_RELATIVE_BIN=Chromium.app/Contents/MacOS/Chromium
elif [[ "$OSTYPE" == "cygwin" ]]; then
  CHROME_URL=$CHROME_SNAPSHOTS/Win
  CHROME_NAME=chrome-win32
  CHROME_RELATIVE_BIN=chrome.exe
else
  echo "Unknown platform: $OSTYPE" >&2
  exit 1
fi

readonly CHROME_CANARY_DIR=$HOME/.chrome/canary
readonly CHROME_CANARY_BIN=$CHROME_CANARY_DIR/$CHROME_NAME/$CHROME_RELATIVE_BIN
readonly CHROME_CANARY_REV_FILE=$CHROME_CANARY_DIR/VERSION
readonly CHROME_REV=$(curl -s ${CHROME_URL}/LAST_CHANGE)

function getCanary() {
  local existing_version=""
  if [[ -f $CHROME_CANARY_REV_FILE && -x $CHROME_CANARY_BIN ]]; then
    existing_version=`cat $CHROME_CANARY_REV_FILE`
    echo "Found cached Chrome Canary version: $existing_version"
  fi

  if [[ "$existing_version" != "$CHROME_REV" ]]; then
    echo "Downloading Chrome Canary version: $CHROME_REV"
    rm -fR $CHROME_CANARY_DIR
    mkdir -p $CHROME_CANARY_DIR

    local file=$CHROME_NAME.zip
    curl ${CHROME_URL}/${CHROME_REV}/$file -o $file
    unzip $file -d $CHROME_CANARY_DIR
    rm $file
    echo $CHROME_REV > $CHROME_CANARY_REV_FILE
  fi
}

getCanary >&2

echo $CHROME_CANARY_BIN
