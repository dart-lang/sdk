# Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

{
  'targets': [
    {
      'target_name': 'create_sdk_internal',
      'type': 'none',
      'dependencies': [
        'runtime/dart-runtime.gyp:dart',
        'utils/compiler/compiler.gyp:dart2js',
        'utils/pub/pub.gyp:pub',
        'utils/dartfmt/dartfmt.gyp:dartfmt',
        'utils/dartdoc/dartdoc.gyp:dartdoc',
        'utils/analysis_server/analysis_server.gyp:analysis_server',
        'utils/dartanalyzer/dartanalyzer.gyp:dartanalyzer',
      ],
      'actions': [
        {
          'action_name': 'create_sdk_py',
          'inputs': [
            # This is neccessary because we have all the pub test files inside
            # the pub directory instead of in tests/pub. Xcode can only handle
            # a certain amount of files in one list (also depending on the
            # length of the path from where you run). This regexp excludes
            # pub/test
            '<!@(["python", "tools/list_files.py",'
                '"^(?!.*pub/test).*dart$",'
                '"sdk/lib"])',
            '<!@(["python", "tools/list_files.py", "", '
                '"sdk/lib/_internal/js_runtime/lib/preambles"])',
            '<!@(["python", "tools/list_files.py", "", "sdk/bin"])',
            'tools/create_sdk.py',
            '<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)dart<(EXECUTABLE_SUFFIX)',
            '<(SHARED_INTERMEDIATE_DIR)/dart2js.dart.snapshot',
            '<(SHARED_INTERMEDIATE_DIR)/utils_wrapper.dart.snapshot',
            '<(SHARED_INTERMEDIATE_DIR)/pub.dart.snapshot',
            '<(SHARED_INTERMEDIATE_DIR)/dartanalyzer.dart.snapshot',
            '<(SHARED_INTERMEDIATE_DIR)/dartfmt.dart.snapshot',
            '<(SHARED_INTERMEDIATE_DIR)/analysis_server.dart.snapshot',
            '<(SHARED_INTERMEDIATE_DIR)/dartdoc.dart.snapshot',
            'tools/VERSION'
          ],
          'outputs': [
            '<(PRODUCT_DIR)/dart-sdk/README',
          ],
          'action': [
            'python',
            'tools/create_sdk.py',
            '--sdk_output_dir', '<(PRODUCT_DIR)/dart-sdk',
            '--snapshot_location', '<(SHARED_INTERMEDIATE_DIR)/'
          ],
          'message': 'Creating SDK.',
        },
      ],
    },
  ],
}
