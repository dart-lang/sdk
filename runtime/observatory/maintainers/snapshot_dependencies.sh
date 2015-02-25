#!/bin/sh

# This script will create a deep snapshot of all Observatory package
# dependencies. The output will be in observatory_pub_packages which
# then should be committed to third_party/observatory_pub_packages.


PUBSPEC_INPUT="pubspec.template"
PUBSPEC_OUTPUT="pubspec.yaml"
PACKAGES_INPUT="packages"
PACKAGES_OUTPUT="observatory_pub_packages"

if [ ! -d "../maintainers" ]; then
  echo "Please run this script from the maintainers directory"
  exit
fi

if [ ! -f $PUBSPEC_INPUT ]; then
  echo "Cannot find $PUBSPEC_INPUT"
  exit
fi

# Cleanup leftovers
rm -f $PUBSPEC_OUTPUT
rm -rf $PACKAGES_INPUT
rm -rf $PACKAGES_OUTPUT

# Setup for pub get run
cp $PUBSPEC_INPUT $PUBSPEC_OUTPUT

# Run pub get
pub get

# Prepare for output
mkdir $PACKAGES_OUTPUT

OUTPUT_BASE=`realpath $PACKAGES_OUTPUT`
# Copy necessary files
pushd $PACKAGES_INPUT  > /dev/null
for i in *; do
  ACTUAL_PATH=`realpath $i`
  mkdir $OUTPUT_BASE/$i
  mkdir $OUTPUT_BASE/$i/lib
  cp $ACTUAL_PATH/../pubspec.yaml $OUTPUT_BASE/$i/pubspec.yaml
  rsync -Lr $ACTUAL_PATH/* $OUTPUT_BASE/$i/lib
done
popd > /dev/null

echo '***'
echo 'Dumping package dependencies:':
echo ''
echo 'dependency_overrides:'
pushd $PACKAGES_OUTPUT > /dev/null
for i in *; do
  echo -e "  $i:\n    path: ../../third_party/$PACKAGES_OUTPUT/$i"
done
popd > /dev/null
echo ''
echo '***'
echo -n 'Now run: rsync -a --delete observatory_pub_packages/ '
echo '~/workspace/dart-third_party/observatory_pub_packages/'
echo 'Then: '
echo 'cd ~/workspace/dart-third_party/observatory_pub_packages/'
echo "svn status | grep ^? | sed 's/?    //' | xargs svn add"
echo "svn st | grep ^! | sed 's/!    //' | xargs svn rm"
echo '***'
