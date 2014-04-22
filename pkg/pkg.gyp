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
                '"polymer/example/"])',
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
    # Other targets depend on pkg files, but have to many inputs, which causes
    # issues on some platforms.
    # This target lists all the files in pkg and third_party/pkg,
    # and creates a single pkg_files.stamp
    {
      'target_name': 'pkg_files_stamp',
      'type': 'none',
      'actions': [
        {
          'action_name': 'make_pkg_files_stamp',
          'inputs': [
            '../tools/create_timestamp_file.py',
            '<!@(["python", "../tools/list_files.py", "", "."])',
            '<!@(["python", "../tools/list_files.py", "",'
                '"../third_party/pkg"])',
          ],
          'outputs': [
            '<(SHARED_INTERMEDIATE_DIR)/pkg_files.stamp',
          ],
          'action': [
            'python', '../tools/create_timestamp_file.py',
            '<@(_outputs)',
          ],
        },
      ],
    }
  ],
}
