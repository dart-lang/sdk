// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.generated.checked_mode_compile_time_error_code_test;

import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'resolver_test_case.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CheckedModeCompileTimeErrorCodeTest);
  });
}

@reflectiveTest
class CheckedModeCompileTimeErrorCodeTest extends ResolverTestCase {
  @override
  AnalysisOptions get defaultAnalysisOptions =>
      new AnalysisOptionsImpl()..strongMode = true;

  test_fieldFormalParameterAssignableToField_extends() async {
    // According to checked-mode type checking rules, a value of type B is
    // assignable to a field of type A, because B extends A (and hence is a
    // subtype of A).
    Source source = addSource(r'''
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
var v = const C(const B());''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_fieldFormalParameterAssignableToField_fieldType_unresolved_null() async {
    // Null always passes runtime type checks, even when the type is
    // unresolved.
    Source source = addSource(r'''
class A {
  final Unresolved x;
  const A(String this.x);
}
var v = const A(null);''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.UNDEFINED_CLASS]);
    verify([source]);
  }

  test_fieldFormalParameterAssignableToField_implements() async {
    // According to checked-mode type checking rules, a value of type B is
    // assignable to a field of type A, because B implements A (and hence is a
    // subtype of A).
    Source source = addSource(r'''
class A {}
class B implements A {
  const B();
}
class C {
  final A a;
  const C(this.a);
}
var v = const C(const B());''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_fieldFormalParameterAssignableToField_list_dynamic() async {
    // [1, 2, 3] has type List<dynamic>, which is a subtype of List<int>.
    Source source = addSource(r'''
class A {
  const A(List<int> x);
}
var x = const A(const [1, 2, 3]);''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_fieldFormalParameterAssignableToField_list_nonDynamic() async {
    // <int>[1, 2, 3] has type List<int>, which is a subtype of List<num>.
    Source source = addSource(r'''
class A {
  const A(List<num> x);
}
var x = const A(const <int>[1, 2, 3]);''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_fieldFormalParameterAssignableToField_map_dynamic() async {
    // {1: 2} has type Map<dynamic, dynamic>, which is a subtype of
    // Map<int, int>.
    Source source = addSource(r'''
class A {
  const A(Map<int, int> x);
}
var x = const A(const {1: 2});''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_fieldFormalParameterAssignableToField_map_keyDifferent() async {
    // <int, int>{1: 2} has type Map<int, int>, which is a subtype of
    // Map<num, int>.
    Source source = addSource(r'''
class A {
  const A(Map<num, int> x);
}
var x = const A(const <int, int>{1: 2});''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_fieldFormalParameterAssignableToField_map_valueDifferent() async {
    // <int, int>{1: 2} has type Map<int, int>, which is a subtype of
    // Map<int, num>.
    Source source = addSource(r'''
class A {
  const A(Map<int, num> x);
}
var x = const A(const <int, int>{1: 2});''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_fieldFormalParameterAssignableToField_notype() async {
    // If a field is declared without a type, then any value may be assigned to
    // it.
    Source source = addSource(r'''
class A {
  final x;
  const A(this.x);
}
var v = const A(5);''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_fieldFormalParameterAssignableToField_null() async {
    // Null is assignable to anything.
    Source source = addSource(r'''
class A {
  final int x;
  const A(this.x);
}
var v = const A(null);''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_fieldFormalParameterAssignableToField_typedef() async {
    // foo has the runtime type dynamic -> dynamic, so it is not assignable
    // to A.f.
    Source source = addSource(r'''
typedef String Int2String(int x);
class A {
  final Int2String f;
  const A(this.f);
}
foo(x) => 1;
var v = const A(foo);''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  test_fieldFormalParameterAssignableToField_typeSubstitution() async {
    // foo has the runtime type dynamic -> dynamic, so it should be assignable
    // to A.f.
    Source source = addSource(r'''
class A<T> {
  final T x;
  const A(this.x);
}
var v = const A<int>(3);''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_fieldFormalParameterNotAssignableToField() async {
    Source source = addSource(r'''
class A {
  final int x;
  const A(this.x);
}
var v = const A('foo');''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH,
      StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE
    ]);
    verify([source]);
  }

  test_fieldFormalParameterNotAssignableToField_extends() async {
    // According to checked-mode type checking rules, a value of type A is not
    // assignable to a field of type B, because B extends A (the subtyping
    // relationship is in the wrong direction).
    Source source = addSource(r'''
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
var v = const C(u);''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH
    ]);
    verify([source]);
  }

  test_fieldFormalParameterNotAssignableToField_fieldType() async {
    Source source = addSource(r'''
class A {
  final int x;
  const A(this.x);
}
var v = const A('foo');''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH,
      StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE
    ]);
    verify([source]);
  }

  test_fieldFormalParameterNotAssignableToField_fieldType_unresolved() async {
    Source source = addSource(r'''
class A {
  final Unresolved x;
  const A(String this.x);
}
var v = const A('foo');''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH,
      StaticWarningCode.UNDEFINED_CLASS
    ]);
    verify([source]);
  }

  test_fieldFormalParameterNotAssignableToField_implements() async {
    // According to checked-mode type checking rules, a value of type A is not
    // assignable to a field of type B, because B implements A (the subtyping
    // relationship is in the wrong direction).
    Source source = addSource(r'''
class A {
  const A();
}
class B implements A {}
class C {
  final B b;
  const C(this.b);
}
const A u = const A();
var v = const C(u);''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH
    ]);
    verify([source]);
  }

  test_fieldFormalParameterNotAssignableToField_list() async {
    // <num>[1, 2, 3] has type List<num>, which is not a subtype of List<int>.
    Source source = addSource(r'''
class A {
  const A(List<int> x);
}
const dynamic w = const <num>[1, 2, 3];
var x = const A(w);''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH
    ]);
    verify([source]);
  }

  test_fieldFormalParameterNotAssignableToField_map_keyMismatch() async {
    // <num, int>{1: 2} has type Map<num, int>, which is not a subtype of
    // Map<int, int>.
    Source source = addSource(r'''
class A {
  const A(Map<int, int> x);
}
const dynamic w = const <num, int>{1: 2};
var x = const A(w);''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH
    ]);
    verify([source]);
  }

  test_fieldFormalParameterNotAssignableToField_map_valueMismatch() async {
    // <int, num>{1: 2} has type Map<int, num>, which is not a subtype of
    // Map<int, int>.
    Source source = addSource(r'''
class A {
  const A(Map<int, int> x);
}
const dynamic w = const <int, num>{1: 2};
var x = const A(w);''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH
    ]);
    verify([source]);
  }

  test_fieldFormalParameterNotAssignableToField_optional() async {
    Source source = addSource(r'''
class A {
  final int x;
  const A([this.x = 'foo']);
}
var v = const A();''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH,
      StaticTypeWarningCode.INVALID_ASSIGNMENT
    ]);
    verify([source]);
  }

  test_fieldFormalParameterNotAssignableToField_typedef() async {
    // foo has the runtime type String -> int, so it should not be assignable
    // to A.f (A.f requires it to be int -> String).
    Source source = addSource(r'''
typedef String Int2String(int x);
class A {
  final Int2String f;
  const A(this.f);
}
int foo(String x) => 1;
var v = const A(foo);''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH,
      StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE
    ]);
    verify([source]);
  }

  test_fieldInitializerNotAssignable() async {
    Source source = addSource(r'''
class A {
  final int x;
  const A() : x = '';
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CheckedModeCompileTimeErrorCode.CONST_FIELD_INITIALIZER_NOT_ASSIGNABLE,
      StaticWarningCode.FIELD_INITIALIZER_NOT_ASSIGNABLE
    ]);
    verify([source]);
  }

  test_fieldTypeMismatch() async {
    Source source = addSource(r'''
class A {
  const A(x) : y = x;
  final int y;
}
var v = const A('foo');''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_FIELD_TYPE_MISMATCH
    ]);
    verify([source]);
  }

  test_fieldTypeMismatch_generic() async {
    Source source = addSource(r'''
class C<T> {
  final T x = y;
  const C();
}
const int y = 1;
var v = const C<String>();
''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_FIELD_TYPE_MISMATCH,
      StaticTypeWarningCode.INVALID_ASSIGNMENT
    ]);
    verify([source]);
  }

  test_fieldTypeMismatch_unresolved() async {
    Source source = addSource(r'''
class A {
  const A(x) : y = x;
  final Unresolved y;
}
var v = const A('foo');''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_FIELD_TYPE_MISMATCH,
      StaticWarningCode.UNDEFINED_CLASS
    ]);
    verify([source]);
  }

  test_fieldTypeOk_generic() async {
    Source source = addSource(r'''
class C<T> {
  final T x = y;
  const C();
}
const int y = 1;
var v = const C<int>();
''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticTypeWarningCode.INVALID_ASSIGNMENT]);
    verify([source]);
  }

  test_fieldTypeOk_null() async {
    Source source = addSource(r'''
class A {
  const A(x) : y = x;
  final int y;
}
var v = const A(null);''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_fieldTypeOk_unresolved_null() async {
    // Null always passes runtime type checks, even when the type is
    // unresolved.
    Source source = addSource(r'''
class A {
  const A(x) : y = x;
  final Unresolved y;
}
var v = const A(null);''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.UNDEFINED_CLASS]);
    verify([source]);
  }

  test_listElementTypeNotAssignable() async {
    Source source = addSource("var v = const <String> [42];");
    await computeAnalysisResult(source);
    assertErrors(source, [
      CheckedModeCompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE,
      StaticWarningCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
    ]);
    verify([source]);
  }

  test_mapKeyTypeNotAssignable() async {
    Source source = addSource("var v = const <String, int > {1 : 2};");
    await computeAnalysisResult(source);
    assertErrors(source, [
      CheckedModeCompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE,
      StaticWarningCode.MAP_KEY_TYPE_NOT_ASSIGNABLE
    ]);
    verify([source]);
  }

  test_mapValueTypeNotAssignable() async {
    Source source = addSource("var v = const <String, String> {'a' : 2};");
    await computeAnalysisResult(source);
    assertErrors(source, [
      CheckedModeCompileTimeErrorCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE,
      StaticWarningCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE
    ]);
    verify([source]);
  }

  test_parameterAssignable_null() async {
    // Null is assignable to anything.
    Source source = addSource(r'''
class A {
  const A(int x);
}
var v = const A(null);''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_parameterAssignable_typeSubstitution() async {
    Source source = addSource(r'''
class A<T> {
  const A(T x);
}
var v = const A<int>(3);''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_parameterAssignable_undefined_null() async {
    // Null always passes runtime type checks, even when the type is
    // unresolved.
    Source source = addSource(r'''
class A {
  const A(Unresolved x);
}
var v = const A(null);''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.UNDEFINED_CLASS]);
    verify([source]);
  }

  test_parameterNotAssignable() async {
    Source source = addSource(r'''
class A {
  const A(int x);
}
var v = const A('foo');''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH,
      StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE
    ]);
    verify([source]);
  }

  test_parameterNotAssignable_typeSubstitution() async {
    Source source = addSource(r'''
class A<T> {
  const A(T x);
}
var v = const A<int>('foo');''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH,
      StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE
    ]);
    verify([source]);
  }

  test_parameterNotAssignable_undefined() async {
    Source source = addSource(r'''
class A {
  const A(Unresolved x);
}
var v = const A('foo');''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH,
      StaticWarningCode.UNDEFINED_CLASS
    ]);
    verify([source]);
  }

  test_redirectingConstructor_paramTypeMismatch() async {
    Source source = addSource(r'''
class A {
  const A.a1(x) : this.a2(x);
  const A.a2(String x);
}
var v = const A.a1(0);''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CheckedModeCompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION]);
    verify([source]);
  }

  test_superConstructor_paramTypeMismatch() async {
    Source source = addSource(r'''
class C {
  final double d;
  const C(this.d);
}
class D extends C {
  const D(d) : super(d);
}
const f = const D(0);
''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CheckedModeCompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION]);
    verify([source]);
  }

  test_topLevelVarAssignable_null() async {
    Source source = addSource("const int x = null;");
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_topLevelVarAssignable_undefined_null() async {
    // Null always passes runtime type checks, even when the type is
    // unresolved.
    Source source = addSource("const Unresolved x = null;");
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.UNDEFINED_CLASS]);
    verify([source]);
  }

  test_topLevelVarNotAssignable() async {
    Source source = addSource("const int x = 'foo';");
    await computeAnalysisResult(source);
    assertErrors(source, [
      CheckedModeCompileTimeErrorCode.VARIABLE_TYPE_MISMATCH,
      StaticTypeWarningCode.INVALID_ASSIGNMENT
    ]);
    verify([source]);
  }

  test_topLevelVarNotAssignable_undefined() async {
    Source source = addSource("const Unresolved x = 'foo';");
    await computeAnalysisResult(source);
    assertErrors(source, [
      CheckedModeCompileTimeErrorCode.VARIABLE_TYPE_MISMATCH,
      StaticWarningCode.UNDEFINED_CLASS
    ]);
    verify([source]);
  }
}
