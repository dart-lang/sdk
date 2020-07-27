// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';
import 'with_null_safety_mixin.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PrefixedIdentifierResolutionTest);
    defineReflectiveTests(PrefixedIdentifierResolutionWithNullSafetyTest);
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
class PrefixedIdentifierResolutionWithNullSafetyTest
    extends PrefixedIdentifierResolutionTest with WithNullSafetyMixin {
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
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 50, 1),
    ]);

    var identifier = findNode.simple('a;');
    assertElement(
      identifier,
      findElement.importFind('package:test/a.dart').topGet('a'),
    );
    assertType(identifier, 'A?');
  }
}
