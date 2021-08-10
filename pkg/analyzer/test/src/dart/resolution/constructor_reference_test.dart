// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstructorReferenceResolutionTest);
    defineReflectiveTests(ConstructorReferenceResolution_TypeArgsTest);
    defineReflectiveTests(
        ConstructorReferenceResolutionWithoutConstructorTearoffsTest);
  });
}

@reflectiveTest
class ConstructorReferenceResolution_TypeArgsTest
    extends PubPackageResolutionTest {
  test_alias_generic_named() async {
    await assertNoErrorsInCode('''
class A<T, U> {
  A.foo();
}
typedef TA<T, U> = A<U, T>;

void bar() {
  TA<int, String>.foo;
}
''');

    var classElement = findElement.class_('A');
    assertConstructorReference(
      findNode.constructorReference('TA<int, String>.foo;'),
      elementMatcher(classElement.getNamedConstructor('foo')!,
          substitution: {'T': 'String', 'U': 'int'}),
      classElement,
      'A<String, int> Function()',
      expectedTypeNameType: 'A<String, int>',
      expectedTypeNameElement: findElement.typeAlias('TA'),
    );
  }

  test_alias_generic_unnamed() async {
    await assertNoErrorsInCode('''
class A<T> {
  A();
}
typedef TA<T> = A<T>;

void bar() {
  TA<int>.new;
}
''');

    var classElement = findElement.class_('A');
    assertConstructorReference(
      findNode.constructorReference('TA<int>.new;'),
      elementMatcher(classElement.unnamedConstructor,
          substitution: {'T': 'int'}),
      classElement,
      'A<int> Function()',
      expectedTypeNameType: 'A<int>',
      expectedTypeNameElement: findElement.typeAlias('TA'),
    );
  }

  test_alias_genericWithBound_unnamed() async {
    await assertNoErrorsInCode('''
class A<T> {
  A();
}
typedef TA<T extends num> = A<T>;

void bar() {
  TA<int>.new;
}
''');

    var classElement = findElement.class_('A');
    assertConstructorReference(
      findNode.constructorReference('TA<int>.new;'),
      elementMatcher(classElement.unnamedConstructor,
          substitution: {'T': 'int'}),
      classElement,
      'A<int> Function()',
      expectedTypeNameType: 'A<int>',
      expectedTypeNameElement: findElement.typeAlias('TA'),
    );
  }

  test_alias_genericWithBound_unnamed_badBound() async {
    await assertErrorsInCode('''
class A<T> {
  A();
}
typedef TA<T extends num> = A<T>;

void bar() {
  TA<String>.new;
}
''', [
      error(CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, 75, 6),
    ]);

    var classElement = findElement.class_('A');
    assertConstructorReference(
      findNode.constructorReference('TA<String>.new;'),
      elementMatcher(classElement.unnamedConstructor,
          substitution: {'T': 'String'}),
      classElement,
      'A<String> Function()',
      expectedTypeNameType: 'A<String>',
      expectedTypeNameElement: findElement.typeAlias('TA'),
    );
  }

  test_class_generic_named() async {
    await assertNoErrorsInCode('''
class A<T> {
  A.foo();
}

void bar() {
  A<int>.foo;
}
''');

    var classElement = findElement.class_('A');
    assertConstructorReference(
      findNode.constructorReference('A<int>.foo;'),
      elementMatcher(classElement.getNamedConstructor('foo')!,
          substitution: {'T': 'int'}),
      classElement,
      'A<int> Function()',
      expectedTypeNameType: 'A<int>',
    );
  }

  test_class_generic_named_cascade() async {
    await assertErrorsInCode('''
class A<T> {
  A.foo();
}

void bar() {
  A<int>..foo;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 50, 3),
    ]);

    // The nodes are not rewritten into a [ConstructorReference].
    var cascade = findNode.cascade('A<int>..foo;');
    assertType(cascade, 'Type');
    var section = cascade.cascadeSections.first as PropertyAccess;
    assertType(section, 'dynamic');
    assertType(section.propertyName, 'dynamic');
  }

  test_class_generic_named_nullAware() async {
    await assertNoErrorsInCode('''
class A<T> {
  A.foo();
}

void bar() {
  A<int>?.foo;
}
''');

    var classElement = findElement.class_('A');
    assertConstructorReference(
      findNode.constructorReference('A<int>?.foo;'),
      elementMatcher(classElement.getNamedConstructor('foo')!,
          substitution: {'T': 'int'}),
      classElement,
      'A<int> Function()',
      expectedTypeNameType: 'A<int>',
    );
  }

  test_class_generic_named_typeArgs() async {
    await assertErrorsInCode('''
class A<T> {
  A.foo();
}

void bar() {
  A<int>.foo<int>;
}
''', [
      error(CompileTimeErrorCode.DISALLOWED_TYPE_INSTANTIATION_EXPRESSION, 42,
          10),
      // TODO(srawlins): Stop reporting the error below; the code is not
      // precise, and it is duplicate with the code above.
      error(
          CompileTimeErrorCode
              .WRONG_NUMBER_OF_TYPE_ARGUMENTS_ANONYMOUS_FUNCTION,
          52,
          5),
    ]);

    var classElement = findElement.class_('A');
    assertConstructorReference(
      findNode.constructorReference('A<int>.foo<int>;'),
      elementMatcher(classElement.getNamedConstructor('foo')!,
          substitution: {'T': 'int'}),
      classElement,
      'A<int> Function()',
      expectedTypeNameType: 'A<int>',
    );
  }

  test_class_generic_unnamed() async {
    await assertNoErrorsInCode('''
class A<T> {
  A();
}

void bar() {
  A<int>.new;
}
''');

    var classElement = findElement.class_('A');
    assertConstructorReference(
      findNode.constructorReference('A<int>.new;'),
      elementMatcher(classElement.unnamedConstructor,
          substitution: {'T': 'int'}),
      classElement,
      'A<int> Function()',
      expectedTypeNameType: 'A<int>',
    );
  }

  test_class_generic_unnamed_partOfPropertyAccess() async {
    await assertNoErrorsInCode('''
class A<T> {
  A();
}

void bar() {
  A<int>.new.runtimeType;
}
''');

    var classElement = findElement.class_('A');
    assertConstructorReference(
      findNode.constructorReference('A<int>.new'),
      elementMatcher(classElement.unnamedConstructor,
          substitution: {'T': 'int'}),
      classElement,
      'A<int> Function()',
      expectedTypeNameType: 'A<int>',
    );
  }

  test_class_genericWithBound_unnamed() async {
    await assertNoErrorsInCode('''
class A<T extends num> {
  A();
}

void bar() {
  A<int>.new;
}
''');

    var classElement = findElement.class_('A');
    assertConstructorReference(
      findNode.constructorReference('A<int>.new;'),
      elementMatcher(classElement.unnamedConstructor,
          substitution: {'T': 'int'}),
      classElement,
      'A<int> Function()',
      expectedTypeNameType: 'A<int>',
    );
  }

  test_class_genericWithBound_unnamed_badBound() async {
    await assertErrorsInCode('''
class A<T extends num> {
  A();
}

void bar() {
  A<String>.new;
}
''', [
      error(CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, 52, 6),
    ]);

    var classElement = findElement.class_('A');
    assertConstructorReference(
      findNode.constructorReference('A<String>.new;'),
      elementMatcher(classElement.unnamedConstructor,
          substitution: {'T': 'String'}),
      classElement,
      'A<String> Function()',
      expectedTypeNameType: 'A<String>',
    );
  }

  test_prefixedAlias_generic_unnamed() async {
    newFile('$testPackageLibPath/a.dart', content: '''
class A<T> {
  A();
}
typedef TA<T> = A<T>;
''');
    await assertNoErrorsInCode('''
import 'a.dart' as a;
void bar() {
  a.TA<int>.new;
}
''');

    var classElement =
        findElement.importFind('package:test/a.dart').class_('A');
    assertConstructorReference(
      findNode.constructorReference('a.TA<int>.new;'),
      elementMatcher(classElement.unnamedConstructor,
          substitution: {'T': 'int'}),
      classElement,
      'A<int> Function()',
      expectedTypeNameType: 'A<int>',
      expectedPrefix: findElement.import('package:test/a.dart').prefix,
      expectedTypeNameElement:
          findElement.importFind('package:test/a.dart').typeAlias('TA'),
    );
  }

  test_prefixedClass_generic_named() async {
    newFile('$testPackageLibPath/a.dart', content: '''
class A<T> {
  A.foo();
}
''');
    await assertNoErrorsInCode('''
import 'a.dart' as a;
void bar() {
  a.A<int>.foo;
}
''');

    var classElement =
        findElement.importFind('package:test/a.dart').class_('A');
    assertConstructorReference(
      findNode.constructorReference('a.A<int>.foo;'),
      elementMatcher(classElement.getNamedConstructor('foo')!,
          substitution: {'T': 'int'}),
      classElement,
      'A<int> Function()',
      expectedTypeNameType: 'A<int>',
      expectedPrefix: findElement.import('package:test/a.dart').prefix,
    );
  }

  test_prefixedClass_generic_unnamed() async {
    newFile('$testPackageLibPath/a.dart', content: '''
class A<T> {
  A();
}
''');
    await assertNoErrorsInCode('''
import 'a.dart' as a;
void bar() {
  a.A<int>.new;
}
''');

    var classElement =
        findElement.importFind('package:test/a.dart').class_('A');
    assertConstructorReference(
      findNode.constructorReference('a.A<int>.new;'),
      elementMatcher(classElement.unnamedConstructor,
          substitution: {'T': 'int'}),
      classElement,
      'A<int> Function()',
      expectedTypeNameType: 'A<int>',
      expectedPrefix: findElement.import('package:test/a.dart').prefix,
    );
  }
}

@reflectiveTest
class ConstructorReferenceResolutionTest extends PubPackageResolutionTest {
  test_class_generic_inferFromContext_badTypeArgument() async {
    await assertErrorsInCode('''
class A<T extends num> {
  A.foo();
}

A<String> Function() bar() {
  return A.foo;
}
''', [
      error(CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, 41, 6),
    ]);

    var classElement = findElement.class_('A');
    var constructorElement = classElement.getNamedConstructor('foo')!;
    assertConstructorReference(
      findNode.constructorReference('A.foo;'),
      elementMatcher(constructorElement, substitution: {'T': 'Never'}),
      classElement,
      'A<Never> Function()',
      expectedTypeNameType: 'A<Never>',
    );
  }

  test_class_generic_named_inferTypeFromContext() async {
    await assertNoErrorsInCode('''
class A<T> {
  A.foo();
}

A<int> Function() bar() {
  return A.foo;
}
''');

    var classElement = findElement.class_('A');
    var constructorElement = classElement.getNamedConstructor('foo')!;
    assertConstructorReference(
      findNode.constructorReference('A.foo;'),
      elementMatcher(constructorElement, substitution: {'T': 'int'}),
      classElement,
      'A<int> Function()',
      expectedTypeNameType: 'A<int>',
    );
  }

  test_class_generic_named_uninstantiated() async {
    await assertNoErrorsInCode('''
class A<T> {
  A.foo();
}

void bar() {
  A.foo;
}
''');

    var classElement = findElement.class_('A');
    var constructorElement = classElement.getNamedConstructor('foo')!;
    assertConstructorReference(
      findNode.constructorReference('A.foo;'),
      elementMatcher(constructorElement, substitution: {'T': 'T'}),
      classElement,
      'A<T> Function<T>()',
      expectedTypeNameType: 'A<T>',
    );
  }

  test_class_generic_named_uninstantiated_bound() async {
    await assertNoErrorsInCode('''
class A<T extends num> {
  A.foo();
}

void bar() {
  A.foo;
}
''');

    var classElement = findElement.class_('A');
    var constructorElement = classElement.getNamedConstructor('foo')!;
    assertConstructorReference(
      findNode.constructorReference('A.foo;'),
      elementMatcher(constructorElement, substitution: {'T': 'T'}),
      classElement,
      'A<T> Function<T extends num>()',
      expectedTypeNameType: 'A<T>',
    );
  }

  test_class_nonGeneric_named() async {
    await assertNoErrorsInCode('''
class A {
  A.foo();
}

void bar() {
  A.foo;
}
''');

    var classElement = findElement.class_('A');
    assertConstructorReference(
      findNode.constructorReference('A.foo;'),
      classElement.getNamedConstructor('foo')!,
      classElement,
      'A Function()',
      expectedTypeNameType: 'A',
    );
  }

  test_class_nonGeneric_unnamed() async {
    await assertNoErrorsInCode('''
class A {
  A();
}

bar() {
  A.new;
}
''');

    var classElement = findElement.class_('A');
    assertConstructorReference(
      findNode.constructorReference('A.new;'),
      classElement.unnamedConstructor,
      classElement,
      'A Function()',
      expectedTypeNameType: 'A',
    );
  }

  test_typeAlias_generic_named_uninstantiated() async {
    await assertNoErrorsInCode('''
class A<T, U> {
  A.foo();
}
typedef TA<U> = A<String, U>;

bar() {
  TA.foo;
}
''');

    var classElement = findElement.class_('A');
    var constructorElement = classElement.getNamedConstructor('foo')!;
    assertConstructorReference(
      findNode.constructorReference('TA.foo;'),
      elementMatcher(constructorElement,
          substitution: {'T': 'String', 'U': 'U'}),
      findElement.class_('A'),
      'A<String, U> Function<U>()',
      expectedTypeNameType: 'A<String, U>',
      expectedTypeNameElement: findElement.typeAlias('TA'),
    );
  }

  test_typeAlias_instantiated_named() async {
    await assertNoErrorsInCode('''
class A<T> {
  A.foo();
}
typedef TA = A<int>;

bar() {
  TA.foo;
}
''');

    var classElement = findElement.class_('A');
    var constructorElement = classElement.getNamedConstructor('foo')!;
    assertConstructorReference(
      findNode.constructorReference('TA.foo;'),
      elementMatcher(constructorElement, substitution: {'T': 'int'}),
      classElement,
      'A<int> Function()',
      expectedTypeNameType: 'A<int>',
      expectedTypeNameElement: findElement.typeAlias('TA'),
    );
  }
}

@reflectiveTest
class ConstructorReferenceResolutionWithoutConstructorTearoffsTest
    extends PubPackageResolutionTest with WithoutConstructorTearoffsMixin {
  test_constructorTearoff() async {
    await assertErrorsInCode('''
class A {
  A.foo();
}

void bar() {
  A.foo;
}
''', [
      error(CompileTimeErrorCode.CONSTRUCTOR_TEAROFFS_NOT_ENABLED, 39, 5),
    ]);

    var classElement = findElement.class_('A');
    assertConstructorReference(
      findNode.constructorReference('A.foo;'),
      classElement.getNamedConstructor('foo')!,
      classElement,
      'A Function()',
      expectedTypeNameType: 'A',
    );
  }
}
