// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'parser_test_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FunctionReferenceParserTest);
  });
}

/// Tests exercising the fasta parser's handling of generic instantiations.
@reflectiveTest
class FunctionReferenceParserTest extends FastaParserTestCase {
  /// Verifies that the given [node] matches `f<a, b>`.
  void expect_f_a_b(AstNode node) {
    var functionReference = node as FunctionReference;
    expect((functionReference.function as SimpleIdentifier).name, 'f');
    var typeArgs = functionReference.typeArguments!.arguments;
    expect(typeArgs, hasLength(2));
    expect(((typeArgs[0] as TypeName).name as SimpleIdentifier).name, 'a');
    expect(((typeArgs[1] as TypeName).name as SimpleIdentifier).name, 'b');
  }

  void expect_two_args(MethodInvocation methodInvocation) {
    var arguments = methodInvocation.argumentList.arguments;
    expect(arguments, hasLength(2));
    expect(arguments[0], TypeMatcher<BinaryExpression>());
    expect(arguments[1], TypeMatcher<BinaryExpression>());
  }

  void test_feature_disabled() {
    var expression =
        (parseStatement('f<a, b>;', featureSet: preConstructorTearoffs)
                as ExpressionStatement)
            .expression;
    // TODO(paulberry): once we have visitor support for FunctionReference, this
    // should be parsed as a FunctionReference, so we should be able to validate
    // it using `expect_f_a_b`.  But for now it's parsed as a
    // FunctionExpressionInvocation with synthetic arguments.
    var functionExpressionInvocation =
        expression as FunctionExpressionInvocation;
    expect(
        (functionExpressionInvocation.function as SimpleIdentifier).name, 'f');
    expect(functionExpressionInvocation.argumentList.arguments, isEmpty);
    var typeArgs = functionExpressionInvocation.typeArguments!.arguments;
    expect(typeArgs, hasLength(2));
    expect(((typeArgs[0] as TypeName).name as SimpleIdentifier).name, 'a');
    expect(((typeArgs[1] as TypeName).name as SimpleIdentifier).name, 'b');
    listener.assertErrors([
      expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 1, 6),
    ]);
  }

  void test_followingToken_accepted_ampersand() {
    expect_f_a_b(
        (parseExpression('f<a, b> & 0', featureSet: constructorTearoffs)
                as BinaryExpression)
            .leftOperand);
  }

  void test_followingToken_accepted_asterisk() {
    expect_f_a_b(
        (parseExpression('f<a, b> * 0', featureSet: constructorTearoffs)
                as BinaryExpression)
            .leftOperand);
  }

  void test_followingToken_accepted_bar() {
    expect_f_a_b(
        (parseExpression('f<a, b> | 0', featureSet: constructorTearoffs)
                as BinaryExpression)
            .leftOperand);
  }

  void test_followingToken_accepted_caret() {
    expect_f_a_b(
        (parseExpression('f<a, b> ^ 0', featureSet: constructorTearoffs)
                as BinaryExpression)
            .leftOperand);
  }

  void test_followingToken_accepted_closeBrace() {
    expect_f_a_b((parseExpression('{f<a, b>}', featureSet: constructorTearoffs)
            as SetOrMapLiteral)
        .elements[0]);
  }

  void test_followingToken_accepted_closeBracket() {
    expect_f_a_b((parseExpression('[f<a, b>]', featureSet: constructorTearoffs)
            as ListLiteral)
        .elements[0]);
  }

  void test_followingToken_accepted_closeParen() {
    expect_f_a_b((parseExpression('g(f<a, b>)', featureSet: constructorTearoffs)
            as MethodInvocation)
        .argumentList
        .arguments[0]);
  }

  void test_followingToken_accepted_colon() {
    expect_f_a_b(
        ((parseExpression('{f<a, b>: null}', featureSet: constructorTearoffs)
                    as SetOrMapLiteral)
                .elements[0] as MapLiteralEntry)
            .key);
  }

  void test_followingToken_accepted_comma() {
    expect_f_a_b(
        (parseExpression('[f<a, b>, null]', featureSet: constructorTearoffs)
                as ListLiteral)
            .elements[0]);
  }

  void test_followingToken_accepted_equals() {
    expect_f_a_b(
        (parseExpression('f<a, b> == null', featureSet: constructorTearoffs)
                as BinaryExpression)
            .leftOperand);
  }

  void test_followingToken_accepted_not_equals() {
    expect_f_a_b(
        (parseExpression('f<a, b> != null', featureSet: constructorTearoffs)
                as BinaryExpression)
            .leftOperand);
  }

  void test_followingToken_accepted_openParen() {
    // This is a special case because when a `(` follows `<typeArguments>` it is
    // parsed as a MethodInvocation rather than a GenericInstantiation.
    var methodInvocation =
        parseExpression('f<a, b>()', featureSet: constructorTearoffs)
            as MethodInvocation;
    expect(methodInvocation.methodName.name, 'f');
    var typeArgs = methodInvocation.typeArguments!.arguments;
    expect(typeArgs, hasLength(2));
    expect(((typeArgs[0] as TypeName).name as SimpleIdentifier).name, 'a');
    expect(((typeArgs[1] as TypeName).name as SimpleIdentifier).name, 'b');
    expect(methodInvocation.argumentList.arguments, isEmpty);
  }

  void test_followingToken_accepted_percent() {
    expect_f_a_b(
        (parseExpression('f<a, b> % 0', featureSet: constructorTearoffs)
                as BinaryExpression)
            .leftOperand);
  }

  void test_followingToken_accepted_period_methodInvocation() {
    // This is a special case because `f<a, b>.methodName(...)` is parsed as an
    // InstanceCreationExpression.
    var instanceCreationExpression =
        parseExpression('f<a, b>.toString()', featureSet: constructorTearoffs)
            as InstanceCreationExpression;
    var constructorName = instanceCreationExpression.constructorName;
    var type = constructorName.type;
    expect((type.name as SimpleIdentifier).name, 'f');
    var typeArgs = type.typeArguments!.arguments;
    expect(typeArgs, hasLength(2));
    expect(((typeArgs[0] as TypeName).name as SimpleIdentifier).name, 'a');
    expect(((typeArgs[1] as TypeName).name as SimpleIdentifier).name, 'b');
    expect(constructorName.name!.name, 'toString');
    expect(instanceCreationExpression.argumentList.arguments, isEmpty);
  }

  void test_followingToken_accepted_period_methodInvocation_generic() {
    expect_f_a_b(
        (parseExpression('f<a, b>.foo<c>()', featureSet: constructorTearoffs)
                as MethodInvocation)
            .target!);
  }

  void test_followingToken_accepted_period_period() {
    expect_f_a_b(
        (parseExpression('f<a, b>..toString()', featureSet: constructorTearoffs)
                as CascadeExpression)
            .target);
  }

  void test_followingToken_accepted_period_propertyAccess() {
    expect_f_a_b(
        (parseExpression('f<a, b>.hashCode', featureSet: constructorTearoffs)
                as PropertyAccess)
            .target!);
  }

  void test_followingToken_accepted_plus() {
    expect_f_a_b(
        (parseExpression('f<a, b> + 0', featureSet: constructorTearoffs)
                as BinaryExpression)
            .leftOperand);
  }

  void test_followingToken_accepted_question() {
    expect_f_a_b((parseExpression('f<a, b> ? null : null',
            featureSet: constructorTearoffs) as ConditionalExpression)
        .condition);
  }

  void test_followingToken_accepted_question_period_methodInvocation() {
    expect_f_a_b(
        (parseExpression('f<a, b>?.toString()', featureSet: constructorTearoffs)
                as MethodInvocation)
            .target!);
  }

  void test_followingToken_accepted_question_period_methodInvocation_generic() {
    expect_f_a_b(
        (parseExpression('f<a, b>?.foo<c>()', featureSet: constructorTearoffs)
                as MethodInvocation)
            .target!);
  }

  void test_followingToken_accepted_question_period_period() {
    expect_f_a_b((parseExpression('f<a, b>?..toString()',
            featureSet: constructorTearoffs) as CascadeExpression)
        .target);
  }

  void test_followingToken_accepted_question_period_propertyAccess() {
    expect_f_a_b(
        (parseExpression('f<a, b>?.hashCode', featureSet: constructorTearoffs)
                as PropertyAccess)
            .target!);
  }

  void test_followingToken_accepted_question_question() {
    expect_f_a_b(
        (parseExpression('f<a, b> ?? 0', featureSet: constructorTearoffs)
                as BinaryExpression)
            .leftOperand);
  }

  void test_followingToken_accepted_semicolon() {
    expect_f_a_b((parseStatement('f<a, b>;', featureSet: constructorTearoffs)
            as ExpressionStatement)
        .expression);
    listener.assertNoErrors();
  }

  void test_followingToken_accepted_slash() {
    expect_f_a_b(
        (parseExpression('f<a, b> / 1', featureSet: constructorTearoffs)
                as BinaryExpression)
            .leftOperand);
  }

  void test_followingToken_accepted_tilde_slash() {
    expect_f_a_b(
        (parseExpression('f<a, b> ~/ 1', featureSet: constructorTearoffs)
                as BinaryExpression)
            .leftOperand);
  }

  void test_followingToken_rejected_bang_openBracket() {
    expect_two_args(
        parseExpression('f(a<b,c>![d])', featureSet: constructorTearoffs)
            as MethodInvocation);
  }

  void test_followingToken_rejected_bang_paren() {
    expect_two_args(
        parseExpression('f(a<b,c>!(d))', featureSet: constructorTearoffs)
            as MethodInvocation);
  }

  void test_followingToken_rejected_lessThan() {
    // Note: in principle we could parse this as a generic instantiation of a
    // generic instantiation, but such an expression would be meaningless so we
    // reject it at the parser level.
    parseExpression('f<a><b>', featureSet: constructorTearoffs, errors: [
      expectedError(ParserErrorCode.EQUALITY_CANNOT_BE_EQUALITY_OPERAND, 3, 1),
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 7, 0),
    ]);
  }

  void test_followingToken_rejected_minus() {
    expect_two_args(
        parseExpression('f(a<b,c>-d)', featureSet: constructorTearoffs)
            as MethodInvocation);
  }

  void test_followingToken_rejected_openBracket() {
    expect_two_args(
        parseExpression('f(a<b,c>[d])', featureSet: constructorTearoffs)
            as MethodInvocation);
  }

  void test_followingToken_rejected_openBracket_error() {
    // Note that theoretically this could be successfully parsed by interpreting
    // `<` and `>` as delimiting type arguments, but the parser doesn't have
    // enough lookahead to see that this is the only possible error-free parse;
    // it commits to interpreting `<` and `>` as operators when it sees the `[`.
    expect_two_args(parseExpression('f(a<b,c>[d]>e)',
        featureSet: constructorTearoffs,
        errors: [
          expectedError(
              ParserErrorCode.EQUALITY_CANNOT_BE_EQUALITY_OPERAND, 11, 1),
        ]) as MethodInvocation);
  }

  void test_followingToken_rejected_openBracket_unambiguous() {
    expect_two_args(
        parseExpression('f(a<b,c>[d, e])', featureSet: constructorTearoffs)
            as MethodInvocation);
  }

  void test_methodTearoff() {
    var functionReference =
        parseExpression('f().m<a, b>', featureSet: constructorTearoffs)
            as FunctionReference;
    var function = functionReference.function as PropertyAccess;
    var target = function.target as MethodInvocation;
    expect(target.methodName.name, 'f');
    expect(function.propertyName.name, 'm');
    var typeArgs = functionReference.typeArguments!.arguments;
    expect(typeArgs, hasLength(2));
    expect(((typeArgs[0] as TypeName).name as SimpleIdentifier).name, 'a');
    expect(((typeArgs[1] as TypeName).name as SimpleIdentifier).name, 'b');
  }

  void test_prefixedIdentifier() {
    var functionReference =
        parseExpression('prefix.f<a, b>', featureSet: constructorTearoffs)
            as FunctionReference;
    var function = functionReference.function as PrefixedIdentifier;
    expect(function.prefix.name, 'prefix');
    expect(function.identifier.name, 'f');
    var typeArgs = functionReference.typeArguments!.arguments;
    expect(typeArgs, hasLength(2));
    expect(((typeArgs[0] as TypeName).name as SimpleIdentifier).name, 'a');
    expect(((typeArgs[1] as TypeName).name as SimpleIdentifier).name, 'b');
  }

  void test_three_identifiers() {
    var functionReference = parseExpression('prefix.ClassName.m<a, b>',
        featureSet: constructorTearoffs) as FunctionReference;
    var function = functionReference.function as PropertyAccess;
    var target = function.target as PrefixedIdentifier;
    expect(target.prefix.name, 'prefix');
    expect(target.identifier.name, 'ClassName');
    expect(function.propertyName.name, 'm');
    var typeArgs = functionReference.typeArguments!.arguments;
    expect(typeArgs, hasLength(2));
    expect(((typeArgs[0] as TypeName).name as SimpleIdentifier).name, 'a');
    expect(((typeArgs[1] as TypeName).name as SimpleIdentifier).name, 'b');
  }
}
