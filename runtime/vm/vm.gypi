# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

{
  'variables': {
    'gen_source_dir': '<(SHARED_INTERMEDIATE_DIR)',
    'libgen_in_cc_file': '../lib/libgen_in.cc',
    'builtin_in_cc_file': '../bin/builtin_in.cc',
    'async_cc_file': '<(gen_source_dir)/async_gen.cc',
    'async_patch_cc_file': '<(gen_source_dir)/async_patch_gen.cc',
    'core_cc_file': '<(gen_source_dir)/core_gen.cc',
    'core_patch_cc_file': '<(gen_source_dir)/core_patch_gen.cc',
    'collection_cc_file': '<(gen_source_dir)/collection_gen.cc',
    'collection_patch_cc_file': '<(gen_source_dir)/collection_patch_gen.cc',
    'convert_cc_file': '<(gen_source_dir)/convert_gen.cc',
    'convert_patch_cc_file': '<(gen_source_dir)/convert_patch_gen.cc',
    'developer_cc_file': '<(gen_source_dir)/developer_gen.cc',
    'developer_patch_cc_file': '<(gen_source_dir)/developer_patch_gen.cc',
    'internal_cc_file': '<(gen_source_dir)/internal_gen.cc',
    'internal_patch_cc_file': '<(gen_source_dir)/internal_patch_gen.cc',
    'isolate_cc_file': '<(gen_source_dir)/isolate_gen.cc',
    'isolate_patch_cc_file': '<(gen_source_dir)/isolate_patch_gen.cc',
    'math_cc_file': '<(gen_source_dir)/math_gen.cc',
    'math_patch_cc_file': '<(gen_source_dir)/math_patch_gen.cc',
    'mirrors_cc_file': '<(gen_source_dir)/mirrors_gen.cc',
    'mirrors_patch_cc_file': '<(gen_source_dir)/mirrors_patch_gen.cc',
    'profiler_cc_file': '<(gen_source_dir)/profiler_gen.cc',
    'snapshot_test_dat_file': '<(gen_source_dir)/snapshot_test.dat',
    'snapshot_test_in_dat_file': 'snapshot_test_in.dat',
    'snapshot_test_dart_file': 'snapshot_test.dart',
    'typed_data_cc_file': '<(gen_source_dir)/typed_data_gen.cc',
    'typed_data_patch_cc_file': '<(gen_source_dir)/typed_data_patch_gen.cc',
    'vmservice_cc_file': '<(gen_source_dir)/vmservice_gen.cc',
    'vmservice_patch_cc_file': '<(gen_source_dir)/vmservice_patch_gen.cc',
  },
  'targets': [
    {
      'target_name': 'libdart_vm',
      'type': 'static_library',
      'toolsets':['host', 'target'],
      'includes': [
        'vm_sources.gypi',
        '../platform/platform_headers.gypi',
        '../platform/platform_sources.gypi',
      ],
      'sources/': [
        # Exclude all _test.[cc|h] files.
        ['exclude', '_test\\.(cc|h)$'],
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
              '-ldl',
            ],
          },
        }],
        ['OS=="android" and _toolset=="host"', {
          'link_settings': {
            'libraries': [
              '-lpthread',
              '-lrt',
              '-ldl',
            ],
          },
        }],
        ['OS=="win"', {
          'sources/' : [
            ['exclude', 'gdbjit.cc'],
          ],
       }]],
    },
    {
      'target_name': 'libdart_vm_precompiled_runtime',
      'type': 'static_library',
      'toolsets':['host', 'target'],
      'includes': [
        'vm_sources.gypi',
        '../platform/platform_headers.gypi',
        '../platform/platform_sources.gypi',
      ],
      'sources/': [
        # Exclude all _test.[cc|h] files.
        ['exclude', '_test\\.(cc|h)$'],
      ],
      'include_dirs': [
        '..',
      ],
      'defines': [
        'DART_PRECOMPILED_RUNTIME',
      ],
      'conditions': [
        ['OS=="linux"', {
          'link_settings': {
            'libraries': [
              '-lpthread',
              '-lrt',
              '-ldl',
            ],
          },
        }],
        ['OS=="android" and _toolset=="host"', {
          'link_settings': {
            'libraries': [
              '-lpthread',
              '-lrt',
              '-ldl',
            ],
          },
        }],
        ['OS=="win"', {
          'sources/' : [
            ['exclude', 'gdbjit.cc'],
          ],
       }]],
    },
    {
      'target_name': 'libdart_vm_noopt',
      'type': 'static_library',
      'toolsets':['host', 'target'],
      'includes': [
        'vm_sources.gypi',
        '../platform/platform_headers.gypi',
        '../platform/platform_sources.gypi',
      ],
      'sources/': [
        # Exclude all _test.[cc|h] files.
        ['exclude', '_test\\.(cc|h)$'],
      ],
      'include_dirs': [
        '..',
      ],
      'defines': [
        'DART_PRECOMPILER',
      ],
      'conditions': [
        ['OS=="linux"', {
          'link_settings': {
            'libraries': [
              '-lpthread',
              '-lrt',
              '-ldl',
            ],
          },
        }],
        ['OS=="android" and _toolset=="host"', {
          'link_settings': {
            'libraries': [
              '-lpthread',
              '-lrt',
              '-ldl',
            ],
          },
        }],
        ['OS=="win"', {
          'sources/' : [
            ['exclude', 'gdbjit.cc'],
          ],
       }]],
    },
    {
      'target_name': 'libdart_vm_nosnapshot',
      'type': 'static_library',
      'toolsets':['host', 'target'],
      'includes': [
        'vm_sources.gypi',
        '../platform/platform_headers.gypi',
        '../platform/platform_sources.gypi',
      ],
      'sources/': [
        # Exclude all _test.[cc|h] files.
        ['exclude', '_test\\.(cc|h)$'],
      ],
      'include_dirs': [
        '..',
      ],
      'defines': [
        'DART_NO_SNAPSHOT',
        'DART_PRECOMPILER',
      ],
      'conditions': [
        ['OS=="linux"', {
          'link_settings': {
            'libraries': [
              '-lpthread',
              '-lrt',
              '-ldl',
            ],
          },
        }],
        ['OS=="android" and _toolset=="host"', {
          'link_settings': {
            'libraries': [
              '-lpthread',
              '-lrt',
              '-ldl',
            ],
          },
        }],
        ['OS=="win"', {
          'sources/' : [
            ['exclude', 'gdbjit.cc'],
          ],
       }]],
    },
    {
      'target_name': 'libdart_lib_nosnapshot',
      'type': 'static_library',
      'toolsets':['host', 'target'],
      'dependencies': [
        'generate_async_cc_file#host',
        'generate_async_patch_cc_file#host',
        'generate_core_cc_file#host',
        'generate_core_patch_cc_file#host',
        'generate_collection_cc_file#host',
        'generate_collection_patch_cc_file#host',
        'generate_convert_cc_file#host',
        'generate_convert_patch_cc_file#host',
        'generate_developer_cc_file#host',
        'generate_developer_patch_cc_file#host',
        'generate_internal_cc_file#host',
        'generate_internal_patch_cc_file#host',
        'generate_isolate_cc_file#host',
        'generate_isolate_patch_cc_file#host',
        'generate_math_cc_file#host',
        'generate_math_patch_cc_file#host',
        'generate_mirrors_cc_file#host',
        'generate_mirrors_patch_cc_file#host',
        'generate_profiler_cc_file#host',
        'generate_typed_data_cc_file#host',
        'generate_typed_data_patch_cc_file#host',
        'generate_vmservice_cc_file#host',
        'generate_vmservice_patch_cc_file#host',
      ],
      'includes': [
        '../lib/async_sources.gypi',
        '../lib/collection_sources.gypi',
        '../lib/core_sources.gypi',
        '../lib/developer_sources.gypi',
        '../lib/internal_sources.gypi',
        '../lib/isolate_sources.gypi',
        '../lib/math_sources.gypi',
        '../lib/mirrors_sources.gypi',
        '../lib/typed_data_sources.gypi',
        '../lib/vmservice_sources.gypi',
      ],
      'sources': [
        'bootstrap.cc',
        # Include generated source files.
        '<(async_cc_file)',
        '<(async_patch_cc_file)',
        '<(core_cc_file)',
        '<(core_patch_cc_file)',
        '<(collection_cc_file)',
        '<(collection_patch_cc_file)',
        '<(convert_cc_file)',
        '<(convert_patch_cc_file)',
        '<(developer_cc_file)',
        '<(developer_patch_cc_file)',
        '<(internal_cc_file)',
        '<(internal_patch_cc_file)',
        '<(isolate_cc_file)',
        '<(isolate_patch_cc_file)',
        '<(math_cc_file)',
        '<(math_patch_cc_file)',
        '<(mirrors_cc_file)',
        '<(mirrors_patch_cc_file)',
        '<(profiler_cc_file)',
        '<(typed_data_cc_file)',
        '<(typed_data_patch_cc_file)',
        '<(vmservice_cc_file)',
        '<(vmservice_patch_cc_file)',
      ],
      'include_dirs': [
        '..',
      ],
    },
    {
      'target_name': 'libdart_lib',
      'type': 'static_library',
      'toolsets':['host', 'target'],
      'includes': [
        '../lib/async_sources.gypi',
        '../lib/collection_sources.gypi',
        '../lib/core_sources.gypi',
        '../lib/developer_sources.gypi',
        '../lib/internal_sources.gypi',
        '../lib/isolate_sources.gypi',
        '../lib/math_sources.gypi',
        '../lib/mirrors_sources.gypi',
        '../lib/typed_data_sources.gypi',
        '../lib/vmservice_sources.gypi',
      ],
      'sources': [
        'bootstrap_nocore.cc',
      ],
      'include_dirs': [
        '..',
      ],
    },
    {
      'target_name': 'libdart_lib_precompiled_runtime',
      'type': 'static_library',
      'toolsets':['host', 'target'],
      'includes': [
        '../lib/async_sources.gypi',
        '../lib/collection_sources.gypi',
        '../lib/core_sources.gypi',
        '../lib/developer_sources.gypi',
        '../lib/internal_sources.gypi',
        '../lib/isolate_sources.gypi',
        '../lib/math_sources.gypi',
        '../lib/mirrors_sources.gypi',
        '../lib/typed_data_sources.gypi',
        '../lib/vmservice_sources.gypi',
      ],
      'sources': [
        'bootstrap_nocore.cc',
      ],
      'defines': [
        'DART_PRECOMPILED_RUNTIME',
      ],
      'include_dirs': [
        '..',
      ],
    },
    {
      'target_name': 'generate_async_cc_file',
      'type': 'none',
      'toolsets':['host'],
      'includes': [
        '../../sdk/lib/async/async_sources.gypi',
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
          'action_name': 'generate_async_cc',
          'inputs': [
            '../tools/gen_library_src_paths.py',
            '<(libgen_in_cc_file)',
            '<@(_sources)',
          ],
          'outputs': [
            '<(async_cc_file)',
          ],
          'action': [
            'python',
            'tools/gen_library_src_paths.py',
            '--output', '<(async_cc_file)',
            '--input_cc', '<(libgen_in_cc_file)',
            '--include', 'vm/bootstrap.h',
            '--var_name', 'dart::Bootstrap::async_source_paths_',
            '--library_name', 'dart:async',
            '<@(_sources)',
          ],
          'message': 'Generating ''<(async_cc_file)'' file.'
        },
      ]
    },
    {
      'target_name': 'generate_async_patch_cc_file',
      'type': 'none',
      'toolsets':['host'],
      'includes': [
        # Load the runtime implementation sources.
        '../lib/async_sources.gypi',
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
          'action_name': 'generate_async_patch_cc',
          'inputs': [
            '../tools/gen_library_src_paths.py',
            '<(libgen_in_cc_file)',
            '<@(_sources)',
          ],
          'outputs': [
            '<(async_patch_cc_file)',
          ],
          'action': [
            'python',
            'tools/gen_library_src_paths.py',
            '--output', '<(async_patch_cc_file)',
            '--input_cc', '<(libgen_in_cc_file)',
            '--include', 'vm/bootstrap.h',
            '--var_name', 'dart::Bootstrap::async_patch_paths_',
            '--library_name', 'dart:async',
            '<@(_sources)',
          ],
          'message': 'Generating ''<(async_patch_cc_file)'' file.'
        },
      ]
    },
    {
      'target_name': 'generate_collection_cc_file',
      'type': 'none',
      'toolsets':['host'],
      'includes': [
        # Load the shared collection library sources.
        '../../sdk/lib/collection/collection_sources.gypi',
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
          'action_name': 'generate_collection_cc',
          'inputs': [
            '../tools/gen_library_src_paths.py',
            '<(libgen_in_cc_file)',
            '<@(_sources)',
          ],
          'outputs': [
            '<(collection_cc_file)',
          ],
          'action': [
            'python',
            'tools/gen_library_src_paths.py',
            '--output', '<(collection_cc_file)',
            '--input_cc', '<(libgen_in_cc_file)',
            '--include', 'vm/bootstrap.h',
            '--var_name', 'dart::Bootstrap::collection_source_paths_',
            '--library_name', 'dart:collection',
            '<@(_sources)',
          ],
          'message': 'Generating ''<(collection_cc_file)'' file.'
        },
      ]
    },
    {
      'target_name': 'generate_collection_patch_cc_file',
      'type': 'none',
      'toolsets':['host'],
      'includes': [
        # Load the runtime implementation sources.
        '../lib/collection_sources.gypi',
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
          'action_name': 'generate_collection_patch_cc',
          'inputs': [
            '../tools/gen_library_src_paths.py',
            '<(libgen_in_cc_file)',
            '<@(_sources)',
          ],
          'outputs': [
            '<(collection_patch_cc_file)',
          ],
          'action': [
            'python',
            'tools/gen_library_src_paths.py',
            '--output', '<(collection_patch_cc_file)',
            '--input_cc', '<(libgen_in_cc_file)',
            '--include', 'vm/bootstrap.h',
            '--var_name', 'dart::Bootstrap::collection_patch_paths_',
            '--library_name', 'dart:collection',
            '<@(_sources)',
          ],
          'message': 'Generating ''<(collection_patch_cc_file)'' file.'
        },
      ]
    },
    {
      'target_name': 'generate_convert_cc_file',
      'type': 'none',
      'toolsets':['host'],
      'includes': [
        # Load the shared convert library sources.
        '../../sdk/lib/convert/convert_sources.gypi',
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
          'action_name': 'generate_convert_cc',
          'inputs': [
            '../tools/gen_library_src_paths.py',
            '<(libgen_in_cc_file)',
            '<@(_sources)',
          ],
          'outputs': [
            '<(convert_cc_file)',
          ],
          'action': [
            'python',
            'tools/gen_library_src_paths.py',
            '--output', '<(convert_cc_file)',
            '--input_cc', '<(libgen_in_cc_file)',
            '--include', 'vm/bootstrap.h',
            '--var_name', 'dart::Bootstrap::convert_source_paths_',
            '--library_name', 'dart:convert',
            '<@(_sources)',
          ],
          'message': 'Generating ''<(convert_cc_file)'' file.'
        },
      ]
    },
    {
      'target_name': 'generate_convert_patch_cc_file',
      'type': 'none',
      'toolsets':['host'],
      'includes': [
        # Load the shared convert library sources.
        '../lib/convert_sources.gypi',
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
          'action_name': 'generate_convert_patch_cc',
          'inputs': [
            '../tools/gen_library_src_paths.py',
            '<(libgen_in_cc_file)',
            '<@(_sources)',
          ],
          'outputs': [
            '<(convert_patch_cc_file)',
          ],
          'action': [
            'python',
            'tools/gen_library_src_paths.py',
            '--output', '<(convert_patch_cc_file)',
            '--input_cc', '<(libgen_in_cc_file)',
            '--include', 'vm/bootstrap.h',
            '--var_name', 'dart::Bootstrap::convert_patch_paths_',
            '--library_name', 'dart:convert',
            '<@(_sources)',
          ],
          'message': 'Generating ''<(convert_patch_cc_file)'' file.'
        },
      ]
    },
    {
      'target_name': 'generate_core_cc_file',
      'type': 'none',
      'toolsets':['host'],
      'includes': [
        # Load the shared core library sources.
        '../../sdk/lib/core/core_sources.gypi',
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
          'action_name': 'generate_core_cc',
          'inputs': [
            '../tools/gen_library_src_paths.py',
            '<(libgen_in_cc_file)',
            '<@(_sources)',
          ],
          'outputs': [
            '<(core_cc_file)',
          ],
          'action': [
            'python',
            'tools/gen_library_src_paths.py',
            '--output', '<(core_cc_file)',
            '--input_cc', '<(libgen_in_cc_file)',
            '--include', 'vm/bootstrap.h',
            '--var_name', 'dart::Bootstrap::core_source_paths_',
            '--library_name', 'dart:core',
            '<@(_sources)',
          ],
          'message': 'Generating ''<(core_cc_file)'' file.'
        },
      ]
    },
    {
      'target_name': 'generate_core_patch_cc_file',
      'type': 'none',
      'toolsets':['host'],
      'includes': [
        # Load the runtime implementation sources.
        '../lib/core_sources.gypi',
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
          'action_name': 'generate_core_patch_cc',
          'inputs': [
            '../tools/gen_library_src_paths.py',
            '<(libgen_in_cc_file)',
            '<@(_sources)',
          ],
          'outputs': [
            '<(core_patch_cc_file)',
          ],
          'action': [
            'python',
            'tools/gen_library_src_paths.py',
            '--output', '<(core_patch_cc_file)',
            '--input_cc', '<(libgen_in_cc_file)',
            '--include', 'vm/bootstrap.h',
            '--var_name', 'dart::Bootstrap::core_patch_paths_',
            '--library_name', 'dart:core',
            '<@(_sources)',
          ],
          'message': 'Generating ''<(core_patch_cc_file)'' file.'
        },
      ]
    },
    {
      'target_name': 'generate_internal_patch_cc_file',
      'type': 'none',
      'toolsets':['host'],
      'includes': [
        # Load the runtime implementation sources.
        '../lib/internal_sources.gypi',
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
          'action_name': 'generate_internal_patch_cc',
          'inputs': [
            '../tools/gen_library_src_paths.py',
            '<(libgen_in_cc_file)',
            '<@(_sources)',
          ],
          'outputs': [
            '<(internal_patch_cc_file)',
          ],
          'action': [
            'python',
            'tools/gen_library_src_paths.py',
            '--output', '<(internal_patch_cc_file)',
            '--input_cc', '<(libgen_in_cc_file)',
            '--include', 'vm/bootstrap.h',
            '--var_name', 'dart::Bootstrap::_internal_patch_paths_',
            '--library_name', 'dart:_internal',
            '<@(_sources)',
          ],
          'message': 'Generating ''<(internal_patch_cc_file)'' file.'
        },
      ]
    },
    {
      'target_name': 'generate_internal_cc_file',
      'type': 'none',
      'toolsets':['host'],
      'includes': [
        # Load the shared internal library sources.
        '../../sdk/lib/internal/internal_sources.gypi',
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
          'action_name': 'generate_internal_cc',
          'inputs': [
            '../tools/gen_library_src_paths.py',
            '<(libgen_in_cc_file)',
            '<@(_sources)',
          ],
          'outputs': [
            '<(internal_cc_file)',
          ],
          'action': [
            'python',
            'tools/gen_library_src_paths.py',
            '--output', '<(internal_cc_file)',
            '--input_cc', '<(libgen_in_cc_file)',
            '--include', 'vm/bootstrap.h',
            '--var_name', 'dart::Bootstrap::_internal_source_paths_',
            '--library_name', 'dart:_internal',
            '<@(_sources)',
          ],
          'message': 'Generating ''<(internal_cc_file)'' file.'
        },
      ]
    },
    {
      'target_name': 'generate_isolate_cc_file',
      'type': 'none',
      'toolsets':['host'],
      'includes': [
        # Load the runtime implementation sources.
        '../../sdk/lib/isolate/isolate_sources.gypi',
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
          'action_name': 'generate_isolate_cc',
          'inputs': [
            '../tools/gen_library_src_paths.py',
            '<(libgen_in_cc_file)',
            '<@(_sources)',
          ],
          'outputs': [
            '<(isolate_cc_file)',
          ],
          'action': [
            'python',
            'tools/gen_library_src_paths.py',
            '--output', '<(isolate_cc_file)',
            '--input_cc', '<(libgen_in_cc_file)',
            '--include', 'vm/bootstrap.h',
            '--var_name', 'dart::Bootstrap::isolate_source_paths_',
            '--library_name', 'dart:isolate',
            '<@(_sources)',
          ],
          'message': 'Generating ''<(isolate_cc_file)'' file.'
        },
      ]
    },
    {
      'target_name': 'generate_isolate_patch_cc_file',
      'type': 'none',
      'toolsets':['host'],
      'includes': [
        # Load the runtime implementation sources.
        '../lib/isolate_sources.gypi',
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
          'action_name': 'generate_isolate_patch_cc',
          'inputs': [
            '../tools/gen_library_src_paths.py',
            '<(libgen_in_cc_file)',
            '<@(_sources)',
          ],
          'outputs': [
            '<(isolate_patch_cc_file)',
          ],
          'action': [
            'python',
            'tools/gen_library_src_paths.py',
            '--output', '<(isolate_patch_cc_file)',
            '--input_cc', '<(libgen_in_cc_file)',
            '--include', 'vm/bootstrap.h',
            '--var_name', 'dart::Bootstrap::isolate_patch_paths_',
            '--library_name', 'dart:isolate',
            '<@(_sources)',
          ],
          'message': 'Generating ''<(isolate_patch_cc_file)'' file.'
        },
      ]
    },
    {
      'target_name': 'generate_math_cc_file',
      'type': 'none',
      'toolsets':['host'],
      'includes': [
        # Load the shared math library sources.
        '../../sdk/lib/math/math_sources.gypi',
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
          'action_name': 'generate_math_cc',
          'inputs': [
            '../tools/gen_library_src_paths.py',
            '<(libgen_in_cc_file)',
            '<@(_sources)',
          ],
          'outputs': [
            '<(math_cc_file)',
          ],
          'action': [
            'python',
            'tools/gen_library_src_paths.py',
            '--output', '<(math_cc_file)',
            '--input_cc', '<(libgen_in_cc_file)',
            '--include', 'vm/bootstrap.h',
            '--var_name', 'dart::Bootstrap::math_source_paths_',
            '--library_name', 'dart:math',
            '<@(_sources)',
          ],
          'message': 'Generating ''<(math_cc_file)'' file.'
        },
      ]
    },
    {
      'target_name': 'generate_math_patch_cc_file',
      'type': 'none',
      'toolsets':['host'],
      'includes': [
        # Load the shared math library sources.
        '../lib/math_sources.gypi',
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
          'action_name': 'generate_math_patch_cc',
          'inputs': [
            '../tools/gen_library_src_paths.py',
            '<(libgen_in_cc_file)',
            '<@(_sources)',
          ],
          'outputs': [
            '<(math_patch_cc_file)',
          ],
          'action': [
            'python',
            'tools/gen_library_src_paths.py',
            '--output', '<(math_patch_cc_file)',
            '--input_cc', '<(libgen_in_cc_file)',
            '--include', 'vm/bootstrap.h',
            '--var_name', 'dart::Bootstrap::math_patch_paths_',
            '--library_name', 'dart:math',
            '<@(_sources)',
          ],
          'message': 'Generating ''<(math_patch_cc_file)'' file.'
        },
      ]
    },
    {
      'target_name': 'generate_mirrors_cc_file',
      'type': 'none',
      'toolsets':['host'],
      'includes': [
        # Load the shared core library sources.
        '../../sdk/lib/mirrors/mirrors_sources.gypi',
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
          'action_name': 'generate_mirrors_cc',
          'inputs': [
            '../tools/gen_library_src_paths.py',
            '<(libgen_in_cc_file)',
            '<@(_sources)',
          ],
          'outputs': [
            '<(mirrors_cc_file)',
          ],
          'action': [
            'python',
            'tools/gen_library_src_paths.py',
            '--output', '<(mirrors_cc_file)',
            '--input_cc', '<(libgen_in_cc_file)',
            '--include', 'vm/bootstrap.h',
            '--var_name', 'dart::Bootstrap::mirrors_source_paths_',
            '--library_name', 'dart:mirrors',
            '<@(_sources)',
          ],
          'message': 'Generating ''<(mirrors_cc_file)'' file.'
        },
      ]
    },
    {
      'target_name': 'generate_mirrors_patch_cc_file',
      'type': 'none',
      'toolsets':['host'],
      'includes': [
        # Load the patch sources.
        '../lib/mirrors_sources.gypi',
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
          'action_name': 'generate_mirrors_patch_cc',
          'inputs': [
            '../tools/gen_library_src_paths.py',
            '<(libgen_in_cc_file)',
            '<@(_sources)',
          ],
          'outputs': [
            '<(mirrors_patch_cc_file)',
          ],
          'action': [
            'python',
            'tools/gen_library_src_paths.py',
            '--output', '<(mirrors_patch_cc_file)',
            '--input_cc', '<(libgen_in_cc_file)',
            '--include', 'vm/bootstrap.h',
            '--var_name', 'dart::Bootstrap::mirrors_patch_paths_',
            '--library_name', 'dart:mirrors',
            '<@(_sources)',
          ],
          'message': 'Generating ''<(mirrors_patch_cc_file)'' file.'
        },
      ]
    },
    {
      'target_name': 'generate_typed_data_cc_file',
      'type': 'none',
      'toolsets':['host'],
      'includes': [
        # Load the runtime implementation sources.
        '../../sdk/lib/typed_data/typed_data_sources.gypi',
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
          'action_name': 'generate_typed_data_cc',
          'inputs': [
            '../tools/gen_library_src_paths.py',
            '<(libgen_in_cc_file)',
            '<@(_sources)',
          ],
          'outputs': [
            '<(typed_data_cc_file)',
          ],
          'action': [
            'python',
            'tools/gen_library_src_paths.py',
            '--output', '<(typed_data_cc_file)',
            '--input_cc', '<(libgen_in_cc_file)',
            '--include', 'vm/bootstrap.h',
            '--var_name', 'dart::Bootstrap::typed_data_source_paths_',
            '--library_name', 'dart:typed_data',
            '<@(_sources)',
          ],
          'message': 'Generating ''<(typed_data_cc_file)'' file.'
        },
      ]
    },
    {
      'target_name': 'generate_typed_data_patch_cc_file',
      'type': 'none',
      'toolsets':['host'],
      'includes': [
        # Load the patch sources.
        '../lib/typed_data_sources.gypi',
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
          'action_name': 'generate_typed_data_patch_cc',
          'inputs': [
            '../tools/gen_library_src_paths.py',
            '<(libgen_in_cc_file)',
            '<@(_sources)',
          ],
          'outputs': [
            '<(typed_data_patch_cc_file)',
          ],
          'action': [
            'python',
            'tools/gen_library_src_paths.py',
            '--output', '<(typed_data_patch_cc_file)',
            '--input_cc', '<(libgen_in_cc_file)',
            '--include', 'vm/bootstrap.h',
            '--var_name', 'dart::Bootstrap::typed_data_patch_paths_',
            '--library_name', 'dart:typed_data',
            '<@(_sources)',
          ],
          'message': 'Generating ''<(typed_data_patch_cc_file)'' file.'
        },
      ]
    },
    {
      'target_name': 'generate_profiler_cc_file',
      'type': 'none',
      'toolsets':['host'],
      'includes': [
        # Load the shared library sources.
        '../../sdk/lib/profiler/profiler_sources.gypi',
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
          'action_name': 'generate_profiler_cc',
          'inputs': [
            '../tools/gen_library_src_paths.py',
            '<(libgen_in_cc_file)',
            '<@(_sources)',
          ],
          'outputs': [
            '<(profiler_cc_file)',
          ],
          'action': [
            'python',
            'tools/gen_library_src_paths.py',
            '--output', '<(profiler_cc_file)',
            '--input_cc', '<(libgen_in_cc_file)',
            '--include', 'vm/bootstrap.h',
            '--var_name', 'dart::Bootstrap::profiler_source_paths_',
            '--library_name', 'dart:profiler',
            '<@(_sources)',
          ],
          'message': 'Generating ''<(profiler_cc_file)'' file.'
        },
      ]
    },
    {
      'target_name': 'generate_developer_cc_file',
      'type': 'none',
      'toolsets':['host'],
      'includes': [
        # Load the shared library sources.
        '../../sdk/lib/developer/developer_sources.gypi',
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
          'action_name': 'generate_developer_cc',
          'inputs': [
            '../tools/gen_library_src_paths.py',
            '<(libgen_in_cc_file)',
            '<@(_sources)',
          ],
          'outputs': [
            '<(developer_cc_file)',
          ],
          'action': [
            'python',
            'tools/gen_library_src_paths.py',
            '--output', '<(developer_cc_file)',
            '--input_cc', '<(libgen_in_cc_file)',
            '--include', 'vm/bootstrap.h',
            '--var_name', 'dart::Bootstrap::developer_source_paths_',
            '--library_name', 'dart:developer',
            '<@(_sources)',
          ],
          'message': 'Generating ''<(developer_cc_file)'' file.'
        },
      ]
    },
    {
      'target_name': 'generate_developer_patch_cc_file',
      'type': 'none',
      'toolsets':['host'],
      'includes': [
        # Load the runtime implementation sources.
        '../lib/developer_sources.gypi',
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
          'action_name': 'generate_developer_patch_cc',
          'inputs': [
            '../tools/gen_library_src_paths.py',
            '<(libgen_in_cc_file)',
            '<@(_sources)',
          ],
          'outputs': [
            '<(developer_patch_cc_file)',
          ],
          'action': [
            'python',
            'tools/gen_library_src_paths.py',
            '--output', '<(developer_patch_cc_file)',
            '--input_cc', '<(libgen_in_cc_file)',
            '--include', 'vm/bootstrap.h',
            '--var_name', 'dart::Bootstrap::developer_patch_paths_',
            '--library_name', 'dart:developer',
            '<@(_sources)',
          ],
          'message': 'Generating ''<(developer_patch_cc_file)'' file.'
        },
      ]
    },
    {
      'target_name': 'generate_snapshot_test_dat_file',
      'type': 'none',
      'toolsets':['host'],
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
            '--include', 'INTENTIONALLY_LEFT_BLANK',
            '--var_name', 'INTENTIONALLY_LEFT_BLANK_TOO',
            '<(snapshot_test_dart_file)',
          ],
          'message': 'Generating ''<(snapshot_test_dat_file)'' file.'
        },
      ]
    },
    {
      'target_name': 'generate_vmservice_cc_file',
      'type': 'none',
      'toolsets':['host'],
      'includes': [
        # Load the shared library sources.
        '../../sdk/lib/vmservice/vmservice_sources.gypi',
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
          'action_name': 'generate_vmservice_cc',
          'inputs': [
            '../tools/gen_library_src_paths.py',
            '<(libgen_in_cc_file)',
            '<@(_sources)',
          ],
          'outputs': [
            '<(vmservice_cc_file)',
          ],
          'action': [
            'python',
            'tools/gen_library_src_paths.py',
            '--output', '<(vmservice_cc_file)',
            '--input_cc', '<(libgen_in_cc_file)',
            '--include', 'vm/bootstrap.h',
            '--var_name', 'dart::Bootstrap::_vmservice_source_paths_',
            '--library_name', 'dart:_vmservice',
            '<@(_sources)',
          ],
          'message': 'Generating ''<(vmservice_cc_file)'' file.'
        },
      ]
    },
    {
      'target_name': 'generate_vmservice_patch_cc_file',
      'type': 'none',
      'toolsets':['host'],
      'includes': [
        # Load the runtime implementation sources.
        '../lib/vmservice_sources.gypi',
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
          'action_name': 'generate_vmservice_patch_cc',
          'inputs': [
            '../tools/gen_library_src_paths.py',
            '<(libgen_in_cc_file)',
            '<@(_sources)',
          ],
          'outputs': [
            '<(vmservice_patch_cc_file)',
          ],
          'action': [
            'python',
            'tools/gen_library_src_paths.py',
            '--output', '<(vmservice_patch_cc_file)',
            '--input_cc', '<(libgen_in_cc_file)',
            '--include', 'vm/bootstrap.h',
            '--var_name', 'dart::Bootstrap::_vmservice_patch_paths_',
            '--library_name', 'dart:_vmservice',
            '<@(_sources)',
          ],
          'message': 'Generating ''<(vmservice_patch_cc_file)'' file.'
        },
      ]
    },
    {
      'target_name': 'generate_patched_sdk',
      'type': 'none',
      'toolsets': ['host'],
      'dependencies': [
        'dart_bootstrap#host',
        'generate_async_library_patch',
        'generate_collection_library_patch',
        'generate_convert_library_patch',
        'generate_core_library_patch',
        'generate_developer_library_patch',
        'generate_internal_library_patch',
        'generate_io_library_patch',
        'generate_isolate_library_patch',
        'generate_math_library_patch',
        'generate_mirrors_library_patch',
        'generate_profiler_library_patch',
        'generate_typed_data_library_patch',
        'generate_vmservice_library_patch',
      ],
      'actions': [
        {
          'action_name': 'patch_sdk',
          'inputs': [
            '<!@(["python", "../tools/list_files.py", "relative",'
                  '"dart$", "sdk/lib"])',
            '../../tools/patch_sdk.py',
            '../../tools/patch_sdk.dart',
            # Unlike the other libraries in the SDK, dart:_builtin and
            # dart:nativewrappers are only available for the Dart VM.
            '../bin/builtin.dart',
            '../bin/vmservice/vmservice_io.dart',
            '../bin/vmservice/loader.dart',
            '../bin/vmservice/server.dart',
            '<(gen_source_dir)/patches/async_patch.dart',
            '<(gen_source_dir)/patches/collection_patch.dart',
            '<(gen_source_dir)/patches/convert_patch.dart',
            '<(gen_source_dir)/patches/core_patch.dart',
            '<(gen_source_dir)/patches/developer_patch.dart',
            '<(gen_source_dir)/patches/internal_patch.dart',
            '<(gen_source_dir)/patches/io_patch.dart',
            '<(gen_source_dir)/patches/isolate_patch.dart',
            '<(gen_source_dir)/patches/math_patch.dart',
            '<(gen_source_dir)/patches/mirrors_patch.dart',
            '<(gen_source_dir)/patches/profiler_patch.dart',
            '<(gen_source_dir)/patches/typed_data_patch.dart',
            '<(gen_source_dir)/patches/vmservice_patch.dart',
          ],
          'outputs': [
            # Instead of listing all outputs we list a single well-known one.
            '<(PRODUCT_DIR)/patched_sdk/lib/core/core.dart',
          ],
          'action': [
            'python',
            '../tools/patch_sdk.py',
            '--dart-executable',
            '<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)dart_bootstrap<(EXECUTABLE_SUFFIX)',
            'vm',
            '../sdk',
            '<(gen_source_dir)/patches',
            '<(PRODUCT_DIR)/patched_sdk',
            '../.packages',
          ],
        },
      ],
    },
    {
      'variables': {
        'library_name': 'async',
        'library_uri': 'dart:async',
      },
      'target_name': 'generate_<(library_name)_library_patch',
      'type': 'none',
      'toolsets': ['host'],
      'includes': [
        '../lib/async_sources.gypi',
      ],
      'actions': [
        {
          'action_name': 'concatenate_<(library_name)_patches',
          'inputs': [
            '../tools/concatenate_patches.py',
            '<@(_sources)',
          ],
          'outputs': [
            '<(gen_source_dir)/patches/<(library_name)_patch.dart'
          ],
          'action': [
            'python',
            'tools/concatenate_patches.py',
            '--output',
            '<(gen_source_dir)/patches/<(library_name)_patch.dart',
            '<@(_sources)',
          ],
          'message': 'Generating <(library_uri) patch.',
        },
      ],
    },
    {
      'variables': {
        'library_name': 'collection',
        'library_uri': 'dart:collection',
      },
      'target_name': 'generate_<(library_name)_library_patch',
      'type': 'none',
      'toolsets': ['host'],
      'includes': [
        '../lib/collection_sources.gypi',
      ],
      'actions': [
        {
          'action_name': 'concatenate_<(library_name)_patches',
          'inputs': [
            '../tools/concatenate_patches.py',
            '<@(_sources)',
          ],
          'outputs': [
            '<(gen_source_dir)/patches/<(library_name)_patch.dart'
          ],
          'action': [
            'python',
            'tools/concatenate_patches.py',
            '--output',
            '<(gen_source_dir)/patches/<(library_name)_patch.dart',
            '<@(_sources)',
          ],
          'message': 'Generating <(library_uri) patch.',
        },
      ],
    },
    {
      'variables': {
        'library_name': 'convert',
        'library_uri': 'dart:convert',
      },
      'target_name': 'generate_<(library_name)_library_patch',
      'type': 'none',
      'toolsets': ['host'],
      'includes': [
        '../lib/convert_sources.gypi',
      ],
      'actions': [
        {
          'action_name': 'concatenate_<(library_name)_patches',
          'inputs': [
            '../tools/concatenate_patches.py',
            '<@(_sources)',
          ],
          'outputs': [
            '<(gen_source_dir)/patches/<(library_name)_patch.dart'
          ],
          'action': [
            'python',
            'tools/concatenate_patches.py',
            '--output',
            '<(gen_source_dir)/patches/<(library_name)_patch.dart',
            '<@(_sources)',
          ],
          'message': 'Generating <(library_uri) patch.',
        },
      ],
    },
    {
      'variables': {
        'library_name': 'core',
        'library_uri': 'dart:core',
      },
      'target_name': 'generate_<(library_name)_library_patch',
      'type': 'none',
      'toolsets': ['host'],
      'includes': [
        '../lib/core_sources.gypi',
      ],
      'actions': [
        {
          'action_name': 'concatenate_<(library_name)_patches',
          'inputs': [
            '../tools/concatenate_patches.py',
            '<@(_sources)',
          ],
          'outputs': [
            '<(gen_source_dir)/patches/<(library_name)_patch.dart'
          ],
          'action': [
            'python',
            'tools/concatenate_patches.py',
            '--output',
            '<(gen_source_dir)/patches/<(library_name)_patch.dart',
            '<@(_sources)',
          ],
          'message': 'Generating <(library_uri) patch.',
        },
      ],
    },
    {
      'variables': {
        'library_name': 'developer',
        'library_uri': 'dart:developer',
      },
      'target_name': 'generate_<(library_name)_library_patch',
      'type': 'none',
      'toolsets': ['host'],
      'includes': [
        '../lib/developer_sources.gypi',
      ],
      'actions': [
        {
          'action_name': 'concatenate_<(library_name)_patches',
          'inputs': [
            '../tools/concatenate_patches.py',
            '<@(_sources)',
          ],
          'outputs': [
            '<(gen_source_dir)/patches/<(library_name)_patch.dart'
          ],
          'action': [
            'python',
            'tools/concatenate_patches.py',
            '--output',
            '<(gen_source_dir)/patches/<(library_name)_patch.dart',
            '<@(_sources)',
          ],
          'message': 'Generating <(library_uri) patch.',
        },
      ],
    },
    {
      'variables': {
        'library_name': 'internal',
        'library_uri': 'dart:_internal',
      },
      'target_name': 'generate_<(library_name)_library_patch',
      'type': 'none',
      'toolsets': ['host'],
      'includes': [
        '../lib/internal_sources.gypi',
      ],
      'actions': [
        {
          'action_name': 'concatenate_<(library_name)_patches',
          'inputs': [
            '../tools/concatenate_patches.py',
            '<@(_sources)',
          ],
          'outputs': [
            '<(gen_source_dir)/patches/<(library_name)_patch.dart'
          ],
          'action': [
            'python',
            'tools/concatenate_patches.py',
            '--output',
            '<(gen_source_dir)/patches/<(library_name)_patch.dart',
            '<@(_sources)',
          ],
          'message': 'Generating <(library_uri) patch.',
        },
      ],
    },
    {
      'variables': {
        'library_name': 'io',
        'library_uri': 'dart:io',
      },
      'target_name': 'generate_<(library_name)_library_patch',
      'type': 'none',
      'toolsets': ['host'],
      'includes': [
        '../bin/io_sources.gypi',
      ],
      'actions': [
        {
          'action_name': 'concatenate_<(library_name)_patches',
          'inputs': [
            '../tools/concatenate_patches.py',
            '<@(_sources)',
          ],
          'outputs': [
            '<(gen_source_dir)/patches/<(library_name)_patch.dart'
          ],
          'action': [
            'python',
            'tools/concatenate_patches.py',
            '--output',
            '<(gen_source_dir)/patches/<(library_name)_patch.dart',
            '<@(_sources)',
          ],
          'message': 'Generating <(library_uri) patch.',
        },
      ],
    },
    {
      'variables': {
        'library_name': 'isolate',
        'library_uri': 'dart:isolate',
      },
      'target_name': 'generate_<(library_name)_library_patch',
      'type': 'none',
      'toolsets': ['host'],
      'includes': [
        '../lib/isolate_sources.gypi',
      ],
      'actions': [
        {
          'action_name': 'concatenate_<(library_name)_patches',
          'inputs': [
            '../tools/concatenate_patches.py',
            '<@(_sources)',
          ],
          'outputs': [
            '<(gen_source_dir)/patches/<(library_name)_patch.dart'
          ],
          'action': [
            'python',
            'tools/concatenate_patches.py',
            '--output',
            '<(gen_source_dir)/patches/<(library_name)_patch.dart',
            '<@(_sources)',
          ],
          'message': 'Generating <(library_uri) patch.',
        },
      ],
    },
    {
      'variables': {
        'library_name': 'math',
        'library_uri': 'dart:math',
      },
      'target_name': 'generate_<(library_name)_library_patch',
      'type': 'none',
      'toolsets': ['host'],
      'includes': [
        '../lib/math_sources.gypi',
      ],
      'actions': [
        {
          'action_name': 'concatenate_<(library_name)_patches',
          'inputs': [
            '../tools/concatenate_patches.py',
            '<@(_sources)',
          ],
          'outputs': [
            '<(gen_source_dir)/patches/<(library_name)_patch.dart'
          ],
          'action': [
            'python',
            'tools/concatenate_patches.py',
            '--output',
            '<(gen_source_dir)/patches/<(library_name)_patch.dart',
            '<@(_sources)',
          ],
          'message': 'Generating <(library_uri) patch.',
        },
      ],
    },
    {
      'variables': {
        'library_name': 'mirrors',
        'library_uri': 'dart:mirrors',
      },
      'target_name': 'generate_<(library_name)_library_patch',
      'type': 'none',
      'toolsets': ['host'],
      'includes': [
        '../lib/mirrors_sources.gypi',
      ],
      'actions': [
        {
          'action_name': 'concatenate_<(library_name)_patches',
          'inputs': [
            '../tools/concatenate_patches.py',
            '<@(_sources)',
          ],
          'outputs': [
            '<(gen_source_dir)/patches/<(library_name)_patch.dart'
          ],
          'action': [
            'python',
            'tools/concatenate_patches.py',
            '--output',
            '<(gen_source_dir)/patches/<(library_name)_patch.dart',
            '<@(_sources)',
          ],
          'message': 'Generating <(library_uri) patch.',
        },
      ],
    },
    {
      'variables': {
        'library_name': 'profiler',
        'library_uri': 'dart:profiler',
      },
      'target_name': 'generate_<(library_name)_library_patch',
      'type': 'none',
      'toolsets': ['host'],
      'includes': [
        '../lib/profiler_sources.gypi',
      ],
      'actions': [
        {
          'action_name': 'concatenate_<(library_name)_patches',
          'inputs': [
            '../tools/concatenate_patches.py',
            '<@(_sources)',
          ],
          'outputs': [
            '<(gen_source_dir)/patches/<(library_name)_patch.dart'
          ],
          'action': [
            'python',
            'tools/concatenate_patches.py',
            '--output',
            '<(gen_source_dir)/patches/<(library_name)_patch.dart',
            '<@(_sources)',
          ],
          'message': 'Generating <(library_uri) patch.',
        },
      ],
    },
    {
      'variables': {
        'library_name': 'typed_data',
        'library_uri': 'dart:typed_data',
      },
      'target_name': 'generate_<(library_name)_library_patch',
      'type': 'none',
      'toolsets': ['host'],
      'includes': [
        '../lib/typed_data_sources.gypi',
      ],
      'actions': [
        {
          'action_name': 'concatenate_<(library_name)_patches',
          'inputs': [
            '../tools/concatenate_patches.py',
            '<@(_sources)',
          ],
          'outputs': [
            '<(gen_source_dir)/patches/<(library_name)_patch.dart'
          ],
          'action': [
            'python',
            'tools/concatenate_patches.py',
            '--output',
            '<(gen_source_dir)/patches/<(library_name)_patch.dart',
            '<@(_sources)',
          ],
          'message': 'Generating <(library_uri) patch.',
        },
      ],
    },
    {
      'variables': {
        'library_name': 'vmservice',
        'library_uri': 'dart:_vmservice',
      },
      'target_name': 'generate_<(library_name)_library_patch',
      'type': 'none',
      'toolsets': ['host'],
      'includes': [
        '../lib/vmservice_sources.gypi',
      ],
      'actions': [
        {
          'action_name': 'concatenate_<(library_name)_patches',
          'inputs': [
            '../tools/concatenate_patches.py',
            '<@(_sources)',
          ],
          'outputs': [
            '<(gen_source_dir)/patches/<(library_name)_patch.dart'
          ],
          'action': [
            'python',
            'tools/concatenate_patches.py',
            '--output',
            '<(gen_source_dir)/patches/<(library_name)_patch.dart',
            '<@(_sources)',
          ],
          'message': 'Generating <(library_uri) patch.',
        },
      ],
    },
  ]
}
