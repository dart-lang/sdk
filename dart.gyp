# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

{
  'targets': [
    {
      'target_name': 'most',
      'type': 'none',
      'dependencies': [
        'analyzer',
        'compiler',
        'create_sdk',
        'dart2js',
        'editor',
        'packages',
        'runtime',
        'samples',
        'upload_sdk',
      ],
    },
    {
      'target_name': 'compiler',
      'type': 'none',
      'dependencies': [
        'compiler/dart-compiler.gyp:dart_analyzer',
      ],
      'actions': []
    },
    {
      # This is the target that is built on the VM build bots.  It
      # must depend on anything that is required by the VM test
      # suites.
      'target_name': 'runtime',
      'type': 'none',
      'dependencies': [
        'runtime/dart-runtime.gyp:dart',
        'runtime/dart-runtime.gyp:dart_no_snapshot',
        'runtime/dart-runtime.gyp:run_vm_tests',
        'runtime/dart-runtime.gyp:process_test',
        'runtime/dart-runtime.gyp:test_extension',
        'packages',
      ],
    },
    {
      # Build the SDK. This target is separate from upload_sdk as the
      # editor needs to build the SDK without uploading it.
      'target_name': 'create_sdk',
      'type': 'none',
      'dependencies': [
        'runtime/dart-runtime.gyp:dart',
        'utils/compiler/compiler.gyp:dart2js',
        'analyzer',
        'compiler',
      ],
      'actions': [
        {
          'action_name': 'create_sdk_py',
          'inputs': [
            '<!@(["python", "tools/list_files.py", "\\.dart$", "sdk/lib"])',
            '<!@(["python", "tools/list_files.py", "", "sdk/bin"])',
            'tools/create_sdk.py',
            '<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)dart<(EXECUTABLE_SUFFIX)',
            '<(SHARED_INTERMEDIATE_DIR)/utils_wrapper.dart.snapshot',
            '<(PRODUCT_DIR)/analyzer/bin/dart_analyzer',
            '<(PRODUCT_DIR)/dartanalyzer/dartanalyzer.jar',
          ],
          'outputs': [
            '<(PRODUCT_DIR)/dart-sdk/README',
          ],
          'action': [
            'python',
            'tools/create_sdk.py',
            '--sdk_output_dir', '<(PRODUCT_DIR)/dart-sdk',
            '--utils_snapshot_location',
             '<(SHARED_INTERMEDIATE_DIR)/utils_wrapper.dart.snapshot'
          ],
          'message': 'Creating SDK.',
        },
      ],
    },
    {
      # Upload the SDK. This target is separate from create_sdk as the
      # editor needs to build the SDK without uploading it.
      'target_name': 'upload_sdk',
      'type': 'none',
      'dependencies': [
        'create_sdk',
      ],
      'actions': [
        {
          'action_name': 'upload_sdk_py',
          'inputs': [
            '<(PRODUCT_DIR)/dart-sdk/README',
            'tools/upload_sdk.py',
          ],
          'outputs': [
            '<(PRODUCT_DIR)/dart-sdk/upload.stamp',
          ],
          'action': [
            'python',
            'tools/upload_sdk.py',
            '<(PRODUCT_DIR)/dart-sdk'
          ],
        },
      ],
    },
    {
      'target_name': 'dart2js',
      'type': 'none',
      'dependencies': [
        'third_party/v8/src/d8.gyp:d8',
        'utils/compiler/compiler.gyp:dart2js',
      ],
    },
    {
      'target_name': 'analyzer',
      'type': 'none',
      'dependencies': [
        'editor/analyzer.gyp:analyzer',
      ],
    },
    {
      # This is the target that is built on the dart2dart bots.
      # It must depend on anything that is required by dart2dart
      # tests.
      'target_name': 'dart2dart_bot',
      'type': 'none',
      'dependencies': [
        'create_sdk',
        'packages',
      ],
    },
    {
      # This is the target that is built on the dartc bots.
      # It must depend on anything that is required by dartc
      # tests.
      'target_name': 'dartc_bot',
      'type': 'none',
      'dependencies': [
        'create_sdk',
        'packages',
      ],
    },
    {
      # This is the target that is built on the dart2js build bots.
      # It must depend on anything that is required by the dart2js
      # test suites.
      'target_name': 'dart2js_bot',
      'type': 'none',
      'dependencies': [
        'third_party/v8/src/d8.gyp:d8',
        'create_sdk',
        'packages',
      ],
    },
    {
      'target_name': 'api_docs',
      'type': 'none',
      'dependencies': [
        'utils/apidoc/apidoc.gyp:api_docs',
      ],
    },
    {
      'target_name': 'editor',
      'type': 'none',
      'dependencies': [
        'editor/build/generated/editor_deps.gyp:editor_deps',

        # This dependency on create_sdk does not mean that the Editor
        # is rebuilt if the SDK is. It only means that when you build
        # the Editor, you should also build the SDK. If we wanted to
        # make sure that the editor is rebuilt when the SDK is, we
        # should list a *file* in PRODUCT_DIR which the action below
        # uses as input.
        # This is the desired behavior as we would otherwise have to
        # rebuild the editor each time the VM, dart2js, or library
        # code changes.
        'create_sdk',
      ],
      'actions': [
        {
          'action_name': 'create_editor_py',
          'inputs': [
            'tools/create_editor.py',
            '<(SHARED_INTERMEDIATE_DIR)/editor_deps/editor.stamp',
            '<!@(["python", "tools/list_files.py", "", "editor/tools/features/com.google.dart.tools.deploy.feature_releng"])',
          ],
          'outputs': [
            '<(PRODUCT_DIR)/editor/VERSION',
          ],
          'action': [
            'python',
            'tools/create_editor.py',
            '--out', '<(PRODUCT_DIR)/editor',
            '--build', '<(INTERMEDIATE_DIR)',
          ],
          'message': 'Creating editor.',
        },
      ],
    },
    {
      'target_name': 'samples',
      'type': 'none',
      'dependencies': [
        'samples/openglui/openglui.gyp:openglui_sample',
      ],
      'conditions': [
        ['OS!="android"', {
           'dependencies': [
             'samples/sample_extension/sample_extension.gyp:sample_extension',
           ],
          },
        ],
      ]
    },
    {
      'target_name': 'packages',
      'type': 'none',
      'dependencies': [
        'pkg/pkg.gyp:pkg_packages',
      ],
    },
  ],
}
