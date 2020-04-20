#!/usr/bin/env python
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
''' % revision
    with open(args.output, 'w') as f:
        f.write(output)
    return 0


if __name__ == '__main__':
    sys.exit(Main(sys.argv))
