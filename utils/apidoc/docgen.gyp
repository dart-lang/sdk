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
        '../../create_sdk.gyp:create_sdk_internal',
        '../../pkg/pkg.gyp:pkg_packages',
        '../../pkg/pkg_files.gyp:pkg_files_stamp',
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
            '../../sdk/bin/docgen',
            '../../sdk/bin/docgen.bat',
            '../../tools/only_in_release_mode.py',
            '<(PRODUCT_DIR)/dart-sdk/README',
            '<(SHARED_INTERMEDIATE_DIR)/pkg_files.stamp',
          ],
          'outputs': [
            '<(PRODUCT_DIR)/api_docs/docgen/index.json',
          ],
          'action': [
            'python',
            '../../tools/only_in_release_mode.py',
            '<@(_outputs)',
            '--',
            '<(PRODUCT_DIR)/dart-sdk/bin/docgen<(script_suffix)',
            '--out=<(PRODUCT_DIR)/api_docs/docgen',
            '--include-sdk',
            '--no-include-dependent-packages',
            '--package-root=<(PRODUCT_DIR)/packages',
            '--exclude-lib=async_helper',
            '--exclude-lib=expect',
            '--exclude-lib=docgen',
            '--exclude-lib=compiler',
            '--exclude-lib=try',
            '../../pkg'
          ],
          'message': 'Running docgen: <(_action)',
        },
      ],
    }
  ],
}
