#!/usr/bin/env python
#
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""Script to create snapshot bin file."""

import getopt
import optparse
import os
from os.path import abspath, basename, dirname, join
import string
import subprocess
import sys
import tempfile
import utils


HOST_OS = utils.GuessOS()
HOST_CPUS = utils.GuessCpus()


def BuildOptions():
  result = optparse.OptionParser()
  result.add_option("--executable",
      action="store", type="string",
      help="path to snapshot generator executable")
  result.add_option("--output_bin",
      action="store", type="string",
      help="output file name into which snapshot in binary form is generated")
  result.add_option("--script",
      action="store", type="string",
      help="Dart script for which snapshot is to be generated")
  result.add_option("--url_mapping",
      default=[],
      action="append",
      help="mapping from url to file name, used when generating snapshots")
  result.add_option("-v", "--verbose",
      help='Verbose output.',
      default=False, action="store_true")
  result.add_option("--target_os",
      action="store", type="string",
      help="Which os to run the executable on")
  return result


def ProcessOptions(options):
  if not options.executable:
    sys.stderr.write('--executable not specified\n')
    return False
  if not options.output_bin:
    sys.stderr.write('--output_bin not specified\n')
    return False
  return True


def RunHost(command):
    print "command %s" % command
    pipe = subprocess.Popen(args=command,
                            shell=True,
                            stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE)
    out, error = pipe.communicate()
    if (pipe.returncode != 0):
      print out, error
      print "command failed"
      print "(Command was: '", ' '.join(command), "')"
      raise Exception("Failed")


def RunTarget(command):
  RunHost("adb shell %s" % command)


def RunOnAndroid(options):
  outputBin = options.output_bin

  android_workspace = os.getenv("ANDROID_DART", "/data/local/dart")
  android_outputBin = join(android_workspace, basename(outputBin))

  executable = options.executable
  android_executable = join(android_workspace, basename(executable))

  filesToPush = [] # (src, dest)
  filesToPull = [] # (src, dest)

  # Setup arguments to the snapshot generator binary.
  script_args = [android_executable]

  # First setup the snapshot output filename.
  filesToPull.append((android_outputBin, outputBin))
  script_args.append(''.join([ "--snapshot=", android_outputBin]))

  # We don't know what source files are needed to fully satisfy a dart script,
  # so we can't support the general case of url mapping or script inclusion.
  if options.url_mapping:
    raise Exception("--url_mapping is not supported when building for Android")

  if options.script:
    raise Exception("--script is not supported when building for Android")

  filesToPush.append((executable, android_executable))

  command = ' '.join(script_args)

  RunHost("adb shell mkdir %s" % android_workspace)
  try:
    for src, dest in filesToPush:
      RunHost("adb push '%s' '%s'" % (src, dest))
    RunTarget(command)
    for src, dest in filesToPull:
      RunHost("adb pull '%s' '%s'" % (src, dest))
  finally:
    for src, dest in filesToPush:
      RunHost("adb shell rm '%s'" % dest)
    for src, dest in filesToPull:
      RunHost("adb shell rm '%s'" % src)


def Main():
  # Parse options.
  parser = BuildOptions()
  (options, args) = parser.parse_args()
  if not ProcessOptions(options):
    parser.print_help()
    return 1

  # If there are additional arguments, report error and exit.
  if args:
    parser.print_help()
    return 1

  # Setup arguments to the snapshot generator binary.
  script_args = []

  # First setup the snapshot output filename.
  script_args.append(''.join([ "--snapshot=", options.output_bin ]))

  # Next setup all url mapping options specified.
  for url_arg in options.url_mapping:
    url_mapping_argument = ''.join(["--url_mapping=", url_arg ])
    script_args.append(url_mapping_argument)

  # Finally append the script name if one is specified.
  if options.script:
    script_args.append(options.script)

  # Construct command line to execute the snapshot generator binary and invoke.
  command = [ options.executable ] + script_args
  if options.verbose:
    print ' '.join(command)

  if options.target_os == 'android':
    try:
      RunOnAndroid(options)
    except Exception as e:
      print "Could not run on Android: %s" % e
      return -1
  else:
    pipe = subprocess.Popen(command,
                            stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE)
    out, error = pipe.communicate()
    if (pipe.returncode != 0):
      print out, error
      print "Snapshot generation failed"
      print "(Command was: '", ' '.join(command), "')"
      return -1

  return 0


if __name__ == '__main__':
  sys.exit(Main())
