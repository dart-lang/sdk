// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library engine.static_warning_code_test;

import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/parser.dart' show ParserErrorCode;
import 'package:unittest/unittest.dart';
import 'resolver_test.dart';
import '../reflective_tests.dart';


class StaticWarningCodeTest extends ResolverTestCase {
  void fail_undefinedGetter() {
    Source source = addSource(r'''
''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.UNDEFINED_GETTER]);
    verify([source]);
  }

  void fail_undefinedIdentifier_commentReference() {
    Source source = addSource(r'''
/** [m] xxx [new B.c] */
class A {
}''');
    resolve(source);
    assertErrors(source, [
        StaticWarningCode.UNDEFINED_IDENTIFIER,
        StaticWarningCode.UNDEFINED_IDENTIFIER]);
  }

  void fail_undefinedSetter() {
    Source source = addSource(r'''
class C {}
f(var p) {
  C.m = 0;
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.UNDEFINED_SETTER]);
    verify([source]);
  }

  void test_ambiguousImport_as() {
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
    resolve(source);
    assertErrors(source, [StaticWarningCode.AMBIGUOUS_IMPORT]);
  }

  void test_ambiguousImport_extends() {
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
    resolve(source);
    assertErrors(source, [
        StaticWarningCode.AMBIGUOUS_IMPORT,
        CompileTimeErrorCode.EXTENDS_NON_CLASS]);
  }

  void test_ambiguousImport_implements() {
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
    resolve(source);
    assertErrors(source, [
        StaticWarningCode.AMBIGUOUS_IMPORT,
        CompileTimeErrorCode.IMPLEMENTS_NON_CLASS]);
  }

  void test_ambiguousImport_inPart() {
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
    resolve(source);
    assertErrors(partSource, [
        StaticWarningCode.AMBIGUOUS_IMPORT,
        CompileTimeErrorCode.EXTENDS_NON_CLASS]);
  }

  void test_ambiguousImport_instanceCreation() {
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
    resolve(source);
    assertErrors(source, [StaticWarningCode.AMBIGUOUS_IMPORT]);
  }

  void test_ambiguousImport_is() {
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
    resolve(source);
    assertErrors(source, [StaticWarningCode.AMBIGUOUS_IMPORT]);
  }

  void test_ambiguousImport_qualifier() {
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
    resolve(source);
    assertErrors(source, [StaticWarningCode.AMBIGUOUS_IMPORT]);
  }

  void test_ambiguousImport_typeAnnotation() {
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
    resolve(source);
    assertErrors(source, [
        StaticWarningCode.AMBIGUOUS_IMPORT,
        StaticWarningCode.AMBIGUOUS_IMPORT,
        StaticWarningCode.AMBIGUOUS_IMPORT,
        StaticWarningCode.AMBIGUOUS_IMPORT,
        StaticWarningCode.AMBIGUOUS_IMPORT,
        StaticWarningCode.AMBIGUOUS_IMPORT,
        StaticWarningCode.AMBIGUOUS_IMPORT]);
  }

  void test_ambiguousImport_typeArgument_annotation() {
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
    resolve(source);
    assertErrors(source, [StaticWarningCode.AMBIGUOUS_IMPORT]);
  }

  void test_ambiguousImport_typeArgument_instanceCreation() {
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
    resolve(source);
    assertErrors(source, [StaticWarningCode.AMBIGUOUS_IMPORT]);
  }

  void test_ambiguousImport_varRead() {
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
    resolve(source);
    assertErrors(source, [StaticWarningCode.AMBIGUOUS_IMPORT]);
  }

  void test_ambiguousImport_varWrite() {
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
    resolve(source);
    assertErrors(source, [StaticWarningCode.AMBIGUOUS_IMPORT]);
  }

  void test_ambiguousImport_withPrefix() {
    Source source = addSource(r'''
library test;
import 'lib1.dart' as p;
import 'lib2.dart' as p;
main() {
  p.f();
}''');
    addNamedSource("/lib1.dart", r'''
library lib1;
f() {}''');
    addNamedSource("/lib2.dart", r'''
library lib2;
f() {}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.AMBIGUOUS_IMPORT]);
  }

  void test_argumentTypeNotAssignable_ambiguousClassName() {
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
    resolve(source);
    // The name _A is private to the library it's defined in, so this is a type mismatch.
    // Furthermore, the error message should mention both _A and the filenames
    // so the user can figure out what's going on.
    List<AnalysisError> errors = analysisContext2.computeErrors(source);
    expect(errors, hasLength(1));
    AnalysisError error = errors[0];
    expect(StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, error.errorCode);
    String message = error.message;
    expect(message.indexOf("_A") != -1, isTrue);
    expect(message.indexOf("lib1.dart") != -1, isTrue);
    expect(message.indexOf("lib2.dart") != -1, isTrue);
  }

  void test_argumentTypeNotAssignable_annotation_namedConstructor() {
    Source source = addSource(r'''
class A {
  const A.fromInt(int p);
}
@A.fromInt('0')
main() {
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  void test_argumentTypeNotAssignable_annotation_unnamedConstructor() {
    Source source = addSource(r'''
class A {
  const A(int p);
}
@A('0')
main() {
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  void test_argumentTypeNotAssignable_binary() {
    Source source = addSource(r'''
class A {
  operator +(int p) {}
}
f(A a) {
  a + '0';
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  void test_argumentTypeNotAssignable_cascadeSecond() {
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
    resolve(source);
    assertErrors(source, [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  void test_argumentTypeNotAssignable_const() {
    Source source = addSource(r'''
class A {
  const A(String p);
}
main() {
  const A(42);
}''');
    resolve(source);
    assertErrors(source, [
        StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE,
        CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH]);
    verify([source]);
  }

  void test_argumentTypeNotAssignable_const_super() {
    Source source = addSource(r'''
class A {
  const A(String p);
}
class B extends A {
  const B() : super(42);
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  void test_argumentTypeNotAssignable_functionExpressionInvocation_required() {
    Source source = addSource(r'''
main() {
  (int x) {} ('');
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  void test_argumentTypeNotAssignable_index() {
    Source source = addSource(r'''
class A {
  operator [](int index) {}
}
f(A a) {
  a['0'];
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  void test_argumentTypeNotAssignable_invocation_callParameter() {
    Source source = addSource(r'''
class A {
  call(int p) {}
}
f(A a) {
  a('0');
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  void test_argumentTypeNotAssignable_invocation_callVariable() {
    Source source = addSource(r'''
class A {
  call(int p) {}
}
main() {
  A a = new A();
  a('0');
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  void test_argumentTypeNotAssignable_invocation_functionParameter() {
    Source source = addSource(r'''
a(b(int p)) {
  b('0');
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  void test_argumentTypeNotAssignable_invocation_functionParameter_generic() {
    Source source = addSource(r'''
class A<K, V> {
  m(f(K k), V v) {
    f(v);
  }
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  void test_argumentTypeNotAssignable_invocation_functionTypes_optional() {
    Source source = addSource(r'''
void acceptFunNumOptBool(void funNumOptBool([bool b])) {}
void funNumBool(bool b) {}
main() {
  acceptFunNumOptBool(funNumBool);
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  void test_argumentTypeNotAssignable_invocation_generic() {
    Source source = addSource(r'''
class A<T> {
  m(T t) {}
}
f(A<String> a) {
  a.m(1);
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  void test_argumentTypeNotAssignable_invocation_named() {
    Source source = addSource(r'''
f({String p}) {}
main() {
  f(p: 42);
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  void test_argumentTypeNotAssignable_invocation_optional() {
    Source source = addSource(r'''
f([String p]) {}
main() {
  f(42);
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  void test_argumentTypeNotAssignable_invocation_required() {
    Source source = addSource(r'''
f(String p) {}
main() {
  f(42);
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  void test_argumentTypeNotAssignable_invocation_typedef_generic() {
    Source source = addSource(r'''
typedef A<T>(T p);
f(A<int> a) {
  a('1');
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  void test_argumentTypeNotAssignable_invocation_typedef_local() {
    Source source = addSource(r'''
typedef A(int p);
A getA() => null;
main() {
  A a = getA();
  a('1');
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  void test_argumentTypeNotAssignable_invocation_typedef_parameter() {
    Source source = addSource(r'''
typedef A(int p);
f(A a) {
  a('1');
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  void test_argumentTypeNotAssignable_new_generic() {
    Source source = addSource(r'''
class A<T> {
  A(T p) {}
}
main() {
  new A<String>(42);
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  void test_argumentTypeNotAssignable_new_optional() {
    Source source = addSource(r'''
class A {
  A([String p]) {}
}
main() {
  new A(42);
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  void test_argumentTypeNotAssignable_new_required() {
    Source source = addSource(r'''
class A {
  A(String p) {}
}
main() {
  new A(42);
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  void test_assignmentToConst_instanceVariable() {
    Source source = addSource(r'''
class A {
  static const v = 0;
}
f() {
  A.v = 1;
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.ASSIGNMENT_TO_CONST]);
    verify([source]);
  }

  void test_assignmentToConst_instanceVariable_plusEq() {
    Source source = addSource(r'''
class A {
  static const v = 0;
}
f() {
  A.v += 1;
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.ASSIGNMENT_TO_CONST]);
    verify([source]);
  }

  void test_assignmentToConst_localVariable() {
    Source source = addSource(r'''
f() {
  const x = 0;
  x = 1;
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.ASSIGNMENT_TO_CONST]);
    verify([source]);
  }

  void test_assignmentToConst_localVariable_plusEq() {
    Source source = addSource(r'''
f() {
  const x = 0;
  x += 1;
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.ASSIGNMENT_TO_CONST]);
    verify([source]);
  }

  void test_assignmentToFinal_instanceVariable() {
    Source source = addSource(r'''
class A {
  final v = 0;
}
f() {
  A a = new A();
  a.v = 1;
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.ASSIGNMENT_TO_FINAL]);
    verify([source]);
  }

  void test_assignmentToFinal_instanceVariable_plusEq() {
    Source source = addSource(r'''
class A {
  final v = 0;
}
f() {
  A a = new A();
  a.v += 1;
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.ASSIGNMENT_TO_FINAL]);
    verify([source]);
  }

  void test_assignmentToFinal_localVariable() {
    Source source = addSource(r'''
f() {
  final x = 0;
  x = 1;
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.ASSIGNMENT_TO_FINAL]);
    verify([source]);
  }

  void test_assignmentToFinal_localVariable_plusEq() {
    Source source = addSource(r'''
f() {
  final x = 0;
  x += 1;
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.ASSIGNMENT_TO_FINAL]);
    verify([source]);
  }

  void test_assignmentToFinal_postfixMinusMinus() {
    Source source = addSource(r'''
f() {
  final x = 0;
  x--;
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.ASSIGNMENT_TO_FINAL]);
    verify([source]);
  }

  void test_assignmentToFinal_postfixPlusPlus() {
    Source source = addSource(r'''
f() {
  final x = 0;
  x++;
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.ASSIGNMENT_TO_FINAL]);
    verify([source]);
  }

  void test_assignmentToFinal_prefixMinusMinus() {
    Source source = addSource(r'''
f() {
  final x = 0;
  --x;
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.ASSIGNMENT_TO_FINAL]);
    verify([source]);
  }

  void test_assignmentToFinal_prefixPlusPlus() {
    Source source = addSource(r'''
f() {
  final x = 0;
  ++x;
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.ASSIGNMENT_TO_FINAL]);
    verify([source]);
  }

  void test_assignmentToFinal_suffixMinusMinus() {
    Source source = addSource(r'''
f() {
  final x = 0;
  x--;
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.ASSIGNMENT_TO_FINAL]);
    verify([source]);
  }

  void test_assignmentToFinal_suffixPlusPlus() {
    Source source = addSource(r'''
f() {
  final x = 0;
  x++;
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.ASSIGNMENT_TO_FINAL]);
    verify([source]);
  }

  void test_assignmentToFinal_topLevelVariable() {
    Source source = addSource(r'''
final x = 0;
f() { x = 1; }''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.ASSIGNMENT_TO_FINAL]);
    verify([source]);
  }

  void test_assignmentToFinalNoSetter_prefixedIdentifier() {
    Source source = addSource(r'''
class A {
  int get x => 0;
}
main() {
  A a = new A();
  a.x = 0;
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.ASSIGNMENT_TO_FINAL_NO_SETTER]);
    verify([source]);
  }

  void test_assignmentToFinalNoSetter_propertyAccess() {
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
    resolve(source);
    assertErrors(source, [StaticWarningCode.ASSIGNMENT_TO_FINAL_NO_SETTER]);
    verify([source]);
  }

  void test_assignmentToFunction() {
    Source source = addSource(r'''
f() {}
main() {
  f = null;
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.ASSIGNMENT_TO_FUNCTION]);
    verify([source]);
  }

  void test_assignmentToMethod() {
    Source source = addSource(r'''
class A {
  m() {}
}
f(A a) {
  a.m = () {};
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.ASSIGNMENT_TO_METHOD]);
    verify([source]);
  }

  void test_caseBlockNotTerminated() {
    Source source = addSource(r'''
f(int p) {
  switch (p) {
    case 0:
      f(p);
    case 1:
      break;
  }
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.CASE_BLOCK_NOT_TERMINATED]);
    verify([source]);
  }

  void test_castToNonType() {
    Source source = addSource(r'''
var A = 0;
f(String s) { var x = s as A; }''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.CAST_TO_NON_TYPE]);
    verify([source]);
  }

  void test_concreteClassWithAbstractMember() {
    Source source = addSource(r'''
class A {
  m();
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER]);
    verify([source]);
  }

  void test_conflictingDartImport() {
    Source source = addSource(r'''
import 'lib.dart';
import 'dart:async';
Future f = null;
Stream s;''');
    addNamedSource("/lib.dart", r'''
library lib;
class Future {}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.CONFLICTING_DART_IMPORT]);
  }

  void test_conflictingInstanceGetterAndSuperclassMember_declField_direct_setter() {
    Source source = addSource(r'''
class A {
  static set v(x) {}
}
class B extends A {
  var v;
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.CONFLICTING_INSTANCE_GETTER_AND_SUPERCLASS_MEMBER]);
    verify([source]);
  }

  void test_conflictingInstanceGetterAndSuperclassMember_declGetter_direct_getter() {
    Source source = addSource(r'''
class A {
  static get v => 0;
}
class B extends A {
  get v => 0;
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.CONFLICTING_INSTANCE_GETTER_AND_SUPERCLASS_MEMBER]);
    verify([source]);
  }

  void test_conflictingInstanceGetterAndSuperclassMember_declGetter_direct_method() {
    Source source = addSource(r'''
class A {
  static v() {}
}
class B extends A {
  get v => 0;
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.CONFLICTING_INSTANCE_GETTER_AND_SUPERCLASS_MEMBER]);
    verify([source]);
  }

  void test_conflictingInstanceGetterAndSuperclassMember_declGetter_direct_setter() {
    Source source = addSource(r'''
class A {
  static set v(x) {}
}
class B extends A {
  get v => 0;
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.CONFLICTING_INSTANCE_GETTER_AND_SUPERCLASS_MEMBER]);
    verify([source]);
  }

  void test_conflictingInstanceGetterAndSuperclassMember_declGetter_indirect() {
    Source source = addSource(r'''
class A {
  static int v;
}
class B extends A {}
class C extends B {
  get v => 0;
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.CONFLICTING_INSTANCE_GETTER_AND_SUPERCLASS_MEMBER]);
    verify([source]);
  }

  void test_conflictingInstanceGetterAndSuperclassMember_declGetter_mixin() {
    Source source = addSource(r'''
class M {
  static int v;
}
class B extends Object with M {
  get v => 0;
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.CONFLICTING_INSTANCE_GETTER_AND_SUPERCLASS_MEMBER]);
    verify([source]);
  }

  void test_conflictingInstanceGetterAndSuperclassMember_direct_field() {
    Source source = addSource(r'''
class A {
  static int v;
}
class B extends A {
  get v => 0;
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.CONFLICTING_INSTANCE_GETTER_AND_SUPERCLASS_MEMBER]);
    verify([source]);
  }

  void test_conflictingInstanceMethodSetter_sameClass() {
    Source source = addSource(r'''
class A {
  set foo(a) {}
  foo() {}
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.CONFLICTING_INSTANCE_METHOD_SETTER]);
    verify([source]);
  }

  void test_conflictingInstanceMethodSetter_setterInInterface() {
    Source source = addSource(r'''
abstract class A {
  set foo(a);
}
abstract class B implements A {
  foo() {}
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.CONFLICTING_INSTANCE_METHOD_SETTER]);
    verify([source]);
  }

  void test_conflictingInstanceMethodSetter_setterInSuper() {
    Source source = addSource(r'''
class A {
  set foo(a) {}
}
class B extends A {
  foo() {}
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.CONFLICTING_INSTANCE_METHOD_SETTER]);
    verify([source]);
  }

  void test_conflictingInstanceMethodSetter2() {
    Source source = addSource(r'''
class A {
  foo() {}
  set foo(a) {}
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.CONFLICTING_INSTANCE_METHOD_SETTER2]);
    verify([source]);
  }

  void test_conflictingInstanceSetterAndSuperclassMember() {
    Source source = addSource(r'''
class A {
  static int v;
}
class B extends A {
  set v(x) {}
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.CONFLICTING_INSTANCE_SETTER_AND_SUPERCLASS_MEMBER]);
    verify([source]);
  }

  void test_conflictingStaticGetterAndInstanceSetter_mixin() {
    Source source = addSource(r'''
class A {
  set x(int p) {}
}
class B extends Object with A {
  static get x => 0;
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.CONFLICTING_STATIC_GETTER_AND_INSTANCE_SETTER]);
    verify([source]);
  }

  void test_conflictingStaticGetterAndInstanceSetter_superClass() {
    Source source = addSource(r'''
class A {
  set x(int p) {}
}
class B extends A {
  static get x => 0;
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.CONFLICTING_STATIC_GETTER_AND_INSTANCE_SETTER]);
    verify([source]);
  }

  void test_conflictingStaticGetterAndInstanceSetter_thisClass() {
    Source source = addSource(r'''
class A {
  static get x => 0;
  set x(int p) {}
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.CONFLICTING_STATIC_GETTER_AND_INSTANCE_SETTER]);
    verify([source]);
  }

  void test_conflictingStaticSetterAndInstanceMember_thisClass_getter() {
    Source source = addSource(r'''
class A {
  get x => 0;
  static set x(int p) {}
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.CONFLICTING_STATIC_SETTER_AND_INSTANCE_MEMBER]);
    verify([source]);
  }

  void test_conflictingStaticSetterAndInstanceMember_thisClass_method() {
    Source source = addSource(r'''
class A {
  x() {}
  static set x(int p) {}
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.CONFLICTING_STATIC_SETTER_AND_INSTANCE_MEMBER]);
    verify([source]);
  }

  void test_constWithAbstractClass() {
    Source source = addSource(r'''
abstract class A {
  const A();
}
void f() {
  A a = const A();
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.CONST_WITH_ABSTRACT_CLASS]);
    verify([source]);
  }

  void test_equalKeysInMap() {
    Source source = addSource("var m = {'a' : 0, 'b' : 1, 'a' : 2};");
    resolve(source);
    assertErrors(source, [StaticWarningCode.EQUAL_KEYS_IN_MAP]);
    verify([source]);
  }

  void test_equalKeysInMap_withEqualTypeParams() {
    Source source = addSource(r'''
class A<T> {
  const A();
}
var m = {const A<int>(): 0, const A<int>(): 1};''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.EQUAL_KEYS_IN_MAP]);
    verify([source]);
  }

  void test_equalKeysInMap_withUnequalTypeParams() {
    // No error should be produced because A<int> and A<num> are different types.
    Source source = addSource(r'''
class A<T> {
  const A();
}
var m = {const A<int>(): 0, const A<num>(): 1};''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_exportDuplicatedLibraryName() {
    Source source = addSource(r'''
library test;
export 'lib1.dart';
export 'lib2.dart';''');
    addNamedSource("/lib1.dart", "library lib;");
    addNamedSource("/lib2.dart", "library lib;");
    resolve(source);
    assertErrors(source, [StaticWarningCode.EXPORT_DUPLICATED_LIBRARY_NAME]);
    verify([source]);
  }

  void test_extraPositionalArguments() {
    Source source = addSource(r'''
f() {}
main() {
  f(0, 1, '2');
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.EXTRA_POSITIONAL_ARGUMENTS]);
    verify([source]);
  }

  void test_extraPositionalArguments_functionExpression() {
    Source source = addSource(r'''
main() {
  (int x) {} (0, 1);
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.EXTRA_POSITIONAL_ARGUMENTS]);
    verify([source]);
  }

  void test_fieldInitializedInInitializerAndDeclaration_final() {
    Source source = addSource(r'''
class A {
  final int x = 0;
  A() : x = 1 {}
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION]);
    verify([source]);
  }

  void test_fieldInitializerNotAssignable() {
    Source source = addSource(r'''
class A {
  int x;
  A() : x = '';
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.FIELD_INITIALIZER_NOT_ASSIGNABLE]);
    verify([source]);
  }

  void test_fieldInitializingFormalNotAssignable() {
    Source source = addSource(r'''
class A {
  int x;
  A(String this.x) {}
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.FIELD_INITIALIZING_FORMAL_NOT_ASSIGNABLE]);
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
  void test_finalInitializedInDeclarationAndConstructor_initializers() {
    Source source = addSource(r'''
class A {
  final x = 0;
  A() : x = 0 {}
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION]);
    verify([source]);
  }

  void test_finalInitializedInDeclarationAndConstructor_initializingFormal() {
    Source source = addSource(r'''
class A {
  final x = 0;
  A(this.x) {}
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.FINAL_INITIALIZED_IN_DECLARATION_AND_CONSTRUCTOR]);
    verify([source]);
  }

  void test_finalNotInitialized_inConstructor() {
    Source source = addSource(r'''
class A {
  final int x;
  A() {}
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.FINAL_NOT_INITIALIZED]);
    verify([source]);
  }

  void test_finalNotInitialized_instanceField_final() {
    Source source = addSource(r'''
class A {
  final F;
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.FINAL_NOT_INITIALIZED]);
    verify([source]);
  }

  void test_finalNotInitialized_instanceField_final_static() {
    Source source = addSource(r'''
class A {
  static final F;
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.FINAL_NOT_INITIALIZED]);
    verify([source]);
  }

  void test_finalNotInitialized_library_final() {
    Source source = addSource("final F;");
    resolve(source);
    assertErrors(source, [StaticWarningCode.FINAL_NOT_INITIALIZED]);
    verify([source]);
  }

  void test_finalNotInitialized_local_final() {
    Source source = addSource(r'''
f() {
  final int x;
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.FINAL_NOT_INITIALIZED]);
    verify([source]);
  }

  void test_functionWithoutCall_direct() {
    Source source = addSource(r'''
class A implements Function {
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.FUNCTION_WITHOUT_CALL]);
    verify([source]);
  }

  void test_functionWithoutCall_indirect_extends() {
    Source source = addSource(r'''
abstract class A implements Function {
}
class B extends A {
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.FUNCTION_WITHOUT_CALL]);
    verify([source]);
  }

  void test_functionWithoutCall_indirect_implements() {
    Source source = addSource(r'''
abstract class A implements Function {
}
class B implements A {
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.FUNCTION_WITHOUT_CALL]);
    verify([source]);
  }

  void test_importDuplicatedLibraryName() {
    Source source = addSource(r'''
library test;
import 'lib1.dart';
import 'lib2.dart';''');
    addNamedSource("/lib1.dart", "library lib;");
    addNamedSource("/lib2.dart", "library lib;");
    resolve(source);
    assertErrors(source, [
        StaticWarningCode.IMPORT_DUPLICATED_LIBRARY_NAME,
        HintCode.UNUSED_IMPORT,
        HintCode.UNUSED_IMPORT]);
    verify([source]);
  }

  void test_importOfNonLibrary() {
    resolveWithAndWithoutExperimental(<String> [
        r'''
part of lib;
class A {}''',
        r'''
library lib;
import 'lib1.dart' deferred as p;
var a = new p.A();'''], <ErrorCode> [
        CompileTimeErrorCode.IMPORT_OF_NON_LIBRARY,
        ParserErrorCode.DEFERRED_IMPORTS_NOT_SUPPORTED], <ErrorCode> [StaticWarningCode.IMPORT_OF_NON_LIBRARY]);
  }

  void test_inconsistentMethodInheritanceGetterAndMethod() {
    Source source = addSource(r'''
abstract class A {
  int x();
}
abstract class B {
  int get x;
}
class C implements A, B {
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.INCONSISTENT_METHOD_INHERITANCE_GETTER_AND_METHOD]);
    verify([source]);
  }

  void test_instanceMethodNameCollidesWithSuperclassStatic_field() {
    Source source = addSource(r'''
class A {
  static var n;
}
class B extends A {
  void n() {}
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.INSTANCE_METHOD_NAME_COLLIDES_WITH_SUPERCLASS_STATIC]);
    verify([source]);
  }

  void test_instanceMethodNameCollidesWithSuperclassStatic_field2() {
    Source source = addSource(r'''
class A {
  static var n;
}
class B extends A {
}
class C extends B {
  void n() {}
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.INSTANCE_METHOD_NAME_COLLIDES_WITH_SUPERCLASS_STATIC]);
    verify([source]);
  }

  void test_instanceMethodNameCollidesWithSuperclassStatic_getter() {
    Source source = addSource(r'''
class A {
  static get n {return 0;}
}
class B extends A {
  void n() {}
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.INSTANCE_METHOD_NAME_COLLIDES_WITH_SUPERCLASS_STATIC]);
    verify([source]);
  }

  void test_instanceMethodNameCollidesWithSuperclassStatic_getter2() {
    Source source = addSource(r'''
class A {
  static get n {return 0;}
}
class B extends A {
}
class C extends B {
  void n() {}
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.INSTANCE_METHOD_NAME_COLLIDES_WITH_SUPERCLASS_STATIC]);
    verify([source]);
  }

  void test_instanceMethodNameCollidesWithSuperclassStatic_interface() {
    Source source = addSource(r'''
class Base {
  static foo() {}
}
abstract class Ifc {
  foo();
}
class C extends Base implements Ifc {
  foo() {}
}
''');
    resolve(source);
    assertErrors(source, [
        StaticWarningCode.INSTANCE_METHOD_NAME_COLLIDES_WITH_SUPERCLASS_STATIC]);
    verify([source]);
  }

  void test_instanceMethodNameCollidesWithSuperclassStatic_method() {
    Source source = addSource(r'''
class A {
  static n () {}
}
class B extends A {
  void n() {}
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.INSTANCE_METHOD_NAME_COLLIDES_WITH_SUPERCLASS_STATIC]);
    verify([source]);
  }

  void test_instanceMethodNameCollidesWithSuperclassStatic_method2() {
    Source source = addSource(r'''
class A {
  static n () {}
}
class B extends A {
}
class C extends B {
  void n() {}
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.INSTANCE_METHOD_NAME_COLLIDES_WITH_SUPERCLASS_STATIC]);
    verify([source]);
  }

  void test_instanceMethodNameCollidesWithSuperclassStatic_setter() {
    Source source = addSource(r'''
class A {
  static set n(int x) {}
}
class B extends A {
  void n() {}
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.INSTANCE_METHOD_NAME_COLLIDES_WITH_SUPERCLASS_STATIC]);
    verify([source]);
  }

  void test_instanceMethodNameCollidesWithSuperclassStatic_setter2() {
    Source source = addSource(r'''
class A {
  static set n(int x) {}
}
class B extends A {
}
class C extends B {
  void n() {}
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.INSTANCE_METHOD_NAME_COLLIDES_WITH_SUPERCLASS_STATIC]);
    verify([source]);
  }

  void test_invalidGetterOverrideReturnType() {
    Source source = addSource(r'''
class A {
  int get g { return 0; }
}
class B extends A {
  String get g { return 'a'; }
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.INVALID_GETTER_OVERRIDE_RETURN_TYPE]);
    verify([source]);
  }

  void test_invalidGetterOverrideReturnType_implicit() {
    Source source = addSource(r'''
class A {
  String f;
}
class B extends A {
  int f;
}''');
    resolve(source);
    assertErrors(source, [
        StaticWarningCode.INVALID_GETTER_OVERRIDE_RETURN_TYPE,
        StaticWarningCode.INVALID_SETTER_OVERRIDE_NORMAL_PARAM_TYPE]);
    verify([source]);
  }

  void test_invalidGetterOverrideReturnType_twoInterfaces() {
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
    resolve(source);
    assertErrors(source, [StaticWarningCode.INVALID_GETTER_OVERRIDE_RETURN_TYPE]);
    verify([source]);
  }

  void test_invalidGetterOverrideReturnType_twoInterfaces_conflicting() {
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
    resolve(source);
    assertErrors(source, [StaticWarningCode.INVALID_GETTER_OVERRIDE_RETURN_TYPE]);
    verify([source]);
  }

  void test_invalidMethodOverrideNamedParamType() {
    Source source = addSource(r'''
class A {
  m({int a}) {}
}
class B implements A {
  m({String a}) {}
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.INVALID_METHOD_OVERRIDE_NAMED_PARAM_TYPE]);
    verify([source]);
  }

  void test_invalidMethodOverrideNormalParamType_interface() {
    Source source = addSource(r'''
class A {
  m(int a) {}
}
class B implements A {
  m(String a) {}
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.INVALID_METHOD_OVERRIDE_NORMAL_PARAM_TYPE]);
    verify([source]);
  }

  void test_invalidMethodOverrideNormalParamType_superclass() {
    Source source = addSource(r'''
class A {
  m(int a) {}
}
class B extends A {
  m(String a) {}
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.INVALID_METHOD_OVERRIDE_NORMAL_PARAM_TYPE]);
    verify([source]);
  }

  void test_invalidMethodOverrideNormalParamType_superclass_interface() {
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
    resolve(source);
    assertErrors(source, [StaticWarningCode.INVALID_METHOD_OVERRIDE_NORMAL_PARAM_TYPE]);
    verify([source]);
  }

  void test_invalidMethodOverrideNormalParamType_twoInterfaces() {
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
    resolve(source);
    assertErrors(source, [StaticWarningCode.INVALID_METHOD_OVERRIDE_NORMAL_PARAM_TYPE]);
    verify([source]);
  }

  void test_invalidMethodOverrideNormalParamType_twoInterfaces_conflicting() {
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
    resolve(source);
    assertErrors(source, [StaticWarningCode.INVALID_METHOD_OVERRIDE_NORMAL_PARAM_TYPE]);
    verify([source]);
  }

  void test_invalidMethodOverrideOptionalParamType() {
    Source source = addSource(r'''
class A {
  m([int a]) {}
}
class B implements A {
  m([String a]) {}
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.INVALID_METHOD_OVERRIDE_OPTIONAL_PARAM_TYPE]);
    verify([source]);
  }

  void test_invalidMethodOverrideOptionalParamType_twoInterfaces() {
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
    resolve(source);
    assertErrors(source, [StaticWarningCode.INVALID_METHOD_OVERRIDE_OPTIONAL_PARAM_TYPE]);
    verify([source]);
  }

  void test_invalidMethodOverrideReturnType_interface() {
    Source source = addSource(r'''
class A {
  int m() { return 0; }
}
class B implements A {
  String m() { return 'a'; }
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.INVALID_METHOD_OVERRIDE_RETURN_TYPE]);
    verify([source]);
  }

  void test_invalidMethodOverrideReturnType_interface_grandparent() {
    Source source = addSource(r'''
abstract class A {
  int m();
}
abstract class B implements A {
}
class C implements B {
  String m() { return 'a'; }
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.INVALID_METHOD_OVERRIDE_RETURN_TYPE]);
    verify([source]);
  }

  void test_invalidMethodOverrideReturnType_mixin() {
    Source source = addSource(r'''
class A {
  int m() { return 0; }
}
class B extends Object with A {
  String m() { return 'a'; }
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.INVALID_METHOD_OVERRIDE_RETURN_TYPE]);
    verify([source]);
  }

  void test_invalidMethodOverrideReturnType_superclass() {
    Source source = addSource(r'''
class A {
  int m() { return 0; }
}
class B extends A {
  String m() { return 'a'; }
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.INVALID_METHOD_OVERRIDE_RETURN_TYPE]);
    verify([source]);
  }

  void test_invalidMethodOverrideReturnType_superclass_grandparent() {
    Source source = addSource(r'''
class A {
  int m() { return 0; }
}
class B extends A {
}
class C extends B {
  String m() { return 'a'; }
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.INVALID_METHOD_OVERRIDE_RETURN_TYPE]);
    verify([source]);
  }

  void test_invalidMethodOverrideReturnType_twoInterfaces() {
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
    resolve(source);
    assertErrors(source, [StaticWarningCode.INVALID_METHOD_OVERRIDE_RETURN_TYPE]);
    verify([source]);
  }

  void test_invalidMethodOverrideReturnType_void() {
    Source source = addSource(r'''
class A {
  int m() { return 0; }
}
class B extends A {
  void m() {}
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.INVALID_METHOD_OVERRIDE_RETURN_TYPE]);
    verify([source]);
  }

  void test_invalidOverride_defaultOverridesNonDefault() {
    // If the base class provided an explicit value for a default parameter,
    // then it is a static warning for the derived class to provide a different
    // value, even if implicitly.
    Source source = addSource(r'''
class A {
  foo([x = 1]) {}
}
class B extends A {
  foo([x]) {}
}
''');
    resolve(source);
    assertErrors(source, [
        StaticWarningCode.INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_POSITIONAL]);
    verify([source]);
  }

  void test_invalidOverride_defaultOverridesNonDefault_named() {
    // If the base class provided an explicit value for a default parameter,
    // then it is a static warning for the derived class to provide a different
    // value, even if implicitly.
    Source source = addSource(r'''
class A {
  foo({x: 1}) {}
}
class B extends A {
  foo({x}) {}
}
''');
    resolve(source);
    assertErrors(source, [
        StaticWarningCode.INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_NAMED]);
    verify([source]);
  }

  void test_invalidOverride_defaultOverridesNonDefaultNull() {
    // If the base class provided an explicit null value for a default
    // parameter, then it is ok for the derived class to let the default value
    // be implicit, because the implicit default value of null matches the
    // explicit default value of null.
    Source source = addSource(r'''
class A {
  foo([x = null]) {}
}
class B extends A {
  foo([x]) {}
}
''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invalidOverride_defaultOverridesNonDefaultNull_named() {
    // If the base class provided an explicit null value for a default
    // parameter, then it is ok for the derived class to let the default value
    // be implicit, because the implicit default value of null matches the
    // explicit default value of null.
    Source source = addSource(r'''
class A {
  foo({x: null}) {}
}
class B extends A {
  foo({x}) {}
}
''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invalidOverride_nonDefaultOverridesDefault() {
    // If the base class lets the default parameter be implicit, then it is ok
    // for the derived class to provide an explicit default value, even if it's
    // not null.
    Source source = addSource(r'''
class A {
  foo([x]) {}
}
class B extends A {
  foo([x = 1]) {}
}
''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invalidOverride_nonDefaultOverridesDefault_named() {
    // If the base class lets the default parameter be implicit, then it is ok
    // for the derived class to provide an explicit default value, even if it's
    // not null.
    Source source = addSource(r'''
class A {
  foo({x}) {}
}
class B extends A {
  foo({x: 1}) {}
}
''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invalidOverrideDifferentDefaultValues_named() {
    Source source = addSource(r'''
class A {
  m({int p : 0}) {}
}
class B extends A {
  m({int p : 1}) {}
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_NAMED]);
    verify([source]);
  }

  void test_invalidOverrideDifferentDefaultValues_positional() {
    Source source = addSource(r'''
class A {
  m([int p = 0]) {}
}
class B extends A {
  m([int p = 1]) {}
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_POSITIONAL]);
    verify([source]);
  }

  void test_invalidOverrideNamed_fewerNamedParameters() {
    Source source = addSource(r'''
class A {
  m({a, b}) {}
}
class B extends A {
  m({a}) {}
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.INVALID_OVERRIDE_NAMED]);
    verify([source]);
  }

  void test_invalidOverrideNamed_missingNamedParameter() {
    Source source = addSource(r'''
class A {
  m({a, b}) {}
}
class B extends A {
  m({a, c}) {}
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.INVALID_OVERRIDE_NAMED]);
    verify([source]);
  }

  void test_invalidOverridePositional_optional() {
    Source source = addSource(r'''
class A {
  m([a, b]) {}
}
class B extends A {
  m([a]) {}
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.INVALID_OVERRIDE_POSITIONAL]);
    verify([source]);
  }

  void test_invalidOverridePositional_optionalAndRequired() {
    Source source = addSource(r'''
class A {
  m(a, b, [c, d]) {}
}
class B extends A {
  m(a, b, [c]) {}
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.INVALID_OVERRIDE_POSITIONAL]);
    verify([source]);
  }

  void test_invalidOverridePositional_optionalAndRequired2() {
    Source source = addSource(r'''
class A {
  m(a, b, [c, d]) {}
}
class B extends A {
  m(a, [c, d]) {}
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.INVALID_OVERRIDE_POSITIONAL]);
    verify([source]);
  }

  void test_invalidOverrideRequired() {
    Source source = addSource(r'''
class A {
  m(a) {}
}
class B extends A {
  m(a, b) {}
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.INVALID_OVERRIDE_REQUIRED]);
    verify([source]);
  }

  void test_invalidSetterOverrideNormalParamType() {
    Source source = addSource(r'''
class A {
  void set s(int v) {}
}
class B extends A {
  void set s(String v) {}
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.INVALID_SETTER_OVERRIDE_NORMAL_PARAM_TYPE]);
    verify([source]);
  }

  void test_invalidSetterOverrideNormalParamType_superclass_interface() {
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
    resolve(source);
    assertErrors(source, [StaticWarningCode.INVALID_SETTER_OVERRIDE_NORMAL_PARAM_TYPE]);
    verify([source]);
  }

  void test_invalidSetterOverrideNormalParamType_twoInterfaces() {
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
    resolve(source);
    assertErrors(source, [StaticWarningCode.INVALID_SETTER_OVERRIDE_NORMAL_PARAM_TYPE]);
    verify([source]);
  }

  void test_invalidSetterOverrideNormalParamType_twoInterfaces_conflicting() {
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
    resolve(source);
    assertErrors(source, [StaticWarningCode.INVALID_SETTER_OVERRIDE_NORMAL_PARAM_TYPE]);
    verify([source]);
  }

  void test_listElementTypeNotAssignable() {
    Source source = addSource("var v = <String> [42];");
    resolve(source);
    assertErrors(source, [StaticWarningCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  void test_mapKeyTypeNotAssignable() {
    Source source = addSource("var v = <String, int > {1 : 2};");
    resolve(source);
    assertErrors(source, [StaticWarningCode.MAP_KEY_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  void test_mapValueTypeNotAssignable() {
    Source source = addSource("var v = <String, String> {'a' : 2};");
    resolve(source);
    assertErrors(source, [StaticWarningCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  void test_mismatchedAccessorTypes_class() {
    Source source = addSource(r'''
class A {
  int get g { return 0; }
  set g(String v) {}
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.MISMATCHED_GETTER_AND_SETTER_TYPES]);
    verify([source]);
  }

  void test_mismatchedAccessorTypes_getterAndSuperSetter() {
    Source source = addSource(r'''
class A {
  int get g { return 0; }
}
class B extends A {
  set g(String v) {}
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.MISMATCHED_GETTER_AND_SETTER_TYPES_FROM_SUPERTYPE]);
    verify([source]);
  }

  void test_mismatchedAccessorTypes_setterAndSuperGetter() {
    Source source = addSource(r'''
class A {
  set g(int v) {}
}
class B extends A {
  String get g { return ''; }
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.MISMATCHED_GETTER_AND_SETTER_TYPES_FROM_SUPERTYPE]);
    verify([source]);
  }

  void test_mismatchedAccessorTypes_topLevel() {
    Source source = addSource(r'''
int get g { return 0; }
set g(String v) {}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.MISMATCHED_GETTER_AND_SETTER_TYPES]);
    verify([source]);
  }

  void test_mixedReturnTypes_localFunction() {
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
    resolve(source);
    assertErrors(source, [
        StaticWarningCode.MIXED_RETURN_TYPES,
        StaticWarningCode.MIXED_RETURN_TYPES]);
    verify([source]);
  }

  void test_mixedReturnTypes_method() {
    Source source = addSource(r'''
class C {
  m(int x) {
    if (x < 0) {
      return;
    }
    return 0;
  }
}''');
    resolve(source);
    assertErrors(source, [
        StaticWarningCode.MIXED_RETURN_TYPES,
        StaticWarningCode.MIXED_RETURN_TYPES]);
    verify([source]);
  }

  void test_mixedReturnTypes_topLevelFunction() {
    Source source = addSource(r'''
f(int x) {
  if (x < 0) {
    return;
  }
  return 0;
}''');
    resolve(source);
    assertErrors(source, [
        StaticWarningCode.MIXED_RETURN_TYPES,
        StaticWarningCode.MIXED_RETURN_TYPES]);
    verify([source]);
  }

  void test_newWithAbstractClass() {
    Source source = addSource(r'''
abstract class A {}
void f() {
  A a = new A();
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.NEW_WITH_ABSTRACT_CLASS]);
    verify([source]);
  }

  void test_newWithInvalidTypeParameters() {
    Source source = addSource(r'''
class A {}
f() { return new A<A>(); }''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.NEW_WITH_INVALID_TYPE_PARAMETERS]);
    verify([source]);
  }

  void test_newWithInvalidTypeParameters_tooFew() {
    Source source = addSource(r'''
class A {}
class C<K, V> {}
f(p) {
  return new C<A>();
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.NEW_WITH_INVALID_TYPE_PARAMETERS]);
    verify([source]);
  }

  void test_newWithInvalidTypeParameters_tooMany() {
    Source source = addSource(r'''
class A {}
class C<E> {}
f(p) {
  return new C<A, A>();
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.NEW_WITH_INVALID_TYPE_PARAMETERS]);
    verify([source]);
  }

  void test_newWithNonType() {
    Source source = addSource(r'''
var A = 0;
void f() {
  var a = new A();
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.NEW_WITH_NON_TYPE]);
    verify([source]);
  }

  void test_newWithNonType_fromLibrary() {
    Source source1 = addNamedSource("lib.dart", "class B {}");
    Source source2 = addNamedSource("lib2.dart", r'''
import 'lib.dart' as lib;
void f() {
  var a = new lib.A();
}
lib.B b;''');
    resolve(source1);
    resolve(source2);
    assertErrors(source2, [StaticWarningCode.NEW_WITH_NON_TYPE]);
    verify([source1]);
  }

  void test_newWithUndefinedConstructor() {
    Source source = addSource(r'''
class A {
  A() {}
}
f() {
  new A.name();
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.NEW_WITH_UNDEFINED_CONSTRUCTOR]);
    // no verify(), 'name' is not resolved
  }

  void test_newWithUndefinedConstructorDefault() {
    Source source = addSource(r'''
class A {
  A.name() {}
}
f() {
  new A();
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.NEW_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT]);
    verify([source]);
  }

  void test_nonAbstractClassInheritsAbstractMemberFivePlus() {
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
    resolve(source);
    assertErrors(source, [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FIVE_PLUS]);
    verify([source]);
  }

  void test_nonAbstractClassInheritsAbstractMemberFour() {
    Source source = addSource(r'''
abstract class A {
  m();
  n();
  o();
  p();
}
class C extends A {
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FOUR]);
    verify([source]);
  }

  void test_nonAbstractClassInheritsAbstractMemberOne_classTypeAlias_interface() {
    // 15979
    Source source = addSource(r'''
abstract class M {}
abstract class A {}
abstract class I {
  m();
}
class B = A with M implements I;''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE]);
    verify([source]);
  }

  void test_nonAbstractClassInheritsAbstractMemberOne_classTypeAlias_mixin() {
    // 15979
    Source source = addSource(r'''
abstract class M {
  m();
}
abstract class A {}
class B = A with M;''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE]);
    verify([source]);
  }

  void test_nonAbstractClassInheritsAbstractMemberOne_classTypeAlias_superclass() {
    // 15979
    Source source = addSource(r'''
class M {}
abstract class A {
  m();
}
class B = A with M;''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE]);
    verify([source]);
  }

  void test_nonAbstractClassInheritsAbstractMemberOne_ensureCorrectFunctionSubtypeIsUsedInImplementation() {
    // 15028
    Source source = addSource(r'''
class C {
  foo(int x) => x;
}
abstract class D {
  foo(x, [y]);
}
class E extends C implements D {}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE]);
    verify([source]);
  }

  void test_nonAbstractClassInheritsAbstractMemberOne_getter_fromInterface() {
    Source source = addSource(r'''
class I {
  int get g {return 1;}
}
class C implements I {
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE]);
    verify([source]);
  }

  void test_nonAbstractClassInheritsAbstractMemberOne_getter_fromSuperclass() {
    Source source = addSource(r'''
abstract class A {
  int get g;
}
class C extends A {
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE]);
    verify([source]);
  }

  void test_nonAbstractClassInheritsAbstractMemberOne_method_fromInterface() {
    Source source = addSource(r'''
class I {
  m(p) {}
}
class C implements I {
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE]);
    verify([source]);
  }

  void test_nonAbstractClassInheritsAbstractMemberOne_method_fromSuperclass() {
    Source source = addSource(r'''
abstract class A {
  m(p);
}
class C extends A {
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE]);
    verify([source]);
  }

  void test_nonAbstractClassInheritsAbstractMemberOne_method_optionalParamCount() {
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
    resolve(source);
    assertErrors(source, [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE]);
    verify([source]);
  }

  void test_nonAbstractClassInheritsAbstractMemberOne_mixinInherits_getter() {
    // 15001
    Source source = addSource(r'''
abstract class A { get g1; get g2; }
abstract class B implements A { get g1 => 1; }
class C extends Object with B {}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE]);
  }

  void test_nonAbstractClassInheritsAbstractMemberOne_mixinInherits_method() {
    // 15001
    Source source = addSource(r'''
abstract class A { m1(); m2(); }
abstract class B implements A { m1() => 1; }
class C extends Object with B {}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE]);
  }

  void test_nonAbstractClassInheritsAbstractMemberOne_mixinInherits_setter() {
    // 15001
    Source source = addSource(r'''
abstract class A { set s1(v); set s2(v); }
abstract class B implements A { set s1(v) {} }
class C extends Object with B {}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE]);
  }

  void test_nonAbstractClassInheritsAbstractMemberOne_setter_and_implicitSetter() {
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
    resolve(source);
    assertErrors(source, [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE]);
    verify([source]);
  }

  void test_nonAbstractClassInheritsAbstractMemberOne_setter_fromInterface() {
    Source source = addSource(r'''
class I {
  set s(int i) {}
}
class C implements I {
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE]);
    verify([source]);
  }

  void test_nonAbstractClassInheritsAbstractMemberOne_setter_fromSuperclass() {
    Source source = addSource(r'''
abstract class A {
  set s(int i);
}
class C extends A {
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE]);
    verify([source]);
  }

  void test_nonAbstractClassInheritsAbstractMemberOne_superclasses_interface() {
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
    resolve(source);
    assertErrors(source, [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE]);
    verify([source]);
  }

  void test_nonAbstractClassInheritsAbstractMemberOne_variable_fromInterface_missingGetter() {
    // 16133
    Source source = addSource(r'''
class I {
  var v;
}
class C implements I {
  set v(_) {}
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE]);
    verify([source]);
  }

  void test_nonAbstractClassInheritsAbstractMemberOne_variable_fromInterface_missingSetter() {
    // 16133
    Source source = addSource(r'''
class I {
  var v;
}
class C implements I {
  get v => 1;
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE]);
    verify([source]);
  }

  void test_nonAbstractClassInheritsAbstractMemberThree() {
    Source source = addSource(r'''
abstract class A {
  m();
  n();
  o();
}
class C extends A {
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_THREE]);
    verify([source]);
  }

  void test_nonAbstractClassInheritsAbstractMemberTwo() {
    Source source = addSource(r'''
abstract class A {
  m();
  n();
}
class C extends A {
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_TWO]);
    verify([source]);
  }

  void test_nonAbstractClassInheritsAbstractMemberTwo_variable_fromInterface_missingBoth() {
    // 16133
    Source source = addSource(r'''
class I {
  var v;
}
class C implements I {
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_TWO]);
    verify([source]);
  }

  void test_nonTypeInCatchClause_noElement() {
    Source source = addSource(r'''
f() {
  try {
  } on T catch (e) {
  }
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.NON_TYPE_IN_CATCH_CLAUSE]);
    verify([source]);
  }

  void test_nonTypeInCatchClause_notType() {
    Source source = addSource(r'''
var T = 0;
f() {
  try {
  } on T catch (e) {
  }
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.NON_TYPE_IN_CATCH_CLAUSE]);
    verify([source]);
  }

  void test_nonVoidReturnForOperator() {
    Source source = addSource(r'''
class A {
  int operator []=(a, b) { return a; }
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.NON_VOID_RETURN_FOR_OPERATOR]);
    verify([source]);
  }

  void test_nonVoidReturnForSetter_function() {
    Source source = addSource(r'''
int set x(int v) {
  return 42;
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.NON_VOID_RETURN_FOR_SETTER]);
    verify([source]);
  }

  void test_nonVoidReturnForSetter_method() {
    Source source = addSource(r'''
class A {
  int set x(int v) {
    return 42;
  }
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.NON_VOID_RETURN_FOR_SETTER]);
    verify([source]);
  }

  void test_notAType() {
    Source source = addSource(r'''
f() {}
main() {
  f v = null;
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.NOT_A_TYPE]);
    verify([source]);
  }

  void test_notEnoughRequiredArguments() {
    Source source = addSource(r'''
f(int a, String b) {}
main() {
  f();
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.NOT_ENOUGH_REQUIRED_ARGUMENTS]);
    verify([source]);
  }

  void test_notEnoughRequiredArguments_functionExpression() {
    Source source = addSource(r'''
main() {
  (int x) {} ();
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.NOT_ENOUGH_REQUIRED_ARGUMENTS]);
    verify([source]);
  }

  void test_notEnoughRequiredArguments_getterReturningFunction() {
    Source source = addSource(r'''
typedef Getter(self);
Getter getter = (x) => x;
main() {
  getter();
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.NOT_ENOUGH_REQUIRED_ARGUMENTS]);
    verify([source]);
  }

  void test_partOfDifferentLibrary() {
    Source source = addSource(r'''
library lib;
part 'part.dart';''');
    addNamedSource("/part.dart", "part of lub;");
    resolve(source);
    assertErrors(source, [StaticWarningCode.PART_OF_DIFFERENT_LIBRARY]);
    verify([source]);
  }

  void test_redirectToInvalidFunctionType() {
    Source source = addSource(r'''
class A implements B {
  A(int p) {}
}
class B {
  factory B() = A;
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.REDIRECT_TO_INVALID_FUNCTION_TYPE]);
    verify([source]);
  }

  void test_redirectToInvalidReturnType() {
    Source source = addSource(r'''
class A {
  A() {}
}
class B {
  factory B() = A;
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.REDIRECT_TO_INVALID_RETURN_TYPE]);
    verify([source]);
  }

  void test_redirectToMissingConstructor_named() {
    Source source = addSource(r'''
class A implements B{
  A() {}
}
class B {
  factory B() = A.name;
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.REDIRECT_TO_MISSING_CONSTRUCTOR]);
  }

  void test_redirectToMissingConstructor_unnamed() {
    Source source = addSource(r'''
class A implements B{
  A.name() {}
}
class B {
  factory B() = A;
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.REDIRECT_TO_MISSING_CONSTRUCTOR]);
  }

  void test_redirectToNonClass_notAType() {
    Source source = addSource(r'''
class B {
  int A;
  factory B() = A;
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.REDIRECT_TO_NON_CLASS]);
    verify([source]);
  }

  void test_redirectToNonClass_undefinedIdentifier() {
    Source source = addSource(r'''
class B {
  factory B() = A;
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.REDIRECT_TO_NON_CLASS]);
    verify([source]);
  }

  void test_returnWithoutValue_factoryConstructor() {
    Source source = addSource("class A { factory A() { return; } }");
    resolve(source);
    assertErrors(source, [StaticWarningCode.RETURN_WITHOUT_VALUE]);
    verify([source]);
  }

  void test_returnWithoutValue_function() {
    Source source = addSource("int f() { return; }");
    resolve(source);
    assertErrors(source, [StaticWarningCode.RETURN_WITHOUT_VALUE]);
    verify([source]);
  }

  void test_returnWithoutValue_method() {
    Source source = addSource("class A { int m() { return; } }");
    resolve(source);
    assertErrors(source, [StaticWarningCode.RETURN_WITHOUT_VALUE]);
    verify([source]);
  }

  void test_returnWithoutValue_mixedReturnTypes_function() {
    // Tests that only the RETURN_WITHOUT_VALUE warning is created, and no MIXED_RETURN_TYPES are
    // created.
    Source source = addSource(r'''
int f(int x) {
  if (x < 0) {
    return 1;
  }
  return;
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.RETURN_WITHOUT_VALUE]);
    verify([source]);
  }

  void test_staticAccessToInstanceMember_method_invocation() {
    Source source = addSource(r'''
class A {
  m() {}
}
main() {
  A.m();
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.STATIC_ACCESS_TO_INSTANCE_MEMBER]);
    verify([source]);
  }

  void test_staticAccessToInstanceMember_method_reference() {
    Source source = addSource(r'''
class A {
  m() {}
}
main() {
  A.m;
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.STATIC_ACCESS_TO_INSTANCE_MEMBER]);
    verify([source]);
  }

  void test_staticAccessToInstanceMember_propertyAccess_field() {
    Source source = addSource(r'''
class A {
  var f;
}
main() {
  A.f;
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.STATIC_ACCESS_TO_INSTANCE_MEMBER]);
    verify([source]);
  }

  void test_staticAccessToInstanceMember_propertyAccess_getter() {
    Source source = addSource(r'''
class A {
  get f => 42;
}
main() {
  A.f;
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.STATIC_ACCESS_TO_INSTANCE_MEMBER]);
    verify([source]);
  }

  void test_staticAccessToInstanceMember_propertyAccess_setter() {
    Source source = addSource(r'''
class A {
  set f(x) {}
}
main() {
  A.f = 42;
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.STATIC_ACCESS_TO_INSTANCE_MEMBER]);
    verify([source]);
  }

  void test_switchExpressionNotAssignable() {
    Source source = addSource(r'''
f(int p) {
  switch (p) {
    case 'a': break;
  }
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.SWITCH_EXPRESSION_NOT_ASSIGNABLE]);
    verify([source]);
  }

  void test_typeAnnotationDeferredClass_asExpression() {
    resolveWithAndWithoutExperimental(<String> [
        r'''
library lib1;
class A {}''',
        r'''
library root;
import 'lib1.dart' deferred as a;
f(var v) {
  v as a.A;
}'''], <ErrorCode> [ParserErrorCode.DEFERRED_IMPORTS_NOT_SUPPORTED], <ErrorCode> [StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS]);
  }

  void test_typeAnnotationDeferredClass_catchClause() {
    resolveWithAndWithoutExperimental(<String> [
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
}'''], <ErrorCode> [ParserErrorCode.DEFERRED_IMPORTS_NOT_SUPPORTED], <ErrorCode> [StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS]);
  }

  void test_typeAnnotationDeferredClass_fieldFormalParameter() {
    resolveWithAndWithoutExperimental(<String> [
        r'''
library lib1;
class A {}''',
        r'''
library root;
import 'lib1.dart' deferred as a;
class C {
  var v;
  C(a.A this.v);
}'''], <ErrorCode> [ParserErrorCode.DEFERRED_IMPORTS_NOT_SUPPORTED], <ErrorCode> [StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS]);
  }

  void test_typeAnnotationDeferredClass_functionDeclaration_returnType() {
    resolveWithAndWithoutExperimental(<String> [
        r'''
library lib1;
class A {}''',
        r'''
library root;
import 'lib1.dart' deferred as a;
a.A f() { return null; }'''], <ErrorCode> [ParserErrorCode.DEFERRED_IMPORTS_NOT_SUPPORTED], <ErrorCode> [StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS]);
  }

  void test_typeAnnotationDeferredClass_functionTypedFormalParameter_returnType() {
    resolveWithAndWithoutExperimental(<String> [
        r'''
library lib1;
class A {}''',
        r'''
library root;
import 'lib1.dart' deferred as a;
f(a.A g()) {}'''], <ErrorCode> [ParserErrorCode.DEFERRED_IMPORTS_NOT_SUPPORTED], <ErrorCode> [StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS]);
  }

  void test_typeAnnotationDeferredClass_isExpression() {
    resolveWithAndWithoutExperimental(<String> [
        r'''
library lib1;
class A {}''',
        r'''
library root;
import 'lib1.dart' deferred as a;
f(var v) {
  bool b = v is a.A;
}'''], <ErrorCode> [ParserErrorCode.DEFERRED_IMPORTS_NOT_SUPPORTED], <ErrorCode> [StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS]);
  }

  void test_typeAnnotationDeferredClass_methodDeclaration_returnType() {
    resolveWithAndWithoutExperimental(<String> [
        r'''
library lib1;
class A {}''',
        r'''
library root;
import 'lib1.dart' deferred as a;
class C {
  a.A m() { return null; }
}'''], <ErrorCode> [ParserErrorCode.DEFERRED_IMPORTS_NOT_SUPPORTED], <ErrorCode> [StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS]);
  }

  void test_typeAnnotationDeferredClass_simpleFormalParameter() {
    resolveWithAndWithoutExperimental(<String> [
        r'''
library lib1;
class A {}''',
        r'''
library root;
import 'lib1.dart' deferred as a;
f(a.A v) {}'''], <ErrorCode> [ParserErrorCode.DEFERRED_IMPORTS_NOT_SUPPORTED], <ErrorCode> [StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS]);
  }

  void test_typeAnnotationDeferredClass_typeArgumentList() {
    resolveWithAndWithoutExperimental(<String> [
        r'''
library lib1;
class A {}''',
        r'''
library root;
import 'lib1.dart' deferred as a;
class C<E> {}
C<a.A> c;'''], <ErrorCode> [ParserErrorCode.DEFERRED_IMPORTS_NOT_SUPPORTED], <ErrorCode> [StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS]);
  }

  void test_typeAnnotationDeferredClass_typeArgumentList2() {
    resolveWithAndWithoutExperimental(<String> [
        r'''
library lib1;
class A {}''',
        r'''
library root;
import 'lib1.dart' deferred as a;
class C<E, F> {}
C<a.A, a.A> c;'''], <ErrorCode> [ParserErrorCode.DEFERRED_IMPORTS_NOT_SUPPORTED], <ErrorCode> [
        StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS,
        StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS]);
  }

  void test_typeAnnotationDeferredClass_typeParameter_bound() {
    resolveWithAndWithoutExperimental(<String> [
        r'''
library lib1;
class A {}''',
        r'''
library root;
import 'lib1.dart' deferred as a;
class C<E extends a.A> {}'''], <ErrorCode> [ParserErrorCode.DEFERRED_IMPORTS_NOT_SUPPORTED], <ErrorCode> [StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS]);
  }

  void test_typeAnnotationDeferredClass_variableDeclarationList() {
    resolveWithAndWithoutExperimental(<String> [
        r'''
library lib1;
class A {}''',
        r'''
library root;
import 'lib1.dart' deferred as a;
a.A v;'''], <ErrorCode> [ParserErrorCode.DEFERRED_IMPORTS_NOT_SUPPORTED], <ErrorCode> [StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS]);
  }

  void test_typeParameterReferencedByStatic_field() {
    Source source = addSource(r'''
class A<K> {
  static K k;
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.TYPE_PARAMETER_REFERENCED_BY_STATIC]);
    verify([source]);
  }

  void test_typeParameterReferencedByStatic_getter() {
    Source source = addSource(r'''
class A<K> {
  static K get k => null;
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.TYPE_PARAMETER_REFERENCED_BY_STATIC]);
    verify([source]);
  }

  void test_typeParameterReferencedByStatic_methodBodyReference() {
    Source source = addSource(r'''
class A<K> {
  static m() {
    K k;
  }
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.TYPE_PARAMETER_REFERENCED_BY_STATIC]);
    verify([source]);
  }

  void test_typeParameterReferencedByStatic_methodParameter() {
    Source source = addSource(r'''
class A<K> {
  static m(K k) {}
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.TYPE_PARAMETER_REFERENCED_BY_STATIC]);
    verify([source]);
  }

  void test_typeParameterReferencedByStatic_methodReturn() {
    Source source = addSource(r'''
class A<K> {
  static K m() { return null; }
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.TYPE_PARAMETER_REFERENCED_BY_STATIC]);
    verify([source]);
  }

  void test_typeParameterReferencedByStatic_setter() {
    Source source = addSource(r'''
class A<K> {
  static set s(K k) {}
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.TYPE_PARAMETER_REFERENCED_BY_STATIC]);
    verify([source]);
  }

  void test_typePromotion_functionType_arg_InterToDyn() {
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
    resolve(source);
    assertErrors(source, [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
  }

  void test_typeTestNonType() {
    Source source = addSource(r'''
var A = 0;
f(var p) {
  if (p is A) {
  }
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.TYPE_TEST_NON_TYPE]);
    verify([source]);
  }

  void test_undefinedClass_instanceCreation() {
    Source source = addSource("f() { new C(); }");
    resolve(source);
    assertErrors(source, [StaticWarningCode.UNDEFINED_CLASS]);
  }

  void test_undefinedClass_variableDeclaration() {
    Source source = addSource("f() { C c; }");
    resolve(source);
    assertErrors(source, [StaticWarningCode.UNDEFINED_CLASS]);
  }

  void test_undefinedClassBoolean_variableDeclaration() {
    Source source = addSource("f() { boolean v; }");
    resolve(source);
    assertErrors(source, [StaticWarningCode.UNDEFINED_CLASS_BOOLEAN]);
  }

  void test_undefinedGetter_fromLibrary() {
    Source source1 = addNamedSource("lib.dart", "");
    Source source2 = addNamedSource("lib2.dart", r'''
import 'lib.dart' as lib;
void f() {
  var g = lib.gg;
}''');
    resolve(source1);
    resolve(source2);
    assertErrors(source2, [StaticWarningCode.UNDEFINED_GETTER]);
    verify([source1]);
  }

  void test_undefinedIdentifier_for() {
    Source source = addSource(r'''
f(var l) {
  for (e in l) {
  }
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.UNDEFINED_IDENTIFIER]);
  }

  void test_undefinedIdentifier_function() {
    Source source = addSource("int a() => b;");
    resolve(source);
    assertErrors(source, [StaticWarningCode.UNDEFINED_IDENTIFIER]);
  }

  void test_undefinedIdentifier_function_prefix() {
    addNamedSource("/lib.dart", r'''
library lib;
class C {}''');
    Source source = addSource(r'''
import 'lib.dart' as b;

int a() => b;
b.C c;''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.UNDEFINED_IDENTIFIER]);
    verify([source]);
  }

  void test_undefinedIdentifier_initializer() {
    Source source = addSource("var a = b;");
    resolve(source);
    assertErrors(source, [StaticWarningCode.UNDEFINED_IDENTIFIER]);
  }

  void test_undefinedIdentifier_initializer_prefix() {
    addNamedSource("/lib.dart", r'''
library lib;
class C {}''');
    Source source = addSource(r'''
import 'lib.dart' as b;

var a = b;
b.C c;''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.UNDEFINED_IDENTIFIER]);
  }

  void test_undefinedIdentifier_methodInvocation() {
    Source source = addSource("f() { C.m(); }");
    resolve(source);
    assertErrors(source, [StaticWarningCode.UNDEFINED_IDENTIFIER]);
  }

  void test_undefinedIdentifier_private_getter() {
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
    resolve(source);
    assertErrors(source, [StaticWarningCode.UNDEFINED_IDENTIFIER]);
  }

  void test_undefinedIdentifier_private_setter() {
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
    resolve(source);
    assertErrors(source, [StaticWarningCode.UNDEFINED_IDENTIFIER]);
  }

  void test_undefinedNamedParameter() {
    Source source = addSource(r'''
f({a, b}) {}
main() {
  f(c: 1);
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.UNDEFINED_NAMED_PARAMETER]);
    // no verify(), 'c' is not resolved
  }

  void test_undefinedSetter() {
    Source source1 = addNamedSource("lib.dart", "");
    Source source2 = addNamedSource("lib2.dart", r'''
import 'lib.dart' as lib;
void f() {
  lib.gg = null;
}''');
    resolve(source1);
    resolve(source2);
    assertErrors(source2, [StaticWarningCode.UNDEFINED_SETTER]);
  }

  void test_undefinedStaticMethodOrGetter_getter() {
    Source source = addSource(r'''
class C {}
f(var p) {
  f(C.m);
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_GETTER]);
  }

  void test_undefinedStaticMethodOrGetter_getter_inSuperclass() {
    Source source = addSource(r'''
class S {
  static int get g => 0;
}
class C extends S {}
f(var p) {
  f(C.g);
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_GETTER]);
  }

  void test_undefinedStaticMethodOrGetter_method() {
    Source source = addSource(r'''
class C {}
f(var p) {
  f(C.m());
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_METHOD]);
  }

  void test_undefinedStaticMethodOrGetter_method_inSuperclass() {
    Source source = addSource(r'''
class S {
  static m() {}
}
class C extends S {}
f(var p) {
  f(C.m());
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_METHOD]);
  }

  void test_undefinedStaticMethodOrGetter_setter_inSuperclass() {
    Source source = addSource(r'''
class S {
  static set s(int i) {}
}
class C extends S {}
f(var p) {
  f(C.s = 1);
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_SETTER]);
  }

  void test_voidReturnForGetter() {
    Source source = addSource(r'''
class S {
  void get value {}
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.VOID_RETURN_FOR_GETTER]);
  }
}

main() {
  groupSep = ' | ';
  runReflectiveTests(StaticWarningCodeTest);
}
