# Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

{
  'targets': [
    {
      'target_name': 'dartfmt',
      'type': 'none',
      'dependencies': [
        '../../runtime/dart-runtime.gyp:dart',
        '../../pkg/pkg.gyp:pkg_packages',
      ],
      'actions': [
        {
          'action_name': 'generate_dartfmt_snapshot',
          'inputs': [
            '<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)dart<(EXECUTABLE_SUFFIX)',
            '../../sdk/lib/_internal/libraries.dart',
            '<(SHARED_INTERMEDIATE_DIR)/packages.stamp',
            '<!@(["python", "../../tools/list_files.py", "\\.dart$", "../../pkg/analyzer"])',
          ],
          'outputs': [
            '<(SHARED_INTERMEDIATE_DIR)/dartfmt.dart.snapshot',
          ],
          'action': [
            '<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)dart<(EXECUTABLE_SUFFIX)',
            '--snapshot=<(SHARED_INTERMEDIATE_DIR)/dartfmt.dart.snapshot',
            '--package-root=<(PRODUCT_DIR)/packages/',
            '../../pkg/analyzer/bin/formatter.dart',
          ],
        },
      ],
    },
  ],
}
