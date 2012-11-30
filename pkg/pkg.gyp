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
            'args/lib',
            'fixnum/lib',
            'htmlescape/lib',
            'http/lib',
            'intl/lib',
            'logging/lib',
            'meta/lib',
            'unittest/lib',
            'webdriver/lib',
          ],
          'outputs': [
            '<(PRODUCT_DIR)/packages',
          ],
          'action': [
            'python', '../tools/make_links.py',
            '<(PRODUCT_DIR)/packages',
            '<@(_inputs)',
          ],
        },
      ],
    }
  ],
}
