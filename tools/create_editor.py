#!/usr/bin/env python
#
# Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#
# A script which will be invoked from gyp to create a build of the editor.
#
# Usage: ./tools/create_editor.py
#            [--mode <mode>] [--arch <arch>] [--out <output>] [--build <build>]
#
# DO NOT CALL THIS SCRIPT DIRECTLY, instead invoke:
# ./tools/build.py -mrelease editor

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
BUILD = None

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


def ProcessEditorArchive(arch, archive, outDir):
  tempDir = join(GetEditorTemp(), 'editor.out')
  try:
    os.makedirs(tempDir)
  except OSError:
    # Directory already exists.
    pass

  if utils.IsWindows():
    f = zipfile.ZipFile(archive)
    f.extractall(tempDir)
    f.close()
  else:
    subprocess.call(['unzip', '-q', archive, '-d', tempDir])

  if arch == 'x64':
    if utils.GuessOS() == 'macos':
      inifile = join(tempDir, 'dart', 'DartEditor.app', 'Contents', 'MacOS',
                     'DartEditor.ini')
    else:
      inifile = join(tempDir, 'dart', 'DartEditor.ini')
    Modify64BitDartEditorIni(inifile)

  for src in glob.glob(join(tempDir, 'dart', '*')):
    shutil.move(src, outDir)

  shutil.rmtree(tempDir)
  os.unlink(archive)


def Modify64BitDartEditorIni(iniFilePath):
  f = open(iniFilePath, 'r')
  lines = f.readlines()
  f.close()
  lines[lines.index('-Xms40m\n')] = '-Xms256m\n'
  lines[lines.index('-Xmx1024m\n')] = '-Xmx2000m\n'
  # Add -d64 to give better error messages to user in 64 bit mode.
  lines[lines.index('-vmargs\n')] = '-vmargs\n-d64\n'
  f = open(iniFilePath, 'w')
  f.writelines(lines)
  f.close()


def GetEditorTemp():
  return join(BUILD, 'editor.build.temp')


def GetDownloadCache():
  return GetEclipseBuildRoot()


def GetEclipseBuildRoot():
  return join(BUILD, 'editor.build.cache')


def GetSdkPath():
  return join(os.path.dirname(OUTPUT), 'dart-sdk')


def GetOutputParent():
  return os.path.dirname(os.path.dirname(OUTPUT))


def BuildOptions():
  options = optparse.OptionParser(usage='usage: %prog [options] <output>')
  options.add_option("-m", "--mode", metavar='[debug,release]')
  options.add_option("-a", "--arch", metavar='[ia32,x64]')
  options.add_option("-o", "--out")
  options.add_option("-b", "--build")
  return options


def Main():
  global OUTPUT
  global BUILD

  parser = BuildOptions()
  (options, args) = parser.parse_args()

  if args:
    parser.print_help()
    return 1

  osName = utils.GuessOS()
  mode = 'debug'
  arch = utils.GuessArchitecture()

  if not options.build:
    print >> sys.stderr, 'Error: no --build option specified'
    exit(1)
  else:
    BUILD = options.build

  if not options.out:
    print >> sys.stderr, 'Error: no --out option specified'
    exit(1)
  else:
    # TODO(devoncarew): Currently we scrape the output path to determine the
    # mode and arch. This is fragile and should moved into one location
    # (utils.py?) or made more explicit.
    OUTPUT = options.out
    mode = ('release', 'debug')['Debug' in OUTPUT]
    arch = ('ia32', 'x64')['X64' in OUTPUT]

  # Use explicit mode and arch information.
  if options.mode:
    mode = options.mode
  if options.arch:
    arch = options.arch

  OUTPUT = os.path.abspath(OUTPUT)
  BUILD = os.path.abspath(BUILD)

  print "\nBuilding the editor"
  print "  config : %s, %s, %s" % (osName, arch, mode)
  print "  output : %s" % OUTPUT

  # Clean the editor output directory.
  print '\ncleaning %s' % OUTPUT
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
  build_cmd = [AntPath(),
      '-lib',
      join('third_party', 'bzip2', 'bzip2.jar'),
      '-Dbuild.out=' + OUTPUT,
      '-Dbuild.configs=' + buildConfig,
      '-Dbuild.root=' + GetEclipseBuildRoot(),
      '-Dbuild.downloads=' + GetDownloadCache(),
      '-Dbuild.source=' + os.path.abspath('editor'),
      '-Dbuild.dart.sdk=' + GetSdkPath(),
      '-Dbuild.no.properties=true',
      '-Dbuild.channel=' + utils.GetChannel(),
      '-Dbuild.revision=' + utils.GetSVNRevision(),
      '-Dbuild.version.qualifier=' + utils.GetEclipseVersionQualifier(),
      '-Ddart.version.full=' + utils.GetVersion(),
      '-buildfile',
      buildScript]
  print build_cmd
  buildRcpStatus = subprocess.call(build_cmd, shell=utils.IsWindows())

  if buildRcpStatus != 0:
    sys.exit(buildRcpStatus)

  # build_rcp.xml will put the built editor archive in the OUTPUT directory
  # (dart-editor-macosx.cocoa.x86.zip). It contains the editor application in a
  # dart/ subdirectory. We unzip the contents of the archive into OUTPUT. It
  # will use the ../dart-sdk directory as its SDK.
  archives = glob.glob(join(OUTPUT, 'd*.zip'))

  if archives:
    ProcessEditorArchive(arch, archives[0], OUTPUT)

  if os.path.exists(GetEditorTemp()):
    shutil.rmtree(GetEditorTemp())

  print('\nEditor build successful')


if __name__ == '__main__':
  sys.exit(Main())
