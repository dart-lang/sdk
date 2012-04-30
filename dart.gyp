# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

{
  'targets': [
    {
      'target_name': 'compiler',
      'type': 'none',
      'dependencies': [
        'compiler/dart-compiler.gyp:dartc',
      ],
      'actions': []
    },
    {
      'target_name': 'runtime',
      'type': 'none',
      'dependencies': [
        'runtime/dart-runtime.gyp:dart',
        'runtime/dart-runtime.gyp:run_vm_tests',
        'runtime/dart-runtime.gyp:process_test',
      ],
    },
    {
      'target_name': 'sdk',
      'type': 'none',
      'dependencies': [
        'runtime/dart-runtime.gyp:dart',
      ],
      'actions': [
        {
          'action_name': 'create_sdk',
          'inputs': [
            '<!@(["python", "frog/scripts/list_frog_files.py", "frog"])',
            # TODO(dgrove) - change these to dependencies and add dom
            # dependences once issues 754 and 755 are fixed
            'lib/html/html_frog.dart',
            'lib/html/html_dartium.dart',
            'lib/dom/dom.dart',
            'lib/dom/src',
            'frog/scripts/bootstrap/frogc',
            'tools/create_sdk.py',
            '<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)dart<(EXECUTABLE_SUFFIX)',
          ],
          'outputs': [
            '<(PRODUCT_DIR)/dart-sdk/create.stamp',
          ],
          'action': [
            'python',
            'tools/create_sdk.py',
            '<(PRODUCT_DIR)/dart-sdk',
          ],
          'message': 'Creating SDK.',
        },
        {
          'action_name': 'upload_sdk',
          'inputs': [
            '<(PRODUCT_DIR)/dart-sdk/create.stamp',
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
        'utils/compiler/compiler.gyp:dart2js',

        # TODO(ahe): Remove dependency on frog, it is just here to
        # simplify frog/scripts/buildbot_annotated_steps.py
        # temporarily.
        'frog/dart-frog.gyp:frog',
      ],
    },
    {
      'target_name': 'api_docs',
      'type': 'none',
      'dependencies': [
        'utils/apidoc/apidoc.gyp:api_docs',
      ],
    }
  ],
}
