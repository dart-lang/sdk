#!/usr/bin/env python
# Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import os
import subprocess
import sys
import utils

usage = """compile_platform.py [options]"""

def DisplayBootstrapWarning():
  print """\


WARNING: Your system can't run the checked-in Dart SDK.  Using the bootstrap
Dart executable will make debug builds slow.  Please see the Wiki for
instructions on replacing the checked-in Dart SDK.

https://github.com/dart-lang/sdk/wiki/The-checked-in-SDK-in-tools

"""


def path(uri_path):
  args = [ os.path.dirname(__file__), ".." ] + uri_path.split("/")
  return os.path.normpath(os.path.join(*args))


def main():
  verbose = False
  arguments = [ None ] # Leave room for the Dart VM executable.
  arguments.append("--packages=" + path(".packages"))
  arguments.append(path("pkg/front_end/tool/_fasta/compile_platform.dart"))
  i = 1 # Skip argument #0 which is the script name.
  dart_executable = None
  while i < len(sys.argv):
    argument = sys.argv[i]
    if argument == "--dart-executable":
      dart_executable = sys.argv[i + 1]
      i += 1
    elif argument.startswith("--dart-executable="):
      dart_executable = argument[len("--dart-executable="):]
    else:
      if argument == "-v" or argument == "--verbose":
        verbose = True
      arguments.append(argument)
    i += 1

  if dart_executable:
    dart_executable = os.path.abspath(dart_executable)
  else:
    if utils.CheckedInSdkCheckExecutable():
      dart_executable = utils.CheckedInSdkExecutable()
    else:
      DisplayBootstrapWarning()
      print >> sys.stderr, "ERROR: Can't locate Dart VM executable."
      return -1

  arguments[0] = os.path.abspath(dart_executable)
  if verbose:
    print "Running:", " ".join(arguments)
  return subprocess.call(arguments)


if __name__ == "__main__":
  sys.exit(main())
