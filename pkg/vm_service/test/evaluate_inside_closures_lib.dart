// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'common/test_helper.dart';

class C {
  static int staticField = 12;
  int instanceField = 34;

  static void staticMethod() {
    ((int x) {
      debugger(); // LINE_A
    })(56);
  }

  void instanceMethod() {
    ((int y) {
      debugger(); // LINE_B
      use(this);
    })(78);
  }
}

void use(_) {}

void testMain() {
  final C c = C();
  C.staticMethod();
  c.instanceMethod();
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testMain);
}
