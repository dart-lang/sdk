// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
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

  test_mixedReturnTypes_localFunction() async {
    await assertErrorsInCode('''
class C {
  m(int x) {
    return (int y) {
      if (y < 0) {
        return;
      }
      return 0;
    };
  }
}''', [
      error(StaticWarningCode.RETURN_WITHOUT_VALUE, 71, 7),
    ]);
  }

  test_mixedReturnTypes_method() async {
    await assertErrorsInCode('''
class C {
  m(int x) {
    if (x < 0) {
      return;
    }
    return 0;
  }
}''', [
      error(StaticWarningCode.MIXED_RETURN_TYPES, 46, 6),
      error(StaticWarningCode.MIXED_RETURN_TYPES, 64, 6),
    ]);
  }

  test_mixedReturnTypes_topLevelFunction() async {
    await assertErrorsInCode('''
f(int x) {
  if (x < 0) {
    return;
  }
  return 0;
}''', [
      error(StaticWarningCode.MIXED_RETURN_TYPES, 30, 6),
      error(StaticWarningCode.MIXED_RETURN_TYPES, 44, 6),
    ]);
  }

  test_newWithAbstractClass() async {
    await assertErrorsInCode('''
abstract class A {}
void f() {
  A a = new A();
}''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 35, 1),
      error(StaticWarningCode.NEW_WITH_ABSTRACT_CLASS, 43, 1),
    ]);
  }

  test_newWithAbstractClass_generic() async {
    await assertErrorsInCode('''
abstract class A<E> {}
void f() {
  var a = new A<int>();
}''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 40, 1),
      error(StaticWarningCode.NEW_WITH_ABSTRACT_CLASS, 48, 6),
    ]);

    ClassDeclaration classA = result.unit.declarations[0];
    FunctionDeclaration f = result.unit.declarations[1];
    BlockFunctionBody body = f.functionExpression.body;
    VariableDeclarationStatement a = body.block.statements[0];
    InstanceCreationExpression init = a.variables.variables[0].initializer;
    expect(init.staticType,
        classA.declaredElement.type.instantiate([typeProvider.intType]));
  }

  test_newWithInvalidTypeParameters() async {
    await assertErrorsInCode('''
class A {}
f() { return new A<A>(); }''', [
      error(StaticWarningCode.NEW_WITH_INVALID_TYPE_PARAMETERS, 28, 4),
    ]);
  }

  test_newWithInvalidTypeParameters_tooFew() async {
    await assertErrorsInCode('''
class A {}
class C<K, V> {}
f(p) {
  return new C<A>();
}''', [
      error(StaticWarningCode.NEW_WITH_INVALID_TYPE_PARAMETERS, 48, 4),
    ]);
  }

  test_newWithInvalidTypeParameters_tooMany() async {
    await assertErrorsInCode('''
class A {}
class C<E> {}
f(p) {
  return new C<A, A>();
}''', [
      error(StaticWarningCode.NEW_WITH_INVALID_TYPE_PARAMETERS, 45, 7),
    ]);
  }

  test_newWithNonType() async {
    await assertErrorsInCode('''
var A = 0;
void f() {
  var a = new A();
}''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 28, 1),
      error(StaticWarningCode.NEW_WITH_NON_TYPE, 36, 1),
    ]);
  }

  test_newWithNonType_fromLibrary() async {
    newFile("/test/lib/lib.dart", content: "class B {}");
    await assertErrorsInCode('''
import 'lib.dart' as lib;
void f() {
  var a = new lib.A();
}
lib.B b;''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 43, 1),
      error(StaticWarningCode.NEW_WITH_NON_TYPE, 55, 1),
    ]);
  }

  test_newWithUndefinedConstructor() async {
    await assertErrorsInCode('''
class A {
  A() {}
}
f() {
  new A.name();
}''', [
      error(StaticWarningCode.NEW_WITH_UNDEFINED_CONSTRUCTOR, 35, 4),
    ]);
  }

  test_newWithUndefinedConstructorDefault() async {
    await assertErrorsInCode('''
class A {
  A.name() {}
}
f() {
  new A();
}''', [
      error(StaticWarningCode.NEW_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT, 38, 1),
    ]);
  }

  test_nonAbstractClassInheritsAbstractMemberFivePlus() async {
    await assertErrorsInCode('''
abstract class A {
  m();
  n();
  o();
  p();
  q();
}
class C extends A {
}''', [
      error(
          StaticWarningCode
              .NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FIVE_PLUS,
          62,
          1),
    ]);
  }

  test_nonAbstractClassInheritsAbstractMemberFour() async {
    await assertErrorsInCode('''
abstract class A {
  m();
  n();
  o();
  p();
}
class C extends A {
}''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FOUR,
          55, 1),
    ]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_classTypeAlias_interface() async {
    // 15979
    await assertErrorsInCode('''
abstract class M {}
abstract class A {}
abstract class I {
  m();
}
class B = A with M implements I;''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          74, 1),
    ]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_classTypeAlias_mixin() async {
    // 15979
    await assertErrorsInCode('''
abstract class M {
  m();
}
abstract class A {}
class B = A with M;''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          54, 1),
    ]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_classTypeAlias_superclass() async {
    // 15979
    await assertErrorsInCode('''
class M {}
abstract class A {
  m();
}
class B = A with M;''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          45, 1),
    ]);
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

  test_nonAbstractClassInheritsAbstractMemberOne_getter_fromInterface() async {
    await assertErrorsInCode('''
class I {
  int get g {return 1;}
}
class C implements I {
}''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          42, 1),
    ]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_getter_fromSuperclass() async {
    await assertErrorsInCode('''
abstract class A {
  int get g;
}
class C extends A {
}''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          40, 1),
    ]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_method_fromInterface() async {
    await assertErrorsInCode('''
class I {
  m(p) {}
}
class C implements I {
}''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          28, 1),
    ]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_method_fromInterface_abstractNSM() async {
    await assertErrorsInCode('''
class I {
  m(p) {}
}
class C implements I {
  noSuchMethod(v);
}''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          28, 1),
    ]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_method_fromInterface_abstractOverrideNSM() async {
    await assertNoErrorsInCode('''
class I {
  m(p) {}
}
class B {
  noSuchMethod(v) => null;
}
class C extends B implements I {
  noSuchMethod(v);
}''');
  }

  test_nonAbstractClassInheritsAbstractMemberOne_method_fromInterface_ifcNSM() async {
    await assertErrorsInCode('''
class I {
  m(p) {}
  noSuchMethod(v) => null;
}
class C implements I {
}''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          55, 1),
    ]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_method_fromSuperclass() async {
    await assertErrorsInCode('''
abstract class A {
  m(p);
}
class C extends A {
}''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          35, 1),
    ]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_method_optionalParamCount() async {
    // 7640
    await assertErrorsInCode('''
abstract class A {
  int x(int a);
}
abstract class B {
  int x(int a, [int b]);
}
class C implements A, B {
}''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          89, 1),
    ]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_mixinInherits_getter() async {
    // 15001
    await assertErrorsInCode('''
abstract class A { get g1; get g2; }
abstract class B implements A { get g1 => 1; }
class C extends Object with B {}''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          90, 1),
    ]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_mixinInherits_method() async {
    // 15001
    await assertErrorsInCode('''
abstract class A { m1(); m2(); }
abstract class B implements A { m1() => 1; }
class C extends Object with B {}''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          84, 1),
    ]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_mixinInherits_setter() async {
    // 15001
    await assertErrorsInCode('''
abstract class A { set s1(v); set s2(v); }
abstract class B implements A { set s1(v) {} }
class C extends Object with B {}''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          96, 1),
    ]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_noSuchMethod_interface() async {
    // 15979
    await assertErrorsInCode('''
class I {
  noSuchMethod(v) => '';
}
abstract class A {
  m();
}
class B extends A implements I {
}''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          71, 1),
    ]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_setter_and_implicitSetter() async {
    // test from language/override_inheritance_abstract_test_14.dart
    await assertErrorsInCode('''
abstract class A {
  set field(_);
}
abstract class I {
  var field;
}
class B extends A implements I {
  get field => 0;
}''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          77, 1),
    ]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_setter_fromInterface() async {
    await assertErrorsInCode('''
class I {
  set s(int i) {}
}
class C implements I {
}''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          36, 1),
    ]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_setter_fromSuperclass() async {
    await assertErrorsInCode('''
abstract class A {
  set s(int i);
}
class C extends A {
}''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          43, 1),
    ]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_superclasses_interface() async {
    // bug 11154
    await assertErrorsInCode('''
class A {
  get a => 'a';
}
abstract class B implements A {
  get b => 'b';
}
class C extends B {
}''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          84, 1),
    ]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_variable_fromInterface_missingGetter() async {
    // 16133
    await assertErrorsInCode('''
class I {
  var v;
}
class C implements I {
  set v(_) {}
}''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          27, 1),
    ]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_variable_fromInterface_missingSetter() async {
    // 16133
    await assertErrorsInCode('''
class I {
  var v;
}
class C implements I {
  get v => 1;
}''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          27, 1),
    ]);
  }

  test_nonAbstractClassInheritsAbstractMemberThree() async {
    await assertErrorsInCode('''
abstract class A {
  m();
  n();
  o();
}
class C extends A {
}''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_THREE,
          48, 1),
    ]);
  }

  test_nonAbstractClassInheritsAbstractMemberTwo() async {
    await assertErrorsInCode('''
abstract class A {
  m();
  n();
}
class C extends A {
}''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_TWO,
          41, 1),
    ]);
  }

  test_nonAbstractClassInheritsAbstractMemberTwo_variable_fromInterface_missingBoth() async {
    // 16133
    await assertErrorsInCode('''
class I {
  var v;
}
class C implements I {
}''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_TWO,
          27, 1),
    ]);
  }

  test_nonTypeInCatchClause_noElement() async {
    await assertErrorsInCode('''
f() {
  try {
  } on T catch (e) {
  }
}''', [
      error(StaticWarningCode.NON_TYPE_IN_CATCH_CLAUSE, 21, 1),
      error(HintCode.UNUSED_CATCH_CLAUSE, 30, 1),
    ]);
  }

  test_nonTypeInCatchClause_notType() async {
    await assertErrorsInCode('''
var T = 0;
f() {
  try {
  } on T catch (e) {
  }
}''', [
      error(StaticWarningCode.NON_TYPE_IN_CATCH_CLAUSE, 32, 1),
      error(HintCode.UNUSED_CATCH_CLAUSE, 41, 1),
    ]);
  }

  test_nonVoidReturnForOperator() async {
    await assertErrorsInCode('''
class A {
  int operator []=(a, b) { return a; }
}''', [
      error(StaticWarningCode.NON_VOID_RETURN_FOR_OPERATOR, 12, 3),
    ]);
  }

  test_nonVoidReturnForSetter_function() async {
    await assertErrorsInCode('''
int set x(int v) {
  return 42;
}''', [
      error(StaticWarningCode.NON_VOID_RETURN_FOR_SETTER, 0, 3),
    ]);
  }

  test_nonVoidReturnForSetter_method() async {
    await assertErrorsInCode('''
class A {
  int set x(int v) {
    return 42;
  }
}''', [
      error(StaticWarningCode.NON_VOID_RETURN_FOR_SETTER, 12, 3),
    ]);
  }

  test_notAType() async {
    await assertErrorsInCode('''
f() {}
main() {
  f v = null;
}''', [
      error(StaticWarningCode.NOT_A_TYPE, 18, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 20, 1),
    ]);
  }

  test_notEnoughRequiredArguments() async {
    await assertErrorsInCode('''
f(int a, String b) {}
main() {
  f();
}''', [
      error(StaticWarningCode.NOT_ENOUGH_REQUIRED_ARGUMENTS, 34, 2),
    ]);
  }

  test_notEnoughRequiredArguments_functionExpression() async {
    await assertErrorsInCode('''
main() {
  (int x) {} ();
}''', [
      error(StaticWarningCode.NOT_ENOUGH_REQUIRED_ARGUMENTS, 22, 2),
    ]);
  }

  test_notEnoughRequiredArguments_getterReturningFunction() async {
    await assertErrorsInCode('''
typedef Getter(self);
Getter getter = (x) => x;
main() {
  getter();
}''', [
      error(StaticWarningCode.NOT_ENOUGH_REQUIRED_ARGUMENTS, 65, 2),
    ]);
  }

  test_partOfDifferentLibrary() async {
    newFile("/test/lib/part.dart", content: "part of lub;");
    await assertErrorsInCode('''
library lib;
part 'part.dart';''', [
      error(StaticWarningCode.PART_OF_DIFFERENT_LIBRARY, 18, 11),
    ]);
  }

  test_redirectToInvalidFunctionType() async {
    await assertErrorsInCode('''
class A implements B {
  A(int p) {}
}
class B {
  factory B() = A;
}''', [
      error(StaticWarningCode.REDIRECT_TO_INVALID_FUNCTION_TYPE, 65, 1),
    ]);
  }

  test_redirectToInvalidReturnType() async {
    await assertErrorsInCode('''
class A {
  A() {}
}
class B {
  factory B() = A;
}''', [
      error(StaticWarningCode.REDIRECT_TO_INVALID_RETURN_TYPE, 47, 1),
    ]);
  }

  test_redirectToMissingConstructor_named() async {
    await assertErrorsInCode('''
class A implements B{
  A() {}
}
class B {
  factory B() = A.name;
}''', [
      error(StaticWarningCode.REDIRECT_TO_MISSING_CONSTRUCTOR, 59, 6),
    ]);
  }

  test_redirectToMissingConstructor_unnamed() async {
    await assertErrorsInCode('''
class A implements B{
  A.name() {}
}
class B {
  factory B() = A;
}''', [
      error(StaticWarningCode.REDIRECT_TO_MISSING_CONSTRUCTOR, 64, 1),
    ]);
  }

  test_redirectToNonClass_notAType() async {
    await assertErrorsInCode('''
class B {
  int A;
  factory B() = A;
}''', [
      error(StaticWarningCode.REDIRECT_TO_NON_CLASS, 35, 1),
    ]);
  }

  test_redirectToNonClass_undefinedIdentifier() async {
    await assertErrorsInCode('''
class B {
  factory B() = A;
}''', [
      error(StaticWarningCode.REDIRECT_TO_NON_CLASS, 26, 1),
    ]);
  }

  test_returnWithoutValue_async() async {
    await assertErrorsInCode('''
import 'dart:async';
Future<int> f() async {
  return;
}
''', [
      error(StaticWarningCode.RETURN_WITHOUT_VALUE, 47, 7),
    ]);
  }

  test_returnWithoutValue_async_future_object_with_return() async {
    await assertErrorsInCode('''
import 'dart:async';
Future<Object> f() async {
  return;
}
''', [
      error(StaticWarningCode.RETURN_WITHOUT_VALUE, 50, 7),
    ]);
  }

  test_returnWithoutValue_factoryConstructor() async {
    await assertErrorsInCode('''
class A { factory A() { return; } }
''', [
      error(StaticWarningCode.RETURN_WITHOUT_VALUE, 24, 7),
    ]);
  }

  test_returnWithoutValue_function() async {
    await assertErrorsInCode('''
int f() { return; }
''', [
      error(StaticWarningCode.RETURN_WITHOUT_VALUE, 10, 7),
    ]);
  }

  test_returnWithoutValue_method() async {
    await assertErrorsInCode('''
class A { int m() { return; } }
''', [
      error(StaticWarningCode.RETURN_WITHOUT_VALUE, 20, 7),
    ]);
  }

  test_returnWithoutValue_mixedReturnTypes_function() async {
    // Tests that only the RETURN_WITHOUT_VALUE warning is created, and no
    // MIXED_RETURN_TYPES are created.
    await assertErrorsInCode('''
int f(int x) {
  if (x < 0) {
    return 1;
  }
  return;
}''', [
      error(StaticWarningCode.RETURN_WITHOUT_VALUE, 50, 7),
    ]);
  }

  test_returnWithoutValue_Null() async {
    // Test that block bodied functions with return type Null and an empty
    // return cause a static warning.
    await assertNoErrorsInCode('''
Null f() {return;}
''');
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
