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

  //
  // todo(pq): lots of test cases to implement; a few breadcrumbs:
  //

  test_multi_match_ambiguous() async {
    // todo(pq): implement
  }

  test_multi_match_best() async {
    // todo(pq): implement
  }
}
