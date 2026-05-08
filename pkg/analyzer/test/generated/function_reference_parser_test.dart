// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
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
    var parseResult = parseStringWithErrors(
      'void f() { f<a, b>; }',
      featureSet: FeatureSet.fromEnableFlags2(
        sdkLanguageVersion: Version.parse('2.13.0'),
        flags: [],
      ),
    );
    parseResult.assertErrors([error(diag.experimentNotEnabled, 12, 6)]);

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
FunctionReference
  function: SimpleIdentifier
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
    var parseResult = parseStringWithErrors(r'''
var x = {f<a, b>};
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleSetOrMapLiteral.elements[0];
    assertParsedNodeText(node, r'''
FunctionReference
  function: SimpleIdentifier
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
    var parseResult = parseStringWithErrors(r'''
var x = [f<a, b>];
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleListLiteral.elements[0];
    assertParsedNodeText(node, r'''
FunctionReference
  function: SimpleIdentifier
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
    var parseResult = parseStringWithErrors(r'''
var x = g(f<a, b>);
''');
    parseResult.assertNoErrors();
    var node =
        parseResult.findNode.singleMethodInvocation.argumentList.arguments[0];
    assertParsedNodeText(node, r'''
FunctionReference
  function: SimpleIdentifier
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
    var parseResult = parseStringWithErrors(r'''
var x = {f<a, b>: null};
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.mapLiteralEntry('null').key;
    assertParsedNodeText(node, r'''
FunctionReference
  function: SimpleIdentifier
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
    var parseResult = parseStringWithErrors(r'''
var x = [f<a, b>, null];
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleListLiteral.elements[0];
    assertParsedNodeText(node, r'''
FunctionReference
  function: SimpleIdentifier
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
    var parseResult = parseStringWithErrors(r'''
var x = f<a, b> == null;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleBinaryExpression.leftOperand;
    assertParsedNodeText(node, r'''
FunctionReference
  function: SimpleIdentifier
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
    var parseResult = parseStringWithErrors(r'''
var x = f<a, b> != null;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleBinaryExpression.leftOperand;
    assertParsedNodeText(node, r'''
FunctionReference
  function: SimpleIdentifier
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
    var parseResult = parseStringWithErrors(r'''
var x = f<a, b>();
''');
    parseResult.assertNoErrors();
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
    var parseResult = parseStringWithErrors(r'''
var x = f<a, b>.toString();
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleInstanceCreationExpression;
    assertParsedNodeText(node, r'''
InstanceCreationExpression
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
    var parseResult = parseStringWithErrors(r'''
var x = f<a, b>.foo<c>();
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleMethodInvocation.target!;
    assertParsedNodeText(node, r'''
FunctionReference
  function: SimpleIdentifier
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
    var parseResult = parseStringWithErrors(r'''
var x = f<a, b>.hashCode;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singlePropertyAccess.target!;
    assertParsedNodeText(node, r'''
FunctionReference
  function: SimpleIdentifier
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
    var parseResult = parseStringWithErrors(r'''
void f() {
  f<a, b>;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
FunctionReference
  function: SimpleIdentifier
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
    var parseResult = parseStringWithErrors(r'''
var x = f(a<b,c>&d);
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 16, 1)]);
    var node = parseResult.findNode.singleMethodInvocation;
    assertParsedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
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
    var parseResult = parseStringWithErrors(r'''
var x = f(a < b, c > as);
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleMethodInvocation;
    assertParsedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
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
    var parseResult = parseStringWithErrors(r'''
var x = f(a<b,c>*d);
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 16, 1)]);
    var node = parseResult.findNode.singleMethodInvocation;
    assertParsedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
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
    var parseResult = parseStringWithErrors(r'''
var x = f(a < b, c > ![d]);
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleMethodInvocation;
    assertParsedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
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
    var parseResult = parseStringWithErrors(r'''
var x = f(a < b, c > !(d));
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleMethodInvocation;
    assertParsedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
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
    var parseResult = parseStringWithErrors(r'''
var x = f(a<b,c>|d);
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 16, 1)]);
    var node = parseResult.findNode.singleMethodInvocation;
    assertParsedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
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
    var parseResult = parseStringWithErrors(r'''
var x = f(a<b,c>^d);
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 16, 1)]);
    var node = parseResult.findNode.singleMethodInvocation;
    assertParsedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
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
    var parseResult = parseStringWithErrors(r'''
var x = f(a<b,c> is int);
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 17, 2)]);
    var node = parseResult.findNode.singleMethodInvocation;
    assertParsedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
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
    var parseResult = parseStringWithErrors(r'''
var x = f<a><b>;
''');
    parseResult.assertErrors([
      error(diag.equalityCannotBeEqualityOperand, 11, 1),
      error(diag.expectedToken, 15, 1),
    ]);
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
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
    var parseResult = parseStringWithErrors(r'''
var x = f(a < b, c > -d);
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleMethodInvocation;
    assertParsedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
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
    var parseResult = parseStringWithErrors(r'''
var x = f(a < b, c > [d]);
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleMethodInvocation;
    assertParsedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
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
    var parseResult = parseStringWithErrors(r'''
var x = f(a<b,c>[d]>e);
''');
    parseResult.assertErrors([
      error(diag.equalityCannotBeEqualityOperand, 19, 1),
    ]);
    var node = parseResult.findNode.singleMethodInvocation;
    assertParsedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
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
    var parseResult = parseStringWithErrors(r'''
var x = f(a < b, c > [d, e]);
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleMethodInvocation;
    assertParsedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
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
    var parseResult = parseStringWithErrors(r'''
var x = f(a<b,c>%d);
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 16, 1)]);
    var node = parseResult.findNode.singleMethodInvocation;
    assertParsedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
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
    var parseResult = parseStringWithErrors(r'''
var x = f(a<b,c>..toString());
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 16, 2)]);
    var node = parseResult.findNode.methodInvocation('f(');
    assertParsedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
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
    var parseResult = parseStringWithErrors(r'''
var x = f(a<b,c>+d);
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 16, 1)]);
    var node = parseResult.findNode.singleMethodInvocation;
    assertParsedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
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
    var parseResult = parseStringWithErrors(r'''
var x = f(a<b,c> ? null : null);
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 17, 1)]);
    var node = parseResult.findNode.singleMethodInvocation;
    assertParsedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
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
    var parseResult = parseStringWithErrors(r'''
var x = f(a<b,c>?.toString());
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 16, 2)]);
    var node = parseResult.findNode.methodInvocation('f(');
    assertParsedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
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
    var parseResult = parseStringWithErrors(r'''
var x = f(a<b,c>?.foo<c>());
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 16, 2)]);
    var node = parseResult.findNode.methodInvocation('f(');
    assertParsedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
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
    var parseResult = parseStringWithErrors(r'''
var x = f(a<b,c>?..toString());
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 16, 3),
      error(diag.expectedToken, 19, 8),
    ]);
    var node = parseResult.findNode.methodInvocation('f(');
    assertParsedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
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
    var parseResult = parseStringWithErrors(r'''
var x = f(a<b,c>?.hashCode);
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 16, 2)]);
    var node = parseResult.findNode.singleMethodInvocation;
    assertParsedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
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
    var parseResult = parseStringWithErrors(r'''
var x = f(a<b,c> ?? d);
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 17, 2)]);
    var node = parseResult.findNode.singleMethodInvocation;
    assertParsedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
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
    var parseResult = parseStringWithErrors(r'''
var x = f(a<b,c>/d);
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 16, 1)]);
    var node = parseResult.findNode.singleMethodInvocation;
    assertParsedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
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
    var parseResult = parseStringWithErrors(r'''
var x = f(a<b,c>~/d);
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 16, 2)]);
    var node = parseResult.findNode.singleMethodInvocation;
    assertParsedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
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
    var parseResult = parseStringWithErrors(r'''
var x = x[0]<a, b>;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
FunctionReference
  function: IndexExpression
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
    var parseResult = parseStringWithErrors(r'''
var x = x[0]!<a, b>;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
FunctionReference
  function: PostfixExpression
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
    var parseResult = parseStringWithErrors(r'''
var x = x[0]()<a, b>;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
FunctionReference
  function: FunctionExpressionInvocation
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
    var parseResult = parseStringWithErrors(r'''
var x = x?[0]<a, b>;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
FunctionReference
  function: IndexExpression
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
    var parseResult = parseStringWithErrors(r'''
var x = f().m<a, b>;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
FunctionReference
  function: PropertyAccess
    target: MethodInvocation
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
    var parseResult = parseStringWithErrors(r'''
var x = f()..m<a, b>;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleCascadeExpression.cascadeSections[0];
    assertParsedNodeText(node, r'''
FunctionReference
  function: PropertyAccess
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
    var parseResult = parseStringWithErrors(r'''
var x = prefix.f<a, b>;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
FunctionReference
  function: PrefixedIdentifier
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
    var parseResult = parseStringWithErrors(r'''
var x = prefix.ClassName.m<a, b>;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
FunctionReference
  function: PropertyAccess
    target: PrefixedIdentifier
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
