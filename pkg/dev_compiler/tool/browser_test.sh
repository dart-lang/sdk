#!/bin/bash
set -e # bail on error

# Switch to the root of the SDK tree
cd $( dirname "${BASH_SOURCE[0]}" )/../../..

./tools/test.py -m release -r chrome -c dartdevc --strong corelib_2 language_2 \
    lib_2 corelib_strong language_strong lib_strong || fail
