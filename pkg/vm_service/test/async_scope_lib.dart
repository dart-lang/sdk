// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'common/test_helper.dart';

void foo() {}

Future<void> doAsync(int param1) async {
  final local1 = param1 + 1;
  foo(); // LINE_A
  // ignore: await_only_futures
  await local1;
}

Stream<int> doAsyncStar(int param2) async* {
  final local2 = param2 + 1;
  foo(); // LINE_B
  yield local2;
}

void testeeDo() {
  debugger(); // LINE_C

  doAsync(1).then((_) {
    doAsyncStar(1).listen((_) {});
  });
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testeeDo);
}
