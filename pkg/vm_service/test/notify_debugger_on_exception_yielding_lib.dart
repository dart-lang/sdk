// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--verbose_debug

import 'common/test_helper.dart';

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

Future<void> testMain() async {
  await throwFromAsync();
  await for (var _ in throwFromAsyncStar()) {/*ignore*/}
  for (var _ in throwFromSyncStar()) {/*ignore*/}
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testMain);
}
