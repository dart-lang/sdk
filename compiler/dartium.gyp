# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# TODO(vsm): Remove this file and use dart.gyp once that can be pulled
# into the dartium build.
{
  'includes': [
    # TODO(mmendez): Add the appropriate gypi includes here.
  ],
  'targets': [
    {
      'target_name': 'dartc',
      'type': 'none',
      'actions': [
        {
          'action_name': 'Build and test',
          'inputs': [
          ],
          'outputs': [
            'dummy_target',
          ],
          'action' : [
            '../third_party/apache_ant/1.8.4/bin/ant',
            '-Dbuild.dir=<(PRODUCT_DIR)/ant-out',
            'clean',
            'dist',
          ],
          'message': 'Building dartc.',
        },
      ],
    },
    {
      # GYP won't generate a catch-all target if there's only one target.
      'target_name': 'dummy',
      'type': 'none',
    },
  ],
}
