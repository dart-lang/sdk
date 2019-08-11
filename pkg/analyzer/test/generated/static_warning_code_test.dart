// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(StaticWarningCodeTest);
  });
}

@reflectiveTest
class StaticWarningCodeTest extends DriverResolutionTest {
  test_functionWithoutCall_direct() async {
    await assertNoErrorsInCode('''
class A implements Function {
}''');
  }

  test_functionWithoutCall_direct_typeAlias() async {
    await assertNoErrorsInCode('''
class M {}
class A = Object with M implements Function;''');
  }

  test_functionWithoutCall_indirect_extends() async {
    await assertNoErrorsInCode('''
abstract class A implements Function {
}
class B extends A {
}''');
  }

  test_functionWithoutCall_indirect_extends_typeAlias() async {
    await assertNoErrorsInCode('''
abstract class A implements Function {}
class M {}
class B = A with M;''');
  }

  test_functionWithoutCall_indirect_implements() async {
    await assertNoErrorsInCode('''
abstract class A implements Function {
}
class B implements A {
}''');
  }

  test_functionWithoutCall_indirect_implements_typeAlias() async {
    await assertNoErrorsInCode('''
abstract class A implements Function {}
class M {}
class B = Object with M implements A;''');
  }

  test_functionWithoutCall_mixin_implements() async {
    await assertNoErrorsInCode('''
abstract class A implements Function {}
class B extends Object with A {}''');
  }

  test_functionWithoutCall_mixin_implements_typeAlias() async {
    await assertNoErrorsInCode('''
abstract class A implements Function {}
class B = Object with A;''');
  }

  test_nonAbstractClassInheritsAbstractMemberOne_ensureCorrectFunctionSubtypeIsUsedInImplementation() async {
    // 15028
    await assertErrorsInCode('''
class C {
  foo(int x) => x;
}
abstract class D {
  foo(x, [y]);
}
class E extends C implements D {}''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 73, 1),
    ]);
  }

  test_staticAccessToInstanceMember_method_invocation() async {
    await assertErrorsInCode('''
class A {
  m() {}
}
main() {
  A.m();
}''', [
      error(StaticWarningCode.STATIC_ACCESS_TO_INSTANCE_MEMBER, 34, 1),
    ]);
  }

  test_staticAccessToInstanceMember_method_reference() async {
    await assertErrorsInCode('''
class A {
  m() {}
}
main() {
  A.m;
}''', [
      error(StaticWarningCode.STATIC_ACCESS_TO_INSTANCE_MEMBER, 34, 1),
    ]);
  }

  test_staticAccessToInstanceMember_propertyAccess_field() async {
    await assertErrorsInCode('''
class A {
  var f;
}
main() {
  A.f;
}''', [
      error(StaticWarningCode.STATIC_ACCESS_TO_INSTANCE_MEMBER, 34, 1),
    ]);
  }

  test_staticAccessToInstanceMember_propertyAccess_getter() async {
    await assertErrorsInCode('''
class A {
  get f => 42;
}
main() {
  A.f;
}''', [
      error(StaticWarningCode.STATIC_ACCESS_TO_INSTANCE_MEMBER, 40, 1),
    ]);
  }

  test_staticAccessToInstanceMember_propertyAccess_setter() async {
    await assertErrorsInCode('''
class A {
  set f(x) {}
}
main() {
  A.f = 42;
}''', [
      error(StaticWarningCode.STATIC_ACCESS_TO_INSTANCE_MEMBER, 39, 1),
    ]);
  }

  test_switchExpressionNotAssignable() async {
    await assertErrorsInCode('''
f(int p) {
  switch (p) {
    case 'a': break;
  }
}''', [
      error(StaticWarningCode.SWITCH_EXPRESSION_NOT_ASSIGNABLE, 21, 1),
    ]);
  }

  test_typeAnnotationDeferredClass_asExpression() async {
    newFile("/test/lib/lib1.dart", content: '''
library lib1;
class A {}''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
f(var v) {
  v as a.A;
}''', [
      error(StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS, 66, 3),
    ]);
  }

  test_typeAnnotationDeferredClass_catchClause() async {
    newFile("/test/lib/lib1.dart", content: '''
library lib1;
class A {}''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
f(var v) {
  try {
  } on a.A {
  }
}''', [
      error(StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS, 74, 3),
    ]);
  }

  test_typeAnnotationDeferredClass_fieldFormalParameter() async {
    newFile("/test/lib/lib1.dart", content: '''
library lib1;
class A {}''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
class C {
  var v;
  C(a.A this.v);
}''', [
      error(StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS, 71, 3),
    ]);
  }

  test_typeAnnotationDeferredClass_functionDeclaration_returnType() async {
    newFile("/test/lib/lib1.dart", content: '''
library lib1;
class A {}''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
a.A f() { return null; }''', [
      error(StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS, 48, 3),
    ]);
  }

  test_typeAnnotationDeferredClass_functionTypedFormalParameter_returnType() async {
    newFile("/test/lib/lib1.dart", content: '''
library lib1;
class A {}''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
f(a.A g()) {}''', [
      error(StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS, 50, 3),
    ]);
  }

  test_typeAnnotationDeferredClass_isExpression() async {
    newFile("/test/lib/lib1.dart", content: '''
library lib1;
class A {}''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
f(var v) {
  bool b = v is a.A;
}''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 66, 1),
      error(StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS, 75, 3),
    ]);
  }

  test_typeAnnotationDeferredClass_methodDeclaration_returnType() async {
    newFile("/test/lib/lib1.dart", content: '''
library lib1;
class A {}''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
class C {
  a.A m() { return null; }
}''', [
      error(StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS, 60, 3),
    ]);
  }

  test_typeAnnotationDeferredClass_simpleFormalParameter() async {
    newFile("/test/lib/lib1.dart", content: '''
library lib1;
class A {}''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
f(a.A v) {}''', [
      error(StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS, 50, 3),
    ]);
  }

  test_typeAnnotationDeferredClass_typeArgumentList() async {
    newFile("/test/lib/lib1.dart", content: '''
library lib1;
class A {}''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
class C<E> {}
C<a.A> c;''', [
      error(StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS, 64, 3),
    ]);
  }

  test_typeAnnotationDeferredClass_typeArgumentList2() async {
    newFile("/test/lib/lib1.dart", content: '''
library lib1;
class A {}''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
class C<E, F> {}
C<a.A, a.A> c;''', [
      error(StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS, 67, 3),
      error(StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS, 72, 3),
    ]);
  }

  test_typeAnnotationDeferredClass_typeParameter_bound() async {
    newFile("/test/lib/lib1.dart", content: '''
library lib1;
class A {}''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
class C<E extends a.A> {}''', [
      error(StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS, 66, 3),
    ]);
  }

  test_typeAnnotationDeferredClass_variableDeclarationList() async {
    newFile("/test/lib/lib1.dart", content: '''
library lib1;
class A {}''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
a.A v;''', [
      error(StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS, 48, 3),
    ]);
  }

  test_typeParameterReferencedByStatic_field() async {
    await assertErrorsInCode('''
class A<K> {
  static K k;
}''', [
      error(StaticWarningCode.TYPE_PARAMETER_REFERENCED_BY_STATIC, 22, 1),
    ]);
  }

  test_typeParameterReferencedByStatic_getter() async {
    await assertErrorsInCode('''
class A<K> {
  static K get k => null;
}''', [
      error(StaticWarningCode.TYPE_PARAMETER_REFERENCED_BY_STATIC, 22, 1),
    ]);
  }

  test_typeParameterReferencedByStatic_methodBodyReference() async {
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

  test_typeParameterReferencedByStatic_methodParameter() async {
    await assertErrorsInCode('''
class A<K> {
  static m(K k) {}
}''', [
      error(StaticWarningCode.TYPE_PARAMETER_REFERENCED_BY_STATIC, 24, 1),
    ]);
  }

  test_typeParameterReferencedByStatic_methodReturn() async {
    await assertErrorsInCode('''
class A<K> {
  static K m() { return null; }
}''', [
      error(StaticWarningCode.TYPE_PARAMETER_REFERENCED_BY_STATIC, 22, 1),
    ]);
  }

  test_typeParameterReferencedByStatic_setter() async {
    await assertErrorsInCode('''
class A<K> {
  static set s(K k) {}
}''', [
      error(StaticWarningCode.TYPE_PARAMETER_REFERENCED_BY_STATIC, 28, 1),
    ]);
  }

  test_typeParameterReferencedByStatic_simpleIdentifier() async {
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

  test_typePromotion_functionType_arg_InterToDyn() async {
    await assertNoErrorsInCode('''
typedef FuncDyn(x);
typedef FuncA(A a);
class A {}
class B {}
main(FuncA f) {
  if (f is FuncDyn) {
    f(new B());
  }
}''');
  }

  test_typeTestNonType() async {
    await assertErrorsInCode('''
var A = 0;
f(var p) {
  if (p is A) {
  }
}''', [
      error(StaticWarningCode.TYPE_TEST_WITH_NON_TYPE, 33, 1),
    ]);
  }

  test_typeTestWithUndefinedName() async {
    await assertErrorsInCode('''
f(var p) {
  if (p is A) {
  }
}''', [
      error(StaticWarningCode.TYPE_TEST_WITH_UNDEFINED_NAME, 22, 1),
    ]);
  }

  test_undefinedClass_instanceCreation() async {
    await assertErrorsInCode('''
f() { new C(); }
''', [
      error(StaticWarningCode.UNDEFINED_CLASS, 10, 1),
    ]);
  }

  test_undefinedClass_variableDeclaration() async {
    await assertErrorsInCode('''
f() { C c; }
''', [
      error(StaticWarningCode.UNDEFINED_CLASS, 6, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 8, 1),
    ]);
  }

  test_undefinedClassBoolean_variableDeclaration() async {
    await assertErrorsInCode('''
f() { boolean v; }
''', [
      error(StaticWarningCode.UNDEFINED_CLASS_BOOLEAN, 6, 7),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 14, 1),
    ]);
  }

  @failingTest
  test_undefinedIdentifier_commentReference() async {
    await assertErrorsInCode('''
/** [m] xxx [new B.c] */
class A {
}''', [
      error(StaticWarningCode.UNDEFINED_IDENTIFIER, 5, 1),
      error(StaticWarningCode.UNDEFINED_IDENTIFIER, 17, 1),
    ]);
  }

  test_undefinedIdentifier_for() async {
    await assertErrorsInCode('''
f(var l) {
  for (e in l) {
  }
}''', [
      error(StaticWarningCode.UNDEFINED_IDENTIFIER, 18, 1),
    ]);
  }

  test_undefinedIdentifier_function() async {
    await assertErrorsInCode('''
int a() => b;
''', [
      error(StaticWarningCode.UNDEFINED_IDENTIFIER, 11, 1),
    ]);
  }

  test_undefinedIdentifier_importCore_withShow() async {
    await assertErrorsInCode('''
import 'dart:core' show List;
main() {
  List;
  String;
}''', [
      error(StaticWarningCode.UNDEFINED_IDENTIFIER, 49, 6),
    ]);
  }

  test_undefinedIdentifier_initializer() async {
    await assertErrorsInCode('''
var a = b;
''', [
      error(StaticWarningCode.UNDEFINED_IDENTIFIER, 8, 1),
    ]);
  }

  test_undefinedIdentifier_methodInvocation() async {
    await assertErrorsInCode('''
f() { C.m(); }
''', [
      error(StaticWarningCode.UNDEFINED_IDENTIFIER, 6, 1),
    ]);
  }

  test_undefinedIdentifier_private_getter() async {
    newFile("/test/lib/lib.dart", content: '''
library lib;
class A {
  var _foo;
}''');
    await assertErrorsInCode('''
import 'lib.dart';
class B extends A {
  test() {
    var v = _foo;
  }
}''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 58, 1),
      error(StaticWarningCode.UNDEFINED_IDENTIFIER, 62, 4),
    ]);
  }

  test_undefinedIdentifier_private_setter() async {
    newFile("/test/lib/lib.dart", content: '''
library lib;
class A {
  var _foo;
}''');
    await assertErrorsInCode('''
import 'lib.dart';
class B extends A {
  test() {
    _foo = 42;
  }
}''', [
      error(StaticWarningCode.UNDEFINED_IDENTIFIER, 54, 4),
    ]);
  }

  test_undefinedIdentifierAwait_function() async {
    await assertErrorsInCode('''
void a() { await; }
''', [
      error(StaticWarningCode.UNDEFINED_IDENTIFIER_AWAIT, 11, 5),
    ]);
  }

  test_undefinedNamedParameter() async {
    await assertErrorsInCode('''
f({a, b}) {}
main() {
  f(c: 1);
}''', [
      error(StaticWarningCode.UNDEFINED_NAMED_PARAMETER, 26, 1),
    ]);
  }

  test_undefinedStaticMethodOrGetter_getter() async {
    await assertErrorsInCode('''
class C {}
f(var p) {
  f(C.m);
}''', [
      error(StaticTypeWarningCode.UNDEFINED_GETTER, 28, 1),
    ]);
  }

  test_undefinedStaticMethodOrGetter_getter_inSuperclass() async {
    await assertErrorsInCode('''
class S {
  static int get g => 0;
}
class C extends S {}
f(var p) {
  f(C.g);
}''', [
      error(StaticTypeWarningCode.UNDEFINED_GETTER, 75, 1),
    ]);
  }

  test_undefinedStaticMethodOrGetter_setter_inSuperclass() async {
    await assertErrorsInCode('''
class S {
  static set s(int i) {}
}
class C extends S {}
f(var p) {
  f(C.s = 1);
}''', [
      error(StaticTypeWarningCode.UNDEFINED_SETTER, 75, 1),
    ]);
  }

  test_useOfVoidResult_assignmentExpression_function() async {
    await assertErrorsInCode('''
void f() {}
class A {
  n() {
    var a;
    a = f();
  }
}''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 38, 1),
      error(StaticWarningCode.USE_OF_VOID_RESULT, 49, 1),
    ]);
  }

  test_useOfVoidResult_assignmentExpression_method() async {
    await assertErrorsInCode('''
class A {
  void m() {}
  n() {
    var a;
    a = m();
  }
}''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 40, 1),
      error(StaticWarningCode.USE_OF_VOID_RESULT, 51, 1),
    ]);
  }

  test_useOfVoidResult_await() async {
    await assertNoErrorsInCode('''
main() async {
  void x;
  await x;
}''');
  }

  test_useOfVoidResult_inForLoop_error() async {
    await assertErrorsInCode('''
class A {
  void m() {}
  n() {
    for(Object a = m();;) {}
  }
}''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 47, 1),
      error(StaticWarningCode.USE_OF_VOID_RESULT, 51, 1),
    ]);
  }

  test_useOfVoidResult_inForLoop_ok() async {
    await assertNoErrorsInCode('''
class A {
  void m() {}
  n() {
    for(void a = m();;) {}
  }
}''');
  }

  test_useOfVoidResult_variableDeclaration_function_error() async {
    await assertErrorsInCode('''
void f() {}
class A {
  n() {
    Object a = f();
  }
}''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 41, 1),
      error(StaticWarningCode.USE_OF_VOID_RESULT, 45, 1),
    ]);
  }

  test_useOfVoidResult_variableDeclaration_function_ok() async {
    await assertNoErrorsInCode('''
void f() {}
class A {
  n() {
    void a = f();
  }
}''');
  }

  test_useOfVoidResult_variableDeclaration_method2() async {
    await assertErrorsInCode('''
class A {
  void m() {}
  n() {
    Object a = m(), b = m();
  }
}''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 43, 1),
      error(StaticWarningCode.USE_OF_VOID_RESULT, 47, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 52, 1),
      error(StaticWarningCode.USE_OF_VOID_RESULT, 56, 1),
    ]);
  }

  test_useOfVoidResult_variableDeclaration_method_error() async {
    await assertErrorsInCode('''
class A {
  void m() {}
  n() {
    Object a = m();
  }
}''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 43, 1),
      error(StaticWarningCode.USE_OF_VOID_RESULT, 47, 1),
    ]);
  }

  test_useOfVoidResult_variableDeclaration_method_ok() async {
    await assertNoErrorsInCode('''
class A {
  void m() {}
  n() {
    void a = m();
  }
}''');
  }

  test_voidReturnForGetter() async {
    await assertNoErrorsInCode('''
class S {
  void get value {}
}''');
  }
}
