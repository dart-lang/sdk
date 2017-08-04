#!/bin/bash
set -e # bail on error

# Switch to the root of the SDK tree
cd $( dirname "${BASH_SOURCE[0]}" )/../../..

# TODO(jmesserly): we need to figure out how to get Travis to extract the
# checked in SDK used by test.py. I think this might be done by runhooks, which
# we're skipping when we aren't in C++ build mode.
dart -c tools/testing/dart/main.dart -m release -r chrome -c dartdevc --strong \
    corelib_2 language_2 lib_2 corelib_strong language_strong lib_strong || fail
