// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/dart/resolution/node_text_expectations.dart';
import '../src/diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FunctionReferenceParserTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

/// Tests exercising the fasta parser's handling of generic instantiations.
@reflectiveTest
class FunctionReferenceParserTest extends ParserDiagnosticsTest {
  void test_feature_disabled() {
    var parseResult = parseTestCodeWithDiagnostics(
      r'''void f() { f<a, b>; }
//          ^^^^^^
// [diag.experimentNotEnabled] This requires the 'constructor-tearoffs' language feature to be enabled.''',
      featureSet: FeatureSet.fromEnableFlags2(
        sdkLanguageVersion: Version.parse('2.13.0'),
        flags: [],
      ),
    );

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
FunctionReference
  function2: SimpleIdentifier
    token: f
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: a
      NamedType
        name: b
    rightBracket: >
''');
  }

  void test_followingToken_accepted_closeBrace() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = {f<a, b>};
''');
    var node = parseResult.findNode.singleSetOrMapLiteral.elements2[0];
    assertParsedNodeText(node, r'''
FunctionReference
  function2: SimpleIdentifier
    token: f
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: a
      NamedType
        name: b
    rightBracket: >
''');
  }

  void test_followingToken_accepted_closeBracket() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = [f<a, b>];
''');
    var node = parseResult.findNode.singleListLiteral.elements2[0];
    assertParsedNodeText(node, r'''
FunctionReference
  function2: SimpleIdentifier
    token: f
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: a
      NamedType
        name: b
    rightBracket: >
''');
  }

  void test_followingToken_accepted_closeParen() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = g(f<a, b>);
''');
    var node =
        parseResult.findNode.singleMethodInvocation.argumentList.arguments2[0];
    assertParsedNodeText(node, r'''
FunctionReference
  function2: SimpleIdentifier
    token: f
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: a
      NamedType
        name: b
    rightBracket: >
''');
  }

  void test_followingToken_accepted_colon() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = {f<a, b>: null};
''');
    var node = parseResult.findNode.mapLiteralEntry('null').key2;
    assertParsedNodeText(node, r'''
FunctionReference
  function2: SimpleIdentifier
    token: f
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: a
      NamedType
        name: b
    rightBracket: >
''');
  }

  void test_followingToken_accepted_comma() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = [f<a, b>, null];
''');
    var node = parseResult.findNode.singleListLiteral.elements2[0];
    assertParsedNodeText(node, r'''
FunctionReference
  function2: SimpleIdentifier
    token: f
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: a
      NamedType
        name: b
    rightBracket: >
''');
  }

  void test_followingToken_accepted_equals() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = f<a, b> == null;
''');
    var node = parseResult.findNode.singleBinaryOperatorInvocation.leftOperand;
    assertParsedNodeText(node, r'''
FunctionReference
  function2: SimpleIdentifier
    token: f
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: a
      NamedType
        name: b
    rightBracket: >
''');
  }

  void test_followingToken_accepted_not_equals() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = f<a, b> != null;
''');
    var node = parseResult.findNode.singleBinaryOperatorInvocation.leftOperand;
    assertParsedNodeText(node, r'''
FunctionReference
  function2: SimpleIdentifier
    token: f
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: a
      NamedType
        name: b
    rightBracket: >
''');
  }

  void test_followingToken_accepted_openParen() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = f<a, b>();
''');
    var node = parseResult.findNode.singleMethodInvocation;
    assertParsedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: a
      NamedType
        name: b
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
''');
  }

  void test_followingToken_accepted_period_methodInvocation() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = f<a, b>.toString();
''');
    var node = parseResult.findNode.singleConstructorInvocation;
    assertParsedNodeText(node, r'''
ConstructorInvocation
  constructorReference: ConstructorReference2
    typeReference: ConstructorTypeReference
      name: f
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: a
          NamedType
            name: b
        rightBracket: >
    selector: ConstructorSelector
      period: .
      name2: toString
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
V1: InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: f
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: a
          NamedType
            name: b
        rightBracket: >
    period: .
    name: SimpleIdentifier
      token: toString
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
''');
  }

  void test_followingToken_accepted_period_methodInvocation_generic() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = f<a, b>.foo<c>();
''');
    var node = parseResult.findNode.singleMethodInvocation.target2!;
    assertParsedNodeText(node, r'''
FunctionReference
  function2: SimpleIdentifier
    token: f
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: a
      NamedType
        name: b
    rightBracket: >
''');
  }

  void test_followingToken_accepted_period_propertyAccess() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = f<a, b>.hashCode;
''');
    var node = parseResult.findNode.singlePropertyAccess.target2!;
    assertParsedNodeText(node, r'''
FunctionReference
  function2: SimpleIdentifier
    token: f
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: a
      NamedType
        name: b
    rightBracket: >
''');
  }

  void test_followingToken_accepted_semicolon() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  f<a, b>;
}
''');
    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
FunctionReference
  function2: SimpleIdentifier
    token: f
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: a
      NamedType
        name: b
    rightBracket: >
''');
  }

  void test_followingToken_rejected_ampersand() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = f(a<b,c>&d);
//              ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleMethodInvocation;
    assertParsedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
  argumentList: ArgumentList
    leftParenthesis: (
    arguments2
      BinaryOperatorInvocation
        leftOperand: SimpleIdentifier
          token: a
        operator: <
        rightOperand: SimpleIdentifier
          token: b
        binaryOperator: lessThan
      BinaryOperatorInvocation
        leftOperand: SimpleIdentifier
          token: c
        operator: >
        rightOperand: BinaryOperatorInvocation
          leftOperand: SimpleIdentifier
            token: <empty> <synthetic>
          operator: &
          rightOperand: SimpleIdentifier
            token: d
          binaryOperator: bitwiseAnd
        binaryOperator: greaterThan
    arguments(v1)
      BinaryExpression
        leftOperand: SimpleIdentifier
          token: a
        operator: <
        rightOperand: SimpleIdentifier
          token: b
      BinaryExpression
        leftOperand: SimpleIdentifier
          token: c
        operator: >
        rightOperand: BinaryExpression
          leftOperand: SimpleIdentifier
            token: <empty> <synthetic>
          operator: &
          rightOperand: SimpleIdentifier
            token: d
    rightParenthesis: )
''');
  }

  void test_followingToken_rejected_as() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = f(a < b, c > as);
''');
    var node = parseResult.findNode.singleMethodInvocation;
    assertParsedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
  argumentList: ArgumentList
    leftParenthesis: (
    arguments2
      BinaryOperatorInvocation
        leftOperand: SimpleIdentifier
          token: a
        operator: <
        rightOperand: SimpleIdentifier
          token: b
        binaryOperator: lessThan
      BinaryOperatorInvocation
        leftOperand: SimpleIdentifier
          token: c
        operator: >
        rightOperand: SimpleIdentifier
          token: as
        binaryOperator: greaterThan
    arguments(v1)
      BinaryExpression
        leftOperand: SimpleIdentifier
          token: a
        operator: <
        rightOperand: SimpleIdentifier
          token: b
      BinaryExpression
        leftOperand: SimpleIdentifier
          token: c
        operator: >
        rightOperand: SimpleIdentifier
          token: as
    rightParenthesis: )
''');
  }

  void test_followingToken_rejected_asterisk() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = f(a<b,c>*d);
//              ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleMethodInvocation;
    assertParsedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
  argumentList: ArgumentList
    leftParenthesis: (
    arguments2
      BinaryOperatorInvocation
        leftOperand: SimpleIdentifier
          token: a
        operator: <
        rightOperand: SimpleIdentifier
          token: b
        binaryOperator: lessThan
      BinaryOperatorInvocation
        leftOperand: SimpleIdentifier
          token: c
        operator: >
        rightOperand: BinaryOperatorInvocation
          leftOperand: SimpleIdentifier
            token: <empty> <synthetic>
          operator: *
          rightOperand: SimpleIdentifier
            token: d
          binaryOperator: multiply
        binaryOperator: greaterThan
    arguments(v1)
      BinaryExpression
        leftOperand: SimpleIdentifier
          token: a
        operator: <
        rightOperand: SimpleIdentifier
          token: b
      BinaryExpression
        leftOperand: SimpleIdentifier
          token: c
        operator: >
        rightOperand: BinaryExpression
          leftOperand: SimpleIdentifier
            token: <empty> <synthetic>
          operator: *
          rightOperand: SimpleIdentifier
            token: d
    rightParenthesis: )
''');
  }

  void test_followingToken_rejected_bang_openBracket() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = f(a < b, c > ![d]);
''');
    var node = parseResult.findNode.singleMethodInvocation;
    assertParsedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
  argumentList: ArgumentList
    leftParenthesis: (
    arguments2
      BinaryOperatorInvocation
        leftOperand: SimpleIdentifier
          token: a
        operator: <
        rightOperand: SimpleIdentifier
          token: b
        binaryOperator: lessThan
      BinaryOperatorInvocation
        leftOperand: SimpleIdentifier
          token: c
        operator: >
        rightOperand: LogicalNot
          operator: !
          operand: ListLiteral
            leftBracket: [
            elements2
              SimpleIdentifier
                token: d
            rightBracket: ]
        binaryOperator: greaterThan
    arguments(v1)
      BinaryExpression
        leftOperand: SimpleIdentifier
          token: a
        operator: <
        rightOperand: SimpleIdentifier
          token: b
      BinaryExpression
        leftOperand: SimpleIdentifier
          token: c
        operator: >
        rightOperand: PrefixExpression
          operator: !
          operand: ListLiteral
            leftBracket: [
            elements
              SimpleIdentifier
                token: d
            rightBracket: ]
    rightParenthesis: )
''');
  }

  void test_followingToken_rejected_bang_paren() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = f(a < b, c > !(d));
''');
    var node = parseResult.findNode.singleMethodInvocation;
    assertParsedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
  argumentList: ArgumentList
    leftParenthesis: (
    arguments2
      BinaryOperatorInvocation
        leftOperand: SimpleIdentifier
          token: a
        operator: <
        rightOperand: SimpleIdentifier
          token: b
        binaryOperator: lessThan
      BinaryOperatorInvocation
        leftOperand: SimpleIdentifier
          token: c
        operator: >
        rightOperand: LogicalNot
          operator: !
          operand: ParenthesizedExpression
            leftParenthesis: (
            expression2: SimpleIdentifier
              token: d
            rightParenthesis: )
        binaryOperator: greaterThan
    arguments(v1)
      BinaryExpression
        leftOperand: SimpleIdentifier
          token: a
        operator: <
        rightOperand: SimpleIdentifier
          token: b
      BinaryExpression
        leftOperand: SimpleIdentifier
          token: c
        operator: >
        rightOperand: PrefixExpression
          operator: !
          operand: ParenthesizedExpression
            leftParenthesis: (
            expression: SimpleIdentifier
              token: d
            rightParenthesis: )
    rightParenthesis: )
''');
  }

  void test_followingToken_rejected_bar() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = f(a<b,c>|d);
//              ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleMethodInvocation;
    assertParsedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
  argumentList: ArgumentList
    leftParenthesis: (
    arguments2
      BinaryOperatorInvocation
        leftOperand: SimpleIdentifier
          token: a
        operator: <
        rightOperand: SimpleIdentifier
          token: b
        binaryOperator: lessThan
      BinaryOperatorInvocation
        leftOperand: SimpleIdentifier
          token: c
        operator: >
        rightOperand: BinaryOperatorInvocation
          leftOperand: SimpleIdentifier
            token: <empty> <synthetic>
          operator: |
          rightOperand: SimpleIdentifier
            token: d
          binaryOperator: bitwiseOr
        binaryOperator: greaterThan
    arguments(v1)
      BinaryExpression
        leftOperand: SimpleIdentifier
          token: a
        operator: <
        rightOperand: SimpleIdentifier
          token: b
      BinaryExpression
        leftOperand: SimpleIdentifier
          token: c
        operator: >
        rightOperand: BinaryExpression
          leftOperand: SimpleIdentifier
            token: <empty> <synthetic>
          operator: |
          rightOperand: SimpleIdentifier
            token: d
    rightParenthesis: )
''');
  }

  void test_followingToken_rejected_caret() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = f(a<b,c>^d);
//              ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleMethodInvocation;
    assertParsedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
  argumentList: ArgumentList
    leftParenthesis: (
    arguments2
      BinaryOperatorInvocation
        leftOperand: SimpleIdentifier
          token: a
        operator: <
        rightOperand: SimpleIdentifier
          token: b
        binaryOperator: lessThan
      BinaryOperatorInvocation
        leftOperand: SimpleIdentifier
          token: c
        operator: >
        rightOperand: BinaryOperatorInvocation
          leftOperand: SimpleIdentifier
            token: <empty> <synthetic>
          operator: ^
          rightOperand: SimpleIdentifier
            token: d
          binaryOperator: bitwiseXor
        binaryOperator: greaterThan
    arguments(v1)
      BinaryExpression
        leftOperand: SimpleIdentifier
          token: a
        operator: <
        rightOperand: SimpleIdentifier
          token: b
      BinaryExpression
        leftOperand: SimpleIdentifier
          token: c
        operator: >
        rightOperand: BinaryExpression
          leftOperand: SimpleIdentifier
            token: <empty> <synthetic>
          operator: ^
          rightOperand: SimpleIdentifier
            token: d
    rightParenthesis: )
''');
  }

  void test_followingToken_rejected_is() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = f(a<b,c> is int);
//               ^^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleMethodInvocation;
    assertParsedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
  argumentList: ArgumentList
    leftParenthesis: (
    arguments2
      BinaryOperatorInvocation
        leftOperand: SimpleIdentifier
          token: a
        operator: <
        rightOperand: SimpleIdentifier
          token: b
        binaryOperator: lessThan
      IsExpression
        expression2: BinaryOperatorInvocation
          leftOperand: SimpleIdentifier
            token: c
          operator: >
          rightOperand: SimpleIdentifier
            token: <empty> <synthetic>
          binaryOperator: greaterThan
        expression(v1): BinaryExpression
          leftOperand: SimpleIdentifier
            token: c
          operator: >
          rightOperand: SimpleIdentifier
            token: <empty> <synthetic>
        isOperator: is
        type: NamedType
          name: int
    arguments(v1)
      BinaryExpression
        leftOperand: SimpleIdentifier
          token: a
        operator: <
        rightOperand: SimpleIdentifier
          token: b
      IsExpression
        expression: BinaryExpression
          leftOperand: SimpleIdentifier
            token: c
          operator: >
          rightOperand: SimpleIdentifier
            token: <empty> <synthetic>
        isOperator: is
        type: NamedType
          name: int
    rightParenthesis: )
''');
  }

  void test_followingToken_rejected_lessThan() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = f<a><b>;
//         ^
// [diag.equalityCannotBeEqualityOperand] A comparison expression can't be an operand of another comparison expression.
//             ^
// [diag.expectedToken] Expected to find '['.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer2!;
    assertParsedNodeText(node, r'''
BinaryOperatorInvocation
  leftOperand: BinaryOperatorInvocation
    leftOperand: SimpleIdentifier
      token: f
    operator: <
    rightOperand: SimpleIdentifier
      token: a
    binaryOperator: lessThan
  operator: >
  rightOperand: ListLiteral
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: b
      rightBracket: >
    leftBracket: [ <synthetic>
    rightBracket: ] <synthetic>
  binaryOperator: greaterThan
V1: BinaryExpression
  leftOperand: BinaryExpression
    leftOperand: SimpleIdentifier
      token: f
    operator: <
    rightOperand: SimpleIdentifier
      token: a
  operator: >
  rightOperand: ListLiteral
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: b
      rightBracket: >
    leftBracket: [ <synthetic>
    rightBracket: ] <synthetic>
''');
  }

  void test_followingToken_rejected_minus() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = f(a < b, c > -d);
''');
    var node = parseResult.findNode.singleMethodInvocation;
    assertParsedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
  argumentList: ArgumentList
    leftParenthesis: (
    arguments2
      BinaryOperatorInvocation
        leftOperand: SimpleIdentifier
          token: a
        operator: <
        rightOperand: SimpleIdentifier
          token: b
        binaryOperator: lessThan
      BinaryOperatorInvocation
        leftOperand: SimpleIdentifier
          token: c
        operator: >
        rightOperand: UnaryOperatorInvocation
          operator: -
          operand: SimpleIdentifier
            token: d
          unaryOperator: negate
        binaryOperator: greaterThan
    arguments(v1)
      BinaryExpression
        leftOperand: SimpleIdentifier
          token: a
        operator: <
        rightOperand: SimpleIdentifier
          token: b
      BinaryExpression
        leftOperand: SimpleIdentifier
          token: c
        operator: >
        rightOperand: PrefixExpression
          operator: -
          operand: SimpleIdentifier
            token: d
    rightParenthesis: )
''');
  }

  void test_followingToken_rejected_openBracket() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = f(a < b, c > [d]);
''');
    var node = parseResult.findNode.singleMethodInvocation;
    assertParsedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
  argumentList: ArgumentList
    leftParenthesis: (
    arguments2
      BinaryOperatorInvocation
        leftOperand: SimpleIdentifier
          token: a
        operator: <
        rightOperand: SimpleIdentifier
          token: b
        binaryOperator: lessThan
      BinaryOperatorInvocation
        leftOperand: SimpleIdentifier
          token: c
        operator: >
        rightOperand: ListLiteral
          leftBracket: [
          elements2
            SimpleIdentifier
              token: d
          rightBracket: ]
        binaryOperator: greaterThan
    arguments(v1)
      BinaryExpression
        leftOperand: SimpleIdentifier
          token: a
        operator: <
        rightOperand: SimpleIdentifier
          token: b
      BinaryExpression
        leftOperand: SimpleIdentifier
          token: c
        operator: >
        rightOperand: ListLiteral
          leftBracket: [
          elements
            SimpleIdentifier
              token: d
          rightBracket: ]
    rightParenthesis: )
''');
  }

  void test_followingToken_rejected_openBracket_error() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = f(a<b,c>[d]>e);
//                 ^
// [diag.equalityCannotBeEqualityOperand] A comparison expression can't be an operand of another comparison expression.
''');
    var node = parseResult.findNode.singleMethodInvocation;
    assertParsedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
  argumentList: ArgumentList
    leftParenthesis: (
    arguments2
      BinaryOperatorInvocation
        leftOperand: SimpleIdentifier
          token: a
        operator: <
        rightOperand: SimpleIdentifier
          token: b
        binaryOperator: lessThan
      BinaryOperatorInvocation
        leftOperand: BinaryOperatorInvocation
          leftOperand: SimpleIdentifier
            token: c
          operator: >
          rightOperand: ListLiteral
            leftBracket: [
            elements2
              SimpleIdentifier
                token: d
            rightBracket: ]
          binaryOperator: greaterThan
        operator: >
        rightOperand: SimpleIdentifier
          token: e
        binaryOperator: greaterThan
    arguments(v1)
      BinaryExpression
        leftOperand: SimpleIdentifier
          token: a
        operator: <
        rightOperand: SimpleIdentifier
          token: b
      BinaryExpression
        leftOperand: BinaryExpression
          leftOperand: SimpleIdentifier
            token: c
          operator: >
          rightOperand: ListLiteral
            leftBracket: [
            elements
              SimpleIdentifier
                token: d
            rightBracket: ]
        operator: >
        rightOperand: SimpleIdentifier
          token: e
    rightParenthesis: )
''');
  }

  void test_followingToken_rejected_openBracket_unambiguous() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = f(a < b, c > [d, e]);
''');
    var node = parseResult.findNode.singleMethodInvocation;
    assertParsedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
  argumentList: ArgumentList
    leftParenthesis: (
    arguments2
      BinaryOperatorInvocation
        leftOperand: SimpleIdentifier
          token: a
        operator: <
        rightOperand: SimpleIdentifier
          token: b
        binaryOperator: lessThan
      BinaryOperatorInvocation
        leftOperand: SimpleIdentifier
          token: c
        operator: >
        rightOperand: ListLiteral
          leftBracket: [
          elements2
            SimpleIdentifier
              token: d
            SimpleIdentifier
              token: e
          rightBracket: ]
        binaryOperator: greaterThan
    arguments(v1)
      BinaryExpression
        leftOperand: SimpleIdentifier
          token: a
        operator: <
        rightOperand: SimpleIdentifier
          token: b
      BinaryExpression
        leftOperand: SimpleIdentifier
          token: c
        operator: >
        rightOperand: ListLiteral
          leftBracket: [
          elements
            SimpleIdentifier
              token: d
            SimpleIdentifier
              token: e
          rightBracket: ]
    rightParenthesis: )
''');
  }

  void test_followingToken_rejected_percent() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = f(a<b,c>%d);
//              ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleMethodInvocation;
    assertParsedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
  argumentList: ArgumentList
    leftParenthesis: (
    arguments2
      BinaryOperatorInvocation
        leftOperand: SimpleIdentifier
          token: a
        operator: <
        rightOperand: SimpleIdentifier
          token: b
        binaryOperator: lessThan
      BinaryOperatorInvocation
        leftOperand: SimpleIdentifier
          token: c
        operator: >
        rightOperand: BinaryOperatorInvocation
          leftOperand: SimpleIdentifier
            token: <empty> <synthetic>
          operator: %
          rightOperand: SimpleIdentifier
            token: d
          binaryOperator: modulo
        binaryOperator: greaterThan
    arguments(v1)
      BinaryExpression
        leftOperand: SimpleIdentifier
          token: a
        operator: <
        rightOperand: SimpleIdentifier
          token: b
      BinaryExpression
        leftOperand: SimpleIdentifier
          token: c
        operator: >
        rightOperand: BinaryExpression
          leftOperand: SimpleIdentifier
            token: <empty> <synthetic>
          operator: %
          rightOperand: SimpleIdentifier
            token: d
    rightParenthesis: )
''');
  }

  void test_followingToken_rejected_period_period() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = f(a<b,c>..toString());
//              ^^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.methodInvocation('f(');
    assertParsedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
  argumentList: ArgumentList
    leftParenthesis: (
    arguments2
      BinaryOperatorInvocation
        leftOperand: SimpleIdentifier
          token: a
        operator: <
        rightOperand: SimpleIdentifier
          token: b
        binaryOperator: lessThan
      CascadeExpression
        target2: BinaryOperatorInvocation
          leftOperand: SimpleIdentifier
            token: c
          operator: >
          rightOperand: SimpleIdentifier
            token: <empty> <synthetic>
          binaryOperator: greaterThan
        target(v1): BinaryExpression
          leftOperand: SimpleIdentifier
            token: c
          operator: >
          rightOperand: SimpleIdentifier
            token: <empty> <synthetic>
        sections
          CascadeSection
            body: MethodInvocation
              operator: ..
              methodName: SimpleIdentifier
                token: toString
              argumentList: ArgumentList
                leftParenthesis: (
                rightParenthesis: )
        cascadeSections
          MethodInvocation
            operator: ..
            methodName: SimpleIdentifier
              token: toString
            argumentList: ArgumentList
              leftParenthesis: (
              rightParenthesis: )
    arguments(v1)
      BinaryExpression
        leftOperand: SimpleIdentifier
          token: a
        operator: <
        rightOperand: SimpleIdentifier
          token: b
      CascadeExpression
        target: BinaryExpression
          leftOperand: SimpleIdentifier
            token: c
          operator: >
          rightOperand: SimpleIdentifier
            token: <empty> <synthetic>
        cascadeSections
          MethodInvocation
            operator: ..
            methodName: SimpleIdentifier
              token: toString
            argumentList: ArgumentList
              leftParenthesis: (
              rightParenthesis: )
    rightParenthesis: )
''');
  }

  void test_followingToken_rejected_plus() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = f(a<b,c>+d);
//              ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleMethodInvocation;
    assertParsedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
  argumentList: ArgumentList
    leftParenthesis: (
    arguments2
      BinaryOperatorInvocation
        leftOperand: SimpleIdentifier
          token: a
        operator: <
        rightOperand: SimpleIdentifier
          token: b
        binaryOperator: lessThan
      BinaryOperatorInvocation
        leftOperand: SimpleIdentifier
          token: c
        operator: >
        rightOperand: BinaryOperatorInvocation
          leftOperand: SimpleIdentifier
            token: <empty> <synthetic>
          operator: +
          rightOperand: SimpleIdentifier
            token: d
          binaryOperator: add
        binaryOperator: greaterThan
    arguments(v1)
      BinaryExpression
        leftOperand: SimpleIdentifier
          token: a
        operator: <
        rightOperand: SimpleIdentifier
          token: b
      BinaryExpression
        leftOperand: SimpleIdentifier
          token: c
        operator: >
        rightOperand: BinaryExpression
          leftOperand: SimpleIdentifier
            token: <empty> <synthetic>
          operator: +
          rightOperand: SimpleIdentifier
            token: d
    rightParenthesis: )
''');
  }

  void test_followingToken_rejected_question() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = f(a<b,c> ? null : null);
//               ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleMethodInvocation;
    assertParsedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
  argumentList: ArgumentList
    leftParenthesis: (
    arguments2
      BinaryOperatorInvocation
        leftOperand: SimpleIdentifier
          token: a
        operator: <
        rightOperand: SimpleIdentifier
          token: b
        binaryOperator: lessThan
      ConditionalExpression
        condition2: BinaryOperatorInvocation
          leftOperand: SimpleIdentifier
            token: c
          operator: >
          rightOperand: SimpleIdentifier
            token: <empty> <synthetic>
          binaryOperator: greaterThan
        condition(v1): BinaryExpression
          leftOperand: SimpleIdentifier
            token: c
          operator: >
          rightOperand: SimpleIdentifier
            token: <empty> <synthetic>
        question: ?
        thenExpression2: NullLiteral
          literal: null
        colon: :
        elseExpression2: NullLiteral
          literal: null
    arguments(v1)
      BinaryExpression
        leftOperand: SimpleIdentifier
          token: a
        operator: <
        rightOperand: SimpleIdentifier
          token: b
      ConditionalExpression
        condition: BinaryExpression
          leftOperand: SimpleIdentifier
            token: c
          operator: >
          rightOperand: SimpleIdentifier
            token: <empty> <synthetic>
        question: ?
        thenExpression: NullLiteral
          literal: null
        colon: :
        elseExpression: NullLiteral
          literal: null
    rightParenthesis: )
''');
  }

  void test_followingToken_rejected_question_period_methodInvocation() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = f(a<b,c>?.toString());
//              ^^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.methodInvocation('f(');
    assertParsedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
  argumentList: ArgumentList
    leftParenthesis: (
    arguments2
      BinaryOperatorInvocation
        leftOperand: SimpleIdentifier
          token: a
        operator: <
        rightOperand: SimpleIdentifier
          token: b
        binaryOperator: lessThan
      BinaryOperatorInvocation
        leftOperand: SimpleIdentifier
          token: c
        operator: >
        rightOperand: MethodInvocation
          target2: SimpleIdentifier
            token: <empty> <synthetic>
          operator: ?.
          methodName: SimpleIdentifier
            token: toString
          argumentList: ArgumentList
            leftParenthesis: (
            rightParenthesis: )
        binaryOperator: greaterThan
    arguments(v1)
      BinaryExpression
        leftOperand: SimpleIdentifier
          token: a
        operator: <
        rightOperand: SimpleIdentifier
          token: b
      BinaryExpression
        leftOperand: SimpleIdentifier
          token: c
        operator: >
        rightOperand: MethodInvocation
          target: SimpleIdentifier
            token: <empty> <synthetic>
          operator: ?.
          methodName: SimpleIdentifier
            token: toString
          argumentList: ArgumentList
            leftParenthesis: (
            rightParenthesis: )
    rightParenthesis: )
''');
  }

  void test_followingToken_rejected_question_period_methodInvocation_generic() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = f(a<b,c>?.foo<c>());
//              ^^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.methodInvocation('f(');
    assertParsedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
  argumentList: ArgumentList
    leftParenthesis: (
    arguments2
      BinaryOperatorInvocation
        leftOperand: SimpleIdentifier
          token: a
        operator: <
        rightOperand: SimpleIdentifier
          token: b
        binaryOperator: lessThan
      BinaryOperatorInvocation
        leftOperand: SimpleIdentifier
          token: c
        operator: >
        rightOperand: MethodInvocation
          target2: SimpleIdentifier
            token: <empty> <synthetic>
          operator: ?.
          methodName: SimpleIdentifier
            token: foo
          typeArguments: TypeArgumentList
            leftBracket: <
            arguments
              NamedType
                name: c
            rightBracket: >
          argumentList: ArgumentList
            leftParenthesis: (
            rightParenthesis: )
        binaryOperator: greaterThan
    arguments(v1)
      BinaryExpression
        leftOperand: SimpleIdentifier
          token: a
        operator: <
        rightOperand: SimpleIdentifier
          token: b
      BinaryExpression
        leftOperand: SimpleIdentifier
          token: c
        operator: >
        rightOperand: MethodInvocation
          target: SimpleIdentifier
            token: <empty> <synthetic>
          operator: ?.
          methodName: SimpleIdentifier
            token: foo
          typeArguments: TypeArgumentList
            leftBracket: <
            arguments
              NamedType
                name: c
            rightBracket: >
          argumentList: ArgumentList
            leftParenthesis: (
            rightParenthesis: )
    rightParenthesis: )
''');
  }

  void test_followingToken_rejected_question_period_period() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = f(a<b,c>?..toString());
//              ^^^
// [diag.missingIdentifier] Expected an identifier.
//                 ^^^^^^^^
// [diag.expectedToken] Expected to find ','.
''');
    var node = parseResult.findNode.methodInvocation('f(');
    assertParsedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
  argumentList: ArgumentList
    leftParenthesis: (
    arguments2
      BinaryOperatorInvocation
        leftOperand: SimpleIdentifier
          token: a
        operator: <
        rightOperand: SimpleIdentifier
          token: b
        binaryOperator: lessThan
      BinaryOperatorInvocation
        leftOperand: SimpleIdentifier
          token: c
        operator: >
        rightOperand: SimpleIdentifier
          token: <empty> <synthetic>
        binaryOperator: greaterThan
      MethodInvocation
        methodName: SimpleIdentifier
          token: toString
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
    arguments(v1)
      BinaryExpression
        leftOperand: SimpleIdentifier
          token: a
        operator: <
        rightOperand: SimpleIdentifier
          token: b
      BinaryExpression
        leftOperand: SimpleIdentifier
          token: c
        operator: >
        rightOperand: SimpleIdentifier
          token: <empty> <synthetic>
      MethodInvocation
        methodName: SimpleIdentifier
          token: toString
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
    rightParenthesis: )
''');
  }

  void test_followingToken_rejected_question_period_propertyAccess() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = f(a<b,c>?.hashCode);
//              ^^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleMethodInvocation;
    assertParsedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
  argumentList: ArgumentList
    leftParenthesis: (
    arguments2
      BinaryOperatorInvocation
        leftOperand: SimpleIdentifier
          token: a
        operator: <
        rightOperand: SimpleIdentifier
          token: b
        binaryOperator: lessThan
      BinaryOperatorInvocation
        leftOperand: SimpleIdentifier
          token: c
        operator: >
        rightOperand: PropertyAccess
          target2: SimpleIdentifier
            token: <empty> <synthetic>
          operator: ?.
          propertyName: SimpleIdentifier
            token: hashCode
        binaryOperator: greaterThan
    arguments(v1)
      BinaryExpression
        leftOperand: SimpleIdentifier
          token: a
        operator: <
        rightOperand: SimpleIdentifier
          token: b
      BinaryExpression
        leftOperand: SimpleIdentifier
          token: c
        operator: >
        rightOperand: PropertyAccess
          target: SimpleIdentifier
            token: <empty> <synthetic>
          operator: ?.
          propertyName: SimpleIdentifier
            token: hashCode
    rightParenthesis: )
''');
  }

  void test_followingToken_rejected_question_question() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = f(a<b,c> ?? d);
//               ^^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleMethodInvocation;
    assertParsedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
  argumentList: ArgumentList
    leftParenthesis: (
    arguments2
      BinaryOperatorInvocation
        leftOperand: SimpleIdentifier
          token: a
        operator: <
        rightOperand: SimpleIdentifier
          token: b
        binaryOperator: lessThan
      IfNull
        leftOperand: BinaryOperatorInvocation
          leftOperand: SimpleIdentifier
            token: c
          operator: >
          rightOperand: SimpleIdentifier
            token: <empty> <synthetic>
          binaryOperator: greaterThan
        operator: ??
        rightOperand: SimpleIdentifier
          token: d
    arguments(v1)
      BinaryExpression
        leftOperand: SimpleIdentifier
          token: a
        operator: <
        rightOperand: SimpleIdentifier
          token: b
      BinaryExpression
        leftOperand: BinaryExpression
          leftOperand: SimpleIdentifier
            token: c
          operator: >
          rightOperand: SimpleIdentifier
            token: <empty> <synthetic>
        operator: ??
        rightOperand: SimpleIdentifier
          token: d
    rightParenthesis: )
''');
  }

  void test_followingToken_rejected_slash() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = f(a<b,c>/d);
//              ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleMethodInvocation;
    assertParsedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
  argumentList: ArgumentList
    leftParenthesis: (
    arguments2
      BinaryOperatorInvocation
        leftOperand: SimpleIdentifier
          token: a
        operator: <
        rightOperand: SimpleIdentifier
          token: b
        binaryOperator: lessThan
      BinaryOperatorInvocation
        leftOperand: SimpleIdentifier
          token: c
        operator: >
        rightOperand: BinaryOperatorInvocation
          leftOperand: SimpleIdentifier
            token: <empty> <synthetic>
          operator: /
          rightOperand: SimpleIdentifier
            token: d
          binaryOperator: divide
        binaryOperator: greaterThan
    arguments(v1)
      BinaryExpression
        leftOperand: SimpleIdentifier
          token: a
        operator: <
        rightOperand: SimpleIdentifier
          token: b
      BinaryExpression
        leftOperand: SimpleIdentifier
          token: c
        operator: >
        rightOperand: BinaryExpression
          leftOperand: SimpleIdentifier
            token: <empty> <synthetic>
          operator: /
          rightOperand: SimpleIdentifier
            token: d
    rightParenthesis: )
''');
  }

  void test_followingToken_rejected_tilde_slash() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = f(a<b,c>~/d);
//              ^^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleMethodInvocation;
    assertParsedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
  argumentList: ArgumentList
    leftParenthesis: (
    arguments2
      BinaryOperatorInvocation
        leftOperand: SimpleIdentifier
          token: a
        operator: <
        rightOperand: SimpleIdentifier
          token: b
        binaryOperator: lessThan
      BinaryOperatorInvocation
        leftOperand: SimpleIdentifier
          token: c
        operator: >
        rightOperand: BinaryOperatorInvocation
          leftOperand: SimpleIdentifier
            token: <empty> <synthetic>
          operator: ~/
          rightOperand: SimpleIdentifier
            token: d
          binaryOperator: truncatingDivide
        binaryOperator: greaterThan
    arguments(v1)
      BinaryExpression
        leftOperand: SimpleIdentifier
          token: a
        operator: <
        rightOperand: SimpleIdentifier
          token: b
      BinaryExpression
        leftOperand: SimpleIdentifier
          token: c
        operator: >
        rightOperand: BinaryExpression
          leftOperand: SimpleIdentifier
            token: <empty> <synthetic>
          operator: ~/
          rightOperand: SimpleIdentifier
            token: d
    rightParenthesis: )
''');
  }

  void test_functionReference_after_indexExpression() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = x[0]<a, b>;
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer2!;
    assertParsedNodeText(node, r'''
FunctionReference
  function2: ReceiverIndexExpression
    receiver: SimpleIdentifier
      token: x
    leftBracket: [
    index: IntegerLiteral
      literal: 0
    rightBracket: ]
  function(v1): IndexExpression
    target: SimpleIdentifier
      token: x
    leftBracket: [
    index: IntegerLiteral
      literal: 0
    rightBracket: ]
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: a
      NamedType
        name: b
    rightBracket: >
''');
  }

  void test_functionReference_after_indexExpression_bang() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = x[0]!<a, b>;
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer2!;
    assertParsedNodeText(node, r'''
FunctionReference
  function2: NullAssertionExpression
    operand: ReceiverIndexExpression
      receiver: SimpleIdentifier
        token: x
      leftBracket: [
      index: IntegerLiteral
        literal: 0
      rightBracket: ]
    operator: !
  function(v1): PostfixExpression
    operand: IndexExpression
      target: SimpleIdentifier
        token: x
      leftBracket: [
      index: IntegerLiteral
        literal: 0
      rightBracket: ]
    operator: !
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: a
      NamedType
        name: b
    rightBracket: >
''');
  }

  void test_functionReference_after_indexExpression_functionCall() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = x[0]()<a, b>;
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer2!;
    assertParsedNodeText(node, r'''
FunctionReference
  function2: CallInvocation
    receiver: ReceiverIndexExpression
      receiver: SimpleIdentifier
        token: x
      leftBracket: [
      index: IntegerLiteral
        literal: 0
      rightBracket: ]
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
  function(v1): FunctionExpressionInvocation
    function: IndexExpression
      target: SimpleIdentifier
        token: x
      leftBracket: [
      index: IntegerLiteral
        literal: 0
      rightBracket: ]
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: a
      NamedType
        name: b
    rightBracket: >
''');
  }

  void test_functionReference_after_indexExpression_nullAware() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = x?[0]<a, b>;
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer2!;
    assertParsedNodeText(node, r'''
FunctionReference
  function2: ReceiverIndexExpression
    receiver: SimpleIdentifier
      token: x
    question: ?
    leftBracket: [
    index: IntegerLiteral
      literal: 0
    rightBracket: ]
  function(v1): IndexExpression
    target: SimpleIdentifier
      token: x
    question: ?
    leftBracket: [
    index: IntegerLiteral
      literal: 0
    rightBracket: ]
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: a
      NamedType
        name: b
    rightBracket: >
''');
  }

  void test_methodTearoff() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = f().m<a, b>;
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer2!;
    assertParsedNodeText(node, r'''
FunctionReference
  function2: PropertyAccess
    target2: MethodInvocation
      methodName: SimpleIdentifier
        token: f
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
    operator: .
    propertyName: SimpleIdentifier
      token: m
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: a
      NamedType
        name: b
    rightBracket: >
''');
  }

  void test_methodTearoff_cascaded() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = f()..m<a, b>;
''');
    var node = parseResult.findNode.singleCascadeExpression.sections[0].body;
    assertParsedNodeText(node, r'''
FunctionReference
  function2: CascadePropertyExtraction
    propertyName: m
  function(v1): PropertyAccess
    operator: ..
    propertyName: SimpleIdentifier
      token: m
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: a
      NamedType
        name: b
    rightBracket: >
''');
  }

  void test_prefixedIdentifier() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = prefix.f<a, b>;
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer2!;
    assertParsedNodeText(node, r'''
FunctionReference
  function2: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: prefix
    period: .
    identifier: SimpleIdentifier
      token: f
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: a
      NamedType
        name: b
    rightBracket: >
''');
  }

  void test_three_identifiers() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = prefix.ClassName.m<a, b>;
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer2!;
    assertParsedNodeText(node, r'''
FunctionReference
  function2: PropertyAccess
    target2: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: prefix
      period: .
      identifier: SimpleIdentifier
        token: ClassName
    operator: .
    propertyName: SimpleIdentifier
      token: m
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: a
      NamedType
        name: b
    rightBracket: >
''');
  }
}
