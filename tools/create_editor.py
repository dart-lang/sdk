#!/usr/bin/env python
#
# Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#
# A script which will be invoked from gyp to create a build of the editor.
# 
# TODO(devoncarew): currently this script is not callable from tools/build.py
# Usage: ./tools/build.py editor
#  -or-
# Usage: ./tools/build_editor.py [--mode <mode>] [--arch <arch>] output

import glob
import optparse
import os
import shutil
import subprocess
import sys
import utils
import zipfile

from os.path import join

OUTPUT = None

OS_CONFIG = {
  'win32': 'win32, win32',
  'linux': 'linux, gtk',
  'macos': 'macosx, cocoa'
}

ARCH_CONFIG = {
  'ia32': 'x86',
  'x64': 'x86_64'
}

def AntPath():
  parent = join('third_party', 'apache_ant', '1.8.4', 'bin')
  if utils.IsWindows():
    return join(parent, 'ant.bat')
  else:
    return join(parent, 'ant')


def ProcessEditorArchive(archive, outDir):
  tempDir = join(GetEditorTemp(), 'editor.out')
  os.makedirs(tempDir)

  if utils.IsWindows():
    f = zipfile.ZipFile(archive)
    f.extractall(tempDir)
  else:
    subprocess.call(['unzip', '-q', archive, '-d', tempDir])

  for src in glob.glob(join(tempDir, 'dart', '*')):
    shutil.move(src, outDir)

  shutil.rmtree(tempDir)
  os.unlink(archive)


def GetEditorTemp():
  return join(GetBuildRoot(), 'editor.build.temp')


def GetDownloadCache():
  return GetEclipseBuildRoot()


def GetBuildRoot():
  return os.path.abspath(utils.GetBuildRoot(utils.GuessOS()))


def GetEclipseBuildRoot():
  return join(GetBuildRoot(), 'editor.build.cache')


def GetSdkPath():
  return join(os.path.dirname(OUTPUT), 'dart-sdk')


def GetOutputParent():
  return os.path.dirname(os.path.dirname(OUTPUT))


def BuildOptions():
  options = optparse.OptionParser(usage='usage: %prog [options] <output>')
  options.add_option("-m", "--mode",
      help='Build variant',
      metavar='[debug,release]')
  options.add_option("-a", "--arch",
      help='Target architecture',
      metavar='[ia32,x64]')
  return options

  
def Main():
  global OUTPUT
  
  parser = BuildOptions()
  (options, args) = parser.parse_args()
  
  if len(args) > 1:
    parser.print_help()
    return 1
  
  osName = utils.GuessOS()
  mode = 'debug'
  arch = utils.GuessArchitecture()
  
  if args:
    # TODO(devoncarew): Currently we scrape the output path to determine the
    # mode and arch. This is fragile and should moved into one location
    # (utils.py?) or made more explicit.
    OUTPUT = args[0]
    
    mode = ('release', 'debug')['Debug' in OUTPUT]
    arch = ('ia32', 'x64')['X64' in OUTPUT]

  # Use explicit mode and arch information.
  if options.mode:
    mode = options.mode
  if options.arch:
    arch = options.arch

  # If an output dir was not given, create one from os, mode, and arch.
  if not OUTPUT:
    OUTPUT = join(utils.GetBuildRoot(osName, mode, arch), 'editor')
  
  OUTPUT = os.path.abspath(OUTPUT)
  
  print "\nBuilding the editor"
  print "  config : %s, %s, %s" % (osName, arch, mode)
  print "  output : %s" % OUTPUT

  # Clean the editor output directory.
  print '  cleaning %s' % OUTPUT
  shutil.rmtree(OUTPUT, True)

  # These are the valid eclipse build configurations that we can produce.
  # We synthesize these up from the OS_CONFIG and ARCH_CONFIG information.
  # macosx, cocoa, x86 & macosx, cocoa, x86_64
  # win32, win32, x86 & win32, win32, x86_64
  # linux, gtk, x86 & linux, gtk, x86_64

  buildConfig = OS_CONFIG[osName] + ', ' + ARCH_CONFIG[arch]

  print "\ninvoking build_rcp.xml with buildConfig = [%s]\n" % buildConfig

  sys.stdout.flush()
  sys.stderr.flush()

  buildScript = join('editor', 'tools', 'features', 
                     'com.google.dart.tools.deploy.feature_releng', 
                     'build_rcp.xml')

  buildRcpStatus = subprocess.call(
      [AntPath(), 
      '-lib',
      join('third_party', 'bzip2', 'bzip2.jar'),
      '-Dbuild.out=' + OUTPUT,
      '-Dbuild.configs=' + buildConfig,
      '-Dbuild.revision=' + utils.GetSVNRevision(),
      '-Ddart.version.full=' + utils.GetVersion(),
      '-Dbuild.root=' + GetEclipseBuildRoot(),
      '-Dbuild.downloads=' + GetDownloadCache(),
      '-Dbuild.source=' + os.path.abspath('editor'),
      '-Dbuild.dart.sdk=' + GetSdkPath(),
      '-Dbuild.no.properties=true',
      '-buildfile',
      buildScript],
    shell=utils.IsWindows())

  if buildRcpStatus != 0:
    sys.exit(buildRcpStatus)

  # build_rcp.xml will put the built editor archive in the OUTPUT directory
  # (dart-editor-macosx.cocoa.x86.zip). It contains the editor application in a
  # dart/ subdirectory. We unzip the contents of the archive into OUTPUT. It
  # will use the ../dart-sdk directory as its SDK.
  archives = glob.glob(join(OUTPUT, '*.zip'))
  
  if archives:
    ProcessEditorArchive(archives[0], OUTPUT)

  if os.path.exists(GetEditorTemp()):
    shutil.rmtree(GetEditorTemp())

  print('\nEditor build successful')


if __name__ == '__main__':
  sys.exit(Main())
