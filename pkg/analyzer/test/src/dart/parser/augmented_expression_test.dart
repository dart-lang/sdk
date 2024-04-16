// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AugmentedExpressionParserTest);
  });
}

@reflectiveTest
class AugmentedExpressionParserTest extends ParserDiagnosticsTest {
  test_class_constructor() {
    var parseResult = parseStringWithErrors(r'''
augment library 'test.dart';

augment class A {
  augment A(int a) {
    augmented(0);
  }
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: AugmentedInvocation
        augmentedKeyword: augmented
        arguments: ArgumentList
          leftParenthesis: (
          arguments
            IntegerLiteral
              literal: 0
          rightParenthesis: )
      semicolon: ;
  rightBracket: }
''');
  }

  test_class_field() {
    var parseResult = parseStringWithErrors(r'''
augment library 'test.dart';

augment class A {
  augment int foo = augmented + 1;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleBinaryExpression;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: AugmentedExpression
    augmentedKeyword: augmented
  operator: +
  rightOperand: IntegerLiteral
    literal: 1
''');
  }

  test_class_getter() {
    var parseResult = parseStringWithErrors(r'''
augment library 'test.dart';

augment class A {
  augment int get foo {
    return augmented;
  }
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ReturnStatement
      returnKeyword: return
      expression: AugmentedExpression
        augmentedKeyword: augmented
      semicolon: ;
  rightBracket: }
''');
  }

  test_class_method() {
    var parseResult = parseStringWithErrors(r'''
augment library 'test.dart';

augment class A {
  augment void foo<T>(T a) {
    augmented<int>(0);
  }
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: AugmentedInvocation
        augmentedKeyword: augmented
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
          rightBracket: >
        arguments: ArgumentList
          leftParenthesis: (
          arguments
            IntegerLiteral
              literal: 0
          rightParenthesis: )
      semicolon: ;
  rightBracket: }
''');
  }

  test_class_operatorBinary() {
    var parseResult = parseStringWithErrors(r'''
augment library 'test.dart';

augment class A {
  augment int operator+(int a) {
    return augmented + 1;
  }
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ReturnStatement
      returnKeyword: return
      expression: BinaryExpression
        leftOperand: AugmentedExpression
          augmentedKeyword: augmented
        operator: +
        rightOperand: IntegerLiteral
          literal: 1
      semicolon: ;
  rightBracket: }
''');
  }

  test_class_operatorIndexRead() {
    var parseResult = parseStringWithErrors(r'''
augment library 'test.dart';

augment class A {
  augment int operator[](int index) {
    return augmented[0];
  }
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ReturnStatement
      returnKeyword: return
      expression: IndexExpression
        target: AugmentedExpression
          augmentedKeyword: augmented
        leftBracket: [
        index: IntegerLiteral
          literal: 0
        rightBracket: ]
      semicolon: ;
  rightBracket: }
''');
  }

  test_class_operatorIndexWrite() {
    var parseResult = parseStringWithErrors(r'''
augment library 'test.dart';

augment class A {
  augment void operator[]=(int index, Object value) {
    augmented[0] = value;
  }
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: AssignmentExpression
        leftHandSide: IndexExpression
          target: AugmentedExpression
            augmentedKeyword: augmented
          leftBracket: [
          index: IntegerLiteral
            literal: 0
          rightBracket: ]
        operator: =
        rightHandSide: SimpleIdentifier
          token: value
      semicolon: ;
  rightBracket: }
''');
  }

  test_class_operatorPrefix() {
    var parseResult = parseStringWithErrors(r'''
augment library 'test.dart';

augment class A {
  augment int operator-() {
    return -augmented;
  }
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ReturnStatement
      returnKeyword: return
      expression: PrefixExpression
        operator: -
        operand: AugmentedExpression
          augmentedKeyword: augmented
      semicolon: ;
  rightBracket: }
''');
  }

  test_class_setter() {
    var parseResult = parseStringWithErrors(r'''
augment library 'test.dart';

augment class A {
  augment set foo(int _) {
    augmented = 0;
  }
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: AssignmentExpression
        leftHandSide: AugmentedExpression
          augmentedKeyword: augmented
        operator: =
        rightHandSide: IntegerLiteral
          literal: 0
      semicolon: ;
  rightBracket: }
''');
  }

  test_enum_getter() {
    var parseResult = parseStringWithErrors(r'''
augment library 'test.dart';

augment enum A {
  bar;

  augment int get foo {
    return augmented;
  }
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ReturnStatement
      returnKeyword: return
      expression: AugmentedExpression
        augmentedKeyword: augmented
      semicolon: ;
  rightBracket: }
''');
  }

  test_enum_method() {
    var parseResult = parseStringWithErrors(r'''
augment library 'test.dart';

augment enum A {
  bar;

  augment void foo<T>(T a) {
    augmented<int>(0);
  }
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: AugmentedInvocation
        augmentedKeyword: augmented
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
          rightBracket: >
        arguments: ArgumentList
          leftParenthesis: (
          arguments
            IntegerLiteral
              literal: 0
          rightParenthesis: )
      semicolon: ;
  rightBracket: }
''');
  }

  test_enum_setter() {
    var parseResult = parseStringWithErrors(r'''
augment library 'test.dart';

augment enum A {
  bar;

  augment set foo(int _) {
    augmented = 0;
  }
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: AssignmentExpression
        leftHandSide: AugmentedExpression
          augmentedKeyword: augmented
        operator: =
        rightHandSide: IntegerLiteral
          literal: 0
      semicolon: ;
  rightBracket: }
''');
  }

  test_extension_getter() {
    var parseResult = parseStringWithErrors(r'''
augment library 'test.dart';

augment extension A {
  augment int get foo {
    return augmented;
  }
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ReturnStatement
      returnKeyword: return
      expression: AugmentedExpression
        augmentedKeyword: augmented
      semicolon: ;
  rightBracket: }
''');
  }

  test_extension_method() {
    var parseResult = parseStringWithErrors(r'''
augment library 'test.dart';

augment extension A {
  augment void foo<T>(T a) {
    augmented<int>(0);
  }
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: AugmentedInvocation
        augmentedKeyword: augmented
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
          rightBracket: >
        arguments: ArgumentList
          leftParenthesis: (
          arguments
            IntegerLiteral
              literal: 0
          rightParenthesis: )
      semicolon: ;
  rightBracket: }
''');
  }

  test_extension_setter() {
    var parseResult = parseStringWithErrors(r'''
augment library 'test.dart';

augment extension A {
  augment set foo(int _) {
    augmented = 0;
  }
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: AssignmentExpression
        leftHandSide: AugmentedExpression
          augmentedKeyword: augmented
        operator: =
        rightHandSide: IntegerLiteral
          literal: 0
      semicolon: ;
  rightBracket: }
''');
  }

  test_extensionType_getter() {
    var parseResult = parseStringWithErrors(r'''
augment library 'test.dart';

augment extension type A(int it) {
  augment int get foo {
    return augmented;
  }
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ReturnStatement
      returnKeyword: return
      expression: AugmentedExpression
        augmentedKeyword: augmented
      semicolon: ;
  rightBracket: }
''');
  }

  test_extensionType_method() {
    var parseResult = parseStringWithErrors(r'''
augment library 'test.dart';

augment extension type A(int it) {
  augment void foo<T>(T a) {
    augmented<int>(0);
  }
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: AugmentedInvocation
        augmentedKeyword: augmented
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
          rightBracket: >
        arguments: ArgumentList
          leftParenthesis: (
          arguments
            IntegerLiteral
              literal: 0
          rightParenthesis: )
      semicolon: ;
  rightBracket: }
''');
  }

  test_extensionType_setter() {
    var parseResult = parseStringWithErrors(r'''
augment library 'test.dart';

augment extension type A(int it) {
  augment set foo(int _) {
    augmented = 0;
  }
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: AssignmentExpression
        leftHandSide: AugmentedExpression
          augmentedKeyword: augmented
        operator: =
        rightHandSide: IntegerLiteral
          literal: 0
      semicolon: ;
  rightBracket: }
''');
  }

  test_mixin_field() {
    var parseResult = parseStringWithErrors(r'''
augment library 'test.dart';

augment mixin A {
  augment int foo = augmented + 1;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleBinaryExpression;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: AugmentedExpression
    augmentedKeyword: augmented
  operator: +
  rightOperand: IntegerLiteral
    literal: 1
''');
  }

  test_mixin_getter() {
    var parseResult = parseStringWithErrors(r'''
augment library 'test.dart';

augment mixin A {
  augment int get foo {
    return augmented;
  }
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ReturnStatement
      returnKeyword: return
      expression: AugmentedExpression
        augmentedKeyword: augmented
      semicolon: ;
  rightBracket: }
''');
  }

  test_mixin_method() {
    var parseResult = parseStringWithErrors(r'''
augment library 'test.dart';

augment mixin A {
  augment void foo<T>(T a) {
    augmented<int>(0);
  }
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: AugmentedInvocation
        augmentedKeyword: augmented
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
          rightBracket: >
        arguments: ArgumentList
          leftParenthesis: (
          arguments
            IntegerLiteral
              literal: 0
          rightParenthesis: )
      semicolon: ;
  rightBracket: }
''');
  }

  test_mixin_setter() {
    var parseResult = parseStringWithErrors(r'''
augment library 'test.dart';

augment mixin A {
  augment set foo(int _) {
    augmented = 0;
  }
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: AssignmentExpression
        leftHandSide: AugmentedExpression
          augmentedKeyword: augmented
        operator: =
        rightHandSide: IntegerLiteral
          literal: 0
      semicolon: ;
  rightBracket: }
''');
  }

  test_topLevel_function() {
    var parseResult = parseStringWithErrors(r'''
augment library 'test.dart';

augment void foo<T>(T a) {
  augmented<int>(0);
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: AugmentedInvocation
        augmentedKeyword: augmented
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
          rightBracket: >
        arguments: ArgumentList
          leftParenthesis: (
          arguments
            IntegerLiteral
              literal: 0
          rightParenthesis: )
      semicolon: ;
  rightBracket: }
''');
  }

  test_topLevel_getter() {
    var parseResult = parseStringWithErrors(r'''
augment library 'test.dart';

augment int get foo {
  return augmented;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ReturnStatement
      returnKeyword: return
      expression: AugmentedExpression
        augmentedKeyword: augmented
      semicolon: ;
  rightBracket: }
''');
  }

  test_topLevel_setter() {
    var parseResult = parseStringWithErrors(r'''
augment library 'test.dart';

augment set foo(int _) {
  augmented = 0;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: AssignmentExpression
        leftHandSide: AugmentedExpression
          augmentedKeyword: augmented
        operator: =
        rightHandSide: IntegerLiteral
          literal: 0
      semicolon: ;
  rightBracket: }
''');
  }

  test_topLevel_variable() {
    var parseResult = parseStringWithErrors(r'''
augment library 'test.dart';

augment int foo = augmented + 1;
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleBinaryExpression;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: AugmentedExpression
    augmentedKeyword: augmented
  operator: +
  rightOperand: IntegerLiteral
    literal: 1
''');
  }
}
