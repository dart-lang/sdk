# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

{
  'includes': [
    'dart_server.gypi',
    'fling/fling.gypi',
  ],
  'targets': [
    {
      'target_name': 'dartserver',
      'type': 'none',
      'dependencies': ['../compiler/dart-compiler.gyp:dartc'],
      'actions': [
        {
          'action_name': 'Build DartServer',
          'inputs': [
            'dart_server.gypi',
            '<@(dart_server_sources)',
            '<@(dart_server_resources)',
            '<(PRODUCT_DIR)/dartc',
          ],
          'outputs': [
            '<(PRODUCT_DIR)/dartserver/dartserver.jar',
          ],
          'action' : [
            '../third_party/apache_ant/v1_7_1/bin/ant',
            '-f', 'tools/dartserver/build.xml',
            '-Dbuild.dir=<(PRODUCT_DIR)',
            'clean',
            'build'
          ],
          'message': 'Running DartServer build actions.',
        },
      ],
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

