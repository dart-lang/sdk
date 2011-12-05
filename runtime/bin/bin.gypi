# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

{
  'variables': {
    'builtin_in_cc_file': 'builtin_in.cc',
    'builtin_cc_file': '<(SHARED_INTERMEDIATE_DIR)/builtin_gen.cc',
    'snapshot_in_cc_file': 'snapshot_in.cc',
    'snapshot_bin_file': '<(SHARED_INTERMEDIATE_DIR)/snapshot_gen.bin',
    'snapshot_cc_file': '<(SHARED_INTERMEDIATE_DIR)/snapshot_gen.cc',
    'cygwin_dir': '../../third_party/cygwin',
  },
  'targets': [
    {
      'target_name': 'generate_builtin_cc_file',
      'type': 'none',
      'conditions': [
        ['OS=="win"', {
          'msvs_cygwin_dirs': ['<(cygwin_dir)'],
        }],
      ],
      'includes': [
        'builtin_sources.gypi',
      ],
      'sources/': [
        ['exclude', '\\.(cc|h)$'],
      ],
      'actions': [
        {
          'action_name': 'generate_builtin_cc',
          'inputs': [
            '../tools/create_string_literal.py',
            '<(builtin_in_cc_file)',
            '<@(_sources)',
          ],
          'outputs': [
            '<(builtin_cc_file)',
          ],
          'action': [
            'python',
            'tools/create_string_literal.py',
            '--output', '<(builtin_cc_file)',
            '--input_cc', '<(builtin_in_cc_file)',
            '<@(_sources)',
          ],
          'message': 'Generating ''<(builtin_cc_file)'' file.'
        },
      ]
    },
    {
      'target_name': 'libdart_builtin',
      'type': 'static_library',
      'dependencies': [
        'generate_builtin_cc_file',
      ],
      'include_dirs': [
        '..',
      ],
      'sources': [
        'builtin_natives.cc',
        'builtin.h',
      ],
      'includes': [
        'builtin_sources.gypi',
      ],
      'sources/': [
        ['exclude', '_test\\.(cc|h)$'],
      ],
      'conditions': [
        ['OS=="win"', {'sources/' : [
          ['exclude', 'fdutils.h'],
        ]}],
      ],
    },
    {
      'target_name': 'libdart_withcore',
      'type': 'static_library',
      'dependencies': [
        'libdart_lib_withcore',
        'libdart_vm',
        'libjscre',
        'libdouble_conversion',
      ],
      'include_dirs': [
        '..',
      ],
      'sources': [
        '../include/dart_api.h',
        '../vm/dart_api_impl.cc',
      ],
    },
    {
      # Completely statically linked binary for generating snapshots.
      'target_name': 'gen_snapshot',
      'type': 'executable',
      'dependencies': [
        'libdart_withcore',
        'libdart_builtin',
      ],
      'include_dirs': [
        '..',
      ],
      'sources': [
        'gen_snapshot.cc',
        'builtin.cc',
        # Include generated source files.
        '<(builtin_cc_file)',
      ],
      'conditions': [
        ['OS=="win"', {
          'link_settings': {
            'libraries': [ '-lws2_32.lib', '-lRpcrt4.lib' ],
          },
       }]],
    },
    {
      # Generate snapshot file.
      'target_name': 'generate_snapshot_file',
      'type': 'none',
      'conditions': [
        ['OS=="win"', {
          'msvs_cygwin_dirs': ['<(cygwin_dir)'],
        }],
      ],
      'dependencies': [
        'gen_snapshot',
      ],
      'actions': [
        {
          'action_name': 'generate_snapshot_file',
          'inputs': [
            '../tools/create_snapshot_file.py',
            '<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)gen_snapshot<(EXECUTABLE_SUFFIX)',
            '<(snapshot_in_cc_file)',
          ],
          'outputs': [
            '<(snapshot_cc_file)',
          ],
          'action': [
            'python',
            'tools/create_snapshot_file.py',
            '--executable', '<(PRODUCT_DIR)/gen_snapshot',
            '--output_bin', '<(snapshot_bin_file)',
            '--input_cc', '<(snapshot_in_cc_file)',
            '--output', '<(snapshot_cc_file)',
          ],
          'message': 'Generating ''<(snapshot_cc_file)'' file.'
        },
      ]
    },
    {
      # dart binary with a snapshot of corelibs built in.
      'target_name': 'dart',
      'type': 'executable',
      'dependencies': [
        'libdart',
        'libdart_builtin',
        'generate_snapshot_file',
      ],
      'include_dirs': [
        '..',
      ],
      'sources': [
        'main.cc',
        'builtin_nolib.cc',
        '<(snapshot_cc_file)',
      ],
      'conditions': [
        ['OS=="win"', {
          'link_settings': {
            'libraries': [ '-lws2_32.lib', '-lRpcrt4.lib' ],
          },
       }]],
    },
    {
      # dart binary without any snapshot built in.
      'target_name': 'dart_no_snapshot',
      'type': 'executable',
      'dependencies': [
        'libdart_withcore',
        'libdart_builtin',
      ],
      'include_dirs': [
        '..',
      ],
      'sources': [
        'main.cc',
        'builtin.cc',
        # Include generated source files.
        '<(builtin_cc_file)',
        'snapshot_empty.cc',
      ],
      'conditions': [
        ['OS=="win"', {
          'link_settings': {
            'libraries': [ '-lws2_32.lib', '-lRpcrt4.lib' ],
          },
       }]],
    },
    {
      'target_name': 'process_test',
      'type': 'executable',
      'sources': [
        'process_test.cc',
      ]
    },
    {
      'target_name': 'run_vm_tests',
      'type': 'executable',
      'dependencies': [
        'libdart_withcore',
        'libdart_builtin',
        'generate_snapshot_test_dat_file',
      ],
      'include_dirs': [
        '..',
        '<(SHARED_INTERMEDIATE_DIR)',
      ],
      'sources': [
        'run_vm_tests.cc',
      ],
      'includes': [
        'builtin_sources.gypi',
        '../vm/vm_sources.gypi',
      ],
      'defines': [
        'TESTING',
      ],
      # Only include _test.[cc|h] files.
      'sources/': [
        ['exclude', '\\.(cc|h)$'],
        ['include', '_test\\.(cc|h)$'],
        ['include', 'run_vm_tests.cc'],
      ],
      'conditions': [
        ['OS=="win"', {
          'link_settings': {
            'libraries': [ '-lws2_32.lib', '-lRpcrt4.lib' ],
          },
        }],
      ],
    },
  ],
}
