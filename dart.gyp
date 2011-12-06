# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

{
  'targets': [
    {
      'target_name': 'compiler',
      'type': 'none',
      'dependencies': [
        'compiler/dart-compiler.gyp:dartc',
      ],
      'actions': []
    },
    {
      'target_name': 'runtime',
      'type': 'none',
      'dependencies': [
        'runtime/dart-runtime.gyp:dart',
        'runtime/dart-runtime.gyp:run_vm_tests',
        'runtime/dart-runtime.gyp:process_test',
      ],
    },
    {
      'target_name': 'frog',
      'type': 'none',
      'dependencies': [
        'frog/dart-frog.gyp:frog',
      ],
    },
    {
      'target_name': 'frogsh',
      'type': 'none',
      'dependencies': [
        'frog/dart-frog.gyp:frogsh',
      ],
    },
    {
      'target_name': 'sdk',
      'type': 'none',
      'dependencies': [
        'frog',
        'runtime/dart-runtime.gyp:dart',
      ],
      'actions': [
        {
          'action_name': 'create_sdk',
          'inputs': [
            'tools/create_sdk.py',
          ],
          'outputs': [
            '<(PRODUCT_DIR)/sdk',
          ],
          'action': [
            'python',
            'tools/create_sdk.py',
            '<(PRODUCT_DIR)/sdk'
          ],
          'message': 'Creating SDK.',
        },
      ],
    },
    {
      'target_name': 'upload_sdk',
      'type': 'none',
      'dependencies': [
        'sdk',
      ],
      'actions': [
        {
          'action_name': 'upload_sdk',
          'inputs': [
            '<(PRODUCT_DIR)/sdk',
            'tools/upload_sdk.py',
          ],
          'outputs': [
            '<(PRODUCT_DIR)/sdk',
          ],
          'action': [
            'python',
            'tools/upload_sdk.py',
            '<(PRODUCT_DIR)/sdk'
          ],
        },
      ],
    }
    # TODO(ngeoffray): Fling does not have proper dependencies,
    # so don't build it for now.
    #{
    #  'target_name': 'client',
    #  'type': 'none',
    #  'dependencies': [
    #    'client/dart.gyp:fling',
    #  ],
    #},
  ],
}
