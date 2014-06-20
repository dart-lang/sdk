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
    'corelib_cc_file': '<(gen_source_dir)/corelib_gen.cc',
    'corelib_patch_cc_file': '<(gen_source_dir)/corelib_patch_gen.cc',
    'collection_cc_file': '<(gen_source_dir)/collection_gen.cc',
    'collection_patch_cc_file': '<(gen_source_dir)/collection_patch_gen.cc',
    'convert_cc_file': '<(gen_source_dir)/convert_gen.cc',
    'convert_patch_cc_file': '<(gen_source_dir)/convert_patch_gen.cc',
    'internal_cc_file': '<(gen_source_dir)/internal_gen.cc',
    'internal_patch_cc_file': '<(gen_source_dir)/internal_patch_gen.cc',
    'isolate_cc_file': '<(gen_source_dir)/isolate_gen.cc',
    'isolate_patch_cc_file': '<(gen_source_dir)/isolate_patch_gen.cc',
    'math_cc_file': '<(gen_source_dir)/math_gen.cc',
    'math_patch_cc_file': '<(gen_source_dir)/math_patch_gen.cc',
    'mirrors_cc_file': '<(gen_source_dir)/mirrors_gen.cc',
    'mirrors_patch_cc_file': '<(gen_source_dir)/mirrors_patch_gen.cc',
    'service_cc_file': '<(gen_source_dir)/service_gen.cc',
    'snapshot_test_dat_file': '<(gen_source_dir)/snapshot_test.dat',
    'snapshot_test_in_dat_file': 'snapshot_test_in.dat',
    'snapshot_test_dart_file': 'snapshot_test.dart',
    'typed_data_cc_file': '<(gen_source_dir)/typed_data_gen.cc',
    'typed_data_patch_cc_file': '<(gen_source_dir)/typed_data_patch_gen.cc',
    'profiler_cc_file': '<(gen_source_dir)/profiler_gen.cc',
    'profiler_patch_cc_file': '<(gen_source_dir)/profiler_patch_gen.cc',
  },
  'targets': [
    {
      'target_name': 'libdart_vm',
      'type': 'static_library',
      'toolsets':['host', 'target'],
      'dependencies': [
        'generate_service_cc_file#host'
      ],
      'includes': [
        'vm_sources.gypi',
        '../platform/platform_headers.gypi',
        '../platform/platform_sources.gypi',
      ],
      'sources': [
        # Include generated source files.
        '<(service_cc_file)',
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
            ],
          },
        }],
        ['OS=="win"', {
          'sources/' : [
            ['exclude', 'gdbjit.cc'],
          ],
       }],
       ['dart_vtune_support==0', {
          'sources/' : [
            ['exclude', 'vtune\\.(cc|h)$'],
          ],
       }],
       ['dart_vtune_support==1', {
          'include_dirs': ['<(dart_vtune_root)/include'],
          'defines': ['DART_VTUNE_SUPPORT'],
          'link_settings': {
            'conditions': [
              ['OS=="linux"', {
                 'libraries': ['-ljitprofiling'],
              }],
              ['OS=="win"', {
                 'libraries': ['-ljitprofiling.lib'],
              }],
            ],
          },
        }]],
    },
    {
      'target_name': 'libdart_lib_withcore',
      'type': 'static_library',
      'toolsets':['host', 'target'],
      'dependencies': [
        'generate_async_cc_file#host',
        'generate_async_patch_cc_file#host',
        'generate_corelib_cc_file#host',
        'generate_corelib_patch_cc_file#host',
        'generate_collection_cc_file#host',
        'generate_collection_patch_cc_file#host',
        'generate_convert_cc_file#host',
        'generate_convert_patch_cc_file#host',
        'generate_internal_cc_file#host',
        'generate_internal_patch_cc_file#host',
        'generate_isolate_cc_file#host',
        'generate_isolate_patch_cc_file#host',
        'generate_math_cc_file#host',
        'generate_math_patch_cc_file#host',
        'generate_mirrors_cc_file#host',
        'generate_mirrors_patch_cc_file#host',
        'generate_typed_data_cc_file#host',
        'generate_typed_data_patch_cc_file#host',
        'generate_profiler_cc_file#host',
        'generate_profiler_patch_cc_file#host',
      ],
      'includes': [
        '../lib/async_sources.gypi',
        '../lib/collection_sources.gypi',
        '../lib/corelib_sources.gypi',
        '../lib/isolate_sources.gypi',
        '../lib/math_sources.gypi',
        '../lib/mirrors_sources.gypi',
        '../lib/typed_data_sources.gypi',
        '../lib/profiler_sources.gypi',
        '../lib/internal_sources.gypi',
      ],
      'sources': [
        'bootstrap.cc',
        # Include generated source files.
        '<(async_cc_file)',
        '<(async_patch_cc_file)',
        '<(corelib_cc_file)',
        '<(corelib_patch_cc_file)',
        '<(collection_cc_file)',
        '<(collection_patch_cc_file)',
        '<(convert_cc_file)',
        '<(convert_patch_cc_file)',
        '<(internal_cc_file)',
        '<(internal_patch_cc_file)',
        '<(isolate_cc_file)',
        '<(isolate_patch_cc_file)',
        '<(math_cc_file)',
        '<(math_patch_cc_file)',
        '<(mirrors_cc_file)',
        '<(mirrors_patch_cc_file)',
        '<(typed_data_cc_file)',
        '<(typed_data_patch_cc_file)',
        '<(profiler_cc_file)',
        '<(profiler_patch_cc_file)',
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
        '../lib/corelib_sources.gypi',
        '../lib/isolate_sources.gypi',
        '../lib/math_sources.gypi',
        '../lib/mirrors_sources.gypi',
        '../lib/typed_data_sources.gypi',
        '../lib/profiler_sources.gypi',
        '../lib/internal_sources.gypi',
      ],
      'sources': [
        'bootstrap_nocorelib.cc',
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
      'target_name': 'generate_corelib_cc_file',
      'type': 'none',
      'toolsets':['host'],
      'includes': [
        # Load the shared core library sources.
        '../../sdk/lib/core/corelib_sources.gypi',
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
            '../tools/gen_library_src_paths.py',
            '<(libgen_in_cc_file)',
            '<@(_sources)',
          ],
          'outputs': [
            '<(corelib_cc_file)',
          ],
          'action': [
            'python',
            'tools/gen_library_src_paths.py',
            '--output', '<(corelib_cc_file)',
            '--input_cc', '<(libgen_in_cc_file)',
            '--include', 'vm/bootstrap.h',
            '--var_name', 'dart::Bootstrap::corelib_source_paths_',
            '--library_name', 'dart:core',
            '<@(_sources)',
          ],
          'message': 'Generating ''<(corelib_cc_file)'' file.'
        },
      ]
    },
    {
      'target_name': 'generate_corelib_patch_cc_file',
      'type': 'none',
      'toolsets':['host'],
      'includes': [
        # Load the runtime implementation sources.
        '../lib/corelib_sources.gypi',
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
          'action_name': 'generate_corelib_patch_cc',
          'inputs': [
            '../tools/gen_library_src_paths.py',
            '<(libgen_in_cc_file)',
            '<@(_sources)',
          ],
          'outputs': [
            '<(corelib_patch_cc_file)',
          ],
          'action': [
            'python',
            'tools/gen_library_src_paths.py',
            '--output', '<(corelib_patch_cc_file)',
            '--input_cc', '<(libgen_in_cc_file)',
            '--include', 'vm/bootstrap.h',
            '--var_name', 'dart::Bootstrap::corelib_patch_paths_',
            '--library_name', 'dart:corelib',
            '<@(_sources)',
          ],
          'message': 'Generating ''<(corelib_patch_cc_file)'' file.'
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
            '--var_name', 'dart::Bootstrap::internal_patch_paths_',
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
            '--var_name', 'dart::Bootstrap::internal_source_paths_',
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
        # Load the shared library sources.
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
        # Load the runtime implementation sources.
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
      'target_name': 'generate_profiler_patch_cc_file',
      'type': 'none',
      'toolsets':['host'],
      'includes': [
        # Load the runtime implementation sources.
        '../lib/profiler_sources.gypi',
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
          'action_name': 'generate_profiler_patch_cc',
          'inputs': [
            '../tools/gen_library_src_paths.py',
            '<(libgen_in_cc_file)',
            '<@(_sources)',
          ],
          'outputs': [
            '<(profiler_patch_cc_file)',
          ],
          'action': [
            'python',
            'tools/gen_library_src_paths.py',
            '--output', '<(profiler_patch_cc_file)',
            '--input_cc', '<(libgen_in_cc_file)',
            '--include', 'vm/bootstrap.h',
            '--var_name', 'dart::Bootstrap::profiler_patch_paths_',
            '--library_name', 'dart:profiler',
            '<@(_sources)',
          ],
          'message': 'Generating ''<(profiler_patch_cc_file)'' file.'
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
      'target_name': 'generate_service_cc_file',
      'type': 'none',
      'toolsets':['host'],
      'includes': [
        'service_sources.gypi',
      ],
      'actions': [
        {
          'action_name': 'generate_service_cc',
          'inputs': [
            '../tools/create_resources.py',
            '<@(_sources)',
          ],
          'outputs': [
            '<(service_cc_file)',
          ],
          'action': [
            'python',
            'tools/create_resources.py',
            '--output', '<(service_cc_file)',
            '--outer_namespace', 'dart',
            '--table_name', 'service',
            '--root_prefix', 'vm/service/',
            '<@(_sources)'
          ],
          'message': 'Generating ''<(service_cc_file)'' file.'
        },
      ]
    },
  ]
}
