#!/bin/bash

# Print svn revisions for Dartium internal repositories.  The output
# is included in each Dartium archive build / release.
#
# This script is necessary because Dartium maintains its own branches
# of Chromium and WebKit.  This script is for temporary use only; it
# will not be integrated back into Chromium.

function version() {
  if [ $(svnversion) == exported ]
  then
    # git-svn
    git svn info | grep Revision | cut -c 11-
  else
    # svn
    echo $(svnversion)
  fi
}

root_dir=$(dirname $0)/../..
pushd ${root_dir} > /dev/null
echo dartium-chromium: $(version)
cd third_party/WebKit
echo dartium-webkit: $(version)
cd ../../dart/runtime
echo dartium-runtime: $(version)
popd > /dev/null
