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
  },
  'targets': [
    {
      'target_name': 'generate_builtin_cc_file',
      'type': 'none',
      'conditions': [
        ['OS=="win"', {
          'msvs_cygwin_dirs': ['<(DEPTH)/../third_party/cygwin'],
        }],
      ],
      'sources': [
        'builtin.dart',
        'directory.dart',
        'directory_impl.dart',
        'eventhandler.dart',
        'file.dart',
        'file_impl.dart',
        'input_stream.dart',
        'output_stream.dart',
        'string_stream.dart',
        'process.dart',
        'process_impl.dart',
        'socket.dart',
        'socket_impl.dart',
        'socket_stream.dart',
        'timer.dart',
        'timer_impl.dart',
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
        'builtin.cc',
        'builtin.h',
        'dartutils.h',
        'dartutils.cc',
        'directory.h',
        'directory.cc',
        'directory_posix.cc',
        'directory_win.cc',
        'eventhandler.cc',
        'eventhandler.h',
        'eventhandler_linux.cc',
        'eventhandler_linux.h',
        'eventhandler_macos.cc',
        'eventhandler_macos.h',
        'eventhandler_win.cc',
        'eventhandler_win.h',
        'file.cc',
        'file.h',
        'file_linux.cc',
        'file_macos.cc',
        'file_win.cc',
        'fdutils.h',
        'fdutils_linux.cc',
        'fdutils_macos.cc',
        'globals.h',
        'process.cc',
        'process.h',
        'process_linux.cc',
        'process_macos.cc',
        'process_win.cc',
        'socket.cc',
        'socket.h',
        'socket_linux.cc',
        'socket_macos.cc',
        'socket_win.cc',
        'set.h',
        # Include generated source files.
        '<(builtin_cc_file)',
      ],
      'conditions': [
        ['OS=="win"', {'sources/' : [
          ['exclude', 'fdutils.h'],
        ]}],
      ],
    },
    {
      # Standalone executable using the shared libdart library.
      'target_name': 'dart_no_snapshot',
      'type': 'executable',
      'dependencies': [
        'libdart',
        'libdart_builtin',
      ],
      'include_dirs': [
        '..',
      ],
      'sources': [
        'main.cc',
        'process_script.cc',
        'process_script.h',
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
      # Completely statically linked dart binary.
      'target_name': 'dart_no_snapshot_bin',
      'type': 'executable',
      'dependencies': [
        'libdart_lib',
        'libdart_vm',
        'libjscre',
        'libdart_api',
        'libdart_builtin',
      ],
      'include_dirs': [
        '..',
      ],
      'sources': [
        'main.cc',
        'process_script.cc',
        'process_script.h',
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
      # Completely statically linked binary for generating snapshots.
      'target_name': 'gen_snapshot_bin',
      'type': 'executable',
      'dependencies': [
        'libdart_lib',
        'libdart_vm',
        'libjscre',
        'libdart_api',
        'libdart_builtin',
      ],
      'include_dirs': [
        '..',
      ],
      'sources': [
        'gen_snapshot.cc',
        'process_script.cc',
        'process_script.h',
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
          'msvs_cygwin_dirs': ['<(DEPTH)/../third_party/cygwin'],
        }],
      ],
      'dependencies': [
        'gen_snapshot_bin',
      ],
      'actions': [
        {
          'action_name': 'generate_snapshot_file',
          'inputs': [
            '../tools/create_snapshot_file.py',
            '<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)gen_snapshot_bin<(EXECUTABLE_SUFFIX)',
            '<(snapshot_in_cc_file)',
          ],
          'outputs': [
            '<(snapshot_cc_file)',
          ],
          'action': [
            'python',
            'tools/create_snapshot_file.py',
            '--executable', '<(PRODUCT_DIR)/gen_snapshot_bin',
            '--output_bin', '<(snapshot_bin_file)',
            '--input_cc', '<(snapshot_in_cc_file)',
            '--output', '<(snapshot_cc_file)',
          ],
          'message': 'Generating ''<(snapshot_cc_file)'' file.'
        },
      ]
    },
    {
      # Standalone executable using the shared libdart library with a snapshot
      # of the core and builtin libraries linked in.
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
        'process_script.cc',
        'process_script.h',
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
      # Completely statically linked dart binary with a snapshot of the core
      # and builtin libraries linked in.
      'target_name': 'dart_bin',
      'type': 'executable',
      'dependencies': [
        'libdart_lib',
        'libdart_vm',
        'libjscre',
        'libdart_api',
        'libdart_builtin',
        'generate_snapshot_file',
      ],
      'include_dirs': [
        '..',
      ],
      'sources': [
        'main.cc',
        'process_script.cc',
        'process_script.h',
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
      'target_name': 'process_test',
      'type': 'executable',
      'sources': [
        'process_test.cc',
      ]
    },
    {
      'target_name': 'run_vm_tests',
      'type': 'executable',
      # The unittest framework needs to be able to call the unexported symbols,
      # which is why it links against the static libraries. In general binaries
      # should depend on the shared library.
      'dependencies': [
        'libdart_lib',
        'libdart_vm',
        'libjscre',
        'libdart_api',
        'generate_snapshot_test_dat_file',
      ],
      'include_dirs': [
        '..',
        '<(SHARED_INTERMEDIATE_DIR)',
      ],
      'sources': [
        'run_vm_tests.cc',
        'dartutils.h',
        'dartutils.cc',
        'directory.h',
        'directory.cc',
        'directory_posix.cc',
        'directory_win.cc',
        'eventhandler.cc',
        'eventhandler.h',
        'eventhandler_linux.cc',
        'eventhandler_linux.h',
        'eventhandler_macos.cc',
        'eventhandler_macos.h',
        'eventhandler_win.cc',
        'eventhandler_win.h',
        'file.cc',
        'file.h',
        'file_test.cc',
        'file_linux.cc',
        'file_macos.cc',
        'file_win.cc',
        'fdutils.h',
        'fdutils_linux.cc',
        'fdutils_macos.cc',
        'process.cc',
        'process.h',
        'process_linux.cc',
        'process_macos.cc',
        'process_win.cc',
        'socket.cc',
        'socket.h',
        'socket_linux.cc',
        'socket_macos.cc',
        'socket_win.cc',
        'set.h',
        'set_test.cc',
      ],
      'includes': [
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
        ['include', 'dart_api_impl.cc'],
        ['include', 'dartutils.h'],
        ['include', 'dartutils.cc'],
        ['include', 'directory.h'],
        ['include', 'directory.cc'],
        ['include', 'eventhandler.cc'],
        ['include', 'eventhandler.h'],
        ['include', 'file.cc'],
        ['include', 'file.h'],
        ['include', 'file_test.cc'],
        ['include', 'process.cc'],
        ['include', 'process.h'],
        ['include', 'socket.cc'],
        ['include', 'socket.h'],
        ['include', 'set_test.cc'],
      ],
      'conditions': [
        ['OS=="linux"', {'sources/' : [
          ['include', 'directory_posix.cc'],
          ['include', 'eventhandler_linux.cc'],
          ['include', 'eventhandler_linux.h'],
          ['include', 'fdutils.h'],
          ['include', 'fdutils_linux.cc'],
          ['include', 'file_linux.cc'],
          ['include', 'process_linux.cc'],
          ['include', 'socket_linux.cc'],
        ]}],
        ['OS=="mac"', {'sources/' : [
          ['include', 'directory_posix.cc'],
          ['include', 'eventhandler_macos.cc'],
          ['include', 'eventhandler_macos.h'],
          ['include', 'fdutils.h'],
          ['include', 'fdutils_macos.cc'],
          ['include', 'file_macos.cc'],
          ['include', 'process_macos.cc'],
          ['include', 'socket_macos.cc'],
        ]}],
        ['OS=="win"', {'sources/' : [
          ['include', 'directory_win.cc'],
          ['include', 'eventhandler_win.cc'],
          ['include', 'eventhandler_win.h'],
          ['include', 'file_win.cc'],
          ['include', 'process_win.cc'],
          ['include', 'socket_win.cc'],
        ]}],
        ['OS=="win"', {
          'link_settings': {
            'libraries': [ '-lws2_32.lib', '-lRpcrt4.lib' ],
          },
        }],
      ],
    },
  ],
}
