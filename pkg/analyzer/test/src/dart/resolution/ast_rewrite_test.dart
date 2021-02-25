// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AstRewriteMethodInvocationTest);
    defineReflectiveTests(
      AstRewriteMethodInvocationWithNonFunctionTypeAliasesTest,
    );
  });
}

@reflectiveTest
class AstRewriteMethodInvocationTest extends PubPackageResolutionTest
    with AstRewriteMethodInvocationTestCases {}

mixin AstRewriteMethodInvocationTestCases on PubPackageResolutionTest {
  test_targetNull_cascade() async {
    await assertNoErrorsInCode(r'''
class A {
  void foo() {}
}

f(A a) {
  a..foo();
}
''');

    var invocation = findNode.methodInvocation('foo();');
    assertElement(invocation, findElement.method('foo'));
  }

  test_targetNull_class() async {
    await assertNoErrorsInCode(r'''
class A<T, U> {
  A(int a);
}

f() {
  A<int, String>(0);
}
''');

    var creation = findNode.instanceCreation('A<int, String>(0);');
    assertInstanceCreation(
      creation,
      findElement.class_('A'),
      'A<int, String>',
      expectedConstructorMember: true,
      expectedSubstitution: {'T': 'int', 'U': 'String'},
    );
    _assertArgumentList(creation.argumentList, ['0']);
  }

  test_targetNull_extension() async {
    await assertNoErrorsInCode(r'''
class A {}

extension E<T> on A {
  void foo() {}
}

f(A a) {
  E<int>(a).foo();
}
''');

    var override = findNode.extensionOverride('E<int>(a)');
    _assertExtensionOverride(
      override,
      expectedElement: findElement.extension_('E'),
      expectedTypeArguments: ['int'],
      expectedExtendedType: 'A',
    );
  }

  test_targetNull_function() async {
    await assertNoErrorsInCode(r'''
void A<T, U>(int a) {}

f() {
  A<int, String>(0);
}
''');

    var invocation = findNode.methodInvocation('A<int, String>(0);');
    assertElement(invocation, findElement.topFunction('A'));
    assertInvokeType(invocation, 'void Function(int)');
    _assertArgumentList(invocation.argumentList, ['0']);
  }

  test_targetPrefixedIdentifier_prefix_class_constructor() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A<T> {
  A.named(T a);
}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

f() {
  prefix.A.named(0);
}
''');

    var importFind = findElement.importFind('package:test/a.dart');

    var creation = findNode.instanceCreation('A.named(0);');
    assertInstanceCreation(
      creation,
      importFind.class_('A'),
      'A<int>',
      constructorName: 'named',
      expectedPrefix: importFind.prefix,
      expectedConstructorMember: true,
      expectedSubstitution: {'T': 'int'},
    );
    _assertArgumentList(creation.argumentList, ['0']);
  }

  test_targetPrefixedIdentifier_prefix_class_constructor_typeArguments() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A<T> {
  A.named(int a);
}
''');

    await assertErrorsInCode(r'''
import 'a.dart' as prefix;

f() {
  prefix.A.named<int>(0);
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR, 50,
          5),
    ]);

    var importFind = findElement.importFind('package:test/a.dart');

    var creation = findNode.instanceCreation('named<int>(0);');
    assertInstanceCreation(
      creation,
      importFind.class_('A'),
      'A<int>',
      constructorName: 'named',
      expectedPrefix: importFind.prefix,
      expectedConstructorMember: true,
      expectedSubstitution: {'T': 'int'},
    );
    _assertTypeArgumentList(
      creation.constructorName.type.typeArguments,
      ['int'],
    );
    expect((creation as InstanceCreationExpressionImpl).typeArguments, isNull);
    _assertArgumentList(creation.argumentList, ['0']);
  }

  test_targetPrefixedIdentifier_prefix_getter_method() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
A get foo => A();

class A {
  void bar(int a) {}
}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

f() {
  prefix.foo.bar(0);
}
''');

    var importFind = findElement.importFind('package:test/a.dart');

    var invocation = findNode.methodInvocation('bar(0);');
    assertElement(invocation, importFind.class_('A').getMethod('bar'));
    assertInvokeType(invocation, 'void Function(int)');
    _assertArgumentList(invocation.argumentList, ['0']);
  }

  test_targetSimpleIdentifier_class_constructor() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  A.named(T a);
}

f() {
  A.named(0);
}
''');

    var creation = findNode.instanceCreation('A.named(0);');
    assertInstanceCreation(
      creation,
      findElement.class_('A'),
      'A<int>',
      constructorName: 'named',
      expectedConstructorMember: true,
      expectedSubstitution: {'T': 'int'},
    );
    _assertArgumentList(creation.argumentList, ['0']);
  }

  test_targetSimpleIdentifier_class_constructor_typeArguments() async {
    await assertErrorsInCode(r'''
class A<T, U> {
  A.named(int a);
}

f() {
  A.named<int, String>(0);
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR, 52,
          13),
    ]);

    var creation = findNode.instanceCreation('named<int, String>(0);');
    assertInstanceCreation(
      creation,
      findElement.class_('A'),
      // TODO(scheglov) Move type arguments
      'A<dynamic, dynamic>',
//      'A<int, String>',
      constructorName: 'named',
      expectedConstructorMember: true,
      // TODO(scheglov) Move type arguments
      expectedSubstitution: {'T': 'dynamic', 'U': 'dynamic'},
//      expectedSubstitution: {'T': 'int', 'U': 'String'},
    );
    // TODO(scheglov) Move type arguments
//    _assertTypeArgumentList(
//      creation.constructorName.type.typeArguments,
//      ['int', 'String'],
//    );
    // TODO(scheglov) Fix and uncomment.
//    expect((creation as InstanceCreationExpressionImpl).typeArguments, isNull);
    _assertArgumentList(creation.argumentList, ['0']);
  }

  test_targetSimpleIdentifier_class_staticMethod() async {
    await assertNoErrorsInCode(r'''
class A {
  static void foo(int a) {}
}

f() {
  A.foo(0);
}
''');

    var invocation = findNode.methodInvocation('foo(0);');
    assertElement(invocation, findElement.method('foo'));
  }

  test_targetSimpleIdentifier_prefix_class() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A<T, U> {
  A(int a);
}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

f() {
  prefix.A<int, String>(0);
}
''');

    var importFind = findElement.importFind('package:test/a.dart');

    var creation = findNode.instanceCreation('A<int, String>(0);');
    assertInstanceCreation(
      creation,
      importFind.class_('A'),
      'A<int, String>',
      expectedPrefix: importFind.prefix,
      expectedConstructorMember: true,
      expectedSubstitution: {'T': 'int', 'U': 'String'},
    );
    _assertArgumentList(creation.argumentList, ['0']);
  }

  test_targetSimpleIdentifier_prefix_extension() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A {}

extension E<T> on A {
  void foo() {}
}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

f(prefix.A a) {
  prefix.E<int>(a).foo();
}
''');

    var importFind = findElement.importFind('package:test/a.dart');

    var override = findNode.extensionOverride('E<int>(a)');
    _assertExtensionOverride(
      override,
      expectedElement: importFind.extension_('E'),
      expectedTypeArguments: ['int'],
      expectedExtendedType: 'A',
    );
    assertImportPrefix(findNode.simple('prefix.E'), importFind.prefix);
  }

  test_targetSimpleIdentifier_prefix_function() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
void A<T, U>(int a) {}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

f() {
  prefix.A<int, String>(0);
}
''');

    var importFind = findElement.importFind('package:test/a.dart');

    var invocation = findNode.methodInvocation('A<int, String>(0);');
    assertElement(invocation, importFind.topFunction('A'));
    assertInvokeType(invocation, 'void Function(int)');
    _assertArgumentList(invocation.argumentList, ['0']);
  }

  void _assertArgumentList(
    ArgumentList argumentList,
    List<String> expectedArguments,
  ) {
    var argumentStrings = argumentList.arguments
        .map((e) => result.content.substring(e.offset, e.end))
        .toList();
    expect(argumentStrings, expectedArguments);
  }

  void _assertExtensionOverride(
    ExtensionOverride override, {
    @required ExtensionElement expectedElement,
    @required List<String> expectedTypeArguments,
    @required String expectedExtendedType,
  }) {
    expect(override.staticElement, expectedElement);

    assertTypeNull(override);
    assertTypeNull(override.extensionName);

    assertElementTypeStrings(
      override.typeArgumentTypes,
      expectedTypeArguments,
    );
    assertType(override.extendedType, expectedExtendedType);
  }

  void _assertTypeArgumentList(
    TypeArgumentList argumentList,
    List<String> expectedArguments,
  ) {
    var argumentStrings = argumentList.arguments
        .map((e) => result.content.substring(e.offset, e.end))
        .toList();
    expect(argumentStrings, expectedArguments);
  }
}

@reflectiveTest
class AstRewriteMethodInvocationWithNonFunctionTypeAliasesTest
    extends PubPackageResolutionTest
    with WithNonFunctionTypeAliasesMixin, AstRewriteMethodInvocationTestCases {
  test_targetNull_typeAlias_interfaceType() async {
    await assertNoErrorsInCode(r'''
class A<T, U> {
  A(int _);
}

typedef X<T, U> = A<T, U>;

void f() {
  X<int, String>(0);
}
''');

    var creation = findNode.instanceCreation('X<int, String>(0);');
    assertInstanceCreation(
      creation,
      findElement.class_('A'),
      'A<int, String>',
      expectedConstructorMember: true,
      expectedSubstitution: {'T': 'int', 'U': 'String'},
      expectedTypeNameElement: findElement.typeAlias('X'),
    );
    _assertArgumentList(creation.argumentList, ['0']);
  }

  test_targetNull_typeAlias_Never() async {
    await assertErrorsInCode(r'''
typedef X = Never;

void f() {
  X(0);
}
''', [
      error(CompileTimeErrorCode.INVOCATION_OF_NON_FUNCTION, 33, 1),
    ]);

    // Not rewritten.
    findNode.methodInvocation('X(0)');
  }

  test_targetPrefixedIdentifier_typeAlias_interfaceType_constructor() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A<T> {
  A.named(T a);
}

typedef X<T> = A<T>;
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

void f() {
  prefix.X.named(0);
}
''');

    var importFind = findElement.importFind('package:test/a.dart');

    var creation = findNode.instanceCreation('X.named(0);');
    assertInstanceCreation(
      creation,
      importFind.class_('A'),
      'A<int>',
      constructorName: 'named',
      expectedConstructorMember: true,
      expectedSubstitution: {'T': 'int'},
      expectedPrefix: findElement.prefix('prefix'),
      expectedTypeNameElement: importFind.typeAlias('X'),
    );
    _assertArgumentList(creation.argumentList, ['0']);
  }

  test_targetSimpleIdentifier_typeAlias_interfaceType_constructor() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  A.named(T a);
}

typedef X<T> = A<T>;

void f() {
  X.named(0);
}
''');

    var creation = findNode.instanceCreation('X.named(0);');
    assertInstanceCreation(
      creation,
      findElement.class_('A'),
      'A<int>',
      constructorName: 'named',
      expectedConstructorMember: true,
      expectedSubstitution: {'T': 'int'},
      expectedTypeNameElement: findElement.typeAlias('X'),
    );
    _assertArgumentList(creation.argumentList, ['0']);
  }
}
