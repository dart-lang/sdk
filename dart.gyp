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
    # TODO(ngeoffray): Requires node to be in the path.
    #{
    #  'target_name': 'frog',
    #  'type': 'none',
    #  'dependencies': [
    #    'frog/dart-frog.gyp:frog',
    #  ],
    #},
    #{
    #  'target_name': 'frogsh',
    #  'type': 'none',
    #  'dependencies': [
    #    'frog/dart-frog.gyp:frogsh',
    #  ],
    #},
    # TODO(ngeoffray): Fling does not have proper dependencies,
    # so don't build it for now.
    #{
    #  'target_name': 'client',
    #  'type': 'none',
    #  'dependencies': [
    #    'client/dart.gyp:fling',
    #  ],
    #},
  ],
}
