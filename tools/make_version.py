#!/usr/bin/env python
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#
# This python script creates a version string in a C++ file.

import hashlib
import os
import sys
import time
from optparse import OptionParser
import utils

def debugLog(message):
  print >> sys.stderr, message
  sys.stderr.flush()

# When these files change, snapshots created by the VM are potentially no longer
# backwards-compatible.
VM_SNAPSHOT_FILES=[
  # Header files.
  'clustered_snapshot.h',
  'datastream.h',
  'image_snapshot.h',
  'object.h',
  'raw_object.h',
  'snapshot.h',
  'snapshot_ids.h',
  'symbols.h',
  # Source files.
  'clustered_snapshot.cc',
  'dart.cc',
  'dart_api_impl.cc',
  'image_snapshot.cc',
  'object.cc',
  'raw_object.cc',
  'raw_object_snapshot.cc',
  'snapshot.cc',
  'symbols.cc',
]

def MakeVersionString(quiet, no_git_hash, custom_for_pub=None):
  if custom_for_pub:
    latest = utils.GetLatestDevTag()
    if not latest:
      # If grabbing the dev tag fails, then fall back on the VERSION file.
      latest = utils.GetSemanticSDKVersion(no_git_hash=True)
    if no_git_hash:
      version_string = ("%s.%s" % (latest, custom_for_pub))
    else:
      git_hash = utils.GetShortGitHash()
      version_string = ("%s.%s-%s" % (latest, custom_for_pub, git_hash))
  else:
    version_string = utils.GetSemanticSDKVersion(no_git_hash=no_git_hash)
  if not quiet:
    debugLog("Returning version string: %s " % version_string)
  return version_string


def MakeSnapshotHashString():
  vmhash = hashlib.md5()
  for vmfilename in VM_SNAPSHOT_FILES:
    vmfilepath = os.path.join(utils.DART_DIR, 'runtime', 'vm', vmfilename)
    with open(vmfilepath) as vmfile:
      vmhash.update(vmfile.read())
  return vmhash.hexdigest()


def MakeFile(quiet, output_file, input_file, no_git_hash, custom_for_pub):
  version_cc_text = open(input_file).read()
  version_string = MakeVersionString(quiet, no_git_hash, custom_for_pub)
  version_cc_text = version_cc_text.replace("{{VERSION_STR}}",
                                            version_string)
  version_time = utils.GetGitTimestamp()
  if no_git_hash or version_time == None:
    version_time = "Unknown timestamp"
  version_cc_text = version_cc_text.replace("{{COMMIT_TIME}}",
                                            version_time)
  snapshot_hash = MakeSnapshotHashString()
  version_cc_text = version_cc_text.replace("{{SNAPSHOT_HASH}}",
                                            snapshot_hash)
  open(output_file, 'w').write(version_cc_text)
  return True


def main(args):
  try:
    # Parse input.
    parser = OptionParser()
    parser.add_option("--custom_for_pub",
        action="store",
        type="string",
        help=("Generates a version string that works with pub that includes"
              "the given string"))
    parser.add_option("--input",
        action="store",
        type="string",
        help="input template file")
    parser.add_option("--no_git_hash",
        action="store_true",
        default=False,
        help="Don't try to determine svn revision")
    parser.add_option("--output",
        action="store",
        type="string",
        help="output file name")
    parser.add_option("-q", "--quiet",
        action="store_true",
        default=False,
        help="disable console output")

    (options, args) = parser.parse_args()
    if not options.output:
      sys.stderr.write('--output not specified\n')
      return -1
    if not len(options.input):
      sys.stderr.write('--input not specified\n')
      return -1

    files = []
    for arg in args:
      files.append(arg)

    if not MakeFile(options.quiet, options.output, options.input,
                    options.no_git_hash, options.custom_for_pub):
      return -1

    return 0
  except Exception, inst:
    sys.stderr.write('make_version.py exception\n')
    sys.stderr.write(str(inst))
    sys.stderr.write('\n')
    return -1

if __name__ == '__main__':
  exit_code = main(sys.argv)
  sys.exit(exit_code)
