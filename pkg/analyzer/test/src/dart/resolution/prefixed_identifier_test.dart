// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PrefixedIdentifierResolutionTest);
    defineReflectiveTests(PrefixedIdentifierResolutionWithNnbdTest);
  });
}

@reflectiveTest
class PrefixedIdentifierResolutionTest extends DriverResolutionTest {
  test_dynamic_explicitCore_withPrefix() async {
    await assertNoErrorsInCode(r'''
import 'dart:core' as mycore;

main() {
  mycore.dynamic;
}
''');

    assertPrefixedIdentifier(
      findNode.prefixed('mycore.dynamic'),
      element: dynamicElement,
      type: 'Type',
    );
  }

  test_implicitCall_tearOff() async {
    newFile('/test/lib/a.dart', content: r'''
class A {
  int call() => 0;
}

A a;
''');
    await assertNoErrorsInCode('''
import 'a.dart';

int Function() foo() {
  return a;
}
''');

    var identifier = findNode.simple('a;');
    assertElement(
      identifier,
      findElement.importFind('package:test/a.dart').topGet('a'),
    );
    assertType(identifier, 'A');
  }
}

@reflectiveTest
class PrefixedIdentifierResolutionWithNnbdTest
    extends PrefixedIdentifierResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = FeatureSet.forTesting(
        sdkVersion: '2.6.0', additionalFeatures: [Feature.non_nullable]);

  @override
  bool get typeToStringWithNullability => true;

  test_deferredImportPrefix_loadLibrary_optIn_fromOptOut() async {
    newFile('/test/lib/a.dart', content: r'''
class A {}
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.7
import 'a.dart' deferred as a;

main() {
  a.loadLibrary;
}
''');

    var import = findElement.importFind('package:test/a.dart');

    assertPrefixedIdentifier(
      findNode.prefixed('a.loadLibrary'),
      element: elementMatcher(
        import.importedLibrary.loadLibraryFunction,
        isLegacy: true,
      ),
      type: 'Future<dynamic>* Function()*',
    );
  }

  test_implicitCall_tearOff_nullable() async {
    newFile('/test/lib/a.dart', content: r'''
class A {
  int call() => 0;
}

A? a;
''');
    await assertErrorsInCode('''
import 'a.dart';

int Function() foo() {
  return a;
}
''', [
      error(StaticTypeWarningCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 50, 1),
    ]);

    var identifier = findNode.simple('a;');
    assertElement(
      identifier,
      findElement.importFind('package:test/a.dart').topGet('a'),
    );
    assertType(identifier, 'A?');
  }
}
