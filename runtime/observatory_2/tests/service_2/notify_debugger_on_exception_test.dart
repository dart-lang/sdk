// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--verbose_debug

// See: https://github.com/flutter/flutter/issues/17007

import 'test_helper.dart';
import 'service_test_common.dart';

const int LINE_A = 16;
const int LINE_B = 32;

syncThrow() {
  throw 'Hello from syncThrow!'; // Line A.
}

@pragma('vm:notify-debugger-on-exception')
void catchNotifyDebugger(Function() code) {
  try {
    code();
  } catch (e) {
    // Ignore. Internals will notify debugger.
  }
}

void catchNotifyDebuggerNested() {
  @pragma('vm:notify-debugger-on-exception')
  void nested() {
    try {
      throw 'Hello from nested!'; // Line B.
    } catch (e) {
      // Ignore. Internals will notify debugger.
    }
  }

  nested();
}

testMain() {
  catchNotifyDebugger(syncThrow);
  catchNotifyDebuggerNested();
}

final tests = <IsolateTest>[
  hasStoppedWithUnhandledException,
  stoppedAtLine(LINE_A),
  resumeIsolate,
  hasStoppedWithUnhandledException,
  stoppedAtLine(LINE_B),
];

main([args = const <String>[]]) => runIsolateTests(args, tests,
    testeeConcurrent: testMain, pause_on_unhandled_exceptions: true);
