// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import '../utils.dart';

void main() {
  group('debug_adapter', debugAdapter, timeout: longTimeout);
}

void debugAdapter() {
  // Implementation of debug_adapter is tested in the DDS package where the
  // DAP implementation lives.
  test('--help', () async {
    final p = project();
    var result = await p.run(['debug_adapter', '--help']);

    expect(
        result.stdout,
        contains(
            'Start a debug adapter that conforms to the Debug Adapter Protocol.'));
    expect(result.stdout,
        contains('Whether to use the "dart test" debug adapter to run tests'));
    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
  });
}
