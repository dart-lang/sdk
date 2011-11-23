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
      help="path to snapshot generator executable")
  result.add_option("--output_bin",
      action="store", type="string",
      help="output file name into which snapshot in binary form is generated")
  result.add_option("--input_cc",
      action="store", type="string",
      help="input file name which contains the C buffer template")
  result.add_option("--output",
      action="store", type="string",
      help="output file name into which snapshot in C buffer form is generated")
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
  pipe = subprocess.Popen(command,
                          stdout=subprocess.PIPE,
                          stderr=subprocess.PIPE)
  out, error = pipe.communicate()
  if (pipe.returncode != 0):
    print out, error
    print "Snapshot generation failed"
    print "(Command was: '", ' '.join(command), "')"
    return -1

  if not makeFile(options.output, options.input_cc, options.output_bin):
    print "Unable to generate snapshot in C buffer form"
    return -1

  return 0

if __name__ == '__main__':
  sys.exit(Main())
