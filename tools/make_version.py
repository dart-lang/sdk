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
  'datastream.h',
  'object.h',
  'raw_object.h',
  'snapshot.h',
  'snapshot_ids.h',
  'symbols.h',
  # Source files.
  'dart.cc',
  'dart_api_impl.cc',
  'object.cc',
  'raw_object.cc',
  'raw_object_snapshot.cc',
  'snapshot.cc',
  'symbols.cc',
]

def makeVersionString():
  version_string = utils.GetVersion()
  debugLog("Returning version string: %s " % version_string)
  return version_string


def makeSnapshotHashString():
  vmhash = hashlib.md5()
  for vmfilename in VM_SNAPSHOT_FILES:
    vmfilepath = os.path.join(utils.DART_DIR, 'runtime', 'vm', vmfilename)
    with open(vmfilepath) as vmfile:
      vmhash.update(vmfile.read())
  return vmhash.hexdigest()


def makeFile(output_file, input_file):
  version_cc_text = open(input_file).read()
  version_string = makeVersionString()
  version_cc_text = version_cc_text.replace("{{VERSION_STR}}",
                                            version_string)
  version_time = time.ctime(time.time())
  version_cc_text = version_cc_text.replace("{{BUILD_TIME}}",
                                            version_time)
  snapshot_hash = makeSnapshotHashString()
  version_cc_text = version_cc_text.replace("{{SNAPSHOT_HASH}}",
                                            snapshot_hash)
  open(output_file, 'w').write(version_cc_text)
  return True


def main(args):
  try:
    # Parse input.
    parser = OptionParser()
    parser.add_option("--output",
                      action="store", type="string",
                      help="output file name")
    parser.add_option("--input",
                      action="store", type="string",
                      help="input template file")

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

    if not makeFile(options.output, options.input):
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
