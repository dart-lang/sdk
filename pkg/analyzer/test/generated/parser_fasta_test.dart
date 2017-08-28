// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart' as analyzer;
import 'package:analyzer/dart/ast/token.dart' show TokenType;
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart' show ErrorReporter;
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/fasta/ast_builder.dart';
import 'package:analyzer/src/generated/parser.dart' as analyzer;
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/string_source.dart';
import 'package:front_end/src/fasta/fasta_codes.dart' show Message;
import 'package:front_end/src/fasta/kernel/kernel_builder.dart';
import 'package:front_end/src/fasta/kernel/kernel_library_builder.dart';
import 'package:front_end/src/fasta/parser.dart' show IdentifierContext;
import 'package:front_end/src/fasta/parser.dart' as fasta;
import 'package:front_end/src/fasta/scanner/string_scanner.dart';
import 'package:front_end/src/fasta/scanner/token.dart' as fasta;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'parser_fasta_listener.dart';
import 'parser_test.dart';
import 'test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClassMemberParserTest_Fasta);
    defineReflectiveTests(ComplexParserTest_Fasta);
    defineReflectiveTests(ErrorParserTest_Fasta);
    defineReflectiveTests(ExpressionParserTest_Fasta);
    defineReflectiveTests(FormalParameterParserTest_Fasta);
    defineReflectiveTests(StatementParserTest_Fasta);
    defineReflectiveTests(TopLevelParserTest_Fasta);
  });
}

/**
 * Type of the "parse..." methods defined in the Fasta parser.
 */
typedef analyzer.Token ParseFunction(analyzer.Token token);

/**
 * Proxy implementation of [Builder] used by Fasta parser tests.
 *
 * All undeclared identifiers are presumed to resolve via an instance of this
 * class.
 */
class BuilderProxy implements Builder {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

@reflectiveTest
class ClassMemberParserTest_Fasta extends FastaParserTestCase
    with ClassMemberParserTestMixin {
  @override
  @failingTest
  void test_parseConstructor_assert() {
    // TODO(paulberry): Fasta doesn't support asserts in initializers
    super.test_parseConstructor_assert();
  }
}

/**
 * Tests of the fasta parser based on [ComplexParserTestMixin].
 */
@reflectiveTest
class ComplexParserTest_Fasta extends FastaParserTestCase
    with ComplexParserTestMixin {
  @override
  @failingTest
  void test_assignableExpression_arguments_normal_chain_typeArgumentComments() {
    // TODO(paulberry,ahe): Fasta doesn't support generic method comment syntax.
    super
        .test_assignableExpression_arguments_normal_chain_typeArgumentComments();
  }

  @override
  @failingTest
  void test_assignableExpression_arguments_normal_chain_typeArguments() {
    // TODO(paulberry,ahe): AstBuilder doesn't implement
    // endTypeArguments().
    super.test_assignableExpression_arguments_normal_chain_typeArguments();
  }

  @override
  @failingTest
  void test_conditionalExpression_precedence_nullableType_as() {
    // TODO(paulberry,ahe): Fasta doesn't support NNBD syntax yet.
    super.test_conditionalExpression_precedence_nullableType_as();
  }

  @override
  @failingTest
  void test_conditionalExpression_precedence_nullableType_is() {
    // TODO(paulberry,ahe): Fasta doesn't support NNBD syntax yet.
    super.test_conditionalExpression_precedence_nullableType_is();
  }

  @override
  @failingTest
  void test_equalityExpression_normal() {
    // TODO(scheglov) error checking is not implemented
    super.test_equalityExpression_normal();
  }

  @override
  @failingTest
  void test_equalityExpression_super() {
    // TODO(scheglov) error checking is not implemented
    super.test_equalityExpression_super();
  }

  @override
  @failingTest
  void test_logicalAndExpression_precedence_nullableType() {
    // TODO(paulberry,ahe): Fasta doesn't support NNBD syntax yet.
    super.test_logicalAndExpression_precedence_nullableType();
  }

  @override
  @failingTest
  void test_logicalOrExpression_precedence_nullableType() {
    // TODO(paulberry,ahe): Fasta doesn't support NNBD syntax yet.
    super.test_logicalOrExpression_precedence_nullableType();
  }
}

/**
 * Tests of the fasta parser based on [ErrorParserTest].
 */
@reflectiveTest
class ErrorParserTest_Fasta extends FastaParserTestCase
    with ErrorParserTestMixin {
  @override
  @failingTest
  void test_abstractClassMember_field() {
    super.test_abstractClassMember_field();
  }

  @override
  @failingTest
  void test_abstractEnum() {
    super.test_abstractEnum();
  }

  @override
  @failingTest
  void test_abstractTopLevelFunction_function() {
    super.test_abstractTopLevelFunction_function();
  }

  @override
  @failingTest
  void test_abstractTopLevelFunction_getter() {
    super.test_abstractTopLevelFunction_getter();
  }

  @override
  @failingTest
  void test_abstractTopLevelFunction_setter() {
    super.test_abstractTopLevelFunction_setter();
  }

  @override
  @failingTest
  void test_abstractTopLevelVariable() {
    super.test_abstractTopLevelVariable();
  }

  @override
  @failingTest
  void test_abstractTypeDef() {
    super.test_abstractTypeDef();
  }

  @override
  @failingTest
  void test_annotationOnEnumConstant_first() {
    super.test_annotationOnEnumConstant_first();
  }

  @override
  @failingTest
  void test_annotationOnEnumConstant_middle() {
    super.test_annotationOnEnumConstant_middle();
  }

  @override
  @failingTest
  void test_breakOutsideOfLoop_breakInDoStatement() {
    super.test_breakOutsideOfLoop_breakInDoStatement();
  }

  @override
  @failingTest
  void test_breakOutsideOfLoop_breakInForStatement() {
    super.test_breakOutsideOfLoop_breakInForStatement();
  }

  @override
  @failingTest
  void test_breakOutsideOfLoop_breakInIfStatement() {
    super.test_breakOutsideOfLoop_breakInIfStatement();
  }

  @override
  @failingTest
  void test_breakOutsideOfLoop_breakInSwitchStatement() {
    super.test_breakOutsideOfLoop_breakInSwitchStatement();
  }

  @override
  @failingTest
  void test_breakOutsideOfLoop_breakInWhileStatement() {
    super.test_breakOutsideOfLoop_breakInWhileStatement();
  }

  @override
  @failingTest
  void test_breakOutsideOfLoop_functionExpression_inALoop() {
    super.test_breakOutsideOfLoop_functionExpression_inALoop();
  }

  @override
  @failingTest
  void test_classInClass_abstract() {
    super.test_classInClass_abstract();
  }

  @override
  @failingTest
  void test_classInClass_nonAbstract() {
    super.test_classInClass_nonAbstract();
  }

  @override
  @failingTest
  void test_classTypeAlias_abstractAfterEq() {
    super.test_classTypeAlias_abstractAfterEq();
  }

  @override
  @failingTest
  void test_colonInPlaceOfIn() {
    super.test_colonInPlaceOfIn();
  }

  @override
  @failingTest
  void test_constAndCovariant() {
    super.test_constAndCovariant();
  }

  @override
  @failingTest
  void test_constAndFinal() {
    super.test_constAndFinal();
  }

  @override
  @failingTest
  void test_constAndVar() {
    super.test_constAndVar();
  }

  @override
  @failingTest
  void test_constClass() {
    super.test_constClass();
  }

  @override
  @failingTest
  void test_constConstructorWithBody() {
    super.test_constConstructorWithBody();
  }

  @override
  @failingTest
  void test_constEnum() {
    super.test_constEnum();
  }

  @override
  @failingTest
  void test_constFactory() {
    super.test_constFactory();
  }

  @override
  @failingTest
  void test_constMethod() {
    super.test_constMethod();
  }

  @override
  @failingTest
  void test_constTypedef() {
    super.test_constTypedef();
  }

  @override
  @failingTest
  void test_constructorWithReturnType() {
    super.test_constructorWithReturnType();
  }

  @override
  @failingTest
  void test_constructorWithReturnType_var() {
    super.test_constructorWithReturnType_var();
  }

  @override
  @failingTest
  void test_continueOutsideOfLoop_continueInDoStatement() {
    super.test_continueOutsideOfLoop_continueInDoStatement();
  }

  @override
  @failingTest
  void test_continueOutsideOfLoop_continueInForStatement() {
    super.test_continueOutsideOfLoop_continueInForStatement();
  }

  @override
  @failingTest
  void test_continueOutsideOfLoop_continueInIfStatement() {
    super.test_continueOutsideOfLoop_continueInIfStatement();
  }

  @override
  @failingTest
  void test_continueOutsideOfLoop_continueInSwitchStatement() {
    super.test_continueOutsideOfLoop_continueInSwitchStatement();
  }

  @override
  @failingTest
  void test_continueOutsideOfLoop_continueInWhileStatement() {
    super.test_continueOutsideOfLoop_continueInWhileStatement();
  }

  @override
  @failingTest
  void test_continueOutsideOfLoop_functionExpression_inALoop() {
    super.test_continueOutsideOfLoop_functionExpression_inALoop();
  }

  @override
  @failingTest
  void test_continueWithoutLabelInCase_error() {
    super.test_continueWithoutLabelInCase_error();
  }

  @override
  @failingTest
  void test_continueWithoutLabelInCase_noError() {
    super.test_continueWithoutLabelInCase_noError();
  }

  @override
  @failingTest
  void test_continueWithoutLabelInCase_noError_switchInLoop() {
    super.test_continueWithoutLabelInCase_noError_switchInLoop();
  }

  @override
  @failingTest
  void test_covariantAfterVar() {
    super.test_covariantAfterVar();
  }

  @override
  @failingTest
  void test_covariantAndStatic() {
    super.test_covariantAndStatic();
  }

  @override
  @failingTest
  void test_covariantConstructor() {
    super.test_covariantConstructor();
  }

  @override
  @failingTest
  void test_covariantMember_getter_noReturnType() {
    super.test_covariantMember_getter_noReturnType();
  }

  @override
  @failingTest
  void test_covariantMember_getter_returnType() {
    super.test_covariantMember_getter_returnType();
  }

  @override
  @failingTest
  void test_covariantMember_method() {
    super.test_covariantMember_method();
  }

  @override
  @failingTest
  void test_covariantTopLevelDeclaration_class() {
    super.test_covariantTopLevelDeclaration_class();
  }

  @override
  @failingTest
  void test_covariantTopLevelDeclaration_enum() {
    super.test_covariantTopLevelDeclaration_enum();
  }

  @override
  @failingTest
  void test_covariantTopLevelDeclaration_typedef() {
    super.test_covariantTopLevelDeclaration_typedef();
  }

  @override
  @failingTest
  void test_defaultValueInFunctionType_named_colon() {
    super.test_defaultValueInFunctionType_named_colon();
  }

  @override
  @failingTest
  void test_defaultValueInFunctionType_named_equal() {
    super.test_defaultValueInFunctionType_named_equal();
  }

  @override
  @failingTest
  void test_defaultValueInFunctionType_positional() {
    super.test_defaultValueInFunctionType_positional();
  }

  @override
  @failingTest
  void test_directiveAfterDeclaration_classBeforeDirective() {
    super.test_directiveAfterDeclaration_classBeforeDirective();
  }

  @override
  @failingTest
  void test_directiveAfterDeclaration_classBetweenDirectives() {
    super.test_directiveAfterDeclaration_classBetweenDirectives();
  }

  @override
  @failingTest
  void test_duplicateLabelInSwitchStatement() {
    super.test_duplicateLabelInSwitchStatement();
  }

  @override
  @failingTest
  void test_duplicatedModifier_const() {
    super.test_duplicatedModifier_const();
  }

  @override
  @failingTest
  void test_duplicatedModifier_external() {
    super.test_duplicatedModifier_external();
  }

  @override
  @failingTest
  void test_duplicatedModifier_factory() {
    super.test_duplicatedModifier_factory();
  }

  @override
  @failingTest
  void test_duplicatedModifier_final() {
    super.test_duplicatedModifier_final();
  }

  @override
  @failingTest
  void test_duplicatedModifier_static() {
    super.test_duplicatedModifier_static();
  }

  @override
  @failingTest
  void test_duplicatedModifier_var() {
    super.test_duplicatedModifier_var();
  }

  @override
  @failingTest
  void test_emptyEnumBody() {
    super.test_emptyEnumBody();
  }

  @override
  @failingTest
  void test_enumInClass() {
    super.test_enumInClass();
  }

  @override
  @failingTest
  void test_equalityCannotBeEqualityOperand_eq_eq() {
    super.test_equalityCannotBeEqualityOperand_eq_eq();
  }

  @override
  @failingTest
  void test_equalityCannotBeEqualityOperand_eq_neq() {
    super.test_equalityCannotBeEqualityOperand_eq_neq();
  }

  @override
  @failingTest
  void test_equalityCannotBeEqualityOperand_neq_eq() {
    super.test_equalityCannotBeEqualityOperand_neq_eq();
  }

  @override
  @failingTest
  void test_expectedCaseOrDefault() {
    super.test_expectedCaseOrDefault();
  }

  @override
  @failingTest
  void test_expectedClassMember_inClass_afterType() {
    super.test_expectedClassMember_inClass_afterType();
  }

  @override
  @failingTest
  void test_expectedClassMember_inClass_beforeType() {
    super.test_expectedClassMember_inClass_beforeType();
  }

  @override
  @failingTest
  void test_expectedExecutable_inClass_afterVoid() {
    super.test_expectedExecutable_inClass_afterVoid();
  }

  @override
  @failingTest
  void test_expectedExecutable_topLevel_afterType() {
    super.test_expectedExecutable_topLevel_afterType();
  }

  @override
  @failingTest
  void test_expectedExecutable_topLevel_afterVoid() {
    super.test_expectedExecutable_topLevel_afterVoid();
  }

  @override
  @failingTest
  void test_expectedExecutable_topLevel_beforeType() {
    super.test_expectedExecutable_topLevel_beforeType();
  }

  @override
  @failingTest
  void test_expectedExecutable_topLevel_eof() {
    super.test_expectedExecutable_topLevel_eof();
  }

  @override
  @failingTest
  void test_expectedInterpolationIdentifier() {
    super.test_expectedInterpolationIdentifier();
  }

  @override
  @failingTest
  void test_expectedInterpolationIdentifier_emptyString() {
    super.test_expectedInterpolationIdentifier_emptyString();
  }

  @override
  @failingTest
  void test_expectedListOrMapLiteral() {
    super.test_expectedListOrMapLiteral();
  }

  @override
  @failingTest
  void test_expectedStringLiteral() {
    super.test_expectedStringLiteral();
  }

  @override
  @failingTest
  void test_expectedToken_commaMissingInArgumentList() {
    super.test_expectedToken_commaMissingInArgumentList();
  }

  @override
  @failingTest
  void test_expectedToken_parseStatement_afterVoid() {
    super.test_expectedToken_parseStatement_afterVoid();
  }

  @override
  @failingTest
  void test_expectedToken_semicolonMissingAfterExpression() {
    super.test_expectedToken_semicolonMissingAfterExpression();
  }

  @override
  @failingTest
  void test_expectedToken_semicolonMissingAfterImport() {
    super.test_expectedToken_semicolonMissingAfterImport();
  }

  @override
  @failingTest
  void test_expectedToken_whileMissingInDoStatement() {
    super.test_expectedToken_whileMissingInDoStatement();
  }

  @override
  @failingTest
  void test_expectedTypeName_as() {
    super.test_expectedTypeName_as();
  }

  @override
  @failingTest
  void test_expectedTypeName_as_void() {
    super.test_expectedTypeName_as_void();
  }

  @override
  @failingTest
  void test_expectedTypeName_is() {
    super.test_expectedTypeName_is();
  }

  @override
  @failingTest
  void test_expectedTypeName_is_void() {
    super.test_expectedTypeName_is_void();
  }

  @override
  @failingTest
  void test_exportDirectiveAfterPartDirective() {
    super.test_exportDirectiveAfterPartDirective();
  }

  @override
  @failingTest
  void test_externalAfterConst() {
    super.test_externalAfterConst();
  }

  @override
  @failingTest
  void test_externalAfterFactory() {
    super.test_externalAfterFactory();
  }

  @override
  @failingTest
  void test_externalAfterStatic() {
    super.test_externalAfterStatic();
  }

  @override
  @failingTest
  void test_externalClass() {
    super.test_externalClass();
  }

  @override
  @failingTest
  void test_externalConstructorWithBody_factory() {
    super.test_externalConstructorWithBody_factory();
  }

  @override
  @failingTest
  void test_externalConstructorWithBody_named() {
    super.test_externalConstructorWithBody_named();
  }

  @override
  @failingTest
  void test_externalEnum() {
    super.test_externalEnum();
  }

  @override
  @failingTest
  void test_externalField_const() {
    super.test_externalField_const();
  }

  @override
  @failingTest
  void test_externalField_final() {
    super.test_externalField_final();
  }

  @override
  @failingTest
  void test_externalField_static() {
    super.test_externalField_static();
  }

  @override
  @failingTest
  void test_externalField_typed() {
    super.test_externalField_typed();
  }

  @override
  @failingTest
  void test_externalField_untyped() {
    super.test_externalField_untyped();
  }

  @override
  @failingTest
  void test_externalGetterWithBody() {
    super.test_externalGetterWithBody();
  }

  @override
  @failingTest
  void test_externalMethodWithBody() {
    super.test_externalMethodWithBody();
  }

  @override
  @failingTest
  void test_externalOperatorWithBody() {
    super.test_externalOperatorWithBody();
  }

  @override
  @failingTest
  void test_externalSetterWithBody() {
    super.test_externalSetterWithBody();
  }

  @override
  @failingTest
  void test_externalTypedef() {
    super.test_externalTypedef();
  }

  @override
  @failingTest
  void test_extraCommaInParameterList() {
    super.test_extraCommaInParameterList();
  }

  @override
  @failingTest
  void test_extraCommaTrailingNamedParameterGroup() {
    super.test_extraCommaTrailingNamedParameterGroup();
  }

  @override
  @failingTest
  void test_extraCommaTrailingPositionalParameterGroup() {
    super.test_extraCommaTrailingPositionalParameterGroup();
  }

  @override
  @failingTest
  void test_extraTrailingCommaInParameterList() {
    super.test_extraTrailingCommaInParameterList();
  }

  @override
  @failingTest
  void test_factoryTopLevelDeclaration_class() {
    super.test_factoryTopLevelDeclaration_class();
  }

  @override
  @failingTest
  void test_factoryTopLevelDeclaration_enum() {
    super.test_factoryTopLevelDeclaration_enum();
  }

  @override
  @failingTest
  void test_factoryTopLevelDeclaration_typedef() {
    super.test_factoryTopLevelDeclaration_typedef();
  }

  @override
  @failingTest
  void test_factoryWithInitializers() {
    super.test_factoryWithInitializers();
  }

  @override
  @failingTest
  void test_factoryWithoutBody() {
    super.test_factoryWithoutBody();
  }

  @override
  @failingTest
  void test_fieldInitializerOutsideConstructor() {
    super.test_fieldInitializerOutsideConstructor();
  }

  @override
  @failingTest
  void test_finalAndCovariant() {
    super.test_finalAndCovariant();
  }

  @override
  @failingTest
  void test_finalAndVar() {
    super.test_finalAndVar();
  }

  @override
  @failingTest
  void test_finalClass() {
    super.test_finalClass();
  }

  @override
  @failingTest
  void test_finalConstructor() {
    super.test_finalConstructor();
  }

  @override
  @failingTest
  void test_finalEnum() {
    super.test_finalEnum();
  }

  @override
  @failingTest
  void test_finalMethod() {
    super.test_finalMethod();
  }

  @override
  @failingTest
  void test_finalTypedef() {
    super.test_finalTypedef();
  }

  @override
  @failingTest
  void test_functionTypedParameter_const() {
    super.test_functionTypedParameter_const();
  }

  @override
  @failingTest
  void test_functionTypedParameter_final() {
    super.test_functionTypedParameter_final();
  }

  @override
  @failingTest
  void test_functionTypedParameter_incomplete1() {
    super.test_functionTypedParameter_incomplete1();
  }

  @override
  @failingTest
  void test_functionTypedParameter_var() {
    super.test_functionTypedParameter_var();
  }

  @override
  @failingTest
  void test_genericFunctionType_extraLessThan() {
    super.test_genericFunctionType_extraLessThan();
  }

  @override
  @failingTest
  void test_getterInFunction_block_noReturnType() {
    super.test_getterInFunction_block_noReturnType();
  }

  @override
  @failingTest
  void test_getterInFunction_block_returnType() {
    super.test_getterInFunction_block_returnType();
  }

  @override
  @failingTest
  void test_getterInFunction_expression_noReturnType() {
    super.test_getterInFunction_expression_noReturnType();
  }

  @override
  @failingTest
  void test_getterInFunction_expression_returnType() {
    super.test_getterInFunction_expression_returnType();
  }

  @override
  @failingTest
  void test_getterWithParameters() {
    super.test_getterWithParameters();
  }

  @override
  @failingTest
  void test_illegalAssignmentToNonAssignable_postfix_minusMinus_literal() {
    super.test_illegalAssignmentToNonAssignable_postfix_minusMinus_literal();
  }

  @override
  @failingTest
  void test_illegalAssignmentToNonAssignable_postfix_plusPlus_literal() {
    super.test_illegalAssignmentToNonAssignable_postfix_plusPlus_literal();
  }

  @override
  @failingTest
  void test_illegalAssignmentToNonAssignable_postfix_plusPlus_parenthesized() {
    super
        .test_illegalAssignmentToNonAssignable_postfix_plusPlus_parenthesized();
  }

  @override
  @failingTest
  void test_illegalAssignmentToNonAssignable_primarySelectorPostfix() {
    super.test_illegalAssignmentToNonAssignable_primarySelectorPostfix();
  }

  @override
  @failingTest
  void test_illegalAssignmentToNonAssignable_superAssigned() {
    super.test_illegalAssignmentToNonAssignable_superAssigned();
  }

  @override
  @failingTest
  void test_illegalAssignmentToNonAssignable_superAssigned_failing() {
    super.test_illegalAssignmentToNonAssignable_superAssigned_failing();
  }

  @override
  @failingTest
  void test_implementsBeforeExtends() {
    super.test_implementsBeforeExtends();
  }

  @override
  @failingTest
  void test_implementsBeforeWith() {
    super.test_implementsBeforeWith();
  }

  @override
  @failingTest
  void test_importDirectiveAfterPartDirective() {
    super.test_importDirectiveAfterPartDirective();
  }

  @override
  @failingTest
  void test_initializedVariableInForEach() {
    super.test_initializedVariableInForEach();
  }

  @override
  @failingTest
  void test_invalidAwaitInFor() {
    super.test_invalidAwaitInFor();
  }

  @override
  @failingTest
  void test_invalidCodePoint() {
    super.test_invalidCodePoint();
  }

  @override
  @failingTest
  void test_invalidCommentReference__new_nonIdentifier() {
    super.test_invalidCommentReference__new_nonIdentifier();
  }

  @override
  @failingTest
  void test_invalidCommentReference__new_tooMuch() {
    super.test_invalidCommentReference__new_tooMuch();
  }

  @override
  @failingTest
  void test_invalidCommentReference__nonNew_nonIdentifier() {
    super.test_invalidCommentReference__nonNew_nonIdentifier();
  }

  @override
  @failingTest
  void test_invalidCommentReference__nonNew_tooMuch() {
    super.test_invalidCommentReference__nonNew_tooMuch();
  }

  @override
  @failingTest
  void test_invalidConstructorName_with() {
    super.test_invalidConstructorName_with();
  }

  @override
  @failingTest
  void test_invalidHexEscape_invalidDigit() {
    super.test_invalidHexEscape_invalidDigit();
  }

  @override
  @failingTest
  void test_invalidHexEscape_tooFewDigits() {
    super.test_invalidHexEscape_tooFewDigits();
  }

  @override
  @failingTest
  void test_invalidInterpolationIdentifier_startWithDigit() {
    super.test_invalidInterpolationIdentifier_startWithDigit();
  }

  @override
  @failingTest
  void test_invalidLiteralInConfiguration() {
    super.test_invalidLiteralInConfiguration();
  }

  @override
  @failingTest
  void test_invalidOperator() {
    super.test_invalidOperator();
  }

  @override
  @failingTest
  void test_invalidOperatorAfterSuper_assignableExpression() {
    super.test_invalidOperatorAfterSuper_assignableExpression();
  }

  @override
  @failingTest
  void test_invalidOperatorAfterSuper_primaryExpression() {
    super.test_invalidOperatorAfterSuper_primaryExpression();
  }

  @override
  @failingTest
  void test_invalidOperatorForSuper() {
    super.test_invalidOperatorForSuper();
  }

  @override
  @failingTest
  void test_invalidStarAfterAsync() {
    super.test_invalidStarAfterAsync();
  }

  @override
  @failingTest
  void test_invalidSync() {
    super.test_invalidSync();
  }

  @override
  @failingTest
  void test_invalidUnicodeEscape_incomplete_noDigits() {
    super.test_invalidUnicodeEscape_incomplete_noDigits();
  }

  @override
  @failingTest
  void test_invalidUnicodeEscape_incomplete_someDigits() {
    super.test_invalidUnicodeEscape_incomplete_someDigits();
  }

  @override
  @failingTest
  void test_invalidUnicodeEscape_invalidDigit() {
    super.test_invalidUnicodeEscape_invalidDigit();
  }

  @override
  @failingTest
  void test_invalidUnicodeEscape_tooFewDigits_fixed() {
    super.test_invalidUnicodeEscape_tooFewDigits_fixed();
  }

  @override
  @failingTest
  void test_invalidUnicodeEscape_tooFewDigits_variable() {
    super.test_invalidUnicodeEscape_tooFewDigits_variable();
  }

  @override
  @failingTest
  void test_invalidUnicodeEscape_tooManyDigits_variable() {
    super.test_invalidUnicodeEscape_tooManyDigits_variable();
  }

  @override
  @failingTest
  void test_libraryDirectiveNotFirst() {
    super.test_libraryDirectiveNotFirst();
  }

  @override
  @failingTest
  void test_libraryDirectiveNotFirst_afterPart() {
    super.test_libraryDirectiveNotFirst_afterPart();
  }

  @override
  @failingTest
  void test_localFunctionDeclarationModifier_abstract() {
    super.test_localFunctionDeclarationModifier_abstract();
  }

  @override
  @failingTest
  void test_localFunctionDeclarationModifier_external() {
    super.test_localFunctionDeclarationModifier_external();
  }

  @override
  @failingTest
  void test_localFunctionDeclarationModifier_factory() {
    super.test_localFunctionDeclarationModifier_factory();
  }

  @override
  @failingTest
  void test_localFunctionDeclarationModifier_static() {
    super.test_localFunctionDeclarationModifier_static();
  }

  @override
  @failingTest
  void test_method_invalidTypeParameterComments() {
    super.test_method_invalidTypeParameterComments();
  }

  @override
  @failingTest
  void test_method_invalidTypeParameterExtends() {
    super.test_method_invalidTypeParameterExtends();
  }

  @override
  @failingTest
  void test_method_invalidTypeParameterExtendsComment() {
    super.test_method_invalidTypeParameterExtendsComment();
  }

  @override
  @failingTest
  void test_method_invalidTypeParameters() {
    super.test_method_invalidTypeParameters();
  }

  @override
  @failingTest
  void test_missingAssignableSelector_identifiersAssigned() {
    super.test_missingAssignableSelector_identifiersAssigned();
  }

  @override
  @failingTest
  void test_missingAssignableSelector_prefix_minusMinus_literal() {
    super.test_missingAssignableSelector_prefix_minusMinus_literal();
  }

  @override
  @failingTest
  void test_missingAssignableSelector_prefix_plusPlus_literal() {
    super.test_missingAssignableSelector_prefix_plusPlus_literal();
  }

  @override
  @failingTest
  void test_missingAssignableSelector_superPrimaryExpression() {
    super.test_missingAssignableSelector_superPrimaryExpression();
  }

  @override
  @failingTest
  void test_missingAssignableSelector_superPropertyAccessAssigned() {
    super.test_missingAssignableSelector_superPropertyAccessAssigned();
  }

  @override
  @failingTest
  void test_missingCatchOrFinally() {
    super.test_missingCatchOrFinally();
  }

  @override
  @failingTest
  void test_missingClassBody() {
    super.test_missingClassBody();
  }

  @override
  @failingTest
  void test_missingClosingParenthesis() {
    super.test_missingClosingParenthesis();
  }

  @override
  @failingTest
  void test_missingConstFinalVarOrType_static() {
    super.test_missingConstFinalVarOrType_static();
  }

  @override
  @failingTest
  void test_missingConstFinalVarOrType_topLevel() {
    super.test_missingConstFinalVarOrType_topLevel();
  }

  @override
  @failingTest
  void test_missingEnumBody() {
    super.test_missingEnumBody();
  }

  @override
  @failingTest
  void test_missingExpressionInThrow_withCascade() {
    super.test_missingExpressionInThrow_withCascade();
  }

  @override
  @failingTest
  void test_missingExpressionInThrow_withoutCascade() {
    super.test_missingExpressionInThrow_withoutCascade();
  }

  @override
  @failingTest
  void test_missingFunctionBody_emptyNotAllowed() {
    super.test_missingFunctionBody_emptyNotAllowed();
  }

  @override
  @failingTest
  void test_missingFunctionBody_invalid() {
    super.test_missingFunctionBody_invalid();
  }

  @override
  @failingTest
  void test_missingFunctionParameters_local_nonVoid_block() {
    super.test_missingFunctionParameters_local_nonVoid_block();
  }

  @override
  @failingTest
  void test_missingFunctionParameters_local_nonVoid_expression() {
    super.test_missingFunctionParameters_local_nonVoid_expression();
  }

  @override
  @failingTest
  void test_missingFunctionParameters_local_void_block() {
    super.test_missingFunctionParameters_local_void_block();
  }

  @override
  @failingTest
  void test_missingFunctionParameters_local_void_expression() {
    super.test_missingFunctionParameters_local_void_expression();
  }

  @override
  @failingTest
  void test_missingFunctionParameters_topLevel_nonVoid_block() {
    super.test_missingFunctionParameters_topLevel_nonVoid_block();
  }

  @override
  @failingTest
  void test_missingFunctionParameters_topLevel_nonVoid_expression() {
    super.test_missingFunctionParameters_topLevel_nonVoid_expression();
  }

  @override
  @failingTest
  void test_missingFunctionParameters_topLevel_void_block() {
    super.test_missingFunctionParameters_topLevel_void_block();
  }

  @override
  @failingTest
  void test_missingFunctionParameters_topLevel_void_expression() {
    super.test_missingFunctionParameters_topLevel_void_expression();
  }

  @override
  @failingTest
  void test_missingIdentifierForParameterGroup() {
    super.test_missingIdentifierForParameterGroup();
  }

  @override
  @failingTest
  void test_missingIdentifier_afterOperator() {
    super.test_missingIdentifier_afterOperator();
  }

  @override
  @failingTest
  void test_missingIdentifier_beforeClosingCurly() {
    super.test_missingIdentifier_beforeClosingCurly();
  }

  @override
  @failingTest
  void test_missingIdentifier_inEnum() {
    super.test_missingIdentifier_inEnum();
  }

  @override
  @failingTest
  void test_missingIdentifier_inSymbol_afterPeriod() {
    super.test_missingIdentifier_inSymbol_afterPeriod();
  }

  @override
  @failingTest
  void test_missingIdentifier_inSymbol_first() {
    super.test_missingIdentifier_inSymbol_first();
  }

  @override
  @failingTest
  void test_missingIdentifier_number() {
    super.test_missingIdentifier_number();
  }

  @override
  @failingTest
  void test_missingKeywordOperator() {
    super.test_missingKeywordOperator();
  }

  @override
  @failingTest
  void test_missingKeywordOperator_parseClassMember() {
    super.test_missingKeywordOperator_parseClassMember();
  }

  @override
  @failingTest
  void test_missingKeywordOperator_parseClassMember_afterTypeName() {
    super.test_missingKeywordOperator_parseClassMember_afterTypeName();
  }

  @override
  @failingTest
  void test_missingKeywordOperator_parseClassMember_afterVoid() {
    super.test_missingKeywordOperator_parseClassMember_afterVoid();
  }

  @override
  @failingTest
  void test_missingMethodParameters_void_block() {
    super.test_missingMethodParameters_void_block();
  }

  @override
  @failingTest
  void test_missingMethodParameters_void_expression() {
    super.test_missingMethodParameters_void_expression();
  }

  @override
  @failingTest
  void test_missingNameForNamedParameter_colon() {
    super.test_missingNameForNamedParameter_colon();
  }

  @override
  @failingTest
  void test_missingNameForNamedParameter_equals() {
    super.test_missingNameForNamedParameter_equals();
  }

  @override
  @failingTest
  void test_missingNameForNamedParameter_noDefault() {
    super.test_missingNameForNamedParameter_noDefault();
  }

  @override
  @failingTest
  void test_missingNameInLibraryDirective() {
    super.test_missingNameInLibraryDirective();
  }

  @override
  @failingTest
  void test_missingNameInPartOfDirective() {
    super.test_missingNameInPartOfDirective();
  }

  @override
  @failingTest
  void test_missingPrefixInDeferredImport() {
    super.test_missingPrefixInDeferredImport();
  }

  @override
  @failingTest
  void test_missingStartAfterSync() {
    super.test_missingStartAfterSync();
  }

  @override
  @failingTest
  void test_missingStatement() {
    super.test_missingStatement();
  }

  @override
  @failingTest
  void test_missingStatement_afterVoid() {
    super.test_missingStatement_afterVoid();
  }

  @override
  @failingTest
  void test_missingTerminatorForParameterGroup_named() {
    super.test_missingTerminatorForParameterGroup_named();
  }

  @override
  @failingTest
  void test_missingTerminatorForParameterGroup_optional() {
    super.test_missingTerminatorForParameterGroup_optional();
  }

  @override
  @failingTest
  void test_missingTypedefParameters_nonVoid() {
    super.test_missingTypedefParameters_nonVoid();
  }

  @override
  @failingTest
  void test_missingTypedefParameters_typeParameters() {
    super.test_missingTypedefParameters_typeParameters();
  }

  @override
  @failingTest
  void test_missingTypedefParameters_void() {
    super.test_missingTypedefParameters_void();
  }

  @override
  @failingTest
  void test_missingVariableInForEach() {
    super.test_missingVariableInForEach();
  }

  @override
  @failingTest
  void test_mixedParameterGroups_namedPositional() {
    super.test_mixedParameterGroups_namedPositional();
  }

  @override
  @failingTest
  void test_mixedParameterGroups_positionalNamed() {
    super.test_mixedParameterGroups_positionalNamed();
  }

  @override
  @failingTest
  void test_mixin_application_lacks_with_clause() {
    super.test_mixin_application_lacks_with_clause();
  }

  @override
  @failingTest
  void test_multipleExtendsClauses() {
    super.test_multipleExtendsClauses();
  }

  @override
  @failingTest
  void test_multipleImplementsClauses() {
    super.test_multipleImplementsClauses();
  }

  @override
  @failingTest
  void test_multipleLibraryDirectives() {
    super.test_multipleLibraryDirectives();
  }

  @override
  @failingTest
  void test_multipleNamedParameterGroups() {
    super.test_multipleNamedParameterGroups();
  }

  @override
  @failingTest
  void test_multiplePartOfDirectives() {
    super.test_multiplePartOfDirectives();
  }

  @override
  @failingTest
  void test_multiplePositionalParameterGroups() {
    super.test_multiplePositionalParameterGroups();
  }

  @override
  @failingTest
  void test_multipleVariablesInForEach() {
    super.test_multipleVariablesInForEach();
  }

  @override
  @failingTest
  void test_multipleWithClauses() {
    super.test_multipleWithClauses();
  }

  @override
  @failingTest
  void test_namedFunctionExpression() {
    super.test_namedFunctionExpression();
  }

  @override
  @failingTest
  void test_namedParameterOutsideGroup() {
    super.test_namedParameterOutsideGroup();
  }

  @override
  @failingTest
  void test_nonConstructorFactory_field() {
    super.test_nonConstructorFactory_field();
  }

  @override
  @failingTest
  void test_nonConstructorFactory_method() {
    super.test_nonConstructorFactory_method();
  }

  @override
  @failingTest
  void test_nonIdentifierLibraryName_library() {
    super.test_nonIdentifierLibraryName_library();
  }

  @override
  @failingTest
  void test_nonIdentifierLibraryName_partOf() {
    super.test_nonIdentifierLibraryName_partOf();
  }

  @override
  @failingTest
  void test_nonPartOfDirectiveInPart_after() {
    super.test_nonPartOfDirectiveInPart_after();
  }

  @override
  @failingTest
  void test_nonPartOfDirectiveInPart_before() {
    super.test_nonPartOfDirectiveInPart_before();
  }

  @override
  @failingTest
  void test_nonUserDefinableOperator() {
    super.test_nonUserDefinableOperator();
  }

  @override
  @failingTest
  void test_nullableTypeInExtends() {
    super.test_nullableTypeInExtends();
  }

  @override
  @failingTest
  void test_nullableTypeInImplements() {
    super.test_nullableTypeInImplements();
  }

  @override
  @failingTest
  void test_nullableTypeInWith() {
    super.test_nullableTypeInWith();
  }

  @override
  @failingTest
  void test_nullableTypeParameter() {
    super.test_nullableTypeParameter();
  }

  @override
  @failingTest
  void test_optionalAfterNormalParameters_named() {
    super.test_optionalAfterNormalParameters_named();
  }

  @override
  @failingTest
  void test_optionalAfterNormalParameters_positional() {
    super.test_optionalAfterNormalParameters_positional();
  }

  @override
  @failingTest
  void test_parseCascadeSection_missingIdentifier() {
    super.test_parseCascadeSection_missingIdentifier();
  }

  @override
  @failingTest
  void test_parseCascadeSection_missingIdentifier_typeArguments() {
    super.test_parseCascadeSection_missingIdentifier_typeArguments();
  }

  @override
  @failingTest
  void test_positionalAfterNamedArgument() {
    super.test_positionalAfterNamedArgument();
  }

  @override
  @failingTest
  void test_positionalParameterOutsideGroup() {
    super.test_positionalParameterOutsideGroup();
  }

  @override
  @failingTest
  void test_redirectingConstructorWithBody_named() {
    super.test_redirectingConstructorWithBody_named();
  }

  @override
  @failingTest
  void test_redirectingConstructorWithBody_unnamed() {
    super.test_redirectingConstructorWithBody_unnamed();
  }

  @override
  @failingTest
  void test_redirectionInNonFactoryConstructor() {
    super.test_redirectionInNonFactoryConstructor();
  }

  @override
  @failingTest
  void test_setterInFunction_block() {
    super.test_setterInFunction_block();
  }

  @override
  @failingTest
  void test_setterInFunction_expression() {
    super.test_setterInFunction_expression();
  }

  @override
  @failingTest
  void test_staticAfterConst() {
    super.test_staticAfterConst();
  }

  @override
  @failingTest
  void test_staticAfterFinal() {
    super.test_staticAfterFinal();
  }

  @override
  @failingTest
  void test_staticAfterVar() {
    super.test_staticAfterVar();
  }

  @override
  @failingTest
  void test_staticConstructor() {
    super.test_staticConstructor();
  }

  @override
  @failingTest
  void test_staticGetterWithoutBody() {
    super.test_staticGetterWithoutBody();
  }

  @override
  @failingTest
  void test_staticOperator_noReturnType() {
    super.test_staticOperator_noReturnType();
  }

  @override
  @failingTest
  void test_staticOperator_returnType() {
    super.test_staticOperator_returnType();
  }

  @override
  @failingTest
  void test_staticSetterWithoutBody() {
    super.test_staticSetterWithoutBody();
  }

  @override
  @failingTest
  void test_staticTopLevelDeclaration_class() {
    super.test_staticTopLevelDeclaration_class();
  }

  @override
  @failingTest
  void test_staticTopLevelDeclaration_enum() {
    super.test_staticTopLevelDeclaration_enum();
  }

  @override
  @failingTest
  void test_staticTopLevelDeclaration_function() {
    super.test_staticTopLevelDeclaration_function();
  }

  @override
  @failingTest
  void test_staticTopLevelDeclaration_typedef() {
    super.test_staticTopLevelDeclaration_typedef();
  }

  @override
  @failingTest
  void test_staticTopLevelDeclaration_variable() {
    super.test_staticTopLevelDeclaration_variable();
  }

  @override
  @failingTest
  void test_string_unterminated_interpolation_block() {
    super.test_string_unterminated_interpolation_block();
  }

  @override
  @failingTest
  void test_switchHasCaseAfterDefaultCase() {
    super.test_switchHasCaseAfterDefaultCase();
  }

  @override
  @failingTest
  void test_switchHasCaseAfterDefaultCase_repeated() {
    super.test_switchHasCaseAfterDefaultCase_repeated();
  }

  @override
  @failingTest
  void test_switchHasMultipleDefaultCases() {
    super.test_switchHasMultipleDefaultCases();
  }

  @override
  @failingTest
  void test_switchHasMultipleDefaultCases_repeated() {
    super.test_switchHasMultipleDefaultCases_repeated();
  }

  @override
  @failingTest
  void test_topLevelOperator_withType() {
    super.test_topLevelOperator_withType();
  }

  @override
  @failingTest
  void test_topLevelOperator_withVoid() {
    super.test_topLevelOperator_withVoid();
  }

  @override
  @failingTest
  void test_topLevelOperator_withoutType() {
    super.test_topLevelOperator_withoutType();
  }

  @override
  @failingTest
  void test_topLevelVariable_withMetadata() {
    super.test_topLevelVariable_withMetadata();
  }

  @override
  @failingTest
  void test_typedefInClass_withReturnType() {
    super.test_typedefInClass_withReturnType();
  }

  @override
  @failingTest
  void test_typedefInClass_withoutReturnType() {
    super.test_typedefInClass_withoutReturnType();
  }

  @override
  @failingTest
  void test_typedef_incomplete() {
    super.test_typedef_incomplete();
  }

  @override
  @failingTest
  void test_typedef_namedFunction() {
    super.test_typedef_namedFunction();
  }

  @override
  @failingTest
  void test_unexpectedTerminatorForParameterGroup_named() {
    super.test_unexpectedTerminatorForParameterGroup_named();
  }

  @override
  @failingTest
  void test_unexpectedTerminatorForParameterGroup_optional() {
    super.test_unexpectedTerminatorForParameterGroup_optional();
  }

  @override
  @failingTest
  void test_unexpectedToken_endOfFieldDeclarationStatement() {
    super.test_unexpectedToken_endOfFieldDeclarationStatement();
  }

  @override
  @failingTest
  void test_unexpectedToken_invalidPostfixExpression() {
    super.test_unexpectedToken_invalidPostfixExpression();
  }

  @override
  @failingTest
  void test_unexpectedToken_returnInExpressionFunctionBody() {
    super.test_unexpectedToken_returnInExpressionFunctionBody();
  }

  @override
  @failingTest
  void test_unexpectedToken_semicolonBetweenClassMembers() {
    super.test_unexpectedToken_semicolonBetweenClassMembers();
  }

  @override
  @failingTest
  void test_unexpectedToken_semicolonBetweenCompilationUnitMembers() {
    super.test_unexpectedToken_semicolonBetweenCompilationUnitMembers();
  }

  @override
  @failingTest
  void test_unterminatedString_at_eof() {
    super.test_unterminatedString_at_eof();
  }

  @override
  @failingTest
  void test_unterminatedString_multiline_at_eof_3_quotes() {
    super.test_unterminatedString_multiline_at_eof_3_quotes();
  }

  @override
  @failingTest
  void test_unterminatedString_multiline_at_eof_4_quotes() {
    super.test_unterminatedString_multiline_at_eof_4_quotes();
  }

  @override
  @failingTest
  void test_unterminatedString_multiline_at_eof_5_quotes() {
    super.test_unterminatedString_multiline_at_eof_5_quotes();
  }

  @override
  @failingTest
  void test_useOfUnaryPlusOperator() {
    super.test_useOfUnaryPlusOperator();
  }

  @override
  @failingTest
  void test_varAndType_field() {
    super.test_varAndType_field();
  }

  @override
  @failingTest
  void test_varAndType_local() {
    super.test_varAndType_local();
  }

  @override
  @failingTest
  void test_varAndType_parameter() {
    super.test_varAndType_parameter();
  }

  @override
  @failingTest
  void test_varAndType_topLevelVariable() {
    super.test_varAndType_topLevelVariable();
  }

  @override
  @failingTest
  void test_varAsTypeName_as() {
    super.test_varAsTypeName_as();
  }

  @override
  @failingTest
  void test_varClass() {
    super.test_varClass();
  }

  @override
  @failingTest
  void test_varEnum() {
    super.test_varEnum();
  }

  @override
  @failingTest
  void test_varReturnType() {
    super.test_varReturnType();
  }

  @override
  @failingTest
  void test_varTypedef() {
    super.test_varTypedef();
  }

  @override
  @failingTest
  void test_voidParameter() {
    super.test_voidParameter();
  }

  @override
  @failingTest
  void test_voidVariable_parseClassMember_initializer() {
    super.test_voidVariable_parseClassMember_initializer();
  }

  @override
  @failingTest
  void test_voidVariable_parseClassMember_noInitializer() {
    super.test_voidVariable_parseClassMember_noInitializer();
  }

  @override
  @failingTest
  void test_voidVariable_parseCompilationUnitMember_initializer() {
    super.test_voidVariable_parseCompilationUnitMember_initializer();
  }

  @override
  @failingTest
  void test_voidVariable_parseCompilationUnitMember_noInitializer() {
    super.test_voidVariable_parseCompilationUnitMember_noInitializer();
  }

  @override
  @failingTest
  void test_voidVariable_parseCompilationUnit_initializer() {
    super.test_voidVariable_parseCompilationUnit_initializer();
  }

  @override
  @failingTest
  void test_voidVariable_parseCompilationUnit_noInitializer() {
    super.test_voidVariable_parseCompilationUnit_noInitializer();
  }

  @override
  @failingTest
  void test_voidVariable_statement_initializer() {
    super.test_voidVariable_statement_initializer();
  }

  @override
  @failingTest
  void test_voidVariable_statement_noInitializer() {
    super.test_voidVariable_statement_noInitializer();
  }

  @override
  @failingTest
  void test_withBeforeExtends() {
    super.test_withBeforeExtends();
  }

  @override
  @failingTest
  void test_withWithoutExtends() {
    super.test_withWithoutExtends();
  }

  @override
  @failingTest
  void test_wrongSeparatorForPositionalParameter() {
    super.test_wrongSeparatorForPositionalParameter();
  }

  @override
  @failingTest
  void test_wrongTerminatorForParameterGroup_named() {
    super.test_wrongTerminatorForParameterGroup_named();
  }

  @override
  @failingTest
  void test_wrongTerminatorForParameterGroup_optional() {
    super.test_wrongTerminatorForParameterGroup_optional();
  }
}

/**
 * Tests of the fasta parser based on [ExpressionParserTestMixin].
 */
@reflectiveTest
class ExpressionParserTest_Fasta extends FastaParserTestCase
    with ExpressionParserTestMixin {
  @override
  @failingTest
  void
      test_parseAssignableExpression_expression_args_dot_typeArgumentComments() {
    super
        .test_parseAssignableExpression_expression_args_dot_typeArgumentComments();
  }

  @override
  @failingTest
  void test_parseAssignableExpression_expression_args_dot_typeArguments() {
    super.test_parseAssignableExpression_expression_args_dot_typeArguments();
  }

  @override
  @failingTest
  void test_parseCascadeSection_ia_typeArgumentComments() {
    super.test_parseCascadeSection_ia_typeArgumentComments();
  }

  @override
  @failingTest
  void test_parseCascadeSection_ia_typeArguments() {
    super.test_parseCascadeSection_ia_typeArguments();
  }

  @override
  @failingTest
  void test_parseCascadeSection_paa_typeArgumentComments() {
    super.test_parseCascadeSection_paa_typeArgumentComments();
  }

  @override
  @failingTest
  void test_parseCascadeSection_paa_typeArguments() {
    super.test_parseCascadeSection_paa_typeArguments();
  }

  @override
  @failingTest
  void test_parseCascadeSection_paapaa_typeArgumentComments() {
    super.test_parseCascadeSection_paapaa_typeArgumentComments();
  }

  @override
  @failingTest
  void test_parseCascadeSection_paapaa_typeArguments() {
    super.test_parseCascadeSection_paapaa_typeArguments();
  }

  @override
  @failingTest
  void test_parseExpression_assign_compound() {
    super.test_parseExpression_assign_compound();
  }

  @override
  @failingTest
  void test_parseInstanceCreationExpression_type_named_typeArgumentComments() {
    super
        .test_parseInstanceCreationExpression_type_named_typeArgumentComments();
  }

  @override
  @failingTest
  void test_parseInstanceCreationExpression_type_typeArguments_nullable() {
    super.test_parseInstanceCreationExpression_type_typeArguments_nullable();
  }

  @override
  void test_parseListLiteral_empty_oneToken_withComment() {
    super.test_parseListLiteral_empty_oneToken_withComment();
  }

  @override
  @failingTest
  void test_parsePrimaryExpression_super() {
    super.test_parsePrimaryExpression_super();
  }

  @override
  @failingTest
  void test_parseRelationalExpression_as_nullable() {
    super.test_parseRelationalExpression_as_nullable();
  }

  @override
  @failingTest
  void test_parseRelationalExpression_is_nullable() {
    super.test_parseRelationalExpression_is_nullable();
  }

  @override
  @failingTest
  void test_parseUnaryExpression_decrement_super() {
    super.test_parseUnaryExpression_decrement_super();
  }

  @override
  @failingTest
  void test_parseUnaryExpression_decrement_super_withComment() {
    super.test_parseUnaryExpression_decrement_super_withComment();
  }
}

/**
 * Implementation of [AbstractParserTestCase] specialized for testing the
 * Fasta parser.
 */
class FastaParserTestCase extends Object
    with ParserTestHelpers
    implements AbstractParserTestCase {
  ParserProxy _parserProxy;
  analyzer.Token _fastaTokens;

  @override
  bool allowNativeClause = false;

  @override
  GatheringErrorListener get listener => _parserProxy._errorListener;

  /**
   * Whether generic method comments should be enabled for the test.
   */
  bool enableGenericMethodComments = false;

  @override
  set enableAssertInitializer(bool value) {
    if (value == true) {
      // TODO(paulberry,ahe): it looks like asserts in initializer lists are not
      // supported by Fasta.
      throw new UnimplementedError();
    }
  }

  @override
  set enableLazyAssignmentOperators(bool value) {
    // TODO: implement enableLazyAssignmentOperators
    if (value == true) {
      throw new UnimplementedError();
    }
  }

  @override
  set enableNnbd(bool value) {
    if (value == true) {
      // TODO(paulberry,ahe): non-null-by-default syntax is not supported by
      // Fasta.
      throw new UnimplementedError();
    }
  }

  @override
  set enableUriInPartOf(bool value) {
    if (value == false) {
      throw new UnimplementedError(
          'URIs in "part of" declarations cannot be disabled in Fasta.');
    }
  }

  @override
  analyzer.Parser get parser => _parserProxy;

  @override
  bool get usingFastaParser => true;

  @override
  void assertErrorsWithCodes(List<ErrorCode> expectedErrorCodes) {
    expectedErrorCodes = expectedErrorCodes.map((code) {
      if (code == ParserErrorCode.ABSTRACT_CLASS_MEMBER)
        return ParserErrorCode.EXTRANEOUS_MODIFIER;
      return code;
    }).toList();
    _parserProxy._errorListener.assertErrorsWithCodes(expectedErrorCodes);
  }

  @override
  void assertNoErrors() {
    _parserProxy._errorListener.assertNoErrors();
  }

  @override
  void createParser(String content) {
    var scanner = new StringScanner(content, includeComments: true);
    scanner.scanGenericMethodComments = enableGenericMethodComments;
    _fastaTokens = scanner.tokenize();
    _parserProxy = new ParserProxy(_fastaTokens,
        allowNativeClause: allowNativeClause,
        enableGenericMethodComments: enableGenericMethodComments);
  }

  @override
  void expectNotNullIfNoErrors(Object result) {
    if (!listener.hasErrors) {
      expect(result, isNotNull);
    }
  }

  @override
  Expression parseAdditiveExpression(String code) {
    return _parseExpression(code);
  }

  @override
  Expression parseAssignableExpression(String code, bool primaryAllowed) {
    return _parseExpression(code);
  }

  @override
  Expression parseAssignableSelector(String code, bool optional,
      {bool allowConditional: true}) {
    if (optional) {
      if (code.isEmpty) {
        return _parseExpression('foo');
      }
      return _parseExpression('(foo)$code');
    }
    return _parseExpression('foo$code');
  }

  @override
  AwaitExpression parseAwaitExpression(String code) {
    var function = _parseExpression('() async => $code') as FunctionExpression;
    return (function.body as ExpressionFunctionBody).expression;
  }

  @override
  Expression parseBitwiseAndExpression(String code) {
    return _parseExpression(code);
  }

  @override
  Expression parseBitwiseOrExpression(String code) {
    return _parseExpression(code);
  }

  @override
  Expression parseBitwiseXorExpression(String code) {
    return _parseExpression(code);
  }

  @override
  Expression parseCascadeSection(String code) {
    var cascadeExpression = _parseExpression('null$code') as CascadeExpression;
    return cascadeExpression.cascadeSections.first;
  }

  @override
  CompilationUnit parseCompilationUnit(String content,
      [List<ErrorCode> expectedErrorCodes = const <ErrorCode>[]]) {
    // Scan tokens
    var source = new StringSource(content, 'parser_test_StringSource.dart');
    GatheringErrorListener listener = new GatheringErrorListener();
    var scanner = new Scanner.fasta(source, listener);
    scanner.scanGenericMethodComments = enableGenericMethodComments;
    _fastaTokens = scanner.tokenize();

    // Run parser
    analyzer.Parser parser =
        new analyzer.Parser(source, listener, useFasta: true);
    CompilationUnit unit = parser.parseCompilationUnit(_fastaTokens);

    // Assert and return result
    listener.assertErrorsWithCodes(expectedErrorCodes);
    expect(unit, isNotNull);
    return unit;
  }

  @override
  ConditionalExpression parseConditionalExpression(String code) {
    return _parseExpression(code);
  }

  @override
  Expression parseConstExpression(String code) {
    return _parseExpression(code);
  }

  @override
  ConstructorInitializer parseConstructorInitializer(String code) {
    String source = 'class __Test { __Test() : $code; }';
    var unit = _runParser(source, null) as CompilationUnit;
    var clazz = unit.declarations[0] as ClassDeclaration;
    var constructor = clazz.members[0] as ConstructorDeclaration;
    return constructor.initializers.single;
  }

  @override
  CompilationUnit parseDirectives(String source,
      [List<ErrorCode> errorCodes = const <ErrorCode>[]]) {
    return _runParser(source, null, errorCodes);
  }

  @override
  BinaryExpression parseEqualityExpression(String code) {
    return _parseExpression(code);
  }

  @override
  Expression parseExpression(String source,
      [List<ErrorCode> errorCodes = const <ErrorCode>[]]) {
    return _runParser(source, (parser) => parser.parseExpression, errorCodes)
        as Expression;
  }

  @override
  List<Expression> parseExpressionList(String code) {
    return (_parseExpression('[$code]') as ListLiteral).elements.toList();
  }

  @override
  Expression parseExpressionWithoutCascade(String code) {
    return _parseExpression(code);
  }

  @override
  FormalParameter parseFormalParameter(String code, ParameterKind kind,
      {List<ErrorCode> errorCodes: const <ErrorCode>[]}) {
    String parametersCode;
    if (kind == ParameterKind.REQUIRED) {
      parametersCode = '($code)';
    } else if (kind == ParameterKind.POSITIONAL) {
      parametersCode = '([$code])';
    } else if (kind == ParameterKind.NAMED) {
      parametersCode = '({$code})';
    } else {
      fail('$kind');
    }
    FormalParameterList list = parseFormalParameterList(parametersCode,
        inFunctionType: false, errorCodes: errorCodes);
    return list.parameters.single;
  }

  @override
  FormalParameterList parseFormalParameterList(String code,
      {bool inFunctionType: false,
      List<ErrorCode> errorCodes: const <ErrorCode>[]}) {
    return _runParser(
        code,
        (parser) => (analyzer.Token token) {
              return parser.parseFormalParameters(
                  token,
                  inFunctionType
                      ? fasta.MemberKind.GeneralizedFunctionType
                      : fasta.MemberKind.NonStaticMethod);
            },
        errorCodes) as FormalParameterList;
  }

  @override
  CompilationUnitMember parseFullCompilationUnitMember() {
    return _parserProxy.parseTopLevelDeclaration(false);
  }

  @override
  Directive parseFullDirective() {
    return _parserProxy.parseTopLevelDeclaration(true);
  }

  @override
  FunctionExpression parseFunctionExpression(String code) {
    return _parseExpression(code);
  }

  @override
  InstanceCreationExpression parseInstanceCreationExpression(
      String code, analyzer.Token newToken) {
    return _parseExpression('$newToken $code');
  }

  @override
  ListLiteral parseListLiteral(
      analyzer.Token token, String typeArgumentsCode, String code) {
    String sc = '';
    if (token != null) {
      sc += token.lexeme + ' ';
    }
    if (typeArgumentsCode != null) {
      sc += typeArgumentsCode;
    }
    sc += code;
    return _parseExpression(sc);
  }

  @override
  TypedLiteral parseListOrMapLiteral(analyzer.Token modifier, String code) {
    String literalCode = modifier != null ? '$modifier $code' : code;
    return parsePrimaryExpression(literalCode) as TypedLiteral;
  }

  @override
  Expression parseLogicalAndExpression(String code) {
    return _parseExpression(code);
  }

  @override
  Expression parseLogicalOrExpression(String code) {
    return _parseExpression(code);
  }

  @override
  MapLiteral parseMapLiteral(
      analyzer.Token token, String typeArgumentsCode, String code) {
    String sc = '';
    if (token != null) {
      sc += token.lexeme + ' ';
    }
    if (typeArgumentsCode != null) {
      sc += typeArgumentsCode;
    }
    sc += code;
    return parsePrimaryExpression(sc) as MapLiteral;
  }

  @override
  MapLiteralEntry parseMapLiteralEntry(String code) {
    var mapLiteral = parseMapLiteral(null, null, '{ $code }');
    return mapLiteral.entries.single;
  }

  @override
  Expression parseMultiplicativeExpression(String code) {
    return _parseExpression(code);
  }

  @override
  InstanceCreationExpression parseNewExpression(String code) {
    return _parseExpression(code);
  }

  @override
  NormalFormalParameter parseNormalFormalParameter(String code,
      {bool inFunctionType: false,
      List<ErrorCode> errorCodes: const <ErrorCode>[]}) {
    FormalParameterList list = parseFormalParameterList('($code)',
        inFunctionType: inFunctionType, errorCodes: errorCodes);
    return list.parameters.single;
  }

  @override
  Expression parsePostfixExpression(String code) {
    return _parseExpression(code);
  }

  @override
  Identifier parsePrefixedIdentifier(String code) {
    return _parseExpression(code);
  }

  @override
  Expression parsePrimaryExpression(String code) {
    return _runParser(
        code,
        (parser) =>
            (token) => parser.parsePrimary(token, IdentifierContext.expression),
        const <ErrorCode>[]) as Expression;
  }

  @override
  Expression parseRelationalExpression(String code) {
    return _parseExpression(code);
  }

  @override
  RethrowExpression parseRethrowExpression(String code) {
    return _parseExpression(code);
  }

  @override
  BinaryExpression parseShiftExpression(String code) {
    return _parseExpression(code);
  }

  @override
  SimpleIdentifier parseSimpleIdentifier(String code) {
    return _parseExpression(code);
  }

  @override
  Statement parseStatement(String source,
      [bool enableLazyAssignmentOperators]) {
    return _runParser(source, (parser) => parser.parseStatement) as Statement;
  }

  @override
  Expression parseStringLiteral(String code) {
    return _parseExpression(code);
  }

  @override
  SymbolLiteral parseSymbolLiteral(String code) {
    return _parseExpression(code);
  }

  @override
  Expression parseThrowExpression(String code) {
    return _parseExpression(code);
  }

  @override
  Expression parseThrowExpressionWithoutCascade(String code) {
    return _parseExpression(code);
  }

  @override
  PrefixExpression parseUnaryExpression(String code) {
    return _parseExpression(code);
  }

  @override
  VariableDeclarationList parseVariableDeclarationList(String code) {
    var statement = parseStatement('$code;') as VariableDeclarationStatement;
    return statement.variables;
  }

  Expression _parseExpression(String code) {
    var statement = parseStatement('$code;') as ExpressionStatement;
    return statement.expression;
  }

  Object _runParser(
      String source, ParseFunction getParseFunction(fasta.Parser parser),
      [List<ErrorCode> errorCodes = const <ErrorCode>[]]) {
    if (errorCodes.isNotEmpty) {
      // TODO(paulberry): Check that the parser generates the proper errors.
      throw new UnimplementedError();
    }
    createParser(source);
    return _parserProxy._run(getParseFunction);
  }
}

/**
 * Tests of the fasta parser based on [FormalParameterParserTestMixin].
 */
@reflectiveTest
class FormalParameterParserTest_Fasta extends FastaParserTestCase
    with FormalParameterParserTestMixin {
  @override
  @failingTest
  void test_parseFormalParameterList_prefixedType_partial() {
    // TODO(scheglov): Unimplemented: errors
    super.test_parseFormalParameterList_prefixedType_partial();
  }

  @override
  @failingTest
  void test_parseFormalParameterList_prefixedType_partial2() {
    // TODO(scheglov): Unimplemented: errors
    super.test_parseFormalParameterList_prefixedType_partial2();
  }

  @override
  @failingTest
  void test_parseNormalFormalParameter_function_noType_nullable() {
    // TODO(scheglov): Not implemented: Nnbd
    super.test_parseNormalFormalParameter_function_noType_nullable();
  }

  @override
  @failingTest
  void
      test_parseNormalFormalParameter_function_noType_typeParameters_nullable() {
    // TODO(scheglov): Not implemented: Nnbd
    super
        .test_parseNormalFormalParameter_function_noType_typeParameters_nullable();
  }

  @override
  @failingTest
  void test_parseNormalFormalParameter_function_type_nullable() {
    // TODO(scheglov): Not implemented: Nnbd
    super.test_parseNormalFormalParameter_function_type_nullable();
  }

  @override
  @failingTest
  void test_parseNormalFormalParameter_function_type_typeParameters_nullable() {
    // TODO(scheglov): Not implemented: Nnbd
    super
        .test_parseNormalFormalParameter_function_type_typeParameters_nullable();
  }

  @override
  @failingTest
  void test_parseNormalFormalParameter_function_void_nullable() {
    // TODO(scheglov): Not implemented: Nnbd
    super.test_parseNormalFormalParameter_function_void_nullable();
  }

  @override
  @failingTest
  void test_parseNormalFormalParameter_function_void_typeParameters_nullable() {
    // TODO(scheglov): Not implemented: Nnbd
    super
        .test_parseNormalFormalParameter_function_void_typeParameters_nullable();
  }

  @failingTest
  void test_parseNormalFormalParameter_field_const_noType2() {
    // TODO(danrubel): should not be generating an error
    super.test_parseNormalFormalParameter_field_const_noType();
    assertNoErrors();
  }

  @failingTest
  void test_parseNormalFormalParameter_field_const_type2() {
    // TODO(danrubel): should not be generating an error
    super.test_parseNormalFormalParameter_field_const_type();
    assertNoErrors();
  }

  @failingTest
  void test_parseNormalFormalParameter_simple_const_noType2() {
    // TODO(danrubel): should not be generating an error
    super.test_parseNormalFormalParameter_simple_const_noType();
    assertNoErrors();
  }

  @failingTest
  void test_parseNormalFormalParameter_simple_const_type2() {
    // TODO(danrubel): should not be generating an error
    super.test_parseNormalFormalParameter_simple_const_type();
    assertNoErrors();
  }
}

/**
 * Proxy implementation of [KernelLibraryBuilderProxy] used by Fasta parser
 * tests.
 */
class KernelLibraryBuilderProxy implements KernelLibraryBuilder {
  @override
  final uri = Uri.parse('file:///test.dart');

  @override
  Uri get fileUri => uri;

  @override
  void addCompileTimeError(Message message, int charOffset, Uri uri,
      {bool silent: false, bool wasHandled: false}) {
    fail('${message.message}');
  }

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/**
 * Proxy implementation of the analyzer parser, implemented in terms of the
 * Fasta parser.
 *
 * This allows many of the analyzer parser tests to be run on Fasta, even if
 * they call into the analyzer parser class directly.
 */
class ParserProxy implements analyzer.Parser {
  /**
   * The token to parse next.
   */
  analyzer.Token _currentFastaToken;

  /**
   * The fasta parser being wrapped.
   */
  final fasta.Parser _fastaParser;

  /**
   * The builder which creates the analyzer AST data structures expected by the
   * analyzer parser tests.
   */
  final AstBuilder _astBuilder;

  /**
   * The error listener to which scanner and parser errors will be reported.
   */
  final GatheringErrorListener _errorListener;

  final ForwardingTestListener _eventListener;

  /**
   * Creates a [ParserProxy] which is prepared to begin parsing at the given
   * Fasta token.
   */
  factory ParserProxy(analyzer.Token startingToken,
      {bool allowNativeClause: false,
      bool enableGenericMethodComments: false}) {
    var library = new KernelLibraryBuilderProxy();
    var member = new BuilderProxy();
    var scope = new ScopeProxy();
    TestSource source = new TestSource();
    var errorListener = new GatheringErrorListener();
    var errorReporter = new ErrorReporter(errorListener, source);
    var astBuilder =
        new AstBuilder(errorReporter, library, member, scope, true);
    astBuilder.allowNativeClause = allowNativeClause;
    astBuilder.parseGenericMethodComments = enableGenericMethodComments;
    var eventListener = new ForwardingTestListener(astBuilder);
    var fastaParser = new fasta.Parser(eventListener);
    astBuilder.parser = fastaParser;
    return new ParserProxy._(
        startingToken, fastaParser, astBuilder, errorListener, eventListener);
  }

  ParserProxy._(this._currentFastaToken, this._fastaParser, this._astBuilder,
      this._errorListener, this._eventListener);

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  ClassMember parseClassMember(String className) {
    _astBuilder.className = className;
    _eventListener.begin('CompilationUnit');
    var result = _run((parser) => parser.parseMember) as ClassMember;
    _eventListener.end('CompilationUnit');
    _astBuilder.className = null;
    return result;
  }

  @override
  CompilationUnit parseCompilationUnit2() {
    var result = _run(null) as CompilationUnit;
    _eventListener.expectEmpty();
    return result;
  }

  AnnotatedNode parseTopLevelDeclaration(bool isDirective) {
    _eventListener.begin('CompilationUnit');
    _currentFastaToken =
        _fastaParser.parseTopLevelDeclaration(_currentFastaToken);
    expect(_currentFastaToken.isEof, isTrue);
    expect(_astBuilder.stack, hasLength(0));
    expect(_astBuilder.scriptTag, isNull);
    expect(_astBuilder.directives, hasLength(isDirective ? 1 : 0));
    expect(_astBuilder.declarations, hasLength(isDirective ? 0 : 1));
    _eventListener.end('CompilationUnit');
    return (isDirective ? _astBuilder.directives : _astBuilder.declarations)
        .first;
  }

  /**
   * Runs a single parser function, and returns the result as an analyzer AST.
   */
  Object _run(ParseFunction getParseFunction(fasta.Parser parser)) {
    ParseFunction parseFunction;
    if (getParseFunction != null) {
      parseFunction = getParseFunction(_fastaParser);
      _fastaParser.firstToken = _currentFastaToken;
    } else {
      parseFunction = _fastaParser.parseUnit;
      // firstToken should be set by beginCompilationUnit event.
    }
    _currentFastaToken = parseFunction(_currentFastaToken);
    expect(_currentFastaToken.isEof, isTrue);
    expect(_astBuilder.stack, hasLength(1));
    return _astBuilder.pop();
  }
}

/**
 * Proxy implementation of [Scope] used by Fasta parser tests.
 *
 * Any name lookup request is satisfied by creating an instance of
 * [BuilderProxy].
 */
class ScopeProxy implements Scope {
  final _locals = <String, Builder>{};

  @override
  Scope createNestedScope({bool isModifiable: true}) {
    return new Scope.nested(this, isModifiable: isModifiable);
  }

  @override
  declare(String name, Builder builder, int charOffset, Uri fileUri) {
    _locals[name] = builder;
    return null;
  }

  @override
  Builder lookup(String name, int charOffset, Uri fileUri,
          {bool isInstanceScope: true}) =>
      _locals.putIfAbsent(name, () => new BuilderProxy());

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/**
 * Tests of the fasta parser based on [StatementParserTestMixin].
 */
@reflectiveTest
class StatementParserTest_Fasta extends FastaParserTestCase
    with StatementParserTestMixin {
  @override
  @failingTest
  void test_parseAssertStatement_trailingComma_message() {
    super.test_parseAssertStatement_trailingComma_message();
  }

  @override
  @failingTest
  void test_parseAssertStatement_trailingComma_noMessage() {
    super.test_parseAssertStatement_trailingComma_noMessage();
  }

  @override
  @failingTest
  void test_parseBreakStatement_noLabel() {
    super.test_parseBreakStatement_noLabel();
  }

  @override
  @failingTest
  void test_parseContinueStatement_label() {
    super.test_parseContinueStatement_label();
  }

  @override
  @failingTest
  void test_parseContinueStatement_noLabel() {
    super.test_parseContinueStatement_noLabel();
  }

  @override
  @failingTest
  void test_parseStatement_emptyTypeArgumentList() {
    super.test_parseStatement_emptyTypeArgumentList();
  }

  @override
  @failingTest
  void test_parseTryStatement_catch_finally() {
    super.test_parseTryStatement_catch_finally();
  }

  @override
  @failingTest
  void test_parseTryStatement_on_catch() {
    super.test_parseTryStatement_on_catch();
  }

  @override
  @failingTest
  void test_parseTryStatement_on_catch_finally() {
    super.test_parseTryStatement_on_catch_finally();
  }
}

/**
 * Tests of the fasta parser based on [TopLevelParserTestMixin].
 */
@reflectiveTest
class TopLevelParserTest_Fasta extends FastaParserTestCase
    with TopLevelParserTestMixin {
  void test_parseClassDeclaration_native_missing_literal() {
    createParser('class A native {}');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    if (allowNativeClause) {
      assertNoErrors();
    } else {
      assertErrorsWithCodes([
        ParserErrorCode.NATIVE_CLAUSE_SHOULD_BE_ANNOTATION,
      ]);
    }
    expect(member, new isInstanceOf<ClassDeclaration>());
    ClassDeclaration declaration = member;
    expect(declaration.nativeClause, isNotNull);
    expect(declaration.nativeClause.nativeKeyword, isNotNull);
    expect(declaration.nativeClause.name, isNull);
    expect(declaration.endToken.type, TokenType.CLOSE_CURLY_BRACKET);
  }

  void test_parseClassDeclaration_native_allowed() {
    allowNativeClause = true;
    test_parseClassDeclaration_native();
  }

  void test_parseClassDeclaration_native_missing_literal_allowed() {
    allowNativeClause = true;
    test_parseClassDeclaration_native_missing_literal();
  }

  void test_parseClassDeclaration_native_missing_literal_not_allowed() {
    allowNativeClause = false;
    test_parseClassDeclaration_native_missing_literal();
  }

  void test_parseClassDeclaration_native_not_allowed() {
    allowNativeClause = false;
    test_parseClassDeclaration_native();
  }

  @override
  @failingTest
  void test_parseCompilationUnit_builtIn_asFunctionName() {
    // TODO(paulberry,ahe): Fasta's parser is confused when one of the built-in
    // identifiers `export`, `import`, `library`, `part`, or `typedef` appears
    // as the name of a top level function with an implicit return type.
    super.test_parseCompilationUnit_builtIn_asFunctionName();
  }

  @override
  @failingTest
  void test_parseCompilationUnit_exportAsPrefix() {
    // TODO(paulberry): As of commit 5de9108 this syntax is invalid.
    super.test_parseCompilationUnit_exportAsPrefix();
  }

  @override
  @failingTest
  void test_parseCompilationUnit_exportAsPrefix_parameterized() {
    // TODO(paulberry): As of commit 5de9108 this syntax is invalid.
    super.test_parseCompilationUnit_exportAsPrefix_parameterized();
  }

  @override
  @failingTest
  void test_parseDirectives_mixed() {
    // TODO(paulberry,ahe): This test verifies the analyzer parser's ability to
    // stop parsing as soon as the first non-directive is encountered; this is
    // useful for quickly traversing an import graph.  Consider adding a similar
    // ability to Fasta's parser.
    super.test_parseDirectives_mixed();
  }

  @failingTest
  void test_parseCompilationUnit_operatorAsPrefix_parameterized2() {
    // TODO(danrubel): should not be generating an error
    super.test_parseCompilationUnit_operatorAsPrefix_parameterized();
    assertNoErrors();
  }

  @failingTest
  void test_parseCompilationUnit_typedefAsPrefix2() {
    // TODO(danrubel): should not be generating an error
    super.test_parseCompilationUnit_typedefAsPrefix();
    assertNoErrors();
  }

  @failingTest
  void test_parseCompilationUnitMember_abstractAsPrefix2() {
    // TODO(danrubel): should not be generating an error
    super.test_parseCompilationUnitMember_abstractAsPrefix();
    assertNoErrors();
  }
}
