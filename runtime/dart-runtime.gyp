# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

{
  'includes': [
    'tools/gyp/runtime-configurations.gypi',
    'vm/vm.gypi',
    'bin/bin.gypi',
    'third_party/double-conversion/src/double-conversion.gypi',
    'third_party/jscre/jscre.gypi',
    '../tools/gyp/source_filter.gypi',
  ],
  'variables': {
    'version_in_cc_file': 'vm/version_in.cc',
    'version_cc_file': '<(SHARED_INTERMEDIATE_DIR)/version.cc',
  },
  'targets': [
    {
      'target_name': 'libdart',
      'type': 'static_library',
      'dependencies': [
        'libdart_lib',
        'libdart_vm',
        'libjscre',
        'libdouble_conversion',
        'generate_version_cc_file',
      ],
      'include_dirs': [
        '.',
      ],
      'sources': [
        'include/dart_api.h',
        'include/dart_debugger_api.h',
        'vm/dart_api_impl.cc',
        'vm/debugger_api_impl.cc',
        'vm/version.h',
        '<(version_cc_file)',
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
        'generate_version_cc_file',
      ],
      'include_dirs': [
        '.',
      ],
      'sources': [
        'include/dart_api.h',
        'include/dart_debugger_api.h',
        'vm/dart_api_impl.cc',
        'vm/debugger_api_impl.cc',
        'vm/version.h',
        '<(version_cc_file)',
      ],
      'defines': [
        # The only effect of DART_SHARED_LIB is to export the Dart API entries.
        'DART_SHARED_LIB',
      ],
      'direct_dependent_settings': {
        'include_dirs': [
          'include',
        ],
      },
    },
    {
      'target_name': 'generate_version_cc_file',
      'type': 'none',
      'actions': [
        {
          'action_name': 'generate_version_cc',
          'inputs': [
            'tools/make_version.py',
            '../tools/VERSION',
            '<(version_in_cc_file)',
          ],
          'outputs': [
            '<(version_cc_file)',
          ],
          'action': [
            'python',
            '-u', # Make standard I/O unbuffered.
            'tools/make_version.py',
            '--output', '<(version_cc_file)',
            '--input', '<(version_in_cc_file)',
            '--version', '../tools/VERSION',
          ],
        },
      ],
    },
  ],
}
