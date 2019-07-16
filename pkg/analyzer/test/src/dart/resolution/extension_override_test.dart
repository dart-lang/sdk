// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:meta/meta.dart';
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
  ExtensionElement extension;
  ExtensionOverride extensionOverride;

  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = new FeatureSet.forTesting(
        sdkVersion: '2.3.0', additionalFeatures: [Feature.extension_methods]);

  void assertInvocation() {
    MethodInvocation invocation = extensionOverride.parent as MethodInvocation;
    Element resolvedElement = invocation.methodName.staticElement;
    expect(resolvedElement, extension.getMethod('m'));
  }

  void assertOverride({List<DartType> typeArguments}) {
    expect(extensionOverride.extensionName.staticElement, extension);
    if (typeArguments == null) {
      expect(extensionOverride.typeArguments, isNull);
    } else {
      expect(
          extensionOverride.typeArguments.arguments
              .map((annotation) => annotation.type),
          unorderedEquals(typeArguments));
    }
    expect(extensionOverride.argumentList.arguments, hasLength(1));
  }

  void findDeclarationAndOverride(
      {@required String declarationName,
      @required String overrideSearch,
      String declarationUri}) {
    if (declarationUri == null) {
      ExtensionDeclaration declaration =
          findNode.extensionDeclaration('extension $declarationName');
      extension = declaration?.declaredElement as ExtensionElement;
    } else {
      extension =
          findElement.importFind(declarationUri).extension_(declarationName);
    }
    extensionOverride = findNode.extensionOverride(overrideSearch);
  }

  @failingTest
  test_multipleArguments() async {
    fail('Implement this');
  }

  @failingTest
  test_noArguments() async {
    fail('Implement this');
  }

  @failingTest
  test_noMatchingMember() async {
    fail('Implement this');
  }

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
    findDeclarationAndOverride(declarationName: 'E ', overrideSearch: 'E(a)');
    assertOverride();
    assertInvocation();
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
    findDeclarationAndOverride(declarationName: 'E', overrideSearch: 'E<int>');
    assertOverride(typeArguments: [intType]);
    assertInvocation();
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
    findDeclarationAndOverride(
        declarationName: 'E',
        declarationUri: 'package:test/lib.dart',
        overrideSearch: 'E(a)');
    assertOverride();
    assertInvocation();
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
    findDeclarationAndOverride(
        declarationName: 'E',
        declarationUri: 'package:test/lib.dart',
        overrideSearch: 'E<int>');
    assertOverride(typeArguments: [intType]);
    assertInvocation();
  }
}
