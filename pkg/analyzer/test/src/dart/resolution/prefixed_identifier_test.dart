// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PrefixedIdentifierResolutionTest);
    defineReflectiveTests(PrefixedIdentifierResolutionWithNullSafetyTest);
  });
}

@reflectiveTest
class PrefixedIdentifierResolutionTest extends PubPackageResolutionTest {
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
    newFile('$testPackageLibPath/a.dart', content: r'''
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

  test_read() async {
    await assertNoErrorsInCode('''
class A {
  int foo = 0;
}

void f(A a) {
  a.foo;
}
''');

    var prefixed = findNode.prefixed('a.foo');
    assertPrefixedIdentifier(
      prefixed,
      element: findElement.getter('foo'),
      type: 'int',
    );

    assertSimpleIdentifier(
      prefixed.prefix,
      readElement: findElement.parameter('a'),
      writeElement: null,
      type: 'A',
    );

    assertSimpleIdentifier(
      prefixed.identifier,
      readElement: findElement.getter('foo'),
      writeElement: null,
      type: 'int',
    );
  }

  test_readWrite_assignment() async {
    await assertNoErrorsInCode('''
class A {
  int foo = 0;
}

void f(A a) {
  a.foo += 1;
}
''');

    var assignment = findNode.assignment('foo += 1');
    assertAssignment(
      assignment,
      readElement: findElement.getter('foo'),
      readType: 'int',
      writeElement: findElement.setter('foo'),
      writeType: 'int',
      operatorElement: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isNullSafetySdkAndLegacyLibrary,
      ),
      type: 'int',
    );

    var prefixed = assignment.leftHandSide as PrefixedIdentifier;
    if (hasAssignmentLeftResolution) {
      assertPrefixedIdentifier(
        prefixed,
        element: findElement.setter('foo'),
        type: 'int',
      );
    }

    assertSimpleIdentifier(
      prefixed.prefix,
      readElement: findElement.parameter('a'),
      writeElement: null,
      type: 'A',
    );

    if (hasAssignmentLeftResolution) {
      assertSimpleIdentifier(
        prefixed.identifier,
        readElement: null,
        writeElement: findElement.setter('foo'),
        type: 'int',
      );
    }
  }

  test_write() async {
    await assertNoErrorsInCode('''
class A {
  int foo = 0;
}

void f(A a) {
  a.foo = 1;
}
''');

    var assignment = findNode.assignment('foo = 1');
    assertAssignment(
      assignment,
      readElement: null,
      readType: null,
      writeElement: findElement.setter('foo'),
      writeType: 'int',
      operatorElement: null,
      type: 'int',
    );

    var prefixed = assignment.leftHandSide as PrefixedIdentifier;
    if (hasAssignmentLeftResolution) {
      assertPrefixedIdentifier(
        prefixed,
        element: findElement.setter('foo'),
        type: 'int',
      );
    }

    assertSimpleIdentifier(
      prefixed.prefix,
      readElement: findElement.parameter('a'),
      writeElement: null,
      type: 'A',
    );

    if (hasAssignmentLeftResolution) {
      assertSimpleIdentifier(
        prefixed.identifier,
        readElement: null,
        writeElement: findElement.setter('foo'),
        type: 'int',
      );
    }
  }
}

@reflectiveTest
class PrefixedIdentifierResolutionWithNullSafetyTest
    extends PrefixedIdentifierResolutionTest with WithNullSafetyMixin {
  test_deferredImportPrefix_loadLibrary_optIn_fromOptOut() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
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
    newFile('$testPackageLibPath/a.dart', content: r'''
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
