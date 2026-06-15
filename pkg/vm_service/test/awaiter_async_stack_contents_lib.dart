// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'common/test_helper.dart';

Future<void> foobar() async {
  await null;
  debugger(); // LINE_0
  print('foobar'); // LINE_C
}

Future<void> helper() async {
  await null;
  debugger(); // LINE_1
  print('helper'); // LINE_A
  await foobar(); // LINE_D
}

Future<void> testMain() async {
  debugger(); // LINE_2
  await helper(); // LINE_B
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testMain);
}
