// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InstanceCreationExpressionResolutionTest);
    defineReflectiveTests(
      InstanceCreationExpressionResolutionTest_WithoutConstructorTearoffs,
    );
  });
}

@reflectiveTest
class InstanceCreationExpressionResolutionTest extends PubPackageResolutionTest
    with InstanceCreationTestCases {}

@reflectiveTest
class InstanceCreationExpressionResolutionTest_WithoutConstructorTearoffs
    extends PubPackageResolutionTest
    with WithoutConstructorTearoffsMixin {
  test_unnamedViaNew() async {
    await assertErrorsInCode(
      '''
class A {
  A(int a);
}

void f() {
  A.new(0);
}
''',
      [error(ParserErrorCode.experimentNotEnabled, 40, 3)],
    );

    // Resolution should continue even though the experiment is not enabled.
    var node = findNode.instanceCreation('A.new(0)');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      element2: <testLibrary>::@class::A
      type: A
    period: .
    name: SimpleIdentifier
      token: new
      element: <testLibrary>::@class::A::@constructor::new
      staticType: null
    element: <testLibrary>::@class::A::@constructor::new
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <testLibrary>::@class::A::@constructor::new::@formalParameter::a
        staticType: int
    rightParenthesis: )
  staticType: A
''');
  }
}

mixin InstanceCreationTestCases on PubPackageResolutionTest {
  test_arguments_named() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int a, {required bool b, required double c});
}

void f() {
  A(0, b: true, c: 1.2);
}
''');

    var node = findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      element2: <testLibrary>::@class::A
      type: A
    element: <testLibrary>::@class::A::@constructor::new
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <testLibrary>::@class::A::@constructor::new::@formalParameter::a
        staticType: int
      NamedExpression
        name: Label
          label: SimpleIdentifier
            token: b
            element: <testLibrary>::@class::A::@constructor::new::@formalParameter::b
            staticType: null
          colon: :
        expression: BooleanLiteral
          literal: true
          staticType: bool
        correspondingParameter: <testLibrary>::@class::A::@constructor::new::@formalParameter::b
      NamedExpression
        name: Label
          label: SimpleIdentifier
            token: c
            element: <testLibrary>::@class::A::@constructor::new::@formalParameter::c
            staticType: null
          colon: :
        expression: DoubleLiteral
          literal: 1.2
          staticType: double
        correspondingParameter: <testLibrary>::@class::A::@constructor::new::@formalParameter::c
    rightParenthesis: )
  staticType: A
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_class_generic_constructor_named_augmentationDeclares() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart'

augment class A<T2> {
  A.named(T2 value);
}
''');
    await assertNoErrorsInCode(r'''
part 'a.dart';

class A<T> {}

void f() {
  A.named(0);
}
''');

    var node = findNode.singleInstanceCreationExpression;
    // TODO(scheglov): should be `A<int>`
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      element: <testLibraryFragment>::@class::A
      element2: <testLibrary>::@class::A
      type: A<dynamic>
    period: .
    name: SimpleIdentifier
      token: named
      staticElement: ConstructorMember
        base: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@constructor::named
        augmentationSubstitution: {T2: T}
        substitution: {T: dynamic}
      element: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@constructor::named#element
      staticType: null
    staticElement: ConstructorMember
      base: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@constructor::named
      augmentationSubstitution: {T2: T}
      substitution: {T: dynamic}
    element: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@constructor::named#element
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: ParameterMember
          base: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@constructor::named::@parameter::value
          augmentationSubstitution: {T2: T}
          substitution: {T: dynamic}
        staticType: int
    rightParenthesis: )
  staticType: A<dynamic>
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_class_generic_constructor_unnamed_augmentationDeclares() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart'

augment class A<T2> {
  A(T2 value);
}
''');
    await assertErrorsInCode(
      r'''
part 'a.dart';

class A<T> {
  A._();
}

void f() {
  A(0);
}
''',
      [error(WarningCode.unusedElement, 33, 1)],
    );

    var node = findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      element: <testLibraryFragment>::@class::A
      element2: <testLibrary>::@class::A
      type: A<int>
    staticElement: ConstructorMember
      base: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@constructor::new
      augmentationSubstitution: {T2: T}
      substitution: {T: int}
    element: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@constructor::new#element
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: ParameterMember
          base: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@constructor::new::@parameter::value
          augmentationSubstitution: {T2: T}
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  staticType: A<int>
''');
  }

  test_class_generic_named_inferTypeArguments() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  A.named(T t);
}

void f() {
  A.named(0);
}
''');

    var node = findNode.instanceCreation('A.named(0)');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      element2: <testLibrary>::@class::A
      type: A<int>
    period: .
    name: SimpleIdentifier
      token: named
      element: ConstructorMember
        baseElement: <testLibrary>::@class::A::@constructor::named
        substitution: {T: dynamic}
      staticType: null
    element: ConstructorMember
      baseElement: <testLibrary>::@class::A::@constructor::named
      substitution: {T: int}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: ParameterMember
          baseElement: <testLibrary>::@class::A::@constructor::named::@formalParameter::t
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  staticType: A<int>
''');
  }

  test_class_generic_named_withTypeArguments() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  A.named();
}

void f() {
  A<int>.named();
}
''');

    var node = findNode.instanceCreation('A<int>');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element2: dart:core::@class::int
            type: int
        rightBracket: >
      element2: <testLibrary>::@class::A
      type: A<int>
    period: .
    name: SimpleIdentifier
      token: named
      element: ConstructorMember
        baseElement: <testLibrary>::@class::A::@constructor::named
        substitution: {T: int}
      staticType: null
    element: ConstructorMember
      baseElement: <testLibrary>::@class::A::@constructor::named
      substitution: {T: int}
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: A<int>
''');
  }

  test_class_generic_unnamed_inferTypeArguments() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  A(T t);
}

void f() {
  A(0);
}
''');

    var node = findNode.instanceCreation('A(0)');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      element2: <testLibrary>::@class::A
      type: A<int>
    element: ConstructorMember
      baseElement: <testLibrary>::@class::A::@constructor::new
      substitution: {T: int}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: ParameterMember
          baseElement: <testLibrary>::@class::A::@constructor::new::@formalParameter::t
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  staticType: A<int>
''');
  }

  test_class_generic_unnamed_withTypeArguments() async {
    await assertNoErrorsInCode(r'''
class A<T> {}

void f() {
  A<int>();
}
''');

    var node = findNode.instanceCreation('A<int>');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element2: dart:core::@class::int
            type: int
        rightBracket: >
      element2: <testLibrary>::@class::A
      type: A<int>
    element: ConstructorMember
      baseElement: <testLibrary>::@class::A::@constructor::new
      substitution: {T: int}
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: A<int>
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_class_notGeneric_constructor_named_augmentationAugments() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart'

augment class A {
  augment A.named();
}
''');
    await assertNoErrorsInCode(r'''
part 'a.dart';

class A {
  A.named();
}

void f() {
  A.named();
}
''');

    var node = findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      element: <testLibraryFragment>::@class::A
      element2: <testLibrary>::@class::A
      type: A
    period: .
    name: SimpleIdentifier
      token: named
      staticElement: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@constructorAugmentation::named
      element: <testLibraryFragment>::@class::A::@constructor::named#element
      staticType: null
    staticElement: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@constructorAugmentation::named
    element: <testLibraryFragment>::@class::A::@constructor::named#element
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: A
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_class_notGeneric_constructor_named_augmentationDeclares() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart'

augment class A {
  A.named();
}
''');
    await assertNoErrorsInCode(r'''
part 'a.dart';

class A {}

void f() {
  A.named();
}
''');

    var node = findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      element: <testLibraryFragment>::@class::A
      element2: <testLibrary>::@class::A
      type: A
    period: .
    name: SimpleIdentifier
      token: named
      staticElement: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@constructor::named
      element: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@constructor::named#element
      staticType: null
    staticElement: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@constructor::named
    element: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@constructor::named#element
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: A
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_class_notGeneric_constructor_unnamed_augmentationAugments() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart'

augment class A {
  augment A();
}
''');
    await assertNoErrorsInCode(r'''
part 'a.dart';

class A {
  A();
}

void f() {
  A();
}
''');

    var node = findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      element: <testLibraryFragment>::@class::A
      element2: <testLibrary>::@class::A
      type: A
    staticElement: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@constructorAugmentation::new
    element: <testLibraryFragment>::@class::A::@constructor::new#element
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: A
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_class_notGeneric_constructor_unnamed_augmentationDeclares() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart'

augment class A {
  A();
}
''');
    await assertErrorsInCode(
      r'''
part 'a.dart';

class A {
  A._();
}

void f() {
  A();
}
''',
      [error(WarningCode.unusedElement, 30, 1)],
    );

    var node = findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      element: <testLibraryFragment>::@class::A
      element2: <testLibrary>::@class::A
      type: A
    staticElement: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@constructor::new
    element: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@constructor::new#element
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: A
''');
  }

  test_class_notGeneric_named() async {
    await assertNoErrorsInCode(r'''
class A {
  A.named(int a);
}

void f() {
  A.named(0);
}
''');

    var node = findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      element2: <testLibrary>::@class::A
      type: A
    period: .
    name: SimpleIdentifier
      token: named
      element: <testLibrary>::@class::A::@constructor::named
      staticType: null
    element: <testLibrary>::@class::A::@constructor::named
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <testLibrary>::@class::A::@constructor::named::@formalParameter::a
        staticType: int
    rightParenthesis: )
  staticType: A
''');
  }

  test_class_notGeneric_unnamed() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int a);
}

void f() {
  A(0);
}

''');

    var node = findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      element2: <testLibrary>::@class::A
      type: A
    element: <testLibrary>::@class::A::@constructor::new
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <testLibrary>::@class::A::@constructor::new::@formalParameter::a
        staticType: int
    rightParenthesis: )
  staticType: A
''');
  }

  test_class_notGeneric_unresolved() async {
    await assertErrorsInCode(
      r'''
class A {}

void f() {
  new A.unresolved(0);
}

''',
      [error(CompileTimeErrorCode.newWithUndefinedConstructor, 31, 10)],
    );

    var node = findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  keyword: new
  constructorName: ConstructorName
    type: NamedType
      name: A
      element2: <testLibrary>::@class::A
      type: A
    period: .
    name: SimpleIdentifier
      token: unresolved
      element: <null>
      staticType: null
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <null>
        staticType: int
    rightParenthesis: )
  staticType: A
''');
  }

  test_demoteType() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  A(T t);
}

void f<S>(S s) {
  if (s is int) {
    A(s);
  }
}

''');

    var node = findNode.instanceCreation('A(s)');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      element2: <testLibrary>::@class::A
      type: A<S>
    element: ConstructorMember
      baseElement: <testLibrary>::@class::A::@constructor::new
      substitution: {T: S}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: s
        correspondingParameter: ParameterMember
          baseElement: <testLibrary>::@class::A::@constructor::new::@formalParameter::t
          substitution: {T: S}
        element: <testLibrary>::@function::f::@formalParameter::s
        staticType: S & int
    rightParenthesis: )
  staticType: A<S>
''');
  }

  test_error_newWithInvalidTypeParameters_implicitNew_inference_top() async {
    await assertErrorsInCode(
      r'''
final foo = Map<int>();
''',
      [error(CompileTimeErrorCode.wrongNumberOfTypeArguments, 12, 8)],
    );

    var node = findNode.instanceCreation('Map<int>');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: Map
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element2: dart:core::@class::int
            type: int
        rightBracket: >
      element2: dart:core::@class::Map
      type: Map<dynamic, dynamic>
    element: ConstructorMember
      baseElement: dart:core::@class::Map::@constructor::new
      substitution: {K: dynamic, V: dynamic}
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: Map<dynamic, dynamic>
''');
  }

  test_error_wrongNumberOfTypeArgumentsConstructor_explicitNew() async {
    await assertErrorsInCode(
      r'''
class Foo<X> {
  Foo.bar();
}

main() {
  new Foo.bar<int>();
}
''',
      [
        error(
          CompileTimeErrorCode.wrongNumberOfTypeArgumentsConstructor,
          53,
          5,
          messageContains: ["The constructor 'Foo.bar'"],
        ),
      ],
    );

    var node = findNode.instanceCreation('Foo.bar<int>');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  keyword: new
  constructorName: ConstructorName
    type: NamedType
      name: Foo
      element2: <testLibrary>::@class::Foo
      type: Foo<dynamic>
    period: .
    name: SimpleIdentifier
      token: bar
      element: ConstructorMember
        baseElement: <testLibrary>::@class::Foo::@constructor::bar
        substitution: {X: dynamic}
      staticType: null
    element: ConstructorMember
      baseElement: <testLibrary>::@class::Foo::@constructor::bar
      substitution: {X: dynamic}
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element2: dart:core::@class::int
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: Foo<dynamic>
''');
  }

  test_error_wrongNumberOfTypeArgumentsConstructor_explicitNew_new() async {
    await assertErrorsInCode(
      r'''
class Foo<X> {
  Foo.new();
}

main() {
  new Foo.new<int>();
}
''',
      [
        error(
          CompileTimeErrorCode.wrongNumberOfTypeArgumentsConstructor,
          53,
          5,
          messageContains: ["The constructor 'Foo.new'"],
        ),
      ],
    );

    var node = findNode.instanceCreation('Foo.new<int>');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  keyword: new
  constructorName: ConstructorName
    type: NamedType
      name: Foo
      element2: <testLibrary>::@class::Foo
      type: Foo<dynamic>
    period: .
    name: SimpleIdentifier
      token: new
      element: ConstructorMember
        baseElement: <testLibrary>::@class::Foo::@constructor::new
        substitution: {X: dynamic}
      staticType: null
    element: ConstructorMember
      baseElement: <testLibrary>::@class::Foo::@constructor::new
      substitution: {X: dynamic}
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element2: dart:core::@class::int
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: Foo<dynamic>
''');
  }

  test_error_wrongNumberOfTypeArgumentsConstructor_explicitNew_prefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class Foo<X> {
  Foo.bar();
}
''');
    await assertErrorsInCode(
      '''
import 'a.dart' as p;

main() {
  new p.Foo.bar<int>();
}
''',
      [error(ParserErrorCode.constructorWithTypeArguments, 44, 3)],
    );

    // TODO(brianwilkerson): Test this more carefully after we can re-write the
    // AST to reflect the expected structure.
    var node = findNode.instanceCreation('Foo.bar<int>');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  keyword: new
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: p
        period: .
        element2: <testLibraryFragment>::@prefix2::p
      name: Foo
      element2: package:test/a.dart::@class::Foo
      type: Foo<dynamic>
    period: .
    name: SimpleIdentifier
      token: bar
      element: ConstructorMember
        baseElement: package:test/a.dart::@class::Foo::@constructor::bar
        substitution: {X: dynamic}
      staticType: null
    element: ConstructorMember
      baseElement: package:test/a.dart::@class::Foo::@constructor::bar
      substitution: {X: dynamic}
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element2: dart:core::@class::int
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: Foo<dynamic>
''');
  }

  test_error_wrongNumberOfTypeArgumentsConstructor_implicitNew() async {
    await assertErrorsInCode(
      r'''
class Foo<X> {
  Foo.bar();
}

main() {
  Foo.bar<int>();
}
''',
      [
        error(
          CompileTimeErrorCode.wrongNumberOfTypeArgumentsConstructor,
          49,
          5,
        ),
      ],
    );

    var node = findNode.instanceCreation('Foo.bar<int>');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: Foo
      element2: <testLibrary>::@class::Foo
      type: Foo<dynamic>
    period: .
    name: SimpleIdentifier
      token: bar
      element: ConstructorMember
        baseElement: <testLibrary>::@class::Foo::@constructor::bar
        substitution: {X: dynamic}
      staticType: null
    element: ConstructorMember
      baseElement: <testLibrary>::@class::Foo::@constructor::bar
      substitution: {X: dynamic}
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element2: dart:core::@class::int
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: Foo<dynamic>
''');
  }

  test_error_wrongNumberOfTypeArgumentsConstructor_implicitNew_prefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class Foo<X> {
  Foo.bar();
}
''');
    await assertErrorsInCode(
      '''
import 'a.dart' as p;

main() {
  p.Foo.bar<int>();
}
''',
      [
        error(
          CompileTimeErrorCode.wrongNumberOfTypeArgumentsConstructor,
          43,
          5,
        ),
      ],
    );

    var node = findNode.instanceCreation('Foo.bar<int>');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: p
        period: .
        element2: <testLibraryFragment>::@prefix2::p
      name: Foo
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element2: dart:core::@class::int
            type: int
        rightBracket: >
      element2: package:test/a.dart::@class::Foo
      type: Foo<int>
    period: .
    name: SimpleIdentifier
      token: bar
      element: ConstructorMember
        baseElement: package:test/a.dart::@class::Foo::@constructor::bar
        substitution: {X: int}
      staticType: null
    element: ConstructorMember
      baseElement: package:test/a.dart::@class::Foo::@constructor::bar
      substitution: {X: int}
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: Foo<int>
''');
  }

  test_extensionType_generic_primary_unnamed() async {
    await assertNoErrorsInCode(r'''
extension type A<T>(T it) {}

void f() {
  A(0);
}
''');

    var node = findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      element2: <testLibrary>::@extensionType::A
      type: A<int>
    element: ConstructorMember
      baseElement: <testLibrary>::@extensionType::A::@constructor::new
      substitution: {T: int}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: FieldFormalParameterMember
          baseElement: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  staticType: A<int>
''');
  }

  test_extensionType_generic_secondary_unnamed() async {
    await assertNoErrorsInCode(r'''
extension type A<T>.named(T it) {
  A(this.it);
}

void f() {
  A(0);
}
''');

    var node = findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      element2: <testLibrary>::@extensionType::A
      type: A<int>
    element: ConstructorMember
      baseElement: <testLibrary>::@extensionType::A::@constructor::new
      substitution: {T: int}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: FieldFormalParameterMember
          baseElement: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  staticType: A<int>
''');
  }

  test_extensionType_notGeneric_primary_named() async {
    await assertNoErrorsInCode(r'''
extension type A.named(int it) {}

void f() {
  A.named(0);
}
''');

    var node = findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      element2: <testLibrary>::@extensionType::A
      type: A
    period: .
    name: SimpleIdentifier
      token: named
      element: <testLibrary>::@extensionType::A::@constructor::named
      staticType: null
    element: <testLibrary>::@extensionType::A::@constructor::named
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <testLibrary>::@extensionType::A::@constructor::named::@formalParameter::it
        staticType: int
    rightParenthesis: )
  staticType: A
''');
  }

  test_extensionType_notGeneric_primary_unnamed() async {
    await assertNoErrorsInCode(r'''
extension type A(int it) {}

void f() {
  A(0);
}
''');

    var node = findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      element2: <testLibrary>::@extensionType::A
      type: A
    element: <testLibrary>::@extensionType::A::@constructor::new
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
        staticType: int
    rightParenthesis: )
  staticType: A
''');
  }

  test_extensionType_notGeneric_secondary_named() async {
    await assertNoErrorsInCode(r'''
extension type A(int it) {
  A.named(this.it);
}

void f() {
  A.named(0);
}
''');

    var node = findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      element2: <testLibrary>::@extensionType::A
      type: A
    period: .
    name: SimpleIdentifier
      token: named
      element: <testLibrary>::@extensionType::A::@constructor::named
      staticType: null
    element: <testLibrary>::@extensionType::A::@constructor::named
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <testLibrary>::@extensionType::A::@constructor::named::@formalParameter::it
        staticType: int
    rightParenthesis: )
  staticType: A
''');
  }

  test_extensionType_notGeneric_secondary_unnamed() async {
    await assertNoErrorsInCode(r'''
extension type A.named(int it) {
  A(this.it);
}

void f() {
  A(0);
}
''');

    var node = findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      element2: <testLibrary>::@extensionType::A
      type: A
    element: <testLibrary>::@extensionType::A::@constructor::new
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
        staticType: int
    rightParenthesis: )
  staticType: A
''');
  }

  test_extensionType_notGeneric_unresolved() async {
    await assertErrorsInCode(
      r'''
extension type A(int it) {}

void f() {
  new A.named(0);
}
''',
      [error(CompileTimeErrorCode.newWithUndefinedConstructor, 48, 5)],
    );

    var node = findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  keyword: new
  constructorName: ConstructorName
    type: NamedType
      name: A
      element2: <testLibrary>::@extensionType::A
      type: A
    period: .
    name: SimpleIdentifier
      token: named
      element: <null>
      staticType: null
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <null>
        staticType: int
    rightParenthesis: )
  staticType: A
''');
  }

  test_importPrefix() async {
    await assertErrorsInCode(
      r'''
import 'dart:math' as prefix;

void f() {
  new prefix(0);
}

''',
      [error(CompileTimeErrorCode.newWithNonType, 48, 6)],
    );

    var node = findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  keyword: new
  constructorName: ConstructorName
    type: NamedType
      name: prefix
      element2: <testLibraryFragment>::@prefix2::prefix
      type: InvalidType
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <null>
        staticType: int
    rightParenthesis: )
  staticType: InvalidType
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_importPrefix_class_generic_constructor_named_augmentationDeclares() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';

class A<T> {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart'

augment class A<T2> {
  A.named(T2 value);
}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

void f() {
  prefix.A.named(0);
}
''');

    var node = findNode.singleInstanceCreationExpression;
    // TODO(scheglov): should be `A<int>`
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: prefix
        period: .
        element: <testLibraryFragment>::@prefix::prefix
        element2: <testLibraryFragment>::@prefix2::prefix
      name: A
      element: package:test/a.dart::<fragment>::@class::A
      element2: package:test/a.dart::@class::A
      type: A<dynamic>
    period: .
    name: SimpleIdentifier
      token: named
      staticElement: ConstructorMember
        base: package:test/a.dart::@fragment::package:test/b.dart::@classAugmentation::A::@constructor::named
        augmentationSubstitution: {T2: T}
        substitution: {T: dynamic}
      element: package:test/a.dart::@fragment::package:test/b.dart::@classAugmentation::A::@constructor::named#element
      staticType: null
    staticElement: ConstructorMember
      base: package:test/a.dart::@fragment::package:test/b.dart::@classAugmentation::A::@constructor::named
      augmentationSubstitution: {T2: T}
      substitution: {T: dynamic}
    element: package:test/a.dart::@fragment::package:test/b.dart::@classAugmentation::A::@constructor::named#element
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: ParameterMember
          base: package:test/a.dart::@fragment::package:test/b.dart::@classAugmentation::A::@constructor::named::@parameter::value
          augmentationSubstitution: {T2: T}
          substitution: {T: dynamic}
        staticType: int
    rightParenthesis: )
  staticType: A<dynamic>
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_importPrefix_class_generic_constructor_unnamed_augmentationDeclares() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';

class A<T> {
  A._();
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart'

augment class A<T2> {
  A(T2 value);
}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

void f() {
  prefix.A(0);
}
''');

    var node = findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: prefix
        period: .
        element: <testLibraryFragment>::@prefix::prefix
        element2: <testLibraryFragment>::@prefix2::prefix
      name: A
      element: package:test/a.dart::<fragment>::@class::A
      element2: package:test/a.dart::@class::A
      type: A<int>
    staticElement: ConstructorMember
      base: package:test/a.dart::@fragment::package:test/b.dart::@classAugmentation::A::@constructor::new
      augmentationSubstitution: {T2: T}
      substitution: {T: int}
    element: package:test/a.dart::@fragment::package:test/b.dart::@classAugmentation::A::@constructor::new#element
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: ParameterMember
          base: package:test/a.dart::@fragment::package:test/b.dart::@classAugmentation::A::@constructor::new::@parameter::value
          augmentationSubstitution: {T2: T}
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  staticType: A<int>
''');
  }

  test_importPrefix_class_named() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  A.named(int a);
}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

void f() {
  prefix.A.named(0);
}

''');

    var node = findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: prefix
        period: .
        element2: <testLibraryFragment>::@prefix2::prefix
      name: A
      element2: package:test/a.dart::@class::A
      type: A
    period: .
    name: SimpleIdentifier
      token: named
      element: package:test/a.dart::@class::A::@constructor::named
      staticType: null
    element: package:test/a.dart::@class::A::@constructor::named
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: package:test/a.dart::@class::A::@constructor::named::@formalParameter::a
        staticType: int
    rightParenthesis: )
  staticType: A
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_importPrefix_class_notGeneric_constructor_named_augmentationDeclares() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';

class A {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart'

augment class A {
  A.named();
}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

void f() {
  prefix.A.named();
}
''');

    var node = findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: prefix
        period: .
        element: <testLibraryFragment>::@prefix::prefix
        element2: <testLibraryFragment>::@prefix2::prefix
      name: A
      element: package:test/a.dart::<fragment>::@class::A
      element2: package:test/a.dart::@class::A
      type: A
    period: .
    name: SimpleIdentifier
      token: named
      staticElement: package:test/a.dart::@fragment::package:test/b.dart::@classAugmentation::A::@constructor::named
      element: package:test/a.dart::@fragment::package:test/b.dart::@classAugmentation::A::@constructor::named#element
      staticType: null
    staticElement: package:test/a.dart::@fragment::package:test/b.dart::@classAugmentation::A::@constructor::named
    element: package:test/a.dart::@fragment::package:test/b.dart::@classAugmentation::A::@constructor::named#element
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: A
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_importPrefix_class_notGeneric_constructor_unnamed_augmentationDeclares() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';

class A {
  A._();
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart'

augment class A {
  A();
}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

void f() {
  prefix.A();
}
''');

    var node = findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: prefix
        period: .
        element: <testLibraryFragment>::@prefix::prefix
        element2: <testLibraryFragment>::@prefix2::prefix
      name: A
      element: package:test/a.dart::<fragment>::@class::A
      element2: package:test/a.dart::@class::A
      type: A
    staticElement: package:test/a.dart::@fragment::package:test/b.dart::@classAugmentation::A::@constructor::new
    element: package:test/a.dart::@fragment::package:test/b.dart::@classAugmentation::A::@constructor::new#element
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: A
''');
  }

  test_importPrefix_class_typeArguments_named() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A<T> {
  A.named(int a);
}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

void f() {
  prefix.A<int>.named(0);
}

''');

    var node = findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: prefix
        period: .
        element2: <testLibraryFragment>::@prefix2::prefix
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element2: dart:core::@class::int
            type: int
        rightBracket: >
      element2: package:test/a.dart::@class::A
      type: A<int>
    period: .
    name: SimpleIdentifier
      token: named
      element: ConstructorMember
        baseElement: package:test/a.dart::@class::A::@constructor::named
        substitution: {T: int}
      staticType: null
    element: ConstructorMember
      baseElement: package:test/a.dart::@class::A::@constructor::named
      substitution: {T: int}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: ParameterMember
          baseElement: package:test/a.dart::@class::A::@constructor::named::@formalParameter::a
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  staticType: A<int>
''');
  }

  test_importPrefix_class_typeArguments_unnamed() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A<T> {
  A(int a);
}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

void f() {
  prefix.A<int>(0);
}

''');

    var node = findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: prefix
        period: .
        element2: <testLibraryFragment>::@prefix2::prefix
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element2: dart:core::@class::int
            type: int
        rightBracket: >
      element2: package:test/a.dart::@class::A
      type: A<int>
    element: ConstructorMember
      baseElement: package:test/a.dart::@class::A::@constructor::new
      substitution: {T: int}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: ParameterMember
          baseElement: package:test/a.dart::@class::A::@constructor::new::@formalParameter::a
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  staticType: A<int>
''');
  }

  test_importPrefix_class_unnamed() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  A(int a);
}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

void f() {
  prefix.A(0);
}

''');

    var node = findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: prefix
        period: .
        element2: <testLibraryFragment>::@prefix2::prefix
      name: A
      element2: package:test/a.dart::@class::A
      type: A
    element: package:test/a.dart::@class::A::@constructor::new
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: package:test/a.dart::@class::A::@constructor::new::@formalParameter::a
        staticType: int
    rightParenthesis: )
  staticType: A
''');
  }

  test_importPrefix_class_unresolved() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    await assertErrorsInCode(
      r'''
import 'a.dart' as prefix;

void f() {
  new prefix.A.foo(0);
}

''',
      [error(CompileTimeErrorCode.newWithUndefinedConstructor, 54, 3)],
    );

    var node = findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  keyword: new
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: prefix
        period: .
        element2: <testLibraryFragment>::@prefix2::prefix
      name: A
      element2: package:test/a.dart::@class::A
      type: A
    period: .
    name: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <null>
        staticType: int
    rightParenthesis: )
  staticType: A
''');
  }

  test_importPrefix_unresolved_identifier() async {
    await assertErrorsInCode(
      r'''
import 'dart:math' as prefix;

void f() {
  new prefix.Foo.bar(0);
}

''',
      [error(CompileTimeErrorCode.newWithNonType, 55, 3)],
    );

    var node = findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  keyword: new
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: prefix
        period: .
        element2: <testLibraryFragment>::@prefix2::prefix
      name: Foo
      element2: <null>
      type: InvalidType
    period: .
    name: SimpleIdentifier
      token: bar
      element: <null>
      staticType: null
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <null>
        staticType: int
    rightParenthesis: )
  staticType: InvalidType
''');
  }

  test_namedArgument_anywhere() async {
    await assertNoErrorsInCode('''
class A {}
class B {}
class C {}
class D {}

class X {
  X(A a, B b, {C? c, D? d});
}

T g1<T>() => throw 0;
T g2<T>() => throw 0;
T g3<T>() => throw 0;
T g4<T>() => throw 0;

void f() {
  X(g1(), c: g3(), g2(), d: g4());
}
''');

    var node = findNode.instanceCreation('X(g');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: X
      element2: <testLibrary>::@class::X
      type: X
    element: <testLibrary>::@class::X::@constructor::new
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      MethodInvocation
        methodName: SimpleIdentifier
          token: g1
          element: <testLibrary>::@function::g1
          staticType: T Function<T>()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        correspondingParameter: <testLibrary>::@class::X::@constructor::new::@formalParameter::a
        staticInvokeType: A Function()
        staticType: A
        typeArgumentTypes
          A
      NamedExpression
        name: Label
          label: SimpleIdentifier
            token: c
            element: <testLibrary>::@class::X::@constructor::new::@formalParameter::c
            staticType: null
          colon: :
        expression: MethodInvocation
          methodName: SimpleIdentifier
            token: g3
            element: <testLibrary>::@function::g3
            staticType: T Function<T>()
          argumentList: ArgumentList
            leftParenthesis: (
            rightParenthesis: )
          staticInvokeType: C? Function()
          staticType: C?
          typeArgumentTypes
            C?
        correspondingParameter: <testLibrary>::@class::X::@constructor::new::@formalParameter::c
      MethodInvocation
        methodName: SimpleIdentifier
          token: g2
          element: <testLibrary>::@function::g2
          staticType: T Function<T>()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        correspondingParameter: <testLibrary>::@class::X::@constructor::new::@formalParameter::b
        staticInvokeType: B Function()
        staticType: B
        typeArgumentTypes
          B
      NamedExpression
        name: Label
          label: SimpleIdentifier
            token: d
            element: <testLibrary>::@class::X::@constructor::new::@formalParameter::d
            staticType: null
          colon: :
        expression: MethodInvocation
          methodName: SimpleIdentifier
            token: g4
            element: <testLibrary>::@function::g4
            staticType: T Function<T>()
          argumentList: ArgumentList
            leftParenthesis: (
            rightParenthesis: )
          staticInvokeType: D? Function()
          staticType: D?
          typeArgumentTypes
            D?
        correspondingParameter: <testLibrary>::@class::X::@constructor::new::@formalParameter::d
    rightParenthesis: )
  staticType: X
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_typeAlias_generic_class_generic_constructor_named_augmentationDeclares() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart'

augment class A<T2> {
  A.named(T2 value);
}
''');
    await assertNoErrorsInCode(r'''
part 'a.dart';

class A<T> {}

typedef X<U> = A<U>;

void f() {
  X.named(0);
}
''');

    var node = findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: X
      element: <testLibraryFragment>::@typeAlias::X
      element2: <testLibrary>::@typeAlias::X
      type: A<int>
    period: .
    name: SimpleIdentifier
      token: named
      staticElement: ConstructorMember
        base: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@constructor::named
        augmentationSubstitution: {T2: T}
        substitution: {T: dynamic}
      element: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@constructor::named#element
      staticType: null
    staticElement: ConstructorMember
      base: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@constructor::named
      augmentationSubstitution: {T2: T}
      substitution: {T: int}
    element: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@constructor::named#element
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: ParameterMember
          base: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@constructor::named::@parameter::value
          augmentationSubstitution: {T2: T}
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  staticType: A<int>
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_typeAlias_generic_class_generic_constructor_unnamed_augmentationDeclares() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart'

augment class A<T2> {
  A(T2 value);
}
''');
    await assertErrorsInCode(
      r'''
part 'a.dart';

class A<T> {
  A._();
}

typedef X<U> = A<U>;

void f() {
  X(0);
}
''',
      [error(WarningCode.unusedElement, 33, 1)],
    );

    var node = findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: X
      element: <testLibraryFragment>::@typeAlias::X
      element2: <testLibrary>::@typeAlias::X
      type: A<int>
    staticElement: ConstructorMember
      base: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@constructor::new
      augmentationSubstitution: {T2: T}
      substitution: {T: int}
    element: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@constructor::new#element
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: ParameterMember
          base: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@constructor::new::@parameter::value
          augmentationSubstitution: {T2: T}
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  staticType: A<int>
''');
  }

  test_typeAlias_generic_class_generic_named_infer_all() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  A.named(T t);
}

typedef B<U> = A<U>;

void f() {
  B.named(0);
}
''');

    var node = findNode.instanceCreation('B.named(0)');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: B
      element2: <testLibrary>::@typeAlias::B
      type: A<int>
    period: .
    name: SimpleIdentifier
      token: named
      element: ConstructorMember
        baseElement: <testLibrary>::@class::A::@constructor::named
        substitution: {T: dynamic}
      staticType: null
    element: ConstructorMember
      baseElement: <testLibrary>::@class::A::@constructor::named
      substitution: {T: int}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: ParameterMember
          baseElement: <testLibrary>::@class::A::@constructor::named::@formalParameter::t
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  staticType: A<int>
''');
  }

  test_typeAlias_generic_class_generic_named_infer_partial() async {
    await assertNoErrorsInCode(r'''
class A<T, U> {
  A.named(T t, U u);
}

typedef B<V> = A<V, String>;

void f() {
  B.named(0, '');
}
''');

    var node = findNode.instanceCreation('B.named(0, ');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: B
      element2: <testLibrary>::@typeAlias::B
      type: A<int, String>
    period: .
    name: SimpleIdentifier
      token: named
      element: ConstructorMember
        baseElement: <testLibrary>::@class::A::@constructor::named
        substitution: {T: dynamic, U: String}
      staticType: null
    element: ConstructorMember
      baseElement: <testLibrary>::@class::A::@constructor::named
      substitution: {T: int, U: String}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: ParameterMember
          baseElement: <testLibrary>::@class::A::@constructor::named::@formalParameter::t
          substitution: {T: int, U: String}
        staticType: int
      SimpleStringLiteral
        literal: ''
    rightParenthesis: )
  staticType: A<int, String>
''');
  }

  test_typeAlias_generic_class_generic_unnamed_infer_all() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  A(T t);
}

typedef B<U> = A<U>;

void f() {
  B(0);
}
''');

    var node = findNode.instanceCreation('B(0)');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: B
      element2: <testLibrary>::@typeAlias::B
      type: A<int>
    element: ConstructorMember
      baseElement: <testLibrary>::@class::A::@constructor::new
      substitution: {T: int}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: ParameterMember
          baseElement: <testLibrary>::@class::A::@constructor::new::@formalParameter::t
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  staticType: A<int>
''');
  }

  test_typeAlias_generic_class_generic_unnamed_infer_partial() async {
    await assertNoErrorsInCode(r'''
class A<T, U> {
  A(T t, U u);
}

typedef B<V> = A<V, String>;

void f() {
  B(0, '');
}
''');

    var node = findNode.instanceCreation('B(0, ');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: B
      element2: <testLibrary>::@typeAlias::B
      type: A<int, String>
    element: ConstructorMember
      baseElement: <testLibrary>::@class::A::@constructor::new
      substitution: {T: int, U: String}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: ParameterMember
          baseElement: <testLibrary>::@class::A::@constructor::new::@formalParameter::t
          substitution: {T: int, U: String}
        staticType: int
      SimpleStringLiteral
        literal: ''
    rightParenthesis: )
  staticType: A<int, String>
''');
  }

  test_typeAlias_notGeneric_class_generic_named_argumentTypeMismatch() async {
    await assertErrorsInCode(
      r'''
class A<T> {
  A.named(T t);
}

typedef B = A<String>;

void f() {
  B.named(0);
}
''',
      [error(CompileTimeErrorCode.argumentTypeNotAssignable, 77, 1)],
    );

    var node = findNode.instanceCreation('B.named(0)');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: B
      element2: <testLibrary>::@typeAlias::B
      type: A<String>
    period: .
    name: SimpleIdentifier
      token: named
      element: ConstructorMember
        baseElement: <testLibrary>::@class::A::@constructor::named
        substitution: {T: String}
      staticType: null
    element: ConstructorMember
      baseElement: <testLibrary>::@class::A::@constructor::named
      substitution: {T: String}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: ParameterMember
          baseElement: <testLibrary>::@class::A::@constructor::named::@formalParameter::t
          substitution: {T: String}
        staticType: int
    rightParenthesis: )
  staticType: A<String>
''');
  }

  test_typeAlias_notGeneric_class_generic_unnamed_argumentTypeMismatch() async {
    await assertErrorsInCode(
      r'''
class A<T> {
  A(T t);
}

typedef B = A<String>;

void f() {
  B(0);
}
''',
      [error(CompileTimeErrorCode.argumentTypeNotAssignable, 65, 1)],
    );

    var node = findNode.instanceCreation('B(0)');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: B
      element2: <testLibrary>::@typeAlias::B
      type: A<String>
    element: ConstructorMember
      baseElement: <testLibrary>::@class::A::@constructor::new
      substitution: {T: String}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: ParameterMember
          baseElement: <testLibrary>::@class::A::@constructor::new::@formalParameter::t
          substitution: {T: String}
        staticType: int
    rightParenthesis: )
  staticType: A<String>
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_typeAlias_notGeneric_class_notGeneric_constructor_named_augmentationDeclares() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart'

augment class A {
  A.named();
}
''');
    await assertNoErrorsInCode(r'''
part 'a.dart';

class A {}

typedef X = A;

void f() {
  X.named();
}
''');

    var node = findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: X
      element: <testLibraryFragment>::@typeAlias::X
      element2: <testLibrary>::@typeAlias::X
      type: A
    period: .
    name: SimpleIdentifier
      token: named
      staticElement: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@constructor::named
      element: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@constructor::named#element
      staticType: null
    staticElement: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@constructor::named
    element: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@constructor::named#element
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: A
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_typeAlias_notGeneric_class_notGeneric_constructor_unnamed_augmentationDeclares() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart'

augment class A {
  A();
}
''');
    await assertErrorsInCode(
      r'''
part 'a.dart';

class A {
  A._();
}

typedef X = A;

void f() {
  X();
}
''',
      [error(WarningCode.unusedElement, 30, 1)],
    );

    var node = findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: X
      element: <testLibraryFragment>::@typeAlias::X
      element2: <testLibrary>::@typeAlias::X
      type: A
    staticElement: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@constructor::new
    element: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@constructor::new#element
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: A
''');
  }

  test_unnamed_declaredNew() async {
    await assertNoErrorsInCode('''
class A {
  A.new(int a);
}

void f() {
  A(0);
}

''');

    var node = findNode.instanceCreation('A(0)');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      element2: <testLibrary>::@class::A
      type: A
    element: <testLibrary>::@class::A::@constructor::new
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <testLibrary>::@class::A::@constructor::new::@formalParameter::a
        staticType: int
    rightParenthesis: )
  staticType: A
''');
  }

  test_unnamedViaNew_declaredNew() async {
    await assertNoErrorsInCode('''
class A {
  A.new(int a);
}

void f() {
  A.new(0);
}

''');

    var node = findNode.instanceCreation('A.new(0)');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      element2: <testLibrary>::@class::A
      type: A
    period: .
    name: SimpleIdentifier
      token: new
      element: <testLibrary>::@class::A::@constructor::new
      staticType: null
    element: <testLibrary>::@class::A::@constructor::new
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <testLibrary>::@class::A::@constructor::new::@formalParameter::a
        staticType: int
    rightParenthesis: )
  staticType: A
''');
  }

  test_unnamedViaNew_declaredUnnamed() async {
    await assertNoErrorsInCode('''
class A {
  A(int a);
}

void f() {
  A.new(0);
}

''');

    var node = findNode.instanceCreation('A.new(0)');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      element2: <testLibrary>::@class::A
      type: A
    period: .
    name: SimpleIdentifier
      token: new
      element: <testLibrary>::@class::A::@constructor::new
      staticType: null
    element: <testLibrary>::@class::A::@constructor::new
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <testLibrary>::@class::A::@constructor::new::@formalParameter::a
        staticType: int
    rightParenthesis: )
  staticType: A
''');
  }

  test_unresolved() async {
    await assertErrorsInCode(
      r'''
void f() {
  new Unresolved(0);
}

''',
      [error(CompileTimeErrorCode.newWithNonType, 17, 10)],
    );

    var node = findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  keyword: new
  constructorName: ConstructorName
    type: NamedType
      name: Unresolved
      element2: <null>
      type: InvalidType
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <null>
        staticType: int
    rightParenthesis: )
  staticType: InvalidType
''');
  }

  test_unresolved_identifier() async {
    await assertErrorsInCode(
      r'''
void f() {
  new Unresolved.named(0);
}

''',
      [error(CompileTimeErrorCode.undefinedIdentifier, 17, 16)],
    );

    var node = findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  keyword: new
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: Unresolved
        period: .
        element2: <null>
      name: named
      element2: <null>
      type: InvalidType
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <null>
        staticType: int
    rightParenthesis: )
  staticType: InvalidType
''');
  }

  test_unresolved_identifier_identifier() async {
    await assertErrorsInCode(
      r'''
void f() {
  new unresolved.Foo.bar(0);
}

''',
      [error(CompileTimeErrorCode.undefinedIdentifier, 17, 14)],
    );

    var node = findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  keyword: new
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: unresolved
        period: .
        element2: <null>
      name: Foo
      element2: <null>
      type: InvalidType
    period: .
    name: SimpleIdentifier
      token: bar
      element: <null>
      staticType: null
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <null>
        staticType: int
    rightParenthesis: )
  staticType: InvalidType
''');
  }
}
