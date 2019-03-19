// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'resolver_test_case.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EqualValuesInConstSetTest);
    defineReflectiveTests(StaticWarningCodeTest);
  });
}

@reflectiveTest
class EqualValuesInConstSetTest extends ResolverTestCase {
  @override
  bool get enableNewAnalysisDriver => true;

  test_simpleValues() async {
    Source source = addSource('var s = const {0, 1, 0};');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.EQUAL_VALUES_IN_CONST_SET]);
    verify([source]);
  }

  test_valuesWithEqualTypeParams() async {
    Source source = addSource(r'''
class A<T> {
  const A();
}
var s = const {A<int>(), A<int>()};
''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.EQUAL_VALUES_IN_CONST_SET]);
    verify([source]);
  }

  test_valuesWithUnequalTypeParams() async {
    // No error should be produced because A<int> and A<num> are different
    // types.
    Source source = addSource(r'''
class A<T> {
  const A();
}
const s = {A<int>(), A<num>()};
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }
}

@reflectiveTest
class StaticWarningCodeTest extends ResolverTestCase {
  @override
  bool get enableNewAnalysisDriver => true;

  test_ambiguousImport_as() async {
    Source source = addSource(r'''
import 'lib1.dart';
import 'lib2.dart';
f(p) {p as N;}''');
    addNamedSource("/lib1.dart", r'''
library lib1;
class N {}''');
    addNamedSource("/lib2.dart", r'''
library lib2;
class N {}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.AMBIGUOUS_IMPORT]);
  }

  test_ambiguousImport_dart() async {
    Source source = addSource(r'''
import 'dart:async';
import 'dart:async2';

Future v;
''');
    await computeAnalysisResult(source);
    if (enableNewAnalysisDriver) {
      assertErrors(source, [StaticWarningCode.AMBIGUOUS_IMPORT]);
    }
  }

  test_ambiguousImport_extends() async {
    Source source = addSource(r'''
import 'lib1.dart';
import 'lib2.dart';
class A extends N {}''');
    addNamedSource("/lib1.dart", r'''
library lib1;
class N {}''');
    addNamedSource("/lib2.dart", r'''
library lib2;
class N {}''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      StaticWarningCode.AMBIGUOUS_IMPORT,
      CompileTimeErrorCode.EXTENDS_NON_CLASS
    ]);
  }

  test_ambiguousImport_implements() async {
    Source source = addSource(r'''
import 'lib1.dart';
import 'lib2.dart';
class A implements N {}''');
    addNamedSource("/lib1.dart", r'''
library lib1;
class N {}''');
    addNamedSource("/lib2.dart", r'''
library lib2;
class N {}''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      StaticWarningCode.AMBIGUOUS_IMPORT,
      CompileTimeErrorCode.IMPLEMENTS_NON_CLASS
    ]);
  }

  test_ambiguousImport_inPart() async {
    Source source = addSource(r'''
library lib;
import 'lib1.dart';
import 'lib2.dart';
part 'part.dart';''');
    addNamedSource("/lib1.dart", r'''
library lib1;
class N {}''');
    addNamedSource("/lib2.dart", r'''
library lib2;
class N {}''');
    Source partSource = addNamedSource("/part.dart", r'''
part of lib;
class A extends N {}''');
    await computeAnalysisResult(source);
    await computeAnalysisResult(partSource);
    assertNoErrors(source);
    assertErrors(partSource, [
      StaticWarningCode.AMBIGUOUS_IMPORT,
      CompileTimeErrorCode.EXTENDS_NON_CLASS
    ]);
  }

  test_ambiguousImport_instanceCreation() async {
    Source source = addSource(r'''
library L;
import 'lib1.dart';
import 'lib2.dart';
f() {new N();}''');
    addNamedSource("/lib1.dart", r'''
library lib1;
class N {}''');
    addNamedSource("/lib2.dart", r'''
library lib2;
class N {}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.AMBIGUOUS_IMPORT]);
  }

  test_ambiguousImport_is() async {
    Source source = addSource(r'''
import 'lib1.dart';
import 'lib2.dart';
f(p) {p is N;}''');
    addNamedSource("/lib1.dart", r'''
library lib1;
class N {}''');
    addNamedSource("/lib2.dart", r'''
library lib2;
class N {}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.AMBIGUOUS_IMPORT]);
  }

  test_ambiguousImport_qualifier() async {
    Source source = addSource(r'''
import 'lib1.dart';
import 'lib2.dart';
g() { N.FOO; }''');
    addNamedSource("/lib1.dart", r'''
library lib1;
class N {}''');
    addNamedSource("/lib2.dart", r'''
library lib2;
class N {}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.AMBIGUOUS_IMPORT]);
  }

  test_ambiguousImport_typeAnnotation() async {
    Source source = addSource(r'''
import 'lib1.dart';
import 'lib2.dart';
typedef N FT(N p);
N f(N p) {
  N v;
  return null;
}
class A {
  N m() { return null; }
}
class B<T extends N> {}''');
    addNamedSource("/lib1.dart", r'''
library lib1;
class N {}''');
    addNamedSource("/lib2.dart", r'''
library lib2;
class N {}''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      StaticWarningCode.AMBIGUOUS_IMPORT,
      StaticWarningCode.AMBIGUOUS_IMPORT,
      StaticWarningCode.AMBIGUOUS_IMPORT,
      StaticWarningCode.AMBIGUOUS_IMPORT,
      StaticWarningCode.AMBIGUOUS_IMPORT,
      StaticWarningCode.AMBIGUOUS_IMPORT,
      StaticWarningCode.AMBIGUOUS_IMPORT
    ]);
  }

  test_ambiguousImport_typeArgument_annotation() async {
    Source source = addSource(r'''
import 'lib1.dart';
import 'lib2.dart';
class A<T> {}
A<N> f() { return null; }''');
    addNamedSource("/lib1.dart", r'''
library lib1;
class N {}''');
    addNamedSource("/lib2.dart", r'''
library lib2;
class N {}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.AMBIGUOUS_IMPORT]);
  }

  test_ambiguousImport_typeArgument_instanceCreation() async {
    Source source = addSource(r'''
import 'lib1.dart';
import 'lib2.dart';
class A<T> {}
f() {new A<N>();}''');
    addNamedSource("/lib1.dart", r'''
library lib1;
class N {}''');
    addNamedSource("/lib2.dart", r'''
library lib2;
class N {}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.AMBIGUOUS_IMPORT]);
  }

  test_ambiguousImport_varRead() async {
    Source source = addSource(r'''
import 'lib1.dart';
import 'lib2.dart';
f() { g(v); }
g(p) {}''');
    addNamedSource("/lib1.dart", r'''
library lib1;
var v;''');
    addNamedSource("/lib2.dart", r'''
library lib2;
var v;''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.AMBIGUOUS_IMPORT]);
  }

  test_ambiguousImport_varWrite() async {
    Source source = addSource(r'''
import 'lib1.dart';
import 'lib2.dart';
f() { v = 0; }''');
    addNamedSource("/lib1.dart", r'''
library lib1;
var v;''');
    addNamedSource("/lib2.dart", r'''
library lib2;
var v;''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.AMBIGUOUS_IMPORT]);
  }

  test_argumentTypeNotAssignable_ambiguousClassName() async {
    // See dartbug.com/19624
    Source source = addNamedSource("/lib1.dart", r'''
library lib1;
import 'lib2.dart';
class _A {}
f() {
  g((_A a) {});
}''');
    addNamedSource("/lib2.dart", r'''
library lib2;
class _A {}
g(h(_A a)) {}''');
    // The name _A is private to the library it's defined in, so this is a type
    // mismatch. Furthermore, the error message should mention both _A and the
    // filenames so the user can figure out what's going on.
    TestAnalysisResult analysisResult = await computeAnalysisResult(source);
    List<AnalysisError> errors = analysisResult.errors;
    expect(errors, hasLength(1));
    AnalysisError error = errors[0];
    expect(StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, error.errorCode);
    String message = error.message;
    expect(message.indexOf("_A") != -1, isTrue);
  }

  test_argumentTypeNotAssignable_annotation_namedConstructor() async {
    Source source = addSource(r'''
class A {
  const A.fromInt(int p);
}
@A.fromInt('0')
main() {
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  test_argumentTypeNotAssignable_annotation_unnamedConstructor() async {
    Source source = addSource(r'''
class A {
  const A(int p);
}
@A('0')
main() {
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  test_argumentTypeNotAssignable_binary() async {
    Source source = addSource(r'''
class A {
  operator +(int p) {}
}
f(A a) {
  a + '0';
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  test_argumentTypeNotAssignable_call() async {
    Source source = addSource(r'''
typedef bool Predicate<T>(T object);

Predicate<String> f() => null;

void main() {
  f().call(3);
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
  }

  test_argumentTypeNotAssignable_cascadeSecond() async {
    Source source = addSource(r'''
// filler filler filler filler filler filler filler filler filler filler
class A {
  B ma() { return new B(); }
}
class B {
  mb(String p) {}
}

main() {
  A a = new A();
  a..  ma().mb(0);
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  test_argumentTypeNotAssignable_const() async {
    Source source = addSource(r'''
class A {
  const A(String p);
}
main() {
  const A(42);
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE,
      CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH
    ]);
    verify([source]);
  }

  test_argumentTypeNotAssignable_const_super() async {
    Source source = addSource(r'''
class A {
  const A(String p);
}
class B extends A {
  const B() : super(42);
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  test_argumentTypeNotAssignable_functionExpressionInvocation_required() async {
    Source source = addSource(r'''
main() {
  (int x) {} ('');
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  test_argumentTypeNotAssignable_index() async {
    Source source = addSource(r'''
class A {
  operator [](int index) {}
}
f(A a) {
  a['0'];
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  test_argumentTypeNotAssignable_invocation_callParameter() async {
    Source source = addSource(r'''
class A {
  call(int p) {}
}
f(A a) {
  a('0');
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  test_argumentTypeNotAssignable_invocation_callVariable() async {
    Source source = addSource(r'''
class A {
  call(int p) {}
}
main() {
  A a = new A();
  a('0');
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  test_argumentTypeNotAssignable_invocation_functionParameter() async {
    Source source = addSource(r'''
a(b(int p)) {
  b('0');
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  test_argumentTypeNotAssignable_invocation_functionParameter_generic() async {
    Source source = addSource(r'''
class A<K, V> {
  m(f(K k), V v) {
    f(v);
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  test_argumentTypeNotAssignable_invocation_functionTypes_optional() async {
    Source source = addSource(r'''
void acceptFunNumOptBool(void funNumOptBool([bool b])) {}
void funNumBool(bool b) {}
main() {
  acceptFunNumOptBool(funNumBool);
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StrongModeCode.INVALID_CAST_FUNCTION]);
    verify([source]);
  }

  test_argumentTypeNotAssignable_invocation_generic() async {
    Source source = addSource(r'''
class A<T> {
  m(T t) {}
}
f(A<String> a) {
  a.m(1);
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  test_argumentTypeNotAssignable_invocation_named() async {
    Source source = addSource(r'''
f({String p}) {}
main() {
  f(p: 42);
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  test_argumentTypeNotAssignable_invocation_optional() async {
    Source source = addSource(r'''
f([String p]) {}
main() {
  f(42);
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  test_argumentTypeNotAssignable_invocation_required() async {
    Source source = addSource(r'''
f(String p) {}
main() {
  f(42);
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  test_argumentTypeNotAssignable_invocation_typedef_generic() async {
    Source source = addSource(r'''
typedef A<T>(T p);
f(A<int> a) {
  a('1');
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  test_argumentTypeNotAssignable_invocation_typedef_local() async {
    Source source = addSource(r'''
typedef A(int p);
A getA() => null;
main() {
  A a = getA();
  a('1');
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  test_argumentTypeNotAssignable_invocation_typedef_parameter() async {
    Source source = addSource(r'''
typedef A(int p);
f(A a) {
  a('1');
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  test_argumentTypeNotAssignable_new_generic() async {
    Source source = addSource(r'''
class A<T> {
  A(T p) {}
}
main() {
  new A<String>(42);
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  test_argumentTypeNotAssignable_new_optional() async {
    Source source = addSource(r'''
class A {
  A([String p]) {}
}
main() {
  new A(42);
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  test_argumentTypeNotAssignable_new_required() async {
    Source source = addSource(r'''
class A {
  A(String p) {}
}
main() {
  new A(42);
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  @failingTest
  test_argumentTypeNotAssignable_tearOff_required() async {
    Source source = addSource(r'''
class C {
  Object/*=T*/ f/*<T>*/(Object/*=T*/ x) => x;
}
g(C c) {
  var h = c.f/*<int>*/;
  print(h('s'));
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  test_assignmentToClass() async {
    Source source = addSource('''
class C {}
main() {
  C = null;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.ASSIGNMENT_TO_TYPE]);
  }

  test_assignmentToConst_instanceVariable() async {
    Source source = addSource(r'''
class A {
  static const v = 0;
}
f() {
  A.v = 1;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.ASSIGNMENT_TO_CONST]);
    verify([source]);
  }

  test_assignmentToConst_instanceVariable_plusEq() async {
    Source source = addSource(r'''
class A {
  static const v = 0;
}
f() {
  A.v += 1;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.ASSIGNMENT_TO_CONST]);
    verify([source]);
  }

  test_assignmentToConst_localVariable() async {
    Source source = addSource(r'''
f() {
  const x = 0;
  x = 1;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.ASSIGNMENT_TO_CONST]);
    verify([source]);
  }

  test_assignmentToConst_localVariable_plusEq() async {
    Source source = addSource(r'''
f() {
  const x = 0;
  x += 1;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.ASSIGNMENT_TO_CONST]);
    verify([source]);
  }

  test_assignmentToEnumType() async {
    Source source = addSource('''
enum E { e }
main() {
  E = null;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.ASSIGNMENT_TO_TYPE]);
  }

  test_assignmentToFinal_instanceVariable() async {
    Source source = addSource(r'''
class A {
  final v = 0;
}
f() {
  A a = new A();
  a.v = 1;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.ASSIGNMENT_TO_FINAL]);
    verify([source]);
  }

  test_assignmentToFinal_instanceVariable_plusEq() async {
    Source source = addSource(r'''
class A {
  final v = 0;
}
f() {
  A a = new A();
  a.v += 1;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.ASSIGNMENT_TO_FINAL]);
    verify([source]);
  }

  test_assignmentToFinalLocal_localVariable() async {
    Source source = addSource(r'''
f() {
  final x = 0;
  x = 1;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.ASSIGNMENT_TO_FINAL_LOCAL]);
    verify([source]);
  }

  test_assignmentToFinalLocal_localVariable_plusEq() async {
    Source source = addSource(r'''
f() {
  final x = 0;
  x += 1;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.ASSIGNMENT_TO_FINAL_LOCAL]);
    verify([source]);
  }

  test_assignmentToFinalLocal_parameter() async {
    Source source = addSource(r'''
f(final x) {
  x = 1;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.ASSIGNMENT_TO_FINAL_LOCAL]);
    verify([source]);
  }

  test_assignmentToFinalLocal_postfixMinusMinus() async {
    Source source = addSource(r'''
f() {
  final x = 0;
  x--;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.ASSIGNMENT_TO_FINAL_LOCAL]);
    verify([source]);
  }

  test_assignmentToFinalLocal_postfixPlusPlus() async {
    Source source = addSource(r'''
f() {
  final x = 0;
  x++;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.ASSIGNMENT_TO_FINAL_LOCAL]);
    verify([source]);
  }

  test_assignmentToFinalLocal_prefixMinusMinus() async {
    Source source = addSource(r'''
f() {
  final x = 0;
  --x;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.ASSIGNMENT_TO_FINAL_LOCAL]);
    verify([source]);
  }

  test_assignmentToFinalLocal_prefixPlusPlus() async {
    Source source = addSource(r'''
f() {
  final x = 0;
  ++x;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.ASSIGNMENT_TO_FINAL_LOCAL]);
    verify([source]);
  }

  test_assignmentToFinalLocal_suffixMinusMinus() async {
    Source source = addSource(r'''
f() {
  final x = 0;
  x--;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.ASSIGNMENT_TO_FINAL_LOCAL]);
    verify([source]);
  }

  test_assignmentToFinalLocal_suffixPlusPlus() async {
    Source source = addSource(r'''
f() {
  final x = 0;
  x++;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.ASSIGNMENT_TO_FINAL_LOCAL]);
    verify([source]);
  }

  test_assignmentToFinalLocal_topLevelVariable() async {
    Source source = addSource(r'''
final x = 0;
f() { x = 1; }''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.ASSIGNMENT_TO_FINAL_LOCAL]);
    verify([source]);
  }

  test_assignmentToFinalNoSetter_prefixedIdentifier() async {
    Source source = addSource(r'''
class A {
  int get x => 0;
}
main() {
  A a = new A();
  a.x = 0;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.ASSIGNMENT_TO_FINAL_NO_SETTER]);
    verify([source]);
  }

  test_assignmentToFinalNoSetter_propertyAccess() async {
    Source source = addSource(r'''
class A {
  int get x => 0;
}
class B {
  static A a;
}
main() {
  B.a.x = 0;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.ASSIGNMENT_TO_FINAL_NO_SETTER]);
    verify([source]);
  }

  test_assignmentToFunction() async {
    Source source = addSource(r'''
f() {}
main() {
  f = null;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.ASSIGNMENT_TO_FUNCTION]);
    verify([source]);
  }

  test_assignmentToMethod() async {
    Source source = addSource(r'''
class A {
  m() {}
}
f(A a) {
  a.m = () {};
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.ASSIGNMENT_TO_METHOD]);
    verify([source]);
  }

  test_assignmentToTypedef() async {
    Source source = addSource('''
typedef void F();
main() {
  F = null;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.ASSIGNMENT_TO_TYPE]);
  }

  test_assignmentToTypeParameter() async {
    Source source = addSource('''
class C<T> {
  f() {
    T = null;
  }
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.ASSIGNMENT_TO_TYPE]);
  }

  test_caseBlockNotTerminated() async {
    Source source = addSource(r'''
f(int p) {
  switch (p) {
    case 0:
      f(p);
    case 1:
      break;
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.CASE_BLOCK_NOT_TERMINATED]);
    verify([source]);
  }

  test_castToNonType() async {
    Source source = addSource(r'''
var A = 0;
f(String s) { var x = s as A; }''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.CAST_TO_NON_TYPE]);
    verify([source]);
  }

  test_concreteClassWithAbstractMember() async {
    Source source = addSource(r'''
class A {
  m();
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [StaticWarningCode.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER]);
    verify([source]);
  }

  test_concreteClassWithAbstractMember_noSuchMethod_interface() async {
    Source source = addSource(r'''
class I {
  noSuchMethod(v) => '';
}
class A implements I {
  m();
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [StaticWarningCode.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER]);
    verify([source]);
  }

  test_constWithAbstractClass() async {
    Source source = addSource(r'''
abstract class A {
  const A();
}
void f() {
  A a = const A();
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.CONST_WITH_ABSTRACT_CLASS]);
    verify([source]);
  }

  test_constWithAbstractClass_generic() async {
    Source source = addSource(r'''
abstract class A<E> {
  const A();
}
void f() {
  var a = const A<int>();
}''');
    TestAnalysisResult result = await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.CONST_WITH_ABSTRACT_CLASS]);
    verify([source]);

    ClassDeclaration classA = result.unit.declarations[0];
    FunctionDeclaration f = result.unit.declarations[1];
    BlockFunctionBody body = f.functionExpression.body;
    VariableDeclarationStatement a = body.block.statements[0];
    InstanceCreationExpression init = a.variables.variables[0].initializer;
    expect(init.staticType,
        classA.declaredElement.type.instantiate([typeProvider.intType]));
  }

  test_equalKeysInMap() async {
    Source source = addSource("var m = {'a' : 0, 'b' : 1, 'a' : 2};");
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.EQUAL_KEYS_IN_MAP]);
    verify([source]);
  }

  test_equalKeysInMap_withEqualTypeParams() async {
    Source source = addSource(r'''
class A<T> {
  const A();
}
var m = {const A<int>(): 0, const A<int>(): 1};''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.EQUAL_KEYS_IN_MAP]);
    verify([source]);
  }

  test_equalKeysInMap_withUnequalTypeParams() async {
    // No error should be produced because A<int> and A<num> are different
    // types.
    Source source = addSource(r'''
class A<T> {
  const A();
}
var m = {const A<int>(): 0, const A<num>(): 1};''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_exportDuplicatedLibraryNamed() async {
    Source source = addSource(r'''
library test;
export 'lib1.dart';
export 'lib2.dart';''');
    addNamedSource("/lib1.dart", "library lib;");
    addNamedSource("/lib2.dart", "library lib;");
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.EXPORT_DUPLICATED_LIBRARY_NAMED]);
    verify([source]);
  }

  test_extraPositionalArguments() async {
    Source source = addSource(r'''
f() {}
main() {
  f(0, 1, '2');
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.EXTRA_POSITIONAL_ARGUMENTS]);
    verify([source]);
  }

  test_extraPositionalArguments_functionExpression() async {
    Source source = addSource(r'''
main() {
  (int x) {} (0, 1);
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.EXTRA_POSITIONAL_ARGUMENTS]);
    verify([source]);
  }

  test_extraPositionalArgumentsCouldBeNamed() async {
    Source source = addSource(r'''
f({x, y}) {}
main() {
  f(0, 1, '2');
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [StaticWarningCode.EXTRA_POSITIONAL_ARGUMENTS_COULD_BE_NAMED]);
    verify([source]);
  }

  test_extraPositionalArgumentsCouldBeNamed_functionExpression() async {
    Source source = addSource(r'''
main() {
  (int x, {int y}) {} (0, 1);
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [StaticWarningCode.EXTRA_POSITIONAL_ARGUMENTS_COULD_BE_NAMED]);
    verify([source]);
  }

  test_fieldInitializedInInitializerAndDeclaration_final() async {
    Source source = addSource(r'''
class A {
  final int x = 0;
  A() : x = 1 {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [StaticWarningCode.FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION]);
    verify([source]);
  }

  test_fieldInitializerNotAssignable() async {
    Source source = addSource(r'''
class A {
  int x;
  A() : x = '';
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.FIELD_INITIALIZER_NOT_ASSIGNABLE]);
    verify([source]);
  }

  test_fieldInitializingFormalNotAssignable() async {
    Source source = addSource(r'''
class A {
  int x;
  A(String this.x) {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      StaticWarningCode.FIELD_INITIALIZING_FORMAL_NOT_ASSIGNABLE,
      StrongModeCode.INVALID_PARAMETER_DECLARATION
    ]);
    verify([source]);
  }

  /**
   * This test doesn't test the FINAL_INITIALIZED_IN_DECLARATION_AND_CONSTRUCTOR code, but tests the
   * FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION code instead. It is provided here to show
   * coverage over all of the permutations of initializers in constructor declarations.
   *
   * Note: FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION covers a subset of
   * FINAL_INITIALIZED_IN_DECLARATION_AND_CONSTRUCTOR, since it more specific, we use it instead of
   * the broader code
   */
  test_finalInitializedInDeclarationAndConstructor_initializers() async {
    Source source = addSource(r'''
class A {
  final x = 0;
  A() : x = 0 {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [StaticWarningCode.FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION]);
    verify([source]);
  }

  test_finalInitializedInDeclarationAndConstructor_initializingFormal() async {
    Source source = addSource(r'''
class A {
  final x = 0;
  A(this.x) {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [StaticWarningCode.FINAL_INITIALIZED_IN_DECLARATION_AND_CONSTRUCTOR]);
    verify([source]);
  }

  test_finalNotInitialized_inConstructor_1() async {
    Source source = addSource(r'''
class A {
  final int x;
  A() {}
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [StaticWarningCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_1]);
    verify([source]);
  }

  test_finalNotInitialized_inConstructor_2() async {
    Source source = addSource(r'''
class A {
  final int a;
  final int b;
  A() {}
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [StaticWarningCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_2]);
    verify([source]);
  }

  test_finalNotInitialized_inConstructor_3() async {
    Source source = addSource(r'''
class A {
  final int a;
  final int b;
  final int c;
  A() {}
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [StaticWarningCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_3_PLUS]);
    verify([source]);
  }

  test_finalNotInitialized_instanceField_final() async {
    Source source = addSource(r'''
class A {
  final F;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.FINAL_NOT_INITIALIZED]);
    verify([source]);
  }

  test_finalNotInitialized_instanceField_final_static() async {
    Source source = addSource(r'''
class A {
  static final F;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.FINAL_NOT_INITIALIZED]);
    verify([source]);
  }

  test_finalNotInitialized_library_final() async {
    Source source = addSource("final F;");
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.FINAL_NOT_INITIALIZED]);
    verify([source]);
  }

  test_finalNotInitialized_local_final() async {
    Source source = addSource(r'''
f() {
  final int x;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.FINAL_NOT_INITIALIZED]);
    verify([source]);
  }

  test_functionWithoutCall_direct() async {
    Source source = addSource(r'''
class A implements Function {
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_functionWithoutCall_direct_typeAlias() async {
    Source source = addSource(r'''
class M {}
class A = Object with M implements Function;''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_functionWithoutCall_indirect_extends() async {
    Source source = addSource(r'''
abstract class A implements Function {
}
class B extends A {
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_functionWithoutCall_indirect_extends_typeAlias() async {
    Source source = addSource(r'''
abstract class A implements Function {}
class M {}
class B = A with M;''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_functionWithoutCall_indirect_implements() async {
    Source source = addSource(r'''
abstract class A implements Function {
}
class B implements A {
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_functionWithoutCall_indirect_implements_typeAlias() async {
    Source source = addSource(r'''
abstract class A implements Function {}
class M {}
class B = Object with M implements A;''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_functionWithoutCall_mixin_implements() async {
    Source source = addSource(r'''
abstract class A implements Function {}
class B extends Object with A {}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_functionWithoutCall_mixin_implements_typeAlias() async {
    Source source = addSource(r'''
abstract class A implements Function {}
class B = Object with A;''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_generalizedVoid_andVoidLhsError() async {
    Source source = addSource(r'''
void main() {
  void x;
  x && true;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.USE_OF_VOID_RESULT]);
  }

  test_generalizedVoid_andVoidRhsError() async {
    Source source = addSource(r'''
void main() {
  void x;
  true && x;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.USE_OF_VOID_RESULT]);
  }

  test_generalizedVoid_assignmentToVoidParameterOk() async {
    // Note: the spec may decide to disallow this, but at this point that seems
    // highly unlikely.
    Source source = addSource(r'''
void main() {
  void x;
  f(x);
}
void f(void x) {}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_generalizedVoid_assignToVoid_notStrong_error() async {
    // See StrongModeStaticTypeAnalyzer2Test.test_generalizedVoid_assignToVoidOk
    // for testing that this does not have errors in strong mode.
    Source source = addSource(r'''
void main() {
  void x;
  x = 42;
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_generalizedVoid_interpolateVoidValueError() async {
    Source source = addSource(r'''
void main() {
  void x;
  "$x";
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.USE_OF_VOID_RESULT]);
  }

  test_generalizedVoid_negateVoidValueError() async {
    Source source = addSource(r'''
void main() {
  void x;
  !x;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.USE_OF_VOID_RESULT]);
  }

  test_generalizedVoid_orVoidLhsError() async {
    Source source = addSource(r'''
void main() {
  void x;
  x || true;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.USE_OF_VOID_RESULT]);
  }

  test_generalizedVoid_orVoidRhsError() async {
    Source source = addSource(r'''
void main() {
  void x;
  false || x;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.USE_OF_VOID_RESULT]);
  }

  test_generalizedVoid_throwVoidValueError() async {
    Source source = addSource(r'''
void main() {
  void x;
  throw x;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.USE_OF_VOID_RESULT]);
  }

  test_generalizedVoid_unaryNegativeVoidValueError() async {
    Source source = addSource(r'''
void main() {
  void x;
  -x;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      StaticWarningCode.USE_OF_VOID_RESULT,
      // TODO(mfairhurst) suppress UNDEFINED_OPERATOR
      StaticTypeWarningCode.UNDEFINED_OPERATOR
    ]);
  }

  test_generalizedVoid_useOfInForeachIterableError() async {
    Source source = addSource(r'''
void main() {
  void x;
  for (var v in x) {}
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.USE_OF_VOID_RESULT]);
  }

  test_generalizedVoid_useOfVoidAsIndexAssignError() async {
    Source source = addSource(r'''
void main(List list) {
  void x;
  list[x] = null;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.USE_OF_VOID_RESULT]);
  }

  test_generalizedVoid_useOfVoidAsIndexError() async {
    Source source = addSource(r'''
void main(List list) {
  void x;
  list[x];
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.USE_OF_VOID_RESULT]);
  }

  test_generalizedVoid_useOfVoidAssignedToDynamicError() async {
    Source source = addSource(r'''
void main() {
  void x;
  dynamic z = x;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.USE_OF_VOID_RESULT]);
  }

  test_generalizedVoid_useOfVoidByIndexingError() async {
    Source source = addSource(r'''
void main() {
  void x;
  x[0];
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.USE_OF_VOID_RESULT]);
  }

  test_generalizedVoid_useOfVoidCallSetterError() async {
    Source source = addSource(r'''
void main() {
  void x;
  x.foo = null;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.USE_OF_VOID_RESULT]);
  }

  test_generalizedVoid_useOfVoidCastsOk() async {
    Source source = addSource(r'''
void use(dynamic x) { }
void main() {
  void x;
  use(x as int);
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_generalizedVoid_useOfVoidInConditionalConditionError() async {
    Source source = addSource(r'''
void main() {
  void x;
  x ? null : null;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.USE_OF_VOID_RESULT]);
  }

  @failingTest
  test_generalizedVoid_useOfVoidInConditionalLhsError() async {
    // TODO(mfairhurst) Enable this.
    Source source = addSource(r'''
void main(bool c) {
  void x;
  c ? x : null;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.USE_OF_VOID_RESULT]);
  }

  @failingTest
  test_generalizedVoid_useOfVoidInConditionalRhsError() async {
    // TODO(mfairhurst) Enable this.
    Source source = addSource(r'''
void main(bool c) {
  void x;
  c ? null : x;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.USE_OF_VOID_RESULT]);
  }

  test_generalizedVoid_useOfVoidInDoWhileConditionError() async {
    Source source = addSource(r'''
void main() {
  void x;
  do {} while (x);
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.USE_OF_VOID_RESULT]);
  }

  test_generalizedVoid_useOfVoidInExpStmtOk() async {
    Source source = addSource(r'''
void main() {
  void x;
  x;
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  @failingTest // This test may be completely invalid.
  test_generalizedVoid_useOfVoidInForeachVariableError() async {
    Source source = addSource(r'''
void main() {
  void x;
  for (x in [1, 2]) {}
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.USE_OF_VOID_RESULT]);
  }

  test_generalizedVoid_useOfVoidInForPartsOk() async {
    Source source = addSource(r'''
void main() {
  void x;
  for (x; false; x) {}
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_generalizedVoid_useOfVoidInIsTestError() async {
    Source source = addSource(r'''
void main() {
  void x;
  x is int;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.USE_OF_VOID_RESULT]);
  }

  test_generalizedVoid_useOfVoidInListLiteralError() async {
    Source source = addSource(r'''
void main() {
  void x;
  <dynamic>[x];
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.USE_OF_VOID_RESULT]);
  }

  test_generalizedVoid_useOfVoidInListLiteralOk() async {
    Source source = addSource(r'''
void main() {
  void x;
  <void>[x]; // not strong mode; we have to specify <void>.
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_generalizedVoid_useOfVoidInMapLiteralKeyError() async {
    Source source = addSource(r'''
void main() {
  void x;
  var m2 = <dynamic, int>{x : 4};
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.USE_OF_VOID_RESULT]);
  }

  test_generalizedVoid_useOfVoidInMapLiteralKeyOk() async {
    Source source = addSource(r'''
void main() {
  void x;
  var m2 = <void, int>{x : 4}; // not strong mode; we have to specify <void>.
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_generalizedVoid_useOfVoidInMapLiteralValueError() async {
    Source source = addSource(r'''
void main() {
  void x;
  var m1 = <int, dynamic>{4: x};
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.USE_OF_VOID_RESULT]);
  }

  test_generalizedVoid_useOfVoidInMapLiteralValueOk() async {
    Source source = addSource(r'''
void main() {
  void x;
  var m1 = <int, void>{4: x}; // not strong mode; we have to specify <void>.
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_generalizedVoid_useOfVoidInNullOperatorLhsError() async {
    Source source = addSource(r'''
void main() {
  void x;
  x ?? 499;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.USE_OF_VOID_RESULT]);
  }

  test_generalizedVoid_useOfVoidInNullOperatorRhsOk() async {
    Source source = addSource(r'''
void main() {
  void x;
  null ?? x;
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_generalizedVoid_useOfVoidInSpecialAssignmentError() async {
    Source source = addSource(r'''
void main() {
  void x;
  x += 1;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.USE_OF_VOID_RESULT]);
  }

  test_generalizedVoid_useOfVoidInSwitchExpressionError() async {
    Source source = addSource(r'''
void main() {
  void x;
  switch(x) {}
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.USE_OF_VOID_RESULT]);
  }

  test_generalizedVoid_useOfVoidInWhileConditionError() async {
    Source source = addSource(r'''
void main() {
  void x;
  while (x) {};
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.USE_OF_VOID_RESULT]);
  }

  test_generalizedVoid_useOfVoidNullPropertyAccessError() async {
    Source source = addSource(r'''
void main() {
  void x;
  x?.foo;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.USE_OF_VOID_RESULT]);
  }

  test_generalizedVoid_useOfVoidPropertyAccessError() async {
    Source source = addSource(r'''
void main() {
  void x;
  x.foo;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.USE_OF_VOID_RESULT]);
  }

  @failingTest
  test_generalizedVoid_useOfVoidReturnInNonVoidFunctionError() async {
    // TODO(mfairhurst) Get this test to pass once codebase is compliant.
    Source source = addSource(r'''
dynamic main() {
  void x;
  return x;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticTypeWarningCode.RETURN_OF_INVALID_TYPE]);
  }

  test_generalizedVoid_useOfVoidReturnInVoidFunctionOk() async {
    Source source = addSource(r'''
void main() {
  void x;
  return x;
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_generalizedVoid_useOfVoidWhenArgumentError() async {
    Source source = addSource(r'''
void use(dynamic x) { }
void main() {
  void x;
  use(x);
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.USE_OF_VOID_RESULT]);
  }

  test_generalizedVoid_useOfVoidWithInitializerOk() async {
    Source source = addSource(r'''
void main() {
  void x;
  void y = x;
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_generalizedVoid_yieldStarVoid_asyncStar() async {
    Source source = addSource(r'''
main(void x) async* {
  yield* x;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.USE_OF_VOID_RESULT]);
  }

  test_generalizedVoid_yieldStarVoid_syncStar() async {
    Source source = addSource(r'''
main(void x) sync* {
  yield* x;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.USE_OF_VOID_RESULT]);
  }

  test_generalizedVoid_yieldVoid_asyncStar() async {
    Source source = addSource(r'''
main(void x) async* {
  yield x;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.USE_OF_VOID_RESULT]);
  }

  test_generalizedVoid_yieldVoid_syncStar() async {
    Source source = addSource(r'''
main(void x) sync* {
  yield x;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.USE_OF_VOID_RESULT]);
  }

  test_importDuplicatedLibraryNamed() async {
    Source source = addSource(r'''
library test;
import 'lib1.dart';
import 'lib2.dart';''');
    addNamedSource("/lib1.dart", "library lib;");
    addNamedSource("/lib2.dart", "library lib;");
    await computeAnalysisResult(source);
    assertErrors(source, [
      StaticWarningCode.IMPORT_DUPLICATED_LIBRARY_NAMED,
      HintCode.UNUSED_IMPORT,
      HintCode.UNUSED_IMPORT
    ]);
    verify([source]);
  }

  test_importOfNonLibrary() async {
    await resolveWithErrors(<String>[
      r'''
part of lib;
class A {}''',
      r'''
library lib;
import 'lib1.dart' deferred as p;
var a = new p.A();'''
    ], <ErrorCode>[
      StaticWarningCode.IMPORT_OF_NON_LIBRARY
    ]);
  }

  test_invalidGetterOverrideReturnType() async {
    Source source = addSource(r'''
class A {
  int get g { return 0; }
}
class B extends A {
  String get g { return 'a'; }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_OVERRIDE]);
    verify([source]);
  }

  test_invalidGetterOverrideReturnType_implicit() async {
    Source source = addSource(r'''
class A {
  String f;
}
class B extends A {
  int f;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.INVALID_OVERRIDE,
      CompileTimeErrorCode.INVALID_OVERRIDE
    ]);
    verify([source]);
  }

  test_invalidGetterOverrideReturnType_twoInterfaces() async {
    // test from language/override_inheritance_field_test_11.dart
    Source source = addSource(r'''
abstract class I {
  int get getter => null;
}
abstract class J {
  num get getter => null;
}
abstract class A implements I, J {}
class B extends A {
  String get getter => null;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.INVALID_OVERRIDE,
      CompileTimeErrorCode.INVALID_OVERRIDE,
    ]);
    verify([source]);
  }

  test_invalidGetterOverrideReturnType_twoInterfaces_conflicting() async {
    Source source = addSource(r'''
abstract class I<U> {
  U get g => null;
}
abstract class J<V> {
  V get g => null;
}
class B implements I<int>, J<String> {
  double get g => null;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.INVALID_OVERRIDE,
      CompileTimeErrorCode.INVALID_OVERRIDE
    ]);
    verify([source]);
  }

  test_invalidMethodOverrideNamedParamType() async {
    Source source = addSource(r'''
class A {
  m({int a}) {}
}
class B implements A {
  m({String a}) {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_OVERRIDE]);
    verify([source]);
  }

  test_invalidMethodOverrideNormalParamType_interface() async {
    Source source = addSource(r'''
class A {
  m(int a) {}
}
class B implements A {
  m(String a) {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_OVERRIDE]);
    verify([source]);
  }

  test_invalidMethodOverrideNormalParamType_superclass() async {
    Source source = addSource(r'''
class A {
  m(int a) {}
}
class B extends A {
  m(String a) {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_OVERRIDE]);
    verify([source]);
  }

  test_invalidMethodOverrideNormalParamType_superclass_interface() async {
    Source source = addSource(r'''
abstract class I<U> {
  m(U u) => null;
}
abstract class J<V> {
  m(V v) => null;
}
class B extends I<int> implements J<String> {
  m(double d) {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.INVALID_OVERRIDE,
      CompileTimeErrorCode.INVALID_OVERRIDE
    ]);
    verify([source]);
  }

  test_invalidMethodOverrideNormalParamType_twoInterfaces() async {
    Source source = addSource(r'''
abstract class I {
  m(int n);
}
abstract class J {
  m(num n);
}
abstract class A implements I, J {}
class B extends A {
  m(String n) {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.INVALID_OVERRIDE,
      CompileTimeErrorCode.INVALID_OVERRIDE
    ]);
    verify([source]);
  }

  test_invalidMethodOverrideNormalParamType_twoInterfaces_conflicting() async {
    // language/override_inheritance_generic_test/08
    Source source = addSource(r'''
abstract class I<U> {
  m(U u) => null;
}
abstract class J<V> {
  m(V v) => null;
}
class B implements I<int>, J<String> {
  m(double d) {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.INVALID_OVERRIDE,
      CompileTimeErrorCode.INVALID_OVERRIDE
    ]);
    verify([source]);
  }

  test_invalidMethodOverrideOptionalParamType() async {
    Source source = addSource(r'''
class A {
  m([int a]) {}
}
class B implements A {
  m([String a]) {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_OVERRIDE]);
    verify([source]);
  }

  test_invalidMethodOverrideOptionalParamType_twoInterfaces() async {
    Source source = addSource(r'''
abstract class I {
  m([int n]);
}
abstract class J {
  m([num n]);
}
abstract class A implements I, J {}
class B extends A {
  m([String n]) {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.INVALID_OVERRIDE,
      CompileTimeErrorCode.INVALID_OVERRIDE
    ]);
    verify([source]);
  }

  test_invalidMethodOverrideReturnType_interface() async {
    Source source = addSource(r'''
class A {
  int m() { return 0; }
}
class B implements A {
  String m() { return 'a'; }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_OVERRIDE]);
    verify([source]);
  }

  test_invalidMethodOverrideReturnType_interface_grandparent() async {
    Source source = addSource(r'''
abstract class A {
  int m();
}
abstract class B implements A {
}
class C implements B {
  String m() { return 'a'; }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_OVERRIDE]);
    verify([source]);
  }

  test_invalidMethodOverrideReturnType_mixin() async {
    Source source = addSource(r'''
class A {
  int m() { return 0; }
}
class B extends Object with A {
  String m() { return 'a'; }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_OVERRIDE]);
    verify([source]);
  }

  test_invalidMethodOverrideReturnType_superclass() async {
    Source source = addSource(r'''
class A {
  int m() { return 0; }
}
class B extends A {
  String m() { return 'a'; }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_OVERRIDE]);
    verify([source]);
  }

  test_invalidMethodOverrideReturnType_superclass_grandparent() async {
    Source source = addSource(r'''
class A {
  int m() { return 0; }
}
class B extends A {
}
class C extends B {
  String m() { return 'a'; }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_OVERRIDE]);
    verify([source]);
  }

  test_invalidMethodOverrideReturnType_twoInterfaces() async {
    Source source = addSource(r'''
abstract class I {
  int m();
}
abstract class J {
  num m();
}
abstract class A implements I, J {}
class B extends A {
  String m() => '';
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.INVALID_OVERRIDE,
      CompileTimeErrorCode.INVALID_OVERRIDE
    ]);
    verify([source]);
  }

  test_invalidMethodOverrideReturnType_void() async {
    Source source = addSource(r'''
class A {
  int m() { return 0; }
}
class B extends A {
  void m() {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_OVERRIDE]);
    verify([source]);
  }

  test_invalidOverrideNamed_fewerNamedParameters() async {
    Source source = addSource(r'''
class A {
  m({a, b}) {}
}
class B extends A {
  m({a}) {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_OVERRIDE]);
    verify([source]);
  }

  test_invalidOverrideNamed_missingNamedParameter() async {
    Source source = addSource(r'''
class A {
  m({a, b}) {}
}
class B extends A {
  m({a, c}) {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_OVERRIDE]);
    verify([source]);
  }

  test_invalidOverridePositional_optional() async {
    Source source = addSource(r'''
class A {
  m([a, b]) {}
}
class B extends A {
  m([a]) {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_OVERRIDE]);
    verify([source]);
  }

  test_invalidOverridePositional_optionalAndRequired() async {
    Source source = addSource(r'''
class A {
  m(a, b, [c, d]) {}
}
class B extends A {
  m(a, b, [c]) {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_OVERRIDE]);
    verify([source]);
  }

  test_invalidOverridePositional_optionalAndRequired2() async {
    Source source = addSource(r'''
class A {
  m(a, b, [c, d]) {}
}
class B extends A {
  m(a, [c, d]) {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_OVERRIDE]);
    verify([source]);
  }

  test_invalidOverrideRequired() async {
    Source source = addSource(r'''
class A {
  m(a) {}
}
class B extends A {
  m(a, b) {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_OVERRIDE]);
    verify([source]);
  }

  test_invalidSetterOverrideNormalParamType() async {
    Source source = addSource(r'''
class A {
  void set s(int v) {}
}
class B extends A {
  void set s(String v) {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_OVERRIDE]);
    verify([source]);
  }

  test_invalidSetterOverrideNormalParamType_superclass_interface() async {
    Source source = addSource(r'''
abstract class I {
  set setter14(int _) => null;
}
abstract class J {
  set setter14(num _) => null;
}
abstract class A extends I implements J {}
class B extends A {
  set setter14(String _) => null;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.INVALID_OVERRIDE,
      CompileTimeErrorCode.INVALID_OVERRIDE,
    ]);
    verify([source]);
  }

  test_invalidSetterOverrideNormalParamType_twoInterfaces() async {
    // test from language/override_inheritance_field_test_34.dart
    Source source = addSource(r'''
abstract class I {
  set setter14(int _) => null;
}
abstract class J {
  set setter14(num _) => null;
}
abstract class A implements I, J {}
class B extends A {
  set setter14(String _) => null;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.INVALID_OVERRIDE,
      CompileTimeErrorCode.INVALID_OVERRIDE
    ]);
    verify([source]);
  }

  test_invalidSetterOverrideNormalParamType_twoInterfaces_conflicting() async {
    Source source = addSource(r'''
abstract class I<U> {
  set s(U u) {}
}
abstract class J<V> {
  set s(V v) {}
}
class B implements I<int>, J<String> {
  set s(double d) {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.INVALID_OVERRIDE,
      CompileTimeErrorCode.INVALID_OVERRIDE
    ]);
    verify([source]);
  }

  test_mismatchedAccessorTypes_topLevel() async {
    Source source = addSource(r'''
int get g { return 0; }
set g(String v) {}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [StaticWarningCode.MISMATCHED_GETTER_AND_SETTER_TYPES]);
    verify([source]);
  }

  test_missingEnumConstantInSwitch() async {
    Source source = addSource(r'''
enum E { ONE, TWO, THREE, FOUR }
bool odd(E e) {
  switch (e) {
    case E.ONE:
    case E.THREE: return true;
  }
  return false;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      StaticWarningCode.MISSING_ENUM_CONSTANT_IN_SWITCH,
      StaticWarningCode.MISSING_ENUM_CONSTANT_IN_SWITCH
    ]);
    verify([source]);
  }

  test_mixedReturnTypes_localFunction() async {
    Source source = addSource(r'''
class C {
  m(int x) {
    return (int y) {
      if (y < 0) {
        return;
      }
      return 0;
    };
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.RETURN_WITHOUT_VALUE]);
    verify([source]);
  }

  test_mixedReturnTypes_method() async {
    Source source = addSource(r'''
class C {
  m(int x) {
    if (x < 0) {
      return;
    }
    return 0;
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      StaticWarningCode.MIXED_RETURN_TYPES,
      StaticWarningCode.MIXED_RETURN_TYPES
    ]);
    verify([source]);
  }

  test_mixedReturnTypes_topLevelFunction() async {
    Source source = addSource(r'''
f(int x) {
  if (x < 0) {
    return;
  }
  return 0;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      StaticWarningCode.MIXED_RETURN_TYPES,
      StaticWarningCode.MIXED_RETURN_TYPES
    ]);
    verify([source]);
  }

  test_newWithAbstractClass() async {
    Source source = addSource(r'''
abstract class A {}
void f() {
  A a = new A();
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.NEW_WITH_ABSTRACT_CLASS]);
    verify([source]);
  }

  test_newWithAbstractClass_generic() async {
    Source source = addSource(r'''
abstract class A<E> {}
void f() {
  var a = new A<int>();
}''');
    TestAnalysisResult result = await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.NEW_WITH_ABSTRACT_CLASS]);
    verify([source]);

    ClassDeclaration classA = result.unit.declarations[0];
    FunctionDeclaration f = result.unit.declarations[1];
    BlockFunctionBody body = f.functionExpression.body;
    VariableDeclarationStatement a = body.block.statements[0];
    InstanceCreationExpression init = a.variables.variables[0].initializer;
    expect(init.staticType,
        classA.declaredElement.type.instantiate([typeProvider.intType]));
  }

  test_newWithInvalidTypeParameters() async {
    Source source = addSource(r'''
class A {}
f() { return new A<A>(); }''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.NEW_WITH_INVALID_TYPE_PARAMETERS]);
    verify([source]);
  }

  test_newWithInvalidTypeParameters_tooFew() async {
    Source source = addSource(r'''
class A {}
class C<K, V> {}
f(p) {
  return new C<A>();
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.NEW_WITH_INVALID_TYPE_PARAMETERS]);
    verify([source]);
  }

  test_newWithInvalidTypeParameters_tooMany() async {
    Source source = addSource(r'''
class A {}
class C<E> {}
f(p) {
  return new C<A, A>();
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.NEW_WITH_INVALID_TYPE_PARAMETERS]);
    verify([source]);
  }

  test_newWithNonType() async {
    Source source = addSource(r'''
var A = 0;
void f() {
  var a = new A();
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.NEW_WITH_NON_TYPE]);
    verify([source]);
  }

  test_newWithNonType_fromLibrary() async {
    Source source1 = addNamedSource("/lib.dart", "class B {}");
    Source source2 = addNamedSource("/lib2.dart", r'''
import 'lib.dart' as lib;
void f() {
  var a = new lib.A();
}
lib.B b;''');
    await computeAnalysisResult(source1);
    await computeAnalysisResult(source2);
    assertErrors(source2, [StaticWarningCode.NEW_WITH_NON_TYPE]);
    verify([source1]);
  }

  test_newWithUndefinedConstructor() async {
    Source source = addSource(r'''
class A {
  A() {}
}
f() {
  new A.name();
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.NEW_WITH_UNDEFINED_CONSTRUCTOR]);
    // no verify(), 'name' is not resolved
  }

  test_newWithUndefinedConstructorDefault() async {
    Source source = addSource(r'''
class A {
  A.name() {}
}
f() {
  new A();
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [StaticWarningCode.NEW_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT]);
    verify([source]);
  }

  test_nonAbstractClassInheritsAbstractMemberFivePlus() async {
    Source source = addSource(r'''
abstract class A {
  m();
  n();
  o();
  p();
  q();
}
class C extends A {
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FIVE_PLUS
    ]);
    verify([source]);
  }

  test_nonAbstractClassInheritsAbstractMemberFour() async {
    Source source = addSource(r'''
abstract class A {
  m();
  n();
  o();
  p();
}
class C extends A {
}''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FOUR]);
    verify([source]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_classTypeAlias_interface() async {
    // 15979
    Source source = addSource(r'''
abstract class M {}
abstract class A {}
abstract class I {
  m();
}
class B = A with M implements I;''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE]);
    verify([source]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_classTypeAlias_mixin() async {
    // 15979
    Source source = addSource(r'''
abstract class M {
  m();
}
abstract class A {}
class B = A with M;''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE]);
    verify([source]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_classTypeAlias_superclass() async {
    // 15979
    Source source = addSource(r'''
class M {}
abstract class A {
  m();
}
class B = A with M;''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE]);
    verify([source]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_ensureCorrectFunctionSubtypeIsUsedInImplementation() async {
    // 15028
    Source source = addSource(r'''
class C {
  foo(int x) => x;
}
abstract class D {
  foo(x, [y]);
}
class E extends C implements D {}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_OVERRIDE]);
    verify([source]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_getter_fromInterface() async {
    Source source = addSource(r'''
class I {
  int get g {return 1;}
}
class C implements I {
}''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE]);
    verify([source]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_getter_fromSuperclass() async {
    Source source = addSource(r'''
abstract class A {
  int get g;
}
class C extends A {
}''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE]);
    verify([source]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_method_fromInterface() async {
    Source source = addSource(r'''
class I {
  m(p) {}
}
class C implements I {
}''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE]);
    verify([source]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_method_fromInterface_abstractNSM() async {
    Source source = addSource(r'''
class I {
  m(p) {}
}
class C implements I {
  noSuchMethod(v);
}''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE]);
    verify([source]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_method_fromInterface_abstractOverrideNSM() async {
    Source source = addSource(r'''
class I {
  m(p) {}
}
class B {
  noSuchMethod(v) => null;
}
class C extends B implements I {
  noSuchMethod(v);
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_method_fromInterface_ifcNSM() async {
    Source source = addSource(r'''
class I {
  m(p) {}
  noSuchMethod(v) => null;
}
class C implements I {
}''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE]);
    verify([source]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_method_fromSuperclass() async {
    Source source = addSource(r'''
abstract class A {
  m(p);
}
class C extends A {
}''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE]);
    verify([source]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_method_optionalParamCount() async {
    // 7640
    Source source = addSource(r'''
abstract class A {
  int x(int a);
}
abstract class B {
  int x(int a, [int b]);
}
class C implements A, B {
}''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE]);
    verify([source]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_mixinInherits_getter() async {
    // 15001
    Source source = addSource(r'''
abstract class A { get g1; get g2; }
abstract class B implements A { get g1 => 1; }
class C extends Object with B {}''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_mixinInherits_method() async {
    // 15001
    Source source = addSource(r'''
abstract class A { m1(); m2(); }
abstract class B implements A { m1() => 1; }
class C extends Object with B {}''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_mixinInherits_setter() async {
    // 15001
    Source source = addSource(r'''
abstract class A { set s1(v); set s2(v); }
abstract class B implements A { set s1(v) {} }
class C extends Object with B {}''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_noSuchMethod_interface() async {
    // 15979
    Source source = addSource(r'''
class I {
  noSuchMethod(v) => '';
}
abstract class A {
  m();
}
class B extends A implements I {
}''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE]);
    verify([source]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_setter_and_implicitSetter() async {
    // test from language/override_inheritance_abstract_test_14.dart
    Source source = addSource(r'''
abstract class A {
  set field(_);
}
abstract class I {
  var field;
}
class B extends A implements I {
  get field => 0;
}''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE]);
    verify([source]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_setter_fromInterface() async {
    Source source = addSource(r'''
class I {
  set s(int i) {}
}
class C implements I {
}''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE]);
    verify([source]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_setter_fromSuperclass() async {
    Source source = addSource(r'''
abstract class A {
  set s(int i);
}
class C extends A {
}''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE]);
    verify([source]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_superclasses_interface() async {
    // bug 11154
    Source source = addSource(r'''
class A {
  get a => 'a';
}
abstract class B implements A {
  get b => 'b';
}
class C extends B {
}''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE]);
    verify([source]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_variable_fromInterface_missingGetter() async {
    // 16133
    Source source = addSource(r'''
class I {
  var v;
}
class C implements I {
  set v(_) {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE]);
    verify([source]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_variable_fromInterface_missingSetter() async {
    // 16133
    Source source = addSource(r'''
class I {
  var v;
}
class C implements I {
  get v => 1;
}''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE]);
    verify([source]);
  }

  test_nonAbstractClassInheritsAbstractMemberThree() async {
    Source source = addSource(r'''
abstract class A {
  m();
  n();
  o();
}
class C extends A {
}''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_THREE]);
    verify([source]);
  }

  test_nonAbstractClassInheritsAbstractMemberTwo() async {
    Source source = addSource(r'''
abstract class A {
  m();
  n();
}
class C extends A {
}''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_TWO]);
    verify([source]);
  }

  test_nonAbstractClassInheritsAbstractMemberTwo_variable_fromInterface_missingBoth() async {
    // 16133
    Source source = addSource(r'''
class I {
  var v;
}
class C implements I {
}''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_TWO]);
    verify([source]);
  }

  test_nonTypeInCatchClause_noElement() async {
    Source source = addSource(r'''
f() {
  try {
  } on T catch (e) {
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.NON_TYPE_IN_CATCH_CLAUSE]);
    verify([source]);
  }

  test_nonTypeInCatchClause_notType() async {
    Source source = addSource(r'''
var T = 0;
f() {
  try {
  } on T catch (e) {
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.NON_TYPE_IN_CATCH_CLAUSE]);
    verify([source]);
  }

  test_nonVoidReturnForOperator() async {
    Source source = addSource(r'''
class A {
  int operator []=(a, b) { return a; }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.NON_VOID_RETURN_FOR_OPERATOR]);
    verify([source]);
  }

  test_nonVoidReturnForSetter_function() async {
    Source source = addSource(r'''
int set x(int v) {
  return 42;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.NON_VOID_RETURN_FOR_SETTER]);
    verify([source]);
  }

  test_nonVoidReturnForSetter_method() async {
    Source source = addSource(r'''
class A {
  int set x(int v) {
    return 42;
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.NON_VOID_RETURN_FOR_SETTER]);
    verify([source]);
  }

  test_notAType() async {
    Source source = addSource(r'''
f() {}
main() {
  f v = null;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.NOT_A_TYPE]);
    verify([source]);
  }

  test_notEnoughRequiredArguments() async {
    Source source = addSource(r'''
f(int a, String b) {}
main() {
  f();
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.NOT_ENOUGH_REQUIRED_ARGUMENTS]);
    verify([source]);
  }

  test_notEnoughRequiredArguments_functionExpression() async {
    Source source = addSource(r'''
main() {
  (int x) {} ();
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.NOT_ENOUGH_REQUIRED_ARGUMENTS]);
    verify([source]);
  }

  test_notEnoughRequiredArguments_getterReturningFunction() async {
    Source source = addSource(r'''
typedef Getter(self);
Getter getter = (x) => x;
main() {
  getter();
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.NOT_ENOUGH_REQUIRED_ARGUMENTS]);
    verify([source]);
  }

  test_partOfDifferentLibrary() async {
    Source source = addSource(r'''
library lib;
part 'part.dart';''');
    addNamedSource("/part.dart", "part of lub;");
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.PART_OF_DIFFERENT_LIBRARY]);
    verify([source]);
  }

  test_redirectToInvalidFunctionType() async {
    Source source = addSource(r'''
class A implements B {
  A(int p) {}
}
class B {
  factory B() = A;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.REDIRECT_TO_INVALID_FUNCTION_TYPE]);
    verify([source]);
  }

  test_redirectToInvalidReturnType() async {
    Source source = addSource(r'''
class A {
  A() {}
}
class B {
  factory B() = A;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.REDIRECT_TO_INVALID_RETURN_TYPE]);
    verify([source]);
  }

  test_redirectToMissingConstructor_named() async {
    Source source = addSource(r'''
class A implements B{
  A() {}
}
class B {
  factory B() = A.name;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.REDIRECT_TO_MISSING_CONSTRUCTOR]);
  }

  test_redirectToMissingConstructor_unnamed() async {
    Source source = addSource(r'''
class A implements B{
  A.name() {}
}
class B {
  factory B() = A;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.REDIRECT_TO_MISSING_CONSTRUCTOR]);
  }

  test_redirectToNonClass_notAType() async {
    Source source = addSource(r'''
class B {
  int A;
  factory B() = A;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.REDIRECT_TO_NON_CLASS]);
    verify([source]);
  }

  test_redirectToNonClass_undefinedIdentifier() async {
    Source source = addSource(r'''
class B {
  factory B() = A;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.REDIRECT_TO_NON_CLASS]);
    verify([source]);
  }

  test_returnWithoutValue_async() async {
    Source source = addSource('''
import 'dart:async';
Future<int> f() async {
  return;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.RETURN_WITHOUT_VALUE]);
    verify([source]);
  }

  test_returnWithoutValue_async_future_object_with_return() async {
    Source source = addSource('''
import 'dart:async';
Future<Object> f() async {
  return;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.RETURN_WITHOUT_VALUE]);
    verify([source]);
  }

  test_returnWithoutValue_factoryConstructor() async {
    Source source = addSource("class A { factory A() { return; } }");
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.RETURN_WITHOUT_VALUE]);
    verify([source]);
  }

  test_returnWithoutValue_function() async {
    Source source = addSource("int f() { return; }");
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.RETURN_WITHOUT_VALUE]);
    verify([source]);
  }

  test_returnWithoutValue_method() async {
    Source source = addSource("class A { int m() { return; } }");
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.RETURN_WITHOUT_VALUE]);
    verify([source]);
  }

  test_returnWithoutValue_mixedReturnTypes_function() async {
    // Tests that only the RETURN_WITHOUT_VALUE warning is created, and no
    // MIXED_RETURN_TYPES are created.
    Source source = addSource(r'''
int f(int x) {
  if (x < 0) {
    return 1;
  }
  return;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.RETURN_WITHOUT_VALUE]);
    verify([source]);
  }

  test_returnWithoutValue_Null() async {
    // Test that block bodied functions with return type Null and an empty
    // return cause a static warning.
    Source source = addSource(r'''
Null f() {return;}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_staticAccessToInstanceMember_method_invocation() async {
    Source source = addSource(r'''
class A {
  m() {}
}
main() {
  A.m();
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.STATIC_ACCESS_TO_INSTANCE_MEMBER]);
    verify([source]);
  }

  test_staticAccessToInstanceMember_method_reference() async {
    Source source = addSource(r'''
class A {
  m() {}
}
main() {
  A.m;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.STATIC_ACCESS_TO_INSTANCE_MEMBER]);
    verify([source]);
  }

  test_staticAccessToInstanceMember_propertyAccess_field() async {
    Source source = addSource(r'''
class A {
  var f;
}
main() {
  A.f;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.STATIC_ACCESS_TO_INSTANCE_MEMBER]);
    verify([source]);
  }

  test_staticAccessToInstanceMember_propertyAccess_getter() async {
    Source source = addSource(r'''
class A {
  get f => 42;
}
main() {
  A.f;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.STATIC_ACCESS_TO_INSTANCE_MEMBER]);
    verify([source]);
  }

  test_staticAccessToInstanceMember_propertyAccess_setter() async {
    Source source = addSource(r'''
class A {
  set f(x) {}
}
main() {
  A.f = 42;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.STATIC_ACCESS_TO_INSTANCE_MEMBER]);
    verify([source]);
  }

  test_switchExpressionNotAssignable() async {
    Source source = addSource(r'''
f(int p) {
  switch (p) {
    case 'a': break;
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.SWITCH_EXPRESSION_NOT_ASSIGNABLE]);
    verify([source]);
  }

  test_typeAnnotationDeferredClass_asExpression() async {
    await resolveWithErrors(<String>[
      r'''
library lib1;
class A {}''',
      r'''
library root;
import 'lib1.dart' deferred as a;
f(var v) {
  v as a.A;
}'''
    ], <ErrorCode>[
      StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS
    ]);
  }

  test_typeAnnotationDeferredClass_catchClause() async {
    await resolveWithErrors(<String>[
      r'''
library lib1;
class A {}''',
      r'''
library root;
import 'lib1.dart' deferred as a;
f(var v) {
  try {
  } on a.A {
  }
}'''
    ], <ErrorCode>[
      StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS
    ]);
  }

  test_typeAnnotationDeferredClass_fieldFormalParameter() async {
    await resolveWithErrors(<String>[
      r'''
library lib1;
class A {}''',
      r'''
library root;
import 'lib1.dart' deferred as a;
class C {
  var v;
  C(a.A this.v);
}'''
    ], <ErrorCode>[
      StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS
    ]);
  }

  test_typeAnnotationDeferredClass_functionDeclaration_returnType() async {
    await resolveWithErrors(<String>[
      r'''
library lib1;
class A {}''',
      r'''
library root;
import 'lib1.dart' deferred as a;
a.A f() { return null; }'''
    ], <ErrorCode>[
      StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS
    ]);
  }

  test_typeAnnotationDeferredClass_functionTypedFormalParameter_returnType() async {
    await resolveWithErrors(<String>[
      r'''
library lib1;
class A {}''',
      r'''
library root;
import 'lib1.dart' deferred as a;
f(a.A g()) {}'''
    ], <ErrorCode>[
      StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS
    ]);
  }

  test_typeAnnotationDeferredClass_isExpression() async {
    await resolveWithErrors(<String>[
      r'''
library lib1;
class A {}''',
      r'''
library root;
import 'lib1.dart' deferred as a;
f(var v) {
  bool b = v is a.A;
}'''
    ], <ErrorCode>[
      StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS
    ]);
  }

  test_typeAnnotationDeferredClass_methodDeclaration_returnType() async {
    await resolveWithErrors(<String>[
      r'''
library lib1;
class A {}''',
      r'''
library root;
import 'lib1.dart' deferred as a;
class C {
  a.A m() { return null; }
}'''
    ], <ErrorCode>[
      StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS
    ]);
  }

  test_typeAnnotationDeferredClass_simpleFormalParameter() async {
    await resolveWithErrors(<String>[
      r'''
library lib1;
class A {}''',
      r'''
library root;
import 'lib1.dart' deferred as a;
f(a.A v) {}'''
    ], <ErrorCode>[
      StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS
    ]);
  }

  test_typeAnnotationDeferredClass_typeArgumentList() async {
    await resolveWithErrors(<String>[
      r'''
library lib1;
class A {}''',
      r'''
library root;
import 'lib1.dart' deferred as a;
class C<E> {}
C<a.A> c;'''
    ], <ErrorCode>[
      StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS
    ]);
  }

  test_typeAnnotationDeferredClass_typeArgumentList2() async {
    await resolveWithErrors(<String>[
      r'''
library lib1;
class A {}''',
      r'''
library root;
import 'lib1.dart' deferred as a;
class C<E, F> {}
C<a.A, a.A> c;'''
    ], <ErrorCode>[
      StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS,
      StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS
    ]);
  }

  test_typeAnnotationDeferredClass_typeParameter_bound() async {
    await resolveWithErrors(<String>[
      r'''
library lib1;
class A {}''',
      r'''
library root;
import 'lib1.dart' deferred as a;
class C<E extends a.A> {}'''
    ], <ErrorCode>[
      StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS
    ]);
  }

  test_typeAnnotationDeferredClass_variableDeclarationList() async {
    await resolveWithErrors(<String>[
      r'''
library lib1;
class A {}''',
      r'''
library root;
import 'lib1.dart' deferred as a;
a.A v;'''
    ], <ErrorCode>[
      StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS
    ]);
  }

  test_typeParameterReferencedByStatic_field() async {
    Source source = addSource(r'''
class A<K> {
  static K k;
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [StaticWarningCode.TYPE_PARAMETER_REFERENCED_BY_STATIC]);
    verify([source]);
  }

  test_typeParameterReferencedByStatic_getter() async {
    Source source = addSource(r'''
class A<K> {
  static K get k => null;
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [StaticWarningCode.TYPE_PARAMETER_REFERENCED_BY_STATIC]);
    verify([source]);
  }

  test_typeParameterReferencedByStatic_methodBodyReference() async {
    Source source = addSource(r'''
class A<K> {
  static m() {
    K k;
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [StaticWarningCode.TYPE_PARAMETER_REFERENCED_BY_STATIC]);
    verify([source]);
  }

  test_typeParameterReferencedByStatic_methodParameter() async {
    Source source = addSource(r'''
class A<K> {
  static m(K k) {}
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [StaticWarningCode.TYPE_PARAMETER_REFERENCED_BY_STATIC]);
    verify([source]);
  }

  test_typeParameterReferencedByStatic_methodReturn() async {
    Source source = addSource(r'''
class A<K> {
  static K m() { return null; }
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [StaticWarningCode.TYPE_PARAMETER_REFERENCED_BY_STATIC]);
    verify([source]);
  }

  test_typeParameterReferencedByStatic_setter() async {
    Source source = addSource(r'''
class A<K> {
  static set s(K k) {}
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [StaticWarningCode.TYPE_PARAMETER_REFERENCED_BY_STATIC]);
    verify([source]);
  }

  test_typeParameterReferencedByStatic_simpleIdentifier() async {
    Source source = addSource('''
class A<T> {
  static foo() {
    T;
  }
}
''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [StaticWarningCode.TYPE_PARAMETER_REFERENCED_BY_STATIC]);
    verify([source]);
  }

  test_typePromotion_functionType_arg_InterToDyn() async {
    Source source = addSource(r'''
typedef FuncDyn(x);
typedef FuncA(A a);
class A {}
class B {}
main(FuncA f) {
  if (f is FuncDyn) {
    f(new B());
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_typeTestNonType() async {
    Source source = addSource(r'''
var A = 0;
f(var p) {
  if (p is A) {
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.TYPE_TEST_WITH_NON_TYPE]);
    verify([source]);
  }

  test_typeTestWithUndefinedName() async {
    Source source = addSource(r'''
f(var p) {
  if (p is A) {
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.TYPE_TEST_WITH_UNDEFINED_NAME]);
    verify([source]);
  }

  test_undefinedClass_instanceCreation() async {
    Source source = addSource("f() { new C(); }");
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.UNDEFINED_CLASS]);
  }

  test_undefinedClass_variableDeclaration() async {
    Source source = addSource("f() { C c; }");
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.UNDEFINED_CLASS]);
  }

  test_undefinedClassBoolean_variableDeclaration() async {
    Source source = addSource("f() { boolean v; }");
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.UNDEFINED_CLASS_BOOLEAN]);
  }

  @failingTest
  test_undefinedIdentifier_commentReference() async {
    Source source = addSource(r'''
/** [m] xxx [new B.c] */
class A {
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      StaticWarningCode.UNDEFINED_IDENTIFIER,
      StaticWarningCode.UNDEFINED_IDENTIFIER
    ]);
  }

  test_undefinedIdentifier_for() async {
    Source source = addSource(r'''
f(var l) {
  for (e in l) {
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.UNDEFINED_IDENTIFIER]);
  }

  test_undefinedIdentifier_function() async {
    Source source = addSource("int a() => b;");
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.UNDEFINED_IDENTIFIER]);
  }

  test_undefinedIdentifier_importCore_withShow() async {
    Source source = addSource(r'''
import 'dart:core' show List;
main() {
  List;
  String;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.UNDEFINED_IDENTIFIER]);
  }

  test_undefinedIdentifier_initializer() async {
    Source source = addSource("var a = b;");
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.UNDEFINED_IDENTIFIER]);
  }

  test_undefinedIdentifier_methodInvocation() async {
    Source source = addSource("f() { C.m(); }");
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.UNDEFINED_IDENTIFIER]);
  }

  test_undefinedIdentifier_private_getter() async {
    addNamedSource("/lib.dart", r'''
library lib;
class A {
  var _foo;
}''');
    Source source = addSource(r'''
import 'lib.dart';
class B extends A {
  test() {
    var v = _foo;
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.UNDEFINED_IDENTIFIER]);
  }

  test_undefinedIdentifier_private_setter() async {
    addNamedSource("/lib.dart", r'''
library lib;
class A {
  var _foo;
}''');
    Source source = addSource(r'''
import 'lib.dart';
class B extends A {
  test() {
    _foo = 42;
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.UNDEFINED_IDENTIFIER]);
  }

  test_undefinedIdentifierAwait_function() async {
    Source source = addSource("void a() { await; }");
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.UNDEFINED_IDENTIFIER_AWAIT]);
  }

  test_undefinedNamedParameter() async {
    Source source = addSource(r'''
f({a, b}) {}
main() {
  f(c: 1);
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.UNDEFINED_NAMED_PARAMETER]);
    // no verify(), 'c' is not resolved
  }

  test_undefinedStaticMethodOrGetter_getter() async {
    Source source = addSource(r'''
class C {}
f(var p) {
  f(C.m);
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_GETTER]);
  }

  test_undefinedStaticMethodOrGetter_getter_inSuperclass() async {
    Source source = addSource(r'''
class S {
  static int get g => 0;
}
class C extends S {}
f(var p) {
  f(C.g);
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_GETTER]);
  }

  test_undefinedStaticMethodOrGetter_setter_inSuperclass() async {
    Source source = addSource(r'''
class S {
  static set s(int i) {}
}
class C extends S {}
f(var p) {
  f(C.s = 1);
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_SETTER]);
  }

  test_useOfVoidResult_assignmentExpression_function() async {
    Source source = addSource(r'''
void f() {}
class A {
  n() {
    var a;
    a = f();
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.USE_OF_VOID_RESULT]);
    verify([source]);
  }

  test_useOfVoidResult_assignmentExpression_method() async {
    Source source = addSource(r'''
class A {
  void m() {}
  n() {
    var a;
    a = m();
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.USE_OF_VOID_RESULT]);
    verify([source]);
  }

  test_useOfVoidResult_await() async {
    Source source = addSource(r'''
main() async {
  void x;
  await x;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_useOfVoidResult_inForLoop_error() async {
    Source source = addSource(r'''
class A {
  void m() {}
  n() {
    for(Object a = m();;) {}
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.USE_OF_VOID_RESULT]);
    verify([source]);
  }

  test_useOfVoidResult_inForLoop_ok() async {
    Source source = addSource(r'''
class A {
  void m() {}
  n() {
    for(void a = m();;) {}
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_useOfVoidResult_variableDeclaration_function_error() async {
    Source source = addSource(r'''
void f() {}
class A {
  n() {
    Object a = f();
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.USE_OF_VOID_RESULT]);
    verify([source]);
  }

  test_useOfVoidResult_variableDeclaration_function_ok() async {
    Source source = addSource(r'''
void f() {}
class A {
  n() {
    void a = f();
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_useOfVoidResult_variableDeclaration_method2() async {
    Source source = addSource(r'''
class A {
  void m() {}
  n() {
    Object a = m(), b = m();
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      StaticWarningCode.USE_OF_VOID_RESULT,
      StaticWarningCode.USE_OF_VOID_RESULT
    ]);
    verify([source]);
  }

  test_useOfVoidResult_variableDeclaration_method_error() async {
    Source source = addSource(r'''
class A {
  void m() {}
  n() {
    Object a = m();
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.USE_OF_VOID_RESULT]);
    verify([source]);
  }

  test_useOfVoidResult_variableDeclaration_method_ok() async {
    Source source = addSource(r'''
class A {
  void m() {}
  n() {
    void a = m();
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_voidReturnForGetter() async {
    Source source = addSource(r'''
class S {
  void get value {}
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }
}
