#!/usr/bin/env python
#
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Script to create snapshot files.

import getopt
import optparse
import string
import subprocess
import sys
import utils


HOST_OS = utils.GuessOS()
HOST_CPUS = utils.GuessCpus()


def BuildOptions():
  result = optparse.OptionParser()
  result.add_option("--executable",
      action="store", type="string",
      help="path to executable")
  result.add_option("--output_bin",
      action="store", type="string",
      help="binary snapshot output file name")
  result.add_option("--input_cc",
      action="store", type="string",
      help="input template file name")
  result.add_option("--output",
      action="store", type="string",
      help="generated snapshot output file name")
  result.add_option("--scripts",
      action="store", type="string",
      help="list of scripts to include in snapshot")
  result.add_option("-v", "--verbose",
      help='Verbose output.',
      default=False, action="store_true")
  return result


def ProcessOptions(options):
  if not options.executable:
    sys.stderr.write('--executable not specified\n')
    return False
  if not options.output_bin:
    sys.stderr.write('--output_bin not specified\n')
    return False
  if not options.input_cc:
    sys.stderr.write('--input_cc not specified\n')
    return False
  if not options.output:
    sys.stderr.write('--output not specified\n')
    return False
  return True


def makeString(input_file):
  result = ' '
  fileHandle = open(input_file, 'rb')
  lineCounter = 0
  for byte in fileHandle.read():
    result += ' %d,' % ord(byte)
    lineCounter += 1
    if lineCounter == 10:
      result += '\n   '
      lineCounter = 0
  if lineCounter != 0:
    result += '\n   '
  return result


def makeFile(output_file, input_cc_file, input_file):
  snapshot_cc_text = open(input_cc_file).read()
  snapshot_cc_text = snapshot_cc_text % makeString(input_file)
  open(output_file, 'w').write(snapshot_cc_text)
  return True


def Main():
  # Parse the options.
  parser = BuildOptions()
  (options, args) = parser.parse_args()
  if not ProcessOptions(options):
    parser.print_help()
    return 1

  # Construct the path to the dart binary.
  snapshot_argument = ''.join([ "--snapshot=", options.output_bin ])
  if not options.scripts:
    command = [ options.executable, snapshot_argument ]
  else:
    scripts = string.split(options.scripts)
    command = [ options.executable, snapshot_argument, "--" ] + scripts + [ "--" ]
  if options.verbose:
    print ' '.join(command)
  subprocess.call(command)

  if not makeFile(options.output, options.input_cc, options.output_bin):
    return -1

  return 0

if __name__ == '__main__':
  sys.exit(Main())
