# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

{
  'targets': [
    {
      'target_name': 'compiler',
      'type': 'none',
      'dependencies': [
        'compiler/dart-compiler.gyp:dart_analyzer',
      ],
      'actions': []
    },
    {
      # This is the target that is built on the VM build bots.  It
      # must depend on anything that is required by the VM test
      # suites.
      'target_name': 'runtime',
      'type': 'none',
      'dependencies': [
        'runtime/dart-runtime.gyp:dart',
        'runtime/dart-runtime.gyp:dart_no_snapshot',
        'runtime/dart-runtime.gyp:run_vm_tests',
        'runtime/dart-runtime.gyp:process_test',
        'runtime/dart-runtime.gyp:test_extension',
        'packages',
      ],
    },
    {
      # Build the SDK. This target is separate from upload_sdk as the
      # editor needs to build the SDK without uploading it.
      'target_name': 'create_sdk',
      'type': 'none',
      'dependencies': [
        'runtime/dart-runtime.gyp:dart',
        'utils/compiler/compiler.gyp:dart2js',
      ],
      'actions': [
        {
          'action_name': 'create_sdk_py',
          'inputs': [
            '<!@(["python", "tools/list_files.py", "\\.dart$", "lib"])',
            '<!@(["python", "tools/list_files.py", "import_.*\\.config$", "lib/config"])',
            'tools/create_sdk.py',
            '<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)dart<(EXECUTABLE_SUFFIX)',
            '<(PRODUCT_DIR)/dart2js',
            '<(PRODUCT_DIR)/dart2js.bat',
          ],
          'outputs': [
            '<(PRODUCT_DIR)/dart-sdk/README',
          ],
          'action': [
            'python',
            'tools/create_sdk.py',
            '<(PRODUCT_DIR)/dart-sdk',
          ],
          'message': 'Creating SDK.',
          'conditions' : [
            ['(OS=="linux" or OS=="mac") ', {
              'inputs' : [
                '<(PRODUCT_DIR)/analyzer/bin/dart_analyzer'
              ],
            }],
          ],
        },
      ],
      'conditions' : [
        ['(OS=="linux" or OS=="mac") ', {
          'dependencies': [
            'compiler',
          ],
        }],
      ],
    },
    {
      # Upload the SDK. This target is separate from create_sdk as the
      # editor needs to build the SDK without uploading it.
      'target_name': 'upload_sdk',
      'type': 'none',
      'dependencies': [
        'create_sdk',
      ],
      'actions': [
        {
          'action_name': 'upload_sdk_py',
          'inputs': [
            '<(PRODUCT_DIR)/dart-sdk/README',
            'tools/upload_sdk.py',
          ],
          'outputs': [
            '<(PRODUCT_DIR)/dart-sdk/upload.stamp',
          ],
          'action': [
            'python',
            'tools/upload_sdk.py',
            '<(PRODUCT_DIR)/dart-sdk'
          ],
        },
      ],
    },
    {
      'target_name': 'dart2js',
      'type': 'none',
      'dependencies': [
        'third_party/v8/src/d8.gyp:d8',
        'utils/compiler/compiler.gyp:dart2js',
      ],
    },
    {
      # This is the target that is built on the dart2js build bots.
      # It must depend on anything that is required by the dart2js
      # test suites.
      'target_name': 'dart2js_bot',
      'type': 'none',
      'dependencies': [
        'third_party/v8/src/d8.gyp:d8',
        'create_sdk',
        'packages',
      ],
    },
    {
      'target_name': 'api_docs',
      'type': 'none',
      'dependencies': [
        'utils/apidoc/apidoc.gyp:api_docs',
      ],
    },
    {
      'target_name': 'samples',
      'type': 'none',
      'dependencies': [
        'samples/sample_extension/sample_extension.gyp:sample_extension',
      ],
    },
    {
      'target_name': 'packages',
      'type': 'none',
      'dependencies': [
        'pkg/pkg.gyp:pkg_packages',
      ],
    },
  ],
}
