// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for constructors and initializers.

// Check function subtyping of inlined function typed parameters.

import 'checked_mode_helper.dart';

class C {
  var field;
  C.c1(int this.field());
  C.c2({int this.field()});
  C.c3({int field(): null});
  C.c4({int this.field(): null});
  C.c5([int this.field()]);
  C.c6([int field() = null]);
  C.c7([int this.field() = null]);
}

void test(var f, String constructorName) {
  testDynamicTypeError(false, () => f(m1), "'new C.$constructorName(m1)'");
  testDynamicTypeError(true, () => f(m2), "'new C.$constructorName(m2)'");
  testDynamicTypeError(false, () => f(m3), "'new C.$constructorName(m3)'");
  testDynamicTypeError(true, () => f(m4), "'new C.$constructorName(m4)'");
}

int m1() => null;
String m2() => null;
m3() => null;
m4(int i) => null;

main() {
  test((m) => new C.c1(m), 'c1');
  test((m) => new C.c2(field: m), 'c2');
  test((m) => new C.c3(field: m), 'c3');
  test((m) => new C.c4(field: m), 'c4');
  test((m) => new C.c5(m), 'c5');
  test((m) => new C.c6(m), 'c6');
  test((m) => new C.c7(m), 'c7');
}
