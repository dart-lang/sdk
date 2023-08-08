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
        InstanceCreationExpressionResolutionTest_WithoutConstructorTearoffs);
  });
}

@reflectiveTest
class InstanceCreationExpressionResolutionTest extends PubPackageResolutionTest
    with InstanceCreationTestCases {}

@reflectiveTest
class InstanceCreationExpressionResolutionTest_WithoutConstructorTearoffs
    extends PubPackageResolutionTest with WithoutConstructorTearoffsMixin {
  test_unnamedViaNew() async {
    await assertErrorsInCode('''
class A {
  A(int a);
}

void f() {
  A.new(0);
}
''', [
      error(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 40, 3),
    ]);

    // Resolution should continue even though the experiment is not enabled.
    var node = findNode.instanceCreation('A.new(0)');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      element: self::@class::A
      type: A
    period: .
    name: SimpleIdentifier
      token: new
      staticElement: self::@class::A::@constructor::new
      staticType: null
    staticElement: self::@class::A::@constructor::new
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: self::@class::A::@constructor::new::@parameter::a
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

    final node = findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      element: self::@class::A
      type: A
    staticElement: self::@class::A::@constructor::new
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: self::@class::A::@constructor::new::@parameter::a
        staticType: int
      NamedExpression
        name: Label
          label: SimpleIdentifier
            token: b
            staticElement: self::@class::A::@constructor::new::@parameter::b
            staticType: null
          colon: :
        expression: BooleanLiteral
          literal: true
          staticType: bool
        parameter: self::@class::A::@constructor::new::@parameter::b
      NamedExpression
        name: Label
          label: SimpleIdentifier
            token: c
            staticElement: self::@class::A::@constructor::new::@parameter::c
            staticType: null
          colon: :
        expression: DoubleLiteral
          literal: 1.2
          staticType: double
        parameter: self::@class::A::@constructor::new::@parameter::c
    rightParenthesis: )
  staticType: A
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
      element: self::@class::A
      type: A<int>
    period: .
    name: SimpleIdentifier
      token: named
      staticElement: ConstructorMember
        base: self::@class::A::@constructor::named
        substitution: {T: dynamic}
      staticType: null
    staticElement: ConstructorMember
      base: self::@class::A::@constructor::named
      substitution: {T: int}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: ParameterMember
          base: self::@class::A::@constructor::named::@parameter::t
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
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: self::@class::A
      type: A<int>
    period: .
    name: SimpleIdentifier
      token: named
      staticElement: ConstructorMember
        base: self::@class::A::@constructor::named
        substitution: {T: int}
      staticType: null
    staticElement: ConstructorMember
      base: self::@class::A::@constructor::named
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
      element: self::@class::A
      type: A<int>
    staticElement: ConstructorMember
      base: self::@class::A::@constructor::new
      substitution: {T: int}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: ParameterMember
          base: self::@class::A::@constructor::new::@parameter::t
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
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: self::@class::A
      type: A<int>
    staticElement: ConstructorMember
      base: self::@class::A::@constructor::new
      substitution: {T: int}
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: A<int>
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

    final node = findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      element: self::@class::A
      type: A
    period: .
    name: SimpleIdentifier
      token: named
      staticElement: self::@class::A::@constructor::named
      staticType: null
    staticElement: self::@class::A::@constructor::named
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: self::@class::A::@constructor::named::@parameter::a
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

    final node = findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      element: self::@class::A
      type: A
    staticElement: self::@class::A::@constructor::new
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: self::@class::A::@constructor::new::@parameter::a
        staticType: int
    rightParenthesis: )
  staticType: A
''');
  }

  test_class_notGeneric_unresolved() async {
    await assertErrorsInCode(r'''
class A {}

void f() {
  new A.unresolved(0);
}

''', [
      error(CompileTimeErrorCode.NEW_WITH_UNDEFINED_CONSTRUCTOR, 31, 10),
    ]);

    final node = findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  keyword: new
  constructorName: ConstructorName
    type: NamedType
      name: A
      element: self::@class::A
      type: A
    period: .
    name: SimpleIdentifier
      token: unresolved
      staticElement: <null>
      staticType: null
    staticElement: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <null>
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
      element: self::@class::A
      type: A<S>
    staticElement: ConstructorMember
      base: self::@class::A::@constructor::new
      substitution: {T: S}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: s
        parameter: ParameterMember
          base: self::@class::A::@constructor::new::@parameter::t
          substitution: {T: S}
        staticElement: self::@function::f::@parameter::s
        staticType: S & int
    rightParenthesis: )
  staticType: A<S>
''');
  }

  test_error_newWithInvalidTypeParameters_implicitNew_inference_top() async {
    await assertErrorsInCode(r'''
final foo = Map<int>();
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 12, 8),
    ]);

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
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: dart:core::@class::Map
      type: Map<dynamic, dynamic>
    staticElement: ConstructorMember
      base: dart:core::@class::Map::@constructor::new
      substitution: {K: dynamic, V: dynamic}
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: Map<dynamic, dynamic>
''');
  }

  test_error_wrongNumberOfTypeArgumentsConstructor_explicitNew() async {
    await assertErrorsInCode(r'''
class Foo<X> {
  Foo.bar();
}

main() {
  new Foo.bar<int>();
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR, 53,
          5,
          messageContains: ["The constructor 'Foo.bar'"]),
    ]);

    var node = findNode.instanceCreation('Foo.bar<int>');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  keyword: new
  constructorName: ConstructorName
    type: NamedType
      name: Foo
      element: self::@class::Foo
      type: Foo<dynamic>
    period: .
    name: SimpleIdentifier
      token: bar
      staticElement: ConstructorMember
        base: self::@class::Foo::@constructor::bar
        substitution: {X: dynamic}
      staticType: null
    staticElement: ConstructorMember
      base: self::@class::Foo::@constructor::bar
      substitution: {X: dynamic}
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: Foo<dynamic>
''');
  }

  test_error_wrongNumberOfTypeArgumentsConstructor_explicitNew_new() async {
    await assertErrorsInCode(r'''
class Foo<X> {
  Foo.new();
}

main() {
  new Foo.new<int>();
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR, 53,
          5,
          messageContains: ["The constructor 'Foo.new'"]),
    ]);

    var node = findNode.instanceCreation('Foo.new<int>');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  keyword: new
  constructorName: ConstructorName
    type: NamedType
      name: Foo
      element: self::@class::Foo
      type: Foo<dynamic>
    period: .
    name: SimpleIdentifier
      token: new
      staticElement: ConstructorMember
        base: self::@class::Foo::@constructor::new
        substitution: {X: dynamic}
      staticType: null
    staticElement: ConstructorMember
      base: self::@class::Foo::@constructor::new
      substitution: {X: dynamic}
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
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
    await assertErrorsInCode('''
import 'a.dart' as p;

main() {
  new p.Foo.bar<int>();
}
''', [
      error(ParserErrorCode.CONSTRUCTOR_WITH_TYPE_ARGUMENTS, 44, 3),
    ]);

    // TODO(brianwilkerson) Test this more carefully after we can re-write the
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
        element: self::@prefix::p
      name: Foo
      element: package:test/a.dart::@class::Foo
      type: Foo<dynamic>
    period: .
    name: SimpleIdentifier
      token: bar
      staticElement: ConstructorMember
        base: package:test/a.dart::@class::Foo::@constructor::bar
        substitution: {X: dynamic}
      staticType: null
    staticElement: ConstructorMember
      base: package:test/a.dart::@class::Foo::@constructor::bar
      substitution: {X: dynamic}
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: Foo<dynamic>
''');
  }

  test_error_wrongNumberOfTypeArgumentsConstructor_implicitNew() async {
    await assertErrorsInCode(r'''
class Foo<X> {
  Foo.bar();
}

main() {
  Foo.bar<int>();
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR, 49,
          5),
    ]);

    var node = findNode.instanceCreation('Foo.bar<int>');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: Foo
      element: self::@class::Foo
      type: Foo<dynamic>
    period: .
    name: SimpleIdentifier
      token: bar
      staticElement: ConstructorMember
        base: self::@class::Foo::@constructor::bar
        substitution: {X: dynamic}
      staticType: null
    staticElement: ConstructorMember
      base: self::@class::Foo::@constructor::bar
      substitution: {X: dynamic}
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
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
    await assertErrorsInCode('''
import 'a.dart' as p;

main() {
  p.Foo.bar<int>();
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR, 43,
          5),
    ]);

    var node = findNode.instanceCreation('Foo.bar<int>');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: p
        period: .
        element: self::@prefix::p
      name: Foo
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: package:test/a.dart::@class::Foo
      type: Foo<int>
    period: .
    name: SimpleIdentifier
      token: bar
      staticElement: ConstructorMember
        base: package:test/a.dart::@class::Foo::@constructor::bar
        substitution: {X: int}
      staticType: null
    staticElement: ConstructorMember
      base: package:test/a.dart::@class::Foo::@constructor::bar
      substitution: {X: int}
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: Foo<int>
''');
  }

  test_extensionType_generic_unnamed() async {
    await assertNoErrorsInCode(r'''
extension type A<T>(T it) {}

void f() {
  A(0);
}
''');

    final node = findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      element: self::@extensionType::A
      type: A<int>
    staticElement: ConstructorMember
      base: self::@extensionType::A::@constructor::new
      substitution: {T: int}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: FieldFormalParameterMember
          base: self::@extensionType::A::@constructor::new::@parameter::it
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  staticType: A<int>
''');
  }

  test_extensionType_notGeneric_named() async {
    await assertNoErrorsInCode(r'''
extension type A.named(int it) {}

void f() {
  A.named(0);
}
''');

    final node = findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      element: self::@extensionType::A
      type: A
    period: .
    name: SimpleIdentifier
      token: named
      staticElement: self::@extensionType::A::@constructor::named
      staticType: null
    staticElement: self::@extensionType::A::@constructor::named
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: self::@extensionType::A::@constructor::named::@parameter::it
        staticType: int
    rightParenthesis: )
  staticType: A
''');
  }

  test_extensionType_notGeneric_unnamed() async {
    await assertNoErrorsInCode(r'''
extension type A(int it) {}

void f() {
  A(0);
}
''');

    final node = findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      element: self::@extensionType::A
      type: A
    staticElement: self::@extensionType::A::@constructor::new
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: self::@extensionType::A::@constructor::new::@parameter::it
        staticType: int
    rightParenthesis: )
  staticType: A
''');
  }

  test_extensionType_notGeneric_unresolved() async {
    await assertErrorsInCode(r'''
extension type A(int it) {}

void f() {
  new A.named(0);
}
''', [
      error(CompileTimeErrorCode.NEW_WITH_UNDEFINED_CONSTRUCTOR, 48, 5),
    ]);

    final node = findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  keyword: new
  constructorName: ConstructorName
    type: NamedType
      name: A
      element: self::@extensionType::A
      type: A
    period: .
    name: SimpleIdentifier
      token: named
      staticElement: <null>
      staticType: null
    staticElement: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <null>
        staticType: int
    rightParenthesis: )
  staticType: A
''');
  }

  test_importPrefix() async {
    await assertErrorsInCode(r'''
import 'dart:math' as prefix;

void f() {
  new prefix(0);
}

''', [
      error(CompileTimeErrorCode.NEW_WITH_NON_TYPE, 48, 6),
    ]);

    final node = findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  keyword: new
  constructorName: ConstructorName
    type: NamedType
      name: prefix
      element: self::@prefix::prefix
      type: InvalidType
    staticElement: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <null>
        staticType: int
    rightParenthesis: )
  staticType: InvalidType
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

    final node = findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: prefix
        period: .
        element: self::@prefix::prefix
      name: A
      element: package:test/a.dart::@class::A
      type: A
    period: .
    name: SimpleIdentifier
      token: named
      staticElement: package:test/a.dart::@class::A::@constructor::named
      staticType: null
    staticElement: package:test/a.dart::@class::A::@constructor::named
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: package:test/a.dart::@class::A::@constructor::named::@parameter::a
        staticType: int
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

    final node = findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: prefix
        period: .
        element: self::@prefix::prefix
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
      type: A<int>
    period: .
    name: SimpleIdentifier
      token: named
      staticElement: ConstructorMember
        base: package:test/a.dart::@class::A::@constructor::named
        substitution: {T: int}
      staticType: null
    staticElement: ConstructorMember
      base: package:test/a.dart::@class::A::@constructor::named
      substitution: {T: int}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: ParameterMember
          base: package:test/a.dart::@class::A::@constructor::named::@parameter::a
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

    final node = findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: prefix
        period: .
        element: self::@prefix::prefix
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
      type: A<int>
    staticElement: ConstructorMember
      base: package:test/a.dart::@class::A::@constructor::new
      substitution: {T: int}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: ParameterMember
          base: package:test/a.dart::@class::A::@constructor::new::@parameter::a
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

    final node = findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: prefix
        period: .
        element: self::@prefix::prefix
      name: A
      element: package:test/a.dart::@class::A
      type: A
    staticElement: package:test/a.dart::@class::A::@constructor::new
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: package:test/a.dart::@class::A::@constructor::new::@parameter::a
        staticType: int
    rightParenthesis: )
  staticType: A
''');
  }

  test_importPrefix_class_unresolved() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    await assertErrorsInCode(r'''
import 'a.dart' as prefix;

void f() {
  new prefix.A.foo(0);
}

''', [
      error(CompileTimeErrorCode.NEW_WITH_UNDEFINED_CONSTRUCTOR, 54, 3),
    ]);

    final node = findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  keyword: new
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: prefix
        period: .
        element: self::@prefix::prefix
      name: A
      element: package:test/a.dart::@class::A
      type: A
    period: .
    name: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticElement: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <null>
        staticType: int
    rightParenthesis: )
  staticType: A
''');
  }

  test_importPrefix_unresolved_identifier() async {
    await assertErrorsInCode(r'''
import 'dart:math' as prefix;

void f() {
  new prefix.Foo.bar(0);
}

''', [
      error(CompileTimeErrorCode.NEW_WITH_NON_TYPE, 55, 3),
    ]);

    final node = findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  keyword: new
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: prefix
        period: .
        element: self::@prefix::prefix
      name: Foo
      element: <null>
      type: InvalidType
    period: .
    name: SimpleIdentifier
      token: bar
      staticElement: <null>
      staticType: null
    staticElement: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <null>
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
      element: self::@class::X
      type: X
    staticElement: self::@class::X::@constructor::new
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      MethodInvocation
        methodName: SimpleIdentifier
          token: g1
          staticElement: self::@function::g1
          staticType: T Function<T>()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        parameter: self::@class::X::@constructor::new::@parameter::a
        staticInvokeType: A Function()
        staticType: A
        typeArgumentTypes
          A
      NamedExpression
        name: Label
          label: SimpleIdentifier
            token: c
            staticElement: self::@class::X::@constructor::new::@parameter::c
            staticType: null
          colon: :
        expression: MethodInvocation
          methodName: SimpleIdentifier
            token: g3
            staticElement: self::@function::g3
            staticType: T Function<T>()
          argumentList: ArgumentList
            leftParenthesis: (
            rightParenthesis: )
          staticInvokeType: C? Function()
          staticType: C?
          typeArgumentTypes
            C?
        parameter: self::@class::X::@constructor::new::@parameter::c
      MethodInvocation
        methodName: SimpleIdentifier
          token: g2
          staticElement: self::@function::g2
          staticType: T Function<T>()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        parameter: self::@class::X::@constructor::new::@parameter::b
        staticInvokeType: B Function()
        staticType: B
        typeArgumentTypes
          B
      NamedExpression
        name: Label
          label: SimpleIdentifier
            token: d
            staticElement: self::@class::X::@constructor::new::@parameter::d
            staticType: null
          colon: :
        expression: MethodInvocation
          methodName: SimpleIdentifier
            token: g4
            staticElement: self::@function::g4
            staticType: T Function<T>()
          argumentList: ArgumentList
            leftParenthesis: (
            rightParenthesis: )
          staticInvokeType: D? Function()
          staticType: D?
          typeArgumentTypes
            D?
        parameter: self::@class::X::@constructor::new::@parameter::d
    rightParenthesis: )
  staticType: X
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
      element: self::@typeAlias::B
      type: A<int>
    period: .
    name: SimpleIdentifier
      token: named
      staticElement: ConstructorMember
        base: self::@class::A::@constructor::named
        substitution: {T: dynamic}
      staticType: null
    staticElement: ConstructorMember
      base: self::@class::A::@constructor::named
      substitution: {T: int}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: ParameterMember
          base: self::@class::A::@constructor::named::@parameter::t
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
      element: self::@typeAlias::B
      type: A<int, String>
    period: .
    name: SimpleIdentifier
      token: named
      staticElement: ConstructorMember
        base: self::@class::A::@constructor::named
        substitution: {T: dynamic, U: String}
      staticType: null
    staticElement: ConstructorMember
      base: self::@class::A::@constructor::named
      substitution: {T: int, U: String}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: ParameterMember
          base: self::@class::A::@constructor::named::@parameter::t
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
      element: self::@typeAlias::B
      type: A<int>
    staticElement: ConstructorMember
      base: self::@class::A::@constructor::new
      substitution: {T: int}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: ParameterMember
          base: self::@class::A::@constructor::new::@parameter::t
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
      element: self::@typeAlias::B
      type: A<int, String>
    staticElement: ConstructorMember
      base: self::@class::A::@constructor::new
      substitution: {T: int, U: String}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: ParameterMember
          base: self::@class::A::@constructor::new::@parameter::t
          substitution: {T: int, U: String}
        staticType: int
      SimpleStringLiteral
        literal: ''
    rightParenthesis: )
  staticType: A<int, String>
''');
  }

  test_typeAlias_notGeneric_class_generic_named_argumentTypeMismatch() async {
    await assertErrorsInCode(r'''
class A<T> {
  A.named(T t);
}

typedef B = A<String>;

void f() {
  B.named(0);
}
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 77, 1),
    ]);

    var node = findNode.instanceCreation('B.named(0)');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: B
      element: self::@typeAlias::B
      type: A<String>
    period: .
    name: SimpleIdentifier
      token: named
      staticElement: ConstructorMember
        base: self::@class::A::@constructor::named
        substitution: {T: String}
      staticType: null
    staticElement: ConstructorMember
      base: self::@class::A::@constructor::named
      substitution: {T: String}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: ParameterMember
          base: self::@class::A::@constructor::named::@parameter::t
          substitution: {T: String}
        staticType: int
    rightParenthesis: )
  staticType: A<String>
''');
  }

  test_typeAlias_notGeneric_class_generic_unnamed_argumentTypeMismatch() async {
    await assertErrorsInCode(r'''
class A<T> {
  A(T t);
}

typedef B = A<String>;

void f() {
  B(0);
}
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 65, 1),
    ]);

    var node = findNode.instanceCreation('B(0)');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: B
      element: self::@typeAlias::B
      type: A<String>
    staticElement: ConstructorMember
      base: self::@class::A::@constructor::new
      substitution: {T: String}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: ParameterMember
          base: self::@class::A::@constructor::new::@parameter::t
          substitution: {T: String}
        staticType: int
    rightParenthesis: )
  staticType: A<String>
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
      element: self::@class::A
      type: A
    staticElement: self::@class::A::@constructor::new
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: self::@class::A::@constructor::new::@parameter::a
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
      element: self::@class::A
      type: A
    period: .
    name: SimpleIdentifier
      token: new
      staticElement: self::@class::A::@constructor::new
      staticType: null
    staticElement: self::@class::A::@constructor::new
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: self::@class::A::@constructor::new::@parameter::a
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
      element: self::@class::A
      type: A
    period: .
    name: SimpleIdentifier
      token: new
      staticElement: self::@class::A::@constructor::new
      staticType: null
    staticElement: self::@class::A::@constructor::new
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: self::@class::A::@constructor::new::@parameter::a
        staticType: int
    rightParenthesis: )
  staticType: A
''');
  }

  test_unresolved() async {
    await assertErrorsInCode(r'''
void f() {
  new Unresolved(0);
}

''', [
      error(CompileTimeErrorCode.NEW_WITH_NON_TYPE, 17, 10),
    ]);

    final node = findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  keyword: new
  constructorName: ConstructorName
    type: NamedType
      name: Unresolved
      element: <null>
      type: InvalidType
    staticElement: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <null>
        staticType: int
    rightParenthesis: )
  staticType: InvalidType
''');
  }

  test_unresolved_identifier() async {
    await assertErrorsInCode(r'''
void f() {
  new Unresolved.named(0);
}

''', [
      error(CompileTimeErrorCode.NEW_WITH_NON_TYPE, 17, 16),
    ]);

    final node = findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  keyword: new
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: Unresolved
        period: .
        element: <null>
      name: named
      element: <null>
      type: InvalidType
    staticElement: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <null>
        staticType: int
    rightParenthesis: )
  staticType: InvalidType
''');
  }

  test_unresolved_identifier_identifier() async {
    await assertErrorsInCode(r'''
void f() {
  new unresolved.Foo.bar(0);
}

''', [
      error(CompileTimeErrorCode.NEW_WITH_NON_TYPE, 17, 14),
    ]);

    final node = findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  keyword: new
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: unresolved
        period: .
        element: <null>
      name: Foo
      element: <null>
      type: InvalidType
    period: .
    name: SimpleIdentifier
      token: bar
      staticElement: <null>
      staticType: null
    staticElement: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <null>
        staticType: int
    rightParenthesis: )
  staticType: InvalidType
''');
  }
}
