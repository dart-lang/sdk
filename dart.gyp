# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

{
  'targets': [
    {
      'target_name': 'most',
      'type': 'none',
      'dependencies': [
        'analysis_server',
        'create_sdk',
        'dart2js',
        'dartanalyzer',
        'packages',
        'runtime',
        'samples',
      ],
    },
    {
      # This is the target that is built on the VM build bots.  It
      # must depend on anything that is required by the VM test
      # suites.
      'target_name': 'runtime',
      'type': 'none',
      'dependencies': [
        'runtime/dart-runtime.gyp:dart',
        'runtime/dart-runtime.gyp:dart_noopt',
        'runtime/dart-runtime.gyp:dart_precompiled_runtime',
        'runtime/dart-runtime.gyp:dart_product',
        'runtime/dart-runtime.gyp:dart_bootstrap#host',
        'runtime/dart-runtime.gyp:run_vm_tests',
        'runtime/dart-runtime.gyp:process_test',
        'packages',
        'runtime/dart-runtime.gyp:test_extension',
        'runtime/dart-runtime.gyp:sample_extension',
      ],
    },
    {
      'target_name': 'create_sdk',
      'type': 'none',
      'dependencies': [
        'create_sdk.gyp:create_sdk_internal',
      ],
    },
    {
      'target_name': 'dart2js',
      'type': 'none',
      'dependencies': [
        'utils/compiler/compiler.gyp:dart2js',
      ],
    },
    {
      'target_name': 'dartanalyzer',
      'type': 'none',
      'dependencies': [
        'utils/dartanalyzer/dartanalyzer.gyp:dartanalyzer',
      ],
    },
    {
      'target_name': 'dartfmt',
      'type': 'none',
      'dependencies': [
        'utils/dartfmt/dartfmt.gyp:dartfmt',
      ],
    },
    {
      'target_name': 'analysis_server',
      'type': 'none',
      'dependencies': [
        'utils/analysis_server/analysis_server.gyp:analysis_server',
      ],
    },
    {
      # This is the target that is built on the dart2js build bots.
      # It must depend on anything that is required by the dart2js
      # test suites.
      'target_name': 'dart2js_bot',
      'type': 'none',
      'dependencies': [
        'create_sdk',
        'packages',
        'try',
      ],
    },
    {
      # This is the target that is built on the dart2js debug build bots.
      # It must depend on anything that is required by the dart2js
      # test suites.
      # We have this additional target because the try target takes to long
      # to build in debug mode and will make the build step time out.
      'target_name': 'dart2js_bot_debug',
      'type': 'none',
      'dependencies': [
        'create_sdk',
        'packages',
      ],
    },
    {
      'target_name': 'samples',
      'type': 'none',
      'dependencies': [],
      'conditions': [
        ['OS!="android"', {
           'dependencies': [
             'runtime/dart-runtime.gyp:sample_extension',
           ],
          },
        ],
      ]
    },
    {
      'target_name': 'packages',
      'type': 'none',
      'dependencies': [
        'pkg/pkg.gyp:pkg_packages',
      ],
    },
    {
      'target_name': 'try',
      'type': 'none',
      'dependencies': [
        'site/try/build_try.gyp:try_site',
      ],
    },
  ],
}
