// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'common/test_helper.dart';

int globalVar = 100;

class MyClass {
  static int staticVar = 1000;

  static void method(int value) {
    debugger();
  }
}

class _MyClass {
  void foo() {
    debugger();
  }
}

void testeeMain() {
  int i = 0;
  while (true) {
    if (++i % 100000000 == 0) {
      MyClass.method(10000);
      _MyClass().foo();
    }
  }
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testeeMain);
}
