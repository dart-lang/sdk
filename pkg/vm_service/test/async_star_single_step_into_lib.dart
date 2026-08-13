// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'common/test_helper.dart';

Stream<int> foobar() async* {
  yield 1; // LINE_A
  yield 2; // LINE_B
}

Future<void> helper() async {
  print('helper'); // LINE_C
  // ignore: unused_local_variable
  await for (var i in foobar()) // LINE_G
  {
    debugger(); // LINE_0
    print('loop'); // LINE_D
  }
}

Future<void> testMain() async {
  debugger(); // LINE_1
  print('mmmmm'); // LINE_E
  await helper(); // LINE_F
  print('z');
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testMain);
}
