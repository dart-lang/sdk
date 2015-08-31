# Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

{
  'targets': [
    {
      'target_name': 'dartanalyzer',
      'type': 'none',
      'dependencies': [
        '../../runtime/dart-runtime.gyp:dart',
        '../../pkg/pkg.gyp:pkg_packages',
      ],
      'actions': [
        {
          'action_name': 'generate_dartanalyzer_snapshot',
          'inputs': [
            '<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)dart<(EXECUTABLE_SUFFIX)',
            '../../sdk/lib/_internal/sdk_library_metadata/lib/libraries.dart',
            '<(SHARED_INTERMEDIATE_DIR)/packages.stamp',
            '<!@(["python", "../../tools/list_files.py", "\\.dart$", "../../third_party/pkg/analyzer_cli"])',
          ],
          'outputs': [
            '<(SHARED_INTERMEDIATE_DIR)/dartanalyzer.dart.snapshot',
          ],
          'action': [
            '<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)dart<(EXECUTABLE_SUFFIX)',
            '--snapshot=<(SHARED_INTERMEDIATE_DIR)/dartanalyzer.dart.snapshot',
            '--package-root=<(PRODUCT_DIR)/packages/',
            '../../third_party/pkg/analyzer_cli/bin/analyzer.dart',
          ],
        },
      ],
    },
  ],
}
