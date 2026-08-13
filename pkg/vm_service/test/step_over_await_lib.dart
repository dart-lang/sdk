// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer';
import 'common/test_helper.dart';

// This tests the asyncNext command.
Future<void> asyncFunction() async {
  debugger(); // LINE_A
  print('a'); // LINE_B
  await Future.delayed(Duration(seconds: 2));
  print('b'); // LINE_C
}

void testMain() {
  asyncFunction();
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testMain);
}
