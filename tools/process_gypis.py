#!/usr/bin/env python
# Copyright 2016, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import gn_helpers
import os.path
import sys

# Given a list of dart package names read in the set of runtime and sdk library
# sources into variables in a gn scope.


def LoadPythonDictionary(path):
  file_string = open(path).read()
  try:
    file_data = eval(file_string, {'__builtins__': None}, None)
  except SyntaxError, e:
    e.filename = path
    raise
  except Exception, e:
    raise Exception('Unexpected error while reading %s: %s' %
                    (path, str(e)))

  assert isinstance(
    file_data, dict), '%s does not eval to a dictionary' % path
  return file_data


def main():
  dart_root_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
  runtime_dir = os.path.join(dart_root_dir, 'runtime')
  runtime_lib_dir = os.path.join(runtime_dir, 'lib')
  sdk_lib_dir = os.path.join(dart_root_dir, 'sdk', 'lib')
  libs = sys.argv[1:]
  data = {}
  data['allsources'] = []

  for lib in libs:
    runtime_path = os.path.join(runtime_lib_dir, lib + '_sources.gypi')
    sdk_path = os.path.join(sdk_lib_dir, lib, lib + '_sources.gypi')
    runtime_dict = LoadPythonDictionary(runtime_path)
    for source in runtime_dict['sources']:
      data['allsources'].append(source)
    data[lib + '_runtime_sources'] = runtime_dict['sources']
    sdk_dict = LoadPythonDictionary(sdk_path)
    data[lib + '_sdk_sources'] = sdk_dict['sources']

  vm_sources_path = os.path.join(runtime_dir, 'vm', 'vm_sources.gypi')
  vm_sources_dict = LoadPythonDictionary(vm_sources_path)
  data['vm_sources'] = vm_sources_dict['sources']

  platform_sources_base = os.path.join(runtime_dir, 'platform', 'platform_')
  platform_headers_dict = LoadPythonDictionary(
      platform_sources_base + 'headers.gypi')
  platform_sources_dict = LoadPythonDictionary(
      platform_sources_base + 'sources.gypi')
  data['platform_sources'] = platform_headers_dict[
      'sources'] + platform_sources_dict['sources']

  bin_io_sources_path = os.path.join(runtime_dir, 'bin', 'io_sources.gypi')
  bin_io_sources_dict = LoadPythonDictionary(bin_io_sources_path)
  data['bin_io_sources'] = bin_io_sources_dict['sources']

  print gn_helpers.ToGNString(data)
  return 0

if __name__ == '__main__':
  sys.exit(main())
