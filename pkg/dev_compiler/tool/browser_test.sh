#!/bin/bash

# Check that node exists and refers to nodejs
checknodejs=$(hash node 2> /dev/null  && node --help | grep js)
if [[ $? -ne 0 ]]; then
  echo 'NodeJS (node) is not properly installed'
  echo 'Note, on Ubuntu / Debian, you may need to also install:'
  echo '$ sudo apt-get install nodejs-legacy'
  exit 1
fi

# Check that npm is installed
checknpm=$(hash npm 2> /dev/null)
if [[ $? -ne 0 ]]; then
  echo 'Node Package Manager (npm) is not properly installed'
  exit 1
fi

# Check for Chrome Canary on Ubuntu
# The default install path is sometimes google-chrome-unstable
# instead of google-chrome-canary as karma expects.
if [[ "$OSTYPE" == "linux-gnu" ]] && [[ -z "$CHROME_CANARY_BIN" ]]; then
  checkcanary=$(hash google-chrome-canary 2> /dev/null)
  if [[ $? -ne 0 ]]; then
    checkunstable=$(hash google-chrome-unstable 2> /dev/null)
    if [[ $? -ne 0 ]]; then
      echo 'Chrome Canary is not found'
      echo 'Please install and/or set CHROME_CANARY_BIN to its path'
      exit 1
    else
      export CHROME_CANARY_BIN=google-chrome-unstable
    fi
  fi
fi

npm install
npm test
