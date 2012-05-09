# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

{
  'includes': [
    'vm/vm.gypi',
    'bin/bin.gypi',
    'third_party/double-conversion/src/double-conversion.gypi',
    'third_party/jscre/jscre.gypi',
    'tools/gyp/runtime-configurations.gypi',
    '../tools/gyp/source_filter.gypi',
  ],
  'targets': [
    {
      'target_name': 'libdart',
      'type': 'static_library',
      'dependencies': [
        'libdart_lib',
        'libdart_vm',
        'libjscre',
        'libdouble_conversion',
      ],
      'include_dirs': [
        '.',
      ],
      'sources': [
        'include/dart_api.h',
        'include/dart_debugger_api.h',
        'vm/dart_api_impl.cc',
        'vm/debugger_api_impl.cc',
      ],
      'direct_dependent_settings': {
        'include_dirs': [
          'include',
        ],
      },
    },
    {
      # The Dart API is exported from this library to dynamically loaded shared
      # libraries.
      'target_name': 'libdart_export',
      'type': 'static_library',
      'dependencies': [
        'libdart_lib',
        'libdart_vm',
        'libjscre',
        'libdouble_conversion',
      ],
      'include_dirs': [
        '.',
      ],
      'sources': [
        'include/dart_api.h',
        'include/dart_debugger_api.h',
        'vm/dart_api_impl.cc',
        'vm/debugger_api_impl.cc',
      ],
      'defines': [
        'DART_SHARED_LIB',
      ],
      'direct_dependent_settings': {
        'include_dirs': [
          'include',
        ],
      },
    },
  ],
}
