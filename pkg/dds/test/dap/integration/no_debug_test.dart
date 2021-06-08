// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'test_support.dart';

main() {
  testDap((dap) async {
    group('noDebug mode', () {
      test('runs a simple script', () async {
        final testFile = dap.createTestFile(r'''
void main(List<String> args) async {
  print('Hello!');
  print('World!');
  print('args: $args');
}
    ''');

        final outputEvents = await dap.client.collectOutput(
          launch: () => dap.client.launch(
            testFile.path,
            noDebug: true,
            args: ['one', 'two'],
          ),
        );

        final output = outputEvents.map((e) => e.output).join();
        expectLines(output, [
          'Hello!',
          'World!',
          'args: [one, two]',
          '',
          'Exited.',
        ]);
      });
      // These tests can be slow due to starting up the external server process.
    }, timeout: Timeout.none);
  });
}
