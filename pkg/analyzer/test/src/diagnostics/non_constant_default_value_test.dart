// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/test_support.dart';
import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonConstantDefaultValueTest);
  });
}

@reflectiveTest
class NonConstantDefaultValueTest extends DriverResolutionTest {
  test_appliedTypeParameter_defaultConstructorValue() async {
    await assertErrorsInCode(r'''
void f<T>(T t) => t;

class C<T> {
  final void Function(T) p;
  const C({this.p = f});
}
''', [ExpectedError(CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE, 83, 1)]);
  }

  test_appliedTypeParameter_defaultFunctionValue() async {
    await assertErrorsInCode(r'''
void f<T>(T t) => t;

void bar<T>([void Function(T) p = f]) {}
''', [ExpectedError(CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE, 56, 1)]);
  }

  test_appliedTypeParameter_defaultMethodValue() async {
    await assertErrorsInCode(r'''
void f<T>(T t) => t;

class C<T> {
  void foo([void Function(T) p = f]) {}
}
''', [ExpectedError(CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE, 68, 1)]);
  }

  test_appliedTypeParameter_nested() async {
    await assertErrorsInCode(r'''
void f<T>(T t) => t;

void bar<T>([void Function(List<T>) p = f]) {}
''', [ExpectedError(CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE, 62, 1)]);
  }

  test_appliedTypeParameter_nestedFunction() async {
    await assertErrorsInCode(r'''
void f<T>(T t) => t;

void bar<T>([void Function(T Function()) p = f]) {}
''', [ExpectedError(CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE, 67, 1)]);
  }

  test_noAppliedTypeParameters_defaultConstructorValue_dynamic() async {
    await assertNoErrorsInCode(r'''
void f<T>(T t) => t;

class C<T> {
  final dynamic p;
  const C({this.p = f});
}
''');
  }

  test_noAppliedTypeParameters_defaultConstructorValue_genericFn() async {
    await assertNoErrorsInCode(r'''
void f<T>(T t) => t;

class C<T> {
  final void Function<T>(T) p;
  const C({this.p = f});
}
''');
  }

  test_noAppliedTypeParameters_defaultFunctionValue_genericFn() async {
    await assertNoErrorsInCode(r'''
void f<T>(T t) => t;

void bar<T>([void Function<T>(T) p = f]) {}
''');
  }

  test_noAppliedTypeParameters_defaultMethodValue_genericFn() async {
    await assertNoErrorsInCode(r'''
void f<T>(T t) => t;

class C<T> {
  void foo([void Function<T>(T) p = f]) {}
}
''');
  }
}
