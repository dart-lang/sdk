// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'common/test_helper.dart';

void foobar() {
  debugger(); // LINE_0
  print('foobar'); // LINE_C
}

Future<void> helper() async {
  // ignore: await_only_futures
  await 0; // force async gap
  debugger(); // LINE_1
  print('helper'); // LINE_A
  foobar();
}

void testMain() {
  debugger(); // LINE_2
  helper(); // LINE_B
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testMain);
}
