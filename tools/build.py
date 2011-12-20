#!/usr/bin/env python
#
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#

import optparse
import os
import shutil
import subprocess
import sys
import utils

HOST_OS = utils.GuessOS()
HOST_CPUS = utils.GuessCpus()
armcompilerlocation = '/opt/codesourcery/arm-2009q1'

def BuildOptions():
  result = optparse.OptionParser()
  result.add_option("-m", "--mode",
      help='Build variants (comma-separated).',
      metavar='[all,debug,release]',
      default='debug')
  result.add_option("-v", "--verbose",
      help='Verbose output.',
      default=False, action="store_true")
  result.add_option("--arch",
      help='Target architectures (comma-separated).',
      metavar='[all,ia32,x64,simarm,arm]',
      default=utils.GuessArchitecture())
  result.add_option("-j",
      help='The number of parallel jobs to run.',
      metavar=HOST_CPUS,
      default=str(HOST_CPUS))
  result.add_option("--devenv",
      help='Path containing devenv.com on Windows',
      default='C:\\Program Files (x86)\\Microsoft Visual Studio 9.0\\Common7\\IDE')
  return result


def ProcessOptions(options):
  if options.arch == 'all':
    options.arch = 'ia32,x64,simarm'
  if options.mode == 'all':
    options.mode = 'release,debug'
  options.mode = options.mode.split(',')
  options.arch = options.arch.split(',')
  for mode in options.mode:
    if not mode in ['debug', 'release']:
      print "Unknown mode %s" % mode
      return False
  for arch in options.arch:
    if not arch in ['ia32', 'x64', 'simarm', 'arm']:
      print "Unknown arch %s" % arch
      return False
  return True


def setTools(arch):
  if arch == 'arm':
    toolsOverride = {
      "CC"  :  armcompilerlocation + "/bin/arm-none-linux-gnueabi-gcc",
      "CXX" :  armcompilerlocation + "/bin/arm-none-linux-gnueabi-g++",
      "AR"  :  armcompilerlocation + "/bin/arm-none-linux-gnueabi-ar",
      "LINK":  armcompilerlocation + "/bin/arm-none-linux-gnueabi-g++",
      "NM"  :  armcompilerlocation + "/bin/arm-none-linux-gnueabi-nm",
    }
    return toolsOverride


def Execute(args):
  print "#" + ' '.join(args)
  process = subprocess.Popen(args)
  process.wait()
  if process.returncode != 0:
    raise Error(args[0] + " failed")


def CurrentDirectoryBaseName():
  """Returns the name of the current directory"""
  return os.path.relpath(os.curdir, start=os.pardir)

def Main():
  utils.ConfigureJava()
  # Parse the options.
  parser = BuildOptions()
  (options, args) = parser.parse_args()
  if not ProcessOptions(options):
    parser.print_help()
    return 1
  # Determine which targets to build. By default we build the "all" target.
  if len(args) == 0:
    if HOST_OS == 'macos':
      target = 'All'
    else:
      target = 'all'
  else:
    target = args[0]
  # Build the targets for each requested configuration.
  for mode in options.mode:
    for arch in options.arch:
      build_config = utils.GetBuildConf(mode, arch)
      if HOST_OS == 'macos':
        project_file = 'dart.xcodeproj'
        if os.path.exists('dart-%s.gyp' % CurrentDirectoryBaseName()):
          project_file = 'dart-%s.xcodeproj' % CurrentDirectoryBaseName()
        args = ['xcodebuild',
                '-project',
                project_file,
                '-target',
                target,
                '-parallelizeTargets',
                '-configuration',
                build_config,
                'SYMROOT=%s' % os.path.abspath('xcodebuild')
                ]
      elif HOST_OS == 'win32':
        project_file = 'dart.sln'
        if os.path.exists('dart-%s.gyp' % CurrentDirectoryBaseName()):
          project_file = 'dart-%s.sln' % CurrentDirectoryBaseName()
        args = [options.devenv + os.sep + 'devenv.com',
                '/build',
                build_config,
                project_file
               ]
      else:
        make = 'make'
        if HOST_OS == 'freebsd':
          make = 'gmake'
          # work around lack of flock
          os.environ['LINK'] = '$(CXX)'
        args = [make,
                '-j',
                options.j,
                'BUILDTYPE=' + build_config,
                ]
        if options.verbose:
          args += ['V=1']

        args += [target]

      toolsOverride = setTools(arch)
      if toolsOverride:
        for k, v in toolsOverride.iteritems():
          args.append(  k + "=" + v)
          print k + " = " + v

      print ' '.join(args)
      process = subprocess.Popen(args)
      process.wait()
      if process.returncode != 0:
        print "BUILD FAILED"
        return 1

  return 0


if __name__ == '__main__':
  sys.exit(Main())
