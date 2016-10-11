#!/bin/bash
set -e

# Switch to the root directory of dev_compiler
cd $( dirname "${BASH_SOURCE[0]}" )/..

# Run formatter in rewrite mode on all files that are part of the project.
# This checks that all files are commited first to git, so no state is lost.
# The formatter ignores:
#   * local files that have never been added to git,
#   * subdirectories of test/ and tool/, unless explicitly added. Those dirs
#     contain a lot of generated or external source we should not reformat.
(files=`git ls-files 'bin/*.dart' 'lib/*.dart' test/*.dart test/checker/*.dart \
  tool/*.dart | grep -v lib/src/js_ast/`; git status -s $files | grep -q . \
  && echo "Did not run the formatter, please commit edited files first." \
  || (echo "Running dart formatter" ; \
  dart ../../third_party/pkg_tested/dart_style/bin/format.dart -w $files))
