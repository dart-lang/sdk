// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConflictingTypeVariableAndMemberExtensionTest);
    defineReflectiveTests(ConflictingTypeVariableAndMemberTest);
  });
}

@reflectiveTest
class ConflictingTypeVariableAndMemberExtensionTest
    extends DriverResolutionTest {
  test_getter() async {
    await assertErrorsInCode(r'''
extension A<T> on String {
  get T => null;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER_EXTENSION,
          12, 1),
    ]);
  }

  test_method() async {
    await assertErrorsInCode(r'''
extension A<T> on String {
  T() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER_EXTENSION,
          12, 1),
    ]);
  }

  test_setter() async {
    await assertErrorsInCode(r'''
extension A<T> on String {
  set T(x) {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER_EXTENSION,
          12, 1),
    ]);
  }
}

@reflectiveTest
class ConflictingTypeVariableAndMemberTest extends DriverResolutionTest {
  test_field() async {
    await assertErrorsInCode(r'''
class A<T> {
  var T;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER_CLASS, 8,
          1),
    ]);
  }

  test_getter() async {
    await assertErrorsInCode(r'''
class A<T> {
  get T => null;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER_CLASS, 8,
          1),
    ]);
  }

  test_method() async {
    await assertErrorsInCode(r'''
class A<T> {
  T() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER_CLASS, 8,
          1),
    ]);
  }

  test_method_static() async {
    await assertErrorsInCode(r'''
class A<T> {
  static T() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER_CLASS, 8,
          1),
    ]);
  }

  test_setter() async {
    await assertErrorsInCode(r'''
class A<T> {
  set T(x) {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER_CLASS, 8,
          1),
    ]);
  }
}
