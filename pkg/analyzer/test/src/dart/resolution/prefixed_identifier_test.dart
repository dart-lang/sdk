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
    defineReflectiveTests(
      PrefixedIdentifierResolutionWithNonFunctionTypeAliasesTest,
    );
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

  test_functionType_call_read() async {
    await assertNoErrorsInCode('''
void f(int Function(String) a) {
  a.call;
}
''');

    assertPrefixedIdentifier(
      findNode.prefixed('.call;'),
      element: null,
      type: 'int Function(String)',
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
      element: findElement.parameter('a'),
      type: 'A',
    );

    assertSimpleIdentifier(
      prefixed.identifier,
      element: findElement.getter('foo'),
      type: 'int',
    );
  }

  test_read_staticMethod_generic() async {
    await assertNoErrorsInCode('''
class A<T> {
  static void foo<U>(int a, U u) {}
}

void f() {
  A.foo;
}
''');

    var prefixed = findNode.prefixed('A.foo');
    assertPrefixedIdentifier(
      prefixed,
      element: findElement.method('foo'),
      type: 'void Function<U>(int, U)',
    );

    assertSimpleIdentifier(
      prefixed.prefix,
      element: findElement.class_('A'),
      type: null,
    );

    assertSimpleIdentifier(
      prefixed.identifier,
      element: findElement.method('foo'),
      type: 'void Function<U>(int, U)',
    );
  }

  test_read_staticMethod_ofGenericClass() async {
    await assertNoErrorsInCode('''
class A<T> {
  static void foo(int a) {}
}

void f() {
  A.foo;
}
''');

    var prefixed = findNode.prefixed('A.foo');
    assertPrefixedIdentifier(
      prefixed,
      element: findElement.method('foo'),
      type: 'void Function(int)',
    );

    assertSimpleIdentifier(
      prefixed.prefix,
      element: findElement.class_('A'),
      type: null,
    );

    assertSimpleIdentifier(
      prefixed.identifier,
      element: findElement.method('foo'),
      type: 'void Function(int)',
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
      element: findElement.parameter('a'),
      type: 'A',
    );

    assertSimpleIdentifierAssignmentTarget(
      prefixed.identifier,
    );
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
      element: findElement.parameter('a'),
      type: 'A',
    );

    assertSimpleIdentifierAssignmentTarget(
      prefixed.identifier,
    );
  }
}

@reflectiveTest
class PrefixedIdentifierResolutionWithNonFunctionTypeAliasesTest
    extends PubPackageResolutionTest with WithNonFunctionTypeAliasesMixin {
  test_hasReceiver_typeAlias_staticGetter() async {
    await assertNoErrorsInCode(r'''
class A {
  static int get foo => 0;
}

typedef B = A;

void f() {
  B.foo;
}
''');

    assertPrefixedIdentifier(
      findNode.prefixed('B.foo'),
      element: findElement.getter('foo'),
      type: 'int',
    );

    assertTypeAliasRef(
      findNode.simple('B.foo'),
      findElement.typeAlias('B'),
    );

    assertSimpleIdentifier(
      findNode.simple('foo;'),
      element: findElement.getter('foo'),
      type: 'int',
    );
  }
}

@reflectiveTest
class PrefixedIdentifierResolutionWithNullSafetyTest
    extends PrefixedIdentifierResolutionTest with WithNullSafetyMixin {
  test_deferredImportPrefix_loadLibrary_optIn_fromOptOut() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A {}
''');

    await assertErrorsInCode(r'''
// @dart = 2.7
import 'a.dart' deferred as a;

main() {
  a.loadLibrary;
}
''', [
      error(HintCode.UNUSED_IMPORT, 22, 8),
    ]);

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
