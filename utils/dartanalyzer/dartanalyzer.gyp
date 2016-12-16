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
      ],
      'actions': [
        {
          'action_name': 'generate_dartanalyzer_snapshot',
          'inputs': [
            '<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)dart<(EXECUTABLE_SUFFIX)',
            '../../sdk/lib/_internal/sdk_library_metadata/lib/libraries.dart',
            '<!@(["python", "../../tools/list_dart_files.py", "relative", '
                '"../../pkg/analyzer_cli"])',
            '<!@(["python", "../../tools/list_dart_files.py", "relative", '
                '"../../pkg/analyzer"])',
          ],
          'outputs': [
            '<(SHARED_INTERMEDIATE_DIR)/dartanalyzer.dart.snapshot',
          ],
          'action': [
            '<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)dart<(EXECUTABLE_SUFFIX)',
            '--packages=../../.packages',
            '--snapshot=<(SHARED_INTERMEDIATE_DIR)/dartanalyzer.dart.snapshot',
            '../../pkg/analyzer_cli/bin/analyzer.dart',
          ],
        },
        {
          'action_name': 'generate_summary_spec',
          'inputs': [
            '<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)dart<(EXECUTABLE_SUFFIX)',
            '<!@(["python", "../../tools/list_dart_files.py", "relative", '
                '"../../sdk/lib"])',
            '<!@(["python", "../../tools/list_dart_files.py", "relative", '
                '"../../pkg/analyzer"])',
          ],
          'outputs': [
            '<(SHARED_INTERMEDIATE_DIR)/spec.sum',
          ],
          'action': [
            '<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)dart<(EXECUTABLE_SUFFIX)',
            '--packages=../../.packages',
            '../../pkg/analyzer/tool/summary/build_sdk_summaries.dart',
            'build-spec',
            '<(SHARED_INTERMEDIATE_DIR)/spec.sum',
          ],
        },
        {
          'action_name': 'generate_summary_strong',
          'inputs': [
            '<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)dart<(EXECUTABLE_SUFFIX)',
            '<!@(["python", "../../tools/list_dart_files.py", "relative", '
                '"../../sdk/lib"])',
            '<!@(["python", "../../tools/list_dart_files.py", "relative", '
                '"../../pkg/analyzer"])',
          ],
          'outputs': [
            '<(SHARED_INTERMEDIATE_DIR)/strong.sum',
          ],
          'action': [
            '<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)dart<(EXECUTABLE_SUFFIX)',
            '--packages=../../.packages',
            '../../pkg/analyzer/tool/summary/build_sdk_summaries.dart',
            'build-strong',
            '<(SHARED_INTERMEDIATE_DIR)/strong.sum',
          ],
        },
      ],
    },
  ],
}
