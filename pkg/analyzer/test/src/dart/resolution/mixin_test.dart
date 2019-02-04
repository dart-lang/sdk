// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';
import 'resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinDriverResolutionTest);
  });
}

@reflectiveTest
class MixinDriverResolutionTest extends DriverResolutionTest
    with MixinResolutionMixin {}

mixin MixinResolutionMixin implements ResolutionTest {
  test_accessor_getter() async {
    addTestFile(r'''
mixin M {
  int get g => 0;
}
''');
    await resolveTestFile();
    assertNoTestErrors();

    var element = findElement.mixin('M');

    var accessors = element.accessors;
    expect(accessors, hasLength(1));

    var gElement = accessors[0];
    assertElementName(gElement, 'g', offset: 20);

    var gNode = findNode.methodDeclaration('g =>');
    assertElement(gNode.name, gElement);

    var fields = element.fields;
    expect(fields, hasLength(1));
    assertElementName(fields[0], 'g', isSynthetic: true);
  }

  test_accessor_method() async {
    addTestFile(r'''
mixin M {
  void foo() {}
}
''');
    await resolveTestFile();
    assertNoTestErrors();

    var element = findElement.mixin('M');

    var methods = element.methods;
    expect(methods, hasLength(1));

    var fooElement = methods[0];
    assertElementName(fooElement, 'foo', offset: 17);

    var fooNode = findNode.methodDeclaration('foo()');
    assertElement(fooNode.name, fooElement);
  }

  test_accessor_setter() async {
    addTestFile(r'''
mixin M {
  void set s(int _) {}
}
''');
    await resolveTestFile();
    assertNoTestErrors();

    var element = findElement.mixin('M');

    var accessors = element.accessors;
    expect(accessors, hasLength(1));

    var sElement = accessors[0];
    assertElementName(sElement, 's=', offset: 21);

    var gNode = findNode.methodDeclaration('s(int _)');
    assertElement(gNode.name, sElement);

    var fields = element.fields;
    expect(fields, hasLength(1));
    assertElementName(fields[0], 's', isSynthetic: true);
  }

  test_classDeclaration_with() async {
    addTestFile(r'''
mixin M {}
class A extends Object with M {} // A
''');
    await resolveTestFile();
    assertNoTestErrors();

    var mElement = findElement.mixin('M');

    var aElement = findElement.class_('A');
    assertElementTypes(aElement.mixins, [mElement.type]);

    var mRef = findNode.typeName('M {} // A');
    assertTypeName(mRef, mElement, 'M');
  }

  test_classTypeAlias_with() async {
    addTestFile(r'''
mixin M {}
class A = Object with M;
''');
    await resolveTestFile();
    assertNoTestErrors();

    var mElement = findElement.mixin('M');

    var aElement = findElement.class_('A');
    assertElementTypes(aElement.mixins, [mElement.type]);

    var mRef = findNode.typeName('M;');
    assertTypeName(mRef, mElement, 'M');
  }

  test_commentReference() async {
    addTestFile(r'''
const a = 0;

/// Reference [a] in documentation.
mixin M {}
''');
    await resolveTestFile();
    assertNoTestErrors();

    var aRef = findNode.commentReference('a]').identifier;
    assertElement(aRef, findElement.topGet('a'));
    assertTypeNull(aRef);
  }

  test_conflictingGenericInterfaces() async {
    addTestFile('''
class I<T> {}
class A implements I<int> {}
class B implements I<String> {}
mixin M on A implements B {}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_GENERIC_INTERFACES]);
  }

  test_element() async {
    addTestFile(r'''
mixin M {}
''');
    await resolveTestFile();
    assertNoTestErrors();

    var mixin = findNode.mixin('mixin M');
    var element = findElement.mixin('M');
    assertElement(mixin, element);

    expect(element.typeParameters, isEmpty);

    expect(element.supertype, isNull);
    expect(element.isAbstract, isTrue);
    expect(element.isEnum, isFalse);
    expect(element.isMixin, isTrue);
    expect(element.isMixinApplication, isFalse);
    expect(element.type.isObject, isFalse);

    assertElementTypes(element.superclassConstraints, [objectType]);
    assertElementTypes(element.interfaces, []);
  }

  test_element_allSupertypes() async {
    addTestFile(r'''
class A {}
class B {}
class C {}

mixin M1 on A, B {}
mixin M2 on A implements B, C {}
''');
    await resolveTestFile();
    assertNoTestErrors();

    var a = findElement.class_('A');
    var b = findElement.class_('B');
    var c = findElement.class_('C');
    assertElementTypes(
      findElement.mixin('M1').allSupertypes,
      [a.type, b.type, objectType],
    );
    assertElementTypes(
      findElement.mixin('M2').allSupertypes,
      [a.type, objectType, b.type, c.type],
    );
  }

  test_element_allSupertypes_generic() async {
    addTestFile(r'''
class A<T, U> {}
class B<T> extends A<int, T> {}

mixin M1 on A<int, double> {}
mixin M2 on B<String> {}
''');
    await resolveTestFile();
    assertNoTestErrors();

    var a = findElement.class_('A');
    var b = findElement.class_('B');
    assertElementTypes(
      findElement.mixin('M1').allSupertypes,
      [
        a.type.instantiate([intType, doubleType]),
        objectType
      ],
    );
    assertElementTypes(
      findElement.mixin('M2').allSupertypes,
      [
        b.type.instantiate([stringType]),
        a.type.instantiate([intType, stringType]),
        objectType
      ],
    );
  }

  test_error_builtInIdentifierAsTypeName() async {
    addTestFile(r'''
mixin as {}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME]);
  }

  test_error_builtInIdentifierAsTypeName_OK_on() async {
    addTestFile(r'''
class A {}

mixin on on A {}

mixin M on on {}

mixin M2 implements on {}

class B = A with on;
class C = B with M;
class D = Object with M2;
''');
    await resolveTestFile();
    assertNoTestErrors();
  }

  test_error_conflictingStaticAndInstance_inClass_getter_getter() async {
    addTestFile(r'''
mixin M {
  static int get foo => 0;
  int get foo => 0;
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inClass_getter_method() async {
    addTestFile(r'''
mixin M {
  static int get foo => 0;
  void foo() {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inClass_getter_setter() async {
    addTestFile(r'''
mixin M {
  static int get foo => 0;
  set foo(_) {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inClass_method_getter() async {
    addTestFile(r'''
mixin M {
  static void foo() {}
  int get foo => 0;
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inClass_method_method() async {
    addTestFile(r'''
mixin M {
  static void foo() {}
  void foo() {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inClass_method_setter() async {
    addTestFile(r'''
mixin M {
  static void foo() {}
  set foo(_) {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inClass_setter_getter() async {
    addTestFile(r'''
mixin M {
  static set foo(_) {}
  int get foo => 0;
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inClass_setter_method() async {
    addTestFile(r'''
mixin M {
  static set foo(_) {}
  void foo() {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inClass_setter_setter() async {
    addTestFile(r'''
mixin M {
  static set foo(_) {}
  set foo(_) {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inConstraint_getter_getter() async {
    addTestFile(r'''
class A {
  int get foo => 0;
}
mixin M on A {
  static int get foo => 0;
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inConstraint_getter_method() async {
    addTestFile(r'''
class A {
  int get foo => 0;
}
mixin M on A {
  static void foo() {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inConstraint_getter_setter() async {
    addTestFile(r'''
class A {
  set foo(_) {}
}
mixin M on A {
  static int get foo => 0;
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inConstraint_method_getter() async {
    addTestFile(r'''
class A {
  int get foo => 0;
}
mixin M on A {
  static void foo() {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inConstraint_method_method() async {
    addTestFile(r'''
class A {
  void foo() {}
}
mixin M on A {
  static void foo() {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inConstraint_method_setter() async {
    addTestFile(r'''
class A {
  set foo(_) {}
}
mixin M on A {
  static void foo() {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inConstraint_setter_method() async {
    addTestFile(r'''
class A {
  void foo() {}
}
mixin M on A {
  static set foo(_) {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inConstraint_setter_setter() async {
    addTestFile(r'''
class A {
  set foo(_) {}
}
mixin M on A {
  static set foo(_) {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inInterface_getter_getter() async {
    addTestFile(r'''
class A {
  int get foo => 0;
}
mixin M implements A {
  static int get foo => 0;
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inInterface_getter_method() async {
    addTestFile(r'''
class A {
  int get foo => 0;
}
mixin M implements A {
  static void foo() {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inInterface_getter_setter() async {
    addTestFile(r'''
class A {
  set foo(_) {}
}
mixin M implements A {
  static int get foo => 0;
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inInterface_method_getter() async {
    addTestFile(r'''
class A {
  int get foo => 0;
}
mixin M implements A {
  static void foo() {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inInterface_method_method() async {
    addTestFile(r'''
class A {
  void foo() {}
}
mixin M implements A {
  static void foo() {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inInterface_method_setter() async {
    addTestFile(r'''
class A {
  set foo(_) {}
}
mixin M implements A {
  static void foo() {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inInterface_setter_method() async {
    addTestFile(r'''
class A {
  void foo() {}
}
mixin M implements A {
  static set foo(_) {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inInterface_setter_setter() async {
    addTestFile(r'''
class A {
  set foo(_) {}
}
mixin M implements A {
  static set foo(_) {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingTypeVariableAndClass() async {
    addTestFile(r'''
mixin M<M> {}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_CLASS,
    ]);
  }

  test_error_conflictingTypeVariableAndMember_field() async {
    addTestFile(r'''
mixin M<T> {
  var T;
}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER,
    ]);
  }

  test_error_conflictingTypeVariableAndMember_getter() async {
    addTestFile(r'''
mixin M<T> {
  get T => null;
}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER,
    ]);
  }

  test_error_conflictingTypeVariableAndMember_method() async {
    addTestFile(r'''
mixin M<T> {
  T() {}
}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER,
    ]);
  }

  test_error_conflictingTypeVariableAndMember_method_static() async {
    addTestFile(r'''
mixin M<T> {
  static T() {}
}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER,
    ]);
  }

  test_error_conflictingTypeVariableAndMember_setter() async {
    addTestFile(r'''
mixin M<T> {
  void set T(_) {}
}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER,
    ]);
  }

  test_error_duplicateDefinition_field() async {
    addTestFile(r'''
mixin M {
  int t;
  int t;
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.DUPLICATE_DEFINITION]);
  }

  test_error_duplicateDefinition_field_method() async {
    addTestFile(r'''
mixin M {
  int t;
  void t() {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.DUPLICATE_DEFINITION]);
  }

  test_error_duplicateDefinition_getter() async {
    addTestFile(r'''
mixin M {
  int get t => 0;
  int get t => 0;
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.DUPLICATE_DEFINITION]);
  }

  test_error_duplicateDefinition_getter_method() async {
    addTestFile(r'''
mixin M {
  int get foo => 0;
  void foo() {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.DUPLICATE_DEFINITION]);
  }

  test_error_duplicateDefinition_method() async {
    addTestFile(r'''
mixin M {
  void t() {}
  void t() {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.DUPLICATE_DEFINITION]);
  }

  test_error_duplicateDefinition_method_getter() async {
    addTestFile(r'''
mixin M {
  void foo() {}
  int get foo => 0;
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.DUPLICATE_DEFINITION]);
  }

  test_error_duplicateDefinition_setter() async {
    addTestFile(r'''
mixin M {
  void set t(_) {}
  void set t(_) {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.DUPLICATE_DEFINITION]);
  }

  test_error_finalNotInitialized() async {
    addTestFile(r'''
mixin M {
  final int f;
}
''');
    await resolveTestFile();
    assertTestErrors([StaticWarningCode.FINAL_NOT_INITIALIZED]);
  }

  test_error_finalNotInitialized_OK() async {
    addTestFile(r'''
mixin M {
  final int f = 0;
}
''');
    await resolveTestFile();
    assertNoTestErrors();
  }

  test_error_finalNotInitializedConstructor() async {
    addTestFile(r'''
mixin M {
  final int f;
  M();
}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.MIXIN_DECLARES_CONSTRUCTOR,
      StaticWarningCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_1,
    ]);
  }

  test_error_finalNotInitializedConstructor_OK() async {
    addTestFile(r'''
mixin M {
  final int f;
  M(this.f);
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.MIXIN_DECLARES_CONSTRUCTOR]);

    var element = findElement.mixin('M');
    var constructorElement = element.constructors.single;

    var fpNode = findNode.fieldFormalParameter('f);');
    assertElement(fpNode.identifier, constructorElement.parameters[0]);

    FieldFormalParameterElement fpElement = fpNode.declaredElement;
    expect(fpElement.field, same(findElement.field('f')));
  }

  test_error_implementsClause_deferredClass() async {
    addTestFile(r'''
import 'dart:math' deferred as math;
mixin M implements math.Random {}
''');
    await resolveTestFile();
    var mathImport = findElement.import('dart:math');
    var randomElement = mathImport.importedLibrary.getType('Random');

    assertTestErrors([
      CompileTimeErrorCode.IMPLEMENTS_DEFERRED_CLASS,
    ]);

    var element = findElement.mixin('M');
    assertElementTypes(element.interfaces, [randomElement.type]);

    var typeRef = findNode.typeName('Random {}');
    assertTypeName(typeRef, randomElement, 'Random',
        expectedPrefix: mathImport.prefix);
  }

  test_error_implementsClause_disallowedClass_int() async {
    addTestFile(r'''
mixin M implements int {}
''');
    await resolveTestFile();

    assertTestErrors([
      CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS,
    ]);

    var element = findElement.mixin('M');
    assertElementTypes(element.interfaces, [intType]);

    var typeRef = findNode.typeName('int {}');
    assertTypeName(typeRef, intElement, 'int');
  }

  test_error_implementsClause_nonClass_void() async {
    addTestFile(r'''
mixin M implements void {}
''');
    await resolveTestFile();

    assertTestErrors([
      CompileTimeErrorCode.IMPLEMENTS_NON_CLASS,
      ParserErrorCode.EXPECTED_TYPE_NAME,
    ]);

    var element = findElement.mixin('M');
    assertElementTypes(element.interfaces, []);

    var typeRef = findNode.typeName('void {}');
    assertTypeName(typeRef, null, 'void');
  }

  test_error_implementsRepeated() async {
    addTestFile(r'''
class A {}
mixin M implements A, A {}
''');
    await resolveTestFile();
    CompileTimeErrorCode.IMPLEMENTS_REPEATED;
    assertTestErrors([CompileTimeErrorCode.IMPLEMENTS_REPEATED]);
  }

  test_error_memberWithClassName_getter() async {
    addTestFile(r'''
mixin M {
  int get M => 0;
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.MEMBER_WITH_CLASS_NAME]);
  }

  test_error_memberWithClassName_getter_static() async {
    addTestFile(r'''
mixin M {
  static int get M => 0;
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.MEMBER_WITH_CLASS_NAME]);
  }

  test_error_memberWithClassName_setter() async {
    addTestFile(r'''
mixin M {
  void set M(_) {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.MEMBER_WITH_CLASS_NAME]);
  }

  test_error_memberWithClassName_setter_static() async {
    addTestFile(r'''
mixin M {
  static void set M(_) {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.MEMBER_WITH_CLASS_NAME]);
  }

  test_error_mixinApplicationConcreteSuperInvokedMemberType_method() async {
    addTestFile(r'''
class I {
  void foo([int p]) {}
}

class A {
  void foo(int p) {}
}

abstract class B extends A implements I {
  void foo([int p]);
}

mixin M on I {
  void bar() {
    super.foo(42);
  }
}

abstract class X extends B with M {}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.MIXIN_APPLICATION_CONCRETE_SUPER_INVOKED_MEMBER_TYPE,
    ]);
  }

  test_error_mixinApplicationConcreteSuperInvokedMemberType_OK_method_overriddenInMixin() async {
    addTestFile(r'''
class A<T> {
  void remove(T x) {}
}

mixin M<U> on A<U> {
  void remove(Object x) {
    super.remove(x as U);
  }
}

class X<T> = A<T> with M<T>;
''');
    await resolveTestFile();
    assertNoTestErrors();
  }

  test_error_mixinApplicationNoConcreteSuperInvokedMember_getter() async {
    addTestFile(r'''
abstract class A {
  int get foo;
}

mixin M on A {
  void bar() {
    super.foo;
  }
}

abstract class X extends A with M {}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.MIXIN_APPLICATION_NO_CONCRETE_SUPER_INVOKED_MEMBER,
    ]);
  }

  test_error_mixinApplicationNoConcreteSuperInvokedMember_inNextMixin() async {
    addTestFile('''
abstract class A {
  void foo();
}

mixin M1 on A {
  void foo() {
    super.foo();
  }
}

mixin M2 on A {
  void foo() {}
}

class X extends A with M1, M2 {}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.MIXIN_APPLICATION_NO_CONCRETE_SUPER_INVOKED_MEMBER
    ]);
  }

  test_error_mixinApplicationNoConcreteSuperInvokedMember_inSameMixin() async {
    addTestFile('''
abstract class A {
  void foo();
}

mixin M on A {
  void foo() {
    super.foo();
  }
}

class X extends A with M {}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.MIXIN_APPLICATION_NO_CONCRETE_SUPER_INVOKED_MEMBER
    ]);
  }

  test_error_mixinApplicationNoConcreteSuperInvokedMember_method() async {
    addTestFile(r'''
abstract class A {
  void foo();
}

mixin M on A {
  void bar() {
    super.foo();
  }
}

abstract class X extends A with M {}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.MIXIN_APPLICATION_NO_CONCRETE_SUPER_INVOKED_MEMBER,
    ]);
  }

  test_error_mixinApplicationNoConcreteSuperInvokedMember_OK_hasNSM() async {
    addTestFile(r'''
abstract class A {
  void foo();
}

mixin M on A {
  void bar() {
    super.foo();
  }
}

class C implements A {
  noSuchMethod(_) {}
}

class X extends C with M {}
''');
    await resolveTestFile();
    assertNoTestErrors();
  }

  test_error_mixinApplicationNoConcreteSuperInvokedMember_OK_hasNSM2() async {
    addTestFile(r'''
abstract class A {
  void foo();
}

mixin M on A {
  void bar() {
    super.foo();
  }
}

/// Class `B` has noSuchMethod forwarder for `foo`.
class B implements A {
  noSuchMethod(_) {}
}

/// Class `C` is abstract, but it inherits noSuchMethod forwarders from `B`.
abstract class C extends B {}

class X extends C with M {}
''');
    await resolveTestFile();
    assertNoTestErrors();
  }

  test_error_mixinApplicationNoConcreteSuperInvokedMember_OK_inPreviousMixin() async {
    addTestFile(r'''
abstract class A {
  void foo();
}

mixin M1 {
  void foo() {}
}

mixin M2 on A {
  void bar() {
    super.foo();
  }
}

class X extends A with M1, M2 {}
''');
    await resolveTestFile();
    assertNoTestErrors();
  }

  test_error_mixinApplicationNoConcreteSuperInvokedMember_OK_inSuper_fromMixin() async {
    addTestFile(r'''
abstract class A {
  void foo();
}

mixin M1 {
  void foo() {}
}

class B extends A with M1 {}

mixin M2 on A {
  void bar() {
    super.foo();
  }
}

class X extends B with M2 {}
''');
    await resolveTestFile();
    assertNoTestErrors();
  }

  test_error_mixinApplicationNoConcreteSuperInvokedMember_OK_notInvoked() async {
    addTestFile(r'''
abstract class A {
  void foo();
}

mixin M on A {}

abstract class X extends A with M {}
''');
    await resolveTestFile();
    assertNoTestErrors();
  }

  test_error_mixinApplicationNoConcreteSuperInvokedMember_OK_super_covariant() async {
    addTestFile(r'''
class A {
  bar(num n) {}
}

mixin M on A {
  test() {
    super.bar(3.14);
  }
}

class B implements A {
  bar(covariant int i) {}
}

class C extends B with M {}
''');
    await resolveTestFile();
    assertNoTestErrors();
  }

  test_error_mixinApplicationNoConcreteSuperInvokedMember_setter() async {
    addTestFile(r'''
abstract class A {
  void set foo(_);
}

mixin M on A {
  void bar() {
    super.foo = 0;
  }
}

abstract class X extends A with M {}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.MIXIN_APPLICATION_NO_CONCRETE_SUPER_INVOKED_MEMBER,
    ]);
  }

  test_error_mixinApplicationNotImplementedInterface() async {
    addTestFile(r'''
class A {}

mixin M on A {}

class X = Object with M;
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE,
    ]);
  }

  test_error_mixinApplicationNotImplementedInterface_generic() async {
    addTestFile(r'''
class A<T> {}

mixin M on A<int> {}

class X = A<double> with M;
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE,
    ]);
  }

  test_error_mixinApplicationNotImplementedInterface_noMemberErrors() async {
    addTestFile(r'''
class A {
  void foo() {}
}

mixin M on A {
  void bar() {
    super.foo();
  }
}

class C {
  noSuchMethod(_) {}
}

class X = C with M;
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE,
    ]);
  }

  test_error_mixinApplicationNotImplementedInterface_OK_0() async {
    addTestFile(r'''
mixin M {}

class X = Object with M;
''');
    await resolveTestFile();
    assertNoTestErrors();
  }

  test_error_mixinApplicationNotImplementedInterface_OK_1() async {
    addTestFile(r'''
class A {}

mixin M on A {}

class X = A with M;
''');
    await resolveTestFile();
    assertNoTestErrors();
  }

  test_error_mixinApplicationNotImplementedInterface_OK_generic() async {
    addTestFile(r'''
class A<T> {}

mixin M<T> on A<T> {}

class B<T> implements A<T> {}

class C<T> = B<T> with M<T>;
''');
    await resolveTestFile();
    assertNoTestErrors();
  }

  test_error_mixinApplicationNotImplementedInterface_OK_previousMixin() async {
    addTestFile(r'''
class A {}

mixin M1 implements A {}

mixin M2 on A {}

class X = Object with M1, M2;
''');
    await resolveTestFile();
    assertNoTestErrors();
  }

  test_error_mixinApplicationNotImplementedInterface_oneOfTwo() async {
    addTestFile(r'''
class A {}
class B {}
class C {}

mixin M on A, B {}

class X = C with M;
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE,
    ]);
  }

  test_error_mixinDeclaresConstructor() async {
    addTestFile(r'''
mixin M {
  M(int a) {
    a; // read
  }
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.MIXIN_DECLARES_CONSTRUCTOR]);

    // Even though it is an error for a mixin to declare a constructor,
    // we still build elements for constructors, and resolve them.

    var element = findElement.mixin('M');
    var constructors = element.constructors;
    expect(constructors, hasLength(1));
    var constructorElement = constructors[0];

    var constructorNode = findNode.constructor('M(int a)');
    assertElement(constructorNode, constructorElement);

    var aElement = constructorElement.parameters[0];
    var aNode = constructorNode.parameters.parameters[0];
    assertElement(aNode, aElement);

    var aRef = findNode.simple('a; // read');
    assertElement(aRef, aElement);
    assertType(aRef, 'int');
  }

  test_error_mixinInstantiate_default() async {
    addTestFile(r'''
mixin M {}

main() {
  new M();
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.MIXIN_INSTANTIATE]);

    var creation = findNode.instanceCreation('M();');
    var m = findElement.mixin('M');
    assertInstanceCreation(creation, m, 'M');
  }

  test_error_mixinInstantiate_named() async {
    addTestFile(r'''
mixin M {
  M.named() {}
}

main() {
  new M.named();
}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.MIXIN_DECLARES_CONSTRUCTOR,
      CompileTimeErrorCode.MIXIN_INSTANTIATE,
    ]);

    var creation = findNode.instanceCreation('M.named();');
    var m = findElement.mixin('M');
    assertInstanceCreation(creation, m, 'M', constructorName: 'named');
  }

  test_error_mixinInstantiate_undefined() async {
    addTestFile(r'''
mixin M {}

main() {
  new M.named();
}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.MIXIN_INSTANTIATE,
    ]);

    var creation = findNode.instanceCreation('M.named();');
    var m = findElement.mixin('M');
    assertElement(creation.constructorName.type.name, m);
  }

  test_error_onClause_deferredClass() async {
    addTestFile(r'''
import 'dart:math' deferred as math;
mixin M on math.Random {}
''');
    await resolveTestFile();
    var mathImport = findElement.import('dart:math');
    var randomElement = mathImport.importedLibrary.getType('Random');

    assertTestErrors([
      CompileTimeErrorCode.MIXIN_SUPER_CLASS_CONSTRAINT_DEFERRED_CLASS,
    ]);

    var element = findElement.mixin('M');
    assertElementTypes(element.superclassConstraints, [randomElement.type]);

    var typeRef = findNode.typeName('Random {}');
    assertTypeName(typeRef, randomElement, 'Random',
        expectedPrefix: mathImport.prefix);
  }

  test_error_onClause_disallowedClass_int() async {
    addTestFile(r'''
mixin M on int {}
''');
    await resolveTestFile();

    assertTestErrors([
      CompileTimeErrorCode.MIXIN_SUPER_CLASS_CONSTRAINT_DISALLOWED_CLASS,
    ]);

    var element = findElement.mixin('M');
    assertElementTypes(element.superclassConstraints, [intType]);

    var typeRef = findNode.typeName('int {}');
    assertTypeName(typeRef, intElement, 'int');
  }

  test_error_onClause_nonInterface_dynamic() async {
    addTestFile(r'''
mixin M on dynamic {}
''');
    await resolveTestFile();

    assertTestErrors([
      CompileTimeErrorCode.MIXIN_SUPER_CLASS_CONSTRAINT_NON_INTERFACE,
    ]);

    var element = findElement.mixin('M');
    assertElementTypes(element.superclassConstraints, [objectType]);

    var typeRef = findNode.typeName('dynamic {}');
    assertTypeName(typeRef, dynamicElement, 'dynamic');
  }

  test_error_onClause_nonInterface_enum() async {
    addTestFile(r'''
enum E {E1, E2, E3}
mixin M on E {}
''');
    await resolveTestFile();

    assertTestErrors([
      CompileTimeErrorCode.MIXIN_SUPER_CLASS_CONSTRAINT_NON_INTERFACE,
    ]);

    var element = findElement.mixin('M');
    assertElementTypes(element.superclassConstraints, [objectType]);

    var typeRef = findNode.typeName('E {}');
    assertTypeName(typeRef, findElement.enum_('E'), 'E');
  }

  test_error_onClause_nonInterface_void() async {
    addTestFile(r'''
mixin M on void {}
''');
    await resolveTestFile();

    assertTestErrors([
      CompileTimeErrorCode.MIXIN_SUPER_CLASS_CONSTRAINT_NON_INTERFACE,
      ParserErrorCode.EXPECTED_TYPE_NAME,
    ]);

    var element = findElement.mixin('M');
    assertElementTypes(element.superclassConstraints, [objectType]);

    var typeRef = findNode.typeName('void {}');
    assertTypeName(typeRef, null, 'void');
  }

  test_error_onClause_OK_mixin() async {
    addTestFile(r'''
mixin A {}
mixin B on A {} // ref
''');
    await resolveTestFile();
    assertNoTestErrors();

    var a = findElement.mixin('A');
    var b = findElement.mixin('B');
    assertElementTypes(b.superclassConstraints, [a.type]);
  }

  test_error_onRepeated() async {
    addTestFile(r'''
class A {}
mixin M on A, A {}
''');
    await resolveTestFile();
    CompileTimeErrorCode.IMPLEMENTS_REPEATED;
    assertTestErrors([CompileTimeErrorCode.ON_REPEATED]);
  }

  test_error_undefinedSuperMethod() async {
    addTestFile(r'''
class A {}

mixin M on A {
  void bar() {
    super.foo(42);
  }
}
''');
    await resolveTestFile();
    assertTestErrors([StaticTypeWarningCode.UNDEFINED_SUPER_METHOD]);

    var invocation = findNode.methodInvocation('foo(42)');
    assertElementNull(invocation.methodName);
    assertInvokeTypeDynamic(invocation);
    assertTypeDynamic(invocation);
  }

  test_field() async {
    addTestFile(r'''
mixin M<T> {
  T f;
}
''');
    await resolveTestFile();
    assertNoTestErrors();

    var element = findElement.mixin('M');

    var typeParameters = element.typeParameters;
    expect(typeParameters, hasLength(1));

    var tElement = typeParameters.single;
    assertElementName(tElement, 'T', offset: 8);
    assertEnclosingElement(tElement, element);

    var tNode = findNode.typeParameter('T> {');
    assertElement(tNode.name, tElement);

    var fields = element.fields;
    expect(fields, hasLength(1));

    var fElement = fields[0];
    assertElementName(fElement, 'f', offset: 17);
    assertEnclosingElement(fElement, element);

    var fNode = findNode.variableDeclaration('f;');
    assertElement(fNode.name, fElement);

    assertTypeName(findNode.typeName('T f'), tElement, 'T');

    var accessors = element.accessors;
    expect(accessors, hasLength(2));
    assertElementName(accessors[0], 'f', isSynthetic: true);
    assertElementName(accessors[1], 'f=', isSynthetic: true);
  }

  test_implementsClause() async {
    addTestFile(r'''
class A {}
class B {}

mixin M implements A, B {} // M
''');
    await resolveTestFile();
    assertNoTestErrors();

    var element = findElement.mixin('M');
    assertElementTypes(element.interfaces, [
      findElement.interfaceType('A'),
      findElement.interfaceType('B'),
    ]);

    var aRef = findNode.typeName('A, ');
    assertTypeName(aRef, findElement.class_('A'), 'A');

    var bRef = findNode.typeName('B {} // M');
    assertTypeName(bRef, findElement.class_('B'), 'B');
  }

  test_inconsistentInheritance_implements_parameterType() async {
    addTestFile(r'''
abstract class A {
  x(int i);
}
abstract class B {
  x(String s);
}
mixin M implements A, B {}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.INCONSISTENT_INHERITANCE,
    ]);
  }

  test_inconsistentInheritance_implements_requiredParameters() async {
    addTestFile(r'''
abstract class A {
  x();
}
abstract class B {
  x(int y);
}
mixin M implements A, B {}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.INCONSISTENT_INHERITANCE,
    ]);
  }

  test_inconsistentInheritance_implements_returnType() async {
    addTestFile(r'''
abstract class A {
  int x();
}
abstract class B {
  String x();
}
mixin M implements A, B {}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.INCONSISTENT_INHERITANCE,
    ]);
  }

  test_inconsistentInheritance_on_parameterType() async {
    addTestFile(r'''
abstract class A {
  x(int i);
}
abstract class B {
  x(String s);
}
mixin M on A, B {}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.INCONSISTENT_INHERITANCE,
    ]);
  }

  test_inconsistentInheritance_on_requiredParameters() async {
    addTestFile(r'''
abstract class A {
  x();
}
abstract class B {
  x(int y);
}
mixin M on A, B {}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.INCONSISTENT_INHERITANCE,
    ]);
  }

  test_inconsistentInheritance_on_returnType() async {
    addTestFile(r'''
abstract class A {
  int x();
}
abstract class B {
  String x();
}
mixin M on A, B {}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.INCONSISTENT_INHERITANCE,
    ]);
  }

  test_inconsistentInheritanceGetterAndMethod_implements_getter_method() async {
    addTestFile(r'''
abstract class A {
  int get x;
}
abstract class B {
  int x();
}
mixin M implements A, B {}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.INCONSISTENT_INHERITANCE_GETTER_AND_METHOD,
    ]);
  }

  test_inconsistentInheritanceGetterAndMethod_implements_method_getter() async {
    addTestFile(r'''
abstract class A {
  int x();
}
abstract class B {
  int get x;
}
mixin M implements A, B {}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.INCONSISTENT_INHERITANCE_GETTER_AND_METHOD,
    ]);
  }

  test_inconsistentInheritanceGetterAndMethod_on_getter_method() async {
    addTestFile(r'''
abstract class A {
  int get x;
}
abstract class B {
  int x();
}
mixin M implements A, B {}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.INCONSISTENT_INHERITANCE_GETTER_AND_METHOD,
    ]);
  }

  test_inconsistentInheritanceGetterAndMethod_on_method_getter() async {
    addTestFile(r'''
abstract class A {
  int x();
}
abstract class B {
  int get x;
}
mixin M implements A, B {}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.INCONSISTENT_INHERITANCE_GETTER_AND_METHOD,
    ]);
  }

  test_invalid_unresolved_before_mixin() async {
    addTestFile(r'''
abstract class A {
  int foo();
}

mixin M on A {
  void bar() {
    super.foo();
  }
}

abstract class X extends A with U1, U2, M {}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.MIXIN_APPLICATION_NO_CONCRETE_SUPER_INVOKED_MEMBER,
      CompileTimeErrorCode.MIXIN_OF_NON_CLASS,
      CompileTimeErrorCode.MIXIN_OF_NON_CLASS,
      StaticWarningCode.UNDEFINED_CLASS,
      StaticWarningCode.UNDEFINED_CLASS,
    ]);
  }

  test_isMoreSpecificThan() async {
    addTestFile(r'''
mixin M {}
''');
    await resolveTestFile();
    assertNoTestErrors();

    var element = findElement.mixin('M');
    var type = element.type;
    expect(type.isMoreSpecificThan(intType), isFalse);
  }

  test_lookUpMemberInInterfaces_Object() async {
    addTestFile(r'''
class Foo {}

mixin UnhappyMixin on Foo {
  String toString() => '$runtimeType';
}
''');
    await resolveTestFile();
    assertNoTestErrors();
  }

  test_metadata() async {
    addTestFile(r'''
const a = 0;

@a
mixin M {}
''');
    await resolveTestFile();
    assertNoTestErrors();

    var a = findElement.topGet('a');
    var element = findElement.mixin('M');

    var metadata = element.metadata;
    expect(metadata, hasLength(1));
    expect(metadata[0].element, same(a));

    var annotation = findNode.annotation('@a');
    assertElement(annotation, a);
    expect(annotation.elementAnnotation, same(metadata[0]));
  }

  test_methodCallTypeInference_mixinType() async {
    addTestFile('''
main() {
  C<int> c = f();
}

class C<T> {}

mixin M<T> on C<T> {}

M<T> f<T>() => null;
''');
    await resolveTestFile();
    assertNoTestErrors();
    var fInvocation = findNode.methodInvocation('f()');
    expect(fInvocation.staticInvokeType.toString(), '() → M<int>');
  }

  test_onClause() async {
    addTestFile(r'''
class A {}
class B {}

mixin M on A, B {} // M
''');
    await resolveTestFile();
    assertNoTestErrors();

    var element = findElement.mixin('M');
    assertElementTypes(element.superclassConstraints, [
      findElement.interfaceType('A'),
      findElement.interfaceType('B'),
    ]);

    var aRef = findNode.typeName('A, ');
    assertTypeName(aRef, findElement.class_('A'), 'A');

    var bRef = findNode.typeName('B {} // M');
    assertTypeName(bRef, findElement.class_('B'), 'B');
  }

  test_recursiveInterfaceInheritance_implements() async {
    addTestFile(r'''
mixin A implements B {}
mixin B implements A {}''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE
    ]);
  }

  test_recursiveInterfaceInheritance_on() async {
    addTestFile(r'''
mixin A on B {}
mixin B on A {}''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE
    ]);
  }

  test_recursiveInterfaceInheritanceOn() async {
    addTestFile(r'''
mixin A on A {}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_ON,
    ]);
  }

  test_superInvocation_getter() async {
    addTestFile(r'''
class A {
  int get foo => 0;
}

mixin M on A {
  void bar() {
    super.foo;
  }
}

class X extends A with M {}
''');
    await resolveTestFile();
    assertNoTestErrors();

    var access = findNode.propertyAccess('super.foo;');
    assertElement(access, findElement.getter('foo'));
    assertType(access, 'int');
  }

  test_superInvocation_method() async {
    addTestFile(r'''
class A {
  void foo(int x) {}
}

mixin M on A {
  void bar() {
    super.foo(42);
  }
}

class X extends A with M {}
''');
    await resolveTestFile();
    assertNoTestErrors();

    var invocation = findNode.methodInvocation('foo(42)');
    assertElement(invocation, findElement.method('foo'));
    assertInvokeType(invocation, '(int) → void');
    assertType(invocation, 'void');
  }

  test_superInvocation_setter() async {
    addTestFile(r'''
class A {
  void set foo(_) {}
}

mixin M on A {
  void bar() {
    super.foo = 0;
  }
}

class X extends A with M {}
''');
    await resolveTestFile();
    assertNoTestErrors();

    var access = findNode.propertyAccess('super.foo = 0');
    assertElement(access, findElement.setter('foo'));
    // Hm... Does it need any type?
    assertTypeDynamic(access);
  }
}
