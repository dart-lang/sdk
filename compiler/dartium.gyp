# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# TODO(vsm): Remove this file and use dart.gyp once that can be pulled
# into the dartium build.
{
  'includes': [
    # TODO(iposva): Move shared gyp setup to a shared location.
    '../tools/gyp/xcode.gypi',
    # TODO(mmendez): Add the appropriate gypi includes here.
    'closure_compiler_sources.gypi',
  ],
  'targets': [
    {
      'target_name': 'dartc',
      'type': 'none',
      'dependencies': [
        'closure_compiler',
      ],
      'actions': [
        {
          'action_name': 'Build and test',
          'inputs': [
          ],
          'outputs': [
            'dummy_target',
          ],
          'action' : [
            '../third_party/apache_ant/v1_7_1/bin/ant',
            '-Dbuild.dir=<(PRODUCT_DIR)/ant-out',
            '-Dclosure_compiler.jar=<(PRODUCT_DIR)/closure_out/compiler.jar',
            'clean',
            'dist',
          ],
          'message': 'Building dartc.',
        },
      ],
    },
    {
      'target_name': 'closure_compiler',
      'type': 'none',
      'dependencies': [],
      'actions': [
        {
          'action_name': 'build_closure_compiler',
          'inputs': [
            '<@(closure_compiler_src_sources)',
            '<@(closure_compiler_src_resources)',
          ],
          'outputs': [
            '<(PRODUCT_DIR)/closure_out/compiler.jar'  
          ],
          'action': [
            '../third_party/apache_ant/v1_7_1/bin/ant',
            '-f',
            '../third_party/closure_compiler_src/build.xml',
            '-Dclosure.build.dir=<(PRODUCT_DIR)/closure_out',
            'clean',
            'jar',
          ],
          'message': 'Building closure compiler'
        },
      ]
    }
  ],
}
