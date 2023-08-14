// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(WrongNumberOfTypeArgumentsExtensionTest);
  });
}

@reflectiveTest
class WrongNumberOfTypeArgumentsExtensionTest extends PubPackageResolutionTest {
  test_notGeneric() async {
    await assertErrorsInCode(r'''
extension E on int {
  void foo() {}
}

void f() {
  E<int>(0).foo();
}
''', [
      error(
          CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_EXTENSION, 54, 5),
    ]);

    final node = findNode.extensionOverride('E<int>');
    assertResolvedNodeText(node, r'''
ExtensionOverride
  name: E
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
    arguments
      IntegerLiteral
        literal: 0
        parameter: <null>
        staticType: int
    rightParenthesis: )
  element: self::@extension::E
  extendedType: int
  staticType: null
''');
  }

  test_tooFew() async {
    await assertErrorsInCode(r'''
extension E<S, T> on int {
  void foo() {}
}

void f() {
  E<bool>(0).foo();
}
''', [
      error(
          CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_EXTENSION, 60, 6),
    ]);

    final node = findNode.extensionOverride('E<bool>');
    assertResolvedNodeText(node, r'''
ExtensionOverride
  name: E
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: bool
        element: dart:core::@class::bool
        type: bool
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <null>
        staticType: int
    rightParenthesis: )
  element: self::@extension::E
  extendedType: int
  staticType: null
  typeArgumentTypes
    dynamic
    dynamic
''');
  }

  test_tooMany() async {
    await assertErrorsInCode(r'''
extension E<T> on int {
  void foo() {}
}

void f() {
  E<bool, int>(0).foo();
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_EXTENSION, 57,
          11),
    ]);

    final node = findNode.extensionOverride('E<bool, int>');
    assertResolvedNodeText(node, r'''
ExtensionOverride
  name: E
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: bool
        element: dart:core::@class::bool
        type: bool
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <null>
        staticType: int
    rightParenthesis: )
  element: self::@extension::E
  extendedType: int
  staticType: null
  typeArgumentTypes
    dynamic
''');
  }
}
