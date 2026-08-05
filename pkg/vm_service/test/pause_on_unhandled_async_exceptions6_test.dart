// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that debugger does not pause when exception is caught by stream
// onError.
//
// Regression test for https://github.com/dart-lang/sdk/issues/54788.

import 'common/service_test_common.dart';
import 'pause_on_unhandled_async_exceptions6_lib.dart' as testee_lib;

Future<void> main([args = const <String>[]]) async {
  final harness = IsolateTestHarness(
    'pause_on_unhandled_async_exceptions6_lib.dart',
    args,
  );

  int nextTestIndex = 0;

  void addTest(
    List<ExpectedFrame> Function(TestScriptParser) expectedFrames,
  ) {
    final testIndex = nextTestIndex++;
    if (testIndex > 0) {
      harness.addCustomTest(
        resumePastUnhandledException('Uncaught#${testIndex - 1}'),
      );
    }
    harness.addCustomTestWithParser(
      (service, isolate, parser) => expectUnhandledExceptionWithFrames(
        exceptionAsString: 'Uncaught#$testIndex',
        expectedFrames: expectedFrames(parser),
      )(service, isolate),
    );
  }

  void addTests(
    List<ExpectedFrame> Function(TestScriptParser) streamFactoryPrefix,
  ) {
    // Testing: _stream().listen((_) {})
    addTest(
      (parser) => [
        ...streamFactoryPrefix(parser),
        asyncGap,
        (
          functionName:
              'testStreamUncaught.<anonymous closure>.<anonymous closure>',
          line: null
        ),
      ],
    );

    // Testing: _stream().toList()
    addTest(
      (parser) => [
        ...streamFactoryPrefix(parser),
        asyncGap,
        (functionName: 'Stream.toList.<anonymous closure>', line: null),
        asyncGap,
        (
          functionName: 'testStreamUncaught.<anonymous closure>',
          line: parser.lineForTag('LINE_B')
        ),
      ],
    );

    // Testing: _stream().last
    addTest(
      (parser) => [
        ...streamFactoryPrefix(parser),
        asyncGap,
        (functionName: 'Stream.last.<anonymous closure>', line: null),
        asyncGap,
        (
          functionName: 'testStreamUncaught.<anonymous closure>',
          line: parser.lineForTag('LINE_C')
        ),
      ],
    );
  }

  addTests(
    (parser) => [
      (functionName: '_throwingStream1', line: parser.lineForTag('LINE_A')),
    ],
  );
  addTests(
    (parser) => [
      (functionName: '_throwingStream1', line: parser.lineForTag('LINE_A')),
      asyncGap,
      (functionName: '_throwingStream2', line: parser.lineForTag('LINE_AA')),
    ],
  );
  addTests(
    (parser) => [
      (functionName: '_throwingStream1', line: parser.lineForTag('LINE_A')),
      asyncGap,
      (functionName: '_throwingStream3', line: parser.lineForTag('LINE_AB')),
    ],
  );

  await harness.run(
    testeeMain: testee_lib.main,
    pauseOnUnhandledExceptions: true,
  );
}
