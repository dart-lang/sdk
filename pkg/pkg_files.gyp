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
    # We split third_party/pkg up into three groups, based on the first letter
    # of the package name.
    {
      'target_name': 'pkg_files_stamp',
      'type': 'none',
      'actions': [
        {
          'action_name': 'make_pkg_files_stamp',
          'inputs': [
            '../tools/create_timestamp_file.py',
            '<!@(["python", "../tools/list_dart_files.py", "relative", "."])',
            '<(SHARED_INTERMEDIATE_DIR)/third_party_pkg_files_a_k.stamp',
            '<(SHARED_INTERMEDIATE_DIR)/third_party_pkg_files_l_r.stamp',
            '<(SHARED_INTERMEDIATE_DIR)/third_party_pkg_files_s_z.stamp',
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
          'action_name': 'make_third_party_pkg_files_a_k_stamp',
          'inputs': [
            '../tools/create_timestamp_file.py',
            '<!@(["python", "../tools/list_dart_files.py", "relative", '
                '"../third_party/pkg", "[a-k].*"])',
          ],
          'outputs': [
            '<(SHARED_INTERMEDIATE_DIR)/third_party_pkg_files_a_k.stamp',
          ],
          'action': [
            'python', '../tools/create_timestamp_file.py',
            '<@(_outputs)',
          ],
        },
        {
          'action_name': 'make_third_party_pkg_files_l_r_stamp',
          'inputs': [
            '../tools/create_timestamp_file.py',
            '<!@(["python", "../tools/list_dart_files.py", "relative", '
                '"../third_party/pkg", "[l-r].*"])',
          ],
          'outputs': [
            '<(SHARED_INTERMEDIATE_DIR)/third_party_pkg_files_l_r.stamp',
          ],
          'action': [
            'python', '../tools/create_timestamp_file.py',
            '<@(_outputs)',
          ],
        },
        {
          'action_name': 'make_third_party_pkg_files_s_z_stamp',
          'inputs': [
            '../tools/create_timestamp_file.py',
            '<!@(["python", "../tools/list_dart_files.py", "relative", '
                '"../third_party/pkg", "[s-z].*"])',
          ],
          'outputs': [
            '<(SHARED_INTERMEDIATE_DIR)/third_party_pkg_files_s_z.stamp',
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
