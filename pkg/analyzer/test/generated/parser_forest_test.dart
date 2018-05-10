// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io' show File;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/fasta/ast_body_builder.dart';
import "package:front_end/src/api_prototype/front_end.dart";
import "package:front_end/src/api_prototype/memory_file_system.dart";
import "package:front_end/src/base/processed_options.dart";
import "package:front_end/src/compute_platform_binaries_location.dart";
import 'package:front_end/src/fasta/compiler_context.dart';
import 'package:front_end/src/fasta/constant_context.dart';
import 'package:front_end/src/fasta/dill/dill_target.dart';
import "package:front_end/src/fasta/fasta_codes.dart";
import 'package:front_end/src/fasta/kernel/forest.dart';
import 'package:front_end/src/fasta/kernel/kernel_builder.dart';
import "package:front_end/src/fasta/kernel/kernel_target.dart";
import 'package:front_end/src/fasta/modifier.dart' as Modifier;
import 'package:front_end/src/fasta/parser/parser.dart';
import 'package:front_end/src/fasta/scanner.dart';
import 'package:front_end/src/fasta/ticker.dart';
import 'package:front_end/src/fasta/type_inference/type_inferrer.dart';
import 'package:front_end/src/fasta/type_inference/type_schema_environment.dart';
import 'package:front_end/src/fasta/uri_translator_impl.dart';
import 'package:kernel/class_hierarchy.dart' as kernel;
import 'package:kernel/core_types.dart' as kernel;
import 'package:kernel/kernel.dart' as kernel;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'parser_test.dart';
import 'test_support.dart';

main() async {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExpressionParserTest_Forest);
  });
}

/**
 * Tests of the fasta parser based on [ExpressionParserTestMixin].
 */
@reflectiveTest
class ExpressionParserTest_Forest extends FastaParserTestCase
    with ExpressionParserTestMixin {
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
  void test_parseConstExpression_listLiteral_untyped() {
    super.test_parseConstExpression_listLiteral_untyped();
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
  void test_parseListLiteral_multiple() {
    super.test_parseListLiteral_multiple();
  }

  @failingTest
  void test_parseListLiteral_single() {
    super.test_parseListLiteral_single();
  }

  @failingTest
  void test_parseListLiteral_single_withTypeArgument() {
    super.test_parseListLiteral_single_withTypeArgument();
  }

  @failingTest
  void test_parseListOrMapLiteral_list_noType() {
    super.test_parseListOrMapLiteral_list_noType();
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
  void test_parsePrimaryExpression_listLiteral() {
    super.test_parsePrimaryExpression_listLiteral();
  }

  @failingTest
  void test_parsePrimaryExpression_listLiteral_index() {
    super.test_parsePrimaryExpression_listLiteral_index();
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
 * Implementation of [AbstractParserTestCase] specialized for testing building
 * Analyzer AST using the fasta [Forest] API.
 */
class FastaParserTestCase extends Object
    with ParserTestHelpers
    implements AbstractParserTestCase {
  // TODO(danrubel): Consider HybridFileSystem.
  static final MemoryFileSystem fs =
      new MemoryFileSystem(Uri.parse("org-dartlang-test:///"));

  /// The custom URI used to locate the dill file in the MemoryFileSystem.
  static final Uri sdkSummary = fs.currentDirectory.resolve("vm_platform.dill");

  /// The in memory test code URI
  static final Uri entryPoint = fs.currentDirectory.resolve("main.dart");

  static ProcessedOptions options;

  static KernelTarget kernelTarget;

  @override
  void assertNoErrors() {
    // TODO(brianwilkerson) Implement this.
  }

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Expression parseAdditiveExpression(String code) {
    return parseExpression(code);
  }

  @override
  Expression parseAssignableExpression(String code, bool primaryAllowed) {
    return parseExpression(code);
  }

  @override
  Expression parseAssignableSelector(String code, bool optional,
      {bool allowConditional: true}) {
    return parseExpression(code);
  }

  @override
  AwaitExpression parseAwaitExpression(String code) {
    return parseExpression(code);
  }

  @override
  Expression parseBitwiseAndExpression(String code) {
    return parseExpression(code);
  }

  @override
  Expression parseBitwiseOrExpression(String code) {
    return parseExpression(code);
  }

  @override
  Expression parseBitwiseXorExpression(String code) {
    return parseExpression(code);
  }

  @override
  Expression parseCascadeSection(String code) {
    return parseExpression(code);
  }

  @override
  CompilationUnit parseCompilationUnit(String source,
      {List<ErrorCode> codes, List<ExpectedError> errors}) {
    throw new UnimplementedError();
  }

  @override
  ConditionalExpression parseConditionalExpression(String code) {
    return parseExpression(code);
  }

  @override
  Expression parseConstExpression(String code) {
    return parseExpression(code);
  }

  @override
  ConstructorInitializer parseConstructorInitializer(String code) {
    throw new UnimplementedError();
  }

  @override
  CompilationUnit parseDirectives(String source,
      [List<ErrorCode> errorCodes = const <ErrorCode>[]]) {
    throw new UnimplementedError();
  }

  @override
  BinaryExpression parseEqualityExpression(String code) {
    return parseExpression(code);
  }

  @override
  Expression parseExpression(String source,
      {List<ErrorCode> codes,
      List<ExpectedError> errors,
      int expectedEndOffset}) {
    ScannerResult scan = scanString(source);

    return CompilerContext.runWithOptions(options, (CompilerContext c) {
      KernelLibraryBuilder library = new KernelLibraryBuilder(
        entryPoint,
        entryPoint,
        kernelTarget.loader,
        null /* actualOrigin */,
        null /* enclosingLibrary */,
      );
      List<KernelTypeVariableBuilder> typeVariableBuilders =
          <KernelTypeVariableBuilder>[];
      List<KernelFormalParameterBuilder> formalParameterBuilders =
          <KernelFormalParameterBuilder>[];
      KernelProcedureBuilder procedureBuilder = new KernelProcedureBuilder(
          null /* metadata */,
          Modifier.staticMask /* or Modifier.varMask */,
          kernelTarget.dynamicType,
          "analyzerTest",
          typeVariableBuilders,
          formalParameterBuilders,
          kernel.ProcedureKind.Method,
          library,
          -1 /* charOffset */,
          -1 /* charOpenParenOffset */,
          -1 /* charEndOffset */);

      TypeInferrerDisabled typeInferrer =
          new TypeInferrerDisabled(new TypeSchemaEnvironment(
        kernelTarget.loader.coreTypes,
        kernelTarget.loader.hierarchy,
        // TODO(danrubel): Enable strong mode.
        false /* strong mode */,
      ));

      AstBodyBuilder builder = new AstBodyBuilder(
        library,
        procedureBuilder,
        library.scope,
        procedureBuilder.computeFormalParameterScope(library.scope),
        kernelTarget.loader.hierarchy,
        kernelTarget.loader.coreTypes,
        null /* classBuilder */,
        false /* isInstanceMember */,
        null /* uri */,
        typeInferrer,
      )..constantContext = ConstantContext.none; // .inferred ?

      Parser parser = new Parser(builder);
      parser.parseExpression(parser.syntheticPreviousToken(scan.tokens));
      return builder.pop();
    });
  }

  @override
  List<Expression> parseExpressionList(String code) {
    throw new UnimplementedError();
  }

  @override
  Expression parseExpressionWithoutCascade(String code) {
    return parseExpression(code);
  }

  @override
  FormalParameter parseFormalParameter(String code, ParameterKind kind,
      {List<ErrorCode> errorCodes: const <ErrorCode>[]}) {
    throw new UnimplementedError();
  }

  @override
  FormalParameterList parseFormalParameterList(String code,
      {bool inFunctionType: false,
      List<ErrorCode> errorCodes: const <ErrorCode>[],
      List<ExpectedError> errors}) {
    throw new UnimplementedError();
  }

  @override
  CompilationUnitMember parseFullCompilationUnitMember() {
    throw new UnimplementedError();
  }

  @override
  Directive parseFullDirective() {
    throw new UnimplementedError();
  }

  @override
  FunctionExpression parseFunctionExpression(String code) {
    return parseExpression(code);
  }

  @override
  InstanceCreationExpression parseInstanceCreationExpression(
      String code, Token newToken) {
    return parseExpression(code);
  }

  @override
  ListLiteral parseListLiteral(
      Token token, String typeArgumentsCode, String code) {
    return parseExpression(code);
  }

  @override
  TypedLiteral parseListOrMapLiteral(Token modifier, String code) {
    return parseExpression(code);
  }

  @override
  Expression parseLogicalAndExpression(String code) {
    return parseExpression(code);
  }

  @override
  Expression parseLogicalOrExpression(String code) {
    return parseExpression(code);
  }

  @override
  MapLiteral parseMapLiteral(
      Token token, String typeArgumentsCode, String code) {
    return parseExpression(code);
  }

  @override
  MapLiteralEntry parseMapLiteralEntry(String code) {
    throw new UnimplementedError();
  }

  @override
  Expression parseMultiplicativeExpression(String code) {
    return parseExpression(code);
  }

  @override
  InstanceCreationExpression parseNewExpression(String code) {
    return parseExpression(code);
  }

  @override
  NormalFormalParameter parseNormalFormalParameter(String code,
      {bool inFunctionType: false,
      List<ErrorCode> errorCodes: const <ErrorCode>[]}) {
    throw new UnimplementedError();
  }

  @override
  Expression parsePostfixExpression(String code) {
    return parseExpression(code);
  }

  @override
  Identifier parsePrefixedIdentifier(String code) {
    return parseExpression(code);
  }

  @override
  Expression parsePrimaryExpression(String code,
      {int expectedEndOffset, List<ExpectedError> errors}) {
    return parseExpression(code,
        expectedEndOffset: expectedEndOffset, errors: errors);
  }

  @override
  Expression parseRelationalExpression(String code) {
    return parseExpression(code);
  }

  @override
  RethrowExpression parseRethrowExpression(String code) {
    return parseExpression(code);
  }

  @override
  BinaryExpression parseShiftExpression(String code) {
    return parseExpression(code);
  }

  @override
  SimpleIdentifier parseSimpleIdentifier(String code) {
    return parseExpression(code);
  }

  @override
  Statement parseStatement(String source,
      {bool enableLazyAssignmentOperators, int expectedEndOffset}) {
    throw new UnimplementedError();
  }

  @override
  Expression parseStringLiteral(String code) {
    return parseExpression(code);
  }

  @override
  SymbolLiteral parseSymbolLiteral(String code) {
    return parseExpression(code);
  }

  @override
  Expression parseThrowExpression(String code) {
    return parseExpression(code);
  }

  @override
  Expression parseThrowExpressionWithoutCascade(String code) {
    return parseExpression(code);
  }

  @override
  PrefixExpression parseUnaryExpression(String code) {
    return parseExpression(code);
  }

  @override
  VariableDeclarationList parseVariableDeclarationList(String source) {
    throw new UnimplementedError();
  }

  Future setUp() async {
    // TODO(danrubel): Tear down once all tests in group have been run.
    if (options != null) {
      return;
    }

    // Read the dill file containing kernel platform summaries into memory.
    List<int> sdkSummaryBytes = await new File.fromUri(
            computePlatformBinariesLocation().resolve("vm_platform.dill"))
        .readAsBytes();
    fs.entityForUri(sdkSummary).writeAsBytesSync(sdkSummaryBytes);

    final CompilerOptions optionBuilder = new CompilerOptions()
      ..strongMode = false // TODO(danrubel): enable strong mode.
      ..reportMessages = true
      ..verbose = false
      ..fileSystem = fs
      ..sdkSummary = sdkSummary
      ..onProblem = (FormattedMessage problem, Severity severity,
          List<FormattedMessage> context) {
        // TODO(danrubel): Capture problems and check against expectations.
        print(problem.formatted);
      };

    options = new ProcessedOptions(optionBuilder, false, [entryPoint]);

    UriTranslatorImpl uriTranslator = await options.getUriTranslator();

    await CompilerContext.runWithOptions(options, (CompilerContext c) async {
      DillTarget dillTarget = new DillTarget(
          new Ticker(isVerbose: false), uriTranslator, options.target);

      kernelTarget = new KernelTarget(fs, true, dillTarget, uriTranslator);

      // Load the dill file containing platform code.
      dillTarget.loader.read(Uri.parse('dart:core'), -1, fileUri: sdkSummary);
      kernel.Component sdkComponent =
          kernel.loadComponentFromBytes(sdkSummaryBytes);
      dillTarget.loader
          .appendLibraries(sdkComponent, byteCount: sdkSummaryBytes.length);
      await dillTarget.buildOutlines();
      await kernelTarget.buildOutlines();
      kernelTarget.computeCoreTypes();
      assert(kernelTarget.loader.coreTypes != null);
    });
  }
}
