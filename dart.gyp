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
        'dartdevc',
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
        'runtime/dart-runtime.gyp:dart_bootstrap#host',
        'runtime/dart-runtime.gyp:run_vm_tests',
        'runtime/dart-runtime.gyp:process_test',
        'runtime/dart-runtime.gyp:test_extension',
        'runtime/dart-runtime.gyp:sample_extension',
        'runtime/dart-runtime.gyp:generate_patched_sdk#host',
      ],
    },
    {
      # This is the target that is built on the VM build bots.  It
      # must depend on anything that is required by the VM test
      # suites.
      'target_name': 'runtime_precompiled',
      'type': 'none',
      'dependencies': [
        'runtime/dart-runtime.gyp:dart_precompiled_runtime',
        'runtime/dart-runtime.gyp:dart_bootstrap#host',
        'runtime/dart-runtime.gyp:process_test',
        'runtime/dart-runtime.gyp:generate_patched_sdk#host',
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
      'target_name': 'dartdevc',
      'type': 'none',
      'dependencies': [
        'utils/dartdevc/dartdevc.gyp:dartdevc',
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
  ],
}
