// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'common/test_helper.dart';

abstract class A {
  int get x;
  int get y;
}

class B implements A {
  @override
  final int x;
  @override
  final int y;
  B(this.x, this.y);
}

void foo(Object obj) {
  switch (obj) {
    case A(x: 4, y: 5):
      print('A(4, 5)');
    case A(x: final x1, y: final y1):
      debugger();
      print('A(x: $x1, y: $y1)');
  }
}

void testMain() {
  foo(B(2, 3));
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testMain);
}
