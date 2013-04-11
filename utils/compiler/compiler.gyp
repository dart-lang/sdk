# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

{
  'variables': {
    'dart_dir': '../..',
  },
  'targets': [
    {
      'target_name': 'dart2js',
      'type': 'none',
      'dependencies': [
        '../../runtime/dart-runtime.gyp:dart',
      ],
      'actions': [
        {
          'action_name': 'generate_dart2js_snapshot',
          'inputs': [
            '<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)dart<(EXECUTABLE_SUFFIX)',
            '../../sdk/lib/_internal/libraries.dart',
            '<!@(["python", "../../tools/list_files.py", "\\.dart$", "../../sdk/lib/_internal/compiler", "../../runtime/lib"])',
          ],
          'outputs': [
            '<(SHARED_INTERMEDIATE_DIR)/utils_wrapper.dart.snapshot',
          ],
          'action': [
            '<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)dart<(EXECUTABLE_SUFFIX)',
            'create_snapshot.dart',
            '--output_dir=<(SHARED_INTERMEDIATE_DIR)',
            '--dart2js_main=sdk/lib/_internal/compiler/implementation/dart2js.dart',
          ],
        },
      ],
    },
  ],
}
