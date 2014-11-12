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
        '../../pkg/pkg.gyp:pkg_packages',
        'dart2js_files_stamp',
      ],
      'actions': [
        {
          'action_name': 'generate_snapshots',
          'inputs': [
            '<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)dart<(EXECUTABLE_SUFFIX)',
            '../../sdk/lib/_internal/libraries.dart',
            '<!@(["python", "../../tools/list_files.py", "\\.dart$", "../../runtime/lib", "../../sdk/lib/_internal/dartdoc"])',
            'create_snapshot.dart',
            '<(SHARED_INTERMEDIATE_DIR)/dart2js_files.stamp',
            '<(SHARED_INTERMEDIATE_DIR)/packages.stamp',
            '../../tools/VERSION',
          ],
          'outputs': [
            '<(SHARED_INTERMEDIATE_DIR)/utils_wrapper.dart.snapshot',
            '<(SHARED_INTERMEDIATE_DIR)/dart2js.dart.snapshot',
          ],
          'action': [
            '<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)dart<(EXECUTABLE_SUFFIX)',
            'create_snapshot.dart',
            '--output_dir=<(SHARED_INTERMEDIATE_DIR)',
            '--dart2js_main=pkg/compiler/lib/src/dart2js.dart',
            '--docgen_main=pkg/docgen/bin/docgen.dart',
            '--package_root=<(PRODUCT_DIR)/packages/',
          ],
        },
      ],
    },
    # Other targets depend on dart2js files, but have to many inputs,
    # which causes issues on some platforms.
    # This target lists all the files in pkg/compiler,
    # and creates a single dart2js_files.stamp
    {
      'target_name': 'dart2js_files_stamp',
      'type': 'none',
      'actions': [
        {
          'action_name': 'make_dart2js_files_stamp',
          'inputs': [
            '../../tools/create_timestamp_file.py',
            '<!@(["python", "../../tools/list_files.py", "\\.dart$",'
                ' "../../pkg/compiler/lib"])',
          ],
          'outputs': [
            '<(SHARED_INTERMEDIATE_DIR)/dart2js_files.stamp',
          ],
          'action': [
            'python', '../../tools/create_timestamp_file.py',
            '<@(_outputs)',
          ],
        },
      ],
    }
  ],
}
