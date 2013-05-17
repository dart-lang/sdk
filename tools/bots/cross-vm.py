#!/usr/bin/python
# Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import os
import re
import shutil
import sys
import tempfile

import bot

GCS_BUCKET = 'gs://dart-cross-compiled-binaries'
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.append(os.path.join(SCRIPT_DIR, '..'))

import utils

CROSS_VM = r'cross-(arm)-vm-linux-(release)'
TARGET_VM = r'target-(arm)-vm-linux-(release)'
GSUTIL = utils.GetBuildbotGSUtilPath()

def run(args):
  print 'Running: %s' % (' '.join(args))
  sys.stdout.flush()
  bot.RunProcess(args)

def main():
  name, is_buildbot = bot.GetBotName()
  build_py = os.path.join('tools', 'build.py')
  test_py = os.path.join('tools', 'test.py')

  cross_vm_pattern_match = re.match(CROSS_VM, name)
  target_vm_pattern_match = re.match(TARGET_VM, name)
  if cross_vm_pattern_match:
    arch = cross_vm_pattern_match.group(1)
    mode = cross_vm_pattern_match.group(2)

    bot.Clobber()
    with bot.BuildStep('Build %s %s' % (arch, mode)):
      args = [sys.executable, build_py,
              '-m%s' % mode, '--arch=%s' % arch, 'runtime']
      run(args)

    tarball = 'cross_build_%s_%s.tar.bz2' % (arch, mode)
    try:
      with bot.BuildStep('Create build tarball'):
        run(['tar', '-cjf', tarball, '--exclude=**/obj',
             '--exclude=**/obj.host', '--exclude=**/obj.target',
             '--exclude=**/*analyzer*', 'out/'])

      with bot.BuildStep('Upload build tarball'):
        uri = "%s/%s" % (GCS_BUCKET, tarball)
        run([GSUTIL, 'cp', tarball, uri])
        run([GSUTIL, 'setacl', 'public-read', uri])
    finally:
      if os.path.exists(tarball):
        os.remove(tarball)
  elif target_vm_pattern_match:
    arch = target_vm_pattern_match.group(1)
    mode = target_vm_pattern_match.group(2)

    bot.Clobber()
    tarball = 'cross_build_%s_%s.tar.bz2' % (arch, mode)
    try:
      test_args = [sys.executable, test_py, '--progress=line', '--report',
              '--time', '--mode=' + mode, '--arch=' + arch, '--compiler=none',
              '--runtime=vm', '--write-debug-log']

      with bot.BuildStep('Fetch build tarball'):
        run([GSUTIL, 'cp', "%s/%s" % (GCS_BUCKET, tarball), tarball])

      with bot.BuildStep('Unpack build tarball'):
        run(['tar', '-xjf', tarball])

      with bot.BuildStep('tests'):
        run(test_args)

      with bot.BuildStep('checked_tests'):
        run(test_args + ['--checked'])
    finally:
      if os.path.exists(tarball):
        os.remove(tarball)
  else:
    raise Exception("Unknown builder name %s" % name)

if __name__ == '__main__':
  sys.exit(main())
