# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

{
  'includes': [
    'vm/vm.gypi',
    'bin/bin.gypi',
    'third_party/jscre/jscre.gypi',
    'tools/gyp/runtime-configurations.gypi',
  ],
  'targets': [
    {
      'target_name': 'libdart',
      'type': 'static_library',
      'dependencies': [
        'libdart_lib',
        'libdart_vm',
        'libjscre',
      ],
      'include_dirs': [
        '.',
      ],
      'sources': [
        'include/dart_api.h',
        'vm/dart_api_impl.cc',
      ],
    },
  ],
}
