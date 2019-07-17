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

  test_more_specific_than_platform() async {
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

  test_multi_match_ambiguous() async {
    // todo(pq): implement
  }

  test_multipleExtensions() async {
    await assertNoErrorsInCode('''
class A {}
extension E1 on A {}
extension E2 on A {}
''');
  }

  test_no_match() async {
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

  test_one_match() async {
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

  test_specific_subtype_match_local() async {
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

  test_specific_subtype_match_platform() async {
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
}
