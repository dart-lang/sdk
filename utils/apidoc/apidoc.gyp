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
      'target_name': 'api_docs',
      'type': 'none',
      'dependencies': [
        '../../utils/compiler/compiler.gyp:dart2js',
        '../../runtime/dart-runtime.gyp:dart',
        '../../pkg/pkg.gyp:pkg_packages',
      ],
      'includes': [
        '../../sdk/lib/core/corelib_sources.gypi',
      ],
      'actions': [
        {
          'action_name': 'run_apidoc',
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
          # In addition, we want to make sure the documentation is
          # regenerated when a resource file (CSS, PNG, etc) is
          # updated.  This is because these files are also copied to
          # the output directory.
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
          ],
          'outputs': [
            '<(PRODUCT_DIR)/api_docs/index.html',
            '<(PRODUCT_DIR)/api_docs/client-static.js',
          ],
          'action': [
            'python',
            '../../tools/only_in_release_mode.py',
            '<@(_outputs)',
            '--',
            '<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)dart<(EXECUTABLE_SUFFIX)',
            '--package-root=<(PRODUCT_DIR)/packages/',
            'apidoc.dart',
            '--out=<(PRODUCT_DIR)/api_docs',
            '--version=<!@(["python", "../../tools/print_version.py"])',
            '--package-root=<(PRODUCT_DIR)/packages',
            '--mode=static',
            '--exclude-lib=analyzer_experimental',
            '--exclude-lib=browser',
            '--exclude-lib=dartdoc',
            '--exclude-lib=expect',
            '--exclude-lib=http',
            '--exclude-lib=oauth2',
            '--exclude-lib=pathos',
            '--exclude-lib=scheduled_test',
            '--exclude-lib=stack_trace',
            '--exclude-lib=webdriver',
            '--exclude-lib=yaml',
            '--include-lib=matcher',
            '--include-lib=mock',
          ],
          'message': 'Running apidoc: <(_action)',
        },
      ],
    }
  ],
}
