// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'common/test_helper.dart';

Stream<int> foobar() async* {
  debugger(); // LINE_0
  yield 1; // LINE_B
  debugger(); // LINE_1
  yield 2; // LINE_C
}

Future<void> helper() async {
  debugger(); // LINE_2
  print('helper'); // LINE_A
  await for (var i in foobar()) {
    print('helper $i');
  }
}

void testMain() {
  helper();
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testMain);
}
