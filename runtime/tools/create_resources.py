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

def makeResources(root_dir, input_files, table_name):
  result = ''
  resources = []

  # Write each file's contents as a byte string constant.
  for resource_file in input_files:
    if root_dir and resource_file.startswith(root_dir):
      resource_file_name = resource_file[ len(root_dir) : ]
    else:
      resource_file_name = resource_file
    resource_url = '/%s' % resource_file_name
    result += '// %s\n' % resource_file
    result += 'const char '
    resource_name = re.sub(r'(/|\.|-|\\)', '_', resource_file_name) + '_'
    result += resource_name
    result += '[] = {\n   '
    fileHandle = open(resource_file, 'rb')
    lineCounter = 0
    for byte in fileHandle.read():
      result += r" '\x%02x'," % ord(byte)
      lineCounter += 1
      if lineCounter == 10:
        result += '\n   '
        lineCounter = 0
    if lineCounter != 0:
      result += '\n   '
    result += ' 0\n};\n\n'
    resource_url_scrubbed = re.sub(r'\\', '/', resource_url)
    resources.append(
        (resource_url_scrubbed, resource_name, os.stat(resource_file).st_size));

  # Write the resource table.
  result += 'ResourcesEntry __%s_resources_[] = ' % table_name
  result += '{\n'
  for res in resources:
    result += '   { "%s", %s, %d },\n' % res
  result += '   { 0, 0, 0 },\n'
  result += '};\n\n'
  return result


def makeFile(output_file, root_dir, input_files, outer_namespace,
             inner_namespace, table_name):
  cc_text = '''
// Copyright (c) %d, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

''' % date.today().year
  cc_text += 'namespace %s {\n' % outer_namespace
  if inner_namespace != None:
    cc_text += 'namespace %s {\n' % inner_namespace
  cc_text += '''
struct ResourcesEntry {
  const char* path_;
  const char* resource_;
  int length_;
};

'''
  cc_text += makeResources(root_dir, input_files, table_name)
  cc_text += '\n'
  if inner_namespace != None:
    cc_text += '}  // namespace %s\n' % inner_namespace
  cc_text += '} // namespace %s\n' % outer_namespace
  open(output_file, 'w').write(cc_text)
  return True


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
    parser.add_option("--outer_namespace",
                      action="store", type="string",
                      help="outer C++ namespace",
                      default="dart")
    parser.add_option("--inner_namespace",
                      action="store", type="string",
                      help="inner C++ namespace")
    parser.add_option("--table_name",
                      action="store", type="string",
                      help="name of table")
    parser.add_option("--client_root",
                      action="store", type="string",
                      help="root directory client resources")
    (options, args) = parser.parse_args()
    if not options.output:
      sys.stderr.write('--output not specified\n')
      return -1
    if not options.table_name:
      sys.stderr.write('--table_name not specified\n')
      return -1
    if len(args) == 0:
      sys.stderr.write('No input files specified\n')
      return -1

    files = [ ]

    if options.client_root != None:
      for dirname, dirnames, filenames in os.walk(options.client_root):
        # strip out all dot files.
        filenames = [f for f in filenames if not f[0] == '.']
        dirnames[:] = [d for d in dirnames if not d[0] == '.']
        for f in filenames:
          src_path = os.path.join(dirname, f)
          if (os.path.isdir(src_path)):
              continue
          # Skip devtools version
          if (src_path.find("index_devtools") != -1):
              continue
          files.append(src_path)

    for arg in args:
      files.append(arg)

    if not makeFile(options.output, options.root_prefix, files,
                    options.outer_namespace, options.inner_namespace,
                    options.table_name):
      return -1

    return 0
  except Exception, inst:
    sys.stderr.write('create_resources.py exception\n')
    sys.stderr.write(str(inst))
    sys.stderr.write('\n')
    return -1

if __name__ == '__main__':
  sys.exit(main(sys.argv))
