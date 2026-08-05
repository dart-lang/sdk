// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer' show debugger;

import 'common/test_helper.dart';

int getTwo() => 3;

int getThree() => 3;

class C {
  static int x = getTwo() + getThree(); // LINE_A
}

Future<void> testeeMain() async {
  final y = C.x;
  print(y);
  debugger(); // LINE_B
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testeeMain);
}
