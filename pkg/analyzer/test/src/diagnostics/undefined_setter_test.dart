// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedSetterTest);
  });
}

@reflectiveTest
class UndefinedSetterTest extends DriverResolutionTest {
  test_importWithPrefix_defined() async {
    newFile("/test/lib/lib.dart", content: r'''
library lib;
set y(int value) {}''');
    await assertNoErrorsInCode(r'''
import 'lib.dart' as x;
main() {
  x.y = 0;
}
''');
  }

  test_instance_undefined() async {
    await assertErrorsInCode(r'''
class T {}
f(T e1) { e1.m = 0; }
''', [
      error(StaticTypeWarningCode.UNDEFINED_SETTER, 24, 1),
    ]);
  }

  test_instance_undefined_mixin() async {
    await assertErrorsInCode(r'''
mixin M {
  f() { this.m = 0; }
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_SETTER, 23, 1),
    ]);
  }

  test_inSubtype() async {
    await assertErrorsInCode(r'''
class A {}
class B extends A {
  set b(x) {}
}
f(var a) {
  if (a is A) {
    a.b = 0;
  }
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_SETTER, 80, 1),
    ]);
  }

  test_inType() async {
    await assertErrorsInCode(r'''
class A {}
f(var a) {
  if(a is A) {
    a.m = 0;
  }
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_SETTER, 43, 1),
    ]);
  }

  test_static_conditionalAccess_defined() async {
    // The conditional access operator '?.' can be used to access static
    // fields.
    await assertNoErrorsInCode('''
class A {
  static var x;
}
f() { A?.x = 1; }
''');
  }

  test_static_definedInSuperclass() async {
    await assertErrorsInCode('''
class S {
  static set s(int i) {}
}
class C extends S {}
f(var p) {
  f(C.s = 1);
}''', [
      error(StaticTypeWarningCode.UNDEFINED_SETTER, 75, 1),
    ]);
  }

  test_static_undefined() async {
    await assertErrorsInCode(r'''
class A {}
f() { A.B = 0;}
''', [
      error(StaticTypeWarningCode.UNDEFINED_SETTER, 19, 1),
    ]);
  }

  test_typeLiteral_cascadeTarget() async {
    await assertErrorsInCode(r'''
class T {
  static void set foo(_) {}
}
main() {
  T..foo = 42;
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_SETTER, 54, 3),
    ]);
  }

  test_withExtension() async {
    await assertErrorsInCode(r'''
class C {}

extension E on C {}

f(C c) {
  c.a = 1;
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_SETTER, 46, 1),
    ]);
  }
}
