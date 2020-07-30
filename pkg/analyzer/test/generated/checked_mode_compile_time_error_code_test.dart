// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CheckedModeCompileTimeErrorCodeTest);
  });
}

@reflectiveTest
class CheckedModeCompileTimeErrorCodeTest extends DriverResolutionTest {
  test_assertion_throws() async {
    await assertErrorsInCode(r'''
class A {
  const A(int x, int y) : assert(x < y);
}
var v = const A(3, 2);
''', [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 61, 13),
    ]);
  }

  test_fieldInitializerNotAssignable() async {
    await assertErrorsInCode(r'''
class A {
  final int x;
  const A() : x = '';
}
''', [
      error(CompileTimeErrorCode.FIELD_INITIALIZER_NOT_ASSIGNABLE, 43, 2),
      error(
          CheckedModeCompileTimeErrorCode
              .CONST_FIELD_INITIALIZER_NOT_ASSIGNABLE,
          43,
          2),
    ]);
  }

  test_fieldTypeMismatch() async {
    await assertErrorsInCode(r'''
class A {
  const A(x) : y = x;
  final int y;
}
var v = const A('foo');
''', [
      error(
          CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_FIELD_TYPE_MISMATCH,
          57,
          14),
    ]);
  }

  test_fieldTypeMismatch_generic() async {
    await assertErrorsInCode(
      r'''
class C<T> {
  final T x = y;
  const C();
}
const int y = 1;
var v = const C<String>();
''',
      [
        error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 27, 1),
        error(
            CheckedModeCompileTimeErrorCode
                .CONST_CONSTRUCTOR_FIELD_TYPE_MISMATCH,
            70,
            17),
      ],
    );
  }

  test_fieldTypeMismatch_unresolved() async {
    await assertErrorsInCode(r'''
class A {
  const A(x) : y = x;
  final Unresolved y;
}
var v = const A('foo');
''', [
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 40, 10),
    ]);
  }

  test_fieldTypeOk_generic() async {
    await assertErrorsInCode(
      r'''
class C<T> {
  final T x = y;
  const C();
}
const int y = 1;
var v = const C<int>();
''',
      [
        error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 27, 1),
      ],
    );
  }

  test_fieldTypeOk_null() async {
    await assertNoErrorsInCode(r'''
class A {
  const A(x) : y = x;
  final int y;
}
var v = const A(null);
''');
  }

  test_fieldTypeOk_unresolved_null() async {
    // Null always passes runtime type checks, even when the type is
    // unresolved.
    await assertErrorsInCode(r'''
class A {
  const A(x) : y = x;
  final Unresolved y;
}
var v = const A(null);
''', [
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 40, 10),
    ]);
  }

  test_listElementTypeNotAssignable() async {
    await assertErrorsInCode('''
var v = const <String> [42];
''', [
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 24, 2),
    ]);
  }

  test_listLiteral_inferredElementType() async {
    await assertErrorsInCode('''
const Object x = [1];
const List<String> y = x;
''', [
      error(CheckedModeCompileTimeErrorCode.VARIABLE_TYPE_MISMATCH, 45, 1),
    ]);
  }

  test_mapLiteral_inferredKeyType() async {
    await assertErrorsInCode('''
const Object x = {1: 1};
const Map<String, dynamic> y = x;
''', [
      error(CheckedModeCompileTimeErrorCode.VARIABLE_TYPE_MISMATCH, 56, 1),
    ]);
  }

  test_mapLiteral_inferredValueType() async {
    await assertErrorsInCode('''
const Object x = {1: 1};
const Map<dynamic, String> y = x;
''', [
      error(CheckedModeCompileTimeErrorCode.VARIABLE_TYPE_MISMATCH, 56, 1),
    ]);
  }

  test_parameterAssignable_null() async {
    // Null is assignable to anything.
    await assertNoErrorsInCode(r'''
class A {
  const A(int x);
}
var v = const A(null);''');
  }

  test_parameterAssignable_typeSubstitution() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  const A(T x);
}
var v = const A<int>(3);''');
  }

  test_parameterAssignable_undefined_null() async {
    // Null always passes runtime type checks, even when the type is
    // unresolved.
    await assertErrorsInCode(r'''
class A {
  const A(Unresolved x);
}
var v = const A(null);
''', [
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 20, 10),
    ]);
  }

  test_parameterNotAssignable() async {
    await assertErrorsInCode(r'''
class A {
  const A(int x);
}
var v = const A('foo');
''', [
      error(CompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH, 46, 5),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 46, 5),
    ]);
  }

  test_parameterNotAssignable_typeSubstitution() async {
    await assertErrorsInCode(r'''
class A<T> {
  const A(T x);
}
var v = const A<int>('foo');
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 52, 5),
      error(CompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH, 52, 5),
    ]);
  }

  test_parameterNotAssignable_undefined() async {
    await assertErrorsInCode(r'''
class A {
  const A(Unresolved x);
}
var v = const A('foo');
''', [
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 20, 10),
    ]);
  }

  test_redirectingConstructor_paramTypeMismatch() async {
    await assertErrorsInCode(r'''
class A {
  const A.a1(x) : this.a2(x);
  const A.a2(String x);
}
var v = const A.a1(0);
''', [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 74, 13),
    ]);
  }

  test_superConstructor_paramTypeMismatch() async {
    await assertErrorsInCode(r'''
class C {
  final double d;
  const C(this.d);
}
class D extends C {
  const D(d) : super(d);
}
const f = const D('0.0');
''', [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 106, 14),
    ]);
  }

  test_topLevelVarAssignable_null() async {
    await assertNoErrorsInCode('''
const int x = null;
''');
  }

  test_topLevelVarAssignable_undefined_null() async {
    // Null always passes runtime type checks, even when the type is
    // unresolved.
    await assertErrorsInCode('''
const Unresolved x = null;
''', [
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 6, 10),
    ]);
  }

  test_topLevelVarNotAssignable() async {
    await assertErrorsInCode('''
const int x = 'foo';
''', [
      error(CheckedModeCompileTimeErrorCode.VARIABLE_TYPE_MISMATCH, 14, 5),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 14, 5),
    ]);
  }

  test_topLevelVarNotAssignable_undefined() async {
    await assertErrorsInCode('''
const Unresolved x = 'foo';
''', [
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 6, 10),
    ]);
  }
}
