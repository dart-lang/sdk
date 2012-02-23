# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

{
  'variables': {
    'io_cc_file': '<(SHARED_INTERMEDIATE_DIR)/io_gen.cc',
    'json_cc_file': '<(SHARED_INTERMEDIATE_DIR)/json_gen.cc',
    'uri_cc_file': '<(SHARED_INTERMEDIATE_DIR)/uri_gen.cc',
    'utf8_cc_file': '<(SHARED_INTERMEDIATE_DIR)/utf8_gen.cc',
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
            '--include', 'bin/builtin.h',
            '--var_name', 'Builtin::builtin_source_',
            '<@(_sources)',
          ],
          'message': 'Generating ''<(builtin_cc_file)'' file.'
        },
      ]
    },
    {
      'target_name': 'generate_io_cc_file',
      'type': 'none',
      'conditions': [
        ['OS=="win"', {
          'msvs_cygwin_dirs': ['<(cygwin_dir)'],
        }],
      ],
      'includes': [
        'io_sources.gypi',
      ],
      'actions': [
        {
          'action_name': 'generate_io_cc',
          'inputs': [
            '../tools/create_string_literal.py',
            '<(builtin_in_cc_file)',
            '<@(_sources)',
          ],
          'outputs': [
            '<(io_cc_file)',
          ],
          'action': [
            'python',
            'tools/create_string_literal.py',
            '--output', '<(io_cc_file)',
            '--input_cc', '<(builtin_in_cc_file)',
            '--include', 'bin/builtin.h',
            '--var_name', 'Builtin::io_source_',
            '<@(_sources)',
          ],
          'message': 'Generating ''<(io_cc_file)'' file.'
        },
      ]
    },
    {
      'target_name': 'generate_json_cc_file',
      'type': 'none',
      'conditions': [
        ['OS=="win"', {
          'msvs_cygwin_dirs': ['<(cygwin_dir)'],
        }],
      ],
      'includes': [
        'json_sources.gypi',
      ],
      'actions': [
        {
          'action_name': 'generate_json_cc',
          'inputs': [
            '../tools/create_string_literal.py',
            '<(builtin_in_cc_file)',
            '<@(_sources)',
          ],
          'outputs': [
            '<(json_cc_file)',
          ],
          'action': [
            'python',
            'tools/create_string_literal.py',
            '--output', '<(json_cc_file)',
            '--input_cc', '<(builtin_in_cc_file)',
            '--include', 'bin/builtin.h',
            '--var_name', 'Builtin::json_source_',
            '<@(_sources)',
          ],
          'message': 'Generating ''<(json_cc_file)'' file.'
        },
      ]
    },
    {
      'target_name': 'generate_uri_cc_file',
      'type': 'none',
      'conditions': [
        ['OS=="win"', {
          'msvs_cygwin_dirs': ['<(cygwin_dir)'],
        }],
      ],
      'includes': [
        'uri_sources.gypi',
      ],
      'actions': [
        {
          'action_name': 'generate_uri_cc',
          'inputs': [
            '../tools/create_string_literal.py',
            '<(builtin_in_cc_file)',
            '<@(_sources)',
          ],
          'outputs': [
            '<(uri_cc_file)',
          ],
          'action': [
            'python',
            'tools/create_string_literal.py',
            '--output', '<(uri_cc_file)',
            '--input_cc', '<(builtin_in_cc_file)',
            '--include', 'bin/builtin.h',
            '--var_name', 'Builtin::uri_source_',
            '<@(_sources)',
          ],
          'message': 'Generating ''<(uri_cc_file)'' file.'
        },
      ]
    },
    {
      'target_name': 'generate_utf8_cc_file',
      'type': 'none',
      'conditions': [
        ['OS=="win"', {
          'msvs_cygwin_dirs': ['<(cygwin_dir)'],
        }],
      ],
      'includes': [
        'utf8_sources.gypi',
      ],
      'actions': [
        {
          'action_name': 'generate_utf8_cc',
          'inputs': [
            '../tools/create_string_literal.py',
            '<(builtin_in_cc_file)',
            '<@(_sources)',
          ],
          'outputs': [
            '<(utf8_cc_file)',
          ],
          'action': [
            'python',
            'tools/create_string_literal.py',
            '--output', '<(utf8_cc_file)',
            '--input_cc', '<(builtin_in_cc_file)',
            '--include', 'bin/builtin.h',
            '--var_name', 'Builtin::utf8_source_',
            '<@(_sources)',
          ],
          'message': 'Generating ''<(utf8_cc_file)'' file.'
        },
      ]
    },
    {
      'target_name': 'libdart_builtin',
      'type': 'static_library',
      'dependencies': [
        'generate_builtin_cc_file',
        'generate_io_cc_file',
        'generate_json_cc_file',
        'generate_uri_cc_file',
        'generate_utf8_cc_file',
      ],
      'include_dirs': [
        '..',
      ],
      'sources': [
        'builtin_natives.cc',
        'builtin.h',
      ],
      'includes': [
        'builtin_impl_sources.gypi',
        '../platform/platform_sources.gypi',
      ],
      'sources/': [
        ['exclude', '_test\\.(cc|h)$'],
      ],
      'conditions': [
        ['OS=="win"', {'sources/' : [
          ['exclude', 'fdutils.h'],
        ]}],
        ['OS=="linux"',
         {'ldflags': ['-ldl',],
        }],
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
        '../include/dart_debugger_api.h',
        '../vm/dart_api_impl.cc',
        '../vm/debugger_api_impl.cc',
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
        '<(io_cc_file)',
        '<(json_cc_file)',
        '<(uri_cc_file)',
        '<(utf8_cc_file)',
      ],
      'conditions': [
        ['OS=="win"', {
          'link_settings': {
            'libraries': [ '-lws2_32.lib', '-lRpcrt4.lib', '-llibeay32MT.lib' ],
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
        'libdart_export',
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
            'libraries': [ '-lws2_32.lib', '-lRpcrt4.lib', '-llibeay32MT.lib' ],
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
        '<(io_cc_file)',
        '<(json_cc_file)',
        '<(uri_cc_file)',
        '<(utf8_cc_file)',
        'snapshot_empty.cc',
      ],
      'conditions': [
        ['OS=="win"', {
          'link_settings': {
            'libraries': [ '-lws2_32.lib', '-lRpcrt4.lib', '-llibeay32MT.lib' ],
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
        'builtin_impl_sources.gypi',
        '../platform/platform_sources.gypi',
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
            'libraries': [ '-lws2_32.lib', '-lRpcrt4.lib', '-llibeay32MT.lib' ],
          },
        }],
      ],
    },
  ],
  'conditions': [
    ['OS=="linux"', {
      'targets': [
        {
          'target_name': 'test_extension',
          'type': 'shared_library',
          'dependencies': [
          ],
          'include_dirs': [
            '.',
          ],
          'sources': [
            'test_extension_linux.cc',
          ],
          'defines': [
            'DART_SHARED_LIB',
          ],
        },
      ],
    }],
  ],
}

