# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

{
  'variables': {
    'builtin_in_cc_file': '../bin/builtin_in.cc',
    'corelib_cc_file': '<(SHARED_INTERMEDIATE_DIR)/corelib_gen.cc',
    'corelib_patch_cc_file': '<(SHARED_INTERMEDIATE_DIR)/corelib_patch_gen.cc',
    'corelib_impl_cc_file': '<(SHARED_INTERMEDIATE_DIR)/corelib_impl_gen.cc',
    'corelib_impl_patch_cc_file': '<(SHARED_INTERMEDIATE_DIR)/corelib_impl_patch_gen.cc',
    'math_cc_file': '<(SHARED_INTERMEDIATE_DIR)/math_gen.cc',
    'math_patch_cc_file': '<(SHARED_INTERMEDIATE_DIR)/math_patch_gen.cc',
    'mirrors_cc_file': '<(SHARED_INTERMEDIATE_DIR)/mirrors_gen.cc',
    'mirrors_patch_cc_file': '<(SHARED_INTERMEDIATE_DIR)/mirrors_patch_gen.cc',
    'isolate_cc_file': '<(SHARED_INTERMEDIATE_DIR)/isolate_gen.cc',
    'isolate_patch_cc_file': '<(SHARED_INTERMEDIATE_DIR)/isolate_patch_gen.cc',
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
        '../platform/platform_headers.gypi',
        '../platform/platform_sources.gypi',
      ],
      'sources/': [
        # Exclude all _test.[cc|h] files.
        ['exclude', '_test\\.cc|h$'],
      ],
      'include_dirs': [
        '..',
      ],
      'conditions': [
        ['OS=="android"', {
          'link_settings': {
            'libraries': [
              '-lc',
              '-lpthread',
            ],
          },
        }],
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
       }]],
    },
    {
      'target_name': 'libdart_lib_withcore',
      'type': 'static_library',
      'dependencies': [
        'generate_corelib_cc_file',
        'generate_corelib_patch_cc_file',
        'generate_corelib_impl_cc_file',
        'generate_corelib_impl_patch_cc_file',
        'generate_math_cc_file',
        'generate_math_patch_cc_file',
        'generate_isolate_cc_file',
        'generate_isolate_patch_cc_file',
        'generate_mirrors_cc_file',
        'generate_mirrors_patch_cc_file',
      ],
      'includes': [
        '../lib/lib_sources.gypi',
        '../lib/lib_impl_sources.gypi',
        '../lib/isolate_sources.gypi',
        '../lib/mirrors_sources.gypi',
      ],
      'sources': [
        'bootstrap.cc',
        # Include generated source files.
        '<(corelib_cc_file)',
        '<(corelib_patch_cc_file)',
        '<(corelib_impl_cc_file)',
        '<(corelib_impl_patch_cc_file)',
        '<(math_cc_file)',
        '<(math_patch_cc_file)',
        '<(isolate_cc_file)',
        '<(isolate_patch_cc_file)',
        '<(mirrors_cc_file)',
        '<(mirrors_patch_cc_file)',
      ],
      'include_dirs': [
        '..',
      ],
    },
    {
      'target_name': 'libdart_lib',
      'type': 'static_library',
      'includes': [
        '../lib/lib_sources.gypi',
        '../lib/lib_impl_sources.gypi',
        '../lib/isolate_sources.gypi',
        '../lib/mirrors_sources.gypi',
      ],
      'sources': [
        'bootstrap_nocorelib.cc',
      ],
      'include_dirs': [
        '..',
      ],
    },
    {
      'target_name': 'generate_corelib_cc_file',
      'type': 'none',
      'includes': [
        # Load the shared core library sources.
        '../../lib/core/corelib_sources.gypi',
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
            '<(builtin_in_cc_file)',
            '<@(_sources)',
          ],
          'outputs': [
            '<(corelib_cc_file)',
          ],
          'action': [
            'python',
            'tools/create_string_literal.py',
            '--output', '<(corelib_cc_file)',
            '--input_cc', '<(builtin_in_cc_file)',
            '--include', 'vm/bootstrap.h',
            '--var_name', 'dart::Bootstrap::corelib_source_',
            '<@(_sources)',
          ],
          'message': 'Generating ''<(corelib_cc_file)'' file.'
        },
      ]
    },
    {
      'target_name': 'generate_corelib_patch_cc_file',
      'type': 'none',
      'includes': [
        # Load the runtime implementation sources.
        '../lib/lib_sources.gypi',
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
            '../tools/create_string_literal.py',
            '<(builtin_in_cc_file)',
            '<@(_sources)',
          ],
          'outputs': [
            '<(corelib_patch_cc_file)',
          ],
          'action': [
            'python',
            'tools/create_string_literal.py',
            '--output', '<(corelib_patch_cc_file)',
            '--input_cc', '<(builtin_in_cc_file)',
            '--include', 'vm/bootstrap.h',
            '--var_name', 'dart::Bootstrap::corelib_patch_',
            '<@(_sources)',
          ],
          'message': 'Generating ''<(corelib_patch_cc_file)'' file.'
        },
      ]
    },
    {
      'target_name': 'generate_corelib_impl_cc_file',
      'type': 'none',
      'includes': [
        # Load the shared core library sources.
        '../../lib/coreimpl/corelib_impl_sources.gypi',
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
            '<(builtin_in_cc_file)',
            '<@(_sources)',
          ],
          'outputs': [
            '<(corelib_impl_cc_file)',
          ],
          'action': [
            'python',
            'tools/create_string_literal.py',
            '--output', '<(corelib_impl_cc_file)',
            '--input_cc', '<(builtin_in_cc_file)',
            '--include', 'vm/bootstrap.h',
            '--var_name', 'dart::Bootstrap::corelib_impl_source_',
            '<@(_sources)',
          ],
          'message': 'Generating ''<(corelib_impl_cc_file)'' file.'
        },
      ]
    },
    {
      'target_name': 'generate_corelib_impl_patch_cc_file',
      'type': 'none',
      'includes': [
        # Load the runtime implementation sources.
        '../lib/lib_impl_sources.gypi',
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
          'action_name': 'generate_corelib_impl_patch_cc',
          'inputs': [
            '../tools/create_string_literal.py',
            '<(builtin_in_cc_file)',
            '<@(_sources)',
          ],
          'outputs': [
            '<(corelib_impl_patch_cc_file)',
          ],
          'action': [
            'python',
            'tools/create_string_literal.py',
            '--output', '<(corelib_impl_patch_cc_file)',
            '--input_cc', '<(builtin_in_cc_file)',
            '--include', 'vm/bootstrap.h',
            '--var_name', 'dart::Bootstrap::corelib_impl_patch_',
            '<@(_sources)',
          ],
          'message': 'Generating ''<(corelib_impl_patch_cc_file)'' file.'
        },
      ]
    },
    {
      'target_name': 'generate_math_cc_file',
      'type': 'none',
      'includes': [
        # Load the shared math library sources.
        '../../lib/math/math_sources.gypi',
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
            '../tools/create_string_literal.py',
            '<(builtin_in_cc_file)',
            '<@(_sources)',
          ],
          'outputs': [
            '<(math_cc_file)',
          ],
          'action': [
            'python',
            'tools/create_string_literal.py',
            '--output', '<(math_cc_file)',
            '--input_cc', '<(builtin_in_cc_file)',
            '--include', 'vm/bootstrap.h',
            '--var_name', 'dart::Bootstrap::math_source_',
            '<@(_sources)',
          ],
          'message': 'Generating ''<(math_cc_file)'' file.'
        },
      ]
    },
    {
      'target_name': 'generate_math_patch_cc_file',
      'type': 'none',
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
            '../tools/create_string_literal.py',
            '<(builtin_in_cc_file)',
            '<@(_sources)',
          ],
          'outputs': [
            '<(math_patch_cc_file)',
          ],
          'action': [
            'python',
            'tools/create_string_literal.py',
            '--output', '<(math_patch_cc_file)',
            '--input_cc', '<(builtin_in_cc_file)',
            '--include', 'vm/bootstrap.h',
            '--var_name', 'dart::Bootstrap::math_patch_',
            '<@(_sources)',
          ],
          'message': 'Generating ''<(math_patch_cc_file)'' file.'
        },
      ]
    },
    {
      'target_name': 'generate_mirrors_cc_file',
      'type': 'none',
      'includes': [
        # Load the shared core library sources.
        '../../lib/mirrors/mirrors_sources.gypi',
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
            '../tools/create_string_literal.py',
            '<(builtin_in_cc_file)',
            '<@(_sources)',
          ],
          'outputs': [
            '<(mirrors_cc_file)',
          ],
          'action': [
            'python',
            'tools/create_string_literal.py',
            '--output', '<(mirrors_cc_file)',
            '--input_cc', '<(builtin_in_cc_file)',
            '--include', 'vm/bootstrap.h',
            '--var_name', 'dart::Bootstrap::mirrors_source_',
            '<@(_sources)',
          ],
          'message': 'Generating ''<(mirrors_cc_file)'' file.'
        },
      ]
    },
    {
      'target_name': 'generate_mirrors_patch_cc_file',
      'type': 'none',
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
            '../tools/create_string_literal.py',
            '<(builtin_in_cc_file)',
            '<@(_sources)',
          ],
          'outputs': [
            '<(mirrors_patch_cc_file)',
          ],
          'action': [
            'python',
            'tools/create_string_literal.py',
            '--output', '<(mirrors_patch_cc_file)',
            '--input_cc', '<(builtin_in_cc_file)',
            '--include', 'vm/bootstrap.h',
            '--var_name', 'dart::Bootstrap::mirrors_patch_',
            '<@(_sources)',
          ],
          'message': 'Generating ''<(mirrors_patch_cc_file)'' file.'
        },
      ]
    },
    {
      'target_name': 'generate_isolate_cc_file',
      'type': 'none',
      'includes': [
        # Load the runtime implementation sources.
        '../../lib/isolate/isolate_sources.gypi',
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
            '../tools/create_string_literal.py',
            '<(builtin_in_cc_file)',
            '<@(_sources)',
          ],
          'outputs': [
            '<(isolate_cc_file)',
          ],
          'action': [
            'python',
            'tools/create_string_literal.py',
            '--output', '<(isolate_cc_file)',
            '--input_cc', '<(builtin_in_cc_file)',
            '--include', 'vm/bootstrap.h',
            '--var_name', 'dart::Bootstrap::isolate_source_',
            '<@(_sources)',
          ],
          'message': 'Generating ''<(isolate_cc_file)'' file.'
        },
      ]
    },
    {
      'target_name': 'generate_isolate_patch_cc_file',
      'type': 'none',
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
            '../tools/create_string_literal.py',
            '<(builtin_in_cc_file)',
            '<@(_sources)',
          ],
          'outputs': [
            '<(isolate_patch_cc_file)',
          ],
          'action': [
            'python',
            'tools/create_string_literal.py',
            '--output', '<(isolate_patch_cc_file)',
            '--input_cc', '<(builtin_in_cc_file)',
            '--include', 'vm/bootstrap.h',
            '--var_name', 'dart::Bootstrap::isolate_patch_',
            '<@(_sources)',
          ],
          'message': 'Generating ''<(isolate_patch_cc_file)'' file.'
        },
      ]
    },
    {
      'target_name': 'generate_snapshot_test_dat_file',
      'type': 'none',
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
  ]
}
