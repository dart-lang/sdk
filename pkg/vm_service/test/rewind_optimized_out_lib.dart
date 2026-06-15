// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'common/test_helper.dart';

int global = 0;

@pragma('vm:never-inline')
int b3(int x) {
  int sum = 0;
  try {
    for (int i = 0; i < x; i++) {
      sum += x;
    }
  } catch (e) {
    print('caught $e');
  }
  if (global >= 100) {
    debugger(); // LINE_0
  }
  global = global + 1; // LINE_A
  return sum;
}

@pragma('vm:prefer-inline')
int b2(x) => b3(x); // LINE_B

@pragma('vm:prefer-inline')
int b1(x) => b2(x); // LINE_C

void test() {
  while (true) {
    b1(10000); // LINE_D
  }
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: test);
}
