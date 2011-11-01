# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

{
  'includes': [
    'fling/fling.gypi',
  ],
  'targets': [
    {
      # this target is needed because gyp fails on Mac if there is a single
      # target
      'target_name': 'noop',
      'type': 'none',
      'actions': [],
    },
    {
      'target_name': 'fling',
      'type': 'none',
      'dependencies': ['../compiler/dart-compiler.gyp:dartc'],
      'actions' : [
        {
          'action_name': 'Build Fling',
          'inputs': [
            'fling/fling.gypi',
            '<@(fling_sources)',
            '<@(fling_resources)',
            '<(PRODUCT_DIR)/dartc',
          ],
          'outputs' :[
            '<(PRODUCT_DIR)/fling/runtime/fling.jar',
          ],
          'action': [
            '../third_party/apache_ant/v1_7_1/bin/ant',
            '-f', 'fling/build.xml',
            '-Dbuild.dir=<(PRODUCT_DIR)',
            'build',
            'setup-eclipse',
          ],
          'message': 'Running Fling build actions.',
        }
      ],
    },
  ],
}

