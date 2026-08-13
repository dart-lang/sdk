// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'common/test_helper.dart';

void topLevel<S>() {
  debugger(); // LINE_A

  void inner1<TBool, TString, TDouble, TInt>(TInt x) {
    debugger(); // LINE_B
  }

  inner1<bool, String, double, int>(3);

  void inner2() {
    debugger(); // LINE_C
  }

  inner2();
}

class A {
  void foo<T, S>() {
    debugger(); // LINE_D
  }

  void bar<T>(T t) {
    debugger(); // LINE_E
  }
}

void testMain() {
  topLevel<String>();
  A().foo<int, bool>();
  A().bar<dynamic>(42);
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testMain);
}
