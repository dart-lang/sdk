# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

{
  'includes': [
    'sources.gypi',
    'test_sources.gypi',
    'corelib_sources.gypi',
    'compiler_corelib_sources.gypi',
    'closure_compiler_sources.gypi',
  ],
  'targets': [
    {
      'target_name': 'dartc',
      'type': 'none',
      'variables': {
        # The Dartium build has this layout:
        # src/dart/compiler/dart.gyp (this file)
        # src/v8/src/d8.gyp
        'v8_location%': '../../v8',
      },
      'dependencies': [
        '<(v8_location)/src/d8.gyp:d8',
        'closure_compiler',
      ],
      'actions': [
        {
          'action_name': 'build_dartc',
          'inputs': [
            'sources.gypi',
            'test_sources.gypi',
            'corelib_sources.gypi',
            'compiler_corelib_sources.gypi',
            '<@(java_sources)',
            '<@(java_resources)',
            '<@(javatests_sources)',
            '<@(javatests_resources)',
            '<@(corelib_sources)',
            '<@(corelib_resources)',
            '<@(compiler_corelib_sources)',
            '<@(compiler_corelib_resources)',
            'dartc.xml',
            'scripts/dartc.sh',
            'scripts/dartc_test.sh',
            'scripts/dartc_run.sh',
            'scripts/dartc_size.sh',
            'scripts/dartc_metrics.sh',
            '../third_party/args4j/2.0.12/args4j-2.0.12.jar',
            '<(PRODUCT_DIR)/closure_out/compiler.jar',
            '../third_party/guava/r09/guava-r09.jar',
            '../third_party/json/r2_20080312/json.jar',
            '../third_party/rhino/1_7R3/js.jar',
            '../third_party/hamcrest/v1_3/hamcrest-core-1.3.0RC2.jar',
            '../third_party/hamcrest/v1_3/hamcrest-generator-1.3.0RC2.jar',
            '../third_party/hamcrest/v1_3/hamcrest-integration-1.3.0RC2.jar',
            '../third_party/hamcrest/v1_3/hamcrest-library-1.3.0RC2.jar',
          ],
          'outputs': [
            '<(INTERMEDIATE_DIR)/<(_target_name)/tests.jar',
            '<(PRODUCT_DIR)/compiler/bin/dartc',
            '<(PRODUCT_DIR)/compiler/bin/dartc_test',
            '<(PRODUCT_DIR)/compiler/lib/args4j/2.0.12/args4j-2.0.12.jar',
            '<(PRODUCT_DIR)/compiler/lib/closure-compiler.jar',
            '<(PRODUCT_DIR)/compiler/lib/dartc.jar',
            '<(PRODUCT_DIR)/compiler/lib/guava/r09/guava-r09.jar',
            '<(PRODUCT_DIR)/compiler/lib/json/r2_20080312/json.jar',
            '<(PRODUCT_DIR)/compiler/lib/rhino/1_7R3/js.jar',
          ],
          'action' : [
            '../third_party/apache_ant/v1_7_1/bin/ant',
            '-f', 'dartc.xml',
            '-Dbuild.dir=<(INTERMEDIATE_DIR)/<(_target_name)',
            '-Ddist.dir=<(PRODUCT_DIR)/compiler',
            '-Dclosure_compiler.jar=<(PRODUCT_DIR)/closure_out/compiler.jar',
            'clean',
            'dist',
            'tests.jar',
          ],
          'message': 'Building dartc.',
        },
        {
          'action_name': 'strip_d8',
          'inputs': [
            # Add fake dependency on dartc because this action must
            # run after ant is invoked
            # (which will delete <(PRODUCT_DIR)/compiler).
            '<(PRODUCT_DIR)/compiler/bin/dartc',
            '<(PRODUCT_DIR)/d8',
          ],
          'outputs': [ '<(PRODUCT_DIR)/compiler/bin/d8.<(OS)', ],
          'action': [ 'strip', '-o', '<@(_outputs)', '<(PRODUCT_DIR)/d8', ],
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
        {
          'message': 'Compiling dart system libraries',
          'action_name': 'compile_systemlibrary',
          'inputs': [
            '<(PRODUCT_DIR)/dartc',
            'api.dart',
          ],
          'outputs': [
            '<(INTERMEDIATE_DIR)/<(_target_name)/api/dart/core/com/google/dart/corelib/corelib.dart.api',
            '<(INTERMEDIATE_DIR)/<(_target_name)/api/dart/dom/dom/dom.dart.api',
            '<(INTERMEDIATE_DIR)/<(_target_name)/api/dart/html/html/html.dart.api',
            '<(INTERMEDIATE_DIR)/<(_target_name)/api/dart/json/json/json.dart.api',
          ],
          'action': [
            '<(PRODUCT_DIR)/dartc', 'api.dart', '-out', '<(INTERMEDIATE_DIR)/<(_target_name)/api',
          ],
        },
        {
          'message': 'Packaging dart:core artifacts',
          'action_name': 'package_corelib_artifacts',
          'inputs': [
            '<(INTERMEDIATE_DIR)/<(_target_name)/api/dart/core/com/google/dart/corelib/corelib.dart.api',
            'api.dart',
          ],
          'outputs': [
            '<(PRODUCT_DIR)/compiler/lib/corelib.jar',
          ],
          'action': [
            'jar', 'u0f', '<(PRODUCT_DIR)/compiler/lib/corelib.jar', '-C', '<(INTERMEDIATE_DIR)/<(_target_name)/api/dart/core', 'com',
          ],
        },
        {
          'message': 'Packaging dart:dom artifacts',
          'action_name': 'package_domlib_artifacts',
          'inputs': [
            '<(INTERMEDIATE_DIR)/<(_target_name)/api/dart/dom/dom/dom.dart.api',
            'api.dart',
          ],
          'outputs': [
            '<(PRODUCT_DIR)/compiler/lib/domlib.jar',
          ],
          'action': [
            'jar', 'u0f', '<(PRODUCT_DIR)/compiler/lib/domlib.jar', '-C', '<(INTERMEDIATE_DIR)/<(_target_name)/api/dart/dom', 'dom',
          ],
        },
        {
          'message': 'Packaging dart:html artifacts',
          'action_name': 'package_htmllib_artifacts',
          'inputs': [
            '<(INTERMEDIATE_DIR)/<(_target_name)/api/dart/html/html/html.dart.api',
            'api.dart',
          ],
          'outputs': [
            '<(PRODUCT_DIR)/compiler/lib/htmllib.jar',
          ],
          'action': [
            'jar', 'u0f', '<(PRODUCT_DIR)/compiler/lib/htmllib.jar', '-C', '<(INTERMEDIATE_DIR)/<(_target_name)/api/dart/html', 'html',
          ],
        },
        {
          'message': 'Packaging dart:json artifacts',
          'action_name': 'package_jsonlib_artifacts',
          'inputs': [
            '<(INTERMEDIATE_DIR)/<(_target_name)/api/dart/json/json/json.dart.api',
            'api.dart',
          ],
          'outputs': [
            '<(PRODUCT_DIR)/compiler/lib/jsonlib.jar',
          ],
          'action': [
            'jar', 'u0f', '<(PRODUCT_DIR)/compiler/lib/jsonlib.jar', '-C', '<(INTERMEDIATE_DIR)/<(_target_name)/api/dart/json', 'json',
          ],
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
            'closure_compiler_sources.gypi',
            '../third_party/closure_compiler_src/build.xml',
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
