# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

{
  'variables': {
    'corelib_in_cc_file': 'corelib_in.cc',
    'corelib_cc_file': '<(SHARED_INTERMEDIATE_DIR)/corelib_gen.cc',
    'corelib_impl_in_cc_file': 'corelib_impl_in.cc',
    'corelib_impl_cc_file': '<(SHARED_INTERMEDIATE_DIR)/corelib_impl_gen.cc',
    'snapshot_test_dat_file': '<(SHARED_INTERMEDIATE_DIR)/snapshot_test.dat',
    'snapshot_test_in_dat_file': 'snapshot_test_in.dat',
    'snapshot_test_dart_file': 'snapshot_test.dart',
  },
  'targets': [
    {
      'target_name': 'libdart_vm',
      'type': 'static_library',
      'includes': [
        'vm_sources.gypi',
      ],
      'sources/': [
        # Exclude all _test.[cc|h] files.
        ['exclude', '_test\\.cc|h$'],
      ],
      'include_dirs': [
        '..',
      ],
      'conditions': [
        ['OS=="linux"', {
          'link_settings': {
            'libraries': [
              '-lpthread',
              '-lrt',
              '-lcrypto',
            ],
          },
        }],
        ['OS=="mac"', {
          'link_settings': {
            'xcode_settings': {
              'OTHER_LDFLAGS': [
                '-lcrypto',
              ],
            },
          },
        }],
        ['OS=="win"', {
          'sources/' : [
            ['exclude', 'gdbjit.cc'],
          ],
          'link_settings': {
            'libraries': [ '-llibeay32MT.lib' ],
          },
       }]],
    },
    {
      'target_name': 'libdart_lib',
      'type': 'static_library',
      'dependencies': [
        'generate_corelib_cc_file',
        'generate_corelib_impl_cc_file',
      ],
      'includes': [
        '../lib/lib_sources.gypi',
        '../lib/lib_impl_sources.gypi',
      ],
      'sources': [
        # Include generated source files.
        '<(corelib_cc_file)',
        '<(corelib_impl_cc_file)',
      ],
      'include_dirs': [
        '..',
      ],
    },
    {
      'target_name': 'libdart_api',
      'type': 'static_library',
      'include_dirs': [
        '..',
      ],
      'sources': [
        '../vm/dart_api_impl.cc',
      ],
    },
    {
      'target_name': 'generate_corelib_cc_file',
      'type': 'none',
      'conditions': [
        ['OS=="win"', {
          'msvs_cygwin_dirs': ['<(DEPTH)/../third_party/cygwin'],
        }],
      ],
      'includes': [
        # Load the runtime implementation sources.
        '../lib/lib_sources.gypi',
        # Load the shared core library sources.
        '../../corelib/src/corelib_sources.gypi',
      ],
      'sources/': [
        # Exclude all .[cc|h] files.
        # This is only here for reference. Excludes happen after
        # variable expansion, so the script has to do its own
        # exclude processing of the sources being passed.
        ['exclude', '\\.cc|h$'],
      ],
      'actions': [
        {
          'action_name': 'generate_corelib_cc',
          'inputs': [
            '../tools/create_string_literal.py',
            '<(corelib_in_cc_file)',
            '<@(_sources)',
          ],
          'outputs': [
            '<(corelib_cc_file)',
          ],
          'action': [
            'python',
            'tools/create_string_literal.py',
            '--output', '<(corelib_cc_file)',
            '--input_cc', '<(corelib_in_cc_file)',
            '<@(_sources)',
          ],
          'message': 'Generating ''<(corelib_cc_file)'' file.'
        },
      ]
    },
    {
      'target_name': 'generate_corelib_impl_cc_file',
      'type': 'none',
      'conditions': [
        ['OS=="win"', {
          'msvs_cygwin_dirs': ['<(DEPTH)/../third_party/cygwin'],
        }],
      ],
      'includes': [
        # Load the runtime implementation sources.
        '../lib/lib_impl_sources.gypi',
        # Load the shared core library sources.
        '../../corelib/src/implementation/corelib_impl_sources.gypi',
      ],
      'sources/': [
        # Exclude all .[cc|h] files.
        # This is only here for reference. Excludes happen after
        # variable expansion, so the script has to do its own
        # exclude processing of the sources being passed.
        ['exclude', '\\.cc|h$'],
      ],
      'actions': [
        {
          'action_name': 'generate_corelib_impl_cc',
          'inputs': [
            '../tools/create_string_literal.py',
            '<(corelib_impl_in_cc_file)',
            '<@(_sources)',
          ],
          'outputs': [
            '<(corelib_impl_cc_file)',
          ],
          'action': [
            'python',
            'tools/create_string_literal.py',
            '--output', '<(corelib_impl_cc_file)',
            '--input_cc', '<(corelib_impl_in_cc_file)',
            '<@(_sources)',
          ],
          'message': 'Generating ''<(corelib_impl_cc_file)'' file.'
        },
      ]
    },
    {
      'target_name': 'generate_snapshot_test_dat_file',
      'type': 'none',
      'conditions': [
        ['OS=="win"', {
          'msvs_cygwin_dirs': ['<(DEPTH)/../third_party/cygwin'],
        }],
      ],
      'actions': [
        {
          'action_name': 'generate_snapshot_test_dat',
          'inputs': [
            '../tools/create_string_literal.py',
            '<(snapshot_test_in_dat_file)',
            '<(snapshot_test_dart_file)',
          ],
          'outputs': [
            '<(snapshot_test_dat_file)',
          ],
          'action': [
            'python',
            'tools/create_string_literal.py',
            '--output', '<(snapshot_test_dat_file)',
            '--input_cc', '<(snapshot_test_in_dat_file)',
            '<(snapshot_test_dart_file)',
          ],
          'message': 'Generating ''<(snapshot_test_dat_file)'' file.'
        },
      ]
    },
  ]
}
