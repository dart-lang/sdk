// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeLiteralResolutionTest);
    defineReflectiveTests(TypeLiteralResolutionTest_WithoutConstructorTearoffs);
  });
}

@reflectiveTest
class TypeLiteralResolutionTest extends PubPackageResolutionTest {
  test_class() async {
    await assertNoErrorsInCode('''
class C<T> {}
var t = C<int>;
''');

    final node = findNode.typeLiteral('C<int>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: SimpleIdentifier
      token: C
      staticElement: self::@class::C
      staticType: C<int>
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: SimpleIdentifier
            token: int
            staticElement: dart:core::@class::int
            staticType: null
          type: int
      rightBracket: >
    type: C<int>
  staticType: Type
''');
  }

  test_class_importPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C<T> {}
''');
    await assertNoErrorsInCode('''
import 'a.dart' as a;
var t = a.C<int>;
''');

    final node = findNode.typeLiteral('C<int>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: a
        staticElement: self::@prefix::a
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: C
        staticElement: package:test/a.dart::@class::C
        staticType: Type
      staticElement: package:test/a.dart::@class::C
      staticType: C<int>
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: SimpleIdentifier
            token: int
            staticElement: dart:core::@class::int
            staticType: null
          type: int
      rightBracket: >
    type: C<int>
  staticType: Type
''');
  }

  test_class_tooFewTypeArgs() async {
    await assertErrorsInCode('''
class C<T, U> {}
var t = C<int>;
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 26, 5),
    ]);

    final node = findNode.typeLiteral('C<int>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: SimpleIdentifier
      token: C
      staticElement: self::@class::C
      staticType: C<dynamic, dynamic>
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: SimpleIdentifier
            token: int
            staticElement: dart:core::@class::int
            staticType: null
          type: int
      rightBracket: >
    type: C<dynamic, dynamic>
  staticType: Type
''');
  }

  test_class_tooManyTypeArgs() async {
    await assertErrorsInCode('''
class C<T> {}
var t = C<int, int>;
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 23, 10),
    ]);

    final node = findNode.typeLiteral('C<int, int>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: SimpleIdentifier
      token: C
      staticElement: self::@class::C
      staticType: C<dynamic>
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: SimpleIdentifier
            token: int
            staticElement: dart:core::@class::int
            staticType: null
          type: int
        NamedType
          name: SimpleIdentifier
            token: int
            staticElement: dart:core::@class::int
            staticType: null
          type: int
      rightBracket: >
    type: C<dynamic>
  staticType: Type
''');
  }

  test_class_typeArgumentDoesNotMatchBound() async {
    await assertErrorsInCode('''
class C<T extends num> {}
var t = C<String>;
''', [
      error(CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, 36, 6,
          contextMessages: [message('/home/test/lib/test.dart', 34, 9)]),
    ]);

    final node = findNode.typeLiteral('C<String>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: SimpleIdentifier
      token: C
      staticElement: self::@class::C
      staticType: C<String>
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: SimpleIdentifier
            token: String
            staticElement: dart:core::@class::String
            staticType: null
          type: String
      rightBracket: >
    type: C<String>
  staticType: Type
''');
  }

  test_classAlias() async {
    await assertNoErrorsInCode('''
class C<T> {}
typedef CA<T> = C<T>;
var t = CA<int>;
''');

    final node = findNode.typeLiteral('CA<int>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: SimpleIdentifier
      token: CA
      staticElement: self::@typeAlias::CA
      staticType: C<int>
        alias: self::@typeAlias::CA
          typeArguments
            int
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: SimpleIdentifier
            token: int
            staticElement: dart:core::@class::int
            staticType: null
          type: int
      rightBracket: >
    type: C<int>
      alias: self::@typeAlias::CA
        typeArguments
          int
  staticType: Type
''');
  }

  test_classAlias_differentTypeArgCount() async {
    await assertNoErrorsInCode('''
class C<T, U> {}
typedef CA<T> = C<T, int>;
var t = CA<String>;
''');

    final node = findNode.typeLiteral('CA<String>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: SimpleIdentifier
      token: CA
      staticElement: self::@typeAlias::CA
      staticType: C<String, int>
        alias: self::@typeAlias::CA
          typeArguments
            String
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: SimpleIdentifier
            token: String
            staticElement: dart:core::@class::String
            staticType: null
          type: String
      rightBracket: >
    type: C<String, int>
      alias: self::@typeAlias::CA
        typeArguments
          String
  staticType: Type
''');
  }

  test_classAlias_functionTypeArg() async {
    await assertNoErrorsInCode('''
class C<T> {}
typedef CA<T> = C<T>;
var t = CA<void Function()>;
''');

    final node = findNode.typeLiteral('CA<void Function()>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: SimpleIdentifier
      token: CA
      staticElement: self::@typeAlias::CA
      staticType: C<void Function()>
        alias: self::@typeAlias::CA
          typeArguments
            void Function()
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        GenericFunctionType
          returnType: NamedType
            name: SimpleIdentifier
              token: void
              staticElement: <null>
              staticType: null
            type: void
          functionKeyword: Function
          parameters: FormalParameterList
            leftParenthesis: (
            rightParenthesis: )
          declaredElement: GenericFunctionTypeElement
            parameters
            returnType: void
            type: void Function()
          type: void Function()
      rightBracket: >
    type: C<void Function()>
      alias: self::@typeAlias::CA
        typeArguments
          void Function()
  staticType: Type
''');
  }

  test_classAlias_importPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C<T> {}
typedef CA<T> = C<T>;
''');
    await assertNoErrorsInCode('''
import 'a.dart' as a;
var t = a.CA<int>;
''');

    final node = findNode.typeLiteral('CA<int>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: a
        staticElement: self::@prefix::a
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: CA
        staticElement: package:test/a.dart::@typeAlias::CA
        staticType: Type
      staticElement: package:test/a.dart::@typeAlias::CA
      staticType: C<int>
        alias: package:test/a.dart::@typeAlias::CA
          typeArguments
            int
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: SimpleIdentifier
            token: int
            staticElement: dart:core::@class::int
            staticType: null
          type: int
      rightBracket: >
    type: C<int>
      alias: package:test/a.dart::@typeAlias::CA
        typeArguments
          int
  staticType: Type
''');
  }

  test_classAlias_typeArgumentDoesNotMatchBound() async {
    await assertErrorsInCode('''
class C<T> {}
typedef CA<T extends num> = C<T>;
var t = CA<String>;
''', [
      error(CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, 59, 6,
          contextMessages: [message('/home/test/lib/test.dart', 56, 10)]),
    ]);

    final node = findNode.typeLiteral('CA<String>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: SimpleIdentifier
      token: CA
      staticElement: self::@typeAlias::CA
      staticType: C<String>
        alias: self::@typeAlias::CA
          typeArguments
            String
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: SimpleIdentifier
            token: String
            staticElement: dart:core::@class::String
            staticType: null
          type: String
      rightBracket: >
    type: C<String>
      alias: self::@typeAlias::CA
        typeArguments
          String
  staticType: Type
''');
  }

  test_functionAlias() async {
    await assertNoErrorsInCode('''
typedef Fn<T> = void Function(T);
var t = Fn<int>;
''');

    final node = findNode.typeLiteral('Fn<int>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: SimpleIdentifier
      token: Fn
      staticElement: self::@typeAlias::Fn
      staticType: void Function(int)
        alias: self::@typeAlias::Fn
          typeArguments
            int
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: SimpleIdentifier
            token: int
            staticElement: dart:core::@class::int
            staticType: null
          type: int
      rightBracket: >
    type: void Function(int)
      alias: self::@typeAlias::Fn
        typeArguments
          int
  staticType: Type
''');
  }

  test_functionAlias_importPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
typedef Fn<T> = void Function(T);
''');
    await assertNoErrorsInCode('''
import 'a.dart' as a;
var t = a.Fn<int>;
''');

    final node = findNode.typeLiteral('Fn<int>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: a
        staticElement: self::@prefix::a
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: Fn
        staticElement: package:test/a.dart::@typeAlias::Fn
        staticType: Type
      staticElement: package:test/a.dart::@typeAlias::Fn
      staticType: void Function(int)
        alias: package:test/a.dart::@typeAlias::Fn
          typeArguments
            int
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: SimpleIdentifier
            token: int
            staticElement: dart:core::@class::int
            staticType: null
          type: int
      rightBracket: >
    type: void Function(int)
      alias: package:test/a.dart::@typeAlias::Fn
        typeArguments
          int
  staticType: Type
''');
  }

  test_functionAlias_targetOfMethodCall() async {
    await assertErrorsInCode('''
typedef Fn<T> = void Function(T);

void bar() {
  Fn<int>.foo();
}

extension E on Type {
  void foo() {}
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD_ON_FUNCTION_TYPE, 58, 3),
    ]);

    final node = findNode.typeLiteral('Fn<int>');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: SimpleIdentifier
      token: Fn
      staticElement: self::@typeAlias::Fn
      staticType: void Function(T)
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: SimpleIdentifier
            token: int
            staticElement: dart:core::@class::int
            staticType: null
          type: int
      rightBracket: >
    type: void Function(int)
      alias: self::@typeAlias::Fn
        typeArguments
          int
  staticType: Type
''');
  }

  test_functionAlias_targetOfMethodCall_importPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
typedef Fn<T> = void Function(T);
''');
    await assertErrorsInCode('''
import 'a.dart' as a;

void bar() {
  a.Fn<int>.foo();
}

extension E on Type {
  void foo() {}
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD_ON_FUNCTION_TYPE, 48, 3),
    ]);

    final node = findNode.typeLiteral('Fn<int>');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: a
        staticElement: self::@prefix::a
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: Fn
        staticElement: package:test/a.dart::@typeAlias::Fn
        staticType: null
      staticElement: package:test/a.dart::@typeAlias::Fn
      staticType: void Function(T)
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: SimpleIdentifier
            token: int
            staticElement: dart:core::@class::int
            staticType: null
          type: int
      rightBracket: >
    type: void Function(int)
      alias: package:test/a.dart::@typeAlias::Fn
        typeArguments
          int
  staticType: Type
''');
  }

  test_functionAlias_targetOfMethodCall_parenthesized() async {
    await assertNoErrorsInCode('''
typedef Fn<T> = void Function(T);

void bar() {
  (Fn<int>).foo();
}

extension E on Type {
  void foo() {}
}
''');

    final node = findNode.typeLiteral('Fn<int>');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: SimpleIdentifier
      token: Fn
      staticElement: self::@typeAlias::Fn
      staticType: void Function(int)
        alias: self::@typeAlias::Fn
          typeArguments
            int
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: SimpleIdentifier
            token: int
            staticElement: dart:core::@class::int
            staticType: null
          type: int
      rightBracket: >
    type: void Function(int)
      alias: self::@typeAlias::Fn
        typeArguments
          int
  staticType: Type
''');
  }

  test_functionAlias_targetOfPropertyAccess_getter() async {
    await assertErrorsInCode('''
typedef Fn<T> = void Function(T);

void bar() {
  Fn<int>.foo;
}

extension E on Type {
  int get foo => 1;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER_ON_FUNCTION_TYPE, 58, 3),
    ]);

    final node = findNode.typeLiteral('Fn<int>');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: SimpleIdentifier
      token: Fn
      staticElement: self::@typeAlias::Fn
      staticType: void Function(int)
        alias: self::@typeAlias::Fn
          typeArguments
            int
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: SimpleIdentifier
            token: int
            staticElement: dart:core::@class::int
            staticType: null
          type: int
      rightBracket: >
    type: void Function(int)
      alias: self::@typeAlias::Fn
        typeArguments
          int
  staticType: Type
''');
  }

  test_functionAlias_targetOfPropertyAccess_getter_parenthesized() async {
    await assertNoErrorsInCode('''
typedef Fn<T> = void Function(T);

void bar() {
  (Fn<int>).foo;
}

extension E on Type {
  int get foo => 1;
}
''');

    final node = findNode.typeLiteral('Fn<int>');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: SimpleIdentifier
      token: Fn
      staticElement: self::@typeAlias::Fn
      staticType: void Function(int)
        alias: self::@typeAlias::Fn
          typeArguments
            int
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: SimpleIdentifier
            token: int
            staticElement: dart:core::@class::int
            staticType: null
          type: int
      rightBracket: >
    type: void Function(int)
      alias: self::@typeAlias::Fn
        typeArguments
          int
  staticType: Type
''');
  }

  test_functionAlias_targetOfPropertyAccess_setter() async {
    await assertErrorsInCode('''
typedef Fn<T> = void Function(T);

void bar() {
  Fn<int>.foo = 7;
}

extension E on Type {
  set foo(int value) {}
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SETTER_ON_FUNCTION_TYPE, 58, 3),
    ]);

    final node = findNode.typeLiteral('Fn<int>');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: SimpleIdentifier
      token: Fn
      staticElement: self::@typeAlias::Fn
      staticType: void Function(int)
        alias: self::@typeAlias::Fn
          typeArguments
            int
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: SimpleIdentifier
            token: int
            staticElement: dart:core::@class::int
            staticType: null
          type: int
      rightBracket: >
    type: void Function(int)
      alias: self::@typeAlias::Fn
        typeArguments
          int
  staticType: Type
''');
  }

  test_functionAlias_targetOfPropertyAccess_setter_parenthesized() async {
    await assertNoErrorsInCode('''
typedef Fn<T> = void Function(T);

void bar() {
  (Fn<int>).foo = 7;
}

extension E on Type {
  set foo(int value) {}
}
''');

    final node = findNode.typeLiteral('Fn<int>');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: SimpleIdentifier
      token: Fn
      staticElement: self::@typeAlias::Fn
      staticType: void Function(int)
        alias: self::@typeAlias::Fn
          typeArguments
            int
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: SimpleIdentifier
            token: int
            staticElement: dart:core::@class::int
            staticType: null
          type: int
      rightBracket: >
    type: void Function(int)
      alias: self::@typeAlias::Fn
        typeArguments
          int
  staticType: Type
''');
  }

  test_functionAlias_tooFewTypeArgs() async {
    await assertErrorsInCode('''
typedef Fn<T, U> = void Function(T, U);
var t = Fn<int>;
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 50, 5),
    ]);

    final node = findNode.typeLiteral('Fn<int>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: SimpleIdentifier
      token: Fn
      staticElement: self::@typeAlias::Fn
      staticType: void Function(dynamic, dynamic)
        alias: self::@typeAlias::Fn
          typeArguments
            dynamic
            dynamic
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: SimpleIdentifier
            token: int
            staticElement: dart:core::@class::int
            staticType: null
          type: int
      rightBracket: >
    type: void Function(dynamic, dynamic)
      alias: self::@typeAlias::Fn
        typeArguments
          dynamic
          dynamic
  staticType: Type
''');
  }

  test_functionAlias_tooManyTypeArgs() async {
    await assertErrorsInCode('''
typedef Fn<T> = void Function(T);
var t = Fn<int, String>;
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 44, 13),
    ]);

    final node = findNode.typeLiteral('Fn<int, String>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: SimpleIdentifier
      token: Fn
      staticElement: self::@typeAlias::Fn
      staticType: void Function(dynamic)
        alias: self::@typeAlias::Fn
          typeArguments
            dynamic
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: SimpleIdentifier
            token: int
            staticElement: dart:core::@class::int
            staticType: null
          type: int
        NamedType
          name: SimpleIdentifier
            token: String
            staticElement: dart:core::@class::String
            staticType: null
          type: String
      rightBracket: >
    type: void Function(dynamic)
      alias: self::@typeAlias::Fn
        typeArguments
          dynamic
  staticType: Type
''');
  }

  test_functionAlias_typeArgumentDoesNotMatchBound() async {
    await assertErrorsInCode('''
typedef Fn<T extends num> = void Function(T);
var t = Fn<String>;
''', [
      error(CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, 57, 6,
          contextMessages: [message('/home/test/lib/test.dart', 54, 10)]),
    ]);

    final node = findNode.typeLiteral('Fn<String>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: SimpleIdentifier
      token: Fn
      staticElement: self::@typeAlias::Fn
      staticType: void Function(String)
        alias: self::@typeAlias::Fn
          typeArguments
            String
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: SimpleIdentifier
            token: String
            staticElement: dart:core::@class::String
            staticType: null
          type: String
      rightBracket: >
    type: void Function(String)
      alias: self::@typeAlias::Fn
        typeArguments
          String
  staticType: Type
''');
  }

  test_mixin() async {
    await assertNoErrorsInCode('''
mixin M<T> {}
var t = M<int>;
''');

    final node = findNode.typeLiteral('M<int>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: SimpleIdentifier
      token: M
      staticElement: self::@mixin::M
      staticType: M<int>
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: SimpleIdentifier
            token: int
            staticElement: dart:core::@class::int
            staticType: null
          type: int
      rightBracket: >
    type: M<int>
  staticType: Type
''');
  }

  test_typeVariableTypeAlias() async {
    await assertNoErrorsInCode('''
typedef T<E> = E;
var t = T<int>;
''');

    final node = findNode.typeLiteral('T<int>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: SimpleIdentifier
      token: T
      staticElement: self::@typeAlias::T
      staticType: int
        alias: self::@typeAlias::T
          typeArguments
            int
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: SimpleIdentifier
            token: int
            staticElement: dart:core::@class::int
            staticType: null
          type: int
      rightBracket: >
    type: int
      alias: self::@typeAlias::T
        typeArguments
          int
  staticType: Type
''');
  }

  test_typeVariableTypeAlias_functionTypeArgument() async {
    await assertNoErrorsInCode('''
typedef T<E> = E;
var t = T<void Function()>;
''');

    final node = findNode.typeLiteral('T<void Function()>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: SimpleIdentifier
      token: T
      staticElement: self::@typeAlias::T
      staticType: void Function()
        alias: self::@typeAlias::T
          typeArguments
            void Function()
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        GenericFunctionType
          returnType: NamedType
            name: SimpleIdentifier
              token: void
              staticElement: <null>
              staticType: null
            type: void
          functionKeyword: Function
          parameters: FormalParameterList
            leftParenthesis: (
            rightParenthesis: )
          declaredElement: GenericFunctionTypeElement
            parameters
            returnType: void
            type: void Function()
          type: void Function()
      rightBracket: >
    type: void Function()
      alias: self::@typeAlias::T
        typeArguments
          void Function()
  staticType: Type
''');
  }
}

@reflectiveTest
class TypeLiteralResolutionTest_WithoutConstructorTearoffs
    extends PubPackageResolutionTest with WithoutConstructorTearoffsMixin {
  test_class() async {
    await assertErrorsInCode('''
class C<T> {}
var t = C<int>;
''', [
      error(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 23, 5),
    ]);
  }

  test_class_importPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class C<T> {}
''');
    await assertErrorsInCode('''
import 'a.dart' as a;
var t = a.C<int>;
''', [
      error(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 33, 5),
    ]);
  }
}
