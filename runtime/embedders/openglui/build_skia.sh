#!/bin/bash

function usage {
  echo "usage: $0 [ --help ] [ --android ] [ --arm | --x86] [ --debug ] [--clean] [<Dart directory>]"
  echo
  echo "Sync up Skia and build"
  echo
  echo " --android: Build for Android"
  echo " --x86 : Build for Intel"
  echo " --arm : Cross-compile for ARM (implies --android)"
  echo " --debug : Build a debug version"
  echo
}

DO_ANDROID=0
TARGET_ARCH=x86
CLEAN=0
BUILD=Release
DART_DIR=../../..

while [ ! -z "$1" ] ; do
  case $1 in
    "-h"|"-?"|"-help"|"--help")
      usage
      exit 1
    ;;
    "--android")
      DO_ANDROID=1
    ;;
    "--arm")
      TARGET_ARCH=arm
      DO_ANDROID=1
    ;;
    "--x86")
      TARGET_ARCH=x86
    ;;
    "--clean")
      CLEAN=1
    ;;
    "--debug")
      BUILD=Debug
    ;;
    "--release")
      BUILD=Release
    ;;
    *)
      if [ ! -d "$1" ]
      then
        echo "Unrecognized argument: $1"
        usage
        exit 1
      fi
      DART_DIR="$1"
    ;;
  esac
  shift
done

mkdir -p "${DART_DIR}/third_party/skia"
pushd "${DART_DIR}/third_party/skia"

if [ ${DO_ANDROID} != 0 ] ; then
  echo "Building for Android ${TARGET_ARCH}"
  curl http://skia.googlecode.com/svn/android/gclient.config -o .gclient
  gclient sync

  export ANDROID_SDK_ROOT=`readlink -f ../android_tools/sdk`

  cd trunk

  echo "Using SDK ${ANDROID_SDK_ROOT}"
  if [ ${CLEAN} != 0 ] ; then
    ../android/bin/android_make -d $TARGET_ARCH -j clean
  else
    env -i BUILDTYPE=$BUILD ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT}" ../android/bin/android_make BUILDTYPE=$BUILD -d $TARGET_ARCH -j --debug=j
  fi

else

  echo "Building for desktop in `pwd`"
  # Desktop build. Requires svn client and Python.

  # Note that on Linux these packages should be installed first:
  #
  # libfreetype6
  # libfreetype6-dev
  # libpng12-0, libpng12-dev
  # libglu1-mesa-dev
  # mesa-common-dev
  # freeglut3-dev

  SKIA_INSTALLDIR=`pwd`
  svn checkout http://skia.googlecode.com/svn/trunk
  cd trunk
  if [ ${CLEAN} != 0 ] ; then
    echo 'Cleaning'
    make clean
  else
    # Dart sets BUILDTYPE to DebugX64 which breaks Skia build.
    make BUILDTYPE=$BUILD
  fi
  cd ..

fi

popd
# TODO(gram) We should really propogate the make exit code here.
exit 0


