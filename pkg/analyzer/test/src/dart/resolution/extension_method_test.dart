// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
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

  test_named_onFunctionType() async {
    try {
      await assertNoErrorsInCode('''
extension E on int Function(int) {}
''');
      var extendedType = findNode.typeAnnotation('Function');
      assertType(extendedType, 'int Function(int)');
      if (!AnalysisDriver.useSummary2) {
        throw 'Test passed - expected to fail.';
      }
    } on String {
      rethrow;
    } catch (e) {
      if (AnalysisDriver.useSummary2) {
        rethrow;
      }
    }
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

  test_visibility_hidden() async {
    newFile('/test/lib/lib.dart', content: '''
class C {}
extension E on C {
  int a = 1;
}
''');
    await assertErrorsInCode('''
import 'lib.dart' hide E;

f(C c) {
  c.a;
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_GETTER, 40, 1),
    ]);
  }

  test_visibility_notShown() async {
    newFile('/test/lib/lib.dart', content: '''
class C {}
extension E on C {
  int a = 1;
}
''');
    await assertErrorsInCode('''
import 'lib.dart' show C;

f(C c) {
  c.a;
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_GETTER, 40, 1),
    ]);
  }
}

/// Tests that extension members can be correctly resolved when referenced
/// by code external to the extension declaration.
@reflectiveTest
class ExtensionMethodsExternalReferenceTest extends BaseExtensionMethodsTest {
  test_instance_call_fromExtendedType() async {
    await assertNoErrorsInCode('''
class C {
  int call(int x) => 0;
}

extension E on C {
  int call(int x) => 0;
}

f(C c) {
  c(2);
}
''');
    var invocation = findNode.methodInvocation('c(2)');
    expect(invocation.staticInvokeType.element,
        same(findElement.method('call', of: 'C')));
    assertInvokeType(invocation, 'int Function(int)');
  }

  test_instance_call_fromExtension() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  int call(int x) => 0;
}

f(C c) {
  c(2);
}
''');
    var invocation = findNode.methodInvocation('c(2)');
    expect(invocation.staticInvokeType.element,
        same(findElement.method('call', of: 'E')));
    assertInvokeType(invocation, 'int Function(int)');
  }

  test_instance_call_fromExtension_int() async {
    await assertNoErrorsInCode('''
extension E on int {
  int call(int x) => 0;
}

f() {
  1(2);
}
''');
    var invocation = findNode.functionExpressionInvocation('1(2)');
    expect(invocation.staticInvokeType.element,
        same(findElement.method('call', of: 'E')));
    assertInvokeType(invocation, 'int Function(int)');
  }

  test_instance_compoundAssignment_fromExtendedType() async {
    await assertNoErrorsInCode('''
class C {
  C operator +(int i) => this;
}
extension E on C {
  C operator +(int i) => this;
}
f(C c) {
  c += 2;
}
''');
    var assignment = findNode.assignment('+=');
    assertElement(assignment, findElement.method('+', of: 'C'));
  }

  test_instance_compoundAssignment_fromExtension() async {
    await assertNoErrorsInCode('''
class C {}
extension E on C {
  C operator +(int i) => this;
}
f(C c) {
  c += 2;
}
''');
    var assignment = findNode.assignment('+=');
    assertElement(assignment, findElement.method('+', of: 'E'));
  }

  test_instance_getter_fromDifferentExtension_usingBounds() async {
    await assertNoErrorsInCode('''
class B {}
extension E1 on B {
  int get g => 0;
}
extension E2<T extends B> on T {
  void a() {
    g;
  }
}
''');
    var identifier = findNode.simple('g;');
    assertElement(identifier, findElement.getter('g'));
  }

  test_instance_getter_fromDifferentExtension_withoutTarget() async {
    await assertNoErrorsInCode('''
class C {}
extension E1 on C {
  int get a => 1;
}
extension E2 on C {
  void m() {
    a;
  }
}
''');
    var identifier = findNode.simple('a;');
    assertElement(identifier, findElement.getter('a'));
    assertType(identifier, 'int');
  }

  test_instance_getter_fromExtendedType_usingBounds() async {
    await assertNoErrorsInCode('''
class B {
  int get g => 0;
}
extension E<T extends B> on T {
  void a() {
    g;
  }
}
''');
    var identifier = findNode.simple('g;');
    assertElement(identifier, findElement.getter('g'));
  }

  test_instance_getter_fromExtendedType_withoutTarget() async {
    await assertNoErrorsInCode('''
class C {
  void m() {
    a;
  }
}
extension E on C {
  int get a => 1;
}
''');
    var identifier = findNode.simple('a;');
    assertElement(identifier, findElement.getter('a'));
    assertType(identifier, 'int');
  }

  test_instance_getter_fromInstance() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  int get a => 1;
}

f(C c) {
  c.a;
}
''');
    var access = findNode.prefixed('c.a');
    assertElement(access, findElement.getter('a'));
    assertType(access, 'int');
  }

  test_instance_getter_methodInvocation() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  double Function(int) get a => (b) => 2.0;
}

f(C c) {
  c.a(0);
}
''');
    var invocation = findNode.methodInvocation('a(0);');
    assertMethodInvocation(
      invocation,
      findElement.getter('a'),
      'double Function(int)',
      expectedMethodNameType: 'double Function(int) Function()',
    );
  }

  test_instance_getter_specificSubtypeMatchLocal() async {
    await assertNoErrorsInCode('''
class A {}
class B extends A {}

extension A_Ext on A {
  int get a => 1;
}
extension B_Ext on B {
  int get a => 2;
}

f(B b) {
  b.a;
}
''');
    var access = findNode.prefixed('b.a');
    assertElement(access, findElement.getter('a', of: 'B_Ext'));
    assertType(access, 'int');
  }

  test_instance_getter_with_setter() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  int get a => 1;
}

extension E2 on C {
  set a(int v) { }
}

f(C c) {
  print(c.a);
}
''');
    var access = findNode.prefixed('c.a');
    assertElement(access, findElement.getter('a'));
    assertType(access, 'int');
  }

  test_instance_method_fromDifferentExtension_usingBounds() async {
    await assertNoErrorsInCode('''
class B {}
extension E1 on B {
  void m() {}
}
extension E2<T extends B> on T {
  void a() {
    m();
  }
}
''');
    var invocation = findNode.methodInvocation('m();');
    assertElement(invocation, findElement.method('m'));
    assertInvokeType(invocation, 'void Function()');
  }

  test_instance_method_fromDifferentExtension_withoutTarget() async {
    await assertNoErrorsInCode('''
class B {}
extension E1 on B {
  void a() {}
}
extension E2 on B {
  void m() {
    a();
  }
}
''');
    var invocation = findNode.methodInvocation('a();');
    assertElement(invocation, findElement.method('a'));
    assertInvokeType(invocation, 'void Function()');
  }

  test_instance_method_fromExtendedType_usingBounds() async {
    await assertNoErrorsInCode('''
class B {
  void m() {}
}
extension E<T extends B> on T {
  void a() {
    m();
  }
}
''');
    var invocation = findNode.methodInvocation('m();');
    assertElement(invocation, findElement.method('m'));
    assertInvokeType(invocation, 'void Function()');
  }

  test_instance_method_fromExtendedType_withoutTarget() async {
    await assertNoErrorsInCode('''
class B {
  void m() {
    a();
  }
}
extension E on B {
  void a() {}
}
''');
    var invocation = findNode.methodInvocation('a();');
    assertElement(invocation, findElement.method('a'));
    assertInvokeType(invocation, 'void Function()');
  }

  test_instance_method_fromInstance() async {
    await assertNoErrorsInCode('''
class B {}

extension A on B {
  void a() {}
}

f(B b) {
  b.a();
}
''');
    var invocation = findNode.methodInvocation('b.a()');
    assertElement(invocation, findElement.method('a'));
    assertInvokeType(invocation, 'void Function()');
  }

  test_instance_method_moreSpecificThanPlatform() async {
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

f(Core2 c) {
  c.a();
}
''');
    var invocation = findNode.methodInvocation('c.a()');
    assertElement(invocation, findElement.method('a', of: 'Core2_Ext'));
    assertInvokeType(invocation, 'void Function()');
  }

  test_instance_method_specificSubtypeMatchLocal() async {
    await assertNoErrorsInCode('''
class A {}
class B extends A {}

extension A_Ext on A {
  void a() {}
}
extension B_Ext on B {
  void a() {}
}

f(B b) {
  b.a();
}
''');

    var invocation = findNode.methodInvocation('b.a()');
    assertElement(invocation, findElement.method('a', of: 'B_Ext'));
    assertInvokeType(invocation, 'void Function()');
  }

  @failingTest
  test_instance_method_specificSubtypeMatchLocalGenerics() async {
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

f(B<C> x, C o) {
  x.f(o);
}
''');
    var invocation = findNode.methodInvocation('x.f(o)');
    assertElement(invocation, findElement.method('f', of: 'B_Ext'));
    assertInvokeType(invocation, 'void Function(T)');
  }

  test_instance_method_specificSubtypeMatchPlatform() async {
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

f(Core2 c) {
  c.a();
}
''');
    var invocation = findNode.methodInvocation('c.a()');
    assertElement(invocation, findElement.method('a', of: 'Core2_Ext'));
    assertInvokeType(invocation, 'void Function()');
  }

  test_instance_operator_binary_fromExtendedType() async {
    await assertNoErrorsInCode('''
class C {
  void operator +(int i) {}
}
extension E on C {
  void operator +(int i) {}
}
f(C c) {
  c + 2;
}
''');
    var binary = findNode.binary('+ ');
    assertElement(binary, findElement.method('+', of: 'C'));
  }

  test_instance_operator_binary_fromExtension() async {
    await assertNoErrorsInCode('''
class C {}
extension E on C {
  void operator +(int i) {}
}
f(C c) {
  c + 2;
}
''');
    var binary = findNode.binary('+ ');
    assertElement(binary, findElement.method('+', of: 'E'));
  }

  test_instance_operator_index_fromExtendedType() async {
    await assertNoErrorsInCode('''
class C {
  void operator [](int index) {}
}
extension E on C {
  void operator [](int index) {}
}
f(C c) {
  c[2];
}
''');
    var index = findNode.index('c[2]');
    assertElement(index, findElement.method('[]', of: 'C'));
  }

  test_instance_operator_index_fromExtension() async {
    await assertNoErrorsInCode('''
class C {}
extension E on C {
  void operator [](int index) {}
}
f(C c) {
  c[2];
}
''');
    var index = findNode.index('c[2]');
    assertElement(index, findElement.method('[]', of: 'E'));
  }

  test_instance_operator_indexEquals_fromExtendedType() async {
    await assertNoErrorsInCode('''
class C {
  void operator []=(int index, int value) {}
}
extension E on C {
  void operator []=(int index, int value) {}
}
f(C c) {
  c[2] = 1;
}
''');
    var index = findNode.index('c[2]');
    assertElement(index, findElement.method('[]=', of: 'C'));
  }

  test_instance_operator_indexEquals_fromExtension() async {
    await assertNoErrorsInCode('''
class C {}
extension E on C {
  void operator []=(int index, int value) {}
}
f(C c) {
  c[2] = 3;
}
''');
    var index = findNode.index('c[2]');
    assertElement(index, findElement.method('[]=', of: 'E'));
  }

  test_instance_operator_postfix_fromExtendedType() async {
    await assertNoErrorsInCode('''
class C {
  void operator +(int i) {}
}
extension E on C {
  void operator +(int i) {}
}
f(C c) {
  c++;
}
''');
    var postfix = findNode.postfix('++');
    assertElement(postfix, findElement.method('+', of: 'C'));
  }

  test_instance_operator_postfix_fromExtension() async {
    await assertNoErrorsInCode('''
class C {}
extension E on C {
  void operator +(int i) {}
}
f(C c) {
  c++;
}
''');
    var postfix = findNode.postfix('++');
    assertElement(postfix, findElement.method('+', of: 'E'));
  }

  test_instance_operator_prefix_fromExtendedType() async {
    await assertNoErrorsInCode('''
class C {
  void operator +(int i) {}
}
extension E on C {
  void operator +(int i) {}
}
f(C c) {
  ++c;
}
''');
    var prefix = findNode.prefix('++');
    assertElement(prefix, findElement.method('+', of: 'C'));
  }

  test_instance_operator_prefix_fromExtension() async {
    await assertNoErrorsInCode('''
class C {}
extension E on C {
  void operator +(int i) {}
}
f(C c) {
  ++c;
}
''');
    var prefix = findNode.prefix('++');
    assertElement(prefix, findElement.method('+', of: 'E'));
  }

  test_instance_operator_unary_fromExtendedType() async {
    await assertNoErrorsInCode('''
class C {
  void operator -() {}
}
extension E on C {
  void operator -() {}
}
f(C c) {
  -c;
}
''');
    var prefix = findNode.prefix('-c');
    assertElement(prefix, findElement.method('unary-', of: 'C'));
  }

  test_instance_operator_unary_fromExtension() async {
    await assertNoErrorsInCode('''
class C {}
extension E on C {
  void operator -() {}
}
f(C c) {
  -c;
}
''');
    var prefix = findNode.prefix('-c');
    assertElement(prefix, findElement.method('unary-', of: 'E'));
  }

  test_instance_setter_oneMatch() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  set a(int x) {}
}

f(C c) {
  c.a = 1;
}
''');
    var access = findNode.prefixed('c.a');
    assertElement(access, findElement.setter('a'));
  }

  test_instance_setter_with_getter() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  int get a => 1;
}

extension E2 on C {
  set a(int v) { }
}

f(C c) {
  print(c.a = 1);
}
''');
    var access = findNode.prefixed('c.a');
    assertElement(access, findElement.setter('a'));
    assertType(access, 'int');
  }

  test_instance_tearoff() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  void a(int x) {}
}

f(C c) => c.a;
''');
    var identifier = findNode.simple('a;');
    assertElement(identifier, findElement.method('a'));
    assertType(identifier, 'void Function(int)');
  }

  test_static_field_importedWithPrefix() async {
    newFile('/test/lib/lib.dart', content: '''
class C {}

extension E on C {
  static int a = 1;
}
''');
    await assertNoErrorsInCode('''
import 'lib.dart' as p;

f() {
  p.E.a;
}
''');
    var identifier = findNode.simple('a;');
    var import = findElement.importFind('package:test/lib.dart');
    assertElement(identifier, import.extension_('E').getGetter('a'));
    assertType(identifier, 'int');
  }

  test_static_field_local() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  static int a = 1;
}

f() {
  E.a;
}
''');
    var identifier = findNode.simple('a;');
    assertElement(identifier, findElement.getter('a'));
    assertType(identifier, 'int');
  }

  test_static_getter_importedWithPrefix() async {
    newFile('/test/lib/lib.dart', content: '''
class C {}

extension E on C {
  static int get a => 1;
}
''');
    await assertNoErrorsInCode('''
import 'lib.dart' as p;

f() {
  p.E.a;
}
''');
    var identifier = findNode.simple('a;');
    var import = findElement.importFind('package:test/lib.dart');
    assertElement(identifier, import.extension_('E').getGetter('a'));
    assertType(identifier, 'int');
  }

  test_static_getter_local() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  static int get a => 1;
}

f() {
  E.a;
}
''');
    var identifier = findNode.simple('a;');
    assertElement(identifier, findElement.getter('a'));
    assertType(identifier, 'int');
  }

  test_static_method_importedWithPrefix() async {
    newFile('/test/lib/lib.dart', content: '''
class C {}

extension E on C {
  static void a() {}
}
''');
    await assertNoErrorsInCode('''
import 'lib.dart' as p;

f() {
  p.E.a();
}
''');
    var invocation = findNode.methodInvocation('E.a()');
    var import = findElement.importFind('package:test/lib.dart');
    assertElement(invocation, import.extension_('E').getMethod('a'));
    assertInvokeType(invocation, 'void Function()');
  }

  test_static_method_local() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  static void a() {}
}

f() {
  E.a();
}
''');
    var invocation = findNode.methodInvocation('E.a()');
    assertElement(invocation, findElement.method('a'));
    assertInvokeType(invocation, 'void Function()');
  }

  test_static_setter_importedWithPrefix() async {
    newFile('/test/lib/lib.dart', content: '''
class C {}

extension E on C {
  static set a(int x) {}
}
''');
    await assertNoErrorsInCode('''
import 'lib.dart' as p;

f() {
  p.E.a = 3;
}
''');
    var identifier = findNode.simple('a =');
    var import = findElement.importFind('package:test/lib.dart');
    assertElement(identifier, import.extension_('E').getSetter('a'));
  }

  test_static_setter_local() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  static set a(int x) {}
}

f() {
  E.a = 3;
}
''');
    var identifier = findNode.simple('a =');
    assertElement(identifier, findElement.setter('a'));
  }

  test_static_tearoff() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  static void a(int x) {}
}

f() => E.a;
''');
    var identifier = findNode.simple('a;');
    assertElement(identifier, findElement.method('a'));
    assertType(identifier, 'void Function(int)');
  }
}

/// Tests that extension members can be correctly resolved when referenced
/// by code internal to (within) the extension declaration.
@reflectiveTest
class ExtensionMethodsInternalReferenceTest extends BaseExtensionMethodsTest {
  test_instance_call() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  int call(int x) => 0;
  int m() => this(2);
}
''');
    var invocation = findNode.functionExpressionInvocation('this(2)');
    assertElement(invocation, findElement.method('call', of: 'E'));
    assertType(invocation, 'int');
  }

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

  test_instance_operator_binary_fromThis_fromExtendedType() async {
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

  test_instance_operator_binary_fromThis_fromExtension() async {
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

  test_instance_operator_index_fromThis_fromExtendedType() async {
    await assertNoErrorsInCode('''
class C {
  void operator [](int index) {}
}
extension E on C {
  void operator [](int index) {}
  void b() { this[2]; }
}
''');
    var index = findNode.index('this[2]');
    assertElement(index, findElement.method('[]', of: 'C'));
  }

  test_instance_operator_index_fromThis_fromExtension() async {
    await assertNoErrorsInCode('''
class C {}
extension E on C {
  void operator [](int index) {}
  void b() { this[2]; }
}
''');
    var index = findNode.index('this[2]');
    assertElement(index, findElement.method('[]', of: 'E'));
  }

  test_instance_operator_indexEquals_fromThis_fromExtendedType() async {
    await assertNoErrorsInCode('''
class C {
  void operator []=(int index, int value) {}
}
extension E on C {
  void operator []=(int index, int value) {}
  void b() { this[2] = 1; }
}
''');
    var index = findNode.index('this[2]');
    assertElement(index, findElement.method('[]=', of: 'C'));
  }

  test_instance_operator_indexEquals_fromThis_fromExtension() async {
    await assertNoErrorsInCode('''
class C {}
extension E on C {
  void operator []=(int index, int value) {}
  void b() { this[2] = 3; }
}
''');
    var index = findNode.index('this[2]');
    assertElement(index, findElement.method('[]=', of: 'E'));
  }

  test_instance_operator_unary_fromThis_fromExtendedType() async {
    await assertNoErrorsInCode('''
class C {
  void operator -() {}
}
extension E on C {
  void operator -() {}
  void b() { -this; }
}
''');
    var prefix = findNode.prefix('-this');
    assertElement(prefix, findElement.method('unary-', of: 'C'));
  }

  test_instance_operator_unary_fromThis_fromExtension() async {
    await assertNoErrorsInCode('''
class C {}
extension E on C {
  void operator -() {}
  void b() { -this; }
}
''');
    var prefix = findNode.prefix('-this');
    assertElement(prefix, findElement.method('unary-', of: 'E'));
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

  test_instance_tearoff_fromInstance() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  void a(int x) {}
  get b => a;
}
''');
    var identifier = findNode.simple('a;');
    assertElement(identifier, findElement.method('a'));
    assertType(identifier, 'void Function(int)');
  }

  test_instance_tearoff_fromThis() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  void a(int x) {}
  get c => this.a;
}
''');
    var identifier = findNode.simple('a;');
    assertElement(identifier, findElement.method('a'));
    assertType(identifier, 'void Function(int)');
  }

  test_static_field_fromInstance() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  static int a = 1;
  int m() => a;
}
''');
    var identifier = findNode.simple('a;');
    assertElement(identifier, findElement.getter('a'));
    assertType(identifier, 'int');
  }

  test_static_field_fromStatic() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  static int a = 1;
  static int m() => a;
}
''');
    var identifier = findNode.simple('a;');
    assertElement(identifier, findElement.getter('a'));
    assertType(identifier, 'int');
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
  static set a(int x) {}
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
  static set a(int x) {}
  static void m() {
    a = 3;
  }
}
''');
    var identifier = findNode.simple('a =');
    assertElement(identifier, findElement.setter('a'));
  }

  test_static_tearoff_fromInstance() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  static void a(int x) {}
  get b => a;
}
''');
    var identifier = findNode.simple('a;');
    assertElement(identifier, findElement.method('a'));
    assertType(identifier, 'void Function(int)');
  }

  test_static_tearoff_fromStatic() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  static void a(int x) {}
  static get c => a;
}
''');
    var identifier = findNode.simple('a;');
    assertElement(identifier, findElement.method('a'));
    assertType(identifier, 'void Function(int)');
  }
}
