// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dap/dap.dart';
import 'package:dds/src/dap/adapters/dart.dart';
import 'package:test/test.dart';

import 'test_client.dart';
import 'test_scripts.dart';
import 'test_support.dart';

main() {
  late DapTestSession dap;
  setUp(() async {
    dap = await DapTestSession.setUp();
  });
  tearDown(() => dap.tearDown());

  group('debug mode evaluation', () {
    test('evaluates expressions with simple results', () async {
      final client = dap.client;
      final testFile = dap.createTestFile('''
void main(List<String> args) {
  var a = 1;
  var b = 2;
  var c = 'test';
  print('Hello!'); $breakpointMarker
}''');
      final breakpointLine = lineWith(testFile, breakpointMarker);

      final stop = await client.hitBreakpoint(testFile, breakpointLine);
      final topFrameId = await client.getTopFrameId(stop.threadId!);
      await client.expectEvalResult(topFrameId, 'a', '1');
      await client.expectEvalResult(topFrameId, 'a * b', '2');
      await client.expectEvalResult(topFrameId, 'c', '"test"');
    });

    test('evaluates expressions with complex results', () async {
      final client = dap.client;
      final testFile = dap.createTestFile(simpleBreakpointProgram);
      final breakpointLine = lineWith(testFile, breakpointMarker);

      final stop = await client.hitBreakpoint(testFile, breakpointLine);
      final topFrameId = await client.getTopFrameId(stop.threadId!);
      final result = await client.expectEvalResult(
        topFrameId,
        'DateTime(2000, 1, 1)',
        'DateTime',
      );

      // Check we got a variablesReference that maps on to the fields.
      expect(result.variablesReference, isPositive);
      await client.expectVariables(
        result.variablesReference,
        '''
            isUtc: false, eval: DateTime(2000, 1, 1).isUtc
        ''',
      );
    });

    test('evaluates expressions ending with semicolons', () async {
      final client = dap.client;
      final testFile = dap.createTestFile('''
void main(List<String> args) {
  var a = 1;
  var b = 2;
  print('Hello!'); $breakpointMarker
}''');
      final breakpointLine = lineWith(testFile, breakpointMarker);

      final stop = await client.hitBreakpoint(testFile, breakpointLine);
      final topFrameId = await client.getTopFrameId(stop.threadId!);
      await client.expectEvalResult(topFrameId, 'a + b;', '3');
    });

    test('evaluates complex expressions with evaluateToStringInDebugViews=true',
        () async {
      final client = dap.client;
      final testFile = dap.createTestFile(simpleBreakpointProgram);
      final breakpointLine = lineWith(testFile, breakpointMarker);

      final stop = await client.hitBreakpoint(
        testFile,
        breakpointLine,
        launch: () =>
            client.launch(testFile.path, evaluateToStringInDebugViews: true),
      );

      final topFrameId = await client.getTopFrameId(stop.threadId!);
      await client.expectEvalResult(
        topFrameId,
        'DateTime(2000, 1, 1)',
        'DateTime (2000-01-01 00:00:00.000)',
      );
    });

    test(
        'evaluates $threadExceptionExpression to the threads exception (simple type)',
        () async {
      final client = dap.client;
      final testFile = dap.createTestFile(r'''
void main(List<String> args) {
  throw 'my error';
}''');

      final stop = await client.hitException(testFile);
      final topFrameId = await client.getTopFrameId(stop.threadId!);
      final result = await client.expectEvalResult(
        topFrameId,
        threadExceptionExpression,
        '"my error"',
      );
      expect(result.variablesReference, equals(0));
    });

    test(
        'evaluates $threadExceptionExpression to the threads exception (complex type)',
        () async {
      final client = dap.client;
      final testFile = dap.createTestFile(r'''
void main(List<String> args) {
  throw Exception('my error');
}''');

      final stop = await client.hitException(testFile);
      final topFrameId = await client.getTopFrameId(stop.threadId!);
      final result = await client.expectEvalResult(
        topFrameId,
        threadExceptionExpression,
        '_Exception',
      );
      expect(result.variablesReference, isPositive);
    });

    test(
        'evaluates $threadExceptionExpression.x.y to x.y on the threads exception',
        () async {
      final client = dap.client;
      final testFile = dap.createTestFile(r'''
void main(List<String> args) {
  throw Exception('12345');
}
    ''');

      final stop = await client.hitException(testFile);
      final topFrameId = await client.getTopFrameId(stop.threadId!);
      await client.expectEvalResult(
        topFrameId,
        '$threadExceptionExpression.message.length',
        '5',
      );
    });

    test('can evaluate expressions in non-top frames', () async {
      final client = dap.client;
      final testFile = dap.createTestFile('''
void main(List<String> args) {
  var a = 999;
  foo();
}

void foo() {
  var a = 111; $breakpointMarker
}''');
      final breakpointLine = lineWith(testFile, breakpointMarker);

      final stop = await client.hitBreakpoint(testFile, breakpointLine);
      final stack = await client.getValidStack(stop.threadId!,
          startFrame: 0, numFrames: 2);
      final secondFrameId = stack.stackFrames[1].id;

      await client.expectEvalResult(secondFrameId, 'a', '999');
    });

    test('returns the full message for evaluation errors', () async {
      final client = dap.client;
      final testFile = dap.createTestFile(simpleBreakpointProgram);
      final breakpointLine = lineWith(testFile, breakpointMarker);

      final stop = await client.hitBreakpoint(testFile, breakpointLine);
      final topFrameId = await client.getTopFrameId(stop.threadId!);
      expectResponseError(
        client.evaluate(
          '1 + "a"',
          frameId: topFrameId,
        ),
        allOf([
          contains('evaluateInFrame: (113) Expression compilation error'),
          contains("'String' can't be assigned to a variable of type 'num'."),
          contains(
            '1 + "a"\n'
            '    ^',
          )
        ]),
      );
    });

    test('returns short errors for evaluation in "watch" context', () async {
      final client = dap.client;
      final testFile = dap.createTestFile(simpleBreakpointProgram);
      final breakpointLine = lineWith(testFile, breakpointMarker);

      final stop = await client.hitBreakpoint(testFile, breakpointLine);
      final topFrameId = await client.getTopFrameId(stop.threadId!);
      expectResponseError(
        client.evaluate(
          '1 + "a"',
          frameId: topFrameId,
          context: 'watch',
        ),
        equals(
          "A value of type 'String' can't be assigned "
          "to a variable of type 'num'.",
        ),
      );
    });

    test('returns truncated strings by default', () async {
      final client = dap.client;
      final testFile = dap.createTestFile(simpleBreakpointProgram);
      final breakpointLine = lineWith(testFile, breakpointMarker);

      final stop = await client.hitBreakpoint(testFile, breakpointLine);
      final topFrameId = await client.getTopFrameId(stop.threadId!);

      final expectedTruncatedString = 'a' * 128;
      await client.expectEvalResult(
        topFrameId,
        '"a" * 200',
        '"$expectedTruncatedString…"',
      );
    });

    test('returns whole string without quotes when context is "clipboard"',
        () async {
      final client = dap.client;
      final testFile = dap.createTestFile(simpleBreakpointProgram);
      final breakpointLine = lineWith(testFile, breakpointMarker);

      final stop = await client.hitBreakpoint(testFile, breakpointLine);
      final topFrameId = await client.getTopFrameId(stop.threadId!);

      final expectedStringValue = 'a' * 200;
      await client.expectEvalResult(
        topFrameId,
        '"a" * 200',
        expectedStringValue,
        context: 'clipboard',
      );
    });

    test('returns whole string with quotes when context is "repl"', () async {
      final client = dap.client;
      final testFile = dap.createTestFile(simpleBreakpointProgram);
      final breakpointLine = lineWith(testFile, breakpointMarker);

      final stop = await client.hitBreakpoint(testFile, breakpointLine);
      final topFrameId = await client.getTopFrameId(stop.threadId!);

      final expectedStringValue = 'a' * 200;
      await client.expectEvalResult(
        topFrameId,
        '"a" * 200',
        '"$expectedStringValue"',
        context: 'repl',
      );
    });

    test('returns whole string with quotes when context is a script', () async {
      final client = dap.client;
      final testFile = dap.createTestFile(simpleBreakpointProgram);
      final breakpointLine = lineWith(testFile, breakpointMarker);

      final stop = await client.hitBreakpoint(testFile, breakpointLine);
      final topFrameId = await client.getTopFrameId(stop.threadId!);

      final expectedStringValue = 'a' * 200;
      await client.expectEvalResult(
        topFrameId,
        '"a" * 200',
        '"$expectedStringValue"',
        context: Uri.file(testFile.path).toString(),
      );
    });

    test('variableReferences remain valid while an isolate is paused',
        () async {
      final client = dap.client;
      final testFile =
          dap.createTestFile(simpleBreakpointProgramWith50ExtraLines);
      final breakpointLine = lineWith(testFile, breakpointMarker);
      final stop = await client.hitBreakpoint(testFile, breakpointLine);

      // We're paused at a breakpoint. Our evaluate results should continue to
      // work even after GCs.
      final threadId = stop.threadId!;
      final topFrameId = await client.getTopFrameId(threadId);

      // Evaluate something and get back a variablesReference.
      final result = await client.expectEvalResult(
        topFrameId,
        'DateTime(2000, 1, 1)',
        'DateTime',
      );

      // Ensure it remains valid even after GCs. This ensures both DAP preserves
      // the variablesReference, and also that the VM preserved the instance
      // reference.
      for (var i = 0; i < 5; i++) {
        await client.expectVariables(
          result.variablesReference,
          'isUtc: false, eval: DateTime(2000, 1, 1).isUtc',
        );
        // Force GC.
        await client.forceGc(threadId);
      }
    });

    test('variableReferences become invalid after a resume', () async {
      final client = dap.client;
      final testFile =
          dap.createTestFile(simpleBreakpointProgramWith50ExtraLines);
      final breakpointLine = lineWith(testFile, breakpointMarker);
      final stop = await client.hitBreakpoint(
        testFile,
        breakpointLine,
        additionalBreakpoints: [breakpointLine + 1],
      );

      // We're paused at a breakpoint. Our evaluate results should only continue
      // to work until we resume.
      final threadId = stop.threadId!;
      final topFrameId = await client.getTopFrameId(threadId);

      // Evaluate something and get back a variablesReference.
      final evalResult = await client.expectEvalResult(
        topFrameId,
        'DateTime(2000, 1, 1)',
        'DateTime',
      );

      // Resume, which should invalidate the variablesReference.
      await client.continue_(threadId);

      // Verify the reference is no longer valid. This is because we clear
      // the threads variable data on resume, and not because of VM Service
      // Zone IDs. We have no way to validate the VM behaviour because we
      // don't have the reference (it is abstracted from the DAP client) to
      // verify.
      expectResponseError(
        client.variables(evalResult.variablesReference),
        equals('Bad state: variablesReference is no longer valid'),
      );
    });

    test('variableReferences become invalid after a step', () async {
      final client = dap.client;
      final testFile =
          dap.createTestFile(simpleBreakpointProgramWith50ExtraLines);
      final breakpointLine = lineWith(testFile, breakpointMarker);
      final stop = await client.hitBreakpoint(testFile, breakpointLine);

      // We're paused at a breakpoint. Our evaluate results should only continue
      // to work until we resume.
      final threadId = stop.threadId!;
      final topFrameId = await client.getTopFrameId(threadId);

      // Evaluate something and get back a variablesReference.
      final evalResult = await client.expectEvalResult(
        topFrameId,
        'DateTime(2000, 1, 1)',
        'DateTime',
      );

      // Step, which should also invalidate because we're basically unpausing
      // and then pausing again.
      await client.next(threadId);

      // Verify the reference is no longer valid. This is because we clear
      // the threads variable data on resume/step, and not because of VM Service
      // Zone IDs. We have no way to validate the VM behaviour because we
      // don't have the reference (it is abstracted from the DAP client) to
      // verify.
      expectResponseError(
        client.variables(evalResult.variablesReference),
        equals('Bad state: variablesReference is no longer valid'),
      );
    });

    test('evaluation service zones are invalidated on resume', () async {
      final client = dap.client;
      final testFile = dap.createTestFile(simpleBreakpointProgram);
      final breakpointLine = lineWith(testFile, breakpointMarker);
      final stop = await client.hitBreakpoint(testFile, breakpointLine);

      // Enable logging and capture any requests to the VM that are calling
      // invalidateIdZone.
      final loggedEvaluateInFrameRequests = client
          .events('dart.log')
          .map((event) => event.body as Map<String, Object?>)
          .map((body) => body['message'] as String)
          .where((message) => message.contains('"method":"invalidateIdZone"'))
          .toList();
      await client.custom('updateSendLogsToClient', {'enabled': true});

      // Trigger an evaluation because evaluation zones are created lazily
      // and we won't invalidate anything if we haven't created one.
      await client.evaluate('0', frameId: stop.threadId!);

      // Resume and wait for the app to terminate.
      await Future.wait([
        client.continue_(stop.threadId!),
        client.event('terminated'),
      ]);

      // Verify that invalidate had been called.
      expect(
        await loggedEvaluateInFrameRequests,
        isNotEmpty,
      );
    });

    test('evaluation service zones are invalidated on step', () async {
      final client = dap.client;
      final testFile = dap.createTestFile(simpleBreakpointProgram);
      final breakpointLine = lineWith(testFile, breakpointMarker);
      final stop = await client.hitBreakpoint(testFile, breakpointLine);

      // Enable logging and capture any requests to the VM that are calling
      // invalidateIdZone.
      final loggedEvaluateInFrameRequests = client
          .events('dart.log')
          .map((event) => event.body as Map<String, Object?>)
          .map((body) => body['message'] as String)
          .where((message) => message.contains('"method":"invalidateIdZone"'))
          .toList();
      await client.custom('updateSendLogsToClient', {'enabled': true});

      // Trigger an evaluation because evaluation zones are created lazily
      // and we won't invalidate anything if we haven't created one.
      await client.evaluate('0', frameId: stop.threadId!);

      // Step, which should also invalidate because we're basically unpausing
      // and then pausing again.
      await client.next(stop.threadId!);

      // Then disable logging (so we don't get false positives from shutdown)
      // and terminate.
      await client.custom('updateSendLogsToClient', {'enabled': false});
      await Future.wait([
        client.terminate(),
        client.event('terminated'),
      ]);

      // Verify that invalidate had been called.
      expect(
        await loggedEvaluateInFrameRequests,
        isNotEmpty,
      );
    });

    group('global evaluation', () {
      test('can evaluate in a bin/ file when not paused given a bin/ URI',
          () async {
        final client = dap.client;
        await dap.createFooPackage();
        final testFile = dap.createTestFile(globalEvaluationProgram);

        await Future.wait([
          client.initialize(),
          client.launch(testFile.path),
        ], eagerError: true);

        // Wait for a '.' to be printed to know the script is up and running.
        await dap.client.outputEvents
            .firstWhere((event) => event.output.trim() == '.');

        await client.expectGlobalEvalResult(
          'myGlobal',
          '"Hello, world!"',
          context: Uri.file(testFile.path).toString(),
        );
      });

      test('can evaluate when not paused given a lib/ URI', () async {
        final client = dap.client;
        final (_, libFile) = await dap.createFooPackage();
        final binFile = dap.createTestFile(globalEvaluationProgram);

        await Future.wait([
          client.initialize(),
          client.launch(binFile.path),
        ], eagerError: true);

        // Wait for a '.' to be printed to know the script is up and running.
        await dap.client.outputEvents
            .firstWhere((event) => event.output.trim() == '.');

        await client.expectGlobalEvalResult(
          'fooGlobal',
          '"Hello, foo!"',
          context: Uri.file(libFile.path).toString(),
        );
      });

      test('returns a suitable error with no context', () async {
        const expectedErrorMessage = 'Evaluation is only supported when the '
            'debugger is paused unless you have a Dart file active in the '
            'editor';

        final client = dap.client;
        await dap.createFooPackage();
        final testFile = dap.createTestFile(globalEvaluationProgram);

        await Future.wait([
          client.initialize(),
          client.launch(testFile.path),
        ], eagerError: true);

        // Wait for a '.' to be printed to know the script is up and running.
        await dap.client.outputEvents
            .firstWhere((event) => event.output.trim() == '.');

        final response = await client.sendRequest(
          EvaluateArguments(
            expression: 'myGlobal',
          ),
          allowFailure: true,
        );
        expect(response.success, isFalse);
        expect(response.message, expectedErrorMessage);

        // Also verify the structured error body.
        final body = response.body as Map<String, Object?>;
        final error = body['error'] as Map<String, Object?>;
        final variables = error['variables'] as Map<String, Object?>;
        expect(error['format'], '{message}');
        expect(error['showUser'], false);
        expect(variables['message'], expectedErrorMessage);
        expect(variables['stack'], isNotNull);
      });

      test('returns a suitable error with an unknown script context', () async {
        final client = dap.client;
        await dap.createFooPackage();
        final testFile = dap.createTestFile(globalEvaluationProgram);

        await Future.wait([
          client.initialize(),
          client.launch(testFile.path),
        ], eagerError: true);

        // Wait for a '.' to be printed to know the script is up and running.
        await dap.client.outputEvents
            .firstWhere((event) => event.output.trim() == '.');

        final context =
            Uri.file(testFile.path.replaceAll('.dart', '_invalid.dart'))
                .toString();
        final response = await client.sendRequest(
          EvaluateArguments(
            expression: 'myGlobal',
            context: context,
          ),
          allowFailure: true,
        );
        expect(response.success, isFalse);
        expect(
          response.message,
          contains('Unable to find the library for file:'),
        );
      });
    });

    group('format specifiers', () {
      test('",nq" suppresses quotes on strings', () async {
        final client = dap.client;
        final testFile = dap.createTestFile('''
  void main(List<String> args) {
    var myString = 'test';
    print('Hello!'); $breakpointMarker
  }''');
        final breakpointLine = lineWith(testFile, breakpointMarker);

        final stop = await client.hitBreakpoint(testFile, breakpointLine);
        final topFrameId = await client.getTopFrameId(stop.threadId!);
        await client.expectEvalResult(topFrameId, 'myString', '"test"');
        await client.expectEvalResult(topFrameId, 'myString,nq', 'test');
      });

      test('",h" renders numbers in hex', () async {
        final client = dap.client;
        final testFile = dap.createTestFile('''
  void main(List<String> args) {
    var i = 12345;
    print('Hello!'); $breakpointMarker
  }''');
        final breakpointLine = lineWith(testFile, breakpointMarker);

        final stop = await client.hitBreakpoint(testFile, breakpointLine);
        final topFrameId = await client.getTopFrameId(stop.threadId!);
        await client.expectEvalResult(topFrameId, 'i', '12345');
        await client.expectEvalResult(topFrameId, 'i,h', '0x3039');
      });

      test('",d" renders numbers in decimal', () async {
        final client = dap.client;
        final testFile = dap.createTestFile('''
  void main(List<String> args) {
    var i = 12345;
    print('Hello!'); $breakpointMarker
  }''');
        final breakpointLine = lineWith(testFile, breakpointMarker);

        final stop = await client.hitBreakpoint(testFile, breakpointLine);
        final topFrameId = await client.getTopFrameId(stop.threadId!);
        await client.expectEvalResult(topFrameId, 'i', '12345');
        await client.expectEvalResult(topFrameId, 'i,d', '12345');
      });

      test('apply to child values', () async {
        final client = dap.client;
        final testFile = dap.createTestFile('''
  void main(List<String> args) {
    var myItems = [12345, 34567];
    print('Hello!'); $breakpointMarker
  }''');
        final breakpointLine = lineWith(testFile, breakpointMarker);

        final stop = await client.hitBreakpoint(testFile, breakpointLine);
        final topFrameId = await client.getTopFrameId(stop.threadId!);
        final result = await client.expectEvalResult(
            topFrameId, 'myItems,h', 'List (2 items)');

        // Check we got a variablesReference and fetching the child items uses
        // the requested formatting.
        expect(result.variablesReference, isPositive);
        await client.expectVariables(
          result.variablesReference,
          '''
            [0]: 0x3039, eval: myItems[0]
            [1]: 0x8707, eval: myItems[1]
        ''',
        );
      });

      test('multiple can be applied in any order', () async {
        final client = dap.client;
        final testFile = dap.createTestFile('''
  void main(List<String> args) {
    var myItems = [12345, 'test'];
    print('Hello!'); $breakpointMarker
  }''');
        final breakpointLine = lineWith(testFile, breakpointMarker);

        final stop = await client.hitBreakpoint(testFile, breakpointLine);
        final topFrameId = await client.getTopFrameId(stop.threadId!);
        for (final expression in ['myItems,h,nq', 'myItems,nq,h']) {
          final result = await client.expectEvalResult(
              topFrameId, expression, 'List (2 items)');

          // Check we got a variablesReference and fetching the child items uses
          // the requested formatting.
          expect(result.variablesReference, isPositive);
          await client.expectVariables(
            result.variablesReference,
            '''
            [0]: 0x3039, eval: myItems[0]
            [1]: test, eval: myItems[1]
        ''',
          );
        }
      });
    });

    group('value formats', () {
      test('supports format.hex in evaluation arguments', () async {
        final client = dap.client;
        final testFile = dap.createTestFile('''
  void main(List<String> args) {
    var i = 12345;
    print('Hello!'); $breakpointMarker
  }''');
        final breakpointLine = lineWith(testFile, breakpointMarker);

        final stop = await client.hitBreakpoint(testFile, breakpointLine);
        final topFrameId = await client.getTopFrameId(stop.threadId!);
        await client.expectEvalResult(
          topFrameId,
          'i',
          '0x3039',
          format: ValueFormat(hex: true),
        );
      });
    });

    group('provides paging data for', () {
      // Additional paging tests are in debug_variables_test.dart
      test('Lists', () async {
        final client = dap.client;
        final testFile = dap.createTestFile('''
void main(List<String> args) {
  var myList = List.generate(10000, (i) => i);
  print('Hello!'); $breakpointMarker
}''');
        final breakpointLine = lineWith(testFile, breakpointMarker);

        final stop = await client.hitBreakpoint(testFile, breakpointLine);
        final topFrameId = await client.getTopFrameId(stop.threadId!);
        final evalResult = await client.expectEvalResult(
            topFrameId, 'myList', 'List (10000 items)');
        expect(evalResult.indexedVariables, 10000);
      });

      test('Uint8List', () async {
        final client = dap.client;
        final testFile = dap.createTestFile('''
import 'dart:typed_data';

void main(List<String> args) {
  var myList = Uint8List(10000);
  print('Hello!'); $breakpointMarker
}''');
        final breakpointLine = lineWith(testFile, breakpointMarker);

        final stop = await client.hitBreakpoint(testFile, breakpointLine);
        final topFrameId = await client.getTopFrameId(stop.threadId!);
        final evalResult = await client.expectEvalResult(
            topFrameId, 'myList', 'Uint8List (10000 items)');
        expect(evalResult.indexedVariables, 10000);
      });
    });
    // These tests can be slow due to starting up the external server process.
  }, timeout: Timeout.none);
}
