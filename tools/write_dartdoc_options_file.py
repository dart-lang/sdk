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
    parser.add_argument('--no-git-hash',
                        help='Omit the git hash in the output',
                        dest='no_git_hash',
                        action='store_true')

    return parser.parse_args(args)


def Main(argv):
    args = ParseArgs(argv)
    # TODO(jcollins-g): switch to version numbers when github has its tags synced
    revision = None
    if not args.no_git_hash:
        revision = utils.GetGitRevision()
    if revision is None:
        revision = 'main'
    output = '''dartdoc:
  categoryOrder: ["Core", "VM", "Web", "Web (Legacy)"]
  categories:
    'Web':
      external:
        - name: 'package:web'
          url: https://pub.dev/documentation/web/latest/
          docs: >-
            This package exposes browser APIs. It's intended to replace
            dart:html and similar Dart SDK libraries. It will support access to
            browser APIs from Dart code compiled to either JavaScript or
            WebAssembly.
    'Web (Legacy)':
      external:
        - name: 'package:js'
          url: https://pub.dev/documentation/js/latest/
          docs: >-
            Use this package when you want to call JavaScript APIs from Dart
            code, or vice versa.
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
  header:
    - ../../../tools/bots/dartdoc_header.html
  footer:
    - ../../../tools/bots/dartdoc_footer.html
  footerText:
    - ../../../tools/bots/dartdoc_footer_text.html
''' % revision
    with open(args.output, 'w') as f:
        f.write(output)
    return 0


if __name__ == '__main__':
    sys.exit(Main(sys.argv))
