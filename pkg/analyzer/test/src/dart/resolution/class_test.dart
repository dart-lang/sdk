// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/elements_types_mixin.dart';
import 'driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClassDriverResolutionTest);
  });
}

@reflectiveTest
class ClassDriverResolutionTest extends DriverResolutionTest
    with ElementsTypesMixin {
  test_abstractSuperMemberReference_getter() async {
    await resolveTestCode(r'''
abstract class A {
  get foo;
}
abstract class B extends A {
  bar() {
    super.foo; // ref
  }
}
''');
    assertTestErrorsWithCodes(
        [CompileTimeErrorCode.ABSTRACT_SUPER_MEMBER_REFERENCE]);
    assertElement(findNode.simple('foo; // ref'), findElement.getter('foo'));
  }

  test_abstractSuperMemberReference_getter2() async {
    await resolveTestCode(r'''
abstract class Foo {
  String get foo;
}

abstract class Bar implements Foo {
}

class Baz extends Bar {
  String get foo => super.foo; // ref
}
''');
    assertTestErrorsWithCodes(
        [CompileTimeErrorCode.ABSTRACT_SUPER_MEMBER_REFERENCE]);
    assertElement(
      findNode.simple('foo; // ref'),
      findElement.getter('foo', of: 'Foo'),
    );
  }

  test_abstractSuperMemberReference_method_reference() async {
    await resolveTestCode(r'''
abstract class A {
  foo();
}
abstract class B extends A {
  bar() {
    super.foo; // ref
  }
}
''');
    assertTestErrorsWithCodes(
        [CompileTimeErrorCode.ABSTRACT_SUPER_MEMBER_REFERENCE]);
    assertElement(findNode.simple('foo; // ref'), findElement.method('foo'));
  }

  test_abstractSuperMemberReference_OK_superHasConcrete_mixinHasAbstract_method() async {
    await resolveTestCode('''
class A {
  void foo() {}
}

abstract class B {
  void foo();
}

class C extends A with B {
  void bar() {
    super.foo(); // ref
  }
}
''');
    assertNoTestErrors();
    assertElement(
      findNode.simple('foo(); // ref'),
      findElement.method('foo', of: 'A'),
    );
  }

  test_abstractSuperMemberReference_OK_superSuperHasConcrete_getter() async {
    await resolveTestCode('''
abstract class A {
  int get foo => 0;
}

abstract class B extends A {
  int get foo;
}

class C extends B {
  int get bar => super.foo; // ref
}
''');
    assertNoTestErrors();
    assertElement(
      findNode.simple('foo; // ref'),
      findElement.getter('foo', of: 'A'),
    );
  }

  test_abstractSuperMemberReference_OK_superSuperHasConcrete_setter() async {
    await resolveTestCode('''
abstract class A {
  void set foo(_) {}
}

abstract class B extends A {
  void set foo(_);
}

class C extends B {
  void bar() {
    super.foo = 0;
  }
}
''');
    assertNoTestErrors();
    assertElement(
      findNode.simple('foo = 0;'),
      findElement.setter('foo', of: 'A'),
    );
  }

  test_abstractSuperMemberReference_setter() async {
    await resolveTestCode(r'''
abstract class A {
  set foo(_);
}
abstract class B extends A {
  bar() {
    super.foo = 0;
  }
}
''');
    assertTestErrorsWithCodes(
        [CompileTimeErrorCode.ABSTRACT_SUPER_MEMBER_REFERENCE]);
    assertElement(findNode.simple('foo = 0;'), findElement.setter('foo'));
  }

  test_conflictingGenericInterfaces_simple() async {
    await resolveTestCode('''
class I<T> {}
class A implements I<int> {}
class B implements I<String> {}
class C extends A implements B {}
''');
    assertTestErrorsWithCodes(
        [CompileTimeErrorCode.CONFLICTING_GENERIC_INTERFACES]);
  }

  test_conflictingGenericInterfaces_viaMixin() async {
    await resolveTestCode('''
class I<T> {}
class A implements I<int> {}
class B implements I<String> {}
class C extends A with B {}
''');
    assertTestErrorsWithCodes(
        [CompileTimeErrorCode.CONFLICTING_GENERIC_INTERFACES]);
  }

  test_element_allSupertypes() async {
    await resolveTestCode(r'''
class A {}
class B {}
class C {}
class D {}
class E {}

class X1 extends A {}
class X2 implements B {}
class X3 extends A implements B {}
class X4 extends A with B implements C {}
class X5 extends A with B, C implements D, E {}
''');
    assertNoTestErrors();

    var a = findElement.class_('A');
    var b = findElement.class_('B');
    var c = findElement.class_('C');
    var d = findElement.class_('D');
    var e = findElement.class_('E');

    var typeA = interfaceType(a);
    var typeB = interfaceType(b);
    var typeC = interfaceType(c);
    var typeD = interfaceType(d);
    var typeE = interfaceType(e);

    assertElementTypes(
      findElement.class_('X1').allSupertypes,
      [typeA, objectType],
    );
    assertElementTypes(
      findElement.class_('X2').allSupertypes,
      [objectType, typeB],
    );
    assertElementTypes(
      findElement.class_('X3').allSupertypes,
      [typeA, objectType, typeB],
    );
    assertElementTypes(
      findElement.class_('X4').allSupertypes,
      [typeA, typeB, objectType, typeC],
    );
    assertElementTypes(
      findElement.class_('X5').allSupertypes,
      [typeA, typeB, typeC, objectType, typeD, typeE],
    );
  }

  test_element_allSupertypes_generic() async {
    await resolveTestCode(r'''
class A<T> {}
class B<T, U> {}
class C<T> extends B<int, T> {}

class X1 extends A<String> {}
class X2 extends B<String, List<int>> {}
class X3 extends C<double> {}
''');
    assertNoTestErrors();

    var a = findElement.class_('A');
    var b = findElement.class_('B');
    var c = findElement.class_('C');
    assertElementTypes(
      findElement.class_('X1').allSupertypes,
      [
        interfaceType(a, typeArguments: [stringType]),
        objectType
      ],
    );
    assertElementTypes(
      findElement.class_('X2').allSupertypes,
      [
        interfaceType(b, typeArguments: [
          stringType,
          interfaceType(listElement, typeArguments: [intType])
        ]),
        objectType
      ],
    );
    assertElementTypes(
      findElement.class_('X3').allSupertypes,
      [
        interfaceType(c, typeArguments: [doubleType]),
        interfaceType(b, typeArguments: [intType, doubleType]),
        objectType
      ],
    );
  }

  test_element_allSupertypes_recursive() async {
    await resolveTestCode(r'''
class A extends B {}
class B extends C {}
class C extends A {}

class X extends A {}
''');
    assertHasTestErrors();

    var a = findElement.class_('A');
    var b = findElement.class_('B');
    var c = findElement.class_('C');
    assertElementTypes(
      findElement.class_('X').allSupertypes,
      [interfaceType(a), interfaceType(b), interfaceType(c)],
    );
  }

  test_error_conflictingConstructorAndStaticField_field() async {
    await resolveTestCode(r'''
class C {
  C.foo();
  static int foo;
}
''');
    assertTestErrorsWithCodes([
      CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_AND_STATIC_FIELD,
    ]);
  }

  test_error_conflictingConstructorAndStaticField_getter() async {
    await resolveTestCode(r'''
class C {
  C.foo();
  static int get foo => 0;
}
''');
    assertTestErrorsWithCodes([
      CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_AND_STATIC_FIELD,
    ]);
  }

  test_error_conflictingConstructorAndStaticField_OK_notSameClass() async {
    await resolveTestCode(r'''
class A {
  static int foo;
}
class B extends A {
  B.foo();
}
''');
    assertNoTestErrors();
  }

  test_error_conflictingConstructorAndStaticField_OK_notStatic() async {
    await resolveTestCode(r'''
class C {
  C.foo();
  int foo;
}
''');
    assertNoTestErrors();
  }

  test_error_conflictingConstructorAndStaticField_setter() async {
    await resolveTestCode(r'''
class C {
  C.foo();
  static void set foo(_) {}
}
''');
    assertTestErrorsWithCodes([
      CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_AND_STATIC_FIELD,
    ]);
  }

  test_error_conflictingConstructorAndStaticMethod() async {
    await resolveTestCode(r'''
class C {
  C.foo();
  static void foo() {}
}
''');
    assertTestErrorsWithCodes([
      CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_AND_STATIC_METHOD,
    ]);
  }

  test_error_conflictingConstructorAndStaticMethod_OK_notSameClass() async {
    await resolveTestCode(r'''
class A {
  static void foo() {}
}
class B extends A {
  B.foo();
}
''');
    assertNoTestErrors();
  }

  test_error_conflictingConstructorAndStaticMethod_OK_notStatic() async {
    await resolveTestCode(r'''
class C {
  C.foo();
  void foo() {}
}
''');
    assertNoTestErrors();
  }

  test_error_conflictingFieldAndMethod_inSuper_field() async {
    await resolveTestCode(r'''
class A {
  foo() {}
}
class B extends A {
  int foo;
}
''');
    assertTestErrorsWithCodes(
        [CompileTimeErrorCode.CONFLICTING_FIELD_AND_METHOD]);
  }

  test_error_conflictingFieldAndMethod_inSuper_getter() async {
    await resolveTestCode(r'''
class A {
  foo() {}
}
class B extends A {
  get foo => 0;
}
''');
    assertTestErrorsWithCodes(
        [CompileTimeErrorCode.CONFLICTING_FIELD_AND_METHOD]);
  }

  test_error_conflictingFieldAndMethod_inSuper_setter() async {
    await resolveTestCode(r'''
class A {
  foo() {}
}
class B extends A {
  set foo(_) {}
}
''');
    assertTestErrorsWithCodes(
        [CompileTimeErrorCode.CONFLICTING_FIELD_AND_METHOD]);
  }

  test_error_conflictingMethodAndField_inSuper_field() async {
    await resolveTestCode(r'''
class A {
  int foo;
}
class B extends A {
  foo() {}
}
''');
    assertTestErrorsWithCodes(
        [CompileTimeErrorCode.CONFLICTING_METHOD_AND_FIELD]);
  }

  test_error_conflictingMethodAndField_inSuper_getter() async {
    await resolveTestCode(r'''
class A {
  get foo => 0;
}
class B extends A {
  foo() {}
}
''');
    assertTestErrorsWithCodes(
        [CompileTimeErrorCode.CONFLICTING_METHOD_AND_FIELD]);
  }

  test_error_conflictingMethodAndField_inSuper_setter() async {
    await resolveTestCode(r'''
class A {
  set foo(_) {}
}
class B extends A {
  foo() {}
}
''');
    assertTestErrorsWithCodes(
        [CompileTimeErrorCode.CONFLICTING_METHOD_AND_FIELD]);
  }

  test_error_duplicateConstructorDefault() async {
    await resolveTestCode(r'''
class C {
  C();
  C();
}
''');
    assertTestErrorsWithCodes([
      CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_DEFAULT,
    ]);
  }

  test_error_duplicateConstructorName() async {
    await resolveTestCode(r'''
class C {
  C.foo();
  C.foo();
}
''');
    assertTestErrorsWithCodes([
      CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_NAME,
    ]);
  }

  test_error_extendsNonClass_dynamic() async {
    await resolveTestCode(r'''
class A extends dynamic {}
''');
    assertTestErrorsWithCodes([
      CompileTimeErrorCode.EXTENDS_NON_CLASS,
    ]);

    var a = findElement.class_('A');
    assertElementType(a.supertype, objectType);
  }

  test_error_extendsNonClass_enum() async {
    await resolveTestCode(r'''
enum E { ONE }
class A extends E {}
''');
    assertTestErrorsWithCodes([
      CompileTimeErrorCode.EXTENDS_NON_CLASS,
    ]);

    var a = findElement.class_('A');
    assertElementType(a.supertype, objectType);

    var eRef = findNode.typeName('E {}');
    assertTypeName(eRef, findElement.enum_('E'), 'E');
  }

  test_error_extendsNonClass_mixin() async {
    await resolveTestCode(r'''
mixin M {}
class A extends M {} // ref
''');
    assertTestErrorsWithCodes([
      CompileTimeErrorCode.EXTENDS_NON_CLASS,
    ]);

    var a = findElement.class_('A');
    assertElementType(a.supertype, objectType);

    var mRef = findNode.typeName('M {} // ref');
    assertTypeName(mRef, findElement.mixin('M'), 'M');
  }

  test_error_extendsNonClass_variable() async {
    await resolveTestCode(r'''
int v;
class A extends v {}
''');
    assertTestErrorsWithCodes([
      CompileTimeErrorCode.EXTENDS_NON_CLASS,
    ]);

    var a = findElement.class_('A');
    assertElementType(a.supertype, objectType);
  }

  test_error_implementsRepeated() async {
    await resolveTestCode(r'''
class A {}
class B implements A, A {} // ref
''');
    assertTestErrorsWithCodes([CompileTimeErrorCode.IMPLEMENTS_REPEATED]);

    var a = findElement.class_('A');
    assertTypeName(findNode.typeName('A, A {} // ref'), a, 'A');
    assertTypeName(findNode.typeName('A {} // ref'), a, 'A');
  }

  test_error_implementsRepeated_3times() async {
    await resolveTestCode(r'''
class A {} class C{}
class B implements A, A, A, A {}''');
    assertTestErrorsWithCodes([
      CompileTimeErrorCode.IMPLEMENTS_REPEATED,
      CompileTimeErrorCode.IMPLEMENTS_REPEATED,
      CompileTimeErrorCode.IMPLEMENTS_REPEATED
    ]);
  }

  test_error_memberWithClassName_getter() async {
    await resolveTestCode(r'''
class C {
  int get C => null;
}
''');
    assertTestErrorsWithCodes([CompileTimeErrorCode.MEMBER_WITH_CLASS_NAME]);
  }

  test_error_memberWithClassName_getter_static() async {
    await resolveTestCode(r'''
class C {
  static int get C => null;
}
''');
    assertTestErrorsWithCodes([CompileTimeErrorCode.MEMBER_WITH_CLASS_NAME]);

    var method = findNode.methodDeclaration('C =>');
    expect(method.isGetter, isTrue);
    expect(method.isStatic, isTrue);
    assertElement(method, findElement.getter('C'));
  }

  test_error_memberWithClassName_setter() async {
    await resolveTestCode(r'''
class C {
  set C(_) {}
}
''');
    assertTestErrorsWithCodes([CompileTimeErrorCode.MEMBER_WITH_CLASS_NAME]);
  }

  test_error_memberWithClassName_setter_static() async {
    await resolveTestCode(r'''
class C {
  static set C(_) {}
}
''');
    assertTestErrorsWithCodes([CompileTimeErrorCode.MEMBER_WITH_CLASS_NAME]);

    var method = findNode.methodDeclaration('C(_)');
    expect(method.isSetter, isTrue);
    expect(method.isStatic, isTrue);
  }

  test_error_mismatchedGetterAndSetterTypes_class() async {
    await resolveTestCode(r'''
class C {
  int get foo => 0;
  set foo(String _) {}
}
''');
    assertTestErrorsWithCodes([
      StaticWarningCode.MISMATCHED_GETTER_AND_SETTER_TYPES,
    ]);
  }

  test_error_mismatchedGetterAndSetterTypes_interfaces() async {
    await resolveTestCode(r'''
class A {
  int get foo {
    return 0;
  }
}

class B {
  set foo(String _) {}
}

abstract class X implements A, B {}
''');
    assertTestErrorsWithCodes([
      StaticWarningCode.MISMATCHED_GETTER_AND_SETTER_TYPES,
    ]);
  }

  test_error_mismatchedGetterAndSetterTypes_OK_private_getter() async {
    newFile('/test/lib/a.dart', content: r'''
class A {
  int get _foo => 0;
}
''');
    await resolveTestCode(r'''
import 'a.dart';

class B extends A {
  set _foo(String _) {}
}
''');
    assertNoTestErrors();
  }

  test_error_mismatchedGetterAndSetterTypes_OK_private_interfaces() async {
    newFile('/test/lib/a.dart', content: r'''
class A {
  int get _foo => 0;
}
''');
    newFile('/test/lib/b.dart', content: r'''
class B {
  set _foo(String _) {}
}
''');
    await resolveTestCode(r'''
import 'a.dart';
import 'b.dart';

class X implements A, B {}
''');
    assertNoTestErrors();
  }

  test_error_mismatchedGetterAndSetterTypes_OK_private_interfaces2() async {
    newFile('/test/lib/a.dart', content: r'''
class A {
  int get _foo => 0;
}

class B {
  set _foo(String _) {}
}
''');
    await resolveTestCode(r'''
import 'a.dart';

class X implements A, B {}
''');
    assertNoTestErrors();
  }

  test_error_mismatchedGetterAndSetterTypes_OK_private_setter() async {
    newFile('/test/lib/a.dart', content: r'''
class A {
  set _foo(String _) {}
}
''');
    await resolveTestCode(r'''
import 'a.dart';

class B extends A {
  int get _foo => 0;
}
''');
    assertNoTestErrors();
  }

  test_error_mismatchedGetterAndSetterTypes_OK_setterParameter_0() async {
    await resolveTestCode(r'''
class C {
  int get foo => 0;
  set foo() {}
}
''');
    assertTestErrorsWithCodes([
      CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER,
    ]);
  }

  test_error_mismatchedGetterAndSetterTypes_OK_setterParameter_2() async {
    await resolveTestCode(r'''
class C {
  int get foo => 0;
  set foo(String p1, String p2) {}
}
''');
    assertTestErrorsWithCodes([
      CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER,
    ]);
  }

  test_error_mismatchedGetterAndSetterTypes_superGetter() async {
    await resolveTestCode(r'''
class A {
  int get foo => 0;
}

class B extends A {
  set foo(String _) {}
}
''');
    assertTestErrorsWithCodes([
      StaticWarningCode.MISMATCHED_GETTER_AND_SETTER_TYPES,
    ]);
  }

  test_error_mismatchedGetterAndSetterTypes_superSetter() async {
    await resolveTestCode(r'''
class A {
  set foo(String _) {}
}

class B extends A {
  int get foo => 0;
}
''');
    assertTestErrorsWithCodes([
      StaticWarningCode.MISMATCHED_GETTER_AND_SETTER_TYPES,
    ]);
  }

  test_inconsistentInheritance_parameterType() async {
    await resolveTestCode(r'''
abstract class A {
  x(int i);
}
abstract class B {
  x(String s);
}
abstract class C implements A, B {}
''');
    assertTestErrorsWithCodes([
      CompileTimeErrorCode.INCONSISTENT_INHERITANCE,
    ]);
  }

  test_inconsistentInheritance_requiredParameters() async {
    await resolveTestCode(r'''
abstract class A {
  x();
}
abstract class B {
  x(int y);
}
abstract class C implements A, B {}
''');
    assertTestErrorsWithCodes([
      CompileTimeErrorCode.INCONSISTENT_INHERITANCE,
    ]);
  }

  test_inconsistentInheritance_returnType() async {
    await resolveTestCode(r'''
abstract class A {
  int x();
}
abstract class B {
  String x();
}
abstract class C implements A, B {}
''');
    assertTestErrorsWithCodes([
      CompileTimeErrorCode.INCONSISTENT_INHERITANCE,
    ]);
  }

  test_inconsistentInheritanceGetterAndMethod_getter_method() async {
    await resolveTestCode(r'''
abstract class A {
  int get x;
}
abstract class B {
  int x();
}
abstract class C implements A, B {}
''');
    assertTestErrorsWithCodes([
      CompileTimeErrorCode.INCONSISTENT_INHERITANCE_GETTER_AND_METHOD,
    ]);
  }

  test_inconsistentInheritanceGetterAndMethod_method_getter() async {
    await resolveTestCode(r'''
abstract class A {
  int x();
}
abstract class B {
  int get x;
}
abstract class C implements A, B {}
''');
    assertTestErrorsWithCodes([
      CompileTimeErrorCode.INCONSISTENT_INHERITANCE_GETTER_AND_METHOD,
    ]);
  }

  test_issue32815() async {
    await resolveTestCode(r'''
class A<T> extends B<T> {}
class B<T> extends A<T> {}
class C<T> extends B<T> implements I<T> {}

abstract class I<T> {}

main() {
  Iterable<I<int>> x = [new C()];
}
''');
    assertHasTestErrors();
  }

  test_recursiveInterfaceInheritance_extends() async {
    await resolveTestCode(r'''
class A extends B {}
class B extends A {}''');
    assertTestErrorsWithCodes([
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE
    ]);
  }

  test_recursiveInterfaceInheritance_extends_implements() async {
    await resolveTestCode(r'''
class A extends B {}
class B implements A {}''');
    assertTestErrorsWithCodes([
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE
    ]);
  }

  test_recursiveInterfaceInheritance_implements() async {
    await resolveTestCode(r'''
class A implements B {}
class B implements A {}''');
    assertTestErrorsWithCodes([
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE
    ]);
  }

  test_recursiveInterfaceInheritance_mixin() async {
    await resolveTestCode(r'''
class M1 = Object with M2;
class M2 = Object with M1;''');
    assertTestErrorsWithCodes([
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE
    ]);
  }

  test_recursiveInterfaceInheritance_mixin_superclass() async {
    // Make sure we don't get CompileTimeErrorCode.MIXIN_HAS_NO_CONSTRUCTORS in
    // addition--that would just be confusing.
    await resolveTestCode('''
class C = D with M;
class D = C with M;
class M {}
''');
    assertTestErrorsWithCodes([
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
    ]);
  }

  test_recursiveInterfaceInheritance_tail() async {
    await resolveTestCode(r'''
abstract class A implements A {}
class B implements A {}''');
    assertTestErrorsWithCodes(
        [CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_IMPLEMENTS]);
  }

  test_recursiveInterfaceInheritance_tail2() async {
    await resolveTestCode(r'''
abstract class A implements B {}
abstract class B implements A {}
class C implements A {}''');
    assertTestErrorsWithCodes([
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE
    ]);
  }

  test_recursiveInterfaceInheritance_tail3() async {
    await resolveTestCode(r'''
abstract class A implements B {}
abstract class B implements C {}
abstract class C implements A {}
class D implements A {}''');
    assertTestErrorsWithCodes([
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE
    ]);
  }

  test_recursiveInterfaceInheritanceExtends() async {
    await resolveTestCode("class A extends A {}");
    assertTestErrorsWithCodes(
        [CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_EXTENDS]);
  }

  test_recursiveInterfaceInheritanceExtends_abstract() async {
    await resolveTestCode(r'''
class C extends C {
  var bar = 0;
  m();
}
''');
    assertTestErrorsWithCodes([
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_EXTENDS,
    ]);
  }

  test_recursiveInterfaceInheritanceImplements() async {
    await resolveTestCode("class A implements A {}");
    assertTestErrorsWithCodes(
        [CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_IMPLEMENTS]);
  }

  test_recursiveInterfaceInheritanceImplements_typeAlias() async {
    await resolveTestCode(r'''
class A {}
class M {}
class B = A with M implements B;''');
    assertTestErrorsWithCodes(
        [CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_IMPLEMENTS]);
  }

  test_recursiveInterfaceInheritanceWith() async {
    await resolveTestCode("class M = Object with M;");
    assertTestErrorsWithCodes([
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_WITH,
    ]);
  }

  test_undefinedSuperGetter() async {
    await resolveTestCode(r'''
class A {}
class B extends A {
  get g {
    return super.g;
  }
}''');
    assertTestErrorsWithCodes([StaticTypeWarningCode.UNDEFINED_SUPER_GETTER]);
  }

  test_undefinedSuperMethod() async {
    await resolveTestCode(r'''
class A {}
class B extends A {
  m() {
    return super.m();
  }
}''');
    assertTestErrorsWithCodes([StaticTypeWarningCode.UNDEFINED_SUPER_METHOD]);
  }

  test_undefinedSuperOperator_binaryExpression() async {
    await resolveTestCode(r'''
class A {}
class B extends A {
  operator +(value) {
    return super + value;
  }
}''');
    assertTestErrorsWithCodes([StaticTypeWarningCode.UNDEFINED_SUPER_OPERATOR]);
  }

  test_undefinedSuperOperator_indexBoth() async {
    await resolveTestCode(r'''
class A {}
class B extends A {
  operator [](index) {
    return super[index]++;
  }
}''');
    assertTestErrorsWithCodes([
      StaticTypeWarningCode.UNDEFINED_SUPER_OPERATOR,
      StaticTypeWarningCode.UNDEFINED_SUPER_OPERATOR,
    ]);
  }

  test_undefinedSuperOperator_indexGetter() async {
    await resolveTestCode(r'''
class A {}
class B extends A {
  operator [](index) {
    return super[index + 1];
  }
}''');
    assertTestErrorsWithCodes([StaticTypeWarningCode.UNDEFINED_SUPER_OPERATOR]);
  }

  test_undefinedSuperOperator_indexSetter() async {
    await resolveTestCode(r'''
class A {}
class B extends A {
  operator []=(index, value) {
    super[index] = 0;
  }
}''');
    assertTestErrorsWithCodes([StaticTypeWarningCode.UNDEFINED_SUPER_OPERATOR]);
  }

  test_undefinedSuperSetter() async {
    await resolveTestCode(r'''
class A {}
class B extends A {
  f() {
    super.m = 0;
  }
}''');
    assertTestErrorsWithCodes([StaticTypeWarningCode.UNDEFINED_SUPER_SETTER]);
  }
}
