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
    var node = parseResult.findNode.singleBinaryExpression.leftOperand2;
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
    var node = parseResult.findNode.singleBinaryExpression.leftOperand2;
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
      BinaryExpression
        leftOperand2: SimpleIdentifier
          token: a
        operator: <
        rightOperand2: SimpleIdentifier
          token: b
      BinaryExpression
        leftOperand2: SimpleIdentifier
          token: c
        operator: >
        rightOperand2: BinaryExpression
          leftOperand2: SimpleIdentifier
            token: <empty> <synthetic>
          operator: &
          rightOperand2: SimpleIdentifier
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
      BinaryExpression
        leftOperand2: SimpleIdentifier
          token: a
        operator: <
        rightOperand2: SimpleIdentifier
          token: b
      BinaryExpression
        leftOperand2: SimpleIdentifier
          token: c
        operator: >
        rightOperand2: SimpleIdentifier
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
      BinaryExpression
        leftOperand2: SimpleIdentifier
          token: a
        operator: <
        rightOperand2: SimpleIdentifier
          token: b
      BinaryExpression
        leftOperand2: SimpleIdentifier
          token: c
        operator: >
        rightOperand2: BinaryExpression
          leftOperand2: SimpleIdentifier
            token: <empty> <synthetic>
          operator: *
          rightOperand2: SimpleIdentifier
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
      BinaryExpression
        leftOperand2: SimpleIdentifier
          token: a
        operator: <
        rightOperand2: SimpleIdentifier
          token: b
      BinaryExpression
        leftOperand2: SimpleIdentifier
          token: c
        operator: >
        rightOperand2: PrefixExpression
          operator: !
          operand2: ListLiteral
            leftBracket: [
            elements2
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
      BinaryExpression
        leftOperand2: SimpleIdentifier
          token: a
        operator: <
        rightOperand2: SimpleIdentifier
          token: b
      BinaryExpression
        leftOperand2: SimpleIdentifier
          token: c
        operator: >
        rightOperand2: PrefixExpression
          operator: !
          operand2: ParenthesizedExpression
            leftParenthesis: (
            expression2: SimpleIdentifier
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
      BinaryExpression
        leftOperand2: SimpleIdentifier
          token: a
        operator: <
        rightOperand2: SimpleIdentifier
          token: b
      BinaryExpression
        leftOperand2: SimpleIdentifier
          token: c
        operator: >
        rightOperand2: BinaryExpression
          leftOperand2: SimpleIdentifier
            token: <empty> <synthetic>
          operator: |
          rightOperand2: SimpleIdentifier
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
      BinaryExpression
        leftOperand2: SimpleIdentifier
          token: a
        operator: <
        rightOperand2: SimpleIdentifier
          token: b
      BinaryExpression
        leftOperand2: SimpleIdentifier
          token: c
        operator: >
        rightOperand2: BinaryExpression
          leftOperand2: SimpleIdentifier
            token: <empty> <synthetic>
          operator: ^
          rightOperand2: SimpleIdentifier
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
      BinaryExpression
        leftOperand2: SimpleIdentifier
          token: a
        operator: <
        rightOperand2: SimpleIdentifier
          token: b
      IsExpression
        expression2: BinaryExpression
          leftOperand2: SimpleIdentifier
            token: c
          operator: >
          rightOperand2: SimpleIdentifier
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
BinaryExpression
  leftOperand2: BinaryExpression
    leftOperand2: SimpleIdentifier
      token: f
    operator: <
    rightOperand2: SimpleIdentifier
      token: a
  operator: >
  rightOperand2: ListLiteral
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
      BinaryExpression
        leftOperand2: SimpleIdentifier
          token: a
        operator: <
        rightOperand2: SimpleIdentifier
          token: b
      BinaryExpression
        leftOperand2: SimpleIdentifier
          token: c
        operator: >
        rightOperand2: PrefixExpression
          operator: -
          operand2: SimpleIdentifier
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
      BinaryExpression
        leftOperand2: SimpleIdentifier
          token: a
        operator: <
        rightOperand2: SimpleIdentifier
          token: b
      BinaryExpression
        leftOperand2: SimpleIdentifier
          token: c
        operator: >
        rightOperand2: ListLiteral
          leftBracket: [
          elements2
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
      BinaryExpression
        leftOperand2: SimpleIdentifier
          token: a
        operator: <
        rightOperand2: SimpleIdentifier
          token: b
      BinaryExpression
        leftOperand2: BinaryExpression
          leftOperand2: SimpleIdentifier
            token: c
          operator: >
          rightOperand2: ListLiteral
            leftBracket: [
            elements2
              SimpleIdentifier
                token: d
            rightBracket: ]
        operator: >
        rightOperand2: SimpleIdentifier
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
      BinaryExpression
        leftOperand2: SimpleIdentifier
          token: a
        operator: <
        rightOperand2: SimpleIdentifier
          token: b
      BinaryExpression
        leftOperand2: SimpleIdentifier
          token: c
        operator: >
        rightOperand2: ListLiteral
          leftBracket: [
          elements2
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
      BinaryExpression
        leftOperand2: SimpleIdentifier
          token: a
        operator: <
        rightOperand2: SimpleIdentifier
          token: b
      BinaryExpression
        leftOperand2: SimpleIdentifier
          token: c
        operator: >
        rightOperand2: BinaryExpression
          leftOperand2: SimpleIdentifier
            token: <empty> <synthetic>
          operator: %
          rightOperand2: SimpleIdentifier
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
      BinaryExpression
        leftOperand2: SimpleIdentifier
          token: a
        operator: <
        rightOperand2: SimpleIdentifier
          token: b
      CascadeExpression
        target2: BinaryExpression
          leftOperand2: SimpleIdentifier
            token: c
          operator: >
          rightOperand2: SimpleIdentifier
            token: <empty> <synthetic>
        cascadeSections2
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
      BinaryExpression
        leftOperand2: SimpleIdentifier
          token: a
        operator: <
        rightOperand2: SimpleIdentifier
          token: b
      BinaryExpression
        leftOperand2: SimpleIdentifier
          token: c
        operator: >
        rightOperand2: BinaryExpression
          leftOperand2: SimpleIdentifier
            token: <empty> <synthetic>
          operator: +
          rightOperand2: SimpleIdentifier
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
      BinaryExpression
        leftOperand2: SimpleIdentifier
          token: a
        operator: <
        rightOperand2: SimpleIdentifier
          token: b
      ConditionalExpression
        condition2: BinaryExpression
          leftOperand2: SimpleIdentifier
            token: c
          operator: >
          rightOperand2: SimpleIdentifier
            token: <empty> <synthetic>
        question: ?
        thenExpression2: NullLiteral
          literal: null
        colon: :
        elseExpression2: NullLiteral
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
      BinaryExpression
        leftOperand2: SimpleIdentifier
          token: a
        operator: <
        rightOperand2: SimpleIdentifier
          token: b
      BinaryExpression
        leftOperand2: SimpleIdentifier
          token: c
        operator: >
        rightOperand2: MethodInvocation
          target2: SimpleIdentifier
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
      BinaryExpression
        leftOperand2: SimpleIdentifier
          token: a
        operator: <
        rightOperand2: SimpleIdentifier
          token: b
      BinaryExpression
        leftOperand2: SimpleIdentifier
          token: c
        operator: >
        rightOperand2: MethodInvocation
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
      BinaryExpression
        leftOperand2: SimpleIdentifier
          token: a
        operator: <
        rightOperand2: SimpleIdentifier
          token: b
      BinaryExpression
        leftOperand2: SimpleIdentifier
          token: c
        operator: >
        rightOperand2: SimpleIdentifier
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
      BinaryExpression
        leftOperand2: SimpleIdentifier
          token: a
        operator: <
        rightOperand2: SimpleIdentifier
          token: b
      BinaryExpression
        leftOperand2: SimpleIdentifier
          token: c
        operator: >
        rightOperand2: PropertyAccess
          target2: SimpleIdentifier
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
      BinaryExpression
        leftOperand2: SimpleIdentifier
          token: a
        operator: <
        rightOperand2: SimpleIdentifier
          token: b
      BinaryExpression
        leftOperand2: BinaryExpression
          leftOperand2: SimpleIdentifier
            token: c
          operator: >
          rightOperand2: SimpleIdentifier
            token: <empty> <synthetic>
        operator: ??
        rightOperand2: SimpleIdentifier
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
      BinaryExpression
        leftOperand2: SimpleIdentifier
          token: a
        operator: <
        rightOperand2: SimpleIdentifier
          token: b
      BinaryExpression
        leftOperand2: SimpleIdentifier
          token: c
        operator: >
        rightOperand2: BinaryExpression
          leftOperand2: SimpleIdentifier
            token: <empty> <synthetic>
          operator: /
          rightOperand2: SimpleIdentifier
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
      BinaryExpression
        leftOperand2: SimpleIdentifier
          token: a
        operator: <
        rightOperand2: SimpleIdentifier
          token: b
      BinaryExpression
        leftOperand2: SimpleIdentifier
          token: c
        operator: >
        rightOperand2: BinaryExpression
          leftOperand2: SimpleIdentifier
            token: <empty> <synthetic>
          operator: ~/
          rightOperand2: SimpleIdentifier
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
  function2: IndexExpression
    target2: SimpleIdentifier
      token: x
    leftBracket: [
    index2: IntegerLiteral
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
  function2: PostfixExpression
    operand2: IndexExpression
      target2: SimpleIdentifier
        token: x
      leftBracket: [
      index2: IntegerLiteral
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
  function2: FunctionExpressionInvocation
    function2: IndexExpression
      target2: SimpleIdentifier
        token: x
      leftBracket: [
      index2: IntegerLiteral
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
  function2: IndexExpression
    target2: SimpleIdentifier
      token: x
    question: ?
    leftBracket: [
    index2: IntegerLiteral
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
    var node = parseResult.findNode.singleCascadeExpression.cascadeSections2[0];
    assertParsedNodeText(node, r'''
FunctionReference
  function2: PropertyAccess
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
