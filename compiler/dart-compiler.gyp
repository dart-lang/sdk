# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

{
  'includes': [
    'sources.gypi',
    'test_sources.gypi',
  ],
  'targets': [
    {
      'target_name': 'dartc',
      'type': 'none',
      'actions': [
        {
          'action_name': 'build_dartc',
          'inputs': [
            'sources.gypi',
            'test_sources.gypi',
            '<@(java_sources)',
            '<@(java_resources)',
            '<@(javatests_sources)',
            '<@(javatests_resources)',
            'dartc.xml',
            'scripts/dartc.sh',
            'scripts/dartc_run.sh',
            'scripts/dartc_metrics.sh',
            '../third_party/args4j/2.0.12/args4j-2.0.12.jar',
            '../third_party/guava/r09/guava-r09.jar',
            '../third_party/hamcrest/v1_3/hamcrest-core-1.3.0RC2.jar',
            '../third_party/hamcrest/v1_3/hamcrest-generator-1.3.0RC2.jar',
            '../third_party/hamcrest/v1_3/hamcrest-integration-1.3.0RC2.jar',
            '../third_party/hamcrest/v1_3/hamcrest-library-1.3.0RC2.jar',
          ],
          'outputs': [
            '<(INTERMEDIATE_DIR)/<(_target_name)/tests.jar',
            '<(PRODUCT_DIR)/compiler/bin/dartc',
            '<(PRODUCT_DIR)/compiler/lib/args4j/2.0.12/args4j-2.0.12.jar',
            '<(PRODUCT_DIR)/compiler/lib/dartc.jar',
            '<(PRODUCT_DIR)/compiler/lib/guava/r09/guava-r09.jar',
          ],
          'action' : [
            '../third_party/apache_ant/v1_7_1/bin/ant',
            '-f', 'dartc.xml',
            '-Dbuild.dir=<(INTERMEDIATE_DIR)/<(_target_name)',
            '-Ddist.dir=<(PRODUCT_DIR)/compiler',
            'clean',
            'dist',
            'tests.jar',
          ],
          'message': 'Building dartc.',
        },
        {
          'action_name': 'copy_tests',
          'inputs': [ '<(INTERMEDIATE_DIR)/<(_target_name)/tests.jar' ],
          'outputs': [ '<(PRODUCT_DIR)/compiler-tests.jar' ],
          'action': [ 'cp', '<@(_inputs)', '<@(_outputs)' ]
        },
        {
          'action_name': 'copy_dartc_wrapper',
          'inputs': [
            '<(PRODUCT_DIR)/compiler/lib/dartc.jar',
            'scripts/dartc_wrapper.py',
          ],
          'outputs': [ '<(PRODUCT_DIR)/dartc' ],
          'action': [ 'cp', 'scripts/dartc_wrapper.py', '<@(_outputs)' ]
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
