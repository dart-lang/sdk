// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--verbose_debug

// Check that a try/finally is not treated as a try/catch:
// http://dartbug.com/45684.

import 'test_helper.dart';
import 'service_test_common.dart';

const int LINE_A = 25;

void tryFinally(Function() code) {
  // There is a synthetic try/catch inside try/finally but it is not authored
  // by the user, so debugger should not consider that this try/catch is
  // going to handle the exception.
  try {
    code();
  } finally {}
}

syncThrow() {
  throw 'Hello from syncThrow!'; // Line A.
}

testMain() {
  tryFinally(syncThrow);
}

final tests = <IsolateTest>[
  hasStoppedWithUnhandledException,
  stoppedAtLine(LINE_A),
];

main([args = const <String>[]]) => runIsolateTests(args, tests,
    testeeConcurrent: testMain, pause_on_unhandled_exceptions: true);
