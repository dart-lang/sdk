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
            '<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)gen_snapshot<(EXECUTABLE_SUFFIX)',
            '<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)dart<(EXECUTABLE_SUFFIX)',
            '../../sdk/lib/_internal/libraries.dart',
            '<!@(["python", "../../tools/list_files.py", "\\.dart$", "../../sdk/lib/_internal/compiler", "../../runtime/lib"])',
          ],
          'outputs': [
            '<(PRODUCT_DIR)/dart2js.snapshot',
          ],
          'action': [
            '<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)gen_snapshot<(EXECUTABLE_SUFFIX)',
            # Note: we don't store the snapshot in the location where
            # the dart2js script is looking for it.  The motivation
            # for that is to support an incremental development model
            # for dart2js compiler engineers.  However, we install the
            # snapshot in the proper location when building the SDK.
            '--script_snapshot=<(PRODUCT_DIR)/dart2js.snapshot',
            '../../sdk/lib/_internal/compiler/implementation/dart2js.dart',
          ],
        },
      ],
    },
  ],
}
