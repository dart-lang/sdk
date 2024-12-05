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

    var node = findNode.typeLiteral('C<int>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::<fragment>::@class::int
          element2: dart:core::<fragment>::@class::int#element
          type: int
      rightBracket: >
    element: <testLibraryFragment>::@class::C
    element2: <testLibraryFragment>::@class::C#element
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

    var node = findNode.typeLiteral('C<int>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
      element2: <testLibraryFragment>::@prefix2::a
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::<fragment>::@class::int
          element2: dart:core::<fragment>::@class::int#element
          type: int
      rightBracket: >
    element: package:test/a.dart::<fragment>::@class::C
    element2: package:test/a.dart::<fragment>::@class::C#element
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

    var node = findNode.typeLiteral('C<int>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::<fragment>::@class::int
          element2: dart:core::<fragment>::@class::int#element
          type: int
      rightBracket: >
    element: <testLibraryFragment>::@class::C
    element2: <testLibraryFragment>::@class::C#element
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

    var node = findNode.typeLiteral('C<int, int>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::<fragment>::@class::int
          element2: dart:core::<fragment>::@class::int#element
          type: int
        NamedType
          name: int
          element: dart:core::<fragment>::@class::int
          element2: dart:core::<fragment>::@class::int#element
          type: int
      rightBracket: >
    element: <testLibraryFragment>::@class::C
    element2: <testLibraryFragment>::@class::C#element
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
          contextMessages: [message(testFile, 34, 9)]),
    ]);

    var node = findNode.typeLiteral('C<String>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: String
          element: dart:core::<fragment>::@class::String
          element2: dart:core::<fragment>::@class::String#element
          type: String
      rightBracket: >
    element: <testLibraryFragment>::@class::C
    element2: <testLibraryFragment>::@class::C#element
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

    var node = findNode.typeLiteral('CA<int>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: CA
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::<fragment>::@class::int
          element2: dart:core::<fragment>::@class::int#element
          type: int
      rightBracket: >
    element: <testLibraryFragment>::@typeAlias::CA
    element2: <testLibraryFragment>::@typeAlias::CA#element
    type: C<int>
      alias: <testLibraryFragment>::@typeAlias::CA
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

    var node = findNode.typeLiteral('CA<String>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: CA
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: String
          element: dart:core::<fragment>::@class::String
          element2: dart:core::<fragment>::@class::String#element
          type: String
      rightBracket: >
    element: <testLibraryFragment>::@typeAlias::CA
    element2: <testLibraryFragment>::@typeAlias::CA#element
    type: C<String, int>
      alias: <testLibraryFragment>::@typeAlias::CA
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

    var node = findNode.typeLiteral('CA<void Function()>;');
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
            element2: <null>
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
    element: <testLibraryFragment>::@typeAlias::CA
    element2: <testLibraryFragment>::@typeAlias::CA#element
    type: C<void Function()>
      alias: <testLibraryFragment>::@typeAlias::CA
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

    var node = findNode.typeLiteral('CA<int>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
      element2: <testLibraryFragment>::@prefix2::a
    name: CA
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::<fragment>::@class::int
          element2: dart:core::<fragment>::@class::int#element
          type: int
      rightBracket: >
    element: package:test/a.dart::<fragment>::@typeAlias::CA
    element2: package:test/a.dart::<fragment>::@typeAlias::CA#element
    type: C<int>
      alias: package:test/a.dart::<fragment>::@typeAlias::CA
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
          contextMessages: [message(testFile, 56, 10)]),
    ]);

    var node = findNode.typeLiteral('CA<String>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: CA
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: String
          element: dart:core::<fragment>::@class::String
          element2: dart:core::<fragment>::@class::String#element
          type: String
      rightBracket: >
    element: <testLibraryFragment>::@typeAlias::CA
    element2: <testLibraryFragment>::@typeAlias::CA#element
    type: C<String>
      alias: <testLibraryFragment>::@typeAlias::CA
        typeArguments
          String
  staticType: Type
''');
  }

  test_extensionType() async {
    await assertNoErrorsInCode('''
extension type A<T>(T it) {}
final v = A<int>;
''');

    var node = findNode.typeLiteral('A<int>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
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
    element: <testLibraryFragment>::@extensionType::A
    element2: <testLibraryFragment>::@extensionType::A#element
    type: A<int>
  staticType: Type
''');
  }

  test_extensionType_importPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
extension type A<T>(T it) {}
''');

    await assertNoErrorsInCode('''
import 'a.dart' as a;
var t = a.A<int>;
''');

    var node = findNode.typeLiteral('A<int>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
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
    element: package:test/a.dart::<fragment>::@extensionType::A
    element2: package:test/a.dart::<fragment>::@extensionType::A#element
    type: A<int>
  staticType: Type
''');
  }

  test_functionAlias() async {
    await assertNoErrorsInCode('''
typedef Fn<T> = void Function(T);
var t = Fn<int>;
''');

    var node = findNode.typeLiteral('Fn<int>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: Fn
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::<fragment>::@class::int
          element2: dart:core::<fragment>::@class::int#element
          type: int
      rightBracket: >
    element: <testLibraryFragment>::@typeAlias::Fn
    element2: <testLibraryFragment>::@typeAlias::Fn#element
    type: void Function(int)
      alias: <testLibraryFragment>::@typeAlias::Fn
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

    var node = findNode.typeLiteral('Fn<int>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
      element2: <testLibraryFragment>::@prefix2::a
    name: Fn
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::<fragment>::@class::int
          element2: dart:core::<fragment>::@class::int#element
          type: int
      rightBracket: >
    element: package:test/a.dart::<fragment>::@typeAlias::Fn
    element2: package:test/a.dart::<fragment>::@typeAlias::Fn#element
    type: void Function(int)
      alias: package:test/a.dart::<fragment>::@typeAlias::Fn
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

    var node = findNode.typeLiteral('Fn<int>');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: Fn
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::<fragment>::@class::int
          element2: dart:core::<fragment>::@class::int#element
          type: int
      rightBracket: >
    element: <testLibraryFragment>::@typeAlias::Fn
    element2: <testLibraryFragment>::@typeAlias::Fn#element
    type: void Function(int)
      alias: <testLibraryFragment>::@typeAlias::Fn
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

    var node = findNode.typeLiteral('Fn<int>');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: a
      period: .
      element: <testLibraryFragment>::@prefix::a
      element2: <testLibraryFragment>::@prefix2::a
    name: Fn
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::<fragment>::@class::int
          element2: dart:core::<fragment>::@class::int#element
          type: int
      rightBracket: >
    element: package:test/a.dart::<fragment>::@typeAlias::Fn
    element2: package:test/a.dart::<fragment>::@typeAlias::Fn#element
    type: void Function(int)
      alias: package:test/a.dart::<fragment>::@typeAlias::Fn
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

    var node = findNode.typeLiteral('Fn<int>');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: Fn
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::<fragment>::@class::int
          element2: dart:core::<fragment>::@class::int#element
          type: int
      rightBracket: >
    element: <testLibraryFragment>::@typeAlias::Fn
    element2: <testLibraryFragment>::@typeAlias::Fn#element
    type: void Function(int)
      alias: <testLibraryFragment>::@typeAlias::Fn
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

    var node = findNode.typeLiteral('Fn<int>');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: Fn
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::<fragment>::@class::int
          element2: dart:core::<fragment>::@class::int#element
          type: int
      rightBracket: >
    element: <testLibraryFragment>::@typeAlias::Fn
    element2: <testLibraryFragment>::@typeAlias::Fn#element
    type: void Function(int)
      alias: <testLibraryFragment>::@typeAlias::Fn
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

    var node = findNode.typeLiteral('Fn<int>');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: Fn
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::<fragment>::@class::int
          element2: dart:core::<fragment>::@class::int#element
          type: int
      rightBracket: >
    element: <testLibraryFragment>::@typeAlias::Fn
    element2: <testLibraryFragment>::@typeAlias::Fn#element
    type: void Function(int)
      alias: <testLibraryFragment>::@typeAlias::Fn
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

    var node = findNode.typeLiteral('Fn<int>');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: Fn
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::<fragment>::@class::int
          element2: dart:core::<fragment>::@class::int#element
          type: int
      rightBracket: >
    element: <testLibraryFragment>::@typeAlias::Fn
    element2: <testLibraryFragment>::@typeAlias::Fn#element
    type: void Function(int)
      alias: <testLibraryFragment>::@typeAlias::Fn
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

    var node = findNode.typeLiteral('Fn<int>');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: Fn
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::<fragment>::@class::int
          element2: dart:core::<fragment>::@class::int#element
          type: int
      rightBracket: >
    element: <testLibraryFragment>::@typeAlias::Fn
    element2: <testLibraryFragment>::@typeAlias::Fn#element
    type: void Function(int)
      alias: <testLibraryFragment>::@typeAlias::Fn
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

    var node = findNode.typeLiteral('Fn<int>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: Fn
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::<fragment>::@class::int
          element2: dart:core::<fragment>::@class::int#element
          type: int
      rightBracket: >
    element: <testLibraryFragment>::@typeAlias::Fn
    element2: <testLibraryFragment>::@typeAlias::Fn#element
    type: void Function(dynamic, dynamic)
      alias: <testLibraryFragment>::@typeAlias::Fn
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

    var node = findNode.typeLiteral('Fn<int, String>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: Fn
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
    element: <testLibraryFragment>::@typeAlias::Fn
    element2: <testLibraryFragment>::@typeAlias::Fn#element
    type: void Function(dynamic)
      alias: <testLibraryFragment>::@typeAlias::Fn
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
          contextMessages: [message(testFile, 54, 10)]),
    ]);

    var node = findNode.typeLiteral('Fn<String>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: Fn
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: String
          element: dart:core::<fragment>::@class::String
          element2: dart:core::<fragment>::@class::String#element
          type: String
      rightBracket: >
    element: <testLibraryFragment>::@typeAlias::Fn
    element2: <testLibraryFragment>::@typeAlias::Fn#element
    type: void Function(String)
      alias: <testLibraryFragment>::@typeAlias::Fn
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

    var node = findNode.typeLiteral('M<int>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: M
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::<fragment>::@class::int
          element2: dart:core::<fragment>::@class::int#element
          type: int
      rightBracket: >
    element: <testLibraryFragment>::@mixin::M
    element2: <testLibraryFragment>::@mixin::M#element
    type: M<int>
  staticType: Type
''');
  }

  test_typeVariableTypeAlias() async {
    await assertNoErrorsInCode('''
typedef T<E> = E;
var t = T<int>;
''');

    var node = findNode.typeLiteral('T<int>;');
    assertResolvedNodeText(node, r'''
TypeLiteral
  type: NamedType
    name: T
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::<fragment>::@class::int
          element2: dart:core::<fragment>::@class::int#element
          type: int
      rightBracket: >
    element: <testLibraryFragment>::@typeAlias::T
    element2: <testLibraryFragment>::@typeAlias::T#element
    type: int
      alias: <testLibraryFragment>::@typeAlias::T
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

    var node = findNode.typeLiteral('T<void Function()>;');
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
            element2: <null>
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
    element: <testLibraryFragment>::@typeAlias::T
    element2: <testLibraryFragment>::@typeAlias::T#element
    type: void Function()
      alias: <testLibraryFragment>::@typeAlias::T
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
