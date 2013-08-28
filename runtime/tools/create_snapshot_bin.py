#!/usr/bin/env python
#
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""Script to create snapshot bin file."""

import getopt
import optparse
import os
from os.path import basename, join
import sys
import utils


HOST_OS = utils.GuessOS()
HOST_CPUS = utils.GuessCpus()
DEBUG = False
VERBOSE = False

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
      help="Which os to run the executable on. Current choice is android")
  result.add_option("--abi",
      action="store", type="string",
      help="Desired ABI for android target OS. armeabi-v7a or x86")
  return result


def ProcessOptions(options):
  if not options.executable:
    sys.stderr.write('--executable not specified\n')
    return False
  if not options.output_bin:
    sys.stderr.write('--output_bin not specified\n')
    return False
  if options.abi and not options.target_os == 'android':
    sys.stderr.write('--abi requires --target_os android\n')
    return False
  return True


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
  script_args = ["--error_on_bad_type", "--error_on_bad_override"]

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
  try:
    utils.RunCommand(command, outStream=sys.stderr, errStream=sys.stderr,
                     verbose=options.verbose, printErrorInfo=True)
  except Exception as e:
    return -1

  return 0


if __name__ == '__main__':
  sys.exit(Main())
