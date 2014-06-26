# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

{
  'targets': [
    {
      'target_name': 'pkg_packages',
      'type': 'none',
      'actions': [
        {
          'action_name': 'make_pkg_packages',
          'inputs': [
            '../tools/make_links.py',
            '<!@(["python", "../tools/list_pkg_directories.py", "."])',
            '<!@(["python", "../tools/list_pkg_directories.py", '
                '"third_party"])',
            '<!@(["python", "../tools/list_pkg_directories.py", '
                '"../third_party/pkg"])',
            '<!@(["python", "../tools/list_pkg_directories.py", '
                '"polymer/e2e_test/"])',
            '../sdk/lib/_internal/compiler',
            '../sdk/lib/_internal/libraries.dart',
            '../site/try',
          ],
          'outputs': [
            '<(SHARED_INTERMEDIATE_DIR)/packages.stamp',
          ],
          'action': [
            'python', '../tools/make_links.py',
            '--timestamp_file=<(SHARED_INTERMEDIATE_DIR)/packages.stamp',
            '<(PRODUCT_DIR)/packages',
            '<@(_inputs)',
          ],
        },
      ],
    },
  ],
}
