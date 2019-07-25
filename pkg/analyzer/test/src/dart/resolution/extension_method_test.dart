// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionMethodsDeclarationTest);
    defineReflectiveTests(ExtensionMethodsExternalReferenceTest);
    defineReflectiveTests(ExtensionMethodsInternalReferenceTest);
  });
}

abstract class BaseExtensionMethodsTest extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = new FeatureSet.forTesting(
        sdkVersion: '2.3.0', additionalFeatures: [Feature.extension_methods]);
}

/// Tests that show that extension declarations and the members inside them are
/// resolved correctly.
@reflectiveTest
class ExtensionMethodsDeclarationTest extends BaseExtensionMethodsTest {
  @failingTest
  test_metadata() async {
    await assertNoErrorsInCode('''
const int ann = 1;
class C {}
@ann
extension E on C {}
''');
    var annotation = findNode.annotation('@ann');
    assertElement(annotation, findElement.topVar('ann'));
  }

  test_multipleExtensions_noConflict() async {
    await assertNoErrorsInCode('''
class C {}
extension E1 on C {}
extension E2 on C {}
''');
  }

  test_named_generic() async {
    await assertNoErrorsInCode('''
class C<T> {}
extension E<S> on C<S> {}
''');
    var extendedType = findNode.typeAnnotation('C<S>');
    assertElement(extendedType, findElement.class_('C'));
    assertType(extendedType, 'C<S>');
  }

  test_named_onDynamic() async {
    await assertNoErrorsInCode('''
extension E on dynamic {}
''');
    var extendedType = findNode.typeAnnotation('dynamic');
    assertType(extendedType, 'dynamic');
  }

  test_named_onEnum() async {
    await assertNoErrorsInCode('''
enum A {a, b, c}
extension E on A {}
''');
    var extendedType = findNode.typeAnnotation('A {}');
    assertElement(extendedType, findElement.enum_('A'));
    assertType(extendedType, 'A');
  }

  @failingTest
  test_named_onFunctionType() async {
    await assertNoErrorsInCode('''
extension E on int Function(int) {}
''');
    var extendedType = findNode.typeAnnotation('int ');
    assertType(extendedType, 'int Function(int)');
  }

  test_named_onInterface() async {
    await assertNoErrorsInCode('''
class C { }
extension E on C {}
''');
    var extendedType = findNode.typeAnnotation('C {}');
    assertElement(extendedType, findElement.class_('C'));
    assertType(extendedType, 'C');
  }

  test_unnamed_generic() async {
    await assertNoErrorsInCode('''
class C<T> {}
extension<S> on C<S> {}
''');
    var extendedType = findNode.typeAnnotation('C<S>');
    assertElement(extendedType, findElement.class_('C'));
    assertType(extendedType, 'C<S>');
  }

  test_unnamed_onDynamic() async {
    await assertNoErrorsInCode('''
extension on dynamic {}
''');
    var extendedType = findNode.typeAnnotation('dynamic');
    assertType(extendedType, 'dynamic');
  }

  test_unnamed_onEnum() async {
    await assertNoErrorsInCode('''
enum A {a, b, c}
extension on A {}
''');
    var extendedType = findNode.typeAnnotation('A {}');
    assertElement(extendedType, findElement.enum_('A'));
    assertType(extendedType, 'A');
  }

  @failingTest
  test_unnamed_onFunctionType() async {
    await assertNoErrorsInCode('''
extension on int Function(int) {}
''');
    var extendedType = findNode.typeAnnotation('int ');
    assertType(extendedType, 'int Function(int)');
  }

  test_unnamed_onInterface() async {
    await assertNoErrorsInCode('''
class C { }
extension on C {}
''');
    var extendedType = findNode.typeAnnotation('C {}');
    assertElement(extendedType, findElement.class_('C'));
    assertType(extendedType, 'C');
  }
}

/// Tests that extension members can be correctly resolved when referenced
/// by code external to the extension declaration.
@reflectiveTest
class ExtensionMethodsExternalReferenceTest extends BaseExtensionMethodsTest {
  test_getter_noMatch() async {
    await assertErrorsInCode(r'''
class B {}

extension A on B {}

Object f() {
  B b = B();
  return b.a;
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_GETTER, 70, 1),
    ]);
  }

  test_getter_oneMatch() async {
    await assertNoErrorsInCode('''
class B {}

extension A on B {
  int get a => 1;
}

f() {
  B b = B();
  int x = b.a;
}
''');
  }

  test_getter_specificSubtypeMatchLocal() async {
    await assertNoErrorsInCode('''
class A {}

class B extends A { 
  int get b => 1;
}

extension A_Ext on A {
  int get a => 1;
}

extension B_Ext on B {
  int /*2*/ get a => 2;
}

f() {
  B b = B();
  int x = b.a;
}
''');

    var invocation = findNode.prefixed('b.a');
    var declaration = findNode.methodDeclaration('int /*2*/ get a');
    expect(invocation.identifier.staticElement, declaration.declaredElement);
  }

  test_method_moreSpecificThanPlatform() async {
    //
    // An extension with on type clause T1 is more specific than another
    // extension with on type clause T2 iff
    //
    // 1. The latter extension is declared in a platform library, and the former
    //    extension is not
    //
    newFile('/test/lib/core.dart', content: '''
library dart.core;

class Core {}
''');

    await assertNoErrorsInCode('''
import 'core.dart' as platform;

class Core2 extends platform.Core {}

extension Core_Ext on platform.Core {
  void a() {}
}

extension Core2_Ext on Core2 {
  void a() {}
}

f() {
  Core2 c = Core2();
  c.a();
}
''');
    var invocation = findNode.methodInvocation('c.a()');
    assertElement(invocation, findElement.method('a', of: 'Core2_Ext'));
    assertInvokeType(invocation, 'void Function()');
  }

  test_method_noMatch() async {
    await assertErrorsInCode(r'''
class B {}

extension A on B {
  void a() {}
}

f() {
  B b = B();
  b.c();
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_METHOD, 71, 1),
    ]);
  }

  test_method_noMostSpecificExtension() async {
    await assertErrorsInCode('''
class A {}

extension A1_Ext on A {
  void a() {}
}

extension A2_Ext on A {
  void a() {}
}

f() {
  A a = A();
  a.a();
}
''', [
      error(CompileTimeErrorCode.AMBIGUOUS_EXTENSION_METHOD_ACCESS, 117, 1),
    ]);
  }

  test_method_oneMatch() async {
    await assertNoErrorsInCode('''
class B {}

extension A on B {
  void a() {}
}

f() {
  B b = B();
  b.a();
}
''');

    var invocation = findNode.methodInvocation('b.a()');
    assertElement(invocation, findElement.method('a'));
    assertInvokeType(invocation, 'void Function()');
  }

  test_method_privateExtension() async {
    newFile('/test/lib/lib.dart', content: '''
class B {}

extension _ on B {
  void a() {}
}
''');
    await assertErrorsInCode(r'''
import 'lib.dart';

f() {
  B b = B();
  b.a();
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_METHOD, 43, 1),
    ]);
  }

  test_method_resolvesToStatic() async {
    await assertErrorsInCode('''
class A {}

extension A1_Ext on A {
  static void a() {}
}

f() {
  A a = A();
  a.a();
}
''', [
      error(CompileTimeErrorCode.ACCESS_STATIC_EXTENSION_MEMBER, 83, 1),
    ]);
  }

  test_method_specificSubtypeMatchLocal() async {
    await assertNoErrorsInCode('''
class A {}

class B extends A {}

extension A_Ext on A {
  void a() {}
}

extension B_Ext on B {
  void a() {}
}

f() {
  B b = B();
  b.a();
}
''');

    var invocation = findNode.methodInvocation('b.a()');
    assertElement(invocation, findElement.method('a', of: 'B_Ext'));
    assertInvokeType(invocation, 'void Function()');
  }

  @failingTest
  test_method_specificSubtypeMatchLocalGenerics() async {
    await assertNoErrorsInCode('''
class A<T> {}

class B<T> extends A<T> {}

class C {}

extension A_Ext<T> on A<T> {
  void f(T x) {}
}

extension B_Ext<T> on B<T> {
  void f(T x) {}
}

main() {
  B<C> x = B<C>();
  C o = C();
  x.f(o);
}
''');

    var invocation = findNode.methodInvocation('x.f(o)');
    assertElement(invocation, findElement.method('f', of: 'B_Ext'));
    assertInvokeType(invocation, 'void Function(T)');
  }

  test_method_specificSubtypeMatchPlatform() async {
    newFile('/test/lib/core.dart', content: '''
library dart.core;

class Core {}

class Core2 extends Core {}
''');

    await assertNoErrorsInCode('''
import 'core.dart';

extension Core_Ext on Core {
  void a() {}
}

extension Core2_Ext on Core2 {
  void a() => 0;
}

f() {
  Core2 c = Core2();
  c.a();
}
''');

    var invocation = findNode.methodInvocation('c.a()');
    assertElement(invocation, findElement.method('a', of: 'Core2_Ext'));
    assertInvokeType(invocation, 'void Function()');
  }

  test_method_unnamedExtension() async {
    newFile('/test/lib/lib.dart', content: '''
class B {}

extension on B {
  void a() {}
}
''');
    await assertErrorsInCode(r'''
import 'lib.dart';

f() {
  B b = B();
  b.a();
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_METHOD, 43, 1),
    ]);
  }

  test_setter_noMatch() async {
    await assertErrorsInCode(r'''
class B {}

extension A on B {}

f() {
  B b = B();
  b.a = 1;
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_SETTER, 56, 1),
    ]);
  }

  test_setter_oneMatch() async {
    await assertNoErrorsInCode('''
class B {}

extension A on B {
  set a(int x) {}
}

f() {
  B b = B();
  b.a = 1;
}
''');
  }
}

/// Tests that extension members can be correctly resolved when referenced
/// by code internal to (within) the extension declaration.
@reflectiveTest
class ExtensionMethodsInternalReferenceTest extends BaseExtensionMethodsTest {
  // TODO(brianwilkerson) Add tests for `call`.
  test_instance_getter_fromInstance() async {
    await assertNoErrorsInCode('''
class C {
  int get a => 1;
}

extension E on C {
  int get a => 1;
  int m() => a;
}
''');
    var identifier = findNode.simple('a;');
    assertElement(identifier, findElement.getter('a', of: 'E'));
    assertType(identifier, 'int');
  }

  test_instance_getter_fromThis_fromExtendedType() async {
    await assertNoErrorsInCode('''
class C {
  int get a => 1;
}

extension E on C {
  int get a => 1;
  int m() => this.a;
}
''');
    var access = findNode.propertyAccess('this.a');
    assertPropertyAccess(access, findElement.getter('a', of: 'C'), 'int');
  }

  test_instance_getter_fromThis_fromExtension() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  int get a => 1;
  int m() => this.a;
}
''');
    var access = findNode.propertyAccess('this.a');
    assertPropertyAccess(access, findElement.getter('a', of: 'E'), 'int');
  }

  test_instance_method_fromInstance() async {
    await assertNoErrorsInCode('''
class C {
  void a() {}
}
extension E on C {
  void a() {}
  void b() { a(); }
}
''');
    var invocation = findNode.methodInvocation('a();');
    assertElement(invocation, findElement.method('a', of: 'E'));
    assertInvokeType(invocation, 'void Function()');
  }

  test_instance_method_fromThis_fromExtendedType() async {
    await assertNoErrorsInCode('''
class C {
  void a() {}
}
extension E on C {
  void a() {}
  void b() { this.a(); }
}
''');
    var invocation = findNode.methodInvocation('this.a');
    assertElement(invocation, findElement.method('a', of: 'C'));
    assertInvokeType(invocation, 'void Function()');
  }

  test_instance_method_fromThis_fromExtension() async {
    await assertNoErrorsInCode('''
class C {}
extension E on C {
  void a() {}
  void b() { this.a(); }
}
''');
    var invocation = findNode.methodInvocation('this.a');
    assertElement(invocation, findElement.method('a', of: 'E'));
    assertInvokeType(invocation, 'void Function()');
  }

  test_instance_operator_fromThis_fromExtendedType() async {
    await assertNoErrorsInCode('''
class C {
  void operator +(int i) {}
}
extension E on C {
  void operator +(int i) {}
  void b() { this + 2; }
}
''');
    var binary = findNode.binary('+ ');
    assertElement(binary, findElement.method('+', of: 'C'));
  }

  @failingTest
  test_instance_operator_fromThis_fromExtension() async {
    await assertNoErrorsInCode('''
class C {}
extension E on C {
  void operator +(int i) {}
  void b() { this + 2; }
}
''');
    var binary = findNode.binary('+ ');
    assertElement(binary, findElement.method('+', of: 'E'));
  }

  test_instance_setter_fromInstance() async {
    await assertNoErrorsInCode('''
class C {
  set a(int) {}
}

extension E on C {
  set a(int) {}
  void m() {
    a = 3;
  }
}
''');
    var identifier = findNode.simple('a =');
    assertElement(identifier, findElement.setter('a', of: 'E'));
  }

  test_instance_setter_fromThis_fromExtendedType() async {
    await assertNoErrorsInCode('''
class C {
  set a(int) {}
}

extension E on C {
  set a(int) {}
  void m() {
    this.a = 3;
  }
}
''');
    var access = findNode.propertyAccess('this.a');
    assertElement(access, findElement.setter('a', of: 'C'));
  }

  test_instance_setter_fromThis_fromExtension() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  set a(int) {}
  void m() {
    this.a = 3;
  }
}
''');
    var access = findNode.propertyAccess('this.a');
    assertElement(access, findElement.setter('a', of: 'E'));
  }

  test_static_getter_fromInstance() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  static int get a => 1;
  int m() => a;
}
''');
    var identifier = findNode.simple('a;');
    assertElement(identifier, findElement.getter('a'));
    assertType(identifier, 'int');
  }

  test_static_getter_fromStatic() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  static int get a => 1;
  static int m() => a;
}
''');
    var identifier = findNode.simple('a;');
    assertElement(identifier, findElement.getter('a'));
    assertType(identifier, 'int');
  }

  test_static_method_fromInstance() async {
    await assertNoErrorsInCode('''
class C {}
extension E on C {
  static void a() {}
  void b() { a(); }
}
''');
    var invocation = findNode.methodInvocation('a();');
    assertElement(invocation, findElement.method('a'));
    assertInvokeType(invocation, 'void Function()');
  }

  test_static_method_fromStatic() async {
    await assertNoErrorsInCode('''
class C {}
extension E on C {
  static void a() {}
  static void b() { a(); }
}
''');
    var invocation = findNode.methodInvocation('a();');
    assertElement(invocation, findElement.method('a'));
    assertInvokeType(invocation, 'void Function()');
  }

  test_static_setter_fromInstance() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  static set a(int) {}
  void m() {
    a = 3;
  }
}
''');
    var identifier = findNode.simple('a =');
    assertElement(identifier, findElement.setter('a'));
  }

  test_static_setter_fromStatic() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  static set a(int) {}
  static void m() {
    a = 3;
  }
}
''');
    var identifier = findNode.simple('a =');
    assertElement(identifier, findElement.setter('a'));
  }
}
