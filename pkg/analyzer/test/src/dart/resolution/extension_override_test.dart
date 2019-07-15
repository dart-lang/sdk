// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
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

  void assertOverride(String extensionName, List<DartType> typeArguments) {
    expect(extensionOverride.extensionName.toSource(), extensionName);
    if (extension != null) {
      expect(extensionOverride.extensionName.staticElement, extension);
    }
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

  void find(String declarationSearch, String overrideSearch) {
    try {
      ExtensionDeclaration declaration =
          findNode.extensionDeclaration(declarationSearch);
      extension = declaration?.declaredElement as ExtensionElement;
    } catch (_) {
      // The extension could not be found.
    }
    extensionOverride = findNode.extensionOverride(overrideSearch);
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
    find('E ', 'E(a)');
    assertOverride('E', null);
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
    find('E<T>', 'E<int>');
    assertOverride('E', [intType]);
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
    find('E ', 'E(a)');
    assertOverride('p.E', null);
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
    find('E<T>', 'E<int>');
    assertOverride('p.E', [intType]);
  }
}
