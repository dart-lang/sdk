// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dds/src/dap/adapters/dart.dart';
import 'package:test/test.dart';

import 'test_client.dart';
import 'test_scripts.dart';
import 'test_support.dart';

main() {
  testDap((dap) async {
    group('debug mode evaluation', () {
      test('evaluates expressions with simple results', () async {
        final client = dap.client;
        final testFile = await dap.createTestFile(r'''
void main(List<String> args) {
  var a = 1;
  var b = 2;
  var c = 'test';
  print('Hello!'); // BREAKPOINT
}''');
        final breakpointLine = lineWith(testFile, '// BREAKPOINT');

        final stop = await client.hitBreakpoint(testFile, breakpointLine);
        await client.expectTopFrameEvalResult(stop.threadId!, 'a', '1');
        await client.expectTopFrameEvalResult(stop.threadId!, 'a * b', '2');
        await client.expectTopFrameEvalResult(stop.threadId!, 'c', '"test"');
      });

      test('evaluates expressions with complex results', () async {
        final client = dap.client;
        final testFile = await dap.createTestFile(simpleBreakpointProgram);
        final breakpointLine = lineWith(testFile, '// BREAKPOINT');

        final stop = await client.hitBreakpoint(testFile, breakpointLine);
        final result = await client.expectTopFrameEvalResult(
          stop.threadId!,
          'DateTime(2000, 1, 1)',
          'DateTime',
        );

        // Check we got a variablesReference that maps on to the fields.
        expect(result.variablesReference, greaterThan(0));
        await client.expectVariables(
          result.variablesReference,
          '''
            isUtc: false
          ''',
        );
      });

      test(
          'evaluates complex expressions expressions with evaluateToStringInDebugViews=true',
          () async {
        final client = dap.client;
        final testFile = await dap.createTestFile(simpleBreakpointProgram);
        final breakpointLine = lineWith(testFile, '// BREAKPOINT');

        final stop = await client.hitBreakpoint(
          testFile,
          breakpointLine,
          launch: () =>
              client.launch(testFile.path, evaluateToStringInDebugViews: true),
        );

        await client.expectTopFrameEvalResult(
          stop.threadId!,
          'DateTime(2000, 1, 1)',
          'DateTime (2000-01-01 00:00:00.000)',
        );
      });

      test(
          'evaluates $threadExceptionExpression to the threads exception (simple type)',
          () async {
        final client = dap.client;
        final testFile = await dap.createTestFile(r'''
void main(List<String> args) {
  throw 'my error';
}''');

        final stop = await client.hitException(testFile);

        final result = await client.expectTopFrameEvalResult(
          stop.threadId!,
          threadExceptionExpression,
          '"my error"',
        );
        expect(result.variablesReference, equals(0));
      });

      test(
          'evaluates $threadExceptionExpression to the threads exception (complex type)',
          () async {
        final client = dap.client;
        final testFile = await dap.createTestFile(r'''
void main(List<String> args) {
  throw Exception('my error');
}''');

        final stop = await client.hitException(testFile);
        final result = await client.expectTopFrameEvalResult(
          stop.threadId!,
          threadExceptionExpression,
          '_Exception',
        );
        expect(result.variablesReference, greaterThan(0));
      });

      test(
          'evaluates $threadExceptionExpression.x.y to x.y on the threads exception',
          () async {
        final client = dap.client;
        final testFile = await dap.createTestFile(r'''
void main(List<String> args) {
  throw Exception('12345');
}
    ''');

        final stop = await client.hitException(testFile);
        await client.expectTopFrameEvalResult(
          stop.threadId!,
          '$threadExceptionExpression.message.length',
          '5',
        );
      });

      test('can evaluate expressions in non-top frames', () async {
        final client = dap.client;
        final testFile = await dap.createTestFile(r'''
void main(List<String> args) {
  var a = 999;
  foo();
}

void foo() {
  var a = 111; // BREAKPOINT
}''');
        final breakpointLine = lineWith(testFile, '// BREAKPOINT');

        final stop = await client.hitBreakpoint(testFile, breakpointLine);
        final stack = await client.getValidStack(stop.threadId!,
            startFrame: 0, numFrames: 2);
        final secondFrameId = stack.stackFrames[1].id;

        await client.expectEvalResult(secondFrameId, 'a', '999');
      });

      // These tests can be slow due to starting up the external server process.
    }, timeout: Timeout.none);
  });
}
