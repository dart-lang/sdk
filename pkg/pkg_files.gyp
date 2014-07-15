# Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

{
  'targets': [
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
            '<!@(["python", "../tools/list_files.py", "\\.dart$", "."])',
            '<(SHARED_INTERMEDIATE_DIR)/third_party_pkg_files.stamp',
          ],
          'outputs': [
            '<(SHARED_INTERMEDIATE_DIR)/pkg_files.stamp',
          ],
          'action': [
            'python', '../tools/create_timestamp_file.py',
            '<@(_outputs)',
          ],
        },
        {
          'action_name': 'make_third_party_pkg_files_stamp',
          'inputs': [
            '../tools/create_timestamp_file.py',
            '<!@(["python", "../tools/list_files.py", "\\.dart$",'
                '"../third_party/pkg"])',
          ],
          'outputs': [
            '<(SHARED_INTERMEDIATE_DIR)/third_party_pkg_files.stamp',
          ],
          'action': [
            'python', '../tools/create_timestamp_file.py',
            '<@(_outputs)',
          ],
        },
      ],
    },
    {
      'target_name': 'http_files_stamp',
      'type': 'none',
      'actions': [
        {
          'action_name': 'make_http_files_stamp',
          'inputs': [
            '../tools/create_timestamp_file.py',
            '<!@(["python", "../tools/list_files.py", "\\.dart$", "http/lib"])',
          ],
          'outputs': [
            '<(SHARED_INTERMEDIATE_DIR)/http_files.stamp',
          ],
          'action': [
            'python', '../tools/create_timestamp_file.py',
            '<@(_outputs)',
          ],
        },
      ],
    },
  ],
}
