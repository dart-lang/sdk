# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

{
  'includes': [
    'sources.gypi',
    'test_sources.gypi',
    'corelib_sources.gypi',
    'compiler_corelib_sources.gypi',
    'domlib_sources.gypi',
    'htmllib_sources.gypi',
    'jsonlib_sources.gypi',
    'isolatelib_sources.gypi',
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
            'scripts/dartc_run.sh',
            'scripts/dartc_metrics.sh',
            '../third_party/args4j/2.0.12/args4j-2.0.12.jar',
            '../third_party/guava/r09/guava-r09.jar',
            '../third_party/json/r2_20080312/json.jar',
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
            '<(PRODUCT_DIR)/compiler/lib/json/r2_20080312/json.jar',
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
        {
          'message': 'Collect system libraries',
          'action_name': 'collect_systemlibrary',
          'inputs': [
            '<(PRODUCT_DIR)/compiler/bin/dartc',
            'dartc.xml',
            'domlib_sources.gypi',
            '<@(domlib_sources)',
            '<@(domlib_resources)',
            'htmllib_sources.gypi',
            '<@(htmllib_sources)',
            '<@(htmllib_resources)',
            'jsonlib_sources.gypi',
            '<@(jsonlib_sources)',
            '<@(jsonlib_resources)',
            'isolatelib_sources.gypi',
            '<@(isolatelib_sources)',
            '<@(isolatelib_resources)',
          ],
          'outputs': [
            '<(INTERMEDIATE_DIR)/<(_target_name)/syslib.stamp',
            '<(INTERMEDIATE_DIR)/<(_target_name)/corelib.jar.stamp',
            '<(INTERMEDIATE_DIR)/<(_target_name)/domlib.jar.stamp',
            '<(INTERMEDIATE_DIR)/<(_target_name)/htmllib.jar.stamp',
            '<(INTERMEDIATE_DIR)/<(_target_name)/jsonlib.jar.stamp',
            '<(INTERMEDIATE_DIR)/<(_target_name)/isolatelib.jar.stamp',
          ],
          'action': [
            '../third_party/apache_ant/v1_7_1/bin/ant',
            '-f', 'dartc.xml',
            '-Dbuild.dir=<(INTERMEDIATE_DIR)/<(_target_name)',
            '-Ddist.dir=<(PRODUCT_DIR)/compiler',
            'syslib_clean',
            'syslib',
          ],
        },
        {
          'message': 'Compiling dart system libraries to <(INTERMEDIATE_DIR)/<(_target_name)/api',
          'action_name': 'compile_systemlibrary',
          'inputs': [
            '<(PRODUCT_DIR)/dartc',
            '<(INTERMEDIATE_DIR)/<(_target_name)/syslib.stamp',
            'api.dart',
          ],
          'outputs': [
            '<(INTERMEDIATE_DIR)/<(_target_name)/api/dart/core/com/google/dart/corelib/corelib.dart.deps',
            '<(INTERMEDIATE_DIR)/<(_target_name)/api/dart/dom/dom/dom.dart.deps',
            '<(INTERMEDIATE_DIR)/<(_target_name)/api/dart/html/html/html.dart.deps',
            '<(INTERMEDIATE_DIR)/<(_target_name)/api/dart/json/json/json.dart.deps',
            '<(INTERMEDIATE_DIR)/<(_target_name)/api/dart/isolate/isolate/isolate_compiler.dart.deps',
          ],
          'action': [
            '<(PRODUCT_DIR)/dartc', 'api.dart',
            '--fatal-warnings', '--fatal-type-errors',
            '-out', '<(INTERMEDIATE_DIR)/<(_target_name)/api',
          ],
        },
        {
          'message': 'Packaging dart:core artifacts',
          'action_name': 'package_corelib_artifacts',
          'inputs': [
            '<(INTERMEDIATE_DIR)/<(_target_name)/corelib.jar.stamp',
            '<(INTERMEDIATE_DIR)/<(_target_name)/api/dart/core/com/google/dart/corelib/corelib.dart.deps',
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
            '<(INTERMEDIATE_DIR)/<(_target_name)/domlib.jar.stamp',
            '<(INTERMEDIATE_DIR)/<(_target_name)/api/dart/dom/dom/dom.dart.deps',
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
            'htmllib_sources.gypi',
            '<@(htmllib_sources)',
            '<@(htmllib_resources)',
            '<(INTERMEDIATE_DIR)/<(_target_name)/htmllib.jar.stamp',
            '<(INTERMEDIATE_DIR)/<(_target_name)/api/dart/html/html/html.dart.deps',
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
            '<(INTERMEDIATE_DIR)/<(_target_name)/jsonlib.jar.stamp',
            '<(INTERMEDIATE_DIR)/<(_target_name)/api/dart/json/json/json.dart.deps',
            'api.dart',
          ],
          'outputs': [
            '<(PRODUCT_DIR)/compiler/lib/jsonlib.jar',
          ],
          'action': [
            'jar', 'u0f', '<(PRODUCT_DIR)/compiler/lib/jsonlib.jar', '-C', '<(INTERMEDIATE_DIR)/<(_target_name)/api/dart/json', 'json',
          ],
        },
        {
          'message': 'Packaging dart:isolate artifacts',
          'action_name': 'package_isolatelib_artifacts',
          'inputs': [
            '<(INTERMEDIATE_DIR)/<(_target_name)/isolatelib.jar.stamp',
            '<(INTERMEDIATE_DIR)/<(_target_name)/api/dart/isolate/isolate/isolate_compiler.dart.deps',
            'api.dart',
          ],
          'outputs': [
            '<(PRODUCT_DIR)/compiler/lib/isolatelib.jar',
          ],
          'action': [
            'jar', 'u0f', '<(PRODUCT_DIR)/compiler/lib/isolatelib.jar', '-C',
            '<(INTERMEDIATE_DIR)/<(_target_name)/api/dart/isolate', 'isolate',
          ],
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
