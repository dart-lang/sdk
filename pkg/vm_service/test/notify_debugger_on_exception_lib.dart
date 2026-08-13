// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/test_helper.dart';

Never syncThrow() {
  throw 'Hello from syncThrow!'; // LINE_A
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
      throw 'Hello from nested!'; // LINE_B
    } catch (e) {
      // Ignore. Internals will notify debugger.
    }
  }

  nested();
}

void testMain() {
  catchNotifyDebugger(syncThrow);
  catchNotifyDebuggerNested();
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testMain);
}
