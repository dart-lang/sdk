# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

{
  'variables': {
    # We place most generated source files in LIB_DIR (rather than, say
    # SHARED_INTERMEDIATE_DIR) because it is toolset specific. This avoids
    # two problems. First, if a generated source file has architecture specific
    # code, we'll get two different files in two different directories. Second,
    # if a generated source file is needed to build a target with multiple
    # toolsets, we avoid having duplicate Makefile targets.
    'gen_source_dir': '<(LIB_DIR)',

    'io_cc_file': '<(gen_source_dir)/io_gen.cc',
    'io_patch_cc_file': '<(gen_source_dir)/io_patch_gen.cc',
    'builtin_in_cc_file': 'builtin_in.cc',
    'builtin_cc_file': '<(gen_source_dir)/builtin_gen.cc',
    'snapshot_in_cc_file': 'snapshot_in.cc',
    'snapshot_bin_file': '<(gen_source_dir)/snapshot_gen.bin',
    'resources_cc_file': '<(gen_source_dir)/resources_gen.cc',

    # The program that creates snapshot_gen.cc is only built and run on the
    # host, but it must be available when dart is built for the target. Thus,
    # we keep it in a shared location.
    'snapshot_cc_file': '<(SHARED_INTERMEDIATE_DIR)/snapshot_gen.cc',
  },
  'targets': [
    {
      'target_name': 'generate_builtin_cc_file',
      'type': 'none',
      'toolsets':['target','host'],
      'includes': [
        'builtin_sources.gypi',
      ],
      'actions': [
        {
          'action_name': 'generate_builtin_cc',
          'inputs': [
            '../tools/gen_library_src_paths.py',
            '<(builtin_in_cc_file)',
            '<@(_sources)',
          ],
          'outputs': [
            '<(builtin_cc_file)',
          ],
          'action': [
            'python',
            'tools/gen_library_src_paths.py',
            '--output', '<(builtin_cc_file)',
            '--input_cc', '<(builtin_in_cc_file)',
            '--include', 'bin/builtin.h',
            '--var_name', 'dart::bin::Builtin::builtin_source_paths_',
            '--library_name', 'dart:builtin',
            '<@(_sources)',
          ],
          'message': 'Generating ''<(builtin_cc_file)'' file.'
        },
      ]
    },
    {
      'target_name': 'generate_io_cc_file',
      'type': 'none',
      'toolsets':['target','host'],
      'sources': [
        '../../sdk/lib/io/io.dart',
      ],
      'includes': [
        '../../sdk/lib/io/iolib_sources.gypi',
      ],
      'actions': [
        {
          'action_name': 'generate_io_cc',
          'inputs': [
            '../tools/gen_library_src_paths.py',
            '<(builtin_in_cc_file)',
            '<@(_sources)',
          ],
          'outputs': [
            '<(io_cc_file)',
          ],
          'action': [
            'python',
            'tools/gen_library_src_paths.py',
            '--output', '<(io_cc_file)',
            '--input_cc', '<(builtin_in_cc_file)',
            '--include', 'bin/builtin.h',
            '--var_name', 'dart::bin::Builtin::io_source_paths_',
            '--library_name', 'dart:io',
            '<@(_sources)',
          ],
          'message': 'Generating ''<(io_cc_file)'' file.'
        },
      ]
    },
    {
      'target_name': 'generate_io_patch_cc_file',
      'type': 'none',
      'toolsets':['target','host'],
      'includes': [
        'io_sources.gypi',
      ],
      'actions': [
        {
          'action_name': 'generate_io_patch_cc',
          'inputs': [
            '../tools/gen_library_src_paths.py',
            '<(builtin_in_cc_file)',
            '<@(_sources)',
          ],
          'outputs': [
            '<(io_patch_cc_file)',
          ],
          'action': [
            'python',
            'tools/gen_library_src_paths.py',
            '--output', '<(io_patch_cc_file)',
            '--input_cc', '<(builtin_in_cc_file)',
            '--include', 'bin/builtin.h',
            '--var_name', 'dart::bin::Builtin::io_patch_paths_',
            '--library_name', 'dart:io',
            '<@(_sources)',
          ],
          'message': 'Generating ''<(io_patch_cc_file)'' file.'
        },
      ]
    },
    {
      'target_name': 'libdart_builtin',
      'type': 'static_library',
      'toolsets':['target','host'],
      'dependencies': [
        'generate_builtin_cc_file',
        'generate_io_cc_file',
        'generate_io_patch_cc_file',
      ],
      'include_dirs': [
        '..',
      ],
      'sources': [
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
      'toolsets':['target', 'host'],
      'include_dirs': [
        '..',
      ],
      'sources': [
        'io_natives.h',
        'io_natives.cc',
      ],
      'conditions': [
        [ 'dart_io_support==1', {
          'dependencies': [
            'bin/net/ssl.gyp:libssl_dart',
          ],
          'includes': [
            'io_impl_sources.gypi',
          ],
        },
        {
          'includes': [
            'io_impl_sources_no_nss.gypi',
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
      'toolsets':['target','host'],
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
      'toolsets':['host'],
      'dependencies': [
        'libdart_withcore',
        'libdart_builtin',
      ],
      'include_dirs': [
        '..',
      ],
      'sources': [
        'gen_snapshot.cc',
        # Very limited native resolver provided.
        'builtin_gen_snapshot.cc',
        'builtin.cc',
        'builtin.h',
        # Include generated source files.
        '<(builtin_cc_file)',
        '<(io_cc_file)',
        '<(io_patch_cc_file)',
      ],
      'conditions': [
        ['OS=="win"', {
          'link_settings': {
            'libraries': [ '-lws2_32.lib', '-lRpcrt4.lib' ],
          },
       }],
        ['OS=="android"', {
          'link_settings': {
            'libraries': [ '-ldl', '-lrt' ],
          },
       }]
      ],
    },
    {
      # Generate snapshot bin file.
      'target_name': 'generate_snapshot_bin',
      'type': 'none',
      'toolsets':['host'],
      'dependencies': [
        'gen_snapshot#host',
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
      'toolsets':['host'],
      'dependencies': [
        'generate_snapshot_bin#host',
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
      'target_name': 'generate_resources_cc_file',
      'type': 'none',
      'toolsets':['target', 'host'],
      'includes': [
        'vmstats_sources.gypi',
      ],
      'actions': [
        {
          'action_name': 'generate_resources_cc',
          'inputs': [
            '../tools/create_resources.py',
            '<@(_sources)',
          ],
          'outputs': [
            '<(resources_cc_file)',
          ],
          'action': [
            'python',
            'tools/create_resources.py',
            '--output', '<(resources_cc_file)',
            '--root_prefix', 'bin/vmstats/',
            '<@(_sources)',
          ],
          'message': 'Generating ''<(resources_cc_file)'' file.'
        },
      ]
    },
    {
      # dart binary with a snapshot of corelibs built in.
      'target_name': 'dart',
      'type': 'executable',
      'toolsets':['target'],
      'dependencies': [
        'libdart',
        'libdart_builtin',
        'libdart_io',
        'generate_snapshot_file#host',
        'generate_resources_cc_file#host',
      ],
      'include_dirs': [
        '..',
      ],
      'sources': [
        'main.cc',
        'builtin_natives.cc',
        'builtin_nolib.cc',
        'builtin.h',
        'io_natives.h',
        'resources.h',
        'vmstats.h',
        'vmstats_impl.cc',
        'vmstats_impl.h',
        'vmstats_impl_android.cc',
        'vmstats_impl_linux.cc',
        'vmstats_impl_macos.cc',
        'vmstats_impl_win.cc',
        '<(snapshot_cc_file)',
        '<(resources_cc_file)',
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
        ['OS=="android"', {
          'link_settings': {
            'ldflags': [
              '-z',
              'muldefs',
            ],
            'ldflags!': [
              '-Wl,--exclude-libs=ALL,-shared',
            ],
            'libraries': [
              '-llog',
              '-lc',
              '-lz',
            ],
          },
        }],
      ],
    },
    {
      # dart binary without any snapshot built in.
      'target_name': 'dart_no_snapshot',
      'type': 'executable',
      'toolsets':['target'],
      'dependencies': [
        'libdart_withcore',
        'libdart_builtin',
        'libdart_io',
        'generate_resources_cc_file#host',
      ],
      'include_dirs': [
        '..',
      ],
      'sources': [
        'main.cc',
        'builtin.cc',
        'builtin_natives.cc',
        'builtin.h',
        'io_natives.h',
        'resources.h',
        'vmstats.h',
        'vmstats_impl.cc',
        'vmstats_impl.h',
        'vmstats_impl_android.cc',
        'vmstats_impl_linux.cc',
        'vmstats_impl_macos.cc',
        'vmstats_impl_win.cc',
        # Include generated source files.
        '<(builtin_cc_file)',
        '<(io_cc_file)',
        '<(io_patch_cc_file)',
        '<(resources_cc_file)',
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

        ['OS=="android"', {
          'link_settings': {
            'ldflags': [
              '-z',
              'muldefs',
            ],
            'ldflags!': [
              '-Wl,--exclude-libs=ALL,-shared',
            ],
            'libraries': [
              '-llog',
              '-lc',
              '-lz',
            ],
          },
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
      'toolsets':['target'],
      'dependencies': [
        'libdart_withcore',
        'libdart_builtin',
        'libdart_io',
        'generate_snapshot_file#host',
        'generate_snapshot_test_dat_file',
      ],
      'include_dirs': [
        '..',
        '<(gen_source_dir)',
      ],
      'sources': [
        'run_vm_tests.cc',
        'builtin_natives.cc',
        'builtin_nolib.cc',
        'builtin.h',
        'io_natives.h',
        # Include generated source files.
        '<(snapshot_cc_file)',
        '<(builtin_cc_file)',
        '<(io_cc_file)',
        '<(io_patch_cc_file)',
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
        ['include', 'builtin_nolib.cc'],
        ['include', 'builtin_natives.cc'],
        ['include', '_gen\\.cc$'],
        ['include', '_test\\.(cc|h)$'],
      ],
      'conditions': [
        ['OS=="win"', {
          'link_settings': {
            'libraries': [ '-lws2_32.lib', '-lRpcrt4.lib', '-lwinmm.lib' ],
          },
        }],
        ['OS=="android"', {

          'link_settings': {
            'ldflags': [
              '-z',
              'muldefs',
            ],
            'ldflags!': [
              '-Wl,--exclude-libs=ALL,-shared',
            ],
            'libraries': [
              '-Wl,--start-group',
              '-Wl,--end-group',
              '-llog',
              '-lc',
              '-lz',
            ],
          },
        }],
      ],
    },
    {
      'target_name': 'run_vm_tests.host',
      'type': 'executable',
      'toolsets':['host'],
      'dependencies': [
        'libdart_withcore',
        'libdart_builtin',
        'libdart_io',
        'generate_snapshot_file#host',
        'generate_snapshot_test_dat_file',
      ],
      'include_dirs': [
        '..',
        '<(gen_source_dir)',
      ],
      'sources': [
        'run_vm_tests.cc',
        'builtin_natives.cc',
        'builtin_nolib.cc',
        'builtin.h',
        'io_natives.h',
        # Include generated source files.
        '<(snapshot_cc_file)',
        '<(builtin_cc_file)',
        '<(io_cc_file)',
        '<(io_patch_cc_file)',
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
        ['include', 'builtin_nolib.cc'],
        ['include', 'builtin_natives.cc'],
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
  ],
  'conditions': [
    ['OS!="android"', {
      'targets': [
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
            # The only effect of DART_SHARED_LIB is to export the Dart API.
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
            ['OS=="linux"', {
              'cflags': [
                '-fPIC',
              ],
            }],
          ],
        },
      ],
    }],
  ],
}

