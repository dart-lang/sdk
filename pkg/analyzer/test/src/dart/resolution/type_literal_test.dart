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
    // defineReflectiveTests(UpdateNodeTextExpectations);
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
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: self::@class::C
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
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: self::@prefix::a
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: package:test/a.dart::@class::C
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
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: self::@class::C
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
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: self::@class::C
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
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: String
          element: dart:core::@class::String
          type: String
      rightBracket: >
    element: self::@class::C
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
    name: CA
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: self::@typeAlias::CA
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
    name: CA
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: String
          element: dart:core::@class::String
          type: String
      rightBracket: >
    element: self::@typeAlias::CA
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
    name: CA
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        GenericFunctionType
          returnType: NamedType
            name: void
            element: <null>
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
    element: self::@typeAlias::CA
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
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: self::@prefix::a
    name: CA
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: package:test/a.dart::@typeAlias::CA
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
    name: CA
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: String
          element: dart:core::@class::String
          type: String
      rightBracket: >
    element: self::@typeAlias::CA
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
    name: Fn
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: self::@typeAlias::Fn
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
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: self::@prefix::a
    name: Fn
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: package:test/a.dart::@typeAlias::Fn
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
    name: Fn
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: self::@typeAlias::Fn
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
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: self::@prefix::a
    name: Fn
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: package:test/a.dart::@typeAlias::Fn
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
    name: Fn
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: self::@typeAlias::Fn
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
    name: Fn
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: self::@typeAlias::Fn
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
    name: Fn
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: self::@typeAlias::Fn
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
    name: Fn
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: self::@typeAlias::Fn
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
    name: Fn
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: self::@typeAlias::Fn
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
    name: Fn
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: self::@typeAlias::Fn
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
    name: Fn
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
    element: self::@typeAlias::Fn
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
    name: Fn
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: String
          element: dart:core::@class::String
          type: String
      rightBracket: >
    element: self::@typeAlias::Fn
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
    name: M
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: self::@mixin::M
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
    name: T
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: self::@typeAlias::T
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
    name: T
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        GenericFunctionType
          returnType: NamedType
            name: void
            element: <null>
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
    element: self::@typeAlias::T
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
