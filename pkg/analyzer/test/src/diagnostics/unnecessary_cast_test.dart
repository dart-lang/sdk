// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryCastTest);
  });
}

@reflectiveTest
class UnnecessaryCastTest extends DriverResolutionTest {
  test_conditionalExpression() async {
    await assertNoErrorsInCode(r'''
abstract class I {}
class A implements I {}
class B implements I {}
I m(A a, B b) {
  return a == null ? b as I : a as I;
}
''');
  }

  test_dynamic_type() async {
    await assertErrorsInCode(r'''
m(v) {
  var b = v as Object;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 13, 1),
    ]);
  }

  test_function() async {
    await assertNoErrorsInCode(r'''
void main() {
  Function(Null) f = (String x) => x;
  (f as Function(int))(3); 
}
''');
  }

  test_function2() async {
    await assertErrorsInCode(r'''
class A {}

class B<T extends A> {
  void foo() {
    T Function(T) f;
    A Function(A) g;
    g = f as A Function(A);
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 89, 1),
    ]);
  }

  test_generics() async {
    // dartbug.com/18953
    await assertErrorsInCode(r'''
import 'dart:async';
Future<int> f() => new Future.value(0);
void g(bool c) {
  (c ? f(): new Future.value(0) as Future<int>).then((int value) {});
}
''', [
      error(HintCode.UNNECESSARY_CAST, 90, 34),
    ]);
  }

  test_parameter_A() async {
    // dartbug.com/13855, dartbug.com/13732
    await assertNoErrorsInCode(r'''
class A{
  a() {}
}
class B<E> {
  E e;
  m() {
    (e as A).a();
  }
}
''');
  }

  test_type_dynamic() async {
    await assertErrorsInCode(r'''
m(v) {
  var b = Object as dynamic;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 13, 1),
    ]);
  }

  test_type_supertype() async {
    await assertErrorsInCode(r'''
m(int i) {
  var b = i as Object;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 17, 1),
      error(HintCode.UNNECESSARY_CAST, 21, 11),
    ]);
  }

  test_type_type() async {
    await assertErrorsInCode(r'''
m(num i) {
  var b = i as num;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 17, 1),
      error(HintCode.UNNECESSARY_CAST, 21, 8),
    ]);
  }
}
