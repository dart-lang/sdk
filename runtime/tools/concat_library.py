#!/usr/bin/env python
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import optparse
import shutil
import sys

def parse_options(argv):
    parser = optparse.OptionParser(usage="Usage: %prog [options] files")
    parser.add_option("--output",
                      dest="output",
                      help="Write output to FILE.",
                      metavar="FILE")
    (options, arguments) = parser.parse_args(argv[1:])
    if not arguments:
        parser.error("At least one input file must be provided.")
    if not options.output:
        parser.error("No --output provided.")
    return (options, arguments)


def main():
    # Print the command that is being run. This is helpful when
    # debugging build errors.
    sys.stderr.write('%s\n' % ' '.join(sys.argv))
    (options, arguments) = parse_options(sys.argv)
    tmp_name = '%s.tmp' % options.output
    with open(tmp_name, 'w') as output:
        for source in arguments:
            with open(source, 'r') as inpt:
                for line in inpt:
                    # Drop unneeded library tags as all the library's files
                    # are concatenated into one big file here:
                    # The 'part' and 'part of' library tags are removed.
                    if line.startswith('#source') or line.startswith('part '):
                        line = '// %s' % line
                    output.write(line)
    shutil.move(tmp_name, options.output)

if __name__ == '__main__':
    main()
