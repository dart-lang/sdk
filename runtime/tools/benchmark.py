#!/usr/bin/env python
#
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Simple wrapper for running benchmarks.

import getopt
import optparse
import os
from os.path import join, dirname, realpath, abspath
import subprocess
import sys
import utils
import re


HOST_OS = utils.GuessOS()
HOST_CPUS = utils.GuessCpus()

# Returns whether 'bench' matches any element in the 'filt' list.
def match(bench, filt):
  bench = bench.lower();
  for element in filt:
    if element.search(bench):
      return True
  return False

def GetBenchmarkFile(path):
  benchmark_root_path = [dirname(sys.argv[0]), '..', '..'] + ['benchmarks']
  return realpath(os.path.sep.join(benchmark_root_path + path))

def ReadBenchmarkList(mode, path, core):
  filename = GetBenchmarkFile([path])
  benchmarks = dict()
  execfile(filename, benchmarks)
  if (mode == "release") and not core:
    return benchmarks['SUPPORTED_BENCHMARKS']
  else:
    return benchmarks['SUPPORTED_CORE_BENCHMARKS']

def BuildOptions():
  result = optparse.OptionParser()
  result.add_option("-m", "--mode",
      help='Build variants (comma-separated).',
      metavar='[all,debug,release]',
      default='release')
  result.add_option("-v", "--verbose",
      help='Verbose output.',
      default=False, action="store_true")
  result.add_option("-c", "--core",
      help='Run only core benchmarks.',
      default=False, action="store_true")
  result.add_option("--arch",
      help='Target architectures (comma-separated).',
      metavar='[all,ia32,x64,simarm,arm,dartc]',
      default=utils.GuessArchitecture())
  result.add_option("--executable",
      help='Virtual machine to execute.',
      metavar='[dart, (path to dart binary)]',
      default=None)
  result.add_option("-w", "--warmup",
      help='Only run the warmup period.',
      default=False, action="store_true")
  return result


def ProcessOptions(options):
  if options.arch == 'all':
    options.arch = 'ia32,x64,simarm,dartc'
  if options.mode == 'all':
    options.mode = 'debug,release'
  options.mode = options.mode.split(',')
  options.arch = options.arch.split(',')
  for mode in options.mode:
    if not mode in ['debug', 'release']:
      print "Unknown mode %s" % mode
      return False
  for arch in options.arch:
    if not arch in ['ia32', 'x64', 'simarm', 'arm', 'dartc']:
      print "Unknown arch %s" % arch
      return False
  return True


def GetBuildRoot(mode, arch):
  return utils.GetBuildRoot(HOST_OS, mode, arch)

def GetDart(mode, arch):
  executable = [abspath(join(GetBuildRoot(mode, arch), 'dart'))]
  return executable

def Main():
  # Parse the options.
  parser = BuildOptions()
  (options, args) = parser.parse_args()
  if not ProcessOptions(options):
    parser.print_help()
    return 1

  chosen_benchmarks = ReadBenchmarkList(options.mode,
      'BENCHMARKS',
      options.core)

  # Use arguments to filter the benchmarks.
  if len(args) > 0:
    filt = [re.compile(x.lower()) for x in args]
    chosen_benchmarks = [b for b in chosen_benchmarks if match(b[0], filt)]

  for mode in options.mode:
    for arch in options.arch:
      if options.executable is None:
        # Construct the path to the dart binary.
        executable = GetDart(mode, arch)
      else:
        executable = [options.executable]
      for benchmark, vmargs, progargs in chosen_benchmarks:
        command = executable
        command = command + [
                     GetBenchmarkFile([benchmark, 'dart', benchmark + '.dart']),
                  ]
        if options.verbose:
          print ' '.join(command)
        subprocess.call(command)
  return 0


if __name__ == '__main__':
  sys.exit(Main())
