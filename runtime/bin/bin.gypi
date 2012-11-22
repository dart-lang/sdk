# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

{
  'variables': {
    'crypto_cc_file': '<(SHARED_INTERMEDIATE_DIR)/crypto_gen.cc',
    'io_cc_file': '<(SHARED_INTERMEDIATE_DIR)/io_gen.cc',
    'io_patch_cc_file': '<(SHARED_INTERMEDIATE_DIR)/io_patch_gen.cc',
    'json_cc_file': '<(SHARED_INTERMEDIATE_DIR)/json_gen.cc',
    'uri_cc_file': '<(SHARED_INTERMEDIATE_DIR)/uri_gen.cc',
    'utf_cc_file': '<(SHARED_INTERMEDIATE_DIR)/utf_gen.cc',
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
      'target_name': 'generate_crypto_cc_file',
      'type': 'none',
      'includes': [
        'crypto_sources.gypi',
      ],
      'actions': [
        {
          'action_name': 'generate_crypto_cc',
          'inputs': [
            '../tools/create_string_literal.py',
            '<(builtin_in_cc_file)',
            '<@(_sources)',
          ],
          'outputs': [
            '<(crypto_cc_file)',
          ],
          'action': [
            'python',
            'tools/create_string_literal.py',
            '--output', '<(crypto_cc_file)',
            '--input_cc', '<(builtin_in_cc_file)',
            '--include', 'bin/builtin.h',
            '--var_name', 'Builtin::crypto_source_',
            '<@(_sources)',
          ],
          'message': 'Generating ''<(crypto_cc_file)'' file.'
        },
      ]
    },
    {
      'target_name': 'generate_io_cc_file',
      'type': 'none',
      'sources': [
        'io.dart',
      ],
      'includes': [
        '../../sdk/lib/io/iolib_sources.gypi',
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
      'target_name': 'generate_io_patch_cc_file',
      'type': 'none',
      'includes': [
        'io_sources.gypi',
      ],
      'actions': [
        {
          'action_name': 'generate_io_patch_cc',
          'inputs': [
            '../tools/create_string_literal.py',
            '<(builtin_in_cc_file)',
            '<@(_sources)',
          ],
          'outputs': [
            '<(io_patch_cc_file)',
          ],
          'action': [
            'python',
            'tools/create_string_literal.py',
            '--output', '<(io_patch_cc_file)',
            '--input_cc', '<(builtin_in_cc_file)',
            '--include', 'bin/builtin.h',
            '--var_name', 'Builtin::io_patch_',
            '<@(_sources)',
          ],
          'message': 'Generating ''<(io_patch_cc_file)'' file.'
        },
      ]
    },
    {
      'target_name': 'generate_json_cc_file',
      'type': 'none',
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
      'includes': [
        'uri_sources.gypi',
      ],
      'variables': {
        'uri_dart': '<(SHARED_INTERMEDIATE_DIR)/uri.dart',
      },
      'actions': [
        {
          'action_name': 'generate_uri_dart',
          'inputs': [
            '../tools/concat_library.py',
            '<@(_sources)',
          ],
          'outputs': [
            '<(uri_dart)',
          ],
          'action': [
            'python',
            '<@(_inputs)',
            '--output', '<(uri_dart)',
          ],
          'message': 'Generating ''<(uri_dart)'' file.'
        },
        {
          'action_name': 'generate_uri_cc',
          'inputs': [
            '../tools/create_string_literal.py',
            '<(builtin_in_cc_file)',
            '<(uri_dart)',
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
            '<(uri_dart)',
          ],
          'message': 'Generating ''<(uri_cc_file)'' file.'
        },
      ]
    },
    {
      'target_name': 'generate_utf_cc_file',
      'type': 'none',
      'includes': [
        'utf_sources.gypi',
      ],
      'actions': [
        {
          'action_name': 'generate_utf_cc',
          'inputs': [
            '../tools/create_string_literal.py',
            '<(builtin_in_cc_file)',
            '<@(_sources)',
          ],
          'outputs': [
            '<(utf_cc_file)',
          ],
          'action': [
            'python',
            'tools/create_string_literal.py',
            '--output', '<(utf_cc_file)',
            '--input_cc', '<(builtin_in_cc_file)',
            '--include', 'bin/builtin.h',
            '--var_name', 'Builtin::utf_source_',
            '<@(_sources)',
          ],
          'message': 'Generating ''<(utf_cc_file)'' file.'
        },
      ]
    },
    {
      'target_name': 'libdart_builtin',
      'type': 'static_library',
      'dependencies': [
        'generate_builtin_cc_file',
        'generate_crypto_cc_file',
        'generate_io_cc_file',
        'generate_io_patch_cc_file',
        'generate_json_cc_file',
        'generate_uri_cc_file',
        'generate_utf_cc_file',
      ],
      'include_dirs': [
        '..',
      ],
      'sources': [
        'builtin_natives.cc',
        'builtin.h',
        'io_natives.h',
        'log_android.cc',
        'log_linux.cc',
        'log_macos.cc',
        'log_win.cc',
      ],
      'includes': [
        'builtin_impl_sources.gypi',
        '../platform/platform_sources.gypi',
      ],
      'sources/': [
        ['exclude', '_test\\.(cc|h)$'],
      ],
      'conditions': [
        ['OS=="win"', {
          'sources/' : [
            ['exclude', 'fdutils.h'],
          ],
          # TODO(antonm): fix the implementation.
          # Current implementation accepts char* strings
          # and therefore fails to compile once _UNICODE is
          # enabled.  That should be addressed using -A
          # versions of functions and adding necessary conversions.
          'configurations': {
            'Common_Base': {
              'msvs_configuration_attributes': {
                'CharacterSet': '0',
              },
            },
          },
        }],
        ['OS=="linux"', {
          'link_settings': {
            'libraries': [
              '-ldl',
            ],
          },
        }],
      ],
    },
    {
      'target_name': 'libdart_io',
      'type': 'static_library',
      'include_dirs': [
        '..',
      ],
      'sources': [
        'io_natives.h',
        'io_natives.cc',
      ],
      'includes': [
        'io_impl_sources.gypi',
      ],
      'conditions': [
        [ 'dart_io_support==1', {
          'dependencies': [
            'bin/net/ssl.gyp:libssl_dart',
          ],
        }],
        ['OS=="win"', {
          # TODO(antonm): fix the implementation.
          # Current implementation accepts char* strings
          # and therefore fails to compile once _UNICODE is
          # enabled.  That should be addressed using -A
          # versions of functions and adding necessary conversions.
          'configurations': {
            'Common_Base': {
              'msvs_configuration_attributes': {
                'CharacterSet': '0',
              },
            },
          },
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
        'generate_version_cc_file',
      ],
      'include_dirs': [
        '..',
      ],
      'sources': [
        '../include/dart_api.h',
        '../include/dart_debugger_api.h',
        '../vm/dart_api_impl.cc',
        '../vm/debugger_api_impl.cc',
        '<(version_cc_file)',
      ],
      'defines': [
        'DART_SHARED_LIB',
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
        # Only looks up native functions in libdart_builtin, not libdart_io.
        'builtin_gen_snapshot.cc',
        # Include generated source files.
        '<(builtin_cc_file)',
        '<(crypto_cc_file)',
        '<(io_cc_file)',
        '<(io_patch_cc_file)',
        '<(json_cc_file)',
        '<(uri_cc_file)',
        '<(utf_cc_file)',
      ],
      'conditions': [
        ['OS=="win"', {
          'link_settings': {
            'libraries': [ '-lws2_32.lib', '-lRpcrt4.lib' ],
          },
       }],
        ['OS=="android"', {
          'link_settings': {
            'libraries': [ '-llog' ],
          },
       }]
      ],
    },
    {
      # Generate snapshot bin file.
      'target_name': 'generate_snapshot_bin',
      'type': 'none',
      'dependencies': [
        'gen_snapshot',
      ],
      'actions': [
        {
          'action_name': 'generate_snapshot_bin',
          'inputs': [
            '../tools/create_snapshot_bin.py',
            '<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)gen_snapshot<(EXECUTABLE_SUFFIX)',
          ],
          'outputs': [
            '<(snapshot_bin_file)',
          ],
          'action': [
            'python',
            'tools/create_snapshot_bin.py',
            '--executable',
            '<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)gen_snapshot<(EXECUTABLE_SUFFIX)',
            '--output_bin', '<(snapshot_bin_file)',
            '--target_os', '<(OS)'
          ],
          'message': 'Generating ''<(snapshot_bin_file)'' file.'
        },
      ],
    },
    {
      # Generate snapshot file.
      'target_name': 'generate_snapshot_file',
      'type': 'none',
      'dependencies': [
        'generate_snapshot_bin',
      ],
      'actions': [
        {
          'action_name': 'generate_snapshot_file',
          'inputs': [
            '../tools/create_snapshot_file.py',
            '<(snapshot_in_cc_file)',
            '<(snapshot_bin_file)'
          ],
          'outputs': [
            '<(snapshot_cc_file)',
          ],
          'action': [
            'python',
            'tools/create_snapshot_file.py',
            '--input_bin', '<(snapshot_bin_file)',
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
        'libdart_io',
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
            'libraries': [ '-lws2_32.lib', '-lRpcrt4.lib', '-lwinmm.lib' ],
          },
          # Generate an import library on Windows, by exporting a function.
          # Extensions use this import library to link to the API in dart.exe.
          'msvs_settings': {
            'VCLinkerTool': {
              'AdditionalOptions': [ '/EXPORT:Dart_True' ],
            },
          },
        }],
        ['OS=="linux"', {
          # Have the linker add all symbols to the dynamic symbol table
          # so that extensions can look them up dynamically in the binary.
          'ldflags': [
            '-rdynamic',
          ],
        }],
      ],
    },
    {
      # dart binary without any snapshot built in.
      'target_name': 'dart_no_snapshot',
      'type': 'executable',
      'dependencies': [
        'libdart_withcore',
        'libdart_builtin',
        'libdart_io',
      ],
      'include_dirs': [
        '..',
      ],
      'sources': [
        'main.cc',
        'builtin.cc',
        # Include generated source files.
        '<(builtin_cc_file)',
        '<(crypto_cc_file)',
        '<(io_cc_file)',
        '<(io_patch_cc_file)',
        '<(json_cc_file)',
        '<(uri_cc_file)',
        '<(utf_cc_file)',
        'snapshot_empty.cc',
      ],
      'conditions': [
        ['OS=="win"', {
          'link_settings': {
            'libraries': [ '-lws2_32.lib', '-lRpcrt4.lib', '-lwinmm.lib' ],
          },
          # Generate an import library on Windows, by exporting a function.
          # Extensions use this import library to link to the API in dart.exe.
          'msvs_settings': {
            'VCLinkerTool': {
              'AdditionalOptions': [ '/EXPORT:Dart_True' ],
            },
          },
        }],
        ['OS=="linux"', {
          # Have the linker add all symbols to the dynamic symbol table
          # so that extensions can look them up dynamically in the binary.
          'ldflags': [
            '-rdynamic',
          ],
        }],
      ],
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
        'libdart_io',
        'generate_snapshot_test_dat_file',
      ],
      'include_dirs': [
        '..',
        '<(SHARED_INTERMEDIATE_DIR)',
      ],
      'sources': [
        'run_vm_tests.cc',
        'builtin.cc',
        # Include generated source files.
        '<(builtin_cc_file)',
        '<(crypto_cc_file)',
        '<(io_cc_file)',
        '<(io_patch_cc_file)',
        '<(json_cc_file)',
        '<(uri_cc_file)',
        '<(utf_cc_file)',
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
        ['include', 'run_vm_tests.cc'],
        ['include', 'builtin.cc'],
        ['include', '_gen\\.cc$'],
        ['include', '_test\\.(cc|h)$'],
      ],
      'conditions': [
        ['OS=="win"', {
          'link_settings': {
            'libraries': [ '-lws2_32.lib', '-lRpcrt4.lib', '-lwinmm.lib' ],
          },
        }],
      ],
    },
    {
      'target_name': 'test_extension',
      'type': 'shared_library',
      'dependencies': [
        'dart',
      ],
      'include_dirs': [
        '..',
      ],
      'sources': [
        'test_extension.cc',
        'test_extension_dllmain_win.cc',
      ],
      'defines': [
        # The only effect of DART_SHARED_LIB is to export the Dart API entries.
        'DART_SHARED_LIB',
      ],
      'conditions': [
        ['OS=="win"', {
          'msvs_settings': {
            'VCLinkerTool': {
              'AdditionalDependencies': [ 'dart.lib' ],
              'AdditionalLibraryDirectories': [ '<(PRODUCT_DIR)' ],
            },
          },
        }],
        ['OS=="mac"', {
          'xcode_settings': {
            'OTHER_LDFLAGS': [ '-undefined', 'dynamic_lookup' ],
          },
        }],
      ],
    },
  ],
}

