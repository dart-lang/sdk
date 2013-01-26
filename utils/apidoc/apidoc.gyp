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
          'inputs': [
            '<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)dart<(EXECUTABLE_SUFFIX)',
            '<(PRODUCT_DIR)/dart2js.snapshot',
            '<!@(["python", "../../tools/list_files.py", "\\.(css|ico|js|json|png|sh|txt|yaml|py)$", ".", "../../sdk/lib/_internal/dartdoc"])',
            '<!@(["python", "../../tools/list_files.py", "\\.dart$", "../../sdk/lib", "../../runtime/lib", "../../runtime/bin"])',
            '../../sdk/bin/dart',
            '../../sdk/bin/dart.bat',
            '../../sdk/bin/dart2js',
            '../../sdk/bin/dart2js.bat',
          ],
          'outputs': [
            '<(PRODUCT_DIR)/api_docs/index.html',
            '<(PRODUCT_DIR)/api_docs/client-static.js',
          ],
          'action': [
            '<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)dart<(EXECUTABLE_SUFFIX)',
            'apidoc.dart',
            '--out=<(PRODUCT_DIR)/api_docs',
            '--pkg=<(PRODUCT_DIR)/packages/',
            '--mode=static',
            '--exclude-lib=dartdoc',
            '--exclude-lib=http',
            '--exclude-lib=oauth2',
            '--exclude-lib=path',
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
