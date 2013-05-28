#!/usr/bin/python
# Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import os
import re
import shutil
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

def tarball_name(arch, mode):
  return 'cross_build_%s_%s.tar.bz2' % (arch, mode)

def record_names(name, arch, mode):
  return ('record_%s_%s_%s.json' % (name, arch, mode),
          'record_output_%s_%s_%s.json' % (name, arch, mode))

def cross_compiling_builder(arch, mode):
  build_py = os.path.join('tools', 'build.py')
  test_py = os.path.join('tools', 'test.py')
  test_args = [sys.executable, test_py, '--progress=line', '--report',
               '--time', '--compiler=none', '--runtime=vm', '--write-debug-log']

  tarball = tarball_name(arch, mode)
  (recording, recording_out) = record_names('tests', arch, mode)
  (checked_recording, checked_recording_out) = record_names(
      'checked_tests', arch, mode)

  temporary_files = [tarball, recording, recording_out, checked_recording,
                     checked_recording_out]
  bot.Clobber()
  try:
    num_run = int(os.environ['BUILDBOT_ANNOTATED_STEPS_RUN'])
    if num_run == 1:
      # FIXME(kustermann/ricow): Remove this hack as soon as our bots are
      # running on precise (i.e. then we can install the normal crosscompiler)
      os.environ['TARGET_TOOLCHAIN_PREFIX'] = ('/home/chrome-bot/codesourcery'
                                               '/bin/arm-none-linux-gnueabi')
      with bot.BuildStep('Build %s %s' % (arch, mode)):
        args = [sys.executable, build_py,
                '-m%s' % mode, '--arch=%s' % arch, 'runtime']

        run(args)
      with bot.BuildStep('Create build tarball'):
        run(['tar', '-cjf', tarball, '--exclude=**/obj',
             '--exclude=**/obj.host', '--exclude=**/obj.target',
             '--exclude=**/*analyzer*', '--exclude=**/*IA32', 'out/'])

      with bot.BuildStep('Upload build tarball'):
        uri = "%s/%s" % (GCS_BUCKET, tarball)
        run([GSUTIL, 'cp', tarball, uri])
        run([GSUTIL, 'setacl', 'public-read', uri])

      with bot.BuildStep('prepare tests'):
        uri = "%s/%s" % (GCS_BUCKET, recording)
        run(test_args + ['--mode=' + mode, '--arch=' + arch,
                         '--record_to_file=' + recording])
        run([GSUTIL, 'cp', recording, uri])
        run([GSUTIL, 'setacl', 'public-read', uri])

      with bot.BuildStep('prepare checked_tests'):
        uri = "%s/%s" % (GCS_BUCKET, checked_recording)
        run(test_args + ['--mode=' + mode, '--arch=' + arch, '--checked',
                         '--record_to_file=' + checked_recording])
        run([GSUTIL, 'cp', checked_recording, uri])
        run([GSUTIL, 'setacl', 'public-read', uri])
    elif num_run == 2:
      with bot.BuildStep('tests'):
        uri = "%s/%s" % (GCS_BUCKET, recording)
        run([GSUTIL, 'cp', uri, recording])
        run(test_args + ['--mode=' + mode, '--arch=' + arch,
                         '--replay_from_file=' + recording_out])

      with bot.BuildStep('checked_tests'):
        uri = "%s/%s" % (GCS_BUCKET, checked_recording)
        run([GSUTIL, 'cp', uri, checked_recording])
        run(test_args + ['--mode=' + mode, '--arch=' + arch, '--checked',
                         '--replay_from_file=' + checked_recording_out])
    else:
      raise Exception("Invalid annotated steps run")
  finally:
    for path in temporary_files:
      if os.path.exists(path):
        os.remove(path)

def target_builder(arch, mode):
  execute_testcases_py = os.path.join('tools', 'execute_recorded_testcases.py')

  tarball = tarball_name(arch, mode)
  (recording, recording_out) = record_names('tests', arch, mode)
  (checked_recording, checked_recording_out) = record_names(
      'checked_tests', arch, mode)

  temporary_files = [tarball, recording, recording_out, checked_recording,
                     checked_recording_out]
  bot.Clobber()
  try:
    with bot.BuildStep('Fetch build tarball'):
      run([GSUTIL, 'cp', "%s/%s" % (GCS_BUCKET, tarball), tarball])

    with bot.BuildStep('Unpack build tarball'):
      run(['tar', '-xjf', tarball])

    with bot.BuildStep('execute tests'):
      uri = "%s/%s" % (GCS_BUCKET, recording)
      uri_out = "%s/%s" % (GCS_BUCKET, recording_out)
      run([GSUTIL, 'cp', uri, recording])
      run(['python', execute_testcases_py, recording, recording_out])
      run([GSUTIL, 'cp', recording_out, uri_out])
      run([GSUTIL, 'setacl', 'public-read', uri_out])

    with bot.BuildStep('execute checked_tests'):
      uri = "%s/%s" % (GCS_BUCKET, checked_recording)
      uri_out = "%s/%s" % (GCS_BUCKET, checked_recording_out)
      run([GSUTIL, 'cp', uri, checked_recording])
      run(['python', execute_testcases_py, checked_recording,
           checked_recording_out])
      run([GSUTIL, 'cp', recording_out, uri_out])
      run([GSUTIL, 'setacl', 'public-read', uri_out])
  finally:
    for path in temporary_files:
      if os.path.exists(path):
        os.remove(path)

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
  sys.exit(main())
