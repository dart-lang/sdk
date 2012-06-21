# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

{
  'targets': [
    {
      'target_name': 'api_docs',
      'type': 'none',
      'dependencies': [
        '../../utils/compiler/compiler.gyp:dart2js',
        '../../runtime/dart-runtime.gyp:dart',
      ],
      'includes': [
        '../../corelib/src/corelib_sources.gypi',
      ],
      'actions': [
        {
          'action_name': 'run_apidoc',
          'inputs': [
            '<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)dart<(EXECUTABLE_SUFFIX)',
            '<(PRODUCT_DIR)/dart2js',
            '<!@(["python", "../../tools/list_files.py", "\\.(css|ico|js|json|png|sh|txt|yaml|py)$", ".", "../../lib/dartdoc"])',
            '<!@(["python", "../../tools/list_files.py", "\\.dart$", "../../lib", "../../runtime/lib", "../../runtime/bin"])',
            '<@(_sources)',
          ],
          'outputs': [
            '<(PRODUCT_DIR)/api_docs/index.html',
            '<(PRODUCT_DIR)/api_docs/client-live-nav.js',
          ],
          'action': [
            '<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)dart<(EXECUTABLE_SUFFIX)',
            'apidoc.dart',
            '--out=<(PRODUCT_DIR)/api_docs',
            '--mode=live-nav',
            '--compiler=<(PRODUCT_DIR)/dart2js',
          ],
        },
      ],
    }
  ],
}
