#!/usr/bin/env python
#
# Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""
Wrapper around a build action that should only be executed in "release" mode.

The following options are accepted:

  --mode=[release,debug]

  --outputs=files...

If mode is not 'release', the script will create the files listed in
outputs.  If mode is release, the script will execute the remaining
command line arguments as a command.

Files are a list of quoted filenames separated by space.  For example,
'"file1.ext" "file2.ext"'
"""

import optparse
import subprocess
import sys


def BuildOptions():
  result = optparse.OptionParser()
  result.add_option('-m', '--mode')
  result.add_option('-o', '--outputs')
  return result


def Main():
  (options, arguments) = BuildOptions().parse_args()
  if options.mode != 'release':
    print >> sys.stderr, 'Not running %s in mode=%s' % (arguments,
                                                        options.mode)
    for output in options.outputs.strip('"').split('" "'):
      with open(output, 'w'):
        # Create an empty file to ensure that we don't rerun this
        # command unnecessarily.
        pass
    return 0
  else:
    try:
      subprocess.check_call(arguments)
    except subprocess.CalledProcessError as e:
      return e.returncode
    return 0


if __name__ == '__main__':
  sys.exit(Main())
