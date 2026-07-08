// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer';

import 'common/test_helper.dart';

Future<void> testMain() async {
  debugger(); // LINE_0
  final future1 = Future.value(); // LINE_A
  final future2 = Future.value(); // LINE_B

  await future1; // LINE_C
  await future2; // LINE_D

  print('foo1'); // LINE_E
  print('foo2'); // LINE_F
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testMain);
}
