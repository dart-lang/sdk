// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--verbose_debug

// See: https://github.com/flutter/flutter/issues/17007

import 'test_helper.dart';
import 'service_test_common.dart';

const int LINE_A = 24;

@pragma('vm:notify-debugger-on-exception')
void catchNotifyDebugger(Function() code) {
  try {
    code();
  } catch (e) {
    // Ignore. Internals will notify debugger.
  }
}

syncThrow() {
  throw 'Hello from syncThrow!'; // Line A.
}

testMain() {
  catchNotifyDebugger(syncThrow);
}

final tests = <IsolateTest>[
  hasStoppedWithUnhandledException,
  stoppedAtLine(LINE_A),
];

main([args = const <String>[]]) => runIsolateTests(args, tests,
    testeeConcurrent: testMain, pause_on_unhandled_exceptions: true);
