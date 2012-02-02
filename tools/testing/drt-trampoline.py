# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#
# For now we have to use this trampoline to turn --dart-flags command line
# switch into env variable DART_FLAGS.  Eventually, DumpRenderTree should
# support --dart-flags and this hack may go away.
#
# Expected invocation: python drt-trampoline.py <path to DRT> <DRT command line>

import os
import subprocess
import sys

DART_FLAGS_PREFIX = '--dart-flags='

def main(argv):
  drt_path = argv[1]
  command_line = argv[2:]

  cmd = [drt_path]

  env = None
  for arg in command_line:
    if arg.startswith(DART_FLAGS_PREFIX):
      env = dict(os.environ.items())
      env['DART_FLAGS'] = arg[len(DART_FLAGS_PREFIX):]
    else:
      cmd.append(arg)

  p = subprocess.Popen(cmd, env=env)
  p.wait()
  if p.returncode != 0:
    raise Exception('Failed to run command. return code=%s' % p.returncode)


if __name__ == '__main__':
  try:
    sys.exit(main(sys.argv))
  except StandardError as e:
    print 'Fail: ' + str(e)
    sys.exit(1)
