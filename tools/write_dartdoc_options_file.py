#!/usr/bin/env python3
# Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import argparse
import sys
import utils


def ParseArgs(args):
    args = args[1:]
    parser = argparse.ArgumentParser(
        description='A script to write a custom dartdoc_options.yaml to a file')

    parser.add_argument(
        '--output', '-o', type=str, required=True, help='File to write')

    return parser.parse_args(args)


def Main(argv):
    args = ParseArgs(argv)
    # TODO(jcollins-g): switch to version numbers when github has its tags synced
    revision = utils.GetGitRevision()
    if revision is None:
        revision = 'master'
    output = '''dartdoc:
  categoryOrder: ["Core", "VM", "Web"]
  linkToSource:
    root: '.'
    uriTemplate: 'https://github.com/dart-lang/sdk/blob/%s/sdk/%%f%%#L%%l%%'
  errors:
    # Default errors of dartdoc:
    - duplicate-file
    - invalid-parameter
    - no-defining-library-found
    - tool-error
    - unresolved-export
    # Warnings that are elevated to errors:
    - ambiguous-doc-reference
    - ambiguous-reexport
    - broken-link
    - category-order-gives-missing-package-name
    - deprecated
    - ignored-canonical-for
    - missing-from-search-index
    - no-canonical-found
    - no-documentable-libraries
    - no-library-level-docs
    - not-implemented
    - orphaned-file
    - reexported-private-api-across-packages
    # - unknown-directive  # Disabled due to https://github.com/dart-lang/dartdoc/issues/2353
    - unknown-file
    - unknown-macro
    - unresolved-doc-reference
''' % revision
    with open(args.output, 'w') as f:
        f.write(output)
    return 0


if __name__ == '__main__':
    sys.exit(Main(sys.argv))
