# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

{
  'variables' : {
    'script_suffix%': '',
  },
  'conditions' : [
    ['OS=="win"', {
      'variables' : {
        'script_suffix': '.bat',
      },
    }],
  ],
  'targets': [
    {
      'target_name': 'docgen',
      'type': 'none',
      'dependencies': [
        '../../utils/compiler/compiler.gyp:dart2js',
        '../../runtime/dart-runtime.gyp:dart',
        '../../pkg/pkg.gyp:pkg_packages',
        'apidoc.gyp:api_docs',
      ],
      'includes': [
        '../../sdk/lib/core/corelib_sources.gypi',
      ],
      'actions': [
        {
          'action_name': 'run_docgen',
          # The 'inputs' list records the files whose timestamps are
          # compared to the files listed in 'outputs'.  If a file
          # 'outputs' doesn't exist or if a file in 'inputs' is newer
          # than a file in 'outputs', this action is executed.  Notice
          # that the dependencies listed above has nothing to do with
          # when this action is executed.  You must list a file in
          # 'inputs' to make sure that it exists before the action is
          # executed, or to make sure this action is re-run.
          #
          # We want to build the platform documentation whenever
          # dartdoc, apidoc, or its dependency changes.  This prevents
          # people from accidentally breaking apidoc when making
          # changes to the platform libraries and or when modifying
          # dart2js or the VM.
          #
          # In addition, we want to make sure that the platform
          # documentation is regenerated when the platform sources
          # changes.
          #
          # So we want this action to be re-run when a dart file
          # changes in this directory, or in the SDK library (we may
          # no longer need to list the files in ../../runtime/lib and
          # ../../runtime/bin, as most of them has moved to
          # ../../sdk/lib).
          #
          'inputs': [
            '<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)dart<(EXECUTABLE_SUFFIX)',
            '<(SHARED_INTERMEDIATE_DIR)/utils_wrapper.dart.snapshot',
            '<!@(["python", "../../tools/list_files.py", "\\.(css|ico|js|json|png|sh|txt|yaml|py)$", ".", "../../sdk/lib/_internal/dartdoc"])',
            '<!@(["python", "../../tools/list_files.py", "\\.dart$", ".", "../../sdk/lib", "../../runtime/lib", "../../runtime/bin"])',
            '../../sdk/bin/dart',
            '../../sdk/bin/dart.bat',
            '../../sdk/bin/dart2js',
            '../../sdk/bin/dart2js.bat',
            '../../tools/only_in_release_mode.py',
            # We sit inside the api_docs directory, so make sure it has run
            # before we do. Otherwise it might run later and delete us.
            '<(PRODUCT_DIR)/api_docs/index.html',
          ],
          'outputs': [
            '<(PRODUCT_DIR)/api_docs/docgen/index.json',
          ],
          'action': [
            'python',
            '../../tools/only_in_release_mode.py',
            '<@(_outputs)',
            '--',
            '<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)dart<(EXECUTABLE_SUFFIX)',
            '--old_gen_heap_size=1024',
            '--package-root=<(PRODUCT_DIR)/packages/',
            '../../pkg/docgen/bin/docgen.dart',
            '--out=<(PRODUCT_DIR)/api_docs/docgen',
            '--json',
            '--include-sdk',
            '--package-root=<(PRODUCT_DIR)/packages',
            '--exclude-lib=async_helper',
            '--exclude-lib=expect',
            '--exclude-lib=docgen',
            '../../pkg',          
          ],
          'message': 'Running docgen: <(_action)',
        },
      ],
    }
  ],
}
