# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

{
  'includes': [
    'tools/gyp/runtime-configurations.gypi',
    'vm/vm.gypi',
    'observatory/observatory.gypi',
    'bin/bin.gypi',
    'third_party/double-conversion/src/double-conversion.gypi',
  ],
  'variables': {
    'gen_source_dir': '<(SHARED_INTERMEDIATE_DIR)',
    'version_in_cc_file': 'vm/version_in.cc',
    'version_cc_file': '<(gen_source_dir)/version.cc',

    'libdart_deps': ['libdart_lib_nosnapshot', 'libdart_lib',
                     'libdart_vm_nosnapshot', 'libdart_vm',
                     'libdouble_conversion',],
  },
  'targets': [
    {
      'target_name': 'libdart',
      'type': 'static_library',
      'dependencies': [
        'libdart_lib',
        'libdart_vm',
        'libdouble_conversion',
        'generate_version_cc_file#host',
      ],
      'include_dirs': [
        '.',
      ],
      'sources': [
        'include/dart_api.h',
        'include/dart_mirrors_api.h',
        'include/dart_native_api.h',
        'include/dart_tools_api.h',
        'vm/dart_api_impl.cc',
        'vm/debugger_api_impl.cc',
        'vm/mirrors_api_impl.cc',
        'vm/native_api_impl.cc',
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
      'target_name': 'libdart_precompiled_runtime',
      'type': 'static_library',
      'dependencies': [
        'libdart_lib_precompiled_runtime',
        'libdart_vm_precompiled_runtime',
        'libdouble_conversion',
        'generate_version_cc_file#host',
      ],
      'include_dirs': [
        '.',
      ],
      'sources': [
        'include/dart_api.h',
        'include/dart_mirrors_api.h',
        'include/dart_native_api.h',
        'include/dart_tools_api.h',
        'vm/dart_api_impl.cc',
        'vm/debugger_api_impl.cc',
        'vm/mirrors_api_impl.cc',
        'vm/native_api_impl.cc',
        'vm/version.h',
        '<(version_cc_file)',
      ],
      'defines': [
        # The only effect of DART_SHARED_LIB is to export the Dart API entries.
        'DART_SHARED_LIB',
        'DART_PRECOMPILED_RUNTIME',
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
      'toolsets':['host'],
      'dependencies': [
        'libdart_dependency_helper.target#target',
        'libdart_dependency_helper.host#host',
      ],
      'actions': [
        {
          'action_name': 'generate_version_cc',
          'inputs': [
            '../tools/make_version.py',
            '../tools/utils.py',
            '../tools/print_version.py',
            '../tools/VERSION',
            '<(version_in_cc_file)',
            # Depend on libdart_dependency_helper to track the libraries it
            # depends on.
            '<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)libdart_dependency_helper.target<(EXECUTABLE_SUFFIX)',
            '<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)libdart_dependency_helper.host<(EXECUTABLE_SUFFIX)',
          ],
          'outputs': [
            '<(version_cc_file)',
          ],
          'action': [
            'python',
            '-u', # Make standard I/O unbuffered.
            '../tools/make_version.py',
            '--output', '<(version_cc_file)',
            '--input', '<(version_in_cc_file)',
          ],
        },
      ],
    },
    {
      'target_name': 'libdart_dependency_helper.target',
      'type': 'executable',
      'toolsets':['target'],
      # The dependencies here are the union of the dependencies of libdart and
      # libdart_nosnapshot.
      'dependencies': ['<@(libdart_deps)'],
      'sources': [
        'vm/libdart_dependency_helper.cc',
      ],
    },
    {
      'target_name': 'libdart_dependency_helper.host',
      'type': 'executable',
      'toolsets':['host'],
      # The dependencies here are the union of the dependencies of libdart and
      # libdart_nosnapshot.
      'dependencies': ['<@(libdart_deps)'],
      'sources': [
        'vm/libdart_dependency_helper.cc',
      ],
    },
    # Targets coming from dart/dart.gyp.
    {
      'target_name': 'runtime_all',
      'type': 'none',
      'dependencies': [
        'sample_extension',
      ],
    },
    {
      'target_name': 'sample_extension',
      'type': 'shared_library',
      'dependencies': [
        'dart',
      ],
      'include_dirs': [
        '.',
      ],
      'sources': [
        '../samples/sample_extension/sample_extension.cc',
        '../samples/sample_extension/sample_extension_dllmain_win.cc',
      ],
      'defines': [
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
            'OTHER_LDFLAGS': [
              '-undefined',
              'dynamic_lookup',
            ],
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
}
