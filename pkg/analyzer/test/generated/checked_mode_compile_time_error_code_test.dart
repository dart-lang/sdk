// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.generated.checked_mode_compile_time_error_code_test;

import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/source_io.dart';

import '../reflective_tests.dart';
import '../utils.dart';
import 'resolver_test_case.dart';

main() {
  initializeTestEnvironment();
  runReflectiveTests(CheckedModeCompileTimeErrorCodeTest);
}

@reflectiveTest
class CheckedModeCompileTimeErrorCodeTest extends ResolverTestCase {
  void test_fieldFormalParameterAssignableToField_extends() {
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
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_fieldFormalParameterAssignableToField_fieldType_unresolved_null() {
    // Null always passes runtime type checks, even when the type is
    // unresolved.
    Source source = addSource(r'''
class A {
  final Unresolved x;
  const A(String this.x);
}
var v = const A(null);''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [StaticWarningCode.UNDEFINED_CLASS]);
    verify([source]);
  }

  void test_fieldFormalParameterAssignableToField_implements() {
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
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_fieldFormalParameterAssignableToField_list_dynamic() {
    // [1, 2, 3] has type List<dynamic>, which is a subtype of List<int>.
    Source source = addSource(r'''
class A {
  const A(List<int> x);
}
var x = const A(const [1, 2, 3]);''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_fieldFormalParameterAssignableToField_list_nonDynamic() {
    // <int>[1, 2, 3] has type List<int>, which is a subtype of List<num>.
    Source source = addSource(r'''
class A {
  const A(List<num> x);
}
var x = const A(const <int>[1, 2, 3]);''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_fieldFormalParameterAssignableToField_map_dynamic() {
    // {1: 2} has type Map<dynamic, dynamic>, which is a subtype of
    // Map<int, int>.
    Source source = addSource(r'''
class A {
  const A(Map<int, int> x);
}
var x = const A(const {1: 2});''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_fieldFormalParameterAssignableToField_map_keyDifferent() {
    // <int, int>{1: 2} has type Map<int, int>, which is a subtype of
    // Map<num, int>.
    Source source = addSource(r'''
class A {
  const A(Map<num, int> x);
}
var x = const A(const <int, int>{1: 2});''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_fieldFormalParameterAssignableToField_map_valueDifferent() {
    // <int, int>{1: 2} has type Map<int, int>, which is a subtype of
    // Map<int, num>.
    Source source = addSource(r'''
class A {
  const A(Map<int, num> x);
}
var x = const A(const <int, int>{1: 2});''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_fieldFormalParameterAssignableToField_notype() {
    // If a field is declared without a type, then any value may be assigned to
    // it.
    Source source = addSource(r'''
class A {
  final x;
  const A(this.x);
}
var v = const A(5);''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_fieldFormalParameterAssignableToField_null() {
    // Null is assignable to anything.
    Source source = addSource(r'''
class A {
  final int x;
  const A(this.x);
}
var v = const A(null);''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_fieldFormalParameterAssignableToField_typedef() {
    // foo has the runtime type dynamic -> dynamic, so it should be assignable
    // to A.f.
    Source source = addSource(r'''
typedef String Int2String(int x);
class A {
  final Int2String f;
  const A(this.f);
}
foo(x) => 1;
var v = const A(foo);''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_fieldFormalParameterAssignableToField_typeSubstitution() {
    // foo has the runtime type dynamic -> dynamic, so it should be assignable
    // to A.f.
    Source source = addSource(r'''
class A<T> {
  final T x;
  const A(this.x);
}
var v = const A<int>(3);''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_fieldFormalParameterNotAssignableToField() {
    Source source = addSource(r'''
class A {
  final int x;
  const A(this.x);
}
var v = const A('foo');''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [
      CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH,
      StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE
    ]);
    verify([source]);
  }

  void test_fieldFormalParameterNotAssignableToField_extends() {
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
var v = const C(const A());''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [
      CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH
    ]);
    verify([source]);
  }

  void test_fieldFormalParameterNotAssignableToField_fieldType() {
    Source source = addSource(r'''
class A {
  final int x;
  const A(String this.x);
}
var v = const A('foo');''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [
      CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH,
      StaticWarningCode.FIELD_INITIALIZING_FORMAL_NOT_ASSIGNABLE
    ]);
    verify([source]);
  }

  void test_fieldFormalParameterNotAssignableToField_fieldType_unresolved() {
    Source source = addSource(r'''
class A {
  final Unresolved x;
  const A(String this.x);
}
var v = const A('foo');''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [
      CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH,
      StaticWarningCode.UNDEFINED_CLASS
    ]);
    verify([source]);
  }

  void test_fieldFormalParameterNotAssignableToField_implements() {
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
var v = const C(const A());''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [
      CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH
    ]);
    verify([source]);
  }

  void test_fieldFormalParameterNotAssignableToField_list() {
    // <num>[1, 2, 3] has type List<num>, which is not a subtype of List<int>.
    Source source = addSource(r'''
class A {
  const A(List<int> x);
}
var x = const A(const <num>[1, 2, 3]);''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [
      CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH
    ]);
    verify([source]);
  }

  void test_fieldFormalParameterNotAssignableToField_map_keyMismatch() {
    // <num, int>{1: 2} has type Map<num, int>, which is not a subtype of
    // Map<int, int>.
    Source source = addSource(r'''
class A {
  const A(Map<int, int> x);
}
var x = const A(const <num, int>{1: 2});''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [
      CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH
    ]);
    verify([source]);
  }

  void test_fieldFormalParameterNotAssignableToField_map_valueMismatch() {
    // <int, num>{1: 2} has type Map<int, num>, which is not a subtype of
    // Map<int, int>.
    Source source = addSource(r'''
class A {
  const A(Map<int, int> x);
}
var x = const A(const <int, num>{1: 2});''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [
      CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH
    ]);
    verify([source]);
  }

  void test_fieldFormalParameterNotAssignableToField_optional() {
    Source source = addSource(r'''
class A {
  final int x;
  const A([this.x = 'foo']);
}
var v = const A();''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [
      CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH,
      StaticTypeWarningCode.INVALID_ASSIGNMENT
    ]);
    verify([source]);
  }

  void test_fieldFormalParameterNotAssignableToField_typedef() {
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
    computeLibrarySourceErrors(source);
    assertErrors(source, [
      CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH,
      StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE
    ]);
    verify([source]);
  }

  void test_fieldInitializerNotAssignable() {
    Source source = addSource(r'''
class A {
  final int x;
  const A() : x = '';
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [
      CheckedModeCompileTimeErrorCode.CONST_FIELD_INITIALIZER_NOT_ASSIGNABLE,
      StaticWarningCode.FIELD_INITIALIZER_NOT_ASSIGNABLE
    ]);
    verify([source]);
  }

  void test_fieldTypeMismatch() {
    Source source = addSource(r'''
class A {
  const A(x) : y = x;
  final int y;
}
var v = const A('foo');''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [
      CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_FIELD_TYPE_MISMATCH
    ]);
    verify([source]);
  }

  void test_fieldTypeMismatch_generic() {
    Source source = addSource(r'''
class C<T> {
  final T x = y;
  const C();
}
const int y = 1;
var v = const C<String>();
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [
      CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_FIELD_TYPE_MISMATCH,
      StaticTypeWarningCode.INVALID_ASSIGNMENT
    ]);
    verify([source]);
  }

  void test_fieldTypeMismatch_unresolved() {
    Source source = addSource(r'''
class A {
  const A(x) : y = x;
  final Unresolved y;
}
var v = const A('foo');''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [
      CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_FIELD_TYPE_MISMATCH,
      StaticWarningCode.UNDEFINED_CLASS
    ]);
    verify([source]);
  }

  void test_fieldTypeOk_generic() {
    Source source = addSource(r'''
class C<T> {
  final T x = y;
  const C();
}
const int y = 1;
var v = const C<int>();
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [StaticTypeWarningCode.INVALID_ASSIGNMENT]);
    verify([source]);
  }

  void test_fieldTypeOk_null() {
    Source source = addSource(r'''
class A {
  const A(x) : y = x;
  final int y;
}
var v = const A(null);''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_fieldTypeOk_unresolved_null() {
    // Null always passes runtime type checks, even when the type is
    // unresolved.
    Source source = addSource(r'''
class A {
  const A(x) : y = x;
  final Unresolved y;
}
var v = const A(null);''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [StaticWarningCode.UNDEFINED_CLASS]);
    verify([source]);
  }

  void test_listElementTypeNotAssignable() {
    Source source = addSource("var v = const <String> [42];");
    computeLibrarySourceErrors(source);
    assertErrors(source, [
      CheckedModeCompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE,
      StaticWarningCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
    ]);
    verify([source]);
  }

  void test_mapKeyTypeNotAssignable() {
    Source source = addSource("var v = const <String, int > {1 : 2};");
    computeLibrarySourceErrors(source);
    assertErrors(source, [
      CheckedModeCompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE,
      StaticWarningCode.MAP_KEY_TYPE_NOT_ASSIGNABLE
    ]);
    verify([source]);
  }

  void test_mapValueTypeNotAssignable() {
    Source source = addSource("var v = const <String, String> {'a' : 2};");
    computeLibrarySourceErrors(source);
    assertErrors(source, [
      CheckedModeCompileTimeErrorCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE,
      StaticWarningCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE
    ]);
    verify([source]);
  }

  void test_parameterAssignable_null() {
    // Null is assignable to anything.
    Source source = addSource(r'''
class A {
  const A(int x);
}
var v = const A(null);''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_parameterAssignable_typeSubstitution() {
    Source source = addSource(r'''
class A<T> {
  const A(T x);
}
var v = const A<int>(3);''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_parameterAssignable_undefined_null() {
    // Null always passes runtime type checks, even when the type is
    // unresolved.
    Source source = addSource(r'''
class A {
  const A(Unresolved x);
}
var v = const A(null);''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [StaticWarningCode.UNDEFINED_CLASS]);
    verify([source]);
  }

  void test_parameterNotAssignable() {
    Source source = addSource(r'''
class A {
  const A(int x);
}
var v = const A('foo');''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [
      CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH,
      StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE
    ]);
    verify([source]);
  }

  void test_parameterNotAssignable_typeSubstitution() {
    Source source = addSource(r'''
class A<T> {
  const A(T x);
}
var v = const A<int>('foo');''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [
      CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH,
      StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE
    ]);
    verify([source]);
  }

  void test_parameterNotAssignable_undefined() {
    Source source = addSource(r'''
class A {
  const A(Unresolved x);
}
var v = const A('foo');''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [
      CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH,
      StaticWarningCode.UNDEFINED_CLASS
    ]);
    verify([source]);
  }

  void test_redirectingConstructor_paramTypeMismatch() {
    Source source = addSource(r'''
class A {
  const A.a1(x) : this.a2(x);
  const A.a2(String x);
}
var v = const A.a1(0);''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [
      CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH
    ]);
    verify([source]);
  }

  void test_topLevelVarAssignable_null() {
    Source source = addSource("const int x = null;");
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_topLevelVarAssignable_undefined_null() {
    // Null always passes runtime type checks, even when the type is
    // unresolved.
    Source source = addSource("const Unresolved x = null;");
    computeLibrarySourceErrors(source);
    assertErrors(source, [StaticWarningCode.UNDEFINED_CLASS]);
    verify([source]);
  }

  void test_topLevelVarNotAssignable() {
    Source source = addSource("const int x = 'foo';");
    computeLibrarySourceErrors(source);
    assertErrors(source, [
      CheckedModeCompileTimeErrorCode.VARIABLE_TYPE_MISMATCH,
      StaticTypeWarningCode.INVALID_ASSIGNMENT
    ]);
    verify([source]);
  }

  void test_topLevelVarNotAssignable_undefined() {
    Source source = addSource("const Unresolved x = 'foo';");
    computeLibrarySourceErrors(source);
    assertErrors(source, [
      CheckedModeCompileTimeErrorCode.VARIABLE_TYPE_MISMATCH,
      StaticWarningCode.UNDEFINED_CLASS
    ]);
    verify([source]);
  }
}
