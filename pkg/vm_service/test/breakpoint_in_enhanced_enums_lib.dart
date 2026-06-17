// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/test_helper.dart';

mixin M on Object {
  int mixedInMethod() {
    print('mixedInMethod'); // LINE_A
    return 0;
  }
}

enum E with M {
  e1,
  e2,
  e3;

  void instanceMethod() {
    print('instanceMethod'); // LINE_B
  }

  static void staticMethod() {
    print('staticMethod'); // LINE_C
  }

  int get getter {
    print('getter'); // LINE_D
    return 0;
  }

  set setter(int x) {
    print('setter'); // LINE_E
  }

  static int get staticGetter {
    print('staticGetter'); // LINE_F
    return 0;
  }

  static set staticSetter(int x) {
    print('staticSetter'); // LINE_G
  }

  @override
  String toString() {
    print('overridden toString'); // LINE_H
    return '';
  }
}

void testMain() {
  E.staticMethod();
  E.staticGetter;
  E.staticSetter = 42;
  final e = E.e1;
  e.mixedInMethod();
  e.instanceMethod();
  e.getter;
  e.setter = 42;
  e.toString();
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testMain);
}
