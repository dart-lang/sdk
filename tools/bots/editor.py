#!/usr/bin/python
# Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import os
import re
import sys

import bot

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.append(os.path.join(SCRIPT_DIR, '..'))
import utils


GSUTIL = utils.GetBuildbotGSUtilPath()
GCS_DARTIUM_BUCKET = "gs://dartium-archive/continuous"
GCS_EDITOR_BUCKET = "gs://continuous-editor-archive"

def GetBuildDirectory(mode, arch):
  configuration_dir = mode + arch.upper()
  build_directory_dict = {
    'linux2' : os.path.join('out', configuration_dir),
    'darwin' : os.path.join('xcodebuild', configuration_dir),
    'win32' : os.path.join('build', configuration_dir),
  }
  if sys.platform == 'darwin':
    # TODO(kustermann,ricow): Maybe we're able to get rid of this in the future.
    # We use ninja on bots which use out/ (i.e. what linux2 does) instead of
    # xcodebuild/
    if (os.path.exists(build_directory_dict['linux2']) and
        os.path.isdir(build_directory_dict['linux2'])):
      return build_directory_dict['linux2']
  return build_directory_dict[sys.platform]

def GetEditorDirectory(mode, arch):
  return os.path.join(GetBuildDirectory(mode, arch), 'editor')

def GetDartSdkDirectory(mode, arch):
  return os.path.join(GetBuildDirectory(mode, arch), 'dart-sdk')

def GetEditorExecutable(mode, arch):
  editor_dir = GetEditorDirectory(mode, arch)
  if sys.platform == 'darwin':
    executable = os.path.join('DartEditor.app', 'Contents', 'MacOS',
                              'DartEditor')
  elif sys.platform == 'win32':
    executable = 'DartEditor.exe'
  elif sys.platform == 'linux2':
    executable = 'DartEditor'
  else:
    raise Exception('Unknown platform %s' % sys.platform)
  return os.path.join(editor_dir, executable)

def RunProcess(args):
  if sys.platform == 'linux2':
    args = ['xvfb-run', '-a'] + args
  print 'Running: %s' % (' '.join(args))
  sys.stdout.flush()
  bot.RunProcess(args)

def DownloadDartium(temp_dir, zip_file):
  """Returns the filename of the unpacked archive"""
  local_path = os.path.join(temp_dir, zip_file)
  uri = "%s/%s" % (GCS_DARTIUM_BUCKET, zip_file)
  RunProcess([GSUTIL, 'cp', uri, local_path])
  RunProcess(['unzip', local_path, '-d', temp_dir])
  for filename in os.listdir(temp_dir):
    match = re.search('^dartium-.*-inc-([0-9]+)\.0$', filename)
    if match:
      return os.path.join(temp_dir, match.group(0))
  raise Exception("Couldn't find dartium archive")

def UploadInstaller(dart_editor_dmg, directory):
  directory = directory % {'revision' : utils.GetSVNRevision()}
  uri = '%s/%s' % (GCS_EDITOR_BUCKET, directory)
  RunProcess([GSUTIL, 'cp', dart_editor_dmg, uri])
  RunProcess([GSUTIL, 'setacl', 'public-read', uri])

def CreateAndUploadMacInstaller(arch):
  dart_icns = os.path.join(
    'editor', 'tools', 'plugins', 'com.google.dart.tools.deploy',
    'icons', 'dart.icns')
  mac_build_bundle_py = os.path.join('tools', 'mac_build_editor_bundle.sh')
  mac_build_dmg_py = os.path.join('tools', 'mac_build_editor_dmg.sh')
  editor_dir = GetEditorDirectory('Release', arch)
  dart_sdk = GetDartSdkDirectory('Release', arch)
  with utils.TempDir('eclipse') as temp_dir:
    # Get dartium
    dartium_directory = DownloadDartium(temp_dir, 'dartium-mac.zip')
    dartium_bundle_dir = os.path.join(dartium_directory,
                                      'Chromium.app')

    # Build the editor bundle
    darteditor_bundle_dir = os.path.join(temp_dir, 'DartEditor.app')
    args = [mac_build_bundle_py, darteditor_bundle_dir, editor_dir,
           dart_sdk, dartium_bundle_dir, dart_icns]
    RunProcess(args)

    # Build the dmg installer from the editor bundle
    dart_editor_dmg = os.path.join(temp_dir, 'DartEditor.dmg')
    args = [mac_build_dmg_py, dart_editor_dmg, darteditor_bundle_dir,
            dart_icns, 'Dart Editor']
    RunProcess(args)

    # Upload the dmg installer
    UploadInstaller(dart_editor_dmg, 'dart-editor-mac-%(revision)s.dmg')

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
              '-mrelease', '--arch=%s' % arch, 'editor', 'create_sdk']
      RunProcess(args)

  for arch in test_architectures:
    editor_executable = GetEditorExecutable('Release', arch)
    with bot.BuildStep('Test Editor %s' % arch):
      with utils.TempDir('eclipse') as temp_dir:
        args = [editor_executable, '-consoleLog', '--test', '--auto-exit',
                '-data', temp_dir]
        RunProcess(args)

  # TODO: Permissions need to be clarified
  for arch in test_architectures:
    with bot.BuildStep('Build Installer %s' % arch):
      if sys.platform == 'darwin':
        CreateAndUploadMacInstaller(arch)
      else:
        print ("We currently don't build installers for sys.platform=%s"
                % sys.platform)
  return 0

if __name__ == '__main__':
  try:
    sys.exit(main())
  except OSError as e:
    sys.exit(e.errno)
