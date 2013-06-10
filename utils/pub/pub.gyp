# Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

{
  'targets': [
    {
      'target_name': 'pub',
      'type': 'none',
      'dependencies': [
        '../../runtime/dart-runtime.gyp:dart',
        '../../pkg/pkg.gyp:pkg_packages',
      ],
      'actions': [
        {
          'action_name': 'generate_pub_snapshot',
          'inputs': [
            '<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)dart<(EXECUTABLE_SUFFIX)',
            '<!@(["python", "../../tools/list_files.py", "\\.dart$", "../../sdk/lib/_internal/pub"])',
            '../../sdk/lib/_internal/libraries.dart',
            '<!@(["python", "../../tools/list_files.py", "\\.dart$", "../../sdk/lib/_internal/compiler"])',
            '<!@(["python", "../../tools/list_files.py", "\\.dart$", "../../pkg"])',
          ],
          'outputs': [
            '<(SHARED_INTERMEDIATE_DIR)/pub.dart.snapshot',
          ],
          'action': [
            '<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)dart<(EXECUTABLE_SUFFIX)',
            '--package-root=<(PRODUCT_DIR)/packages/',
            '--snapshot=<(SHARED_INTERMEDIATE_DIR)/pub.dart.snapshot',
            '../../sdk/lib/_internal/pub/bin/pub.dart',
          ],
        },
      ],
    },
  ],
}
