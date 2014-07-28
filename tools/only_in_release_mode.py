#!/usr/bin/env python
#
# Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""
Wrapper around a build action that should only be executed in release mode.

The mode is defined via an environment variable DART_BUILD_MODE.

The arguments to the script are:

  only_in_release_mode.py files... -- command arguments...

If mode is not 'release', the script will create the files listed
before --.  If mode is release, the script will execute the command
after --.
"""

import os
import subprocess
import sys


def Main():
  # Throws an error if '--' is not in the argument list.
  separator_index = sys.argv.index('--')
  outputs = sys.argv[1:separator_index]
  arguments = sys.argv[separator_index + 1:]
  arguments[0] = os.path.normpath(arguments[0])
  mode = os.getenv('DART_BUILD_MODE', 'release')
  if mode != 'release':
    print >> sys.stderr, 'Not running %s in mode=%s' % (arguments, mode)
    for output in outputs:
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
