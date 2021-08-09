// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstructorReferenceResolutionTest);
    defineReflectiveTests(
        ConstructorReferenceResolutionWithoutConstructorTearoffsTest);
  });
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

  test_classs_generic_named_inferTypeFromContext() async {
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
