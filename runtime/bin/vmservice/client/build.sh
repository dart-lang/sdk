#!/bin/sh

# This script copies the build outputs produced by `pub build` to
# the deployed directory.

if [ ! -d "deployed" ]; then
  echo "Run this script from the client directory"
  exit
fi

# Fixup polymer breakage
pushd lib/src
find . -name "*.html" -exec ../../dotdot.sh {} \;
popd

# Build JS
pub build

# Undo polymer breakage fix
pushd lib/src
find . -name "*.html" -exec ../../notdotdot.sh {} \;
popd

# Deploy
./deploy.sh

