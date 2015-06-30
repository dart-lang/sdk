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
                '"../third_party/pkg"])',
            '<!@(["python", "../tools/list_pkg_directories.py", '
                '"../third_party/pkg_tested"])',
            '<!@(["python", "../tools/list_pkg_directories.py", '
                '"../runtime"])',
            '../sdk/lib/_internal/js_runtime/lib',
            '../sdk/lib/_internal/sdk_library_metadata/lib',
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
            # Pub imports dart2js as compiler_unsupported so it can work outside
            # the SDK. Map that to the compiler package.
            'compiler/lib:compiler_unsupported'
          ],
        },
      ],
    }
  ],
}
