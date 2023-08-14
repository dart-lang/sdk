// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This test ensures that "pkg:stack_trace" (used by "pkg:test") doesn't break
// when lazy async stacks are enabled by dropping frames below a synchronous
// start to an async function.
//
// Note: we pass --save-debugging-info=* without --dwarf-stack-traces to
// make this test pass on vm-aot-dwarf-* builders.
//
// VMOptions=--save-debugging-info=$TEST_COMPILATION_DIR/debug.so
// VMOptions=--dwarf-stack-traces --save-debugging-info=$TEST_COMPILATION_DIR/debug.so

import 'dart:async';

import 'package:test/test.dart';

import 'harness.dart' as harness;

Future<StackTrace> firstMethod() async {
  return await secondMethod();
}

Future<StackTrace> secondMethod() async {
  return StackTrace.current;
}

void main() {
  if (harness.shouldSkip()) {
    return;
  }

  setUpAll(() => harness.configure(currentExpectations));

  test("Stacktrace includes sync-starts.", () async {
    final st = await firstMethod();
    await harness.checkExpectedStack(st);
  });

  tearDownAll(() => harness.updateExpectations());
}

// CURRENT EXPECTATIONS BEGIN
final currentExpectations = [
  """
#0    secondMethod (%test%)
#1    firstMethod (%test%)
#2    main.<anonymous closure> (%test%)
#3    Declarer.test.<anonymous closure>.<anonymous closure> (declarer.dart)
<asynchronous suspension>
#4    Declarer.test.<anonymous closure> (declarer.dart)
<asynchronous suspension>
#5    Invoker._waitForOutstandingCallbacks.<anonymous closure> (invoker.dart)
<asynchronous suspension>"""
];
// CURRENT EXPECTATIONS END
