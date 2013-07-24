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
      ],
      'actions': [
        {
          'action_name': 'generate_dart2js_snapshot',
          'inputs': [
            '<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)dart<(EXECUTABLE_SUFFIX)',
            '../../sdk/lib/_internal/libraries.dart',
            '<!@(["python", "../../tools/list_files.py", "\\.dart$",'
            ' "../../sdk/lib/_internal/compiler", "../../runtime/lib"])',
            '../../sdk/lib/_internal/libraries.dart',
          ],
          'outputs': [
            '<(SHARED_INTERMEDIATE_DIR)/dart2js.dart.snapshot',
          ],
          'action': [
            '<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)dart<(EXECUTABLE_SUFFIX)',
            # Note: we don't store the snapshot in the location where
            # the dart2js script is looking for it.  The motivation
            # for that is to support an incremental development model
            # for dart2js compiler engineers.  However, we install the
            # snapshot in the proper location when building the SDK.
            '--snapshot=<(SHARED_INTERMEDIATE_DIR)/dart2js.dart.snapshot',
            '../../sdk/lib/_internal/compiler/implementation/dart2js.dart',
          ],
        },
        {
          'action_name': 'generate_dartdoc_snapshot',
          'inputs': [
            '<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)dart<(EXECUTABLE_SUFFIX)',
            '../../sdk/lib/_internal/libraries.dart',
            '<!@(["python", "../../tools/list_files.py", "\\.dart$", "../../sdk/lib/_internal/compiler", "../../runtime/lib", "../../sdk/lib/_internal/dartdoc"])',
            'create_snapshot.dart',
            '<(SHARED_INTERMEDIATE_DIR)/packages.stamp',
          ],
          'outputs': [
            '<(SHARED_INTERMEDIATE_DIR)/utils_wrapper.dart.snapshot',
          ],
          'action': [
            '<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)dart<(EXECUTABLE_SUFFIX)',
            'create_snapshot.dart',
            '--output_dir=<(SHARED_INTERMEDIATE_DIR)',
            '--dart2js_main=sdk/lib/_internal/compiler/implementation/dart2js.dart',
            '--dartdoc_main=sdk/lib/_internal/dartdoc/bin/dartdoc.dart',
            '--package_root=<(PRODUCT_DIR)/packages/',
          ],
        },
      ],
    },
  ],
}
