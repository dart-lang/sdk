// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/hint_codes.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeParameterReferencedByStaticTest);
  });
}

@reflectiveTest
class TypeParameterReferencedByStaticTest extends DriverResolutionTest {
  test_field() async {
    await assertErrorsInCode('''
class A<K> {
  static K k;
}''', [
      error(StaticWarningCode.TYPE_PARAMETER_REFERENCED_BY_STATIC, 22, 1),
    ]);
  }

  test_getter() async {
    await assertErrorsInCode('''
class A<K> {
  static K get k => null;
}''', [
      error(StaticWarningCode.TYPE_PARAMETER_REFERENCED_BY_STATIC, 22, 1),
    ]);
  }

  test_methodBodyReference() async {
    await assertErrorsInCode('''
class A<K> {
  static m() {
    K k;
  }
}''', [
      error(StaticWarningCode.TYPE_PARAMETER_REFERENCED_BY_STATIC, 32, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 34, 1),
    ]);
  }

  test_methodParameter() async {
    await assertErrorsInCode('''
class A<K> {
  static m(K k) {}
}''', [
      error(StaticWarningCode.TYPE_PARAMETER_REFERENCED_BY_STATIC, 24, 1),
    ]);
  }

  test_methodReturn() async {
    await assertErrorsInCode('''
class A<K> {
  static K m() { return null; }
}''', [
      error(StaticWarningCode.TYPE_PARAMETER_REFERENCED_BY_STATIC, 22, 1),
    ]);
  }

  test_setter() async {
    await assertErrorsInCode('''
class A<K> {
  static set s(K k) {}
}''', [
      error(StaticWarningCode.TYPE_PARAMETER_REFERENCED_BY_STATIC, 28, 1),
    ]);
  }

  test_simpleIdentifier() async {
    await assertErrorsInCode('''
class A<T> {
  static foo() {
    T;
  }
}
''', [
      error(StaticWarningCode.TYPE_PARAMETER_REFERENCED_BY_STATIC, 34, 1),
    ]);
  }
}
