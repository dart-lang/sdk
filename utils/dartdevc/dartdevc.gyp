# Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

{
  'targets': [
    {
      'target_name': 'dartdevc',
      'type': 'none',
      'dependencies': [
        '../../runtime/dart-runtime.gyp:dart',
        '../../pkg/pkg.gyp:pkg_packages',
      ],
      'actions': [
        {
          'action_name': 'generate_dartdevc_snapshot',
          'inputs': [
            '<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)dart<(EXECUTABLE_SUFFIX)',
            '../../sdk/lib/_internal/sdk_library_metadata/lib/libraries.dart',
            '<!@(["python", "../../tools/list_files.py", "\\.dart$", "../../pkg/dev_compiler/bin"])',
            '<(SHARED_INTERMEDIATE_DIR)/packages.stamp',
            '<(SHARED_INTERMEDIATE_DIR)/pkg_files.stamp',
          ],
          'outputs': [
            '<(SHARED_INTERMEDIATE_DIR)/dartdevc.dart.snapshot',
          ],
          'action': [
            '<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)dart<(EXECUTABLE_SUFFIX)',
            '--snapshot=<(SHARED_INTERMEDIATE_DIR)/dartdevc.dart.snapshot',
            '--package-root=<(PRODUCT_DIR)/packages/',
            '../../pkg/dev_compiler/bin/dartdevc.dart'
          ],
        },
      ],
    },
  ],
}
