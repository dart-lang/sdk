// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/fasta/body_builder_test_helper.dart';
import 'parser_test.dart';

main() async {
  defineReflectiveSuite(() {
    // TODO(brianwilkerson) Implement the remaining parser tests.
//    defineReflectiveTests(ClassMemberParserTest_Forest);
//    defineReflectiveTests(ComplexParserTest_Forest);
//    defineReflectiveTests(ErrorParserTest_Forest);
    defineReflectiveTests(ExpressionParserTest_Forest);
//    defineReflectiveTests(FormalParameterParserTest_Forest);
//    defineReflectiveTests(NonErrorParserTest_Forest);
//    defineReflectiveTests(RecoveryParserTest_Forest);
//    defineReflectiveTests(SimpleParserTest_Forest);
    defineReflectiveTests(StatementParserTest_Forest);
    defineReflectiveTests(TopLevelParserTest_Forest);
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

/**
 * Tests of the fasta parser based on [StatementParserTestMixin].
 */
@reflectiveTest
class StatementParserTest_Forest extends FastaBodyBuilderTestCase
    with StatementParserTestMixin {
  StatementParserTest_Forest() : super(false);

  @failingTest
  void test_invalid_typeParamAnnotation() {
    super.test_invalid_typeParamAnnotation();
  }

  @failingTest
  void test_invalid_typeParamAnnotation2() {
    super.test_invalid_typeParamAnnotation2();
  }

  @failingTest
  void test_invalid_typeParamAnnotation3() {
    super.test_invalid_typeParamAnnotation3();
  }

  @failingTest
  void test_parseAssertStatement() {
    super.test_parseAssertStatement();
  }

  @failingTest
  void test_parseAssertStatement_messageLowPrecedence() {
    super.test_parseAssertStatement_messageLowPrecedence();
  }

  @failingTest
  void test_parseAssertStatement_messageString() {
    super.test_parseAssertStatement_messageString();
  }

  @failingTest
  void test_parseAssertStatement_trailingComma_message() {
    super.test_parseAssertStatement_trailingComma_message();
  }

  @failingTest
  void test_parseAssertStatement_trailingComma_noMessage() {
    super.test_parseAssertStatement_trailingComma_noMessage();
  }

  @failingTest
  void test_parseBlock_empty() {
    super.test_parseBlock_empty();
  }

  @failingTest
  void test_parseBlock_nonEmpty() {
    super.test_parseBlock_nonEmpty();
  }

  @failingTest
  void test_parseBreakStatement_label() {
    super.test_parseBreakStatement_label();
  }

  @failingTest
  void test_parseBreakStatement_noLabel() {
    super.test_parseBreakStatement_noLabel();
  }

  @failingTest
  void test_parseContinueStatement_label() {
    super.test_parseContinueStatement_label();
  }

  @failingTest
  void test_parseContinueStatement_noLabel() {
    super.test_parseContinueStatement_noLabel();
  }

  @failingTest
  void test_parseDoStatement() {
    super.test_parseDoStatement();
  }

  @failingTest
  void test_parseEmptyStatement() {
    super.test_parseEmptyStatement();
  }

  @failingTest
  void test_parseForStatement_each_await() {
    super.test_parseForStatement_each_await();
  }

  @failingTest
  void test_parseForStatement_each_genericFunctionType() {
    super.test_parseForStatement_each_genericFunctionType();
  }

  @failingTest
  void test_parseForStatement_each_identifier() {
    super.test_parseForStatement_each_identifier();
  }

  @failingTest
  void test_parseForStatement_each_noType_metadata() {
    super.test_parseForStatement_each_noType_metadata();
  }

  @failingTest
  void test_parseForStatement_each_type() {
    super.test_parseForStatement_each_type();
  }

  @failingTest
  void test_parseForStatement_each_var() {
    super.test_parseForStatement_each_var();
  }

  @failingTest
  void test_parseForStatement_loop_c() {
    super.test_parseForStatement_loop_c();
  }

  @failingTest
  void test_parseForStatement_loop_cu() {
    super.test_parseForStatement_loop_cu();
  }

  @failingTest
  void test_parseForStatement_loop_ecu() {
    super.test_parseForStatement_loop_ecu();
  }

  @failingTest
  void test_parseForStatement_loop_i() {
    super.test_parseForStatement_loop_i();
  }

  @failingTest
  void test_parseForStatement_loop_i_withMetadata() {
    super.test_parseForStatement_loop_i_withMetadata();
  }

  @failingTest
  void test_parseForStatement_loop_ic() {
    super.test_parseForStatement_loop_ic();
  }

  @failingTest
  void test_parseForStatement_loop_icu() {
    super.test_parseForStatement_loop_icu();
  }

  @failingTest
  void test_parseForStatement_loop_iicuu() {
    super.test_parseForStatement_loop_iicuu();
  }

  @failingTest
  void test_parseForStatement_loop_iu() {
    super.test_parseForStatement_loop_iu();
  }

  @failingTest
  void test_parseForStatement_loop_u() {
    super.test_parseForStatement_loop_u();
  }

  @failingTest
  void test_parseFunctionDeclarationStatement() {
    super.test_parseFunctionDeclarationStatement();
  }

  @failingTest
  void test_parseFunctionDeclarationStatement_typeParameterComments() {
    super.test_parseFunctionDeclarationStatement_typeParameterComments();
  }

  @failingTest
  void test_parseFunctionDeclarationStatement_typeParameters() {
    super.test_parseFunctionDeclarationStatement_typeParameters();
  }

  @failingTest
  void test_parseFunctionDeclarationStatement_typeParameters_noReturnType() {
    super.test_parseFunctionDeclarationStatement_typeParameters_noReturnType();
  }

  @failingTest
  void test_parseIfStatement_else_block() {
    super.test_parseIfStatement_else_block();
  }

  @failingTest
  void test_parseIfStatement_else_statement() {
    super.test_parseIfStatement_else_statement();
  }

  @failingTest
  void test_parseIfStatement_noElse_block() {
    super.test_parseIfStatement_noElse_block();
  }

  @failingTest
  void test_parseIfStatement_noElse_statement() {
    super.test_parseIfStatement_noElse_statement();
  }

  @failingTest
  void test_parseNonLabeledStatement_const_list_empty() {
    super.test_parseNonLabeledStatement_const_list_empty();
  }

  @failingTest
  void test_parseNonLabeledStatement_const_list_nonEmpty() {
    super.test_parseNonLabeledStatement_const_list_nonEmpty();
  }

  @failingTest
  void test_parseNonLabeledStatement_const_map_empty() {
    super.test_parseNonLabeledStatement_const_map_empty();
  }

  @failingTest
  void test_parseNonLabeledStatement_const_map_nonEmpty() {
    super.test_parseNonLabeledStatement_const_map_nonEmpty();
  }

  @failingTest
  void test_parseNonLabeledStatement_const_object() {
    super.test_parseNonLabeledStatement_const_object();
  }

  @failingTest
  void test_parseNonLabeledStatement_const_object_named_typeParameters() {
    super.test_parseNonLabeledStatement_const_object_named_typeParameters();
  }

  @failingTest
  void test_parseNonLabeledStatement_constructorInvocation() {
    super.test_parseNonLabeledStatement_constructorInvocation();
  }

  @failingTest
  void test_parseNonLabeledStatement_false() {
    super.test_parseNonLabeledStatement_false();
  }

  @failingTest
  void test_parseNonLabeledStatement_functionDeclaration() {
    super.test_parseNonLabeledStatement_functionDeclaration();
  }

  @failingTest
  void test_parseNonLabeledStatement_functionDeclaration_arguments() {
    super.test_parseNonLabeledStatement_functionDeclaration_arguments();
  }

  @failingTest
  void test_parseNonLabeledStatement_functionExpressionIndex() {
    super.test_parseNonLabeledStatement_functionExpressionIndex();
  }

  @failingTest
  void test_parseNonLabeledStatement_functionInvocation() {
    super.test_parseNonLabeledStatement_functionInvocation();
  }

  @failingTest
  void test_parseNonLabeledStatement_invokeFunctionExpression() {
    super.test_parseNonLabeledStatement_invokeFunctionExpression();
  }

  @failingTest
  void test_parseNonLabeledStatement_localFunction_gftReturnType() {
    super.test_parseNonLabeledStatement_localFunction_gftReturnType();
  }

  @failingTest
  void test_parseNonLabeledStatement_null() {
    super.test_parseNonLabeledStatement_null();
  }

  @failingTest
  void test_parseNonLabeledStatement_startingWithBuiltInIdentifier() {
    super.test_parseNonLabeledStatement_startingWithBuiltInIdentifier();
  }

  @failingTest
  void test_parseNonLabeledStatement_true() {
    super.test_parseNonLabeledStatement_true();
  }

  @failingTest
  void test_parseNonLabeledStatement_typeCast() {
    super.test_parseNonLabeledStatement_typeCast();
  }

  @failingTest
  void test_parseNonLabeledStatement_variableDeclaration_final_namedFunction() {
    super
        .test_parseNonLabeledStatement_variableDeclaration_final_namedFunction();
  }

  @failingTest
  void test_parseNonLabeledStatement_variableDeclaration_gftType() {
    super.test_parseNonLabeledStatement_variableDeclaration_gftType();
  }

  @failingTest
  void
      test_parseNonLabeledStatement_variableDeclaration_gftType_functionReturnType() {
    super
        .test_parseNonLabeledStatement_variableDeclaration_gftType_functionReturnType();
  }

  @failingTest
  void
      test_parseNonLabeledStatement_variableDeclaration_gftType_gftReturnType() {
    super
        .test_parseNonLabeledStatement_variableDeclaration_gftType_gftReturnType();
  }

  @failingTest
  void
      test_parseNonLabeledStatement_variableDeclaration_gftType_gftReturnType2() {
    super
        .test_parseNonLabeledStatement_variableDeclaration_gftType_gftReturnType2();
  }

  @failingTest
  void
      test_parseNonLabeledStatement_variableDeclaration_gftType_noReturnType() {
    super
        .test_parseNonLabeledStatement_variableDeclaration_gftType_noReturnType();
  }

  @failingTest
  void test_parseNonLabeledStatement_variableDeclaration_gftType_returnType() {
    super
        .test_parseNonLabeledStatement_variableDeclaration_gftType_returnType();
  }

  @failingTest
  void
      test_parseNonLabeledStatement_variableDeclaration_gftType_voidReturnType() {
    super
        .test_parseNonLabeledStatement_variableDeclaration_gftType_voidReturnType();
  }

  @failingTest
  void test_parseNonLabeledStatement_variableDeclaration_typeParam() {
    super.test_parseNonLabeledStatement_variableDeclaration_typeParam();
  }

  @failingTest
  void test_parseNonLabeledStatement_variableDeclaration_typeParam2() {
    super.test_parseNonLabeledStatement_variableDeclaration_typeParam2();
  }

  @failingTest
  void test_parseNonLabeledStatement_variableDeclaration_typeParam3() {
    super.test_parseNonLabeledStatement_variableDeclaration_typeParam3();
  }

  @failingTest
  void test_parseStatement_emptyTypeArgumentList() {
    super.test_parseStatement_emptyTypeArgumentList();
  }

  @failingTest
  void test_parseStatement_function_gftReturnType() {
    super.test_parseStatement_function_gftReturnType();
  }

  @failingTest
  void test_parseStatement_functionDeclaration_noReturnType() {
    super.test_parseStatement_functionDeclaration_noReturnType();
  }

  @failingTest
  void
      test_parseStatement_functionDeclaration_noReturnType_typeParameterComments() {
    super
        .test_parseStatement_functionDeclaration_noReturnType_typeParameterComments();
  }

  @failingTest
  void test_parseStatement_functionDeclaration_noReturnType_typeParameters() {
    super.test_parseStatement_functionDeclaration_noReturnType_typeParameters();
  }

  @failingTest
  void test_parseStatement_functionDeclaration_returnType() {
    super.test_parseStatement_functionDeclaration_returnType();
  }

  @failingTest
  void test_parseStatement_functionDeclaration_returnType_typeParameters() {
    super.test_parseStatement_functionDeclaration_returnType_typeParameters();
  }

  @failingTest
  void test_parseStatement_multipleLabels() {
    super.test_parseStatement_multipleLabels();
  }

  @failingTest
  void test_parseStatement_noLabels() {
    super.test_parseStatement_noLabels();
  }

  @failingTest
  void test_parseStatement_singleLabel() {
    super.test_parseStatement_singleLabel();
  }

  @failingTest
  void test_parseSwitchStatement_case() {
    super.test_parseSwitchStatement_case();
  }

  @failingTest
  void test_parseSwitchStatement_empty() {
    super.test_parseSwitchStatement_empty();
  }

  @failingTest
  void test_parseSwitchStatement_labeledCase() {
    super.test_parseSwitchStatement_labeledCase();
  }

  @failingTest
  void test_parseSwitchStatement_labeledDefault() {
    super.test_parseSwitchStatement_labeledDefault();
  }

  @failingTest
  void test_parseSwitchStatement_labeledStatementInCase() {
    super.test_parseSwitchStatement_labeledStatementInCase();
  }

  @failingTest
  void test_parseTryStatement_catch() {
    super.test_parseTryStatement_catch();
  }

  @failingTest
  void test_parseTryStatement_catch_error_missingCatchParam() {
    super.test_parseTryStatement_catch_error_missingCatchParam();
  }

  @failingTest
  void test_parseTryStatement_catch_error_missingCatchParen() {
    super.test_parseTryStatement_catch_error_missingCatchParen();
  }

  @failingTest
  void test_parseTryStatement_catch_error_missingCatchTrace() {
    super.test_parseTryStatement_catch_error_missingCatchTrace();
  }

  @failingTest
  void test_parseTryStatement_catch_finally() {
    super.test_parseTryStatement_catch_finally();
  }

  @failingTest
  void test_parseTryStatement_finally() {
    super.test_parseTryStatement_finally();
  }

  @failingTest
  void test_parseTryStatement_multiple() {
    super.test_parseTryStatement_multiple();
  }

  @failingTest
  void test_parseTryStatement_on() {
    super.test_parseTryStatement_on();
  }

  @failingTest
  void test_parseTryStatement_on_catch() {
    super.test_parseTryStatement_on_catch();
  }

  @failingTest
  void test_parseTryStatement_on_catch_finally() {
    super.test_parseTryStatement_on_catch_finally();
  }

  @failingTest
  void test_parseVariableDeclaration_equals_builtIn() {
    super.test_parseVariableDeclaration_equals_builtIn();
  }

  @failingTest
  void test_parseVariableDeclarationListAfterMetadata_const_noType() {
    super.test_parseVariableDeclarationListAfterMetadata_const_noType();
  }

  @failingTest
  void test_parseVariableDeclarationListAfterMetadata_const_type() {
    super.test_parseVariableDeclarationListAfterMetadata_const_type();
  }

  @failingTest
  void test_parseVariableDeclarationListAfterMetadata_const_typeComment() {
    super.test_parseVariableDeclarationListAfterMetadata_const_typeComment();
  }

  @failingTest
  void test_parseVariableDeclarationListAfterMetadata_dynamic_typeComment() {
    super.test_parseVariableDeclarationListAfterMetadata_dynamic_typeComment();
  }

  @failingTest
  void test_parseVariableDeclarationListAfterMetadata_final_noType() {
    super.test_parseVariableDeclarationListAfterMetadata_final_noType();
  }

  @failingTest
  void test_parseVariableDeclarationListAfterMetadata_final_type() {
    super.test_parseVariableDeclarationListAfterMetadata_final_type();
  }

  @failingTest
  void test_parseVariableDeclarationListAfterMetadata_final_typeComment() {
    super.test_parseVariableDeclarationListAfterMetadata_final_typeComment();
  }

  @failingTest
  void test_parseVariableDeclarationListAfterMetadata_type_multiple() {
    super.test_parseVariableDeclarationListAfterMetadata_type_multiple();
  }

  @failingTest
  void test_parseVariableDeclarationListAfterMetadata_type_single() {
    super.test_parseVariableDeclarationListAfterMetadata_type_single();
  }

  @failingTest
  void test_parseVariableDeclarationListAfterMetadata_type_typeComment() {
    super.test_parseVariableDeclarationListAfterMetadata_type_typeComment();
  }

  @failingTest
  void test_parseVariableDeclarationListAfterMetadata_var_multiple() {
    super.test_parseVariableDeclarationListAfterMetadata_var_multiple();
  }

  @failingTest
  void test_parseVariableDeclarationListAfterMetadata_var_single() {
    super.test_parseVariableDeclarationListAfterMetadata_var_single();
  }

  @failingTest
  void test_parseVariableDeclarationListAfterMetadata_var_typeComment() {
    super.test_parseVariableDeclarationListAfterMetadata_var_typeComment();
  }

  @failingTest
  void test_parseVariableDeclarationStatementAfterMetadata_multiple() {
    super.test_parseVariableDeclarationStatementAfterMetadata_multiple();
  }

  @failingTest
  void test_parseVariableDeclarationStatementAfterMetadata_single() {
    super.test_parseVariableDeclarationStatementAfterMetadata_single();
  }

  @failingTest
  void test_parseWhileStatement() {
    super.test_parseWhileStatement();
  }

  @failingTest
  void test_parseYieldStatement_each() {
    super.test_parseYieldStatement_each();
  }

  @failingTest
  void test_parseYieldStatement_normal() {
    super.test_parseYieldStatement_normal();
  }
}

@reflectiveTest
class TopLevelParserTest_Forest extends FastaBodyBuilderTestCase
    with TopLevelParserTestMixin {
  TopLevelParserTest_Forest() : super(false);

  @failingTest
  void test_function_literal_allowed_at_toplevel() {
    super.test_function_literal_allowed_at_toplevel();
  }

  @failingTest
  void
      test_function_literal_allowed_in_ArgumentList_in_ConstructorFieldInitializer() {
    super
        .test_function_literal_allowed_in_ArgumentList_in_ConstructorFieldInitializer();
  }

  @failingTest
  void
      test_function_literal_allowed_in_IndexExpression_in_ConstructorFieldInitializer() {
    super
        .test_function_literal_allowed_in_IndexExpression_in_ConstructorFieldInitializer();
  }

  @failingTest
  void
      test_function_literal_allowed_in_ListLiteral_in_ConstructorFieldInitializer() {
    super
        .test_function_literal_allowed_in_ListLiteral_in_ConstructorFieldInitializer();
  }

  @failingTest
  void
      test_function_literal_allowed_in_MapLiteral_in_ConstructorFieldInitializer() {
    super
        .test_function_literal_allowed_in_MapLiteral_in_ConstructorFieldInitializer();
  }

  @failingTest
  void
      test_function_literal_allowed_in_ParenthesizedExpression_in_ConstructorFieldInitializer() {
    super
        .test_function_literal_allowed_in_ParenthesizedExpression_in_ConstructorFieldInitializer();
  }

  @failingTest
  void
      test_function_literal_allowed_in_StringInterpolation_in_ConstructorFieldInitializer() {
    super
        .test_function_literal_allowed_in_StringInterpolation_in_ConstructorFieldInitializer();
  }

  @failingTest
  void test_import_as_show() {
    super.test_import_as_show();
  }

  @failingTest
  void test_import_show_hide() {
    super.test_import_show_hide();
  }

  @failingTest
  void test_import_withDocComment() {
    super.test_import_withDocComment();
  }

  @failingTest
  void test_parseClassDeclaration_abstract() {
    super.test_parseClassDeclaration_abstract();
  }

  @failingTest
  void test_parseClassDeclaration_empty() {
    super.test_parseClassDeclaration_empty();
  }

  @failingTest
  void test_parseClassDeclaration_extends() {
    super.test_parseClassDeclaration_extends();
  }

  @failingTest
  void test_parseClassDeclaration_extendsAndImplements() {
    super.test_parseClassDeclaration_extendsAndImplements();
  }

  @failingTest
  void test_parseClassDeclaration_extendsAndWith() {
    super.test_parseClassDeclaration_extendsAndWith();
  }

  @failingTest
  void test_parseClassDeclaration_extendsAndWithAndImplements() {
    super.test_parseClassDeclaration_extendsAndWithAndImplements();
  }

  @failingTest
  void test_parseClassDeclaration_implements() {
    super.test_parseClassDeclaration_implements();
  }

  @failingTest
  void test_parseClassDeclaration_metadata() {
    super.test_parseClassDeclaration_metadata();
  }

  @failingTest
  void test_parseClassDeclaration_native() {
    super.test_parseClassDeclaration_native();
  }

  @failingTest
  void test_parseClassDeclaration_nonEmpty() {
    super.test_parseClassDeclaration_nonEmpty();
  }

  @failingTest
  void test_parseClassDeclaration_typeAlias_implementsC() {
    super.test_parseClassDeclaration_typeAlias_implementsC();
  }

  @failingTest
  void test_parseClassDeclaration_typeAlias_withB() {
    super.test_parseClassDeclaration_typeAlias_withB();
  }

  @failingTest
  void test_parseClassDeclaration_typeParameters() {
    super.test_parseClassDeclaration_typeParameters();
  }

  @failingTest
  void test_parseClassDeclaration_withDocumentationComment() {
    super.test_parseClassDeclaration_withDocumentationComment();
  }

  @failingTest
  void test_parseClassTypeAlias_withDocumentationComment() {
    super.test_parseClassTypeAlias_withDocumentationComment();
  }

  @failingTest
  void test_parseCompilationUnit_abstractAsPrefix_parameterized() {
    super.test_parseCompilationUnit_abstractAsPrefix_parameterized();
  }

  @failingTest
  void test_parseCompilationUnit_builtIn_asFunctionName() {
    super.test_parseCompilationUnit_builtIn_asFunctionName();
  }

  @failingTest
  void test_parseCompilationUnit_builtIn_asFunctionName_withTypeParameter() {
    super.test_parseCompilationUnit_builtIn_asFunctionName_withTypeParameter();
  }

  @failingTest
  void test_parseCompilationUnit_builtIn_asGetter() {
    super.test_parseCompilationUnit_builtIn_asGetter();
  }

  @failingTest
  void test_parseCompilationUnit_directives_multiple() {
    super.test_parseCompilationUnit_directives_multiple();
  }

  @failingTest
  void test_parseCompilationUnit_directives_single() {
    super.test_parseCompilationUnit_directives_single();
  }

  @failingTest
  void test_parseCompilationUnit_empty() {
    super.test_parseCompilationUnit_empty();
  }

  @failingTest
  void test_parseCompilationUnit_exportAsPrefix() {
    super.test_parseCompilationUnit_exportAsPrefix();
  }

  @failingTest
  void test_parseCompilationUnit_exportAsPrefix_parameterized() {
    super.test_parseCompilationUnit_exportAsPrefix_parameterized();
  }

  @failingTest
  void test_parseCompilationUnit_operatorAsPrefix_parameterized() {
    super.test_parseCompilationUnit_operatorAsPrefix_parameterized();
  }

  @failingTest
  void test_parseCompilationUnit_pseudo_prefixed() {
    super.test_parseCompilationUnit_pseudo_prefixed();
  }

  @failingTest
  void test_parseCompilationUnit_script() {
    super.test_parseCompilationUnit_script();
  }

  @failingTest
  void test_parseCompilationUnit_skipFunctionBody_withInterpolation() {
    super.test_parseCompilationUnit_skipFunctionBody_withInterpolation();
  }

  @failingTest
  void test_parseCompilationUnit_topLevelDeclaration() {
    super.test_parseCompilationUnit_topLevelDeclaration();
  }

  @failingTest
  void test_parseCompilationUnit_typedefAsPrefix() {
    super.test_parseCompilationUnit_typedefAsPrefix();
  }

  @failingTest
  void test_parseCompilationUnitMember_abstractAsPrefix() {
    super.test_parseCompilationUnitMember_abstractAsPrefix();
  }

  @failingTest
  void test_parseCompilationUnitMember_class() {
    super.test_parseCompilationUnitMember_class();
  }

  @failingTest
  void test_parseCompilationUnitMember_classTypeAlias() {
    super.test_parseCompilationUnitMember_classTypeAlias();
  }

  @failingTest
  void test_parseCompilationUnitMember_constVariable() {
    super.test_parseCompilationUnitMember_constVariable();
  }

  @failingTest
  void test_parseCompilationUnitMember_expressionFunctionBody_tokens() {
    super.test_parseCompilationUnitMember_expressionFunctionBody_tokens();
  }

  @failingTest
  void test_parseCompilationUnitMember_finalVariable() {
    super.test_parseCompilationUnitMember_finalVariable();
  }

  @failingTest
  void test_parseCompilationUnitMember_function_external_noType() {
    super.test_parseCompilationUnitMember_function_external_noType();
  }

  @failingTest
  void test_parseCompilationUnitMember_function_external_type() {
    super.test_parseCompilationUnitMember_function_external_type();
  }

  @failingTest
  void test_parseCompilationUnitMember_function_generic_noReturnType() {
    super.test_parseCompilationUnitMember_function_generic_noReturnType();
  }

  @failingTest
  void
      test_parseCompilationUnitMember_function_generic_noReturnType_annotated() {
    super
        .test_parseCompilationUnitMember_function_generic_noReturnType_annotated();
  }

  @failingTest
  void test_parseCompilationUnitMember_function_generic_returnType() {
    super.test_parseCompilationUnitMember_function_generic_returnType();
  }

  @failingTest
  void test_parseCompilationUnitMember_function_generic_void() {
    super.test_parseCompilationUnitMember_function_generic_void();
  }

  @failingTest
  void test_parseCompilationUnitMember_function_gftReturnType() {
    super.test_parseCompilationUnitMember_function_gftReturnType();
  }

  @failingTest
  void test_parseCompilationUnitMember_function_noReturnType() {
    super.test_parseCompilationUnitMember_function_noReturnType();
  }

  @failingTest
  void test_parseCompilationUnitMember_function_noType() {
    super.test_parseCompilationUnitMember_function_noType();
  }

  @failingTest
  void test_parseCompilationUnitMember_function_type() {
    super.test_parseCompilationUnitMember_function_type();
  }

  @failingTest
  void test_parseCompilationUnitMember_function_void() {
    super.test_parseCompilationUnitMember_function_void();
  }

  @failingTest
  void test_parseCompilationUnitMember_getter_external_noType() {
    super.test_parseCompilationUnitMember_getter_external_noType();
  }

  @failingTest
  void test_parseCompilationUnitMember_getter_external_type() {
    super.test_parseCompilationUnitMember_getter_external_type();
  }

  @failingTest
  void test_parseCompilationUnitMember_getter_noType() {
    super.test_parseCompilationUnitMember_getter_noType();
  }

  @failingTest
  void test_parseCompilationUnitMember_getter_type() {
    super.test_parseCompilationUnitMember_getter_type();
  }

  @failingTest
  void test_parseCompilationUnitMember_setter_external_noType() {
    super.test_parseCompilationUnitMember_setter_external_noType();
  }

  @failingTest
  void test_parseCompilationUnitMember_setter_external_type() {
    super.test_parseCompilationUnitMember_setter_external_type();
  }

  @failingTest
  void test_parseCompilationUnitMember_setter_noType() {
    super.test_parseCompilationUnitMember_setter_noType();
  }

  @failingTest
  void test_parseCompilationUnitMember_setter_type() {
    super.test_parseCompilationUnitMember_setter_type();
  }

  @failingTest
  void test_parseCompilationUnitMember_typeAlias_abstract() {
    super.test_parseCompilationUnitMember_typeAlias_abstract();
  }

  @failingTest
  void test_parseCompilationUnitMember_typeAlias_generic() {
    super.test_parseCompilationUnitMember_typeAlias_generic();
  }

  @failingTest
  void test_parseCompilationUnitMember_typeAlias_implements() {
    super.test_parseCompilationUnitMember_typeAlias_implements();
  }

  @failingTest
  void test_parseCompilationUnitMember_typeAlias_noImplements() {
    super.test_parseCompilationUnitMember_typeAlias_noImplements();
  }

  @failingTest
  void test_parseCompilationUnitMember_typedef() {
    super.test_parseCompilationUnitMember_typedef();
  }

  @failingTest
  void test_parseCompilationUnitMember_typedef_withDocComment() {
    super.test_parseCompilationUnitMember_typedef_withDocComment();
  }

  @failingTest
  void test_parseCompilationUnitMember_typedVariable() {
    super.test_parseCompilationUnitMember_typedVariable();
  }

  @failingTest
  void test_parseCompilationUnitMember_variable() {
    super.test_parseCompilationUnitMember_variable();
  }

  @failingTest
  void test_parseCompilationUnitMember_variable_gftType_gftReturnType() {
    super.test_parseCompilationUnitMember_variable_gftType_gftReturnType();
  }

  @failingTest
  void test_parseCompilationUnitMember_variable_gftType_noReturnType() {
    super.test_parseCompilationUnitMember_variable_gftType_noReturnType();
  }

  @failingTest
  void test_parseCompilationUnitMember_variable_withDocumentationComment() {
    super.test_parseCompilationUnitMember_variable_withDocumentationComment();
  }

  @failingTest
  void test_parseCompilationUnitMember_variableGet() {
    super.test_parseCompilationUnitMember_variableGet();
  }

  @failingTest
  void test_parseCompilationUnitMember_variableSet() {
    super.test_parseCompilationUnitMember_variableSet();
  }

  @failingTest
  void test_parseDirective_export() {
    super.test_parseDirective_export();
  }

  @failingTest
  void test_parseDirective_export_withDocComment() {
    super.test_parseDirective_export_withDocComment();
  }

  @failingTest
  void test_parseDirective_import() {
    super.test_parseDirective_import();
  }

  @failingTest
  void test_parseDirective_library() {
    super.test_parseDirective_library();
  }

  @failingTest
  void test_parseDirective_library_1_component() {
    super.test_parseDirective_library_1_component();
  }

  @failingTest
  void test_parseDirective_library_2_components() {
    super.test_parseDirective_library_2_components();
  }

  @failingTest
  void test_parseDirective_library_3_components() {
    super.test_parseDirective_library_3_components();
  }

  @failingTest
  void test_parseDirective_library_withDocumentationComment() {
    super.test_parseDirective_library_withDocumentationComment();
  }

  @failingTest
  void test_parseDirective_part() {
    super.test_parseDirective_part();
  }

  @failingTest
  void test_parseDirective_part_of_1_component() {
    super.test_parseDirective_part_of_1_component();
  }

  @failingTest
  void test_parseDirective_part_of_2_components() {
    super.test_parseDirective_part_of_2_components();
  }

  @failingTest
  void test_parseDirective_part_of_3_components() {
    super.test_parseDirective_part_of_3_components();
  }

  @failingTest
  void test_parseDirective_part_of_withDocumentationComment() {
    super.test_parseDirective_part_of_withDocumentationComment();
  }

  @failingTest
  void test_parseDirective_part_withDocumentationComment() {
    super.test_parseDirective_part_withDocumentationComment();
  }

  @failingTest
  void test_parseDirective_partOf() {
    super.test_parseDirective_partOf();
  }

  @failingTest
  void test_parseDirectives_complete() {
    super.test_parseDirectives_complete();
  }

  @failingTest
  void test_parseDirectives_empty() {
    super.test_parseDirectives_empty();
  }

  @failingTest
  void test_parseDirectives_mixed() {
    super.test_parseDirectives_mixed();
  }

  @failingTest
  void test_parseDirectives_multiple() {
    super.test_parseDirectives_multiple();
  }

  @failingTest
  void test_parseDirectives_script() {
    super.test_parseDirectives_script();
  }

  @failingTest
  void test_parseDirectives_single() {
    super.test_parseDirectives_single();
  }

  @failingTest
  void test_parseDirectives_topLevelDeclaration() {
    super.test_parseDirectives_topLevelDeclaration();
  }

  @failingTest
  void test_parseEnumDeclaration_one() {
    super.test_parseEnumDeclaration_one();
  }

  @failingTest
  void test_parseEnumDeclaration_trailingComma() {
    super.test_parseEnumDeclaration_trailingComma();
  }

  @failingTest
  void test_parseEnumDeclaration_two() {
    super.test_parseEnumDeclaration_two();
  }

  @failingTest
  void test_parseEnumDeclaration_withDocComment_onEnum() {
    super.test_parseEnumDeclaration_withDocComment_onEnum();
  }

  @failingTest
  void test_parseEnumDeclaration_withDocComment_onValue() {
    super.test_parseEnumDeclaration_withDocComment_onValue();
  }

  @failingTest
  void test_parseExportDirective_configuration_multiple() {
    super.test_parseExportDirective_configuration_multiple();
  }

  @failingTest
  void test_parseExportDirective_configuration_single() {
    super.test_parseExportDirective_configuration_single();
  }

  @failingTest
  void test_parseExportDirective_hide() {
    super.test_parseExportDirective_hide();
  }

  @failingTest
  void test_parseExportDirective_hide_show() {
    super.test_parseExportDirective_hide_show();
  }

  @failingTest
  void test_parseExportDirective_noCombinator() {
    super.test_parseExportDirective_noCombinator();
  }

  @failingTest
  void test_parseExportDirective_show() {
    super.test_parseExportDirective_show();
  }

  @failingTest
  void test_parseExportDirective_show_hide() {
    super.test_parseExportDirective_show_hide();
  }

  @failingTest
  void test_parseFunctionDeclaration_function() {
    super.test_parseFunctionDeclaration_function();
  }

  @failingTest
  void test_parseFunctionDeclaration_functionWithTypeParameters() {
    super.test_parseFunctionDeclaration_functionWithTypeParameters();
  }

  @failingTest
  void test_parseFunctionDeclaration_functionWithTypeParameters_comment() {
    super.test_parseFunctionDeclaration_functionWithTypeParameters_comment();
  }

  @failingTest
  void test_parseFunctionDeclaration_getter() {
    super.test_parseFunctionDeclaration_getter();
  }

  @failingTest
  void test_parseFunctionDeclaration_getter_generic_comment_returnType() {
    super.test_parseFunctionDeclaration_getter_generic_comment_returnType();
  }

  @failingTest
  void test_parseFunctionDeclaration_metadata() {
    super.test_parseFunctionDeclaration_metadata();
  }

  @failingTest
  void test_parseFunctionDeclaration_setter() {
    super.test_parseFunctionDeclaration_setter();
  }

  @failingTest
  void test_parseGenericTypeAlias_noTypeParameters() {
    super.test_parseGenericTypeAlias_noTypeParameters();
  }

  @failingTest
  void test_parseGenericTypeAlias_typeParameters() {
    super.test_parseGenericTypeAlias_typeParameters();
  }

  @failingTest
  void test_parseImportDirective_configuration_multiple() {
    super.test_parseImportDirective_configuration_multiple();
  }

  @failingTest
  void test_parseImportDirective_configuration_single() {
    super.test_parseImportDirective_configuration_single();
  }

  @failingTest
  void test_parseImportDirective_deferred() {
    super.test_parseImportDirective_deferred();
  }

  @failingTest
  void test_parseImportDirective_hide() {
    super.test_parseImportDirective_hide();
  }

  @failingTest
  void test_parseImportDirective_noCombinator() {
    super.test_parseImportDirective_noCombinator();
  }

  @failingTest
  void test_parseImportDirective_prefix() {
    super.test_parseImportDirective_prefix();
  }

  @failingTest
  void test_parseImportDirective_prefix_hide_show() {
    super.test_parseImportDirective_prefix_hide_show();
  }

  @failingTest
  void test_parseImportDirective_prefix_show_hide() {
    super.test_parseImportDirective_prefix_show_hide();
  }

  @failingTest
  void test_parseImportDirective_show() {
    super.test_parseImportDirective_show();
  }

  @failingTest
  void test_parseLibraryDirective() {
    super.test_parseLibraryDirective();
  }

  @failingTest
  void test_parsePartDirective() {
    super.test_parsePartDirective();
  }

  @failingTest
  void test_parsePartOfDirective_name() {
    super.test_parsePartOfDirective_name();
  }

  @failingTest
  void test_parsePartOfDirective_uri() {
    super.test_parsePartOfDirective_uri();
  }

  @failingTest
  void test_parseTypeAlias_function_noParameters() {
    super.test_parseTypeAlias_function_noParameters();
  }

  @failingTest
  void test_parseTypeAlias_function_noReturnType() {
    super.test_parseTypeAlias_function_noReturnType();
  }

  @failingTest
  void test_parseTypeAlias_function_parameterizedReturnType() {
    super.test_parseTypeAlias_function_parameterizedReturnType();
  }

  @failingTest
  void test_parseTypeAlias_function_parameters() {
    super.test_parseTypeAlias_function_parameters();
  }

  @failingTest
  void test_parseTypeAlias_function_typeParameters() {
    super.test_parseTypeAlias_function_typeParameters();
  }

  @failingTest
  void test_parseTypeAlias_function_voidReturnType() {
    super.test_parseTypeAlias_function_voidReturnType();
  }

  @failingTest
  void test_parseTypeAlias_genericFunction_noParameters() {
    super.test_parseTypeAlias_genericFunction_noParameters();
  }

  @failingTest
  void test_parseTypeAlias_genericFunction_noReturnType() {
    super.test_parseTypeAlias_genericFunction_noReturnType();
  }

  @failingTest
  void test_parseTypeAlias_genericFunction_parameterizedReturnType() {
    super.test_parseTypeAlias_genericFunction_parameterizedReturnType();
  }

  @failingTest
  void test_parseTypeAlias_genericFunction_parameters() {
    super.test_parseTypeAlias_genericFunction_parameters();
  }

  @failingTest
  void test_parseTypeAlias_genericFunction_typeParameters() {
    super.test_parseTypeAlias_genericFunction_typeParameters();
  }

  @failingTest
  void test_parseTypeAlias_genericFunction_typeParameters_noParameters() {
    super.test_parseTypeAlias_genericFunction_typeParameters_noParameters();
  }

  @failingTest
  void test_parseTypeAlias_genericFunction_typeParameters_noReturnType() {
    super.test_parseTypeAlias_genericFunction_typeParameters_noReturnType();
  }

  @failingTest
  void
      test_parseTypeAlias_genericFunction_typeParameters_parameterizedReturnType() {
    super
        .test_parseTypeAlias_genericFunction_typeParameters_parameterizedReturnType();
  }

  @failingTest
  void test_parseTypeAlias_genericFunction_typeParameters_parameters() {
    super.test_parseTypeAlias_genericFunction_typeParameters_parameters();
  }

  @failingTest
  void test_parseTypeAlias_genericFunction_typeParameters_typeParameters() {
    super.test_parseTypeAlias_genericFunction_typeParameters_typeParameters();
  }

  @failingTest
  void test_parseTypeAlias_genericFunction_typeParameters_voidReturnType() {
    super.test_parseTypeAlias_genericFunction_typeParameters_voidReturnType();
  }

  @failingTest
  void test_parseTypeAlias_genericFunction_voidReturnType() {
    super.test_parseTypeAlias_genericFunction_voidReturnType();
  }

  @failingTest
  void test_parseTypeAlias_genericFunction_withDocComment() {
    super.test_parseTypeAlias_genericFunction_withDocComment();
  }

  @failingTest
  void test_parseTypeVariable_withDocumentationComment() {
    super.test_parseTypeVariable_withDocumentationComment();
  }
}
