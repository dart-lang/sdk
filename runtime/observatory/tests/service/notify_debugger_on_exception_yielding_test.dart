// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--verbose_debug

// See: https://github.com/dart-lang/sdk/issues/45673

import 'test_helper.dart';
import 'service_test_common.dart';

const int LINE_A = 19;
const int LINE_B = 29;
const int LINE_C = 39;

@pragma('vm:notify-debugger-on-exception')
Future<void> throwFromAsync() async {
  try {
    throw 'Throw from throwFromAsync'; // LINE_A
  } catch (e) {
    // Ignore. Internals will notify debugger.
  }
  return Future.value();
}

@pragma('vm:notify-debugger-on-exception')
Stream<int> throwFromAsyncStar() async* {
  try {
    throw 'Throw from throwFromAsyncStar'; // LINE_B
  } catch (e) {
    // Ignore. Internals will notify debugger.
  }
  yield 13;
}

@pragma('vm:notify-debugger-on-exception')
Iterable<int> throwFromSyncStar() sync* {
  try {
    throw 'Throw from throwFromSyncStar'; // LINE_C
  } catch (e) {
    // Ignore. Internals will notify debugger.
  }
  yield 7;
}

testMain() async {
  throwFromAsync();
  await for (var e in throwFromAsyncStar()) {/*ignore*/}
  for (var e in throwFromSyncStar()) {/*ignore*/}
}

final tests = <IsolateTest>[
  hasStoppedWithUnhandledException,
  stoppedAtLine(LINE_A),
  resumeIsolate,
  hasStoppedWithUnhandledException,
  stoppedAtLine(LINE_B),
  resumeIsolate,
  hasStoppedWithUnhandledException,
  stoppedAtLine(LINE_C),
];

main([args = const <String>[]]) => runIsolateTests(args, tests,
    testeeConcurrent: testMain, pause_on_unhandled_exceptions: true);
