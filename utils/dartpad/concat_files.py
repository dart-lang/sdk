#!/usr/bin/env python3
# Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
"""Concatenates one or more input files into a single output file.

Used by GN action() targets in utils/dartpad/BUILD.gn to bundle JavaScript
assets during the build, separating each input file with a newline.

Example usage:
  python3 utils/dartpad/concat_files.py --output=out.js first.js second.js
"""

import argparse
import os


def main():
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        '--output',
        required=True,
        help='Path to the destination file to write.',
    )
    parser.add_argument(
        'inputs',
        nargs='+',
        help='Ordered list of input file paths to concatenate.',
    )
    args = parser.parse_args()

    os.makedirs(os.path.dirname(args.output), exist_ok=True)
    # Remove any existing file first in case a previous GN copy() rule created a
    # hardlink to a source file at the output path.
    if os.path.exists(args.output):
        os.unlink(args.output)

    with open(args.output, 'wb') as out_f:
        for input_path in args.inputs:
            with open(input_path, 'rb') as in_f:
                out_f.write(in_f.read())
            out_f.write(b'\n')


if __name__ == '__main__':
    main()
