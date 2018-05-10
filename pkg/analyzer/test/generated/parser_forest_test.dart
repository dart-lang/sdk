// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/fasta/body_builder_test_helper.dart';
import 'parser_test.dart';

main() async {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExpressionParserTest_Forest);
  });
}

/**
 * Tests of the fasta parser based on [ExpressionParserTestMixin].
 */
@reflectiveTest
class ExpressionParserTest_Forest extends FastaBodyBuilderTestCase
    with ExpressionParserTestMixin {
  ExpressionParserTest_Forest() : super(false);

  @failingTest
  void test_namedArgument() {
    super.test_namedArgument();
  }

  @failingTest
  void test_parseAdditiveExpression_normal() {
    super.test_parseAdditiveExpression_normal();
  }

  @failingTest
  void test_parseAdditiveExpression_super() {
    super.test_parseAdditiveExpression_super();
  }

  @failingTest
  void test_parseAssignableExpression_expression_args_dot() {
    super.test_parseAssignableExpression_expression_args_dot();
  }

  @failingTest
  void
      test_parseAssignableExpression_expression_args_dot_typeArgumentComments() {
    super
        .test_parseAssignableExpression_expression_args_dot_typeArgumentComments();
  }

  @failingTest
  void test_parseAssignableExpression_expression_args_dot_typeArguments() {
    super.test_parseAssignableExpression_expression_args_dot_typeArguments();
  }

  @failingTest
  void test_parseAssignableExpression_expression_dot() {
    super.test_parseAssignableExpression_expression_dot();
  }

  @failingTest
  void test_parseAssignableExpression_expression_index() {
    super.test_parseAssignableExpression_expression_index();
  }

  @failingTest
  void test_parseAssignableExpression_expression_question_dot() {
    super.test_parseAssignableExpression_expression_question_dot();
  }

  @failingTest
  void test_parseAssignableExpression_identifier() {
    super.test_parseAssignableExpression_identifier();
  }

  @failingTest
  void test_parseAssignableExpression_identifier_args_dot() {
    super.test_parseAssignableExpression_identifier_args_dot();
  }

  @failingTest
  void
      test_parseAssignableExpression_identifier_args_dot_typeArgumentComments() {
    super
        .test_parseAssignableExpression_identifier_args_dot_typeArgumentComments();
  }

  @failingTest
  void test_parseAssignableExpression_identifier_args_dot_typeArguments() {
    super.test_parseAssignableExpression_identifier_args_dot_typeArguments();
  }

  @failingTest
  void test_parseAssignableExpression_identifier_dot() {
    super.test_parseAssignableExpression_identifier_dot();
  }

  @failingTest
  void test_parseAssignableExpression_identifier_index() {
    super.test_parseAssignableExpression_identifier_index();
  }

  @failingTest
  void test_parseAssignableExpression_identifier_question_dot() {
    super.test_parseAssignableExpression_identifier_question_dot();
  }

  @failingTest
  void test_parseAssignableExpression_super_dot() {
    super.test_parseAssignableExpression_super_dot();
  }

  @failingTest
  void test_parseAssignableExpression_super_index() {
    super.test_parseAssignableExpression_super_index();
  }

  @failingTest
  void test_parseAssignableSelector_dot() {
    super.test_parseAssignableSelector_dot();
  }

  @failingTest
  void test_parseAssignableSelector_index() {
    super.test_parseAssignableSelector_index();
  }

  @failingTest
  void test_parseAssignableSelector_none() {
    super.test_parseAssignableSelector_none();
  }

  @failingTest
  void test_parseAssignableSelector_question_dot() {
    super.test_parseAssignableSelector_question_dot();
  }

  @failingTest
  void test_parseAwaitExpression() {
    super.test_parseAwaitExpression();
  }

  @failingTest
  void test_parseBitwiseAndExpression_normal() {
    super.test_parseBitwiseAndExpression_normal();
  }

  @failingTest
  void test_parseBitwiseAndExpression_super() {
    super.test_parseBitwiseAndExpression_super();
  }

  @failingTest
  void test_parseBitwiseOrExpression_normal() {
    super.test_parseBitwiseOrExpression_normal();
  }

  @failingTest
  void test_parseBitwiseOrExpression_super() {
    super.test_parseBitwiseOrExpression_super();
  }

  @failingTest
  void test_parseBitwiseXorExpression_normal() {
    super.test_parseBitwiseXorExpression_normal();
  }

  @failingTest
  void test_parseBitwiseXorExpression_super() {
    super.test_parseBitwiseXorExpression_super();
  }

  @failingTest
  void test_parseCascadeSection_i() {
    super.test_parseCascadeSection_i();
  }

  @failingTest
  void test_parseCascadeSection_ia() {
    super.test_parseCascadeSection_ia();
  }

  @failingTest
  void test_parseCascadeSection_ia_typeArgumentComments() {
    super.test_parseCascadeSection_ia_typeArgumentComments();
  }

  @failingTest
  void test_parseCascadeSection_ia_typeArguments() {
    super.test_parseCascadeSection_ia_typeArguments();
  }

  @failingTest
  void test_parseCascadeSection_ii() {
    super.test_parseCascadeSection_ii();
  }

  @failingTest
  void test_parseCascadeSection_ii_typeArgumentComments() {
    super.test_parseCascadeSection_ii_typeArgumentComments();
  }

  @failingTest
  void test_parseCascadeSection_ii_typeArguments() {
    super.test_parseCascadeSection_ii_typeArguments();
  }

  @failingTest
  void test_parseCascadeSection_p() {
    super.test_parseCascadeSection_p();
  }

  @failingTest
  void test_parseCascadeSection_p_assign() {
    super.test_parseCascadeSection_p_assign();
  }

  @failingTest
  void test_parseCascadeSection_p_assign_withCascade() {
    super.test_parseCascadeSection_p_assign_withCascade();
  }

  @failingTest
  void test_parseCascadeSection_p_assign_withCascade_typeArgumentComments() {
    super.test_parseCascadeSection_p_assign_withCascade_typeArgumentComments();
  }

  @failingTest
  void test_parseCascadeSection_p_assign_withCascade_typeArguments() {
    super.test_parseCascadeSection_p_assign_withCascade_typeArguments();
  }

  @failingTest
  void test_parseCascadeSection_p_builtIn() {
    super.test_parseCascadeSection_p_builtIn();
  }

  @failingTest
  void test_parseCascadeSection_pa() {
    super.test_parseCascadeSection_pa();
  }

  @failingTest
  void test_parseCascadeSection_pa_typeArgumentComments() {
    super.test_parseCascadeSection_pa_typeArgumentComments();
  }

  @failingTest
  void test_parseCascadeSection_pa_typeArguments() {
    super.test_parseCascadeSection_pa_typeArguments();
  }

  @failingTest
  void test_parseCascadeSection_paa() {
    super.test_parseCascadeSection_paa();
  }

  @failingTest
  void test_parseCascadeSection_paa_typeArgumentComments() {
    super.test_parseCascadeSection_paa_typeArgumentComments();
  }

  @failingTest
  void test_parseCascadeSection_paa_typeArguments() {
    super.test_parseCascadeSection_paa_typeArguments();
  }

  @failingTest
  void test_parseCascadeSection_paapaa() {
    super.test_parseCascadeSection_paapaa();
  }

  @failingTest
  void test_parseCascadeSection_paapaa_typeArgumentComments() {
    super.test_parseCascadeSection_paapaa_typeArgumentComments();
  }

  @failingTest
  void test_parseCascadeSection_paapaa_typeArguments() {
    super.test_parseCascadeSection_paapaa_typeArguments();
  }

  @failingTest
  void test_parseCascadeSection_pap() {
    super.test_parseCascadeSection_pap();
  }

  @failingTest
  void test_parseCascadeSection_pap_typeArgumentComments() {
    super.test_parseCascadeSection_pap_typeArgumentComments();
  }

  @failingTest
  void test_parseCascadeSection_pap_typeArguments() {
    super.test_parseCascadeSection_pap_typeArguments();
  }

  @failingTest
  void test_parseConditionalExpression() {
    super.test_parseConditionalExpression();
  }

  @failingTest
  void test_parseConstExpression_instanceCreation() {
    super.test_parseConstExpression_instanceCreation();
  }

  @failingTest
  void test_parseConstExpression_listLiteral_typed() {
    super.test_parseConstExpression_listLiteral_typed();
  }

  @failingTest
  void test_parseConstExpression_listLiteral_typed_genericComment() {
    super.test_parseConstExpression_listLiteral_typed_genericComment();
  }

  @failingTest
  void test_parseConstExpression_mapLiteral_typed() {
    super.test_parseConstExpression_mapLiteral_typed();
  }

  @failingTest
  void test_parseConstExpression_mapLiteral_typed_genericComment() {
    super.test_parseConstExpression_mapLiteral_typed_genericComment();
  }

  @failingTest
  void test_parseEqualityExpression_normal() {
    super.test_parseEqualityExpression_normal();
  }

  @failingTest
  void test_parseEqualityExpression_super() {
    super.test_parseEqualityExpression_super();
  }

  @failingTest
  void test_parseExpression_assign() {
    super.test_parseExpression_assign();
  }

  @failingTest
  void test_parseExpression_assign_compound() {
    super.test_parseExpression_assign_compound();
  }

  @failingTest
  void test_parseExpression_comparison() {
    super.test_parseExpression_comparison();
  }

  @failingTest
  void test_parseExpression_function_async() {
    super.test_parseExpression_function_async();
  }

  @failingTest
  void test_parseExpression_function_asyncStar() {
    super.test_parseExpression_function_asyncStar();
  }

  @failingTest
  void test_parseExpression_function_sync() {
    super.test_parseExpression_function_sync();
  }

  @failingTest
  void test_parseExpression_function_syncStar() {
    super.test_parseExpression_function_syncStar();
  }

  @failingTest
  void test_parseExpression_invokeFunctionExpression() {
    super.test_parseExpression_invokeFunctionExpression();
  }

  @failingTest
  void test_parseExpression_nonAwait() {
    super.test_parseExpression_nonAwait();
  }

  @failingTest
  void test_parseExpression_superMethodInvocation() {
    super.test_parseExpression_superMethodInvocation();
  }

  @failingTest
  void test_parseExpression_superMethodInvocation_typeArgumentComments() {
    super.test_parseExpression_superMethodInvocation_typeArgumentComments();
  }

  @failingTest
  void test_parseExpression_superMethodInvocation_typeArguments() {
    super.test_parseExpression_superMethodInvocation_typeArguments();
  }

  @failingTest
  void test_parseExpression_superMethodInvocation_typeArguments_chained() {
    super.test_parseExpression_superMethodInvocation_typeArguments_chained();
  }

  @failingTest
  void test_parseExpressionList_multiple() {
    super.test_parseExpressionList_multiple();
  }

  @failingTest
  void test_parseExpressionList_single() {
    super.test_parseExpressionList_single();
  }

  @failingTest
  void test_parseExpressionWithoutCascade_assign() {
    super.test_parseExpressionWithoutCascade_assign();
  }

  @failingTest
  void test_parseExpressionWithoutCascade_comparison() {
    super.test_parseExpressionWithoutCascade_comparison();
  }

  @failingTest
  void test_parseExpressionWithoutCascade_superMethodInvocation() {
    super.test_parseExpressionWithoutCascade_superMethodInvocation();
  }

  @failingTest
  void
      test_parseExpressionWithoutCascade_superMethodInvocation_typeArgumentComments() {
    super
        .test_parseExpressionWithoutCascade_superMethodInvocation_typeArgumentComments();
  }

  @failingTest
  void
      test_parseExpressionWithoutCascade_superMethodInvocation_typeArguments() {
    super
        .test_parseExpressionWithoutCascade_superMethodInvocation_typeArguments();
  }

  @failingTest
  void test_parseFunctionExpression_body_inExpression() {
    super.test_parseFunctionExpression_body_inExpression();
  }

  @failingTest
  void test_parseFunctionExpression_typeParameterComments() {
    super.test_parseFunctionExpression_typeParameterComments();
  }

  @failingTest
  void test_parseFunctionExpression_typeParameters() {
    super.test_parseFunctionExpression_typeParameters();
  }

  @failingTest
  void test_parseInstanceCreationExpression_qualifiedType() {
    super.test_parseInstanceCreationExpression_qualifiedType();
  }

  @failingTest
  void test_parseInstanceCreationExpression_qualifiedType_named() {
    super.test_parseInstanceCreationExpression_qualifiedType_named();
  }

  @failingTest
  void
      test_parseInstanceCreationExpression_qualifiedType_named_typeArgumentComments() {
    super
        .test_parseInstanceCreationExpression_qualifiedType_named_typeArgumentComments();
  }

  @failingTest
  void
      test_parseInstanceCreationExpression_qualifiedType_named_typeArguments() {
    super
        .test_parseInstanceCreationExpression_qualifiedType_named_typeArguments();
  }

  @failingTest
  void
      test_parseInstanceCreationExpression_qualifiedType_typeArgumentComments() {
    super
        .test_parseInstanceCreationExpression_qualifiedType_typeArgumentComments();
  }

  @failingTest
  void test_parseInstanceCreationExpression_qualifiedType_typeArguments() {
    super.test_parseInstanceCreationExpression_qualifiedType_typeArguments();
  }

  @failingTest
  void test_parseInstanceCreationExpression_type() {
    super.test_parseInstanceCreationExpression_type();
  }

  @failingTest
  void test_parseInstanceCreationExpression_type_named() {
    super.test_parseInstanceCreationExpression_type_named();
  }

  @failingTest
  void test_parseInstanceCreationExpression_type_named_typeArgumentComments() {
    super
        .test_parseInstanceCreationExpression_type_named_typeArgumentComments();
  }

  @failingTest
  void test_parseInstanceCreationExpression_type_named_typeArguments() {
    super.test_parseInstanceCreationExpression_type_named_typeArguments();
  }

  @failingTest
  void test_parseInstanceCreationExpression_type_typeArgumentComments() {
    super.test_parseInstanceCreationExpression_type_typeArgumentComments();
  }

  @failingTest
  void test_parseInstanceCreationExpression_type_typeArguments() {
    super.test_parseInstanceCreationExpression_type_typeArguments();
  }

  @failingTest
  void test_parseListLiteral_empty_oneToken() {
    super.test_parseListLiteral_empty_oneToken();
  }

  @failingTest
  void test_parseListLiteral_empty_oneToken_withComment() {
    super.test_parseListLiteral_empty_oneToken_withComment();
  }

  @failingTest
  void test_parseListLiteral_empty_twoTokens() {
    super.test_parseListLiteral_empty_twoTokens();
  }

  @failingTest
  void test_parseListLiteral_single_withTypeArgument() {
    super.test_parseListLiteral_single_withTypeArgument();
  }

  @failingTest
  void test_parseListOrMapLiteral_list_type() {
    super.test_parseListOrMapLiteral_list_type();
  }

  @failingTest
  void test_parseListOrMapLiteral_map_noType() {
    super.test_parseListOrMapLiteral_map_noType();
  }

  @failingTest
  void test_parseListOrMapLiteral_map_type() {
    super.test_parseListOrMapLiteral_map_type();
  }

  @failingTest
  void test_parseLogicalAndExpression() {
    super.test_parseLogicalAndExpression();
  }

  @failingTest
  void test_parseLogicalOrExpression() {
    super.test_parseLogicalOrExpression();
  }

  @failingTest
  void test_parseMapLiteral_empty() {
    super.test_parseMapLiteral_empty();
  }

  @failingTest
  void test_parseMapLiteral_multiple() {
    super.test_parseMapLiteral_multiple();
  }

  @failingTest
  void test_parseMapLiteral_single() {
    super.test_parseMapLiteral_single();
  }

  @failingTest
  void test_parseMapLiteralEntry_complex() {
    super.test_parseMapLiteralEntry_complex();
  }

  @failingTest
  void test_parseMapLiteralEntry_int() {
    super.test_parseMapLiteralEntry_int();
  }

  @failingTest
  void test_parseMapLiteralEntry_string() {
    super.test_parseMapLiteralEntry_string();
  }

  @failingTest
  void test_parseMultiplicativeExpression_normal() {
    super.test_parseMultiplicativeExpression_normal();
  }

  @failingTest
  void test_parseMultiplicativeExpression_super() {
    super.test_parseMultiplicativeExpression_super();
  }

  @failingTest
  void test_parseNewExpression() {
    super.test_parseNewExpression();
  }

  @failingTest
  void test_parsePostfixExpression_decrement() {
    super.test_parsePostfixExpression_decrement();
  }

  @failingTest
  void test_parsePostfixExpression_increment() {
    super.test_parsePostfixExpression_increment();
  }

  @failingTest
  void test_parsePostfixExpression_none_indexExpression() {
    super.test_parsePostfixExpression_none_indexExpression();
  }

  @failingTest
  void test_parsePostfixExpression_none_methodInvocation() {
    super.test_parsePostfixExpression_none_methodInvocation();
  }

  @failingTest
  void test_parsePostfixExpression_none_methodInvocation_question_dot() {
    super.test_parsePostfixExpression_none_methodInvocation_question_dot();
  }

  @failingTest
  void
      test_parsePostfixExpression_none_methodInvocation_question_dot_typeArgumentComments() {
    super
        .test_parsePostfixExpression_none_methodInvocation_question_dot_typeArgumentComments();
  }

  @failingTest
  void
      test_parsePostfixExpression_none_methodInvocation_question_dot_typeArguments() {
    super
        .test_parsePostfixExpression_none_methodInvocation_question_dot_typeArguments();
  }

  @failingTest
  void
      test_parsePostfixExpression_none_methodInvocation_typeArgumentComments() {
    super
        .test_parsePostfixExpression_none_methodInvocation_typeArgumentComments();
  }

  @failingTest
  void test_parsePostfixExpression_none_methodInvocation_typeArguments() {
    super.test_parsePostfixExpression_none_methodInvocation_typeArguments();
  }

  @failingTest
  void test_parsePostfixExpression_none_propertyAccess() {
    super.test_parsePostfixExpression_none_propertyAccess();
  }

  @failingTest
  void test_parsePrefixedIdentifier_noPrefix() {
    super.test_parsePrefixedIdentifier_noPrefix();
  }

  @failingTest
  void test_parsePrefixedIdentifier_prefix() {
    super.test_parsePrefixedIdentifier_prefix();
  }

  @failingTest
  void test_parsePrimaryExpression_const() {
    super.test_parsePrimaryExpression_const();
  }

  @failingTest
  void test_parsePrimaryExpression_function_arguments() {
    super.test_parsePrimaryExpression_function_arguments();
  }

  @failingTest
  void test_parsePrimaryExpression_function_noArguments() {
    super.test_parsePrimaryExpression_function_noArguments();
  }

  @failingTest
  void test_parsePrimaryExpression_genericFunctionExpression() {
    super.test_parsePrimaryExpression_genericFunctionExpression();
  }

  @failingTest
  void test_parsePrimaryExpression_identifier() {
    super.test_parsePrimaryExpression_identifier();
  }

  @failingTest
  void test_parsePrimaryExpression_listLiteral_typed() {
    super.test_parsePrimaryExpression_listLiteral_typed();
  }

  @failingTest
  void test_parsePrimaryExpression_listLiteral_typed_genericComment() {
    super.test_parsePrimaryExpression_listLiteral_typed_genericComment();
  }

  @failingTest
  void test_parsePrimaryExpression_mapLiteral_typed() {
    super.test_parsePrimaryExpression_mapLiteral_typed();
  }

  @failingTest
  void test_parsePrimaryExpression_mapLiteral_typed_genericComment() {
    super.test_parsePrimaryExpression_mapLiteral_typed_genericComment();
  }

  @failingTest
  void test_parsePrimaryExpression_new() {
    super.test_parsePrimaryExpression_new();
  }

  @failingTest
  void test_parsePrimaryExpression_parenthesized() {
    super.test_parsePrimaryExpression_parenthesized();
  }

  @failingTest
  void test_parsePrimaryExpression_super() {
    super.test_parsePrimaryExpression_super();
  }

  @failingTest
  void test_parsePrimaryExpression_this() {
    super.test_parsePrimaryExpression_this();
  }

  @failingTest
  void test_parseRedirectingConstructorInvocation_named() {
    super.test_parseRedirectingConstructorInvocation_named();
  }

  @failingTest
  void test_parseRedirectingConstructorInvocation_unnamed() {
    super.test_parseRedirectingConstructorInvocation_unnamed();
  }

  @failingTest
  void test_parseRelationalExpression_as_functionType_noReturnType() {
    super.test_parseRelationalExpression_as_functionType_noReturnType();
  }

  @failingTest
  void test_parseRelationalExpression_as_functionType_returnType() {
    super.test_parseRelationalExpression_as_functionType_returnType();
  }

  @failingTest
  void test_parseRelationalExpression_as_generic() {
    super.test_parseRelationalExpression_as_generic();
  }

  @failingTest
  void test_parseRelationalExpression_as_simple() {
    super.test_parseRelationalExpression_as_simple();
  }

  @failingTest
  void test_parseRelationalExpression_as_simple_function() {
    super.test_parseRelationalExpression_as_simple_function();
  }

  @failingTest
  void test_parseRelationalExpression_is() {
    super.test_parseRelationalExpression_is();
  }

  @failingTest
  void test_parseRelationalExpression_isNot() {
    super.test_parseRelationalExpression_isNot();
  }

  @failingTest
  void test_parseRelationalExpression_normal() {
    super.test_parseRelationalExpression_normal();
  }

  @failingTest
  void test_parseRelationalExpression_super() {
    super.test_parseRelationalExpression_super();
  }

  @failingTest
  void test_parseRethrowExpression() {
    super.test_parseRethrowExpression();
  }

  @failingTest
  void test_parseShiftExpression_normal() {
    super.test_parseShiftExpression_normal();
  }

  @failingTest
  void test_parseShiftExpression_super() {
    super.test_parseShiftExpression_super();
  }

  @failingTest
  void test_parseSimpleIdentifier_builtInIdentifier() {
    super.test_parseSimpleIdentifier_builtInIdentifier();
  }

  @failingTest
  void test_parseSimpleIdentifier_normalIdentifier() {
    super.test_parseSimpleIdentifier_normalIdentifier();
  }

  @failingTest
  void test_parseStringLiteral_adjacent() {
    super.test_parseStringLiteral_adjacent();
  }

  @failingTest
  void test_parseStringLiteral_endsWithInterpolation() {
    super.test_parseStringLiteral_endsWithInterpolation();
  }

  @failingTest
  void test_parseStringLiteral_interpolated() {
    super.test_parseStringLiteral_interpolated();
  }

  @failingTest
  void test_parseStringLiteral_multiline_endsWithInterpolation() {
    super.test_parseStringLiteral_multiline_endsWithInterpolation();
  }

  @failingTest
  void test_parseStringLiteral_multiline_quoteAfterInterpolation() {
    super.test_parseStringLiteral_multiline_quoteAfterInterpolation();
  }

  @failingTest
  void test_parseStringLiteral_multiline_startsWithInterpolation() {
    super.test_parseStringLiteral_multiline_startsWithInterpolation();
  }

  @failingTest
  void test_parseStringLiteral_quoteAfterInterpolation() {
    super.test_parseStringLiteral_quoteAfterInterpolation();
  }

  @failingTest
  void test_parseStringLiteral_startsWithInterpolation() {
    super.test_parseStringLiteral_startsWithInterpolation();
  }

  @failingTest
  void test_parseSuperConstructorInvocation_named() {
    super.test_parseSuperConstructorInvocation_named();
  }

  @failingTest
  void test_parseSuperConstructorInvocation_unnamed() {
    super.test_parseSuperConstructorInvocation_unnamed();
  }

  @failingTest
  void test_parseSymbolLiteral_builtInIdentifier() {
    super.test_parseSymbolLiteral_builtInIdentifier();
  }

  @failingTest
  void test_parseSymbolLiteral_multiple() {
    super.test_parseSymbolLiteral_multiple();
  }

  @failingTest
  void test_parseSymbolLiteral_operator() {
    super.test_parseSymbolLiteral_operator();
  }

  @failingTest
  void test_parseSymbolLiteral_single() {
    super.test_parseSymbolLiteral_single();
  }

  @failingTest
  void test_parseSymbolLiteral_void() {
    super.test_parseSymbolLiteral_void();
  }

  @failingTest
  void test_parseThrowExpression() {
    super.test_parseThrowExpression();
  }

  @failingTest
  void test_parseThrowExpressionWithoutCascade() {
    super.test_parseThrowExpressionWithoutCascade();
  }

  @failingTest
  void test_parseUnaryExpression_decrement_normal() {
    super.test_parseUnaryExpression_decrement_normal();
  }

  @failingTest
  void test_parseUnaryExpression_decrement_super() {
    super.test_parseUnaryExpression_decrement_super();
  }

  @failingTest
  void test_parseUnaryExpression_decrement_super_propertyAccess() {
    super.test_parseUnaryExpression_decrement_super_propertyAccess();
  }

  @failingTest
  void test_parseUnaryExpression_decrement_super_withComment() {
    super.test_parseUnaryExpression_decrement_super_withComment();
  }

  @failingTest
  void test_parseUnaryExpression_increment_normal() {
    super.test_parseUnaryExpression_increment_normal();
  }

  @failingTest
  void test_parseUnaryExpression_increment_super_index() {
    super.test_parseUnaryExpression_increment_super_index();
  }

  @failingTest
  void test_parseUnaryExpression_increment_super_propertyAccess() {
    super.test_parseUnaryExpression_increment_super_propertyAccess();
  }

  @failingTest
  void test_parseUnaryExpression_minus_normal() {
    super.test_parseUnaryExpression_minus_normal();
  }

  @failingTest
  void test_parseUnaryExpression_minus_super() {
    super.test_parseUnaryExpression_minus_super();
  }

  @failingTest
  void test_parseUnaryExpression_not_normal() {
    super.test_parseUnaryExpression_not_normal();
  }

  @failingTest
  void test_parseUnaryExpression_not_super() {
    super.test_parseUnaryExpression_not_super();
  }

  @failingTest
  void test_parseUnaryExpression_tilda_normal() {
    super.test_parseUnaryExpression_tilda_normal();
  }

  @failingTest
  void test_parseUnaryExpression_tilda_super() {
    super.test_parseUnaryExpression_tilda_super();
  }
}
