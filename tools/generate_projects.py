#!/usr/bin/env python
#
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import os
import sys
import platform

def NormJoin(path1, path2):
  return os.path.normpath(os.path.join(path1, path2))


def GetProjectGypFile(project_name):
  project_file = os.path.join(project_name, 'dart-%s.gyp' % project_name)
  if not os.path.exists(project_file):
    sys.stderr.write('%s does not exist\n' % project_file)
    project_file = os.path.join(project_name, 'dart.gyp')
  return project_file

dart_src = NormJoin(os.path.dirname(sys.argv[0]), os.pardir)
project_src = sys.argv[1]
gyp_pylib = os.path.join(dart_src, 'third_party', 'gyp', 'pylib')

if __name__ == '__main__':
  # If this script is invoked with the -fmake option, we assume that
  # it is being run automatically via a project Makefile. That can be
  # problematic (because GYP is really bad at setting up the paths
  # correctly), so we try to run "gclient runhooks" instead.
  if '-fmake' in sys.argv:
    try:
      sys.exit(os.execvp("gclient", ["gclient", "runhooks"]))
    except OSError:
      # Sometimes gclient is not on the PATH. Let the user know that
      # he must run "gclient runhooks" manually.
      sys.stderr.write('Error: GYP files are out of date.\n')
      sys.stderr.write('\n\n*** Please run "gclient runhooks" ***\n\n\n')
      sys.exit(1)


# Add gyp to the imports and if needed get it from the third_party location
# inside the standalone dart gclient checkout.
try:
  import gyp
except ImportError, e:
  sys.path.append(os.path.abspath(gyp_pylib))
  import gyp


if __name__ == '__main__':
  # Make our own location absolute as it is stored in Makefiles.
  sys.argv[0] = os.path.abspath(sys.argv[0])

  # Add any extra arguments. Needed by compiler/dart.gyp to build v8.
  args = sys.argv[2:]

  args += ['--depth', project_src]
  args += ['-I', './tools/gyp/common.gypi']

  if platform.system() == 'Linux':
    # We need to fiddle with toplevel-dir to work around a GYP bug
    # that breaks building v8 from compiler/dart.gyp.
    args += ['--toplevel-dir', os.curdir]
    args += ['--generator-output', project_src]
  else:
    # On at least the Mac, the toplevel-dir should be where the
    # sources are. Otherwise, Xcode won't show sources correctly.
    args += ['--toplevel-dir', project_src]

  # Change into the dart directory as we want the project to be rooted here.
  # Also, GYP is very sensitive to exacly from where it is being run.
  os.chdir(dart_src)

  args += [GetProjectGypFile(project_src)]

  # Generate the projects.
  sys.exit(gyp.main(args))
