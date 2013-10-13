# Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#
# This python script creates string literals in a C++ source file from a C++
# source template and one or more resource files.

import os
import sys
from os.path import join
import time
from optparse import OptionParser
import re
from datetime import date

def makeResources(root_dir, package_dir, third_party_dir, rebase, input_files):
  result = ''
  resources = []

  # Write each file's contents as a byte string constant.
  for resource_file in input_files:
    if root_dir and resource_file.startswith(root_dir):
      resource_file_name = resource_file[ len(root_dir) : ]
    elif package_dir and resource_file.startswith(package_dir):
      resource_file_name = os.path.join(rebase,
                                        resource_file[ len(package_dir) : ])
    elif third_party_dir and resource_file.startswith(third_party_dir):
      resource_file_name = os.path.join(rebase,
                                        resource_file[ len(third_party_dir) : ])
    else:
      resource_file_name = resource_file

    resource_url = '/%s' % resource_file_name
    result += '// %s\n' % resource_file
    result += 'const char '
    resource_name = re.sub(r'(/|\.|-)', '_', resource_file_name) + '_'
    result += resource_name
    result += '[] = {\n   '
    fileHandle = open(resource_file, 'rb')
    lineCounter = 0
    for byte in fileHandle.read():
      result += ' %d,' % ord(byte)
      lineCounter += 1
      if lineCounter == 10:
        result += '\n   '
        lineCounter = 0
    if lineCounter != 0:
      result += '\n   '
    result += ' 0\n};\n\n'
    resources.append(
        (resource_url, resource_name, os.stat(resource_file).st_size) );

  # Write the resource table.
  result += 'Resources::resource_map_entry Resources::builtin_resources_[] = '
  result += '{\n'
  for res in resources:
    result += '   { "%s", %s, %d },\n' % res
  result += '};\n\n'
  result += 'const intptr_t Resources::builtin_resources_count_ '
  result += '= %d;\n' % len(resources)
  return result


def makeFile(output_file, root_dir, package_dir, third_party_dir, rebase_dir,
             input_files):
  cc_text = '''
// Copyright (c) %d, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

''' % date.today().year
  cc_text += '#include "bin/resources.h"\n\n'
  cc_text += 'namespace dart {\n'
  cc_text += 'namespace bin {\n'
  cc_text += makeResources(root_dir, package_dir, third_party_dir, rebase_dir,
                           input_files)
  cc_text += '}  // namespace bin\n} // namespace dart\n'
  open(output_file, 'w').write(cc_text)
  return True


def makeFileList(input_file_name, root_prefix, package_dir):
  product_dir = '<(PRODUCT_DIR)/'
  file = open(input_file_name, 'rb')
  gyp_contents = eval(file.read())
  files = []
  for input_file in gyp_contents['sources']:
    if input_file.startswith(product_dir):
      files.append(os.path.join(package_dir, input_file[ len(product_dir) : ]))
    else:
      files.append(os.path.join(root_prefix, input_file))
  return files


def main(args):
  try:
    # Parse input.
    parser = OptionParser()
    parser.add_option("--output",
                      action="store", type="string",
                      help="output file name")
    parser.add_option("--root_prefix",
                      action="store", type="string",
                      help="root directory for resources")
    parser.add_option("--package_dir",
                      action="store", type="string",
                      help="root directory for package resources")
    parser.add_option("--third_party_dir",
                      action="store", type="string",
                      help="root directory for third party resources")
    parser.add_option("--rebase",
                      action="store", type="string",
                      help="base directory for package/third_party resources")

    (options, args) = parser.parse_args()
    if not options.output:
      sys.stderr.write('--output not specified\n')
      return -1
    if not options.root_prefix:
      sys.stderr.write('--root_prefix not specified\n')
      return -1
    if not options.package_dir:
      sys.stderr.write('--package_dir not specified\n')
      return -1
    if not options.third_party_dir:
      sys.stderr.write('--third_party_dir not specified\n')
      return -1
    if not options.rebase:
      sys.stderr.write('--rebase not specified\n')
      return -1
    if len(args) == 0:
      sys.stderr.write('No input files specified\n')
      return -1

    files = makeFileList(args[0], options.root_prefix, options.package_dir)
    for file in files:
      print(file)

    if not makeFile(options.output, options.root_prefix, options.package_dir,
                    options.third_party_dir, options.rebase, files):
      return -1

    return 0
  except Exception, inst:
    sys.stderr.write('create_resources.py exception\n')
    sys.stderr.write(str(inst))
    sys.stderr.write('\n')
    return -1

if __name__ == '__main__':
  sys.exit(main(sys.argv))
