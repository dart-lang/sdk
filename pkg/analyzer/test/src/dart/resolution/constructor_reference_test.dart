// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstructorReferenceResolutionTest);
    defineReflectiveTests(ConstructorReferenceResolutionTest_TypeArgs);
    defineReflectiveTests(
      ConstructorReferenceResolutionTest_WithoutConstructorTearoffs,
    );
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ConstructorReferenceResolutionTest extends PubPackageResolutionTest {
  test_abstractClass_factory() async {
    var result = await resolveTestCodeWithDiagnostics('''
abstract class A {
  factory A() => A2();
}

class A2 implements A {}

foo() {
  A.new;
}
''');

    var node = result.findNode.constructorReference('A.new;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: A
      element: <testLibrary>::@class::A
      type: null
    period: .
    name: SimpleIdentifier
      token: new
      element: <testLibrary>::@class::A::@constructor::new
      staticType: null
    element: <testLibrary>::@class::A::@constructor::new
  staticType: A Function()
''');
  }

  test_abstractClass_generative() async {
    var result = await resolveTestCodeWithDiagnostics('''
abstract class A {
  A();
}

foo() {
  A.new;
//^^^^^
// [diag.tearoffOfGenerativeConstructorOfAbstractClass] A generative constructor of an abstract class can't be torn off.
}
''');

    var node = result.findNode.constructorReference('A.new;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: A
      element: <testLibrary>::@class::A
      type: null
    period: .
    name: SimpleIdentifier
      token: new
      element: <testLibrary>::@class::A::@constructor::new
      staticType: null
    element: <testLibrary>::@class::A::@constructor::new
  staticType: A Function()
''');
  }

  test_abstractClass_redirecting() async {
    var result = await resolveTestCodeWithDiagnostics('''
abstract class A {
  A(): this.two();

  A.two();
}

foo() {
  A.new;
//^^^^^
// [diag.tearoffOfGenerativeConstructorOfAbstractClass] A generative constructor of an abstract class can't be torn off.
}
''');

    var node = result.findNode.constructorReference('A.new;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: A
      element: <testLibrary>::@class::A
      type: null
    period: .
    name: SimpleIdentifier
      token: new
      element: <testLibrary>::@class::A::@constructor::new
      staticType: null
    element: <testLibrary>::@class::A::@constructor::new
  staticType: A Function()
''');
  }

  test_class_generic_inferFromContext_badTypeArgument() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A<T extends num> {
  A.foo();
}

A<String> Function() bar() {
// [context 1][column 1][length 9] The inverted type 'A<String>' is also not regular-bounded, so the type is not well-bounded.
//^^^^^^
// [diag.typeArgumentNotMatchingBounds][context 1] 'String' doesn't conform to the bound 'num' of the type parameter 'T'.
  return A.foo;
}
''');

    var node = result.findNode.constructorReference('A.foo;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: A
      element: <testLibrary>::@class::A
      type: null
    period: .
    name: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@constructor::foo
      staticType: null
      tearOffTypeArgumentTypes
        Never
    element: <testLibrary>::@class::A::@constructor::foo
  staticType: A<Never> Function()
''');
  }

  test_class_generic_named_inferTypeFromContext() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A<T> {
  A.foo();
}

A<int> Function() bar() {
  return A.foo;
}
''');

    var node = result.findNode.constructorReference('A.foo;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: A
      element: <testLibrary>::@class::A
      type: null
    period: .
    name: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@constructor::foo
      staticType: null
      tearOffTypeArgumentTypes
        int
    element: <testLibrary>::@class::A::@constructor::foo
  staticType: A<int> Function()
''');
  }

  test_class_generic_named_uninstantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A<T> {
  A.foo();
}

void bar() {
  A.foo;
}
''');

    var node = result.findNode.constructorReference('A.foo;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: A
      element: <testLibrary>::@class::A
      type: null
    period: .
    name: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@constructor::foo
      staticType: null
    element: <testLibrary>::@class::A::@constructor::foo
  staticType: A<T> Function<T>()
''');
  }

  test_class_generic_named_uninstantiated_bound() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A<T extends num> {
  A.foo();
}

void bar() {
  A.foo;
}
''');

    var node = result.findNode.constructorReference('A.foo;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: A
      element: <testLibrary>::@class::A
      type: null
    period: .
    name: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@constructor::foo
      staticType: null
    element: <testLibrary>::@class::A::@constructor::foo
  staticType: A<T> Function<T extends num>()
''');
  }

  test_class_nonGeneric_const() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  const A();
}

const a1 = A.new;
''');

    var node = result.findNode.constructorReference('A.new;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: A
      element: <testLibrary>::@class::A
      type: null
    period: .
    name: SimpleIdentifier
      token: new
      element: <testLibrary>::@class::A::@constructor::new
      staticType: null
    element: <testLibrary>::@class::A::@constructor::new
  staticType: A Function()
''');
  }

  test_class_nonGeneric_named() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  A.foo();
}

void bar() {
  A.foo;
}
''');

    var node = result.findNode.constructorReference('A.foo;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: A
      element: <testLibrary>::@class::A
      type: null
    period: .
    name: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@constructor::foo
      staticType: null
    element: <testLibrary>::@class::A::@constructor::foo
  staticType: A Function()
''');
  }

  test_class_nonGeneric_unnamed() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  A();
}

bar() {
  A.new;
}
''');

    var node = result.findNode.constructorReference('A.new;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: A
      element: <testLibrary>::@class::A
      type: null
    period: .
    name: SimpleIdentifier
      token: new
      element: <testLibrary>::@class::A::@constructor::new
      staticType: null
    element: <testLibrary>::@class::A::@constructor::new
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
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
bar() {
  a.TA.foo;
}
''');

    var node = result.findNode.constructorReference('a.TA.foo;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: a
        period: .
        element: <testLibraryFragment>::@prefix::a
      name: TA
      element: package:test/a.dart::@typeAlias::TA
      type: null
    period: .
    name: SimpleIdentifier
      token: foo
      element: package:test/a.dart::@class::A::@constructor::foo
      staticType: null
    element: package:test/a.dart::@class::A::@constructor::foo
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
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
bar() {
  a.TA.new;
}
''');

    var node = result.findNode.constructorReference('a.TA.new;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: a
        period: .
        element: <testLibraryFragment>::@prefix::a
      name: TA
      element: package:test/a.dart::@typeAlias::TA
      type: null
    period: .
    name: SimpleIdentifier
      token: new
      element: package:test/a.dart::@class::A::@constructor::new
      staticType: null
    element: package:test/a.dart::@class::A::@constructor::new
  staticType: A Function()
''');
  }

  test_prefixedClass_nonGeneric_named() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {
  A.foo();
}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
bar() {
  a.A.foo;
}
''');

    var node = result.findNode.constructorReference('a.A.foo;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: a
        period: .
        element: <testLibraryFragment>::@prefix::a
      name: A
      element: package:test/a.dart::@class::A
      type: null
    period: .
    name: SimpleIdentifier
      token: foo
      element: package:test/a.dart::@class::A::@constructor::foo
      staticType: null
    element: package:test/a.dart::@class::A::@constructor::foo
  staticType: A Function()
''');
  }

  test_prefixedClass_nonGeneric_unnamed() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {
  A();
}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
bar() {
  a.A.new;
}
''');

    var node = result.findNode.constructorReference('a.A.new;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: a
        period: .
        element: <testLibraryFragment>::@prefix::a
      name: A
      element: package:test/a.dart::@class::A
      type: null
    period: .
    name: SimpleIdentifier
      token: new
      element: package:test/a.dart::@class::A::@constructor::new
      staticType: null
    element: package:test/a.dart::@class::A::@constructor::new
  staticType: A Function()
''');
  }

  test_typeAlias_generic_const() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A<T> {
  const A();
}
typedef TA<T> = A<T>;

const a = TA.new;
''');

    var node = result.findNode.constructorReference('TA.new;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: TA
      element: <testLibrary>::@typeAlias::TA
      type: null
    period: .
    name: SimpleIdentifier
      token: new
      element: <testLibrary>::@class::A::@constructor::new
      staticType: null
    element: <testLibrary>::@class::A::@constructor::new
  staticType: A<T> Function<T>()
''');
  }

  test_typeAlias_generic_named_uninstantiated() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A<T, U> {
  A.foo();
}
typedef TA<U> = A<String, U>;

bar() {
  TA.foo;
}
''');

    var node = result.findNode.constructorReference('TA.foo;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: TA
      element: <testLibrary>::@typeAlias::TA
      type: null
    period: .
    name: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@constructor::foo
      staticType: null
    element: <testLibrary>::@class::A::@constructor::foo
  staticType: A<String, U> Function<U>()
''');
  }

  test_typeAlias_instantiated_const() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A<T> {
  const A();
}
typedef TA = A<int>;

const a = TA.new;
''');

    var node = result.findNode.constructorReference('TA.new;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: TA
      element: <testLibrary>::@typeAlias::TA
      type: null
    period: .
    name: SimpleIdentifier
      token: new
      element: SubstitutedConstructorElementImpl
        baseElement: <testLibrary>::@class::A::@constructor::new
        substitution: {T: int}
      staticType: null
    element: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::new
      substitution: {T: int}
  staticType: A<int> Function()
''');
  }

  test_typeAlias_instantiated_named() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A<T> {
  A.foo();
}
typedef TA = A<int>;

bar() {
  TA.foo;
}
''');

    var node = result.findNode.constructorReference('TA.foo;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: TA
      element: <testLibrary>::@typeAlias::TA
      type: null
    period: .
    name: SimpleIdentifier
      token: foo
      element: SubstitutedConstructorElementImpl
        baseElement: <testLibrary>::@class::A::@constructor::foo
        substitution: {T: int}
      staticType: null
    element: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::foo
      substitution: {T: int}
  staticType: A<int> Function()
''');
  }
}

@reflectiveTest
class ConstructorReferenceResolutionTest_TypeArgs
    extends PubPackageResolutionTest {
  test_alias_generic_const() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A<T, U> {
  const A.foo();
}
typedef TA<T, U> = A<U, T>;

const a = TA<int, String>.foo;
''');

    var node = result.findNode.constructorReference('TA<int, String>.foo;');
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
            element: dart:core::@class::int
            type: int
          NamedType
            name: String
            element: dart:core::@class::String
            type: String
        rightBracket: >
      element: <testLibrary>::@typeAlias::TA
      type: null
    period: .
    name: SimpleIdentifier
      token: foo
      element: SubstitutedConstructorElementImpl
        baseElement: <testLibrary>::@class::A::@constructor::foo
        substitution: {T: String, U: int}
      staticType: null
    element: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::foo
      substitution: {T: String, U: int}
  staticType: A<String, int> Function()
''');
  }

  test_alias_generic_const_differingNumberOfTypeParameters() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A<T, U> {
  A.foo() {}
}
typedef TA<T> = A<T, String>;

const x = TA<int>.foo;
''');

    var node = result.findNode.constructorReference('TA<int>.foo;');
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
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::TA
      type: null
    period: .
    name: SimpleIdentifier
      token: foo
      element: SubstitutedConstructorElementImpl
        baseElement: <testLibrary>::@class::A::@constructor::foo
        substitution: {T: int, U: String}
      staticType: null
    element: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::foo
      substitution: {T: int, U: String}
  staticType: A<int, String> Function()
''');
  }

  test_alias_generic_named() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A<T, U> {
  A.foo();
}
typedef TA<T, U> = A<U, T>;

void bar() {
  TA<int, String>.foo;
}
''');

    var node = result.findNode.constructorReference('TA<int, String>.foo;');
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
            element: dart:core::@class::int
            type: int
          NamedType
            name: String
            element: dart:core::@class::String
            type: String
        rightBracket: >
      element: <testLibrary>::@typeAlias::TA
      type: null
    period: .
    name: SimpleIdentifier
      token: foo
      element: SubstitutedConstructorElementImpl
        baseElement: <testLibrary>::@class::A::@constructor::foo
        substitution: {T: String, U: int}
      staticType: null
    element: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::foo
      substitution: {T: String, U: int}
  staticType: A<String, int> Function()
''');
  }

  test_alias_generic_uninstantiated_const() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A<T, U> {
  const A.foo();
}
typedef TA<T, U> = A<U, T>;

const a = TA.foo;
''');

    var node = result.findNode.constructorReference('TA.foo;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: TA
      element: <testLibrary>::@typeAlias::TA
      type: null
    period: .
    name: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@constructor::foo
      staticType: null
    element: <testLibrary>::@class::A::@constructor::foo
  staticType: A<U, T> Function<T, U>()
''');
  }

  test_alias_generic_unnamed() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A<T> {
  A();
}
typedef TA<T> = A<T>;

void bar() {
  TA<int>.new;
}
''');

    var node = result.findNode.constructorReference('TA<int>.new;');
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
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::TA
      type: null
    period: .
    name: SimpleIdentifier
      token: new
      element: SubstitutedConstructorElementImpl
        baseElement: <testLibrary>::@class::A::@constructor::new
        substitution: {T: int}
      staticType: null
    element: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::new
      substitution: {T: int}
  staticType: A<int> Function()
''');
  }

  test_alias_generic_with_inferred_type_parameter() async {
    await resolveTestCodeWithDiagnostics('''
class C<T> {
  final T x;
  C(this.x);
}
typedef Direct<T> = C<T>;
void main() {
  var x = const <C<int> Function(int)>[Direct.new];
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
}
''');
  }

  test_alias_genericWithBound_unnamed() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A<T> {
  A();
}
typedef TA<T extends num> = A<T>;

void bar() {
  TA<int>.new;
}
''');

    var node = result.findNode.constructorReference('TA<int>.new;');
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
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::TA
      type: null
    period: .
    name: SimpleIdentifier
      token: new
      element: SubstitutedConstructorElementImpl
        baseElement: <testLibrary>::@class::A::@constructor::new
        substitution: {T: int}
      staticType: null
    element: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::new
      substitution: {T: int}
  staticType: A<int> Function()
''');
  }

  test_alias_genericWithBound_unnamed_badBound() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A<T> {
  A();
}
typedef TA<T extends num> = A<T>;

void bar() {
  TA<String>.new;
//   ^^^^^^
// [diag.typeArgumentNotMatchingBounds] 'String' doesn't conform to the bound 'num' of the type parameter 'T'.
}
''');

    var node = result.findNode.constructorReference('TA<String>.new;');
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
            element: dart:core::@class::String
            type: String
        rightBracket: >
      element: <testLibrary>::@typeAlias::TA
      type: null
    period: .
    name: SimpleIdentifier
      token: new
      element: SubstitutedConstructorElementImpl
        baseElement: <testLibrary>::@class::A::@constructor::new
        substitution: {T: String}
      staticType: null
    element: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::new
      substitution: {T: String}
  staticType: A<String> Function()
''');
  }

  test_class_generic_const() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A<T> {
  const A();
}

const a = A<int>.new;
''');

    var node = result.findNode.constructorReference('A<int>.new;');
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
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@class::A
      type: null
    period: .
    name: SimpleIdentifier
      token: new
      element: SubstitutedConstructorElementImpl
        baseElement: <testLibrary>::@class::A::@constructor::new
        substitution: {T: int}
      staticType: null
    element: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::new
      substitution: {T: int}
  staticType: A<int> Function()
''');
  }

  test_class_generic_named() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A<T> {
  A.foo();
}

void bar() {
  A<int>.foo;
}
''');

    var node = result.findNode.constructorReference('A<int>.foo;');
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
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@class::A
      type: null
    period: .
    name: SimpleIdentifier
      token: foo
      element: SubstitutedConstructorElementImpl
        baseElement: <testLibrary>::@class::A::@constructor::foo
        substitution: {T: int}
      staticType: null
    element: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::foo
      substitution: {T: int}
  staticType: A<int> Function()
''');
  }

  test_class_generic_named_cascade() async {
    await resolveTestCodeWithDiagnostics('''
class A<T> {
  A.foo();
}

void bar() {
  A<int>..foo;
// ^
// [diag.undefinedOperator] The operator '<' isn't defined for the type 'Type'.
//     ^
// [diag.equalityCannotBeEqualityOperand] A comparison expression can't be an operand of another comparison expression.
//      ^^
// [diag.missingIdentifier] Expected an identifier.
}
''');
    // The parser produces nonsense here because the `<` disambiguates as a
    // relational operator, so no need to assert anything about analysis
    // results.
  }

  test_class_generic_named_nullAware() async {
    await resolveTestCodeWithDiagnostics('''
class A<T> {
  A.foo();
}

void bar() {
  A<int>?.foo;
// ^
// [diag.undefinedOperator] The operator '<' isn't defined for the type 'Type'.
//     ^
// [diag.equalityCannotBeEqualityOperand] A comparison expression can't be an operand of another comparison expression.
//      ^^
// [diag.missingIdentifier] Expected an identifier.
}
''');
    // The parser produces nonsense here because the `<` disambiguates as a
    // relational operator, so no need to assert anything about analysis
    // results.
  }

  test_class_generic_named_typeArgs() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A<T> {
  A.foo();
}

void bar() {
  A<int>.foo<int>;
//          ^^^^^
// [diag.wrongNumberOfTypeArgumentsConstructor] The constructor 'A.foo' doesn't have type parameters.
}
''');

    var node = result.findNode.constructorReference('A<int>.foo<int>;');
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
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@class::A
      type: null
    period: .
    name: SimpleIdentifier
      token: foo
      element: SubstitutedConstructorElementImpl
        baseElement: <testLibrary>::@class::A::@constructor::foo
        substitution: {T: int}
      staticType: null
    element: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::foo
      substitution: {T: int}
  staticType: A<int> Function()
''');
  }

  test_class_generic_new_typeArgs() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A<T> {
  A.new();
}

void bar() {
  A<int>.new<int>;
//          ^^^^^
// [diag.wrongNumberOfTypeArgumentsConstructor] The constructor 'A.new' doesn't have type parameters.
}
''');

    var node = result.findNode.constructorReference('A<int>.new<int>;');
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
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@class::A
      type: null
    period: .
    name: SimpleIdentifier
      token: new
      element: SubstitutedConstructorElementImpl
        baseElement: <testLibrary>::@class::A::@constructor::new
        substitution: {T: int}
      staticType: null
    element: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::new
      substitution: {T: int}
  staticType: A<int> Function()
''');
  }

  test_class_generic_nonConstructor() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A<T> {
  static int i = 1;
}

void bar() {
  A<int>.i;
//^^^^^^^^
// [diag.classInstantiationAccessToStaticMember] The static member 'i' can't be accessed on a class instantiation.
}
''');

    var node = result.findNode.constructorReference('A<int>.i;');
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
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@class::A
      type: null
    period: .
    name: SimpleIdentifier
      token: i
      element: <null>
      staticType: null
    element: <null>
  staticType: InvalidType
''');
  }

  test_class_generic_nothing_hasNamedConstructor() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A<T> {
  A.foo();
}

void bar() {
  A<int>.;
//       ^
// [diag.missingIdentifier] Expected an identifier.
}
''');

    var node = result.findNode.constructorReference('A<int>.;');
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
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@class::A
      type: null
    period: .
    name: SimpleIdentifier
      token: <empty> <synthetic>
      element: <null>
      staticType: null
    element: <null>
  staticType: InvalidType
''');
  }

  test_class_generic_unnamed() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A<T> {
  A();
}

void bar() {
  A<int>.new;
}
''');

    var node = result.findNode.constructorReference('A<int>.new;');
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
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@class::A
      type: null
    period: .
    name: SimpleIdentifier
      token: new
      element: SubstitutedConstructorElementImpl
        baseElement: <testLibrary>::@class::A::@constructor::new
        substitution: {T: int}
      staticType: null
    element: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::new
      substitution: {T: int}
  staticType: A<int> Function()
''');
  }

  test_class_generic_unnamed_partOfPropertyAccess() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A<T> {
  A();
}

void bar() {
  A<int>.new.runtimeType;
}
''');

    var node = result.findNode.constructorReference('A<int>.new');
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
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@class::A
      type: null
    period: .
    name: SimpleIdentifier
      token: new
      element: SubstitutedConstructorElementImpl
        baseElement: <testLibrary>::@class::A::@constructor::new
        substitution: {T: int}
      staticType: null
    element: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::new
      substitution: {T: int}
  staticType: A<int> Function()
''');
  }

  test_class_genericWithBound_unnamed() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A<T extends num> {
  A();
}

void bar() {
  A<int>.new;
}
''');

    var node = result.findNode.constructorReference('A<int>.new;');
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
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@class::A
      type: null
    period: .
    name: SimpleIdentifier
      token: new
      element: SubstitutedConstructorElementImpl
        baseElement: <testLibrary>::@class::A::@constructor::new
        substitution: {T: int}
      staticType: null
    element: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::new
      substitution: {T: int}
  staticType: A<int> Function()
''');
  }

  test_class_genericWithBound_unnamed_badBound() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A<T extends num> {
  A();
}

void bar() {
  A<String>.new;
//  ^^^^^^
// [diag.typeArgumentNotMatchingBounds] 'String' doesn't conform to the bound 'num' of the type parameter 'T'.
}
''');

    var node = result.findNode.constructorReference('A<String>.new;');
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
            element: dart:core::@class::String
            type: String
        rightBracket: >
      element: <testLibrary>::@class::A
      type: null
    period: .
    name: SimpleIdentifier
      token: new
      element: SubstitutedConstructorElementImpl
        baseElement: <testLibrary>::@class::A::@constructor::new
        substitution: {T: String}
      staticType: null
    element: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::new
      substitution: {T: String}
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
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
void bar() {
  a.TA<int>.new;
}
''');

    var node = result.findNode.constructorReference('a.TA<int>.new;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: a
        period: .
        element: <testLibraryFragment>::@prefix::a
      name: TA
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: package:test/a.dart::@typeAlias::TA
      type: null
    period: .
    name: SimpleIdentifier
      token: new
      element: SubstitutedConstructorElementImpl
        baseElement: package:test/a.dart::@class::A::@constructor::new
        substitution: {T: int}
      staticType: null
    element: SubstitutedConstructorElementImpl
      baseElement: package:test/a.dart::@class::A::@constructor::new
      substitution: {T: int}
  staticType: A<int> Function()
''');
  }

  test_prefixedClass_generic_named() async {
    newFile('$testPackageLibPath/a.dart', '''
class A<T> {
  A.foo();
}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
void bar() {
  a.A<int>.foo;
}
''');

    var node = result.findNode.constructorReference('a.A<int>.foo;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: a
        period: .
        element: <testLibraryFragment>::@prefix::a
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: package:test/a.dart::@class::A
      type: null
    period: .
    name: SimpleIdentifier
      token: foo
      element: SubstitutedConstructorElementImpl
        baseElement: package:test/a.dart::@class::A::@constructor::foo
        substitution: {T: int}
      staticType: null
    element: SubstitutedConstructorElementImpl
      baseElement: package:test/a.dart::@class::A::@constructor::foo
      substitution: {T: int}
  staticType: A<int> Function()
''');
  }

  test_prefixedClass_generic_targetOfFunctionCall() async {
    newFile('$testPackageLibPath/a.dart', '''
class A<T> {
  A();
}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
extension on Function {
  void m() {}
}
void bar() {
  a.A<int>.new.m();
}
''');

    var node = result.findNode.constructorReference('a.A<int>.new');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: a
        period: .
        element: <testLibraryFragment>::@prefix::a
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: package:test/a.dart::@class::A
      type: null
    period: .
    name: SimpleIdentifier
      token: new
      element: SubstitutedConstructorElementImpl
        baseElement: package:test/a.dart::@class::A::@constructor::new
        substitution: {T: int}
      staticType: null
    element: SubstitutedConstructorElementImpl
      baseElement: package:test/a.dart::@class::A::@constructor::new
      substitution: {T: int}
  staticType: A<int> Function()
''');
  }

  test_prefixedClass_generic_unnamed() async {
    newFile('$testPackageLibPath/a.dart', '''
class A<T> {
  A();
}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;
void bar() {
  a.A<int>.new;
}
''');

    var node = result.findNode.constructorReference('a.A<int>.new;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: a
        period: .
        element: <testLibraryFragment>::@prefix::a
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: package:test/a.dart::@class::A
      type: null
    period: .
    name: SimpleIdentifier
      token: new
      element: SubstitutedConstructorElementImpl
        baseElement: package:test/a.dart::@class::A::@constructor::new
        substitution: {T: int}
      staticType: null
    element: SubstitutedConstructorElementImpl
      baseElement: package:test/a.dart::@class::A::@constructor::new
      substitution: {T: int}
  staticType: A<int> Function()
''');
  }
}

@reflectiveTest
class ConstructorReferenceResolutionTest_WithoutConstructorTearoffs
    extends PubPackageResolutionTest
    with WithoutConstructorTearoffsMixin {
  test_class_generic_nonConstructor() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A<T> {
  static int i = 1;
}

void bar() {
  A<int>.i;
// ^^^^^
// [diag.experimentNotEnabled] This requires the 'constructor-tearoffs' language feature to be enabled.
}
''');

    var node = result.findNode.constructorReference('A<int>.i;');
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
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@class::A
      type: null
    period: .
    name: SimpleIdentifier
      token: i
      element: <null>
      staticType: null
    element: <null>
  staticType: InvalidType
''');
  }

  test_constructorTearoff() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  A.foo();
}

void bar() {
  A.foo;
//^^^^^
// [diag.sdkVersionConstructorTearoffs] Tearing off a constructor requires the 'constructor-tearoffs' language feature.
}
''');

    var node = result.findNode.constructorReference('A.foo;');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: A
      element: <testLibrary>::@class::A
      type: null
    period: .
    name: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@constructor::foo
      staticType: null
    element: <testLibrary>::@class::A::@constructor::foo
  staticType: A Function()
''');
  }
}
