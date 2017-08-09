# Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

{
  'variables': {
    'gen_source_dir': '<(SHARED_INTERMEDIATE_DIR)',
  },
  'targets': [
    {
      'target_name': 'build_observatory',
      'type': 'none',
      'dependencies': [
        'dart_bootstrap#host',
      ],
      'toolsets': ['host'],
      'includes': [
        'observatory_sources.gypi',
      ],
      'actions': [
        {
          'action_name': 'pub_build_observatory',
          'inputs': [
            '../../tools/observatory_tool.py',
            '<@(_sources)',
          ],
          'outputs': [
            '<(PRODUCT_DIR)/observatory/build/web/index.html',
          ],
          'action': [
            'python',
            '../tools/observatory_tool.py',
            '--sdk=True',
            '--dart-executable',
            '<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)dart_bootstrap<(EXECUTABLE_SUFFIX)',
            '--directory', 'observatory',
            '--command', 'build',
            '<(PRODUCT_DIR)/observatory/build'
          ],
        },
        {
          'action_name': 'deploy_observatory',
          'inputs': [
            '../../tools/observatory_tool.py',
            '<(PRODUCT_DIR)/observatory/build/web/index.html',
          ],
          'outputs': [
            '<(PRODUCT_DIR)/observatory/deployed/web/index.html',
          ],
          'action': [
            'python',
            '../tools/observatory_tool.py',
            '--sdk=True',
            '--dart-executable',
            '<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)dart_bootstrap<(EXECUTABLE_SUFFIX)',
            '--directory', '<(PRODUCT_DIR)/observatory/',
            '--command', 'deploy',
          ],
        }
      ],
    },
  ],
}
