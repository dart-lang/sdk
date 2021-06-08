// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'test_support.dart';

main() {
  testDap((dap) async {
    group('debug mode', () {
      test('prints messages from dart:developer log()', () async {
        final testFile = dap.createTestFile(r'''
import 'dart:developer';

void main(List<String> args) async {
  log('this is a test\nacross two lines');
  log('this is a test', name: 'foo');
}
    ''');

        var outputEvents = await dap.client.collectOutput(file: testFile);

        // Skip the first line because it's the VM Service connection info.
        final output = outputEvents.skip(1).map((e) => e.output).join();
        expectLines(output, [
          '[log] this is a test',
          '      across two lines',
          '[foo] this is a test',
          '',
          'Exited.',
        ]);
      });
      // These tests can be slow due to starting up the external server process.
    }, timeout: Timeout.none);
  });
}
