#!/usr/bin/python
# Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import os
import re
import sys

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

def tarball_name(arch, mode, revision):
  return 'cross_build_%s_%s_%s.tar.bz2' % (arch, mode, revision)

def record_names(name, arch, mode):
  return ('record_%s_%s_%s.json' % (name, arch, mode),
          'record_output_%s_%s_%s.json' % (name, arch, mode))

def cross_compiling_builder(arch, mode):
  build_py = os.path.join('tools', 'build.py')
  revision = int(os.environ['BUILDBOT_GOT_REVISION'])
  tarball = tarball_name(arch, mode, revision)
  temporary_files = [tarball]
  bot.Clobber()
  try:
    num_run = int(os.environ['BUILDBOT_ANNOTATED_STEPS_RUN'])
    if num_run == 1:
      with bot.BuildStep('Build %s %s' % (arch, mode)):
        run([sys.executable, build_py,
             '-m%s' % mode, '--arch=%s' % arch])

      with bot.BuildStep('Create build tarball'):
        run(['tar', '-cjf', tarball, '--exclude=**/obj',
             '--exclude=**/obj.host', '--exclude=**/obj.target',
             '--exclude=**/*analyzer*', 'out/'])

      with bot.BuildStep('Upload build tarball'):
        uri = "%s/%s" % (GCS_BUCKET, tarball)
        run([GSUTIL, 'cp', tarball, uri])
        run([GSUTIL, 'setacl', 'public-read', uri])

    elif num_run == 2:
      with bot.BuildStep('tests'):
        print "Please see the target device for results."
        print "We no longer record/replay tests."
    else:
      raise Exception("Invalid annotated steps run")
  finally:
    for path in temporary_files:
      if os.path.exists(path):
        os.remove(path)

def target_builder(arch, mode):
  test_py = os.path.join('tools', 'test.py')
  test_args = [sys.executable, test_py, '--progress=line', '--report',
               '--time', '--compiler=none', '--runtime=vm', '--write-debug-log',
               '--write-test-outcome-log', '--mode=' + mode, '--arch=' + arch,
               '--exclude-suite=pkg']

  revision = int(os.environ['BUILDBOT_GOT_REVISION'])
  tarball = tarball_name(arch, mode, revision)
  temporary_files = [tarball]
  bot.Clobber()
  try:
    with bot.BuildStep('Fetch build tarball'):
      run([GSUTIL, 'cp', "%s/%s" % (GCS_BUCKET, tarball), tarball])

    with bot.BuildStep('Unpack build tarball'):
      run(['tar', '-xjf', tarball])

    with bot.BuildStep('execute tests'):
      run(test_args)

    with bot.BuildStep('execute checked_tests'):
      run(test_args + ['--checked', '--append_logs'])
  finally:
    for path in temporary_files:
      if os.path.exists(path):
        os.remove(path)
    # We always clobber this to save disk on the arm board.
    bot.Clobber(force=True)

def main():
  name, is_buildbot = bot.GetBotName()

  cross_vm_pattern_match = re.match(CROSS_VM, name)
  target_vm_pattern_match = re.match(TARGET_VM, name)
  if cross_vm_pattern_match:
    arch = cross_vm_pattern_match.group(1)
    mode = cross_vm_pattern_match.group(2)
    cross_compiling_builder(arch, mode)
  elif target_vm_pattern_match:
    arch = target_vm_pattern_match.group(1)
    mode = target_vm_pattern_match.group(2)
    target_builder(arch, mode)
  else:
    raise Exception("Unknown builder name %s" % name)

if __name__ == '__main__':
  try:
    sys.exit(main())
  except OSError as e:
    sys.exit(e.errno)
