#!/bin/sh

# NOTE: You should only have to run this script if you add a new resource
# (html, js, image) file.

# This script generates lines for resources_sources.gypi (standalone)
# and devtools.gypi (Dartium) for the current deployed Observatory.

if [ ! -d deployed ]; then
  echo "Please run inside client directory"
fi

PREFIX="vmservice/client"
echo "For resources_sources.gypi:"
for i in `find deployed/web/ -not -type d -not -path '*/\.*' -not -path '*~'`; do
  echo "'$PREFIX/$i',"
done

PREFIX="../../../../dart/runtime/bin/vmservice/client"
echo "For devtools.gypi:"
for i in `find deployed/web/ -not -type d -not -path '*/\.*' -not -path '*~'`; do
  echo "'$PREFIX/$i',"
done
