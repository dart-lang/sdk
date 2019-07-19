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
    defineReflectiveTests(ExtensionMethodTest);
  });
}

@reflectiveTest
class ExtensionMethodTest extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = new FeatureSet.forTesting(
        sdkVersion: '2.3.0', additionalFeatures: [Feature.extension_methods]);

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

class Core { }
''');

    await assertNoErrorsInCode('''
import 'core.dart' as platform;

class Core2 extends platform.Core { }

extension Core_Ext on platform.Core {
  void a() { }
}

extension Core2_Ext on Core2 {
  void a() { }
}

f() {
  Core2 c = Core2();
  c.a();
}
''');

    var invocation = findNode.methodInvocation('c.a()');
    expect(invocation.methodName.staticElement.library.isDartCore, isFalse);
  }

  test_method_noMatch() async {
    await assertErrorCodesInCode(r'''
class B { }

extension A on B {
  void a() { }
}

f() {
  B b = B();
  b.c();
}
''', [StaticTypeWarningCode.UNDEFINED_METHOD]);
  }

  test_method_noMostSpecificExtension() async {
    await assertErrorsInCode('''
class A { }

extension A1_Ext on A {
  void a() { }
}

extension A2_Ext on A {
  void a() { }
}

f() {
  A a = A();
  a.a();
}
''', [
      error(CompileTimeErrorCode.AMBIGUOUS_EXTENSION_METHOD_ACCESS, 120, 1),
    ]);
  }

  test_method_oneMatch() async {
    await assertNoErrorsInCode('''
class B { }

extension A on B {
  void a() { }
}

f() {
  B b = B();
  b.a();
}
''');

    var invocation = findNode.methodInvocation('b.a()');
    var declaration = findNode.methodDeclaration('void a()');
    expect(invocation.methodName.staticElement, declaration.declaredElement);
  }

  test_method_privateExtension() async {
    newFile('/test/lib/lib.dart', content: '''
class B { }

extension _ on B {
  void a() { }
}
''');
    await assertErrorCodesInCode(r'''
import 'lib.dart';

f() {
  B b = B();
  b.a();
}
''', [StaticTypeWarningCode.UNDEFINED_METHOD]);
  }

  test_method_resolvesToStatic() async {
    await assertErrorsInCode('''
class A { }

extension A1_Ext on A {
  static void a() { }
}

f() {
  A a = A();
  a.a();
}
''', [
      error(CompileTimeErrorCode.ACCESS_STATIC_EXTENSION_MEMBER, 85, 1),
    ]);
  }

  test_method_specificSubtypeMatchLocal() async {
    await assertNoErrorsInCode('''
class A { }

class B extends A { }

extension A_Ext on A {
  void a() { }
}

extension B_Ext on B {
  void /*2*/ a() { }
}

f() {
  B b = B();
  b.a();
}
''');

    var invocation = findNode.methodInvocation('b.a()');
    var declaration = findNode.methodDeclaration('void /*2*/ a()');
    expect(invocation.methodName.staticElement, declaration.declaredElement);
  }

  @failingTest
  test_method_specificSubtypeMatchLocalGenerics() async {
    await assertNoErrorsInCode('''
class A<T> { }

class B<T> extends A<T> { }

class O { }

extension A_Ext<T> on A<T> {
  void f(T x) { }
}

extension B_Ext<T> on B<T> {
  void /*2*/ f(T x) { }
}

main() {
  B<O> x = B<O>();
  O o = O();
  x.f(o);
}
''');

    var invocation = findNode.methodInvocation('x.f(o)');
    var declaration = findNode.methodDeclaration('void /*2*/ f(T x)');
    expect(invocation.methodName.staticElement, declaration.declaredElement);
  }

  test_method_specificSubtypeMatchPlatform() async {
    newFile('/test/lib/core.dart', content: '''
library dart.core;

class Core { }

class Core2 extends Core { }
''');

    await assertNoErrorsInCode('''
import 'core.dart';

extension Core_Ext on Core {
  void a() { }
}

extension Core2_Ext on Core2 {
  void /*2*/ a() => 0;
}

f() {
  Core2 c = Core2();
  c.a();
}
''');

    var invocation = findNode.methodInvocation('c.a()');
    var declaration = findNode.methodDeclaration('void /*2*/ a()');
    expect(invocation.methodName.staticElement, declaration.declaredElement);
  }

  test_method_unnamedExtension() async {
    newFile('/test/lib/lib.dart', content: '''
class B { }

extension on B {
  void a() { }
}
''');
    await assertErrorCodesInCode(r'''
import 'lib.dart';

f() {
  B b = B();
  b.a();
}
''', [StaticTypeWarningCode.UNDEFINED_METHOD]);
  }

  test_multipleExtensions() async {
    await assertNoErrorsInCode('''
class A {}
extension E1 on A {}
extension E2 on A {}
''');
  }

  test_unnamedExtension() async {
    await assertNoErrorsInCode('''
class A {}
extension on A {
  void a() { }
}
''');
  }
}
