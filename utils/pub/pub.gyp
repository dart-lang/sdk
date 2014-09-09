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
        '../../pkg/pkg.gyp:pub_packages',
        '../../pkg/pkg_files.gyp:pkg_files_stamp',
        '../../utils/compiler/compiler.gyp:dart2js_files_stamp',
        'pub_files_stamp'
      ],
      'actions': [
        {
          'action_name': 'generate_pub_snapshot',
          'inputs': [
            '<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)dart<(EXECUTABLE_SUFFIX)',
            '../../sdk/lib/_internal/libraries.dart',
            '<(SHARED_INTERMEDIATE_DIR)/pub_files.stamp',
            '<(SHARED_INTERMEDIATE_DIR)/dart2js_files.stamp',
            '<(SHARED_INTERMEDIATE_DIR)/pkg_files.stamp',
            '<(SHARED_INTERMEDIATE_DIR)/pub_packages.stamp',
          ],
          'outputs': [
            '<(SHARED_INTERMEDIATE_DIR)/pub.dart.snapshot',
          ],
          'action': [
            '<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)dart<(EXECUTABLE_SUFFIX)',
            '--package-root=<(PRODUCT_DIR)/pub_packages/',
            '--snapshot=<(SHARED_INTERMEDIATE_DIR)/pub.dart.snapshot',
            '../../sdk/lib/_internal/pub_generated/bin/pub.dart',
          ]
        },
      ],
    },
    {
      'target_name': 'core_stubs',
      'type': 'none',
      'dependencies': [
        '../../runtime/dart-runtime.gyp:dart',
        '../../pkg/pkg.gyp:pkg_packages',
        '../../pkg/pkg_files.gyp:pkg_files_stamp'
      ],
      'actions': [
        {
          'action_name': 'generate_core_stubs',
          'inputs': [
            '<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)dart<(EXECUTABLE_SUFFIX)',
            '../../sdk/lib/_internal/libraries.dart',
            '<(SHARED_INTERMEDIATE_DIR)/pkg_files.stamp',
          ],
          'outputs': [
            '<(SHARED_INTERMEDIATE_DIR)/core_stubs/dart_io.dart',
          ],
          'action': [
            '<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)dart<(EXECUTABLE_SUFFIX)',
            '--package-root=<(PRODUCT_DIR)/packages/',
            '../../pkg/stub_core_library/bin/stub_core_library.dart',
            '<(SHARED_INTERMEDIATE_DIR)/core_stubs',
          ],
        }
      ]
    },
    # Other targets depend on pub files, but have to many inputs, which causes
    # issues on some platforms.
    # This target lists all the files in sdk/lib/_internal/pub,
    # and creates a single pub_files.stamp
    {
      'target_name': 'pub_files_stamp',
      'type': 'none',
      'actions': [
        {
          'action_name': 'make_pub_files_stamp',
          'inputs': [
            '../../tools/create_timestamp_file.py',
            '<!@(["python", "../../tools/list_files.py", "\\.dart$",'
                ' "../../sdk/lib/_internal/pub"])',
          ],
          'outputs': [
            '<(SHARED_INTERMEDIATE_DIR)/pub_files.stamp',
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
