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
            '<(PRODUCT_DIR)/packages/args',
            '<(PRODUCT_DIR)/packages/fixnum',
            '<(PRODUCT_DIR)/packages/htmlescape',
            '<(PRODUCT_DIR)/packages/http',
            '<(PRODUCT_DIR)/packages/intl',
            '<(PRODUCT_DIR)/packages/logging',
            '<(PRODUCT_DIR)/packages/meta',
            '<(PRODUCT_DIR)/packages/unittest',
            '<(PRODUCT_DIR)/packages/webdriver',
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
