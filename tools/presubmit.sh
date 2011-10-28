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
  cd $1
  ../tools/build.py --arch $2 --mode $3
  if [ $? != 0 ] ; then
    echo "Build of $1 failed"
    exit 1
  fi
  cd ..
}

# Execute a set of tests
# $1 directory to test in
# $2 arch 
# $3 mode
# Returns the output from the subcommand
function doTest {
  cd $1
  ../tools/test.py --arch $2 --mode $3
  RESULT=$?
  cd ..
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
echo "--- Building runtime ---"
doBuild runtime ia32 release

echo
echo "--- Building compiler ---"
doBuild compiler ia32 debug

if [ ${DO_OPTIMIZE} == 1 ] ; then
  # echo "Syncing compiler debug build to release"
  # rsync -a out/Debug_ia32 out/Release_ia32
  doBuild compiler ia32 release
fi

# TODO(zundel): Potential shortcut: don't rebuild all of dartc again.
# Tried using rsync, but it doesn't work - client rebuilds anyway

# Build in client dir
echo
echo "--- Building client ---"
doBuild client ia32 debug

if [ ${DO_OPTIMIZE} == 1 ] ; then
  # echo "Syncing client debug build to release"
  # rsync -a out/Debug_ia32 out/Release_ia32
  doBuild client ia32 release
fi


echo
echo "=== Runtime tests === "
doTest runtime ia32 release 
RUNTIME_RESULT=$?


echo
echo "=== Compiler tests ==="
echo " Debug mode (Ctrl-C to skip this set of tests)"
doTest compiler dartc debug
COMPILER_RESULT=$?

if [ ${DO_OPTIMIZE} == 1 ] ; then
  echo " Release mode (--optimize) (Ctrl-C to skip this set of tests)"
  doTest compiler dartc release
  RESULT=$?
  if [ ${RESULT} != 0 ] ; then
    COMPILER_RESULT=${RESULT}
  fi
fi

echo
echo "=== Client tests ==="
echo " Chromium  (Ctrl-C to skip this set of tests)"
doTest client chromium debug
CLIENT_RESULT=$?

if [ ${DO_OPTIMIZE} == 1 ] ; then
  echo " Chromium Release mode (--optimize) (Ctrl-C to skip this set of tests)"
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
  echo "*** Runtime tests failed"
fi

if [ ${COMPILER_RESULT}  != 0 ] ; then
  echo "*** Compiler tests failed"
fi

if [ ${CLIENT_RESULT}  != 0 ] ; then
  echo "*** Client tests failed"
fi

if [ ${TESTS_FAILED} == 0 ] ; then
  echo "All presubmit tests passed!"
fi
