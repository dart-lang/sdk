// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'common/test_helper.dart';

Future<void> helper() async {
  print('helper'); // LINE_A
  return; // LINE_B
}

Future<void> testMain() async {
  debugger(); // LINE_0
  print('mmmmm'); // LINE_C
  await helper(); // LINE_D
  print('z'); // LINE_E
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testMain);
}
