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

  test_fieldFormalParameterAssignableToField_extends() async {
    // According to checked-mode type checking rules, a value of type B is
    // assignable to a field of type A, because B extends A (and hence is a
    // subtype of A).
    await assertNoErrorsInCode(r'''
class A {
  const A();
}
class B extends A {
  const B();
}
class C {
  final A a;
  const C(this.a);
}
var v = const C(const B());
''');
  }

  test_fieldFormalParameterAssignableToField_fieldType_unresolved_null() async {
    // Null always passes runtime type checks, even when the type is
    // unresolved.
    await assertErrorsInCode(r'''
class A {
  final Unresolved x;
  const A(String this.x);
}
var v = const A(null);
''', [
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 18, 10),
    ]);
  }

  test_fieldFormalParameterAssignableToField_implements() async {
    // According to checked-mode type checking rules, a value of type B is
    // assignable to a field of type A, because B implements A (and hence is a
    // subtype of A).
    await assertNoErrorsInCode(r'''
class A {}
class B implements A {
  const B();
}
class C {
  final A a;
  const C(this.a);
}
var v = const C(const B());
''');
  }

  test_fieldFormalParameterAssignableToField_list_dynamic() async {
    // [1, 2, 3] has type List<dynamic>, which is a subtype of List<int>.
    await assertNoErrorsInCode(r'''
class A {
  const A(List<int> x);
}
var x = const A(const [1, 2, 3]);
''');
  }

  test_fieldFormalParameterAssignableToField_list_nonDynamic() async {
    // <int>[1, 2, 3] has type List<int>, which is a subtype of List<num>.
    await assertNoErrorsInCode(r'''
class A {
  const A(List<num> x);
}
var x = const A(const <int>[1, 2, 3]);
''');
  }

  test_fieldFormalParameterAssignableToField_map_dynamic() async {
    // {1: 2} has type Map<dynamic, dynamic>, which is a subtype of
    // Map<int, int>.
    await assertNoErrorsInCode(r'''
class A {
  const A(Map<int, int> x);
}
var x = const A(const {1: 2});
''');
  }

  test_fieldFormalParameterAssignableToField_map_keyDifferent() async {
    // <int, int>{1: 2} has type Map<int, int>, which is a subtype of
    // Map<num, int>.
    await assertNoErrorsInCode(r'''
class A {
  const A(Map<num, int> x);
}
var x = const A(const <int, int>{1: 2});
''');
  }

  test_fieldFormalParameterAssignableToField_map_valueDifferent() async {
    // <int, int>{1: 2} has type Map<int, int>, which is a subtype of
    // Map<int, num>.
    await assertNoErrorsInCode(r'''
class A {
  const A(Map<int, num> x);
}
var x = const A(const <int, int>{1: 2});
''');
  }

  test_fieldFormalParameterAssignableToField_notype() async {
    // If a field is declared without a type, then any value may be assigned to
    // it.
    await assertNoErrorsInCode(r'''
class A {
  final x;
  const A(this.x);
}
var v = const A(5);
''');
  }

  test_fieldFormalParameterAssignableToField_null() async {
    // Null is assignable to anything.
    await assertNoErrorsInCode(r'''
class A {
  final int x;
  const A(this.x);
}
var v = const A(null);
''');
  }

  test_fieldFormalParameterAssignableToField_typedef() async {
    // foo has the runtime type dynamic -> dynamic, so it is not assignable
    // to A.f.
    await assertErrorsInCode(r'''
typedef String Int2String(int x);
class A {
  final Int2String f;
  const A(this.f);
}
foo(x) => 1;
var v = const A(foo);
''', [
      error(StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 116, 3),
      error(
          CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH,
          116,
          3),
    ]);
  }

  test_fieldFormalParameterAssignableToField_typeSubstitution() async {
    // foo has the runtime type dynamic -> dynamic, so it should be assignable
    // to A.f.
    await assertNoErrorsInCode(r'''
class A<T> {
  final T x;
  const A(this.x);
}
var v = const A<int>(3);
''');
  }

  test_fieldFormalParameterNotAssignableToField() async {
    await assertErrorsInCode(r'''
class A {
  final int x;
  const A(this.x);
}
var v = const A('foo');
''', [
      error(
          CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH,
          62,
          5),
      error(StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 62, 5),
    ]);
  }

  test_fieldFormalParameterNotAssignableToField_extends() async {
    // According to checked-mode type checking rules, a value of type A is not
    // assignable to a field of type B, because B extends A (the subtyping
    // relationship is in the wrong direction).
    await assertErrorsInCode(r'''
class A {
  const A();
}
class B extends A {
  const B();
}
class C {
  final B b;
  const C(this.b);
}
const A u = const A();
var v = const C(u);
''', [
      error(
          CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH,
          143,
          1),
    ]);
  }

  test_fieldFormalParameterNotAssignableToField_fieldType() async {
    await assertErrorsInCode(r'''
class A {
  final int x;
  const A(this.x);
}
var v = const A('foo');
''', [
      error(
          CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH,
          62,
          5),
      error(StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 62, 5),
    ]);
  }

  test_fieldFormalParameterNotAssignableToField_fieldType_unresolved() async {
    await assertErrorsInCode(r'''
class A {
  final Unresolved x;
  const A(String this.x);
}
var v = const A('foo');
''', [
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 18, 10),
    ]);
  }

  test_fieldFormalParameterNotAssignableToField_implements() async {
    // According to checked-mode type checking rules, a value of type A is not
    // assignable to a field of type B, because B implements A (the subtyping
    // relationship is in the wrong direction).
    await assertErrorsInCode(r'''
class A {
  const A();
}
class B implements A {}
class C {
  final B b;
  const C(this.b);
}
const A u = const A();
var v = const C(u);
''', [
      error(
          CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH,
          132,
          1),
    ]);
  }

  test_fieldFormalParameterNotAssignableToField_list() async {
    // <num>[1, 2, 3] has type List<num>, which is not a subtype of List<int>.
    await assertErrorsInCode(r'''
class A {
  const A(List<int> x);
}
const dynamic w = const <num>[1, 2, 3];
var x = const A(w);
''', [
      error(
          CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH,
          92,
          1),
    ]);
  }

  test_fieldFormalParameterNotAssignableToField_map_keyMismatch() async {
    // <num, int>{1: 2} has type Map<num, int>, which is not a subtype of
    // Map<int, int>.
    await assertErrorsInCode(r'''
class A {
  const A(Map<int, int> x);
}
const dynamic w = const <num, int>{1: 2};
var x = const A(w);
''', [
      error(
          CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH,
          98,
          1),
    ]);
  }

  test_fieldFormalParameterNotAssignableToField_map_valueMismatch() async {
    // <int, num>{1: 2} has type Map<int, num>, which is not a subtype of
    // Map<int, int>.
    await assertErrorsInCode(r'''
class A {
  const A(Map<int, int> x);
}
const dynamic w = const <int, num>{1: 2};
var x = const A(w);
''', [
      error(
          CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH,
          98,
          1),
    ]);
  }

  test_fieldFormalParameterNotAssignableToField_optional() async {
    await assertErrorsInCode(r'''
class A {
  final int x;
  const A([this.x = 'foo']);
}
var v = const A();
''', [
      error(StaticTypeWarningCode.INVALID_ASSIGNMENT, 45, 5),
      error(
          CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH,
          64,
          9),
    ]);
  }

  test_fieldFormalParameterNotAssignableToField_typedef() async {
    // foo has the runtime type String -> int, so it should not be assignable
    // to A.f (A.f requires it to be int -> String).
    await assertErrorsInCode(r'''
typedef String Int2String(int x);
class A {
  final Int2String f;
  const A(this.f);
}
int foo(String x) => 1;
var v = const A(foo);
''', [
      error(StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 127, 3),
      error(
          CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH,
          127,
          3),
    ]);
  }

  test_fieldInitializerNotAssignable() async {
    await assertErrorsInCode(r'''
class A {
  final int x;
  const A() : x = '';
}
''', [
      error(StaticWarningCode.FIELD_INITIALIZER_NOT_ASSIGNABLE, 43, 2),
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
        error(StaticTypeWarningCode.INVALID_ASSIGNMENT, 27, 1),
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
        error(StaticTypeWarningCode.INVALID_ASSIGNMENT, 27, 1),
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
      error(StaticWarningCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 24, 2),
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
      error(
          CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH,
          46,
          5),
      error(StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 46, 5),
    ]);
  }

  test_parameterNotAssignable_typeSubstitution() async {
    await assertErrorsInCode(r'''
class A<T> {
  const A(T x);
}
var v = const A<int>('foo');
''', [
      error(StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 52, 5),
      error(
          CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH,
          52,
          5),
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
      error(StaticTypeWarningCode.INVALID_ASSIGNMENT, 14, 5),
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
