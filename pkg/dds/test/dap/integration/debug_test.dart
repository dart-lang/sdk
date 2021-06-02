// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'test_support.dart';

main() {
  testDap((dap) async {
    group('debug mode', () {
      test('runs a simple script', () async {
        final testFile = dap.createTestFile(r'''
void main(List<String> args) async {
  print('Hello!');
  print('World!');
  print('args: $args');
}
    ''');

        var outputEvents = await dap.client.collectOutput(
          launch: () => dap.client.launch(
            testFile.path,
            args: ['one', 'two'],
          ),
        );

        // Expect a "console" output event that prints the URI of the VM Service
        // the debugger connects to.
        final vmConnection = outputEvents.first;
        expect(vmConnection.output,
            startsWith('Connecting to VM Service at ws://127.0.0.1:'));
        expect(vmConnection.category, equals('console'));

        // Expect the normal applications output.
        final output = outputEvents.skip(1).map((e) => e.output).join();
        expectLines(output, [
          'Hello!',
          'World!',
          'args: [one, two]',
          '',
          'Exited.',
        ]);
      });
    });
  });
}
