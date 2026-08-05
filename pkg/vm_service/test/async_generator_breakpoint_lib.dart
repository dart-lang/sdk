// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'common/test_helper.dart';

void printSync() {
  print('sync'); // LINE_A
}

Future<void> printAsync() async {
  await null;
  print('async'); // LINE_B
}

Stream<void> printAsyncStar() async* {
  await null;
  print('async*'); // LINE_C
}

Iterable<void> printSyncStar() sync* {
  print('sync*'); // LINE_D
}

var testerReady = false;
Future<void> testeeDo() async {
  // We block here rather than allowing the isolate to enter the
  // paused-on-exit state before the tester gets a chance to set
  // the breakpoints because we need the event loop to remain
  // operational for the async bodies to run.
  print('testee waiting');
  while (!testerReady) {}

  printSync();
  final future = printAsync();
  final stream = printAsyncStar();
  final iterator = printSyncStar();

  print('middle'); // LINE_E

  unawaited(future);
  unawaited(stream.toList());
  iterator.toList();
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testeeDo);
}
