// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/fasta/body_builder_test_helper.dart';
import 'parser_test.dart';

main() async {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClassMemberParserTest_Forest);
    defineReflectiveTests(ComplexParserTest_Forest);
    defineReflectiveTests(ErrorParserTest_Forest);
    defineReflectiveTests(ExpressionParserTest_Forest);
    defineReflectiveTests(FormalParameterParserTest_Forest);
    defineReflectiveTests(RecoveryParserTest_Forest);
    defineReflectiveTests(SimpleParserTest_Forest);
    defineReflectiveTests(StatementParserTest_Forest);
    defineReflectiveTests(TopLevelParserTest_Forest);
  });
}

@reflectiveTest
class ClassMemberParserTest_Forest extends FastaBodyBuilderTestCase
    with ClassMemberParserTestMixin {
  ClassMemberParserTest_Forest() : super(false);

  @failingTest
  void test_parseAwaitExpression_asStatement_inAsync() {
    super.test_parseAwaitExpression_asStatement_inAsync();
  }

  @failingTest
  void test_parseAwaitExpression_asStatement_inSync() {
    super.test_parseAwaitExpression_asStatement_inSync();
  }

  @failingTest
  void test_parseAwaitExpression_inSync() {
    super.test_parseAwaitExpression_inSync();
  }

  @failingTest
  void test_parseClassMember_constructor_withDocComment() {
    super.test_parseClassMember_constructor_withDocComment();
  }

  @failingTest
  void test_parseClassMember_constructor_withInitializers() {
    super.test_parseClassMember_constructor_withInitializers();
  }

  @failingTest
  void test_parseClassMember_field_covariant() {
    super.test_parseClassMember_field_covariant();
  }

  @failingTest
  void test_parseClassMember_field_generic() {
    super.test_parseClassMember_field_generic();
  }

  @failingTest
  void test_parseClassMember_field_gftType_gftReturnType() {
    super.test_parseClassMember_field_gftType_gftReturnType();
  }

  @failingTest
  void test_parseClassMember_field_gftType_noReturnType() {
    super.test_parseClassMember_field_gftType_noReturnType();
  }

  @failingTest
  void test_parseClassMember_field_instance_prefixedType() {
    super.test_parseClassMember_field_instance_prefixedType();
  }

  @failingTest
  void test_parseClassMember_field_namedGet() {
    super.test_parseClassMember_field_namedGet();
  }

  @failingTest
  void test_parseClassMember_field_namedOperator() {
    super.test_parseClassMember_field_namedOperator();
  }

  @failingTest
  void test_parseClassMember_field_namedOperator_withAssignment() {
    super.test_parseClassMember_field_namedOperator_withAssignment();
  }

  @failingTest
  void test_parseClassMember_field_namedSet() {
    super.test_parseClassMember_field_namedSet();
  }

  @failingTest
  void test_parseClassMember_field_nameKeyword() {
    super.test_parseClassMember_field_nameKeyword();
  }

  @failingTest
  void test_parseClassMember_field_nameMissing() {
    super.test_parseClassMember_field_nameMissing();
  }

  @failingTest
  void test_parseClassMember_field_nameMissing2() {
    super.test_parseClassMember_field_nameMissing2();
  }

  @failingTest
  void test_parseClassMember_field_static() {
    super.test_parseClassMember_field_static();
  }

  @failingTest
  void test_parseClassMember_getter_functionType() {
    super.test_parseClassMember_getter_functionType();
  }

  @failingTest
  void test_parseClassMember_getter_void() {
    super.test_parseClassMember_getter_void();
  }

  @failingTest
  void test_parseClassMember_method_external() {
    super.test_parseClassMember_method_external();
  }

  @failingTest
  void test_parseClassMember_method_external_withTypeAndArgs() {
    super.test_parseClassMember_method_external_withTypeAndArgs();
  }

  @failingTest
  void test_parseClassMember_method_generic_comment_noReturnType() {
    super.test_parseClassMember_method_generic_comment_noReturnType();
  }

  @failingTest
  void test_parseClassMember_method_generic_comment_parameterType() {
    super.test_parseClassMember_method_generic_comment_parameterType();
  }

  @failingTest
  void test_parseClassMember_method_generic_comment_returnType() {
    super.test_parseClassMember_method_generic_comment_returnType();
  }

  @failingTest
  void test_parseClassMember_method_generic_comment_returnType_bound() {
    super.test_parseClassMember_method_generic_comment_returnType_bound();
  }

  @failingTest
  void test_parseClassMember_method_generic_comment_returnType_complex() {
    super.test_parseClassMember_method_generic_comment_returnType_complex();
  }

  @failingTest
  void test_parseClassMember_method_generic_comment_void() {
    super.test_parseClassMember_method_generic_comment_void();
  }

  @failingTest
  void test_parseClassMember_method_generic_noReturnType() {
    super.test_parseClassMember_method_generic_noReturnType();
  }

  @failingTest
  void test_parseClassMember_method_generic_parameterType() {
    super.test_parseClassMember_method_generic_parameterType();
  }

  @failingTest
  void test_parseClassMember_method_generic_returnType() {
    super.test_parseClassMember_method_generic_returnType();
  }

  @failingTest
  void test_parseClassMember_method_generic_returnType_bound() {
    super.test_parseClassMember_method_generic_returnType_bound();
  }

  @failingTest
  void test_parseClassMember_method_generic_returnType_complex() {
    super.test_parseClassMember_method_generic_returnType_complex();
  }

  @failingTest
  void test_parseClassMember_method_generic_returnType_static() {
    super.test_parseClassMember_method_generic_returnType_static();
  }

  @failingTest
  void test_parseClassMember_method_generic_void() {
    super.test_parseClassMember_method_generic_void();
  }

  @failingTest
  void test_parseClassMember_method_get_noType() {
    super.test_parseClassMember_method_get_noType();
  }

  @failingTest
  void test_parseClassMember_method_get_type() {
    super.test_parseClassMember_method_get_type();
  }

  @failingTest
  void test_parseClassMember_method_get_void() {
    super.test_parseClassMember_method_get_void();
  }

  @failingTest
  void test_parseClassMember_method_gftReturnType_noReturnType() {
    super.test_parseClassMember_method_gftReturnType_noReturnType();
  }

  @failingTest
  void test_parseClassMember_method_gftReturnType_voidReturnType() {
    super.test_parseClassMember_method_gftReturnType_voidReturnType();
  }

  @failingTest
  void test_parseClassMember_method_native_allowed() {
    super.test_parseClassMember_method_native_allowed();
  }

  @failingTest
  void test_parseClassMember_method_native_missing_literal_allowed() {
    super.test_parseClassMember_method_native_missing_literal_allowed();
  }

  @failingTest
  void test_parseClassMember_method_native_missing_literal_not_allowed() {
    super.test_parseClassMember_method_native_missing_literal_not_allowed();
  }

  @failingTest
  void test_parseClassMember_method_native_not_allowed() {
    super.test_parseClassMember_method_native_not_allowed();
  }

  @failingTest
  void test_parseClassMember_method_native_with_body_allowed() {
    super.test_parseClassMember_method_native_with_body_allowed();
  }

  @failingTest
  void test_parseClassMember_method_native_with_body_not_allowed() {
    super.test_parseClassMember_method_native_with_body_not_allowed();
  }

  @failingTest
  void test_parseClassMember_method_operator_noType() {
    super.test_parseClassMember_method_operator_noType();
  }

  @failingTest
  void test_parseClassMember_method_operator_type() {
    super.test_parseClassMember_method_operator_type();
  }

  @failingTest
  void test_parseClassMember_method_operator_void() {
    super.test_parseClassMember_method_operator_void();
  }

  @failingTest
  void test_parseClassMember_method_returnType_functionType() {
    super.test_parseClassMember_method_returnType_functionType();
  }

  @failingTest
  void test_parseClassMember_method_returnType_parameterized() {
    super.test_parseClassMember_method_returnType_parameterized();
  }

  @failingTest
  void test_parseClassMember_method_set_noType() {
    super.test_parseClassMember_method_set_noType();
  }

  @failingTest
  void test_parseClassMember_method_set_type() {
    super.test_parseClassMember_method_set_type();
  }

  @failingTest
  void test_parseClassMember_method_set_void() {
    super.test_parseClassMember_method_set_void();
  }

  @failingTest
  void test_parseClassMember_method_static_generic_comment_returnType() {
    super.test_parseClassMember_method_static_generic_comment_returnType();
  }

  @failingTest
  void test_parseClassMember_method_trailing_commas() {
    super.test_parseClassMember_method_trailing_commas();
  }

  @failingTest
  void test_parseClassMember_operator_functionType() {
    super.test_parseClassMember_operator_functionType();
  }

  @failingTest
  void test_parseClassMember_operator_index() {
    super.test_parseClassMember_operator_index();
  }

  @failingTest
  void test_parseClassMember_operator_indexAssign() {
    super.test_parseClassMember_operator_indexAssign();
  }

  @failingTest
  void test_parseClassMember_operator_lessThan() {
    super.test_parseClassMember_operator_lessThan();
  }

  @failingTest
  void test_parseClassMember_redirectingFactory_const() {
    super.test_parseClassMember_redirectingFactory_const();
  }

  @failingTest
  void test_parseClassMember_redirectingFactory_expressionBody() {
    super.test_parseClassMember_redirectingFactory_expressionBody();
  }

  @failingTest
  void test_parseClassMember_redirectingFactory_nonConst() {
    super.test_parseClassMember_redirectingFactory_nonConst();
  }

  @failingTest
  void test_parseConstructor_assert() {
    super.test_parseConstructor_assert();
  }

  @failingTest
  void test_parseConstructor_factory_const_external() {
    super.test_parseConstructor_factory_const_external();
  }

  @failingTest
  void test_parseConstructor_factory_named() {
    super.test_parseConstructor_factory_named();
  }

  @failingTest
  void test_parseConstructor_initializers_field() {
    super.test_parseConstructor_initializers_field();
  }

  @failingTest
  void test_parseConstructor_named() {
    super.test_parseConstructor_named();
  }

  @failingTest
  void test_parseConstructor_unnamed() {
    super.test_parseConstructor_unnamed();
  }

  @failingTest
  void test_parseConstructor_with_pseudo_function_literal() {
    super.test_parseConstructor_with_pseudo_function_literal();
  }

  @failingTest
  void test_parseConstructorFieldInitializer_qualified() {
    super.test_parseConstructorFieldInitializer_qualified();
  }

  @failingTest
  void test_parseConstructorFieldInitializer_unqualified() {
    super.test_parseConstructorFieldInitializer_unqualified();
  }

  @failingTest
  void test_parseGetter_nonStatic() {
    super.test_parseGetter_nonStatic();
  }

  @failingTest
  void test_parseGetter_static() {
    super.test_parseGetter_static();
  }

  @failingTest
  void test_parseInitializedIdentifierList_type() {
    super.test_parseInitializedIdentifierList_type();
  }

  @failingTest
  void test_parseInitializedIdentifierList_var() {
    super.test_parseInitializedIdentifierList_var();
  }

  @failingTest
  void test_parseOperator() {
    super.test_parseOperator();
  }

  @failingTest
  void test_parseSetter_nonStatic() {
    super.test_parseSetter_nonStatic();
  }

  @failingTest
  void test_parseSetter_static() {
    super.test_parseSetter_static();
  }

  @failingTest
  void test_simpleFormalParameter_withDocComment() {
    super.test_simpleFormalParameter_withDocComment();
  }
}

@reflectiveTest
class ComplexParserTest_Forest extends FastaBodyBuilderTestCase
    with ComplexParserTestMixin {
  ComplexParserTest_Forest() : super(false);

  @failingTest
  void test_additiveExpression_normal() {
    super.test_additiveExpression_normal();
  }

  @failingTest
  void test_additiveExpression_noSpaces() {
    super.test_additiveExpression_noSpaces();
  }

  @failingTest
  void test_additiveExpression_precedence_multiplicative_left() {
    super.test_additiveExpression_precedence_multiplicative_left();
  }

  @failingTest
  void test_additiveExpression_precedence_multiplicative_left_withSuper() {
    super.test_additiveExpression_precedence_multiplicative_left_withSuper();
  }

  @failingTest
  void test_additiveExpression_precedence_multiplicative_right() {
    super.test_additiveExpression_precedence_multiplicative_right();
  }

  @failingTest
  void test_additiveExpression_super() {
    super.test_additiveExpression_super();
  }

  @failingTest
  void test_assignableExpression_arguments_normal_chain() {
    super.test_assignableExpression_arguments_normal_chain();
  }

  @failingTest
  void test_assignableExpression_arguments_normal_chain_typeArgumentComments() {
    super
        .test_assignableExpression_arguments_normal_chain_typeArgumentComments();
  }

  @failingTest
  void test_assignableExpression_arguments_normal_chain_typeArguments() {
    super.test_assignableExpression_arguments_normal_chain_typeArguments();
  }

  @failingTest
  void test_assignmentExpression_compound() {
    super.test_assignmentExpression_compound();
  }

  @failingTest
  void test_assignmentExpression_indexExpression() {
    super.test_assignmentExpression_indexExpression();
  }

  @failingTest
  void test_assignmentExpression_prefixedIdentifier() {
    super.test_assignmentExpression_prefixedIdentifier();
  }

  @failingTest
  void test_assignmentExpression_propertyAccess() {
    super.test_assignmentExpression_propertyAccess();
  }

  @failingTest
  void test_bitwiseAndExpression_normal() {
    super.test_bitwiseAndExpression_normal();
  }

  @failingTest
  void test_bitwiseAndExpression_precedence_equality_left() {
    super.test_bitwiseAndExpression_precedence_equality_left();
  }

  @failingTest
  void test_bitwiseAndExpression_precedence_equality_right() {
    super.test_bitwiseAndExpression_precedence_equality_right();
  }

  @failingTest
  void test_bitwiseAndExpression_super() {
    super.test_bitwiseAndExpression_super();
  }

  @failingTest
  void test_bitwiseOrExpression_normal() {
    super.test_bitwiseOrExpression_normal();
  }

  @failingTest
  void test_bitwiseOrExpression_precedence_xor_left() {
    super.test_bitwiseOrExpression_precedence_xor_left();
  }

  @failingTest
  void test_bitwiseOrExpression_precedence_xor_right() {
    super.test_bitwiseOrExpression_precedence_xor_right();
  }

  @failingTest
  void test_bitwiseOrExpression_super() {
    super.test_bitwiseOrExpression_super();
  }

  @failingTest
  void test_bitwiseXorExpression_normal() {
    super.test_bitwiseXorExpression_normal();
  }

  @failingTest
  void test_bitwiseXorExpression_precedence_and_left() {
    super.test_bitwiseXorExpression_precedence_and_left();
  }

  @failingTest
  void test_bitwiseXorExpression_precedence_and_right() {
    super.test_bitwiseXorExpression_precedence_and_right();
  }

  @failingTest
  void test_bitwiseXorExpression_super() {
    super.test_bitwiseXorExpression_super();
  }

  @failingTest
  void test_cascade_withAssignment() {
    super.test_cascade_withAssignment();
  }

  @failingTest
  void test_conditionalExpression_precedence_ifNullExpression() {
    super.test_conditionalExpression_precedence_ifNullExpression();
  }

  @failingTest
  void test_conditionalExpression_precedence_logicalOrExpression() {
    super.test_conditionalExpression_precedence_logicalOrExpression();
  }

  @failingTest
  void test_conditionalExpression_precedence_nullableType_as() {
    super.test_conditionalExpression_precedence_nullableType_as();
  }

  @failingTest
  void test_conditionalExpression_precedence_nullableType_is() {
    super.test_conditionalExpression_precedence_nullableType_is();
  }

  @failingTest
  void test_constructor_initializer_withParenthesizedExpression() {
    super.test_constructor_initializer_withParenthesizedExpression();
  }

  @failingTest
  void test_equalityExpression_normal() {
    super.test_equalityExpression_normal();
  }

  @failingTest
  void test_equalityExpression_precedence_relational_left() {
    super.test_equalityExpression_precedence_relational_left();
  }

  @failingTest
  void test_equalityExpression_precedence_relational_right() {
    super.test_equalityExpression_precedence_relational_right();
  }

  @failingTest
  void test_equalityExpression_super() {
    super.test_equalityExpression_super();
  }

  @failingTest
  void test_ifNullExpression() {
    super.test_ifNullExpression();
  }

  @failingTest
  void test_ifNullExpression_precedence_logicalOr_left() {
    super.test_ifNullExpression_precedence_logicalOr_left();
  }

  @failingTest
  void test_ifNullExpression_precedence_logicalOr_right() {
    super.test_ifNullExpression_precedence_logicalOr_right();
  }

  @failingTest
  void test_logicalAndExpression() {
    super.test_logicalAndExpression();
  }

  @failingTest
  void test_logicalAndExpression_precedence_bitwiseOr_left() {
    super.test_logicalAndExpression_precedence_bitwiseOr_left();
  }

  @failingTest
  void test_logicalAndExpression_precedence_bitwiseOr_right() {
    super.test_logicalAndExpression_precedence_bitwiseOr_right();
  }

  @failingTest
  void test_logicalAndExpressionStatement() {
    super.test_logicalAndExpressionStatement();
  }

  @failingTest
  void test_logicalOrExpression() {
    super.test_logicalOrExpression();
  }

  @failingTest
  void test_logicalOrExpression_precedence_logicalAnd_left() {
    super.test_logicalOrExpression_precedence_logicalAnd_left();
  }

  @failingTest
  void test_logicalOrExpression_precedence_logicalAnd_right() {
    super.test_logicalOrExpression_precedence_logicalAnd_right();
  }

  @failingTest
  void test_methodInvocation1() {
    super.test_methodInvocation1();
  }

  @failingTest
  void test_methodInvocation2() {
    super.test_methodInvocation2();
  }

  @failingTest
  void test_methodInvocation3() {
    super.test_methodInvocation3();
  }

  @failingTest
  void test_multipleLabels_statement() {
    super.test_multipleLabels_statement();
  }

  @failingTest
  void test_multiplicativeExpression_normal() {
    super.test_multiplicativeExpression_normal();
  }

  @failingTest
  void test_multiplicativeExpression_precedence_unary_left() {
    super.test_multiplicativeExpression_precedence_unary_left();
  }

  @failingTest
  void test_multiplicativeExpression_precedence_unary_right() {
    super.test_multiplicativeExpression_precedence_unary_right();
  }

  @failingTest
  void test_multiplicativeExpression_super() {
    super.test_multiplicativeExpression_super();
  }

  @failingTest
  void test_relationalExpression_precedence_shift_right() {
    super.test_relationalExpression_precedence_shift_right();
  }

  @failingTest
  void test_shiftExpression_normal() {
    super.test_shiftExpression_normal();
  }

  @failingTest
  void test_shiftExpression_precedence_additive_left() {
    super.test_shiftExpression_precedence_additive_left();
  }

  @failingTest
  void test_shiftExpression_precedence_additive_right() {
    super.test_shiftExpression_precedence_additive_right();
  }

  @failingTest
  void test_shiftExpression_super() {
    super.test_shiftExpression_super();
  }

  @failingTest
  void test_topLevelFunction_nestedGenericFunction() {
    super.test_topLevelFunction_nestedGenericFunction();
  }
}

@reflectiveTest
class ErrorParserTest_Forest extends FastaBodyBuilderTestCase
    with ErrorParserTestMixin {
  ErrorParserTest_Forest() : super(false);

  @failingTest
  void test_abstractClassMember_constructor() {
    super.test_abstractClassMember_constructor();
  }

  @failingTest
  void test_abstractClassMember_field() {
    super.test_abstractClassMember_field();
  }

  @failingTest
  void test_abstractClassMember_getter() {
    super.test_abstractClassMember_getter();
  }

  @failingTest
  void test_abstractClassMember_method() {
    super.test_abstractClassMember_method();
  }

  @failingTest
  void test_abstractClassMember_setter() {
    super.test_abstractClassMember_setter();
  }

  @failingTest
  void test_abstractEnum() {
    super.test_abstractEnum();
  }

  @failingTest
  void test_abstractTopLevelFunction_function() {
    super.test_abstractTopLevelFunction_function();
  }

  @failingTest
  void test_abstractTopLevelFunction_getter() {
    super.test_abstractTopLevelFunction_getter();
  }

  @failingTest
  void test_abstractTopLevelFunction_setter() {
    super.test_abstractTopLevelFunction_setter();
  }

  @failingTest
  void test_abstractTopLevelVariable() {
    super.test_abstractTopLevelVariable();
  }

  @failingTest
  void test_abstractTypeDef() {
    super.test_abstractTypeDef();
  }

  @failingTest
  void test_breakOutsideOfLoop_breakInDoStatement() {
    super.test_breakOutsideOfLoop_breakInDoStatement();
  }

  @failingTest
  void test_breakOutsideOfLoop_breakInForStatement() {
    super.test_breakOutsideOfLoop_breakInForStatement();
  }

  @failingTest
  void test_breakOutsideOfLoop_breakInIfStatement() {
    super.test_breakOutsideOfLoop_breakInIfStatement();
  }

  @failingTest
  void test_breakOutsideOfLoop_breakInSwitchStatement() {
    super.test_breakOutsideOfLoop_breakInSwitchStatement();
  }

  @failingTest
  void test_breakOutsideOfLoop_breakInWhileStatement() {
    super.test_breakOutsideOfLoop_breakInWhileStatement();
  }

  @failingTest
  void test_breakOutsideOfLoop_functionExpression_inALoop() {
    super.test_breakOutsideOfLoop_functionExpression_inALoop();
  }

  @failingTest
  void test_breakOutsideOfLoop_functionExpression_withALoop() {
    super.test_breakOutsideOfLoop_functionExpression_withALoop();
  }

  @failingTest
  void test_classInClass_abstract() {
    super.test_classInClass_abstract();
  }

  @failingTest
  void test_classInClass_nonAbstract() {
    super.test_classInClass_nonAbstract();
  }

  @failingTest
  void test_classTypeAlias_abstractAfterEq() {
    super.test_classTypeAlias_abstractAfterEq();
  }

  @failingTest
  void test_colonInPlaceOfIn() {
    super.test_colonInPlaceOfIn();
  }

  @failingTest
  void test_constAndCovariant() {
    super.test_constAndCovariant();
  }

  @failingTest
  void test_constAndFinal() {
    super.test_constAndFinal();
  }

  @failingTest
  void test_constAndVar() {
    super.test_constAndVar();
  }

  @failingTest
  void test_constClass() {
    super.test_constClass();
  }

  @failingTest
  void test_constConstructorWithBody() {
    super.test_constConstructorWithBody();
  }

  @failingTest
  void test_constEnum() {
    super.test_constEnum();
  }

  @failingTest
  void test_constFactory() {
    super.test_constFactory();
  }

  @failingTest
  void test_constMethod() {
    super.test_constMethod();
  }

  @failingTest
  void test_constructorPartial() {
    super.test_constructorPartial();
  }

  @failingTest
  void test_constructorWithReturnType() {
    super.test_constructorWithReturnType();
  }

  @failingTest
  void test_constructorWithReturnType_var() {
    super.test_constructorWithReturnType_var();
  }

  @failingTest
  void test_constTypedef() {
    super.test_constTypedef();
  }

  @failingTest
  void test_continueOutsideOfLoop_continueInDoStatement() {
    super.test_continueOutsideOfLoop_continueInDoStatement();
  }

  @failingTest
  void test_continueOutsideOfLoop_continueInForStatement() {
    super.test_continueOutsideOfLoop_continueInForStatement();
  }

  @failingTest
  void test_continueOutsideOfLoop_continueInIfStatement() {
    super.test_continueOutsideOfLoop_continueInIfStatement();
  }

  @failingTest
  void test_continueOutsideOfLoop_continueInSwitchStatement() {
    super.test_continueOutsideOfLoop_continueInSwitchStatement();
  }

  @failingTest
  void test_continueOutsideOfLoop_continueInWhileStatement() {
    super.test_continueOutsideOfLoop_continueInWhileStatement();
  }

  @failingTest
  void test_continueOutsideOfLoop_functionExpression_inALoop() {
    super.test_continueOutsideOfLoop_functionExpression_inALoop();
  }

  @failingTest
  void test_continueOutsideOfLoop_functionExpression_withALoop() {
    super.test_continueOutsideOfLoop_functionExpression_withALoop();
  }

  @failingTest
  void test_continueWithoutLabelInCase_error() {
    super.test_continueWithoutLabelInCase_error();
  }

  @failingTest
  void test_continueWithoutLabelInCase_noError() {
    super.test_continueWithoutLabelInCase_noError();
  }

  @failingTest
  void test_continueWithoutLabelInCase_noError_switchInLoop() {
    super.test_continueWithoutLabelInCase_noError_switchInLoop();
  }

  @failingTest
  void test_covariantAfterVar() {
    super.test_covariantAfterVar();
  }

  @failingTest
  void test_covariantAndFinal() {
    super.test_covariantAndFinal();
  }

  @failingTest
  void test_covariantAndStatic() {
    super.test_covariantAndStatic();
  }

  @failingTest
  void test_covariantAndType_local() {
    super.test_covariantAndType_local();
  }

  @failingTest
  void test_covariantConstructor() {
    super.test_covariantConstructor();
  }

  @failingTest
  void test_covariantMember_getter_noReturnType() {
    super.test_covariantMember_getter_noReturnType();
  }

  @failingTest
  void test_covariantMember_getter_returnType() {
    super.test_covariantMember_getter_returnType();
  }

  @failingTest
  void test_covariantMember_method() {
    super.test_covariantMember_method();
  }

  @failingTest
  void test_covariantTopLevelDeclaration_class() {
    super.test_covariantTopLevelDeclaration_class();
  }

  @failingTest
  void test_covariantTopLevelDeclaration_enum() {
    super.test_covariantTopLevelDeclaration_enum();
  }

  @failingTest
  void test_covariantTopLevelDeclaration_typedef() {
    super.test_covariantTopLevelDeclaration_typedef();
  }

  @failingTest
  void test_defaultValueInFunctionType_named_colon() {
    super.test_defaultValueInFunctionType_named_colon();
  }

  @failingTest
  void test_defaultValueInFunctionType_named_equal() {
    super.test_defaultValueInFunctionType_named_equal();
  }

  @failingTest
  void test_defaultValueInFunctionType_positional() {
    super.test_defaultValueInFunctionType_positional();
  }

  @failingTest
  void test_directiveAfterDeclaration_classBeforeDirective() {
    super.test_directiveAfterDeclaration_classBeforeDirective();
  }

  @failingTest
  void test_directiveAfterDeclaration_classBetweenDirectives() {
    super.test_directiveAfterDeclaration_classBetweenDirectives();
  }

  @failingTest
  void test_duplicatedModifier_const() {
    super.test_duplicatedModifier_const();
  }

  @failingTest
  void test_duplicatedModifier_external() {
    super.test_duplicatedModifier_external();
  }

  @failingTest
  void test_duplicatedModifier_factory() {
    super.test_duplicatedModifier_factory();
  }

  @failingTest
  void test_duplicatedModifier_final() {
    super.test_duplicatedModifier_final();
  }

  @failingTest
  void test_duplicatedModifier_static() {
    super.test_duplicatedModifier_static();
  }

  @failingTest
  void test_duplicatedModifier_var() {
    super.test_duplicatedModifier_var();
  }

  @failingTest
  void test_duplicateLabelInSwitchStatement() {
    super.test_duplicateLabelInSwitchStatement();
  }

  @failingTest
  void test_emptyEnumBody() {
    super.test_emptyEnumBody();
  }

  @failingTest
  void test_enumInClass() {
    super.test_enumInClass();
  }

  @failingTest
  void test_equalityCannotBeEqualityOperand_eq_eq() {
    super.test_equalityCannotBeEqualityOperand_eq_eq();
  }

  @failingTest
  void test_equalityCannotBeEqualityOperand_eq_neq() {
    super.test_equalityCannotBeEqualityOperand_eq_neq();
  }

  @failingTest
  void test_equalityCannotBeEqualityOperand_neq_eq() {
    super.test_equalityCannotBeEqualityOperand_neq_eq();
  }

  @failingTest
  void test_expectedCaseOrDefault() {
    super.test_expectedCaseOrDefault();
  }

  @failingTest
  void test_expectedClassMember_inClass_afterType() {
    super.test_expectedClassMember_inClass_afterType();
  }

  @failingTest
  void test_expectedClassMember_inClass_beforeType() {
    super.test_expectedClassMember_inClass_beforeType();
  }

  @failingTest
  void test_expectedExecutable_afterAnnotation_atEOF() {
    super.test_expectedExecutable_afterAnnotation_atEOF();
  }

  @failingTest
  void test_expectedExecutable_inClass_afterVoid() {
    super.test_expectedExecutable_inClass_afterVoid();
  }

  @failingTest
  void test_expectedExecutable_topLevel_afterType() {
    super.test_expectedExecutable_topLevel_afterType();
  }

  @failingTest
  void test_expectedExecutable_topLevel_afterVoid() {
    super.test_expectedExecutable_topLevel_afterVoid();
  }

  @failingTest
  void test_expectedExecutable_topLevel_beforeType() {
    super.test_expectedExecutable_topLevel_beforeType();
  }

  @failingTest
  void test_expectedExecutable_topLevel_eof() {
    super.test_expectedExecutable_topLevel_eof();
  }

  @failingTest
  void test_expectedInterpolationIdentifier() {
    super.test_expectedInterpolationIdentifier();
  }

  @failingTest
  void test_expectedInterpolationIdentifier_emptyString() {
    super.test_expectedInterpolationIdentifier_emptyString();
  }

  @failingTest
  void test_expectedListOrMapLiteral() {
    super.test_expectedListOrMapLiteral();
  }

  @failingTest
  void test_expectedStringLiteral() {
    super.test_expectedStringLiteral();
  }

  @failingTest
  void test_expectedToken_commaMissingInArgumentList() {
    super.test_expectedToken_commaMissingInArgumentList();
  }

  @failingTest
  void test_expectedToken_parseStatement_afterVoid() {
    super.test_expectedToken_parseStatement_afterVoid();
  }

  @failingTest
  void test_expectedToken_semicolonMissingAfterExport() {
    super.test_expectedToken_semicolonMissingAfterExport();
  }

  @failingTest
  void test_expectedToken_semicolonMissingAfterExpression() {
    super.test_expectedToken_semicolonMissingAfterExpression();
  }

  @failingTest
  void test_expectedToken_semicolonMissingAfterImport() {
    super.test_expectedToken_semicolonMissingAfterImport();
  }

  @failingTest
  void test_expectedToken_uriAndSemicolonMissingAfterExport() {
    super.test_expectedToken_uriAndSemicolonMissingAfterExport();
  }

  @failingTest
  void test_expectedToken_whileMissingInDoStatement() {
    super.test_expectedToken_whileMissingInDoStatement();
  }

  @failingTest
  void test_expectedTypeName_as() {
    super.test_expectedTypeName_as();
  }

  @failingTest
  void test_expectedTypeName_as_void() {
    super.test_expectedTypeName_as_void();
  }

  @failingTest
  void test_expectedTypeName_is() {
    super.test_expectedTypeName_is();
  }

  @failingTest
  void test_expectedTypeName_is_void() {
    super.test_expectedTypeName_is_void();
  }

  @failingTest
  void test_exportAsType() {
    super.test_exportAsType();
  }

  @failingTest
  void test_exportAsType_inClass() {
    super.test_exportAsType_inClass();
  }

  @failingTest
  void test_exportDirectiveAfterPartDirective() {
    super.test_exportDirectiveAfterPartDirective();
  }

  @failingTest
  void test_externalAfterConst() {
    super.test_externalAfterConst();
  }

  @failingTest
  void test_externalAfterFactory() {
    super.test_externalAfterFactory();
  }

  @failingTest
  void test_externalAfterStatic() {
    super.test_externalAfterStatic();
  }

  @failingTest
  void test_externalClass() {
    super.test_externalClass();
  }

  @failingTest
  void test_externalConstructorWithBody_factory() {
    super.test_externalConstructorWithBody_factory();
  }

  @failingTest
  void test_externalConstructorWithBody_named() {
    super.test_externalConstructorWithBody_named();
  }

  @failingTest
  void test_externalEnum() {
    super.test_externalEnum();
  }

  @failingTest
  void test_externalField_const() {
    super.test_externalField_const();
  }

  @failingTest
  void test_externalField_final() {
    super.test_externalField_final();
  }

  @failingTest
  void test_externalField_static() {
    super.test_externalField_static();
  }

  @failingTest
  void test_externalField_typed() {
    super.test_externalField_typed();
  }

  @failingTest
  void test_externalField_untyped() {
    super.test_externalField_untyped();
  }

  @failingTest
  void test_externalGetterWithBody() {
    super.test_externalGetterWithBody();
  }

  @failingTest
  void test_externalMethodWithBody() {
    super.test_externalMethodWithBody();
  }

  @failingTest
  void test_externalOperatorWithBody() {
    super.test_externalOperatorWithBody();
  }

  @failingTest
  void test_externalSetterWithBody() {
    super.test_externalSetterWithBody();
  }

  @failingTest
  void test_externalTypedef() {
    super.test_externalTypedef();
  }

  @failingTest
  void test_extraCommaInParameterList() {
    super.test_extraCommaInParameterList();
  }

  @failingTest
  void test_extraCommaTrailingNamedParameterGroup() {
    super.test_extraCommaTrailingNamedParameterGroup();
  }

  @failingTest
  void test_extraCommaTrailingPositionalParameterGroup() {
    super.test_extraCommaTrailingPositionalParameterGroup();
  }

  @failingTest
  void test_extraTrailingCommaInParameterList() {
    super.test_extraTrailingCommaInParameterList();
  }

  @failingTest
  void test_factoryTopLevelDeclaration_class() {
    super.test_factoryTopLevelDeclaration_class();
  }

  @failingTest
  void test_factoryTopLevelDeclaration_enum() {
    super.test_factoryTopLevelDeclaration_enum();
  }

  @failingTest
  void test_factoryTopLevelDeclaration_typedef() {
    super.test_factoryTopLevelDeclaration_typedef();
  }

  @failingTest
  void test_factoryWithInitializers() {
    super.test_factoryWithInitializers();
  }

  @failingTest
  void test_factoryWithoutBody() {
    super.test_factoryWithoutBody();
  }

  @failingTest
  void test_fieldInitializerOutsideConstructor() {
    super.test_fieldInitializerOutsideConstructor();
  }

  @failingTest
  void test_finalAndCovariant() {
    super.test_finalAndCovariant();
  }

  @failingTest
  void test_finalAndVar() {
    super.test_finalAndVar();
  }

  @failingTest
  void test_finalClass() {
    super.test_finalClass();
  }

  @failingTest
  void test_finalClassMember_modifierOnly() {
    super.test_finalClassMember_modifierOnly();
  }

  @failingTest
  void test_finalConstructor() {
    super.test_finalConstructor();
  }

  @failingTest
  void test_finalEnum() {
    super.test_finalEnum();
  }

  @failingTest
  void test_finalMethod() {
    super.test_finalMethod();
  }

  @failingTest
  void test_finalTypedef() {
    super.test_finalTypedef();
  }

  @failingTest
  void test_functionTypedField_invalidType_abstract() {
    super.test_functionTypedField_invalidType_abstract();
  }

  @failingTest
  void test_functionTypedField_invalidType_class() {
    super.test_functionTypedField_invalidType_class();
  }

  @failingTest
  void test_functionTypedParameter_const() {
    super.test_functionTypedParameter_const();
  }

  @failingTest
  void test_functionTypedParameter_final() {
    super.test_functionTypedParameter_final();
  }

  @failingTest
  void test_functionTypedParameter_incomplete1() {
    super.test_functionTypedParameter_incomplete1();
  }

  @failingTest
  void test_functionTypedParameter_var() {
    super.test_functionTypedParameter_var();
  }

  @failingTest
  void test_genericFunctionType_asIdentifier() {
    super.test_genericFunctionType_asIdentifier();
  }

  @failingTest
  void test_genericFunctionType_asIdentifier2() {
    super.test_genericFunctionType_asIdentifier2();
  }

  @failingTest
  void test_genericFunctionType_asIdentifier3() {
    super.test_genericFunctionType_asIdentifier3();
  }

  @failingTest
  void test_genericFunctionType_extraLessThan() {
    super.test_genericFunctionType_extraLessThan();
  }

  @failingTest
  void test_getterInFunction_block_noReturnType() {
    super.test_getterInFunction_block_noReturnType();
  }

  @failingTest
  void test_getterInFunction_block_returnType() {
    super.test_getterInFunction_block_returnType();
  }

  @failingTest
  void test_getterInFunction_expression_noReturnType() {
    super.test_getterInFunction_expression_noReturnType();
  }

  @failingTest
  void test_getterInFunction_expression_returnType() {
    super.test_getterInFunction_expression_returnType();
  }

  @failingTest
  void test_getterWithParameters() {
    super.test_getterWithParameters();
  }

  @failingTest
  void test_illegalAssignmentToNonAssignable_assign_int() {
    super.test_illegalAssignmentToNonAssignable_assign_int();
  }

  @failingTest
  void test_illegalAssignmentToNonAssignable_assign_this() {
    super.test_illegalAssignmentToNonAssignable_assign_this();
  }

  @failingTest
  void test_illegalAssignmentToNonAssignable_postfix_minusMinus_literal() {
    super.test_illegalAssignmentToNonAssignable_postfix_minusMinus_literal();
  }

  @failingTest
  void test_illegalAssignmentToNonAssignable_postfix_plusPlus_literal() {
    super.test_illegalAssignmentToNonAssignable_postfix_plusPlus_literal();
  }

  @failingTest
  void test_illegalAssignmentToNonAssignable_postfix_plusPlus_parenthesized() {
    super
        .test_illegalAssignmentToNonAssignable_postfix_plusPlus_parenthesized();
  }

  @failingTest
  void test_illegalAssignmentToNonAssignable_primarySelectorPostfix() {
    super.test_illegalAssignmentToNonAssignable_primarySelectorPostfix();
  }

  @failingTest
  void test_illegalAssignmentToNonAssignable_superAssigned() {
    super.test_illegalAssignmentToNonAssignable_superAssigned();
  }

  @failingTest
  void test_implementsBeforeExtends() {
    super.test_implementsBeforeExtends();
  }

  @failingTest
  void test_implementsBeforeWith() {
    super.test_implementsBeforeWith();
  }

  @failingTest
  void test_importDirectiveAfterPartDirective() {
    super.test_importDirectiveAfterPartDirective();
  }

  @failingTest
  void test_initializedVariableInForEach() {
    super.test_initializedVariableInForEach();
  }

  @failingTest
  void test_initializedVariableInForEach_annotation() {
    super.test_initializedVariableInForEach_annotation();
  }

  @failingTest
  void test_initializedVariableInForEach_localFunction() {
    super.test_initializedVariableInForEach_localFunction();
  }

  @failingTest
  void test_initializedVariableInForEach_localFunction2() {
    super.test_initializedVariableInForEach_localFunction2();
  }

  @failingTest
  void test_initializedVariableInForEach_var() {
    super.test_initializedVariableInForEach_var();
  }

  @failingTest
  void test_invalidAwaitInFor() {
    super.test_invalidAwaitInFor();
  }

  @failingTest
  void test_invalidCodePoint() {
    super.test_invalidCodePoint();
  }

  @failingTest
  void test_invalidCommentReference__new_nonIdentifier() {
    super.test_invalidCommentReference__new_nonIdentifier();
  }

  @failingTest
  void test_invalidCommentReference__new_tooMuch() {
    super.test_invalidCommentReference__new_tooMuch();
  }

  @failingTest
  void test_invalidCommentReference__nonNew_nonIdentifier() {
    super.test_invalidCommentReference__nonNew_nonIdentifier();
  }

  @failingTest
  void test_invalidCommentReference__nonNew_tooMuch() {
    super.test_invalidCommentReference__nonNew_tooMuch();
  }

  @failingTest
  void test_invalidConstructorName_star() {
    super.test_invalidConstructorName_star();
  }

  @failingTest
  void test_invalidConstructorName_with() {
    super.test_invalidConstructorName_with();
  }

  @failingTest
  void test_invalidHexEscape_invalidDigit() {
    super.test_invalidHexEscape_invalidDigit();
  }

  @failingTest
  void test_invalidHexEscape_tooFewDigits() {
    super.test_invalidHexEscape_tooFewDigits();
  }

  @failingTest
  void test_invalidInterpolationIdentifier_startWithDigit() {
    super.test_invalidInterpolationIdentifier_startWithDigit();
  }

  @failingTest
  void test_invalidLiteralInConfiguration() {
    super.test_invalidLiteralInConfiguration();
  }

  @failingTest
  void test_invalidOperator() {
    super.test_invalidOperator();
  }

  @failingTest
  void test_invalidOperator_unary() {
    super.test_invalidOperator_unary();
  }

  @failingTest
  void test_invalidOperatorAfterSuper_assignableExpression() {
    super.test_invalidOperatorAfterSuper_assignableExpression();
  }

  @failingTest
  void test_invalidOperatorAfterSuper_primaryExpression() {
    super.test_invalidOperatorAfterSuper_primaryExpression();
  }

  @failingTest
  void test_invalidOperatorForSuper() {
    super.test_invalidOperatorForSuper();
  }

  @failingTest
  void test_invalidStarAfterAsync() {
    super.test_invalidStarAfterAsync();
  }

  @failingTest
  void test_invalidSync() {
    super.test_invalidSync();
  }

  @failingTest
  void test_invalidTopLevelSetter() {
    super.test_invalidTopLevelSetter();
  }

  @failingTest
  void test_invalidTopLevelVar() {
    super.test_invalidTopLevelVar();
  }

  @failingTest
  void test_invalidTypedef() {
    super.test_invalidTypedef();
  }

  @failingTest
  void test_invalidTypedef2() {
    super.test_invalidTypedef2();
  }

  @failingTest
  void test_invalidUnicodeEscape_incomplete_noDigits() {
    super.test_invalidUnicodeEscape_incomplete_noDigits();
  }

  @failingTest
  void test_invalidUnicodeEscape_incomplete_someDigits() {
    super.test_invalidUnicodeEscape_incomplete_someDigits();
  }

  @failingTest
  void test_invalidUnicodeEscape_invalidDigit() {
    super.test_invalidUnicodeEscape_invalidDigit();
  }

  @failingTest
  void test_invalidUnicodeEscape_tooFewDigits_fixed() {
    super.test_invalidUnicodeEscape_tooFewDigits_fixed();
  }

  @failingTest
  void test_invalidUnicodeEscape_tooFewDigits_variable() {
    super.test_invalidUnicodeEscape_tooFewDigits_variable();
  }

  @failingTest
  void test_invalidUnicodeEscape_tooManyDigits_variable() {
    super.test_invalidUnicodeEscape_tooManyDigits_variable();
  }

  @failingTest
  void test_libraryDirectiveNotFirst() {
    super.test_libraryDirectiveNotFirst();
  }

  @failingTest
  void test_libraryDirectiveNotFirst_afterPart() {
    super.test_libraryDirectiveNotFirst_afterPart();
  }

  @failingTest
  void test_localFunction_annotation() {
    super.test_localFunction_annotation();
  }

  @failingTest
  void test_localFunctionDeclarationModifier_abstract() {
    super.test_localFunctionDeclarationModifier_abstract();
  }

  @failingTest
  void test_localFunctionDeclarationModifier_external() {
    super.test_localFunctionDeclarationModifier_external();
  }

  @failingTest
  void test_localFunctionDeclarationModifier_factory() {
    super.test_localFunctionDeclarationModifier_factory();
  }

  @failingTest
  void test_localFunctionDeclarationModifier_static() {
    super.test_localFunctionDeclarationModifier_static();
  }

  @failingTest
  void test_method_invalidTypeParameterComments() {
    super.test_method_invalidTypeParameterComments();
  }

  @failingTest
  void test_method_invalidTypeParameterExtends() {
    super.test_method_invalidTypeParameterExtends();
  }

  @failingTest
  void test_method_invalidTypeParameterExtendsComment() {
    super.test_method_invalidTypeParameterExtendsComment();
  }

  @failingTest
  void test_method_invalidTypeParameters() {
    super.test_method_invalidTypeParameters();
  }

  @failingTest
  void test_missingAssignableSelector_identifiersAssigned() {
    super.test_missingAssignableSelector_identifiersAssigned();
  }

  @failingTest
  void test_missingAssignableSelector_prefix_minusMinus_literal() {
    super.test_missingAssignableSelector_prefix_minusMinus_literal();
  }

  @failingTest
  void test_missingAssignableSelector_prefix_plusPlus_literal() {
    super.test_missingAssignableSelector_prefix_plusPlus_literal();
  }

  @failingTest
  void test_missingAssignableSelector_selector() {
    super.test_missingAssignableSelector_selector();
  }

  @failingTest
  void test_missingAssignableSelector_superPrimaryExpression() {
    super.test_missingAssignableSelector_superPrimaryExpression();
  }

  @failingTest
  void test_missingAssignableSelector_superPropertyAccessAssigned() {
    super.test_missingAssignableSelector_superPropertyAccessAssigned();
  }

  @failingTest
  void test_missingCatchOrFinally() {
    super.test_missingCatchOrFinally();
  }

  @failingTest
  void test_missingClassBody() {
    super.test_missingClassBody();
  }

  @failingTest
  void test_missingClosingParenthesis() {
    super.test_missingClosingParenthesis();
  }

  @failingTest
  void test_missingConstFinalVarOrType_static() {
    super.test_missingConstFinalVarOrType_static();
  }

  @failingTest
  void test_missingConstFinalVarOrType_topLevel() {
    super.test_missingConstFinalVarOrType_topLevel();
  }

  @failingTest
  void test_missingEnumBody() {
    super.test_missingEnumBody();
  }

  @failingTest
  void test_missingEnumComma() {
    super.test_missingEnumComma();
  }

  @failingTest
  void test_missingExpressionInThrow() {
    super.test_missingExpressionInThrow();
  }

  @failingTest
  void test_missingFunctionBody_emptyNotAllowed() {
    super.test_missingFunctionBody_emptyNotAllowed();
  }

  @failingTest
  void test_missingFunctionBody_invalid() {
    super.test_missingFunctionBody_invalid();
  }

  @failingTest
  void test_missingFunctionParameters_local_nonVoid_block() {
    super.test_missingFunctionParameters_local_nonVoid_block();
  }

  @failingTest
  void test_missingFunctionParameters_local_nonVoid_expression() {
    super.test_missingFunctionParameters_local_nonVoid_expression();
  }

  @failingTest
  void test_missingFunctionParameters_local_void_block() {
    super.test_missingFunctionParameters_local_void_block();
  }

  @failingTest
  void test_missingFunctionParameters_local_void_expression() {
    super.test_missingFunctionParameters_local_void_expression();
  }

  @failingTest
  void test_missingFunctionParameters_topLevel_nonVoid_block() {
    super.test_missingFunctionParameters_topLevel_nonVoid_block();
  }

  @failingTest
  void test_missingFunctionParameters_topLevel_nonVoid_expression() {
    super.test_missingFunctionParameters_topLevel_nonVoid_expression();
  }

  @failingTest
  void test_missingFunctionParameters_topLevel_void_block() {
    super.test_missingFunctionParameters_topLevel_void_block();
  }

  @failingTest
  void test_missingFunctionParameters_topLevel_void_expression() {
    super.test_missingFunctionParameters_topLevel_void_expression();
  }

  @failingTest
  void test_missingIdentifier_afterOperator() {
    super.test_missingIdentifier_afterOperator();
  }

  @failingTest
  void test_missingIdentifier_beforeClosingCurly() {
    super.test_missingIdentifier_beforeClosingCurly();
  }

  @failingTest
  void test_missingIdentifier_inEnum() {
    super.test_missingIdentifier_inEnum();
  }

  @failingTest
  void test_missingIdentifier_inParameterGroupNamed() {
    super.test_missingIdentifier_inParameterGroupNamed();
  }

  @failingTest
  void test_missingIdentifier_inParameterGroupOptional() {
    super.test_missingIdentifier_inParameterGroupOptional();
  }

  @failingTest
  void test_missingIdentifier_inSymbol_afterPeriod() {
    super.test_missingIdentifier_inSymbol_afterPeriod();
  }

  @failingTest
  void test_missingIdentifier_inSymbol_first() {
    super.test_missingIdentifier_inSymbol_first();
  }

  @failingTest
  void test_missingIdentifierForParameterGroup() {
    super.test_missingIdentifierForParameterGroup();
  }

  @failingTest
  void test_missingKeywordOperator() {
    super.test_missingKeywordOperator();
  }

  @failingTest
  void test_missingKeywordOperator_parseClassMember() {
    super.test_missingKeywordOperator_parseClassMember();
  }

  @failingTest
  void test_missingKeywordOperator_parseClassMember_afterTypeName() {
    super.test_missingKeywordOperator_parseClassMember_afterTypeName();
  }

  @failingTest
  void test_missingKeywordOperator_parseClassMember_afterVoid() {
    super.test_missingKeywordOperator_parseClassMember_afterVoid();
  }

  @failingTest
  void test_missingMethodParameters_void_block() {
    super.test_missingMethodParameters_void_block();
  }

  @failingTest
  void test_missingMethodParameters_void_expression() {
    super.test_missingMethodParameters_void_expression();
  }

  @failingTest
  void test_missingNameForNamedParameter_colon() {
    super.test_missingNameForNamedParameter_colon();
  }

  @failingTest
  void test_missingNameForNamedParameter_equals() {
    super.test_missingNameForNamedParameter_equals();
  }

  @failingTest
  void test_missingNameForNamedParameter_noDefault() {
    super.test_missingNameForNamedParameter_noDefault();
  }

  @failingTest
  void test_missingNameInLibraryDirective() {
    super.test_missingNameInLibraryDirective();
  }

  @failingTest
  void test_missingNameInPartOfDirective() {
    super.test_missingNameInPartOfDirective();
  }

  @failingTest
  void test_missingPrefixInDeferredImport() {
    super.test_missingPrefixInDeferredImport();
  }

  @failingTest
  void test_missingStartAfterSync() {
    super.test_missingStartAfterSync();
  }

  @failingTest
  void test_missingStatement() {
    super.test_missingStatement();
  }

  @failingTest
  void test_missingStatement_afterVoid() {
    super.test_missingStatement_afterVoid();
  }

  @failingTest
  void test_missingTerminatorForParameterGroup_named() {
    super.test_missingTerminatorForParameterGroup_named();
  }

  @failingTest
  void test_missingTerminatorForParameterGroup_optional() {
    super.test_missingTerminatorForParameterGroup_optional();
  }

  @failingTest
  void test_missingTypedefParameters_nonVoid() {
    super.test_missingTypedefParameters_nonVoid();
  }

  @failingTest
  void test_missingTypedefParameters_typeParameters() {
    super.test_missingTypedefParameters_typeParameters();
  }

  @failingTest
  void test_missingTypedefParameters_void() {
    super.test_missingTypedefParameters_void();
  }

  @failingTest
  void test_missingVariableInForEach() {
    super.test_missingVariableInForEach();
  }

  @failingTest
  void test_mixedParameterGroups_namedPositional() {
    super.test_mixedParameterGroups_namedPositional();
  }

  @failingTest
  void test_mixedParameterGroups_positionalNamed() {
    super.test_mixedParameterGroups_positionalNamed();
  }

  @failingTest
  void test_mixin_application_lacks_with_clause() {
    super.test_mixin_application_lacks_with_clause();
  }

  @failingTest
  void test_multipleExtendsClauses() {
    super.test_multipleExtendsClauses();
  }

  @failingTest
  void test_multipleImplementsClauses() {
    super.test_multipleImplementsClauses();
  }

  @failingTest
  void test_multipleLibraryDirectives() {
    super.test_multipleLibraryDirectives();
  }

  @failingTest
  void test_multipleNamedParameterGroups() {
    super.test_multipleNamedParameterGroups();
  }

  @failingTest
  void test_multiplePartOfDirectives() {
    super.test_multiplePartOfDirectives();
  }

  @failingTest
  void test_multiplePositionalParameterGroups() {
    super.test_multiplePositionalParameterGroups();
  }

  @failingTest
  void test_multipleVariablesInForEach() {
    super.test_multipleVariablesInForEach();
  }

  @failingTest
  void test_multipleWithClauses() {
    super.test_multipleWithClauses();
  }

  @failingTest
  void test_namedFunctionExpression() {
    super.test_namedFunctionExpression();
  }

  @failingTest
  void test_namedParameterOutsideGroup() {
    super.test_namedParameterOutsideGroup();
  }

  @failingTest
  void test_nonConstructorFactory_field() {
    super.test_nonConstructorFactory_field();
  }

  @failingTest
  void test_nonConstructorFactory_method() {
    super.test_nonConstructorFactory_method();
  }

  @failingTest
  void test_nonIdentifierLibraryName_library() {
    super.test_nonIdentifierLibraryName_library();
  }

  @failingTest
  void test_nonIdentifierLibraryName_partOf() {
    super.test_nonIdentifierLibraryName_partOf();
  }

  @failingTest
  void test_nonPartOfDirectiveInPart_after() {
    super.test_nonPartOfDirectiveInPart_after();
  }

  @failingTest
  void test_nonPartOfDirectiveInPart_before() {
    super.test_nonPartOfDirectiveInPart_before();
  }

  @failingTest
  void test_nonUserDefinableOperator() {
    super.test_nonUserDefinableOperator();
  }

  @failingTest
  void test_optionalAfterNormalParameters_named() {
    super.test_optionalAfterNormalParameters_named();
  }

  @failingTest
  void test_optionalAfterNormalParameters_positional() {
    super.test_optionalAfterNormalParameters_positional();
  }

  @failingTest
  void test_parseCascadeSection_missingIdentifier() {
    super.test_parseCascadeSection_missingIdentifier();
  }

  @failingTest
  void test_parseCascadeSection_missingIdentifier_typeArguments() {
    super.test_parseCascadeSection_missingIdentifier_typeArguments();
  }

  @failingTest
  void test_positionalAfterNamedArgument() {
    super.test_positionalAfterNamedArgument();
  }

  @failingTest
  void test_positionalParameterOutsideGroup() {
    super.test_positionalParameterOutsideGroup();
  }

  @failingTest
  void test_redirectingConstructorWithBody_named() {
    super.test_redirectingConstructorWithBody_named();
  }

  @failingTest
  void test_redirectingConstructorWithBody_unnamed() {
    super.test_redirectingConstructorWithBody_unnamed();
  }

  @failingTest
  void test_redirectionInNonFactoryConstructor() {
    super.test_redirectionInNonFactoryConstructor();
  }

  @failingTest
  void test_setterInFunction_block() {
    super.test_setterInFunction_block();
  }

  @failingTest
  void test_setterInFunction_expression() {
    super.test_setterInFunction_expression();
  }

  @failingTest
  void test_staticAfterConst() {
    super.test_staticAfterConst();
  }

  @failingTest
  void test_staticAfterFinal() {
    super.test_staticAfterFinal();
  }

  @failingTest
  void test_staticAfterVar() {
    super.test_staticAfterVar();
  }

  @failingTest
  void test_staticConstructor() {
    super.test_staticConstructor();
  }

  @failingTest
  void test_staticGetterWithoutBody() {
    super.test_staticGetterWithoutBody();
  }

  @failingTest
  void test_staticOperator_noReturnType() {
    super.test_staticOperator_noReturnType();
  }

  @failingTest
  void test_staticOperator_returnType() {
    super.test_staticOperator_returnType();
  }

  @failingTest
  void test_staticSetterWithoutBody() {
    super.test_staticSetterWithoutBody();
  }

  @failingTest
  void test_staticTopLevelDeclaration_class() {
    super.test_staticTopLevelDeclaration_class();
  }

  @failingTest
  void test_staticTopLevelDeclaration_enum() {
    super.test_staticTopLevelDeclaration_enum();
  }

  @failingTest
  void test_staticTopLevelDeclaration_function() {
    super.test_staticTopLevelDeclaration_function();
  }

  @failingTest
  void test_staticTopLevelDeclaration_typedef() {
    super.test_staticTopLevelDeclaration_typedef();
  }

  @failingTest
  void test_staticTopLevelDeclaration_variable() {
    super.test_staticTopLevelDeclaration_variable();
  }

  @failingTest
  void test_string_unterminated_interpolation_block() {
    super.test_string_unterminated_interpolation_block();
  }

  @failingTest
  void test_switchCase_missingColon() {
    super.test_switchCase_missingColon();
  }

  @failingTest
  void test_switchDefault_missingColon() {
    super.test_switchDefault_missingColon();
  }

  @failingTest
  void test_switchHasCaseAfterDefaultCase() {
    super.test_switchHasCaseAfterDefaultCase();
  }

  @failingTest
  void test_switchHasCaseAfterDefaultCase_repeated() {
    super.test_switchHasCaseAfterDefaultCase_repeated();
  }

  @failingTest
  void test_switchHasMultipleDefaultCases() {
    super.test_switchHasMultipleDefaultCases();
  }

  @failingTest
  void test_switchHasMultipleDefaultCases_repeated() {
    super.test_switchHasMultipleDefaultCases_repeated();
  }

  @failingTest
  void test_switchMissingBlock() {
    super.test_switchMissingBlock();
  }

  @failingTest
  void test_topLevel_getter() {
    super.test_topLevel_getter();
  }

  @failingTest
  void test_topLevelFactory_withFunction() {
    super.test_topLevelFactory_withFunction();
  }

  @failingTest
  void test_topLevelOperator_withFunction() {
    super.test_topLevelOperator_withFunction();
  }

  @failingTest
  void test_topLevelOperator_withoutOperator() {
    super.test_topLevelOperator_withoutOperator();
  }

  @failingTest
  void test_topLevelOperator_withoutType() {
    super.test_topLevelOperator_withoutType();
  }

  @failingTest
  void test_topLevelOperator_withType() {
    super.test_topLevelOperator_withType();
  }

  @failingTest
  void test_topLevelOperator_withVoid() {
    super.test_topLevelOperator_withVoid();
  }

  @failingTest
  void test_topLevelVariable_withMetadata() {
    super.test_topLevelVariable_withMetadata();
  }

  @failingTest
  void test_typedef_incomplete() {
    super.test_typedef_incomplete();
  }

  @failingTest
  void test_typedef_namedFunction() {
    super.test_typedef_namedFunction();
  }

  @failingTest
  void test_typedefInClass_withoutReturnType() {
    super.test_typedefInClass_withoutReturnType();
  }

  @failingTest
  void test_typedefInClass_withReturnType() {
    super.test_typedefInClass_withReturnType();
  }

  @failingTest
  void test_unexpectedTerminatorForParameterGroup_named() {
    super.test_unexpectedTerminatorForParameterGroup_named();
  }

  @failingTest
  void test_unexpectedTerminatorForParameterGroup_optional() {
    super.test_unexpectedTerminatorForParameterGroup_optional();
  }

  @failingTest
  void test_unexpectedToken_endOfFieldDeclarationStatement() {
    super.test_unexpectedToken_endOfFieldDeclarationStatement();
  }

  @failingTest
  void test_unexpectedToken_invalidPostfixExpression() {
    super.test_unexpectedToken_invalidPostfixExpression();
  }

  @failingTest
  void test_unexpectedToken_invalidPrefixExpression() {
    super.test_unexpectedToken_invalidPrefixExpression();
  }

  @failingTest
  void test_unexpectedToken_returnInExpressionFunctionBody() {
    super.test_unexpectedToken_returnInExpressionFunctionBody();
  }

  @failingTest
  void test_unexpectedToken_semicolonBetweenClassMembers() {
    super.test_unexpectedToken_semicolonBetweenClassMembers();
  }

  @failingTest
  void test_unexpectedToken_semicolonBetweenCompilationUnitMembers() {
    super.test_unexpectedToken_semicolonBetweenCompilationUnitMembers();
  }

  @failingTest
  void test_unterminatedString_at_eof() {
    super.test_unterminatedString_at_eof();
  }

  @failingTest
  void test_unterminatedString_at_eol() {
    super.test_unterminatedString_at_eol();
  }

  @failingTest
  void test_unterminatedString_multiline_at_eof_3_quotes() {
    super.test_unterminatedString_multiline_at_eof_3_quotes();
  }

  @failingTest
  void test_unterminatedString_multiline_at_eof_4_quotes() {
    super.test_unterminatedString_multiline_at_eof_4_quotes();
  }

  @failingTest
  void test_unterminatedString_multiline_at_eof_5_quotes() {
    super.test_unterminatedString_multiline_at_eof_5_quotes();
  }

  @failingTest
  void test_useOfUnaryPlusOperator() {
    super.test_useOfUnaryPlusOperator();
  }

  @failingTest
  void test_varAndType_field() {
    super.test_varAndType_field();
  }

  @failingTest
  void test_varAndType_local() {
    super.test_varAndType_local();
  }

  @failingTest
  void test_varAndType_parameter() {
    super.test_varAndType_parameter();
  }

  @failingTest
  void test_varAndType_topLevelVariable() {
    super.test_varAndType_topLevelVariable();
  }

  @failingTest
  void test_varAsTypeName_as() {
    super.test_varAsTypeName_as();
  }

  @failingTest
  void test_varClass() {
    super.test_varClass();
  }

  @failingTest
  void test_varEnum() {
    super.test_varEnum();
  }

  @failingTest
  void test_varReturnType() {
    super.test_varReturnType();
  }

  @failingTest
  void test_varTypedef() {
    super.test_varTypedef();
  }

  @failingTest
  void test_voidParameter() {
    super.test_voidParameter();
  }

  @failingTest
  void test_voidVariable_parseClassMember_initializer() {
    super.test_voidVariable_parseClassMember_initializer();
  }

  @failingTest
  void test_voidVariable_parseClassMember_noInitializer() {
    super.test_voidVariable_parseClassMember_noInitializer();
  }

  @failingTest
  void test_voidVariable_parseCompilationUnit_initializer() {
    super.test_voidVariable_parseCompilationUnit_initializer();
  }

  @failingTest
  void test_voidVariable_parseCompilationUnit_noInitializer() {
    super.test_voidVariable_parseCompilationUnit_noInitializer();
  }

  @failingTest
  void test_voidVariable_parseCompilationUnitMember_initializer() {
    super.test_voidVariable_parseCompilationUnitMember_initializer();
  }

  @failingTest
  void test_voidVariable_parseCompilationUnitMember_noInitializer() {
    super.test_voidVariable_parseCompilationUnitMember_noInitializer();
  }

  @failingTest
  void test_voidVariable_statement_initializer() {
    super.test_voidVariable_statement_initializer();
  }

  @failingTest
  void test_voidVariable_statement_noInitializer() {
    super.test_voidVariable_statement_noInitializer();
  }

  @failingTest
  void test_withBeforeExtends() {
    super.test_withBeforeExtends();
  }

  @failingTest
  void test_withWithoutExtends() {
    super.test_withWithoutExtends();
  }

  @failingTest
  void test_wrongSeparatorForPositionalParameter() {
    super.test_wrongSeparatorForPositionalParameter();
  }

  @failingTest
  void test_wrongTerminatorForParameterGroup_named() {
    super.test_wrongTerminatorForParameterGroup_named();
  }

  @failingTest
  void test_wrongTerminatorForParameterGroup_optional() {
    super.test_wrongTerminatorForParameterGroup_optional();
  }
}

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
  void test_parseListLiteral_empty_oneToken_withComment() {
    super.test_parseListLiteral_empty_oneToken_withComment();
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

@reflectiveTest
class FormalParameterParserTest_Forest extends FastaBodyBuilderTestCase
    with FormalParameterParserTestMixin {
  FormalParameterParserTest_Forest() : super(false);

  @failingTest
  void test_parseFormalParameter_covariant_final_named() {
    super.test_parseFormalParameter_covariant_final_named();
  }

  @failingTest
  void test_parseFormalParameter_covariant_final_normal() {
    super.test_parseFormalParameter_covariant_final_normal();
  }

  @failingTest
  void test_parseFormalParameter_covariant_final_positional() {
    super.test_parseFormalParameter_covariant_final_positional();
  }

  @failingTest
  void test_parseFormalParameter_covariant_final_type_named() {
    super.test_parseFormalParameter_covariant_final_type_named();
  }

  @failingTest
  void test_parseFormalParameter_covariant_final_type_normal() {
    super.test_parseFormalParameter_covariant_final_type_normal();
  }

  @failingTest
  void test_parseFormalParameter_covariant_final_type_positional() {
    super.test_parseFormalParameter_covariant_final_type_positional();
  }

  @failingTest
  void test_parseFormalParameter_covariant_type_function() {
    super.test_parseFormalParameter_covariant_type_function();
  }

  @failingTest
  void test_parseFormalParameter_covariant_type_named() {
    super.test_parseFormalParameter_covariant_type_named();
  }

  @failingTest
  void test_parseFormalParameter_covariant_type_normal() {
    super.test_parseFormalParameter_covariant_type_normal();
  }

  @failingTest
  void test_parseFormalParameter_covariant_type_positional() {
    super.test_parseFormalParameter_covariant_type_positional();
  }

  @failingTest
  void test_parseFormalParameter_covariant_var_named() {
    super.test_parseFormalParameter_covariant_var_named();
  }

  @failingTest
  void test_parseFormalParameter_covariant_var_normal() {
    super.test_parseFormalParameter_covariant_var_normal();
  }

  @failingTest
  void test_parseFormalParameter_covariant_var_positional() {
    super.test_parseFormalParameter_covariant_var_positional();
  }

  @failingTest
  void test_parseFormalParameter_final_named() {
    super.test_parseFormalParameter_final_named();
  }

  @failingTest
  void test_parseFormalParameter_final_normal() {
    super.test_parseFormalParameter_final_normal();
  }

  @failingTest
  void test_parseFormalParameter_final_positional() {
    super.test_parseFormalParameter_final_positional();
  }

  @failingTest
  void test_parseFormalParameter_final_type_named() {
    super.test_parseFormalParameter_final_type_named();
  }

  @failingTest
  void test_parseFormalParameter_final_type_normal() {
    super.test_parseFormalParameter_final_type_normal();
  }

  @failingTest
  void test_parseFormalParameter_final_type_positional() {
    super.test_parseFormalParameter_final_type_positional();
  }

  @failingTest
  void test_parseFormalParameter_type_function() {
    super.test_parseFormalParameter_type_function();
  }

  @failingTest
  void test_parseFormalParameter_type_named() {
    super.test_parseFormalParameter_type_named();
  }

  @failingTest
  void test_parseFormalParameter_type_named_noDefault() {
    super.test_parseFormalParameter_type_named_noDefault();
  }

  @failingTest
  void test_parseFormalParameter_type_normal() {
    super.test_parseFormalParameter_type_normal();
  }

  @failingTest
  void test_parseFormalParameter_type_positional() {
    super.test_parseFormalParameter_type_positional();
  }

  @failingTest
  void test_parseFormalParameter_type_positional_noDefault() {
    super.test_parseFormalParameter_type_positional_noDefault();
  }

  @failingTest
  void test_parseFormalParameter_var_named() {
    super.test_parseFormalParameter_var_named();
  }

  @failingTest
  void test_parseFormalParameter_var_normal() {
    super.test_parseFormalParameter_var_normal();
  }

  @failingTest
  void test_parseFormalParameter_var_positional() {
    super.test_parseFormalParameter_var_positional();
  }

  @failingTest
  void test_parseFormalParameterList_empty() {
    super.test_parseFormalParameterList_empty();
  }

  @failingTest
  void test_parseFormalParameterList_named_multiple() {
    super.test_parseFormalParameterList_named_multiple();
  }

  @failingTest
  void test_parseFormalParameterList_named_single() {
    super.test_parseFormalParameterList_named_single();
  }

  @failingTest
  void test_parseFormalParameterList_named_trailing_comma() {
    super.test_parseFormalParameterList_named_trailing_comma();
  }

  @failingTest
  void test_parseFormalParameterList_normal_multiple() {
    super.test_parseFormalParameterList_normal_multiple();
  }

  @failingTest
  void test_parseFormalParameterList_normal_named() {
    super.test_parseFormalParameterList_normal_named();
  }

  @failingTest
  void test_parseFormalParameterList_normal_named_inFunctionType() {
    super.test_parseFormalParameterList_normal_named_inFunctionType();
  }

  @failingTest
  void test_parseFormalParameterList_normal_positional() {
    super.test_parseFormalParameterList_normal_positional();
  }

  @failingTest
  void test_parseFormalParameterList_normal_single() {
    super.test_parseFormalParameterList_normal_single();
  }

  @failingTest
  void test_parseFormalParameterList_normal_single_Function() {
    super.test_parseFormalParameterList_normal_single_Function();
  }

  @failingTest
  void test_parseFormalParameterList_normal_single_trailing_comma() {
    super.test_parseFormalParameterList_normal_single_trailing_comma();
  }

  @failingTest
  void test_parseFormalParameterList_positional_multiple() {
    super.test_parseFormalParameterList_positional_multiple();
  }

  @failingTest
  void test_parseFormalParameterList_positional_single() {
    super.test_parseFormalParameterList_positional_single();
  }

  @failingTest
  void test_parseFormalParameterList_positional_trailing_comma() {
    super.test_parseFormalParameterList_positional_trailing_comma();
  }

  @failingTest
  void test_parseFormalParameterList_prefixedType() {
    super.test_parseFormalParameterList_prefixedType();
  }

  @failingTest
  void test_parseFormalParameterList_prefixedType_missingName() {
    super.test_parseFormalParameterList_prefixedType_missingName();
  }

  @failingTest
  void test_parseFormalParameterList_prefixedType_partial() {
    super.test_parseFormalParameterList_prefixedType_partial();
  }

  @failingTest
  void test_parseFormalParameterList_prefixedType_partial2() {
    super.test_parseFormalParameterList_prefixedType_partial2();
  }

  @failingTest
  void test_parseNormalFormalParameter_field_const_noType() {
    super.test_parseNormalFormalParameter_field_const_noType();
  }

  @failingTest
  void test_parseNormalFormalParameter_field_const_type() {
    super.test_parseNormalFormalParameter_field_const_type();
  }

  @failingTest
  void test_parseNormalFormalParameter_field_final_noType() {
    super.test_parseNormalFormalParameter_field_final_noType();
  }

  @failingTest
  void test_parseNormalFormalParameter_field_final_type() {
    super.test_parseNormalFormalParameter_field_final_type();
  }

  @failingTest
  void test_parseNormalFormalParameter_field_function_nested() {
    super.test_parseNormalFormalParameter_field_function_nested();
  }

  @failingTest
  void test_parseNormalFormalParameter_field_function_noNested() {
    super.test_parseNormalFormalParameter_field_function_noNested();
  }

  @failingTest
  void test_parseNormalFormalParameter_field_function_withDocComment() {
    super.test_parseNormalFormalParameter_field_function_withDocComment();
  }

  @failingTest
  void test_parseNormalFormalParameter_field_noType() {
    super.test_parseNormalFormalParameter_field_noType();
  }

  @failingTest
  void test_parseNormalFormalParameter_field_type() {
    super.test_parseNormalFormalParameter_field_type();
  }

  @failingTest
  void test_parseNormalFormalParameter_field_var() {
    super.test_parseNormalFormalParameter_field_var();
  }

  @failingTest
  void test_parseNormalFormalParameter_field_withDocComment() {
    super.test_parseNormalFormalParameter_field_withDocComment();
  }

  @failingTest
  void test_parseNormalFormalParameter_function_named() {
    super.test_parseNormalFormalParameter_function_named();
  }

  @failingTest
  void test_parseNormalFormalParameter_function_noType() {
    super.test_parseNormalFormalParameter_function_noType();
  }

  @failingTest
  void test_parseNormalFormalParameter_function_noType_covariant() {
    super.test_parseNormalFormalParameter_function_noType_covariant();
  }

  @failingTest
  void test_parseNormalFormalParameter_function_noType_typeParameterComments() {
    super
        .test_parseNormalFormalParameter_function_noType_typeParameterComments();
  }

  @failingTest
  void test_parseNormalFormalParameter_function_noType_typeParameters() {
    super.test_parseNormalFormalParameter_function_noType_typeParameters();
  }

  @failingTest
  void test_parseNormalFormalParameter_function_type() {
    super.test_parseNormalFormalParameter_function_type();
  }

  @failingTest
  void test_parseNormalFormalParameter_function_type_typeParameterComments() {
    super.test_parseNormalFormalParameter_function_type_typeParameterComments();
  }

  @failingTest
  void test_parseNormalFormalParameter_function_type_typeParameters() {
    super.test_parseNormalFormalParameter_function_type_typeParameters();
  }

  @failingTest
  void test_parseNormalFormalParameter_function_typeVoid_covariant() {
    super.test_parseNormalFormalParameter_function_typeVoid_covariant();
  }

  @failingTest
  void test_parseNormalFormalParameter_function_void() {
    super.test_parseNormalFormalParameter_function_void();
  }

  @failingTest
  void test_parseNormalFormalParameter_function_void_typeParameterComments() {
    super.test_parseNormalFormalParameter_function_void_typeParameterComments();
  }

  @failingTest
  void test_parseNormalFormalParameter_function_void_typeParameters() {
    super.test_parseNormalFormalParameter_function_void_typeParameters();
  }

  @failingTest
  void test_parseNormalFormalParameter_function_withDocComment() {
    super.test_parseNormalFormalParameter_function_withDocComment();
  }

  @failingTest
  void test_parseNormalFormalParameter_simple_const_noType() {
    super.test_parseNormalFormalParameter_simple_const_noType();
  }

  @failingTest
  void test_parseNormalFormalParameter_simple_const_type() {
    super.test_parseNormalFormalParameter_simple_const_type();
  }

  @failingTest
  void test_parseNormalFormalParameter_simple_final_noType() {
    super.test_parseNormalFormalParameter_simple_final_noType();
  }

  @failingTest
  void test_parseNormalFormalParameter_simple_final_type() {
    super.test_parseNormalFormalParameter_simple_final_type();
  }

  @failingTest
  void test_parseNormalFormalParameter_simple_noName() {
    super.test_parseNormalFormalParameter_simple_noName();
  }

  @failingTest
  void test_parseNormalFormalParameter_simple_noType() {
    super.test_parseNormalFormalParameter_simple_noType();
  }

  @failingTest
  void test_parseNormalFormalParameter_simple_noType_namedCovariant() {
    super.test_parseNormalFormalParameter_simple_noType_namedCovariant();
  }

  @failingTest
  void test_parseNormalFormalParameter_simple_type() {
    super.test_parseNormalFormalParameter_simple_type();
  }
}

@reflectiveTest
class RecoveryParserTest_Forest extends FastaBodyBuilderTestCase
    with RecoveryParserTestMixin {
  RecoveryParserTest_Forest() : super(false);

  @failingTest
  void test_additiveExpression_missing_LHS() {
    super.test_additiveExpression_missing_LHS();
  }

  @failingTest
  void test_additiveExpression_missing_LHS_RHS() {
    super.test_additiveExpression_missing_LHS_RHS();
  }

  @failingTest
  void test_additiveExpression_missing_RHS() {
    super.test_additiveExpression_missing_RHS();
  }

  @failingTest
  void test_additiveExpression_missing_RHS_super() {
    super.test_additiveExpression_missing_RHS_super();
  }

  @failingTest
  void test_additiveExpression_precedence_multiplicative_left() {
    super.test_additiveExpression_precedence_multiplicative_left();
  }

  @failingTest
  void test_additiveExpression_precedence_multiplicative_right() {
    super.test_additiveExpression_precedence_multiplicative_right();
  }

  @failingTest
  void test_additiveExpression_super() {
    super.test_additiveExpression_super();
  }

  @failingTest
  void test_assignableSelector() {
    super.test_assignableSelector();
  }

  @failingTest
  void test_assignmentExpression_missing_compound1() {
    super.test_assignmentExpression_missing_compound1();
  }

  @failingTest
  void test_assignmentExpression_missing_compound2() {
    super.test_assignmentExpression_missing_compound2();
  }

  @failingTest
  void test_assignmentExpression_missing_compound3() {
    super.test_assignmentExpression_missing_compound3();
  }

  @failingTest
  void test_assignmentExpression_missing_LHS() {
    super.test_assignmentExpression_missing_LHS();
  }

  @failingTest
  void test_assignmentExpression_missing_RHS() {
    super.test_assignmentExpression_missing_RHS();
  }

  @failingTest
  void test_bitwiseAndExpression_missing_LHS() {
    super.test_bitwiseAndExpression_missing_LHS();
  }

  @failingTest
  void test_bitwiseAndExpression_missing_LHS_RHS() {
    super.test_bitwiseAndExpression_missing_LHS_RHS();
  }

  @failingTest
  void test_bitwiseAndExpression_missing_RHS() {
    super.test_bitwiseAndExpression_missing_RHS();
  }

  @failingTest
  void test_bitwiseAndExpression_missing_RHS_super() {
    super.test_bitwiseAndExpression_missing_RHS_super();
  }

  @failingTest
  void test_bitwiseAndExpression_precedence_equality_left() {
    super.test_bitwiseAndExpression_precedence_equality_left();
  }

  @failingTest
  void test_bitwiseAndExpression_precedence_equality_right() {
    super.test_bitwiseAndExpression_precedence_equality_right();
  }

  @failingTest
  void test_bitwiseAndExpression_super() {
    super.test_bitwiseAndExpression_super();
  }

  @failingTest
  void test_bitwiseOrExpression_missing_LHS() {
    super.test_bitwiseOrExpression_missing_LHS();
  }

  @failingTest
  void test_bitwiseOrExpression_missing_LHS_RHS() {
    super.test_bitwiseOrExpression_missing_LHS_RHS();
  }

  @failingTest
  void test_bitwiseOrExpression_missing_RHS() {
    super.test_bitwiseOrExpression_missing_RHS();
  }

  @failingTest
  void test_bitwiseOrExpression_missing_RHS_super() {
    super.test_bitwiseOrExpression_missing_RHS_super();
  }

  @failingTest
  void test_bitwiseOrExpression_precedence_xor_left() {
    super.test_bitwiseOrExpression_precedence_xor_left();
  }

  @failingTest
  void test_bitwiseOrExpression_precedence_xor_right() {
    super.test_bitwiseOrExpression_precedence_xor_right();
  }

  @failingTest
  void test_bitwiseOrExpression_super() {
    super.test_bitwiseOrExpression_super();
  }

  @failingTest
  void test_bitwiseXorExpression_missing_LHS() {
    super.test_bitwiseXorExpression_missing_LHS();
  }

  @failingTest
  void test_bitwiseXorExpression_missing_LHS_RHS() {
    super.test_bitwiseXorExpression_missing_LHS_RHS();
  }

  @failingTest
  void test_bitwiseXorExpression_missing_RHS() {
    super.test_bitwiseXorExpression_missing_RHS();
  }

  @failingTest
  void test_bitwiseXorExpression_missing_RHS_super() {
    super.test_bitwiseXorExpression_missing_RHS_super();
  }

  @failingTest
  void test_bitwiseXorExpression_precedence_and_left() {
    super.test_bitwiseXorExpression_precedence_and_left();
  }

  @failingTest
  void test_bitwiseXorExpression_precedence_and_right() {
    super.test_bitwiseXorExpression_precedence_and_right();
  }

  @failingTest
  void test_bitwiseXorExpression_super() {
    super.test_bitwiseXorExpression_super();
  }

  @failingTest
  void test_classTypeAlias_withBody() {
    super.test_classTypeAlias_withBody();
  }

  @failingTest
  void test_combinator_missingIdentifier() {
    super.test_combinator_missingIdentifier();
  }

  @failingTest
  void test_conditionalExpression_missingElse() {
    super.test_conditionalExpression_missingElse();
  }

  @failingTest
  void test_conditionalExpression_missingThen() {
    super.test_conditionalExpression_missingThen();
  }

  @failingTest
  void test_declarationBeforeDirective() {
    super.test_declarationBeforeDirective();
  }

  @failingTest
  void test_equalityExpression_missing_LHS() {
    super.test_equalityExpression_missing_LHS();
  }

  @failingTest
  void test_equalityExpression_missing_LHS_RHS() {
    super.test_equalityExpression_missing_LHS_RHS();
  }

  @failingTest
  void test_equalityExpression_missing_RHS() {
    super.test_equalityExpression_missing_RHS();
  }

  @failingTest
  void test_equalityExpression_missing_RHS_super() {
    super.test_equalityExpression_missing_RHS_super();
  }

  @failingTest
  void test_equalityExpression_precedence_relational_left() {
    super.test_equalityExpression_precedence_relational_left();
  }

  @failingTest
  void test_equalityExpression_precedence_relational_right() {
    super.test_equalityExpression_precedence_relational_right();
  }

  @failingTest
  void test_equalityExpression_super() {
    super.test_equalityExpression_super();
  }

  @failingTest
  void test_expressionList_multiple_end() {
    super.test_expressionList_multiple_end();
  }

  @failingTest
  void test_expressionList_multiple_middle() {
    super.test_expressionList_multiple_middle();
  }

  @failingTest
  void test_expressionList_multiple_start() {
    super.test_expressionList_multiple_start();
  }

  @failingTest
  void test_functionExpression_in_ConstructorFieldInitializer() {
    super.test_functionExpression_in_ConstructorFieldInitializer();
  }

  @failingTest
  void test_functionExpression_named() {
    super.test_functionExpression_named();
  }

  @failingTest
  void test_ifStatement_noElse_statement() {
    super.test_ifStatement_noElse_statement();
  }

  @failingTest
  void test_importDirectivePartial_as() {
    super.test_importDirectivePartial_as();
  }

  @failingTest
  void test_importDirectivePartial_hide() {
    super.test_importDirectivePartial_hide();
  }

  @failingTest
  void test_importDirectivePartial_show() {
    super.test_importDirectivePartial_show();
  }

  @failingTest
  void test_incomplete_conditionalExpression() {
    super.test_incomplete_conditionalExpression();
  }

  @failingTest
  void test_incomplete_constructorInitializers_empty() {
    super.test_incomplete_constructorInitializers_empty();
  }

  @failingTest
  void test_incomplete_constructorInitializers_missingEquals() {
    super.test_incomplete_constructorInitializers_missingEquals();
  }

  @failingTest
  void test_incomplete_constructorInitializers_this() {
    super.test_incomplete_constructorInitializers_this();
  }

  @failingTest
  void test_incomplete_constructorInitializers_thisField() {
    super.test_incomplete_constructorInitializers_thisField();
  }

  @failingTest
  void test_incomplete_constructorInitializers_thisPeriod() {
    super.test_incomplete_constructorInitializers_thisPeriod();
  }

  @failingTest
  void test_incomplete_constructorInitializers_variable() {
    super.test_incomplete_constructorInitializers_variable();
  }

  @failingTest
  void test_incomplete_functionExpression() {
    super.test_incomplete_functionExpression();
  }

  @failingTest
  void test_incomplete_functionExpression2() {
    super.test_incomplete_functionExpression2();
  }

  @failingTest
  void test_incomplete_returnType() {
    super.test_incomplete_returnType();
  }

  @failingTest
  void test_incomplete_topLevelFunction() {
    super.test_incomplete_topLevelFunction();
  }

  @failingTest
  void test_incomplete_topLevelVariable() {
    super.test_incomplete_topLevelVariable();
  }

  @failingTest
  void test_incomplete_topLevelVariable_const() {
    super.test_incomplete_topLevelVariable_const();
  }

  @failingTest
  void test_incomplete_topLevelVariable_final() {
    super.test_incomplete_topLevelVariable_final();
  }

  @failingTest
  void test_incomplete_topLevelVariable_var() {
    super.test_incomplete_topLevelVariable_var();
  }

  @failingTest
  void test_incompleteField_const() {
    super.test_incompleteField_const();
  }

  @failingTest
  void test_incompleteField_final() {
    super.test_incompleteField_final();
  }

  @failingTest
  void test_incompleteField_static() {
    super.test_incompleteField_static();
  }

  @failingTest
  void test_incompleteField_static2() {
    super.test_incompleteField_static2();
  }

  @failingTest
  void test_incompleteField_type() {
    super.test_incompleteField_type();
  }

  @failingTest
  void test_incompleteField_var() {
    super.test_incompleteField_var();
  }

  @failingTest
  void test_incompleteForEach() {
    super.test_incompleteForEach();
  }

  @failingTest
  void test_incompleteLocalVariable_atTheEndOfBlock() {
    super.test_incompleteLocalVariable_atTheEndOfBlock();
  }

  @failingTest
  void test_incompleteLocalVariable_atTheEndOfBlock_modifierOnly() {
    super.test_incompleteLocalVariable_atTheEndOfBlock_modifierOnly();
  }

  @failingTest
  void test_incompleteLocalVariable_beforeIdentifier() {
    super.test_incompleteLocalVariable_beforeIdentifier();
  }

  @failingTest
  void test_incompleteLocalVariable_beforeKeyword() {
    super.test_incompleteLocalVariable_beforeKeyword();
  }

  @failingTest
  void test_incompleteLocalVariable_beforeNextBlock() {
    super.test_incompleteLocalVariable_beforeNextBlock();
  }

  @failingTest
  void test_incompleteLocalVariable_parameterizedType() {
    super.test_incompleteLocalVariable_parameterizedType();
  }

  @failingTest
  void test_incompleteTypeArguments_field() {
    super.test_incompleteTypeArguments_field();
  }

  @failingTest
  void test_incompleteTypeParameters() {
    super.test_incompleteTypeParameters();
  }

  @failingTest
  void test_incompleteTypeParameters2() {
    super.test_incompleteTypeParameters2();
  }

  @failingTest
  void test_invalidFunctionBodyModifier() {
    super.test_invalidFunctionBodyModifier();
  }

  @failingTest
  void test_invalidTypeParameters() {
    super.test_invalidTypeParameters();
  }

  @failingTest
  void test_isExpression_noType() {
    super.test_isExpression_noType();
  }

  @failingTest
  void test_keywordInPlaceOfIdentifier() {
    super.test_keywordInPlaceOfIdentifier();
  }

  @failingTest
  void test_logicalAndExpression_missing_LHS() {
    super.test_logicalAndExpression_missing_LHS();
  }

  @failingTest
  void test_logicalAndExpression_missing_LHS_RHS() {
    super.test_logicalAndExpression_missing_LHS_RHS();
  }

  @failingTest
  void test_logicalAndExpression_missing_RHS() {
    super.test_logicalAndExpression_missing_RHS();
  }

  @failingTest
  void test_logicalAndExpression_precedence_bitwiseOr_left() {
    super.test_logicalAndExpression_precedence_bitwiseOr_left();
  }

  @failingTest
  void test_logicalAndExpression_precedence_bitwiseOr_right() {
    super.test_logicalAndExpression_precedence_bitwiseOr_right();
  }

  @failingTest
  void test_logicalOrExpression_missing_LHS() {
    super.test_logicalOrExpression_missing_LHS();
  }

  @failingTest
  void test_logicalOrExpression_missing_LHS_RHS() {
    super.test_logicalOrExpression_missing_LHS_RHS();
  }

  @failingTest
  void test_logicalOrExpression_missing_RHS() {
    super.test_logicalOrExpression_missing_RHS();
  }

  @failingTest
  void test_logicalOrExpression_precedence_logicalAnd_left() {
    super.test_logicalOrExpression_precedence_logicalAnd_left();
  }

  @failingTest
  void test_logicalOrExpression_precedence_logicalAnd_right() {
    super.test_logicalOrExpression_precedence_logicalAnd_right();
  }

  @failingTest
  void test_method_missingBody() {
    super.test_method_missingBody();
  }

  @failingTest
  void test_missing_commaInArgumentList() {
    super.test_missing_commaInArgumentList();
  }

  @failingTest
  void test_missingComma_beforeNamedArgument() {
    super.test_missingComma_beforeNamedArgument();
  }

  @failingTest
  void test_missingGet() {
    super.test_missingGet();
  }

  @failingTest
  void test_missingIdentifier_afterAnnotation() {
    super.test_missingIdentifier_afterAnnotation();
  }

  @failingTest
  void test_missingSemicolon_varialeDeclarationList() {
    super.test_missingSemicolon_varialeDeclarationList();
  }

  @failingTest
  void test_multiplicativeExpression_missing_LHS() {
    super.test_multiplicativeExpression_missing_LHS();
  }

  @failingTest
  void test_multiplicativeExpression_missing_LHS_RHS() {
    super.test_multiplicativeExpression_missing_LHS_RHS();
  }

  @failingTest
  void test_multiplicativeExpression_missing_RHS() {
    super.test_multiplicativeExpression_missing_RHS();
  }

  @failingTest
  void test_multiplicativeExpression_missing_RHS_super() {
    super.test_multiplicativeExpression_missing_RHS_super();
  }

  @failingTest
  void test_multiplicativeExpression_precedence_unary_left() {
    super.test_multiplicativeExpression_precedence_unary_left();
  }

  @failingTest
  void test_multiplicativeExpression_precedence_unary_right() {
    super.test_multiplicativeExpression_precedence_unary_right();
  }

  @failingTest
  void test_multiplicativeExpression_super() {
    super.test_multiplicativeExpression_super();
  }

  @failingTest
  void test_namedParameterOutsideGroup() {
    super.test_namedParameterOutsideGroup();
  }

  @failingTest
  void test_nonStringLiteralUri_import() {
    super.test_nonStringLiteralUri_import();
  }

  @failingTest
  void test_prefixExpression_missing_operand_minus() {
    super.test_prefixExpression_missing_operand_minus();
  }

  @failingTest
  void test_primaryExpression_argumentDefinitionTest() {
    super.test_primaryExpression_argumentDefinitionTest();
  }

  @failingTest
  void test_propertyAccess_missing_LHS_RHS() {
    super.test_propertyAccess_missing_LHS_RHS();
  }

  @failingTest
  void test_relationalExpression_missing_LHS() {
    super.test_relationalExpression_missing_LHS();
  }

  @failingTest
  void test_relationalExpression_missing_LHS_RHS() {
    super.test_relationalExpression_missing_LHS_RHS();
  }

  @failingTest
  void test_relationalExpression_missing_RHS() {
    super.test_relationalExpression_missing_RHS();
  }

  @failingTest
  void test_relationalExpression_precedence_shift_right() {
    super.test_relationalExpression_precedence_shift_right();
  }

  @failingTest
  void test_shiftExpression_missing_LHS() {
    super.test_shiftExpression_missing_LHS();
  }

  @failingTest
  void test_shiftExpression_missing_LHS_RHS() {
    super.test_shiftExpression_missing_LHS_RHS();
  }

  @failingTest
  void test_shiftExpression_missing_RHS() {
    super.test_shiftExpression_missing_RHS();
  }

  @failingTest
  void test_shiftExpression_missing_RHS_super() {
    super.test_shiftExpression_missing_RHS_super();
  }

  @failingTest
  void test_shiftExpression_precedence_unary_left() {
    super.test_shiftExpression_precedence_unary_left();
  }

  @failingTest
  void test_shiftExpression_precedence_unary_right() {
    super.test_shiftExpression_precedence_unary_right();
  }

  @failingTest
  void test_shiftExpression_super() {
    super.test_shiftExpression_super();
  }

  @failingTest
  void test_typedef_eof() {
    super.test_typedef_eof();
  }

  @failingTest
  void test_unaryPlus() {
    super.test_unaryPlus();
  }
}

@reflectiveTest
class SimpleParserTest_Forest extends FastaBodyBuilderTestCase
    with SimpleParserTestMixin {
  SimpleParserTest_Forest() : super(false);

  @failingTest
  void test_classDeclaration_complexTypeParam() {
    super.test_classDeclaration_complexTypeParam();
  }

  @failingTest
  void test_parseAnnotation_n1() {
    super.test_parseAnnotation_n1();
  }

  @failingTest
  void test_parseAnnotation_n1_a() {
    super.test_parseAnnotation_n1_a();
  }

  @failingTest
  void test_parseAnnotation_n2() {
    super.test_parseAnnotation_n2();
  }

  @failingTest
  void test_parseAnnotation_n2_a() {
    super.test_parseAnnotation_n2_a();
  }

  @failingTest
  void test_parseAnnotation_n3() {
    super.test_parseAnnotation_n3();
  }

  @failingTest
  void test_parseAnnotation_n3_a() {
    super.test_parseAnnotation_n3_a();
  }

  @failingTest
  void test_parseArgumentList_empty() {
    super.test_parseArgumentList_empty();
  }

  @failingTest
  void test_parseArgumentList_mixed() {
    super.test_parseArgumentList_mixed();
  }

  @failingTest
  void test_parseArgumentList_noNamed() {
    super.test_parseArgumentList_noNamed();
  }

  @failingTest
  void test_parseArgumentList_onlyNamed() {
    super.test_parseArgumentList_onlyNamed();
  }

  @failingTest
  void test_parseArgumentList_trailing_comma() {
    super.test_parseArgumentList_trailing_comma();
  }

  @failingTest
  void test_parseArgumentList_typeArguments() {
    super.test_parseArgumentList_typeArguments();
  }

  @failingTest
  void test_parseArgumentList_typeArguments_prefixed() {
    super.test_parseArgumentList_typeArguments_prefixed();
  }

  @failingTest
  void test_parseArgumentList_typeArguments_none() {
    super.test_parseArgumentList_typeArguments_none();
  }

  @failingTest
  void test_parseCombinators_h() {
    super.test_parseCombinators_h();
  }

  @failingTest
  void test_parseCombinators_hs() {
    super.test_parseCombinators_hs();
  }

  @failingTest
  void test_parseCombinators_hshs() {
    super.test_parseCombinators_hshs();
  }

  @failingTest
  void test_parseCombinators_s() {
    super.test_parseCombinators_s();
  }

  @failingTest
  void test_parseCommentAndMetadata_c() {
    super.test_parseCommentAndMetadata_c();
  }

  @failingTest
  void test_parseCommentAndMetadata_cmc() {
    super.test_parseCommentAndMetadata_cmc();
  }

  @failingTest
  void test_parseCommentAndMetadata_cmcm() {
    super.test_parseCommentAndMetadata_cmcm();
  }

  @failingTest
  void test_parseCommentAndMetadata_cmm() {
    super.test_parseCommentAndMetadata_cmm();
  }

  @failingTest
  void test_parseCommentAndMetadata_m() {
    super.test_parseCommentAndMetadata_m();
  }

  @failingTest
  void test_parseCommentAndMetadata_mcm() {
    super.test_parseCommentAndMetadata_mcm();
  }

  @failingTest
  void test_parseCommentAndMetadata_mcmc() {
    super.test_parseCommentAndMetadata_mcmc();
  }

  @failingTest
  void test_parseCommentAndMetadata_mm() {
    super.test_parseCommentAndMetadata_mm();
  }

  @failingTest
  void test_parseCommentAndMetadata_none() {
    super.test_parseCommentAndMetadata_none();
  }

  @failingTest
  void test_parseCommentAndMetadata_singleLine() {
    super.test_parseCommentAndMetadata_singleLine();
  }

  @failingTest
  void test_parseConfiguration_noOperator_dottedIdentifier() {
    super.test_parseConfiguration_noOperator_dottedIdentifier();
  }

  @failingTest
  void test_parseConfiguration_noOperator_simpleIdentifier() {
    super.test_parseConfiguration_noOperator_simpleIdentifier();
  }

  @failingTest
  void test_parseConfiguration_operator_dottedIdentifier() {
    super.test_parseConfiguration_operator_dottedIdentifier();
  }

  @failingTest
  void test_parseConfiguration_operator_simpleIdentifier() {
    super.test_parseConfiguration_operator_simpleIdentifier();
  }

  @failingTest
  void test_parseConstructorName_named_noPrefix() {
    super.test_parseConstructorName_named_noPrefix();
  }

  @failingTest
  void test_parseConstructorName_named_prefixed() {
    super.test_parseConstructorName_named_prefixed();
  }

  @failingTest
  void test_parseConstructorName_unnamed_noPrefix() {
    super.test_parseConstructorName_unnamed_noPrefix();
  }

  @failingTest
  void test_parseConstructorName_unnamed_prefixed() {
    super.test_parseConstructorName_unnamed_prefixed();
  }

  @failingTest
  void test_parseDocumentationComment_block() {
    super.test_parseDocumentationComment_block();
  }

  @failingTest
  void test_parseDocumentationComment_block_withReference() {
    super.test_parseDocumentationComment_block_withReference();
  }

  @failingTest
  void test_parseDocumentationComment_endOfLine() {
    super.test_parseDocumentationComment_endOfLine();
  }

  @failingTest
  void test_parseExtendsClause() {
    super.test_parseExtendsClause();
  }

  @failingTest
  void test_parseFunctionBody_block() {
    super.test_parseFunctionBody_block();
  }

  @failingTest
  void test_parseFunctionBody_block_async() {
    super.test_parseFunctionBody_block_async();
  }

  @failingTest
  void test_parseFunctionBody_block_asyncGenerator() {
    super.test_parseFunctionBody_block_asyncGenerator();
  }

  @failingTest
  void test_parseFunctionBody_block_syncGenerator() {
    super.test_parseFunctionBody_block_syncGenerator();
  }

  @failingTest
  void test_parseFunctionBody_empty() {
    super.test_parseFunctionBody_empty();
  }

  @failingTest
  void test_parseFunctionBody_expression() {
    super.test_parseFunctionBody_expression();
  }

  @failingTest
  void test_parseFunctionBody_expression_async() {
    super.test_parseFunctionBody_expression_async();
  }

  @failingTest
  void test_parseIdentifierList_multiple() {
    super.test_parseIdentifierList_multiple();
  }

  @failingTest
  void test_parseIdentifierList_single() {
    super.test_parseIdentifierList_single();
  }

  @failingTest
  void test_parseImplementsClause_multiple() {
    super.test_parseImplementsClause_multiple();
  }

  @failingTest
  void test_parseImplementsClause_single() {
    super.test_parseImplementsClause_single();
  }

  @failingTest
  void test_parseInstanceCreation_noKeyword_noPrefix() {
    super.test_parseInstanceCreation_noKeyword_noPrefix();
  }

  @failingTest
  void test_parseInstanceCreation_noKeyword_prefix() {
    super.test_parseInstanceCreation_noKeyword_prefix();
  }

  @failingTest
  void test_parseInstanceCreation_noKeyword_varInit() {
    super.test_parseInstanceCreation_noKeyword_varInit();
  }

  @failingTest
  void test_parseLibraryIdentifier_builtin() {
    super.test_parseLibraryIdentifier_builtin();
  }

  @failingTest
  void test_parseLibraryIdentifier_invalid() {
    super.test_parseLibraryIdentifier_invalid();
  }

  @failingTest
  void test_parseLibraryIdentifier_multiple() {
    super.test_parseLibraryIdentifier_multiple();
  }

  @failingTest
  void test_parseLibraryIdentifier_pseudo() {
    super.test_parseLibraryIdentifier_pseudo();
  }

  @failingTest
  void test_parseLibraryIdentifier_single() {
    super.test_parseLibraryIdentifier_single();
  }

  @failingTest
  void test_parseReturnStatement_noValue() {
    super.test_parseReturnStatement_noValue();
  }

  @failingTest
  void test_parseReturnStatement_value() {
    super.test_parseReturnStatement_value();
  }

  @failingTest
  void test_parseStatement_function_noReturnType() {
    super.test_parseStatement_function_noReturnType();
  }

  @failingTest
  void test_parseStatements_multiple() {
    super.test_parseStatements_multiple();
  }

  @failingTest
  void test_parseStatements_single() {
    super.test_parseStatements_single();
  }

  @failingTest
  void test_parseTypeAnnotation_function_noReturnType_noParameters() {
    super.test_parseTypeAnnotation_function_noReturnType_noParameters();
  }

  @failingTest
  void test_parseTypeAnnotation_function_noReturnType_parameters() {
    super.test_parseTypeAnnotation_function_noReturnType_parameters();
  }

  @failingTest
  void test_parseTypeAnnotation_function_noReturnType_typeParameters() {
    super.test_parseTypeAnnotation_function_noReturnType_typeParameters();
  }

  @failingTest
  void
      test_parseTypeAnnotation_function_noReturnType_typeParameters_parameters() {
    super
        .test_parseTypeAnnotation_function_noReturnType_typeParameters_parameters();
  }

  @failingTest
  void test_parseTypeAnnotation_function_returnType_classFunction() {
    super.test_parseTypeAnnotation_function_returnType_classFunction();
  }

  @failingTest
  void test_parseTypeAnnotation_function_returnType_function() {
    super.test_parseTypeAnnotation_function_returnType_function();
  }

  @failingTest
  void test_parseTypeAnnotation_function_returnType_noParameters() {
    super.test_parseTypeAnnotation_function_returnType_noParameters();
  }

  @failingTest
  void test_parseTypeAnnotation_function_returnType_parameters() {
    super.test_parseTypeAnnotation_function_returnType_parameters();
  }

  @failingTest
  void test_parseTypeAnnotation_function_returnType_simple() {
    super.test_parseTypeAnnotation_function_returnType_simple();
  }

  @failingTest
  void test_parseTypeAnnotation_function_returnType_typeParameters() {
    super.test_parseTypeAnnotation_function_returnType_typeParameters();
  }

  @failingTest
  void
      test_parseTypeAnnotation_function_returnType_typeParameters_parameters() {
    super
        .test_parseTypeAnnotation_function_returnType_typeParameters_parameters();
  }

  @failingTest
  void test_parseTypeAnnotation_function_returnType_withArguments() {
    super.test_parseTypeAnnotation_function_returnType_withArguments();
  }

  @failingTest
  void test_parseTypeAnnotation_named() {
    super.test_parseTypeAnnotation_named();
  }

  @failingTest
  void test_parseTypeArgumentList_empty() {
    super.test_parseTypeArgumentList_empty();
  }

  @failingTest
  void test_parseTypeArgumentList_multiple() {
    super.test_parseTypeArgumentList_multiple();
  }

  @failingTest
  void test_parseTypeArgumentList_nested() {
    super.test_parseTypeArgumentList_nested();
  }

  @failingTest
  void test_parseTypeArgumentList_nested_withComment_double() {
    super.test_parseTypeArgumentList_nested_withComment_double();
  }

  @failingTest
  void test_parseTypeArgumentList_nested_withComment_tripple() {
    super.test_parseTypeArgumentList_nested_withComment_tripple();
  }

  @failingTest
  void test_parseTypeArgumentList_single() {
    super.test_parseTypeArgumentList_single();
  }

  @failingTest
  void test_parseTypeName_parameterized() {
    super.test_parseTypeName_parameterized();
  }

  @failingTest
  void test_parseTypeName_simple() {
    super.test_parseTypeName_simple();
  }

  @failingTest
  void test_parseTypeParameter_bounded_functionType_noReturn() {
    super.test_parseTypeParameter_bounded_functionType_noReturn();
  }

  @failingTest
  void test_parseTypeParameter_bounded_functionType_return() {
    super.test_parseTypeParameter_bounded_functionType_return();
  }

  @failingTest
  void test_parseTypeParameter_bounded_generic() {
    super.test_parseTypeParameter_bounded_generic();
  }

  @failingTest
  void test_parseTypeParameter_bounded_simple() {
    super.test_parseTypeParameter_bounded_simple();
  }

  @failingTest
  void test_parseTypeParameter_simple() {
    super.test_parseTypeParameter_simple();
  }

  @failingTest
  void test_parseTypeParameterList_multiple() {
    super.test_parseTypeParameterList_multiple();
  }

  @failingTest
  void test_parseTypeParameterList_parameterizedWithTrailingEquals() {
    super.test_parseTypeParameterList_parameterizedWithTrailingEquals();
  }

  @failingTest
  void test_parseTypeParameterList_parameterizedWithTrailingEquals2() {
    super.test_parseTypeParameterList_parameterizedWithTrailingEquals2();
  }

  @failingTest
  void test_parseTypeParameterList_single() {
    super.test_parseTypeParameterList_single();
  }

  @failingTest
  void test_parseTypeParameterList_withTrailingEquals() {
    super.test_parseTypeParameterList_withTrailingEquals();
  }

  @failingTest
  void test_parseVariableDeclaration_equals() {
    super.test_parseVariableDeclaration_equals();
  }

  @failingTest
  void test_parseVariableDeclaration_noEquals() {
    super.test_parseVariableDeclaration_noEquals();
  }

  @failingTest
  void test_parseWithClause_multiple() {
    super.test_parseWithClause_multiple();
  }

  @failingTest
  void test_parseWithClause_single() {
    super.test_parseWithClause_single();
  }
}

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
  void test_parseIfStatement_else_emptyStatements() {
    super.test_parseIfStatement_else_emptyStatements();
    fail(
        'This passes under Dart 1, but fails under Dart 2 because of a cast exception');
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
  void test_parseNonLabeledStatement_startingWithBuiltInIdentifier() {
    super.test_parseNonLabeledStatement_startingWithBuiltInIdentifier();
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
