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


def BuildOptions():
  result = optparse.OptionParser()
  result.add_option("--executable",
      action="store", type="string",
      help="path to snapshot generator executable")
  result.add_option("--snapshot_kind",
      action="store", type="string",
      help="kind of snapshot to generate",
      default="core")
  result.add_option("--load_compilation_trace",
      action="store", type="string",
      help="path to a compilation trace to load before generating a core-jit snapshot")
  result.add_option("--vm_flag",
      action="append", type="string", default=[],
      help="pass additional Dart VM flag")
  result.add_option("--vm_output_bin",
      action="store", type="string",
      help="output file name into which vm isolate snapshot in binary form " +
           "is generated")
  result.add_option("--vm_instructions_output_bin",
      action="store", type="string",
      help="output file name into which vm isolate snapshot in binary form " +
           "is generated")
  result.add_option("--isolate_output_bin",
      action="store", type="string",
      help="output file name into which isolate snapshot in binary form " +
           "is generated")
  result.add_option("--isolate_instructions_output_bin",
      action="store", type="string",
      help="output file name into which isolate snapshot in binary form " +
           "is generated")
  result.add_option("--embedder_entry_points_manifest",
      action="store", type="string",
      help="input manifest with the vm entry points in a precompiled snapshot")
  result.add_option("--script",
      action="store", type="string",
      help="Dart script for which snapshot is to be generated")
  result.add_option("--package_root",
      action="store", type="string",
      help="path used to resolve package: imports.")
  result.add_option("--packages",
      action="store", type="string",
      help="package config file used to reasolve package: imports.")
  result.add_option("--url_mapping",
      default=[],
      action="append",
      help=("mapping from url to file name, used when generating snapshots " +
            "E.g.: --url_mapping=fileUri,/path/to/file.dart"))
  result.add_option("-v", "--verbose",
      help='Verbose output.',
      default=False, action="store_true")
  result.add_option("--timestamp_file",
      action="store", type="string",
      help="Path to timestamp file that will be written",
      default="")
  return result


def ProcessOptions(options):
  if not options.executable:
    sys.stderr.write('--executable not specified\n')
    return False
  if not options.snapshot_kind:
    sys.stderr.write('--snapshot_kind not specified\n')
    return False
  if not options.vm_output_bin:
    sys.stderr.write('--vm_output_bin not specified\n')
    return False
  if not options.isolate_output_bin:
    sys.stderr.write('--isolate_output_bin not specified\n')
    return False
  if (options.snapshot_kind == 'core-jit'
      and not options.vm_instructions_output_bin):
    sys.stderr.write('--vm_instructions_output_bin not specified\n')
    return False
  if (options.snapshot_kind == 'core-jit'
      and not options.isolate_instructions_output_bin):
    sys.stderr.write('--isolate_instructions_output_bin not specified\n')
    return False
  return True


def CreateTimestampFile(options):
  if options.timestamp_file != '':
    dir_name = os.path.dirname(options.timestamp_file)
    if not os.path.exists(dir_name):
      os.mkdir(dir_name)
    open(options.timestamp_file, 'w').close()


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
  script_args = ["--ignore_unrecognized_flags"]

  for flag in options.vm_flag:
    script_args.append(flag)

  if options.load_compilation_trace:
    script_args.append(''.join([ "--load_compilation_trace=", options.load_compilation_trace]))

  # Pass along the package_root if there is one.
  if options.package_root:
    script_args.append(''.join([ "--package_root=", options.package_root]))

  # Pass along the packages if there is one.
  if options.packages:
    script_args.append(''.join([ "--packages=", options.packages]))

  # First setup the vm isolate and regular isolate snapshot output filename.
  script_args.append(''.join([ "--snapshot_kind=", options.snapshot_kind ]))
  script_args.append(''.join([ "--vm_snapshot_data=", options.vm_output_bin ]))
  script_args.append(''.join([ "--isolate_snapshot_data=", options.isolate_output_bin ]))

  if options.vm_instructions_output_bin != None:
    script_args.append(''.join([ "--vm_snapshot_instructions=",
                                 options.vm_instructions_output_bin ]))
  if options.isolate_instructions_output_bin != None:
    script_args.append(''.join([ "--isolate_snapshot_instructions=",
                                 options.isolate_instructions_output_bin ]))

  # Specify the embedder entry points snapshot
  if options.embedder_entry_points_manifest:
    script_args.append(''.join([ "--embedder_entry_points_manifest=",
                                 options.embedder_entry_points_manifest ]))

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

  # Success, update timestamp file.
  CreateTimestampFile(options)

  return 0


if __name__ == '__main__':
  sys.exit(Main())
