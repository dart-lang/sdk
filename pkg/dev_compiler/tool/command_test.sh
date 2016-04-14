#!/bin/bash

set -e # bail on error

# Some tests require being run from the package root
# switch to the root directory of dev_compiler
cd $( dirname "${BASH_SOURCE[0]}" )/..

dart -c ./bin/dartdevc.dart compile --no-summarize \
    -o test/command/hello.js test/command/hello.dart
