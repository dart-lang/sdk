#!/bin/bash
#
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#

# A quick check over a subset the tests in the runtime, compiler 
# and client directories.

# Currently builds and checks:
#  runtime - release mode
#  compiler - debug mode (non-optimized)
#  client - chromium debug mode

DO_OPTIMIZE=0
DO_DARTIUM=0
TESTS_FAILED=0

function usage {
  echo "usage: $0 [ --help ] [ --optimize ] [ --dartium ] "
  echo
  echo "Runs a quick set of tests on runtime, client, and compiler dirs"
  echo
  echo " --optimize: Also run dartc and client tests in release mode"
  echo " --dartium : Also run dartium/debug tests"
  echo
}

# Compile the vm/runtime
# $1 directory to build in
# $2 arch 
# $3 mode
function doBuild {
  ./tools/build.py --arch $1 --mode $2
  if [ $? != 0 ] ; then
    echo "Build of $1 - $2 failed"
    exit 1
  fi
}

# Execute a set of tests
# $1 directory to test in
# $2 arch 
# $3 mode
# Returns the output from the subcommand
function doTest {
  ./tools/test.py --component $2 --mode $3
  RESULT=$?
  if [ ${RESULT} != 0 ] ; then
    TESTS_FAILED=1
  fi
  return ${RESULT}
}

# Main

while [ ! -z "$1" ] ; do
  case $1 in
    "-h"|"-?"|"-help"|"--help")
      usage
      exit 1
    ;;
    "--optimize")
      DO_OPTIMIZE=1
    ;;
    "--dartium")
      DO_DARTIUM=1
    ;; 
    *)
      echo "Unrecognized argument: $1"
      usage
      exit 1
    ;;
  esac
  shift
done

if [ ! -d compiler -o ! -d runtime -o ! -d tests ] ; then
  echo "This doesn't look like the dart source tree."
  echo "Change your directory to the dart trunk source"
  exit 1
fi

echo
echo "--- Building release ---"
doBuild ia32 release

echo
echo "--- Building debug ---"
doBuild ia32 debug

echo
echo "=== Runtime tests === "
echo " Debug (Ctrl-C to skip this set of tests)"
doTest runtime vm debug
RUNTIME_RESULT=$?
if [ ${RUNTIME_RESULT} == 0 ] ; then
  echo " Release (Ctrl-C to skip this set of tests)"
  doTest runtime vm release 
  RUNTIME_RESULT=$?
fi


echo
echo "=== dartc tests ==="
echo " Debug mode (Ctrl-C to skip this set of tests)"
doTest compiler dartc debug
DARTC_RESULT=$?

if [ ${DO_OPTIMIZE} == 1 ] ; then
  echo " Release mode (--optimize)"
  doTest compiler dartc release
  RESULT=$?
  if [ ${RESULT} != 0 ] ; then
    DARTC_RESULT=${RESULT}
  fi
fi

echo
echo "=== Client tests ==="
echo " Chromium  (Ctrl-C to skip this set of tests)"
doTest client chromium debug
CLIENT_RESULT=$?

if [ ${DO_OPTIMIZE} == 1 ] ; then
  echo " Chromium Release mode (--optimize)"
  doTest compiler chromium release
  RESULT=$?
  if [ ${RESULT} != 0 ] ; then
    CLIENT_RESULT=${RESULT}
  fi
fi

if [ ${DO_DARTIUM} == 1 ] ; then
  echo " Dartium (Ctrl-C to skip this set of tests)"
  doTest client dartium release
  RESULT=$?
  if [ ${RESULT} != 0 ] ; then
    CLIENT_RESULT=${RESULT}
  fi
fi

# Print summary of results
if [ ${RUNTIME_RESULT}  != 0 ] ; then
  echo "*** vm tests failed"
fi

if [ ${DARTC_RESULT}  != 0 ] ; then
  echo "*** dartc tests failed"
fi

if [ ${CLIENT_RESULT}  != 0 ] ; then
  echo "*** client tests failed"
fi

if [ ${TESTS_FAILED} == 0 ] ; then
  echo "All presubmit tests passed!"
fi
