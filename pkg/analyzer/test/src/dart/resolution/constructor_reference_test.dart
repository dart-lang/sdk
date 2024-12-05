// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstructorReferenceResolutionTest);
    defineReflectiveTests(ConstructorReferenceResolutionTest_TypeArgs);
    defineReflectiveTests(
        ConstructorReferenceResolutionTest_WithoutConstructorTearoffs);
  });
}

@reflectiveTest
class ConstructorReferenceResolutionTest extends PubPackageResolutionTest {
  test_abstractClass_factory() async {
    await assertNoErrorsInCode('''
abstract class A {
  factory A() => A2();
}

class A2 implements A {}

foo() {
  A.new;
}
''');

    var node = findNode.constructorReference('A.new;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: A
      element: <testLibraryFragment>::@class::A
      element2: <testLibraryFragment>::@class::A#element
      type: null
    period: .
    name: SimpleIdentifier
      token: new
      staticElement: <testLibraryFragment>::@class::A::@constructor::new
      element: <testLibraryFragment>::@class::A::@constructor::new#element
      staticType: null
    staticElement: <testLibraryFragment>::@class::A::@constructor::new
    element: <testLibraryFragment>::@class::A::@constructor::new#element
  staticType: A Function()
''');
  }

  test_abstractClass_generative() async {
    await assertErrorsInCode('''
abstract class A {
  A();
}

foo() {
  A.new;
}
''', [
      error(
          CompileTimeErrorCode
              .TEAROFF_OF_GENERATIVE_CONSTRUCTOR_OF_ABSTRACT_CLASS,
          39,
          5),
    ]);

    var node = findNode.constructorReference('A.new;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: A
      element: <testLibraryFragment>::@class::A
      element2: <testLibraryFragment>::@class::A#element
      type: null
    period: .
    name: SimpleIdentifier
      token: new
      staticElement: <testLibraryFragment>::@class::A::@constructor::new
      element: <testLibraryFragment>::@class::A::@constructor::new#element
      staticType: null
    staticElement: <testLibraryFragment>::@class::A::@constructor::new
    element: <testLibraryFragment>::@class::A::@constructor::new#element
  staticType: A Function()
''');
  }

  test_abstractClass_redirecting() async {
    await assertErrorsInCode('''
abstract class A {
  A(): this.two();

  A.two();
}

foo() {
  A.new;
}
''', [
      error(
          CompileTimeErrorCode
              .TEAROFF_OF_GENERATIVE_CONSTRUCTOR_OF_ABSTRACT_CLASS,
          63,
          5),
    ]);

    var node = findNode.constructorReference('A.new;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: A
      element: <testLibraryFragment>::@class::A
      element2: <testLibraryFragment>::@class::A#element
      type: null
    period: .
    name: SimpleIdentifier
      token: new
      staticElement: <testLibraryFragment>::@class::A::@constructor::new
      element: <testLibraryFragment>::@class::A::@constructor::new#element
      staticType: null
    staticElement: <testLibraryFragment>::@class::A::@constructor::new
    element: <testLibraryFragment>::@class::A::@constructor::new#element
  staticType: A Function()
''');
  }

  test_class_generic_inferFromContext_badTypeArgument() async {
    await assertErrorsInCode('''
class A<T extends num> {
  A.foo();
}

A<String> Function() bar() {
  return A.foo;
}
''', [
      error(CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, 41, 6,
          contextMessages: [message(testFile, 39, 9)]),
    ]);

    var node = findNode.constructorReference('A.foo;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: A
      element: <testLibraryFragment>::@class::A
      element2: <testLibraryFragment>::@class::A#element
      type: null
    period: .
    name: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@class::A::@constructor::foo
      element: <testLibraryFragment>::@class::A::@constructor::foo#element
      staticType: null
      tearOffTypeArgumentTypes
        Never
    staticElement: <testLibraryFragment>::@class::A::@constructor::foo
    element: <testLibraryFragment>::@class::A::@constructor::foo#element
  staticType: A<Never> Function()
''');
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

    var node = findNode.constructorReference('A.foo;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: A
      element: <testLibraryFragment>::@class::A
      element2: <testLibraryFragment>::@class::A#element
      type: null
    period: .
    name: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@class::A::@constructor::foo
      element: <testLibraryFragment>::@class::A::@constructor::foo#element
      staticType: null
      tearOffTypeArgumentTypes
        int
    staticElement: <testLibraryFragment>::@class::A::@constructor::foo
    element: <testLibraryFragment>::@class::A::@constructor::foo#element
  staticType: A<int> Function()
''');
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

    var node = findNode.constructorReference('A.foo;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: A
      element: <testLibraryFragment>::@class::A
      element2: <testLibraryFragment>::@class::A#element
      type: null
    period: .
    name: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@class::A::@constructor::foo
      element: <testLibraryFragment>::@class::A::@constructor::foo#element
      staticType: null
    staticElement: <testLibraryFragment>::@class::A::@constructor::foo
    element: <testLibraryFragment>::@class::A::@constructor::foo#element
  staticType: A<T> Function<T>()
''');
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

    var node = findNode.constructorReference('A.foo;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: A
      element: <testLibraryFragment>::@class::A
      element2: <testLibraryFragment>::@class::A#element
      type: null
    period: .
    name: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@class::A::@constructor::foo
      element: <testLibraryFragment>::@class::A::@constructor::foo#element
      staticType: null
    staticElement: <testLibraryFragment>::@class::A::@constructor::foo
    element: <testLibraryFragment>::@class::A::@constructor::foo#element
  staticType: A<T> Function<T extends num>()
''');
  }

  test_class_nonGeneric_const() async {
    await assertNoErrorsInCode('''
class A {
  const A();
}

const a1 = A.new;
''');

    var node = findNode.constructorReference('A.new;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: A
      element: <testLibraryFragment>::@class::A
      element2: <testLibraryFragment>::@class::A#element
      type: null
    period: .
    name: SimpleIdentifier
      token: new
      staticElement: <testLibraryFragment>::@class::A::@constructor::new
      element: <testLibraryFragment>::@class::A::@constructor::new#element
      staticType: null
    staticElement: <testLibraryFragment>::@class::A::@constructor::new
    element: <testLibraryFragment>::@class::A::@constructor::new#element
  staticType: A Function()
''');
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

    var node = findNode.constructorReference('A.foo;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: A
      element: <testLibraryFragment>::@class::A
      element2: <testLibraryFragment>::@class::A#element
      type: null
    period: .
    name: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@class::A::@constructor::foo
      element: <testLibraryFragment>::@class::A::@constructor::foo#element
      staticType: null
    staticElement: <testLibraryFragment>::@class::A::@constructor::foo
    element: <testLibraryFragment>::@class::A::@constructor::foo#element
  staticType: A Function()
''');
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

    var node = findNode.constructorReference('A.new;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: A
      element: <testLibraryFragment>::@class::A
      element2: <testLibraryFragment>::@class::A#element
      type: null
    period: .
    name: SimpleIdentifier
      token: new
      staticElement: <testLibraryFragment>::@class::A::@constructor::new
      element: <testLibraryFragment>::@class::A::@constructor::new#element
      staticType: null
    staticElement: <testLibraryFragment>::@class::A::@constructor::new
    element: <testLibraryFragment>::@class::A::@constructor::new#element
  staticType: A Function()
''');
  }

  test_prefixedAlias_nonGeneric_named() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {
  A.foo();
}
typedef TA = A;
''');
    await assertNoErrorsInCode('''
import 'a.dart' as a;
bar() {
  a.TA.foo;
}
''');

    var node = findNode.constructorReference('a.TA.foo;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: a
        period: .
        element: <testLibraryFragment>::@prefix::a
        element2: <testLibraryFragment>::@prefix2::a
      name: TA
      element: package:test/a.dart::<fragment>::@typeAlias::TA
      element2: package:test/a.dart::<fragment>::@typeAlias::TA#element
      type: null
    period: .
    name: SimpleIdentifier
      token: foo
      staticElement: package:test/a.dart::<fragment>::@class::A::@constructor::foo
      element: package:test/a.dart::<fragment>::@class::A::@constructor::foo#element
      staticType: null
    staticElement: package:test/a.dart::<fragment>::@class::A::@constructor::foo
    element: package:test/a.dart::<fragment>::@class::A::@constructor::foo#element
  staticType: A Function()
''');
  }

  test_prefixedAlias_nonGeneric_unnamed() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {
  A();
}
typedef TA = A;
''');
    await assertNoErrorsInCode('''
import 'a.dart' as a;
bar() {
  a.TA.new;
}
''');

    var node = findNode.constructorReference('a.TA.new;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: a
        period: .
        element: <testLibraryFragment>::@prefix::a
        element2: <testLibraryFragment>::@prefix2::a
      name: TA
      element: package:test/a.dart::<fragment>::@typeAlias::TA
      element2: package:test/a.dart::<fragment>::@typeAlias::TA#element
      type: null
    period: .
    name: SimpleIdentifier
      token: new
      staticElement: package:test/a.dart::<fragment>::@class::A::@constructor::new
      element: package:test/a.dart::<fragment>::@class::A::@constructor::new#element
      staticType: null
    staticElement: package:test/a.dart::<fragment>::@class::A::@constructor::new
    element: package:test/a.dart::<fragment>::@class::A::@constructor::new#element
  staticType: A Function()
''');
  }

  test_prefixedClass_nonGeneric_named() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {
  A.foo();
}
''');
    await assertNoErrorsInCode('''
import 'a.dart' as a;
bar() {
  a.A.foo;
}
''');

    var node = findNode.constructorReference('a.A.foo;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: a
        period: .
        element: <testLibraryFragment>::@prefix::a
        element2: <testLibraryFragment>::@prefix2::a
      name: A
      element: package:test/a.dart::<fragment>::@class::A
      element2: package:test/a.dart::<fragment>::@class::A#element
      type: null
    period: .
    name: SimpleIdentifier
      token: foo
      staticElement: package:test/a.dart::<fragment>::@class::A::@constructor::foo
      element: package:test/a.dart::<fragment>::@class::A::@constructor::foo#element
      staticType: null
    staticElement: package:test/a.dart::<fragment>::@class::A::@constructor::foo
    element: package:test/a.dart::<fragment>::@class::A::@constructor::foo#element
  staticType: A Function()
''');
  }

  test_prefixedClass_nonGeneric_unnamed() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {
  A();
}
''');
    await assertNoErrorsInCode('''
import 'a.dart' as a;
bar() {
  a.A.new;
}
''');

    var node = findNode.constructorReference('a.A.new;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: a
        period: .
        element: <testLibraryFragment>::@prefix::a
        element2: <testLibraryFragment>::@prefix2::a
      name: A
      element: package:test/a.dart::<fragment>::@class::A
      element2: package:test/a.dart::<fragment>::@class::A#element
      type: null
    period: .
    name: SimpleIdentifier
      token: new
      staticElement: package:test/a.dart::<fragment>::@class::A::@constructor::new
      element: package:test/a.dart::<fragment>::@class::A::@constructor::new#element
      staticType: null
    staticElement: package:test/a.dart::<fragment>::@class::A::@constructor::new
    element: package:test/a.dart::<fragment>::@class::A::@constructor::new#element
  staticType: A Function()
''');
  }

  test_typeAlias_generic_const() async {
    await assertNoErrorsInCode('''
class A<T> {
  const A();
}
typedef TA<T> = A<T>;

const a = TA.new;
''');

    var node = findNode.constructorReference('TA.new;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: TA
      element: <testLibraryFragment>::@typeAlias::TA
      element2: <testLibraryFragment>::@typeAlias::TA#element
      type: null
    period: .
    name: SimpleIdentifier
      token: new
      staticElement: <testLibraryFragment>::@class::A::@constructor::new
      element: <testLibraryFragment>::@class::A::@constructor::new#element
      staticType: null
    staticElement: <testLibraryFragment>::@class::A::@constructor::new
    element: <testLibraryFragment>::@class::A::@constructor::new#element
  staticType: A<T> Function<T>()
''');
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

    var node = findNode.constructorReference('TA.foo;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: TA
      element: <testLibraryFragment>::@typeAlias::TA
      element2: <testLibraryFragment>::@typeAlias::TA#element
      type: null
    period: .
    name: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@class::A::@constructor::foo
      element: <testLibraryFragment>::@class::A::@constructor::foo#element
      staticType: null
    staticElement: <testLibraryFragment>::@class::A::@constructor::foo
    element: <testLibraryFragment>::@class::A::@constructor::foo#element
  staticType: A<String, U> Function<U>()
''');
  }

  test_typeAlias_instantiated_const() async {
    await assertNoErrorsInCode('''
class A<T> {
  const A();
}
typedef TA = A<int>;

const a = TA.new;
''');

    var node = findNode.constructorReference('TA.new;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: TA
      element: <testLibraryFragment>::@typeAlias::TA
      element2: <testLibraryFragment>::@typeAlias::TA#element
      type: null
    period: .
    name: SimpleIdentifier
      token: new
      staticElement: ConstructorMember
        base: <testLibraryFragment>::@class::A::@constructor::new
        substitution: {T: int}
      element: <testLibraryFragment>::@class::A::@constructor::new#element
      staticType: null
    staticElement: ConstructorMember
      base: <testLibraryFragment>::@class::A::@constructor::new
      substitution: {T: int}
    element: <testLibraryFragment>::@class::A::@constructor::new#element
  staticType: A<int> Function()
''');
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

    var node = findNode.constructorReference('TA.foo;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: TA
      element: <testLibraryFragment>::@typeAlias::TA
      element2: <testLibraryFragment>::@typeAlias::TA#element
      type: null
    period: .
    name: SimpleIdentifier
      token: foo
      staticElement: ConstructorMember
        base: <testLibraryFragment>::@class::A::@constructor::foo
        substitution: {T: int}
      element: <testLibraryFragment>::@class::A::@constructor::foo#element
      staticType: null
    staticElement: ConstructorMember
      base: <testLibraryFragment>::@class::A::@constructor::foo
      substitution: {T: int}
    element: <testLibraryFragment>::@class::A::@constructor::foo#element
  staticType: A<int> Function()
''');
  }
}

@reflectiveTest
class ConstructorReferenceResolutionTest_TypeArgs
    extends PubPackageResolutionTest {
  test_alias_generic_const() async {
    await assertNoErrorsInCode('''
class A<T, U> {
  const A.foo();
}
typedef TA<T, U> = A<U, T>;

const a = TA<int, String>.foo;
''');

    var node = findNode.constructorReference('TA<int, String>.foo;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: TA
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::<fragment>::@class::int
            element2: dart:core::<fragment>::@class::int#element
            type: int
          NamedType
            name: String
            element: dart:core::<fragment>::@class::String
            element2: dart:core::<fragment>::@class::String#element
            type: String
        rightBracket: >
      element: <testLibraryFragment>::@typeAlias::TA
      element2: <testLibraryFragment>::@typeAlias::TA#element
      type: null
    period: .
    name: SimpleIdentifier
      token: foo
      staticElement: ConstructorMember
        base: <testLibraryFragment>::@class::A::@constructor::foo
        substitution: {T: String, U: int}
      element: <testLibraryFragment>::@class::A::@constructor::foo#element
      staticType: null
    staticElement: ConstructorMember
      base: <testLibraryFragment>::@class::A::@constructor::foo
      substitution: {T: String, U: int}
    element: <testLibraryFragment>::@class::A::@constructor::foo#element
  staticType: A<String, int> Function()
''');
  }

  test_alias_generic_const_differingNumberOfTypeParameters() async {
    await assertNoErrorsInCode('''
class A<T, U> {
  A.foo() {}
}
typedef TA<T> = A<T, String>;

const x = TA<int>.foo;
''');

    var node = findNode.constructorReference('TA<int>.foo;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: TA
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::<fragment>::@class::int
            element2: dart:core::<fragment>::@class::int#element
            type: int
        rightBracket: >
      element: <testLibraryFragment>::@typeAlias::TA
      element2: <testLibraryFragment>::@typeAlias::TA#element
      type: null
    period: .
    name: SimpleIdentifier
      token: foo
      staticElement: ConstructorMember
        base: <testLibraryFragment>::@class::A::@constructor::foo
        substitution: {T: int, U: String}
      element: <testLibraryFragment>::@class::A::@constructor::foo#element
      staticType: null
    staticElement: ConstructorMember
      base: <testLibraryFragment>::@class::A::@constructor::foo
      substitution: {T: int, U: String}
    element: <testLibraryFragment>::@class::A::@constructor::foo#element
  staticType: A<int, String> Function()
''');
  }

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

    var node = findNode.constructorReference('TA<int, String>.foo;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: TA
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::<fragment>::@class::int
            element2: dart:core::<fragment>::@class::int#element
            type: int
          NamedType
            name: String
            element: dart:core::<fragment>::@class::String
            element2: dart:core::<fragment>::@class::String#element
            type: String
        rightBracket: >
      element: <testLibraryFragment>::@typeAlias::TA
      element2: <testLibraryFragment>::@typeAlias::TA#element
      type: null
    period: .
    name: SimpleIdentifier
      token: foo
      staticElement: ConstructorMember
        base: <testLibraryFragment>::@class::A::@constructor::foo
        substitution: {T: String, U: int}
      element: <testLibraryFragment>::@class::A::@constructor::foo#element
      staticType: null
    staticElement: ConstructorMember
      base: <testLibraryFragment>::@class::A::@constructor::foo
      substitution: {T: String, U: int}
    element: <testLibraryFragment>::@class::A::@constructor::foo#element
  staticType: A<String, int> Function()
''');
  }

  test_alias_generic_uninstantiated_const() async {
    await assertNoErrorsInCode('''
class A<T, U> {
  const A.foo();
}
typedef TA<T, U> = A<U, T>;

const a = TA.foo;
''');

    var node = findNode.constructorReference('TA.foo;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: TA
      element: <testLibraryFragment>::@typeAlias::TA
      element2: <testLibraryFragment>::@typeAlias::TA#element
      type: null
    period: .
    name: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@class::A::@constructor::foo
      element: <testLibraryFragment>::@class::A::@constructor::foo#element
      staticType: null
    staticElement: <testLibraryFragment>::@class::A::@constructor::foo
    element: <testLibraryFragment>::@class::A::@constructor::foo#element
  staticType: A<U, T> Function<T, U>()
''');
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

    var node = findNode.constructorReference('TA<int>.new;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: TA
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::<fragment>::@class::int
            element2: dart:core::<fragment>::@class::int#element
            type: int
        rightBracket: >
      element: <testLibraryFragment>::@typeAlias::TA
      element2: <testLibraryFragment>::@typeAlias::TA#element
      type: null
    period: .
    name: SimpleIdentifier
      token: new
      staticElement: ConstructorMember
        base: <testLibraryFragment>::@class::A::@constructor::new
        substitution: {T: int}
      element: <testLibraryFragment>::@class::A::@constructor::new#element
      staticType: null
    staticElement: ConstructorMember
      base: <testLibraryFragment>::@class::A::@constructor::new
      substitution: {T: int}
    element: <testLibraryFragment>::@class::A::@constructor::new#element
  staticType: A<int> Function()
''');
  }

  test_alias_generic_with_inferred_type_parameter() async {
    await assertErrorsInCode('''
class C<T> {
  final T x;
  C(this.x);
}
typedef Direct<T> = C<T>;
void main() {
  var x = const <C<int> Function(int)>[Direct.new];
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 87, 1),
    ]);
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

    var node = findNode.constructorReference('TA<int>.new;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: TA
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::<fragment>::@class::int
            element2: dart:core::<fragment>::@class::int#element
            type: int
        rightBracket: >
      element: <testLibraryFragment>::@typeAlias::TA
      element2: <testLibraryFragment>::@typeAlias::TA#element
      type: null
    period: .
    name: SimpleIdentifier
      token: new
      staticElement: ConstructorMember
        base: <testLibraryFragment>::@class::A::@constructor::new
        substitution: {T: int}
      element: <testLibraryFragment>::@class::A::@constructor::new#element
      staticType: null
    staticElement: ConstructorMember
      base: <testLibraryFragment>::@class::A::@constructor::new
      substitution: {T: int}
    element: <testLibraryFragment>::@class::A::@constructor::new#element
  staticType: A<int> Function()
''');
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

    var node = findNode.constructorReference('TA<String>.new;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: TA
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: String
            element: dart:core::<fragment>::@class::String
            element2: dart:core::<fragment>::@class::String#element
            type: String
        rightBracket: >
      element: <testLibraryFragment>::@typeAlias::TA
      element2: <testLibraryFragment>::@typeAlias::TA#element
      type: null
    period: .
    name: SimpleIdentifier
      token: new
      staticElement: ConstructorMember
        base: <testLibraryFragment>::@class::A::@constructor::new
        substitution: {T: String}
      element: <testLibraryFragment>::@class::A::@constructor::new#element
      staticType: null
    staticElement: ConstructorMember
      base: <testLibraryFragment>::@class::A::@constructor::new
      substitution: {T: String}
    element: <testLibraryFragment>::@class::A::@constructor::new#element
  staticType: A<String> Function()
''');
  }

  test_class_generic_const() async {
    await assertNoErrorsInCode('''
class A<T> {
  const A();
}

const a = A<int>.new;
''');

    var node = findNode.constructorReference('A<int>.new;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::<fragment>::@class::int
            element2: dart:core::<fragment>::@class::int#element
            type: int
        rightBracket: >
      element: <testLibraryFragment>::@class::A
      element2: <testLibraryFragment>::@class::A#element
      type: null
    period: .
    name: SimpleIdentifier
      token: new
      staticElement: ConstructorMember
        base: <testLibraryFragment>::@class::A::@constructor::new
        substitution: {T: int}
      element: <testLibraryFragment>::@class::A::@constructor::new#element
      staticType: null
    staticElement: ConstructorMember
      base: <testLibraryFragment>::@class::A::@constructor::new
      substitution: {T: int}
    element: <testLibraryFragment>::@class::A::@constructor::new#element
  staticType: A<int> Function()
''');
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

    var node = findNode.constructorReference('A<int>.foo;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::<fragment>::@class::int
            element2: dart:core::<fragment>::@class::int#element
            type: int
        rightBracket: >
      element: <testLibraryFragment>::@class::A
      element2: <testLibraryFragment>::@class::A#element
      type: null
    period: .
    name: SimpleIdentifier
      token: foo
      staticElement: ConstructorMember
        base: <testLibraryFragment>::@class::A::@constructor::foo
        substitution: {T: int}
      element: <testLibraryFragment>::@class::A::@constructor::foo#element
      staticType: null
    staticElement: ConstructorMember
      base: <testLibraryFragment>::@class::A::@constructor::foo
      substitution: {T: int}
    element: <testLibraryFragment>::@class::A::@constructor::foo#element
  staticType: A<int> Function()
''');
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
      error(CompileTimeErrorCode.UNDEFINED_OPERATOR, 43, 1),
      error(ParserErrorCode.EQUALITY_CANNOT_BE_EQUALITY_OPERAND, 47, 1),
      error(ParserErrorCode.MISSING_IDENTIFIER, 48, 2),
    ]);
    // The parser produces nonsense here because the `<` disambiguates as a
    // relational operator, so no need to assert anything about analysis
    // results.
  }

  test_class_generic_named_nullAware() async {
    await assertErrorsInCode('''
class A<T> {
  A.foo();
}

void bar() {
  A<int>?.foo;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_OPERATOR, 43, 1),
      error(ParserErrorCode.EQUALITY_CANNOT_BE_EQUALITY_OPERAND, 47, 1),
      error(ParserErrorCode.MISSING_IDENTIFIER, 48, 2),
    ]);
    // The parser produces nonsense here because the `<` disambiguates as a
    // relational operator, so no need to assert anything about analysis
    // results.
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
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR, 52,
          5,
          messageContains: ["The constructor 'A.foo'"]),
    ]);

    var node = findNode.constructorReference('A<int>.foo<int>;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::<fragment>::@class::int
            element2: dart:core::<fragment>::@class::int#element
            type: int
        rightBracket: >
      element: <testLibraryFragment>::@class::A
      element2: <testLibraryFragment>::@class::A#element
      type: null
    period: .
    name: SimpleIdentifier
      token: foo
      staticElement: ConstructorMember
        base: <testLibraryFragment>::@class::A::@constructor::foo
        substitution: {T: int}
      element: <testLibraryFragment>::@class::A::@constructor::foo#element
      staticType: null
    staticElement: ConstructorMember
      base: <testLibraryFragment>::@class::A::@constructor::foo
      substitution: {T: int}
    element: <testLibraryFragment>::@class::A::@constructor::foo#element
  staticType: A<int> Function()
''');
  }

  test_class_generic_new_typeArgs() async {
    await assertErrorsInCode('''
class A<T> {
  A.new();
}

void bar() {
  A<int>.new<int>;
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR, 52,
          5,
          messageContains: ["The constructor 'A.new'"]),
    ]);

    var node = findNode.constructorReference('A<int>.new<int>;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::<fragment>::@class::int
            element2: dart:core::<fragment>::@class::int#element
            type: int
        rightBracket: >
      element: <testLibraryFragment>::@class::A
      element2: <testLibraryFragment>::@class::A#element
      type: null
    period: .
    name: SimpleIdentifier
      token: new
      staticElement: ConstructorMember
        base: <testLibraryFragment>::@class::A::@constructor::new
        substitution: {T: int}
      element: <testLibraryFragment>::@class::A::@constructor::new#element
      staticType: null
    staticElement: ConstructorMember
      base: <testLibraryFragment>::@class::A::@constructor::new
      substitution: {T: int}
    element: <testLibraryFragment>::@class::A::@constructor::new#element
  staticType: A<int> Function()
''');
  }

  test_class_generic_nonConstructor() async {
    await assertErrorsInCode('''
class A<T> {
  static int i = 1;
}

void bar() {
  A<int>.i;
}
''', [
      error(CompileTimeErrorCode.CLASS_INSTANTIATION_ACCESS_TO_STATIC_MEMBER,
          51, 8),
    ]);

    var node = findNode.constructorReference('A<int>.i;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::<fragment>::@class::int
            element2: dart:core::<fragment>::@class::int#element
            type: int
        rightBracket: >
      element: <testLibraryFragment>::@class::A
      element2: <testLibraryFragment>::@class::A#element
      type: null
    period: .
    name: SimpleIdentifier
      token: i
      staticElement: <null>
      element: <null>
      staticType: null
    staticElement: <null>
    element: <null>
  staticType: InvalidType
''');
  }

  test_class_generic_nothing_hasNamedConstructor() async {
    await assertErrorsInCode('''
class A<T> {
  A.foo();
}

void bar() {
  A<int>.;
}
''', [
      error(ParserErrorCode.MISSING_IDENTIFIER, 49, 1),
    ]);

    var node = findNode.constructorReference('A<int>.;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::<fragment>::@class::int
            element2: dart:core::<fragment>::@class::int#element
            type: int
        rightBracket: >
      element: <testLibraryFragment>::@class::A
      element2: <testLibraryFragment>::@class::A#element
      type: null
    period: .
    name: SimpleIdentifier
      token: <empty> <synthetic>
      staticElement: <null>
      element: <null>
      staticType: null
    staticElement: <null>
    element: <null>
  staticType: InvalidType
''');
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

    var node = findNode.constructorReference('A<int>.new;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::<fragment>::@class::int
            element2: dart:core::<fragment>::@class::int#element
            type: int
        rightBracket: >
      element: <testLibraryFragment>::@class::A
      element2: <testLibraryFragment>::@class::A#element
      type: null
    period: .
    name: SimpleIdentifier
      token: new
      staticElement: ConstructorMember
        base: <testLibraryFragment>::@class::A::@constructor::new
        substitution: {T: int}
      element: <testLibraryFragment>::@class::A::@constructor::new#element
      staticType: null
    staticElement: ConstructorMember
      base: <testLibraryFragment>::@class::A::@constructor::new
      substitution: {T: int}
    element: <testLibraryFragment>::@class::A::@constructor::new#element
  staticType: A<int> Function()
''');
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

    var node = findNode.constructorReference('A<int>.new');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::<fragment>::@class::int
            element2: dart:core::<fragment>::@class::int#element
            type: int
        rightBracket: >
      element: <testLibraryFragment>::@class::A
      element2: <testLibraryFragment>::@class::A#element
      type: null
    period: .
    name: SimpleIdentifier
      token: new
      staticElement: ConstructorMember
        base: <testLibraryFragment>::@class::A::@constructor::new
        substitution: {T: int}
      element: <testLibraryFragment>::@class::A::@constructor::new#element
      staticType: null
    staticElement: ConstructorMember
      base: <testLibraryFragment>::@class::A::@constructor::new
      substitution: {T: int}
    element: <testLibraryFragment>::@class::A::@constructor::new#element
  staticType: A<int> Function()
''');
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

    var node = findNode.constructorReference('A<int>.new;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::<fragment>::@class::int
            element2: dart:core::<fragment>::@class::int#element
            type: int
        rightBracket: >
      element: <testLibraryFragment>::@class::A
      element2: <testLibraryFragment>::@class::A#element
      type: null
    period: .
    name: SimpleIdentifier
      token: new
      staticElement: ConstructorMember
        base: <testLibraryFragment>::@class::A::@constructor::new
        substitution: {T: int}
      element: <testLibraryFragment>::@class::A::@constructor::new#element
      staticType: null
    staticElement: ConstructorMember
      base: <testLibraryFragment>::@class::A::@constructor::new
      substitution: {T: int}
    element: <testLibraryFragment>::@class::A::@constructor::new#element
  staticType: A<int> Function()
''');
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

    var node = findNode.constructorReference('A<String>.new;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: String
            element: dart:core::<fragment>::@class::String
            element2: dart:core::<fragment>::@class::String#element
            type: String
        rightBracket: >
      element: <testLibraryFragment>::@class::A
      element2: <testLibraryFragment>::@class::A#element
      type: null
    period: .
    name: SimpleIdentifier
      token: new
      staticElement: ConstructorMember
        base: <testLibraryFragment>::@class::A::@constructor::new
        substitution: {T: String}
      element: <testLibraryFragment>::@class::A::@constructor::new#element
      staticType: null
    staticElement: ConstructorMember
      base: <testLibraryFragment>::@class::A::@constructor::new
      substitution: {T: String}
    element: <testLibraryFragment>::@class::A::@constructor::new#element
  staticType: A<String> Function()
''');
  }

  test_prefixedAlias_generic_unnamed() async {
    newFile('$testPackageLibPath/a.dart', '''
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

    var node = findNode.constructorReference('a.TA<int>.new;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: a
        period: .
        element: <testLibraryFragment>::@prefix::a
        element2: <testLibraryFragment>::@prefix2::a
      name: TA
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::<fragment>::@class::int
            element2: dart:core::<fragment>::@class::int#element
            type: int
        rightBracket: >
      element: package:test/a.dart::<fragment>::@typeAlias::TA
      element2: package:test/a.dart::<fragment>::@typeAlias::TA#element
      type: null
    period: .
    name: SimpleIdentifier
      token: new
      staticElement: ConstructorMember
        base: package:test/a.dart::<fragment>::@class::A::@constructor::new
        substitution: {T: int}
      element: package:test/a.dart::<fragment>::@class::A::@constructor::new#element
      staticType: null
    staticElement: ConstructorMember
      base: package:test/a.dart::<fragment>::@class::A::@constructor::new
      substitution: {T: int}
    element: package:test/a.dart::<fragment>::@class::A::@constructor::new#element
  staticType: A<int> Function()
''');
  }

  test_prefixedClass_generic_named() async {
    newFile('$testPackageLibPath/a.dart', '''
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

    var node = findNode.constructorReference('a.A<int>.foo;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: a
        period: .
        element: <testLibraryFragment>::@prefix::a
        element2: <testLibraryFragment>::@prefix2::a
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::<fragment>::@class::int
            element2: dart:core::<fragment>::@class::int#element
            type: int
        rightBracket: >
      element: package:test/a.dart::<fragment>::@class::A
      element2: package:test/a.dart::<fragment>::@class::A#element
      type: null
    period: .
    name: SimpleIdentifier
      token: foo
      staticElement: ConstructorMember
        base: package:test/a.dart::<fragment>::@class::A::@constructor::foo
        substitution: {T: int}
      element: package:test/a.dart::<fragment>::@class::A::@constructor::foo#element
      staticType: null
    staticElement: ConstructorMember
      base: package:test/a.dart::<fragment>::@class::A::@constructor::foo
      substitution: {T: int}
    element: package:test/a.dart::<fragment>::@class::A::@constructor::foo#element
  staticType: A<int> Function()
''');
  }

  test_prefixedClass_generic_targetOfFunctionCall() async {
    newFile('$testPackageLibPath/a.dart', '''
class A<T> {
  A();
}
''');
    await assertNoErrorsInCode('''
import 'a.dart' as a;
extension on Function {
  void m() {}
}
void bar() {
  a.A<int>.new.m();
}
''');

    var node = findNode.constructorReference('a.A<int>.new');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: a
        period: .
        element: <testLibraryFragment>::@prefix::a
        element2: <testLibraryFragment>::@prefix2::a
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::<fragment>::@class::int
            element2: dart:core::<fragment>::@class::int#element
            type: int
        rightBracket: >
      element: package:test/a.dart::<fragment>::@class::A
      element2: package:test/a.dart::<fragment>::@class::A#element
      type: null
    period: .
    name: SimpleIdentifier
      token: new
      staticElement: ConstructorMember
        base: package:test/a.dart::<fragment>::@class::A::@constructor::new
        substitution: {T: int}
      element: package:test/a.dart::<fragment>::@class::A::@constructor::new#element
      staticType: null
    staticElement: ConstructorMember
      base: package:test/a.dart::<fragment>::@class::A::@constructor::new
      substitution: {T: int}
    element: package:test/a.dart::<fragment>::@class::A::@constructor::new#element
  staticType: A<int> Function()
''');
  }

  test_prefixedClass_generic_unnamed() async {
    newFile('$testPackageLibPath/a.dart', '''
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

    var node = findNode.constructorReference('a.A<int>.new;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: a
        period: .
        element: <testLibraryFragment>::@prefix::a
        element2: <testLibraryFragment>::@prefix2::a
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::<fragment>::@class::int
            element2: dart:core::<fragment>::@class::int#element
            type: int
        rightBracket: >
      element: package:test/a.dart::<fragment>::@class::A
      element2: package:test/a.dart::<fragment>::@class::A#element
      type: null
    period: .
    name: SimpleIdentifier
      token: new
      staticElement: ConstructorMember
        base: package:test/a.dart::<fragment>::@class::A::@constructor::new
        substitution: {T: int}
      element: package:test/a.dart::<fragment>::@class::A::@constructor::new#element
      staticType: null
    staticElement: ConstructorMember
      base: package:test/a.dart::<fragment>::@class::A::@constructor::new
      substitution: {T: int}
    element: package:test/a.dart::<fragment>::@class::A::@constructor::new#element
  staticType: A<int> Function()
''');
  }
}

@reflectiveTest
class ConstructorReferenceResolutionTest_WithoutConstructorTearoffs
    extends PubPackageResolutionTest with WithoutConstructorTearoffsMixin {
  test_class_generic_nonConstructor() async {
    await assertErrorsInCode('''
class A<T> {
  static int i = 1;
}

void bar() {
  A<int>.i;
}
''', [
      error(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 52, 5),
    ]);

    var node = findNode.constructorReference('A<int>.i;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::<fragment>::@class::int
            element2: dart:core::<fragment>::@class::int#element
            type: int
        rightBracket: >
      element: <testLibraryFragment>::@class::A
      element2: <testLibraryFragment>::@class::A#element
      type: null
    period: .
    name: SimpleIdentifier
      token: i
      staticElement: <null>
      element: <null>
      staticType: null
    staticElement: <null>
    element: <null>
  staticType: InvalidType
''');
  }

  test_constructorTearoff() async {
    await assertErrorsInCode('''
class A {
  A.foo();
}

void bar() {
  A.foo;
}
''', [
      error(WarningCode.SDK_VERSION_CONSTRUCTOR_TEAROFFS, 39, 5),
    ]);

    var node = findNode.constructorReference('A.foo;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: A
      element: <testLibraryFragment>::@class::A
      element2: <testLibraryFragment>::@class::A#element
      type: null
    period: .
    name: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@class::A::@constructor::foo
      element: <testLibraryFragment>::@class::A::@constructor::foo#element
      staticType: null
    staticElement: <testLibraryFragment>::@class::A::@constructor::foo
    element: <testLibraryFragment>::@class::A::@constructor::foo#element
  staticType: A Function()
''');
  }
}
