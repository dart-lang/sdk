# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

{
  'targets': [
    {
      'target_name': 'compiler',
      'type': 'none',
      'dependencies': [
        'compiler/dart-compiler.gyp:dartc',
      ],
      'actions': []
    },
    {
      'target_name': 'runtime',
      'type': 'none',
      'dependencies': [
        'runtime/dart-runtime.gyp:dart',
        'runtime/dart-runtime.gyp:dart_bin',
        'runtime/dart-runtime.gyp:run_vm_tests',
        'runtime/dart-runtime.gyp:process_test',
      ],
    },
    {
      'target_name': 'client',
      'type': 'none',
      'dependencies': [
        # TODO(ngeoffray): Fling does not have proper dependencies,
        # so don't build it for now.
        # 'client/dart.gyp:fling',
        'client/dart.gyp:dartserver',
      ],
    },
  ],
}
