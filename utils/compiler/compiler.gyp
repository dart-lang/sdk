# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

{
  'targets': [
    {
      'target_name': 'dart2js',
      'type': 'none',
      'dependencies': [
        '../../runtime/dart-runtime.gyp:dart',
      ],
      'actions': [
        {
          'action_name': 'build_dart2js',
          'inputs': [
            '<(PRODUCT_DIR)/dart',
            'build_helper.dart',
          ],
          'outputs': [
            '<(PRODUCT_DIR)/dart2js',
            '<(PRODUCT_DIR)/dart2js_developer',
          ],
          'action': [
            '<(PRODUCT_DIR)/dart',
            'build_helper.dart',
            '<(PRODUCT_DIR)',
            'dart',
            'dart2js',
            'dart2js_developer',
          ],
        },
      ],
    },
  ],
}
