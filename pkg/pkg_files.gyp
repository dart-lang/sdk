# Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

{
  'targets': [
    # Other targets depend on pkg files, but have too many inputs, which causes
    # issues on some platforms.
    # This target lists all the files in pkg and third_party/pkg,
    # and creates the timestamp pkg_files.stamp, which depends on some
    # intermediate helper timestamps.
    # We split third_party/pkg up into three groups, based on the last
    # character before .dart at the end of the filename.
    {
      'target_name': 'pkg_files_stamp',
      'type': 'none',
      'actions': [
        {
          'action_name': 'make_pkg_files_stamp',
          'inputs': [
            '../tools/create_timestamp_file.py',
            '<!@(["python", "../tools/list_files.py",'
                '"^(?!.*/test/).*(?<!_test)[.]dart$",'
                '"."])',
            '<(SHARED_INTERMEDIATE_DIR)/third_party_pkg_files_1.stamp',
            '<(SHARED_INTERMEDIATE_DIR)/third_party_pkg_files_2.stamp',
            '<(SHARED_INTERMEDIATE_DIR)/third_party_pkg_files_3.stamp',
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
          'action_name': 'make_third_party_pkg_files_1_stamp',
          'inputs': [
            '../tools/create_timestamp_file.py',
            '<!@(["python", "../tools/list_files.py",'
                '"^(?!.*_test\.dart).*[a-k]\.dart$",'
                '"../third_party/pkg"])',
          ],
          'outputs': [
            '<(SHARED_INTERMEDIATE_DIR)/third_party_pkg_files_1.stamp',
          ],
          'action': [
            'python', '../tools/create_timestamp_file.py',
            '<@(_outputs)',
          ],
        },
        {
          'action_name': 'make_third_party_pkg_files_2_stamp',
          'inputs': [
            '../tools/create_timestamp_file.py',
            '<!@(["python", "../tools/list_files.py",'
                '"^(?!.*_test\.dart).*[l-r]\.dart$",'
                '"../third_party/pkg"])',
          ],
          'outputs': [
            '<(SHARED_INTERMEDIATE_DIR)/third_party_pkg_files_2.stamp',
          ],
          'action': [
            'python', '../tools/create_timestamp_file.py',
            '<@(_outputs)',
          ],
        },
        {
          'action_name': 'make_third_party_pkg_files_3_stamp',
          'inputs': [
            '../tools/create_timestamp_file.py',
            '<!@(["python", "../tools/list_files.py",'
                '"^(?!.*_test\.dart).*[^a-r]\.dart$",'
                '"../third_party/pkg"])',
          ],
          'outputs': [
            '<(SHARED_INTERMEDIATE_DIR)/third_party_pkg_files_3.stamp',
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
