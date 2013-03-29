#!/usr/bin/python
# Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import os
import shutil
import sys
import tempfile

import bot

class TempDir(object):
  def __enter__(self):
    self._temp_dir = tempfile.mkdtemp('eclipse-workspace')
    return self._temp_dir

  def __exit__(self, *_):
    shutil.rmtree(self._temp_dir, ignore_errors = True)

def GetEditorExecutable(mode, arch):
  configuration_dir = mode + arch.upper()
  linux_path = os.path.join('out', configuration_dir, 'editor')
  win_path = os.path.join('build', configuration_dir, 'editor')
  mac_path = os.path.join('xcodebuild', configuration_dir, 'editor')

  if sys.platform == 'darwin':
    executable = os.path.join('DartEditor.app', 'Contents', 'MacOS',
                              'DartEditor')
    # TODO(kustermann,ricow): Maybe we're able to get rid of this in the future.
    # We use ninja on bots which use out/ instead of xcodebuild/
    if os.path.exists(linux_path) and os.path.isdir(linux_path):
      return os.path.join(linux_path, executable)
    else:
      return os.path.join(mac_path, executable)
  elif sys.platform == 'win32':
    return os.path.join(win_path, 'DartEditor.exe')
  elif sys.platform == 'linux2':
    return os.path.join(linux_path, 'DartEditor')
  else:
    raise Exception('Unknown platform %s' % sys.platform)


def main():
  build_py = os.path.join('tools', 'build.py')
  architectures = ['ia32', 'x64']
  test_architectures = ['x64']
  if sys.platform == 'win32':
    # Our windows bots pull in only a 32 bit JVM.
    test_architectures = ['ia32']

  for arch in architectures:
    with bot.BuildStep('Build Editor %s' % arch):
      args = [sys.executable, build_py,
              '-mrelease', '--arch=%s' % arch, 'editor']
      print 'Running: %s' % (' '.join(args))
      sys.stdout.flush()
      bot.RunProcess(args)

  for arch in test_architectures:
    editor_executable = GetEditorExecutable('Release', arch)
    with bot.BuildStep('Test Editor %s' % arch):
      with TempDir() as temp_dir:
        args = [editor_executable, '--test', '--auto-exit', '-data', temp_dir]
        print 'Running: %s' % (' '.join(args))
        sys.stdout.flush()
        bot.RunProcess(args)
  return 0

if __name__ == '__main__':
  try:
    sys.exit(main())
  except OSError as e:
    sys.exit(e.errno)
