// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionOverrideTest);
  });
}

@reflectiveTest
class ExtensionOverrideTest extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = new FeatureSet.forTesting(
        sdkVersion: '2.3.0', additionalFeatures: [Feature.extension_methods]);

  test_noPrefix_noTypeArguments() async {
    await assertNoErrorsInCode('''
class A {}
extension E on A {
  void m() {}
}
void f(A a) {
  E(a).m();
}
''');
    ExtensionOverride override = findNode.extensionOverride('E(a)');
    expect(override.extensionName.toSource(), 'E');
    expect(override.typeArguments, isNull);
    expect(override.argumentList.arguments, hasLength(1));
  }

  test_noPrefix_typeArguments() async {
    await assertNoErrorsInCode('''
class A {}
extension E<T> on A {
  void m() {}
}
void f(A a) {
  E<int>(a).m();
}
''');
    ExtensionOverride override = findNode.extensionOverride('E<int>');
    expect(override.extensionName.toSource(), 'E');
    expect(override.typeArguments.arguments, hasLength(1));
    expect(override.argumentList.arguments, hasLength(1));
  }

  test_prefix_noTypeArguments() async {
    newFile('/test/lib/lib.dart', content: '''
class A {}
extension E on A {
  void m() {}
}
''');
    await assertNoErrorsInCode('''
import 'lib.dart' as p;
void f(p.A a) {
  p.E(a).m();
}
''');
    ExtensionOverride override = findNode.extensionOverride('E(a)');
    expect(override.extensionName.toSource(), 'p.E');
    expect(override.typeArguments, isNull);
    expect(override.argumentList.arguments, hasLength(1));
  }

  test_prefix_typeArguments() async {
    newFile('/test/lib/lib.dart', content: '''
class A {}
extension E<T> on A {
  void m() {}
}
''');
    await assertNoErrorsInCode('''
import 'lib.dart' as p;
void f(p.A a) {
  p.E<int>(a).m();
}
''');
    ExtensionOverride override = findNode.extensionOverride('E<int>');
    expect(override.extensionName.toSource(), 'p.E');
    expect(override.typeArguments.arguments, hasLength(1));
    expect(override.argumentList.arguments, hasLength(1));
  }
}
