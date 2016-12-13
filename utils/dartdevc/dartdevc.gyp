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
      ],
      'actions': [
        {
          'action_name': 'generate_dartdevc_snapshot',
          'inputs': [
            '<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)dart<(EXECUTABLE_SUFFIX)',
            '../../sdk/lib/_internal/sdk_library_metadata/lib/libraries.dart',
            '<!@(["python", "../../tools/list_dart_files.py", "relative", '
                '"../../pkg/dev_compiler/bin"])',
            '<(SHARED_INTERMEDIATE_DIR)/pkg_files.stamp',
          ],
          'outputs': [
            '<(SHARED_INTERMEDIATE_DIR)/dartdevc.dart.snapshot',
          ],
          'action': [
            '<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)dart<(EXECUTABLE_SUFFIX)',
            '--packages=../../.packages',
            '--snapshot=<(SHARED_INTERMEDIATE_DIR)/dartdevc.dart.snapshot',
            '../../pkg/dev_compiler/bin/dartdevc.dart'
          ],
        },
      ],
    },
  ],
}
