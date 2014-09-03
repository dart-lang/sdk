#!/usr/bin/python

# Copyright (c) 2011 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import glob
import optparse
import os
import shutil
import sys
import utils

HOST_OS = utils.guessOS()

if HOST_OS == 'mac':
  CONTENTSHELL_FILES = ['Content Shell.app', 'ffmpegsumo.so', 'osmesa.so',
                        'lib']
  CHROMEDRIVER_FILES = ['chromedriver']
elif HOST_OS == 'linux':
  CONTENTSHELL_FILES = ['content_shell', 'content_shell.pak', 'fonts.conf',
                        'libffmpegsumo.so', 'libosmesa.so', 'lib',
                        'icudtl.dat']
  CHROMEDRIVER_FILES = ['chromedriver']
elif HOST_OS == 'win':
  # TODO: provide proper list.
  CONTENTSHELL_FILES = ['content_shell.exe', 'AHEM____.ttf']
  CHROMEDRIVER_FILES = ['chromedriver.exe']
else:
  raise Exception('Unsupported platform')

# Append a file with size of the snapshot.
CONTENTSHELL_FILES.append('snapshot-size.txt')


def GenerateDartiumFileList(mode, srcpath):
  def blacklisted(name):
    # We include everything if this is a debug build.
    if mode.lower() == 'debug':
      return True
    else:
      # We don't include .debug/.pdb files if this is a release build.
      if name.endswith('.debug') or name.endswith('.pdb'):
        return False
      return True

  configFile = os.path.join(srcpath, 'chrome', 'tools', 'build', HOST_OS,
                            'FILES.cfg')
  configNamespace = {}
  execfile(configFile, configNamespace)
  fileList = [file['filename'] for file in configNamespace['FILES']]

  # The debug version of dartium on our bots build with
  # 'component=shared_library', so we need to include all libraries
  # (i.e. 'lib/*.so) as we do on the CONTENTSHELL_FILES list above.
  if HOST_OS == 'linux' and mode.lower() == 'debug':
    fileList.append('lib')

  # Filter out files we've blacklisted and don't want to include.
  fileList = filter(blacklisted, fileList)
  return fileList


def GenerateContentShellFileList(srcpath):
  return CONTENTSHELL_FILES


def GenerateChromeDriverFileList(srcpath):
  return CHROMEDRIVER_FILES


def ZipDir(zipFile, directory):
  if HOST_OS == 'win':
    cmd = os.path.normpath(os.path.join(
        os.path.dirname(__file__),
        '../../../third_party/lzma_sdk/Executable/7za.exe'))
    options = ['a', '-r', '-tzip']
  else:
    cmd = 'zip'
    options = ['-yr']
  utils.runCommand([cmd] + options + [zipFile, directory])


def GenerateZipFile(zipFile, stageDir, fileList):
  # Stage files.
  for fileName in fileList:
    fileName = fileName.rstrip(os.linesep)
    targetName = os.path.join(stageDir, fileName)
    try:
      targetDir = os.path.dirname(targetName)
      if not os.path.exists(targetDir):
        os.makedirs(targetDir)
      if os.path.isdir(fileName):
        # TODO: This is a hack to handle duplicates on the fileList of the
        # form: [ 'lib/foo.so', 'lib' ]
        if os.path.exists(targetName) and os.path.isdir(targetName):
          shutil.rmtree(targetName)
        shutil.copytree(fileName, targetName)
      elif os.path.exists(fileName):
        shutil.copy2(fileName, targetName)
    except:
      import traceback
      print 'Troubles processing %s [cwd=%s]: %s' % (fileName, os.getcwd(), traceback.format_exc())

  ZipDir(zipFile, stageDir)


def StageAndZip(fileList, target):
  if not target:
    return None

  stageDir = target
  zipFile = stageDir + '.zip'

  # Cleanup old files.
  if os.path.exists(stageDir):
    shutil.rmtree(stageDir)
  os.mkdir(stageDir)
  revision = target.split('-')[-1]
  oldFiles = glob.glob(target.replace(revision, '*.zip'))
  for oldFile in oldFiles:
    os.remove(oldFile)

  GenerateZipFile(zipFile, stageDir, fileList)
  print 'last change: %s' % (zipFile)

  # Clean up. Buildbot disk space is limited.
  shutil.rmtree(stageDir)

  return zipFile


def Archive(srcpath, mode, dartium_target, contentshell_target,
            chromedriver_target, is_win_ninja=False):
  # We currently build using ninja on mac debug.
  if HOST_OS == 'mac':
    releaseDir = os.path.join(srcpath, 'out', mode)
    # Also package dynamic libraries.
    extra_files = [file for file in os.listdir(releaseDir) if file.endswith('.dylib')]
  elif HOST_OS == 'linux':
    releaseDir = os.path.join(srcpath, 'out', mode)
    extra_files = []
  elif HOST_OS == 'win':
    if is_win_ninja:
      releaseDir = os.path.join(srcpath, 'out', mode)
    else:
      releaseDir = os.path.join(srcpath, 'out', mode)
    # issue(16760) - we _need_ to fix our parsing of the FILES.cfg
    extra_files = [file for file in os.listdir(releaseDir) if file.endswith('manifest')]
  else:
    raise Exception('Unsupported platform')
  os.chdir(releaseDir)

  dartium_zip = StageAndZip(
      GenerateDartiumFileList(mode, srcpath) + extra_files, dartium_target)
  contentshell_zip = StageAndZip(GenerateContentShellFileList(srcpath) + extra_files,
                                 contentshell_target)
  chromedriver_zip = StageAndZip(GenerateChromeDriverFileList(srcpath) + extra_files,
                                 chromedriver_target)
  return (dartium_zip, contentshell_zip, chromedriver_zip)


def main():
  pathname = os.path.dirname(sys.argv[0])
  fullpath = os.path.abspath(pathname)
  srcpath = os.path.join(fullpath, '..', '..', '..')

  parser = optparse.OptionParser()
  parser.add_option('--dartium', dest='dartium',
                    action='store', type='string',
                    help='dartium archive name')
  parser.add_option('--contentshell', dest='contentshell',
                    action='store', type='string',
                    help='content shell archive name')
  parser.add_option('--chromedriver', dest='chromedriver',
                    action='store', type='string',
                    help='chromedriver archive name')
  parser.add_option('--mode', dest='mode',
                    default='Release',
                    action='store', type='string',
                    help='(Release|Debug)')
  (options, args) = parser.parse_args()
  Archive(srcpath, options.mode, options.dartium, options.contentshell,
          options.chromedriver)
  return 0


if __name__ == '__main__':
  sys.exit(main())
