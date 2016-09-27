# Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

{
  'targets': [
    {
      'target_name': 'analysis_server',
      'type': 'none',
      'dependencies': [
        '../../runtime/dart-runtime.gyp:dart',
        '../../pkg/pkg_files.gyp:pkg_files_stamp'
      ],
      'actions': [
        {
          'action_name': 'generate_analysis_server_snapshot',
          'inputs': [
            '<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)dart<(EXECUTABLE_SUFFIX)',
            '../../sdk/lib/_internal/sdk_library_metadata/lib/libraries.dart',
            '<(SHARED_INTERMEDIATE_DIR)/pkg_files.stamp',
          ],
          'outputs': [
            '<(SHARED_INTERMEDIATE_DIR)/analysis_server.dart.snapshot',
          ],
          'action': [
            '<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)dart<(EXECUTABLE_SUFFIX)',
            '--packages=../../.packages',
            '--snapshot=<(SHARED_INTERMEDIATE_DIR)/analysis_server.dart.snapshot',
            '../../pkg/analysis_server/bin/server.dart',
          ],
        },
      ],
    },
  ],
}
