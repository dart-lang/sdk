# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

{
  'variables': {
    # These variables are used in the creation of the .vcproj file on
    # Windows.
    'cygwin_dir': '../../third_party/cygwin',
  },
  'targets': [
    {
      'target_name': 'api_docs',
      'type': 'none',
      'dependencies': [
        '../../frog/dart-frog.gyp:frog',
        '../../runtime/dart-runtime.gyp:dart',
      ],
      'conditions': [
        ['OS=="win"', {
          'msvs_cygwin_dirs': ['<(cygwin_dir)'],
        }],
      ],
      'actions': [
        {
          'action_name': 'run_apidoc',
          'inputs': [
            '<(PRODUCT_DIR)/dart',
            '<!@(["python", "scripts/list_files.py"])',
          ],
          'outputs': [
            '<(PRODUCT_DIR)/api_docs',
          ],
          'action': [
            '<(PRODUCT_DIR)/dart',
            'apidoc.dart',
            '--out=<(PRODUCT_DIR)/api_docs',
            '--mode=live-nav'
          ],
        },
      ],
    }
  ],
}
