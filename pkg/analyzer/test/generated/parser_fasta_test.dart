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
import 'package:analyzer/src/generated/parser.dart' show CommentAndMetadata;
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/string_source.dart';
import 'package:front_end/src/fasta/fasta_codes.dart' show Message;
import 'package:front_end/src/fasta/kernel/kernel_builder.dart';
import 'package:front_end/src/fasta/kernel/kernel_library_builder.dart';
import 'package:front_end/src/fasta/parser.dart' show IdentifierContext;
import 'package:front_end/src/fasta/parser.dart' as fasta;
import 'package:front_end/src/fasta/scanner/string_scanner.dart';
import 'package:front_end/src/fasta/scanner/token.dart' as fasta;
import 'package:front_end/src/fasta/source/stack_listener.dart';
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
    defineReflectiveTests(RecoveryParserTest_Fasta);
    defineReflectiveTests(SimpleParserTest_Fasta);
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
    // TODO(brianwilkerson) Does not inject generic type arguments following a
    // function-valued expression, returning "a<E>(b)(c).d<G>(e).f".
    super
        .test_assignableExpression_arguments_normal_chain_typeArgumentComments();
  }

  @override
  @failingTest
  void test_assignableExpression_arguments_normal_chain_typeArguments() {
    // TODO(brianwilkerson) Does not parse generic type arguments following a
    // function-valued expression, returning the binary expression "a<E>(b) < F".
    super.test_assignableExpression_arguments_normal_chain_typeArguments();
  }

  @override
  @failingTest
  void test_equalityExpression_normal() {
    // TODO(brianwilkerson) Does not recover.
    super.test_equalityExpression_normal();
  }

  @override
  @failingTest
  void test_equalityExpression_super() {
    // TODO(brianwilkerson) Does not recover.
    super.test_equalityExpression_super();
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
  void test_annotationOnEnumConstant_first() {
    // TODO(brianwilkerson) Does not support annotations on enum constants.
    super.test_annotationOnEnumConstant_first();
  }

  @override
  @failingTest
  void test_annotationOnEnumConstant_middle() {
    // TODO(brianwilkerson) Does not support annotations on enum constants.
    super.test_annotationOnEnumConstant_middle();
  }

  @override
  @failingTest
  void test_breakOutsideOfLoop_breakInIfStatement() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.BREAK_OUTSIDE_OF_LOOP, found 0
    super.test_breakOutsideOfLoop_breakInIfStatement();
  }

  @override
  @failingTest
  void test_breakOutsideOfLoop_functionExpression_inALoop() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.BREAK_OUTSIDE_OF_LOOP, found 0
    super.test_breakOutsideOfLoop_functionExpression_inALoop();
  }

  @override
  @failingTest
  void test_classInClass_abstract() {
    // TODO(brianwilkerson) Does not recover.
    super.test_classInClass_abstract();
  }

  @override
  @failingTest
  void test_classInClass_nonAbstract() {
    // TODO(brianwilkerson) Does not recover.
    super.test_classInClass_nonAbstract();
  }

  @override
  @failingTest
  void test_classTypeAlias_abstractAfterEq() {
    // TODO(brianwilkerson) Does not recover.
    super.test_classTypeAlias_abstractAfterEq();
  }

  @override
  @failingTest
  void test_colonInPlaceOfIn() {
    // TODO(brianwilkerson) Does not recover.
    super.test_colonInPlaceOfIn();
  }

  @override
  @failingTest
  void test_constAndCovariant() {
    // TODO(brianwilkerson) Does not recover.
    super.test_constAndCovariant();
  }

  @override
  @failingTest
  void test_constAndFinal() {
    // TODO(brianwilkerson) Does not recover.
    super.test_constAndFinal();
  }

  @override
  @failingTest
  void test_constAndVar() {
    // TODO(brianwilkerson) Does not recover.
    super.test_constAndVar();
  }

  @override
  @failingTest
  void test_constClass() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.CONST_CLASS, found 0;
    // 0 errors of type ParserErrorCode.EXTRANEOUS_MODIFIER, found 2 (1, 7)
    super.test_constClass();
  }

  @override
  @failingTest
  void test_constConstructorWithBody() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.CONST_CONSTRUCTOR_WITH_BODY, found 0
    super.test_constConstructorWithBody();
  }

  @override
  @failingTest
  void test_constEnum() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.CONST_ENUM, found 0;
    // 0 errors of type ParserErrorCode.EXTRANEOUS_MODIFIER, found 2 (1, 7)
    super.test_constEnum();
  }

  @override
  @failingTest
  void test_constFactory() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.CONST_FACTORY, found 0
    super.test_constFactory();
  }

  @override
  @failingTest
  void test_constMethod() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.CONST_METHOD, found 0
    super.test_constMethod();
  }

  @override
  @failingTest
  void test_constructorWithReturnType() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.CONSTRUCTOR_WITH_RETURN_TYPE, found 0
    super.test_constructorWithReturnType();
  }

  @override
  @failingTest
  void test_constructorWithReturnType_var() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.CONSTRUCTOR_WITH_RETURN_TYPE, found 0;
    // 0 errors of type ParserErrorCode.EXTRANEOUS_MODIFIER, found 1 (0)
    super.test_constructorWithReturnType_var();
  }

  @override
  @failingTest
  void test_constTypedef() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.CONST_TYPEDEF, found 0;
    // 0 errors of type ParserErrorCode.EXTRANEOUS_MODIFIER, found 2 (1, 7)
    super.test_constTypedef();
  }

  @override
  @failingTest
  void test_continueOutsideOfLoop_continueInIfStatement() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.CONTINUE_OUTSIDE_OF_LOOP, found 0
    super.test_continueOutsideOfLoop_continueInIfStatement();
  }

  @override
  @failingTest
  void test_continueOutsideOfLoop_functionExpression_inALoop() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.CONTINUE_OUTSIDE_OF_LOOP, found 0
    super.test_continueOutsideOfLoop_functionExpression_inALoop();
  }

  @override
  @failingTest
  void test_continueWithoutLabelInCase_error() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.CONTINUE_WITHOUT_LABEL_IN_CASE, found 0
    super.test_continueWithoutLabelInCase_error();
  }

  @override
  @failingTest
  void test_covariantAfterVar() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.COVARIANT_AFTER_VAR, found 0;
    // 0 errors of type ParserErrorCode.EXTRANEOUS_MODIFIER, found 1 (4)
    super.test_covariantAfterVar();
  }

  @override
  @failingTest
  void test_covariantAndStatic() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.COVARIANT_AND_STATIC, found 0;
    // 0 errors of type ParserErrorCode.EXTRANEOUS_MODIFIER, found 1 (10)
    super.test_covariantAndStatic();
  }

  @override
  @failingTest
  void test_covariantConstructor() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.COVARIANT_CONSTRUCTOR, found 0;
    // 0 errors of type ParserErrorCode.EXTRANEOUS_MODIFIER, found 1 (10)
    super.test_covariantConstructor();
  }

  @override
  @failingTest
  void test_covariantMember_getter_noReturnType() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.COVARIANT_MEMBER, found 0;
    // 0 errors of type ParserErrorCode.EXTRANEOUS_MODIFIER, found 1 (7)
    super.test_covariantMember_getter_noReturnType();
  }

  @override
  @failingTest
  void test_covariantMember_getter_returnType() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.COVARIANT_MEMBER, found 0;
    // 0 errors of type ParserErrorCode.EXTRANEOUS_MODIFIER, found 1 (7)
    super.test_covariantMember_getter_returnType();
  }

  @override
  @failingTest
  void test_covariantMember_method() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.COVARIANT_MEMBER, found 0;
    // 0 errors of type ParserErrorCode.EXTRANEOUS_MODIFIER, found 1 (0)
    super.test_covariantMember_method();
  }

  @override
  @failingTest
  void test_covariantTopLevelDeclaration_class() {
    // TODO(brianwilkerson) Does not recover.
    //   type 'FunctionDeclarationImpl' is not a subtype of type 'ClassDeclaration' of 'member' where
    //     FunctionDeclarationImpl is from package:analyzer/src/dart/ast/ast.dart
    //     ClassDeclaration is from package:analyzer/dart/ast/ast.dart
    //
    //   test/generated/parser_test.dart 2418:31                            FastaParserTestCase&ErrorParserTestMixin.test_covariantTopLevelDeclaration_class
    super.test_covariantTopLevelDeclaration_class();
  }

  @override
  @failingTest
  void test_covariantTopLevelDeclaration_enum() {
    // TODO(brianwilkerson) Does not recover.
    //   type 'FunctionDeclarationImpl' is not a subtype of type 'EnumDeclaration' of 'member' where
    //   FunctionDeclarationImpl is from package:analyzer/src/dart/ast/ast.dart
    //   EnumDeclaration is from package:analyzer/dart/ast/ast.dart
    //
    //   test/generated/parser_test.dart 2426:30                            FastaParserTestCase&ErrorParserTestMixin.test_covariantTopLevelDeclaration_enum
    super.test_covariantTopLevelDeclaration_enum();
  }

  @override
  @failingTest
  void test_covariantTopLevelDeclaration_typedef() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.COVARIANT_TOP_LEVEL_DECLARATION, found 0;
    // 0 errors of type ParserErrorCode.EXTRANEOUS_MODIFIER, found 2 (1, 11)
    super.test_covariantTopLevelDeclaration_typedef();
  }

  @override
  @failingTest
  void test_defaultValueInFunctionType_named_colon() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPE, found 0
    super.test_defaultValueInFunctionType_named_colon();
  }

  @override
  @failingTest
  void test_defaultValueInFunctionType_named_equal() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPE, found 0
    super.test_defaultValueInFunctionType_named_equal();
  }

  @override
  @failingTest
  void test_defaultValueInFunctionType_positional() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPE, found 0
    super.test_defaultValueInFunctionType_positional();
  }

  @override
  @failingTest
  void test_directiveAfterDeclaration_classBeforeDirective() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.DIRECTIVE_AFTER_DECLARATION, found 0
    super.test_directiveAfterDeclaration_classBeforeDirective();
  }

  @override
  @failingTest
  void test_directiveAfterDeclaration_classBetweenDirectives() {
    super.test_directiveAfterDeclaration_classBetweenDirectives();
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
  void test_duplicateLabelInSwitchStatement() {
    super.test_duplicateLabelInSwitchStatement();
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
  void test_missingIdentifierForParameterGroup() {
    super.test_missingIdentifierForParameterGroup();
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
  void test_topLevelOperator_withoutType() {
    super.test_topLevelOperator_withoutType();
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
  void test_topLevelVariable_withMetadata() {
    super.test_topLevelVariable_withMetadata();
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
  void test_typedefInClass_withoutReturnType() {
    super.test_typedefInClass_withoutReturnType();
  }

  @override
  @failingTest
  void test_typedefInClass_withReturnType() {
    super.test_typedefInClass_withReturnType();
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
//  @failingTest
  void test_voidVariable_parseClassMember_initializer() {
    // TODO(brianwilkerson) Passes, but ought to fail.
    super.test_voidVariable_parseClassMember_initializer();
  }

  @override
//  @failingTest
  void test_voidVariable_parseClassMember_noInitializer() {
    // TODO(brianwilkerson) Passes, but ought to fail.
    super.test_voidVariable_parseClassMember_noInitializer();
  }

  @override
//  @failingTest
  void test_voidVariable_parseCompilationUnit_initializer() {
    // TODO(brianwilkerson) Passes, but ought to fail.
    super.test_voidVariable_parseCompilationUnit_initializer();
  }

  @override
//  @failingTest
  void test_voidVariable_parseCompilationUnit_noInitializer() {
    // TODO(brianwilkerson) Passes, but ought to fail.
    super.test_voidVariable_parseCompilationUnit_noInitializer();
  }

  @override
//  @failingTest
  void test_voidVariable_parseCompilationUnitMember_initializer() {
    // TODO(brianwilkerson) Passes, but ought to fail.
    super.test_voidVariable_parseCompilationUnitMember_initializer();
  }

  @override
//  @failingTest
  void test_voidVariable_parseCompilationUnitMember_noInitializer() {
    // TODO(brianwilkerson) Passes, but ought to fail.
    super.test_voidVariable_parseCompilationUnitMember_noInitializer();
  }

  @override
//  @failingTest
  void test_voidVariable_statement_initializer() {
    // TODO(brianwilkerson) Passes, but ought to fail.
    super.test_voidVariable_statement_initializer();
  }

  @override
//  @failingTest
  void test_voidVariable_statement_noInitializer() {
    // TODO(brianwilkerson) Passes, but ought to fail.
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
  GatheringErrorListener get listener => _parserProxy._errorListener;

  @override
  analyzer.Parser get parser => _parserProxy;

  @override
  bool get usingFastaParser => true;

  @override
  void assertErrorsWithCodes(List<ErrorCode> expectedErrorCodes) {
    _parserProxy._errorListener.assertErrorsWithCodes(
        _toFastaGeneratedAnalyzerErrorCodes(expectedErrorCodes));
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
    listener.assertErrorsWithCodes(
        _toFastaGeneratedAnalyzerErrorCodes(expectedErrorCodes));
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
    createParser(source);
    Object result = _parserProxy._run(getParseFunction);
    assertErrorsWithCodes(errorCodes);
    return result;
  }

  List<ErrorCode> _toFastaGeneratedAnalyzerErrorCodes(
          List<ErrorCode> expectedErrorCodes) =>
      expectedErrorCodes.map((code) {
        if (code == ParserErrorCode.ABSTRACT_CLASS_MEMBER ||
            code == ParserErrorCode.ABSTRACT_ENUM ||
            code == ParserErrorCode.ABSTRACT_TOP_LEVEL_FUNCTION ||
            code == ParserErrorCode.ABSTRACT_TOP_LEVEL_VARIABLE ||
            code == ParserErrorCode.ABSTRACT_TYPEDEF)
          return ParserErrorCode.EXTRANEOUS_MODIFIER;
        return code;
      }).toList();
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
    super.test_parseFormalParameterList_prefixedType_partial();
  }

  @override
  @failingTest
  void test_parseFormalParameterList_prefixedType_partial2() {
    super.test_parseFormalParameterList_prefixedType_partial2();
  }

  @override
  @failingTest
  void test_parseNormalFormalParameter_field_const_noType() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 0 errors of type ParserErrorCode.EXTRANEOUS_MODIFIER, found 1 (1)
    super.test_parseNormalFormalParameter_field_const_noType();
  }

  @failingTest
  void test_parseNormalFormalParameter_field_const_noType2() {
    // TODO(danrubel): should not be generating an error
    super.test_parseNormalFormalParameter_field_const_noType();
    assertNoErrors();
  }

  @override
  @failingTest
  void test_parseNormalFormalParameter_field_const_type() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 0 errors of type ParserErrorCode.EXTRANEOUS_MODIFIER, found 1 (1)
    super.test_parseNormalFormalParameter_field_const_type();
  }

  @failingTest
  void test_parseNormalFormalParameter_field_const_type2() {
    // TODO(danrubel): should not be generating an error
    super.test_parseNormalFormalParameter_field_const_type();
    assertNoErrors();
  }

  @override
  @failingTest
  void test_parseNormalFormalParameter_simple_const_noType() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 0 errors of type ParserErrorCode.EXTRANEOUS_MODIFIER, found 1 (1)
    super.test_parseNormalFormalParameter_simple_const_noType();
  }

  @failingTest
  void test_parseNormalFormalParameter_simple_const_noType2() {
    // TODO(danrubel): should not be generating an error
    super.test_parseNormalFormalParameter_simple_const_noType();
    assertNoErrors();
  }

  @override
  @failingTest
  void test_parseNormalFormalParameter_simple_const_type() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 0 errors of type ParserErrorCode.EXTRANEOUS_MODIFIER, found 1 (1)
    super.test_parseNormalFormalParameter_simple_const_type();
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
  Annotation parseAnnotation() {
    return _run((parser) => parser.parseMetadata) as Annotation;
  }

  @override
  ArgumentList parseArgumentList() {
    Object result = _run((parser) => parser.parseArguments);
    if (result is MethodInvocation) {
      return result.argumentList;
    }
    return result as ArgumentList;
  }

  @override
  ClassMember parseClassMember(String className) {
    _astBuilder.className = className;
    _eventListener.begin('CompilationUnit');
    var result = _run((parser) => parser.parseMember) as ClassMember;
    _eventListener.end('CompilationUnit');
    _astBuilder.className = null;
    return result;
  }

  List<Combinator> parseCombinators() {
    return _run((parser) => parser.parseCombinators);
  }

  @override
  CommentAndMetadata parseCommentAndMetadata() {
    List commentAndMetadata =
        _run((parser) => parser.parseMetadataStar, nodeCount: -1);
    expect(commentAndMetadata, hasLength(2));
    Object comment = commentAndMetadata[0];
    Object metadata = commentAndMetadata[1];
    if (comment == NullValue.Comments) {
      comment = null;
    }
    if (metadata == NullValue.Metadata) {
      metadata = null;
    } else {
      metadata = new List<Annotation>.from(metadata);
    }
    return new CommentAndMetadata(comment, metadata);
  }

  @override
  CompilationUnit parseCompilationUnit2() {
    var result = _run(null) as CompilationUnit;
    _eventListener.expectEmpty();
    return result;
  }

  @override
  Configuration parseConfiguration() {
    return _run((parser) => parser.parseConditionalUri) as Configuration;
  }

  @override
  FormalParameterList parseFormalParameterList({bool inFunctionType: false}) {
    return _run((parser) => (token) => parser.parseFormalParameters(
        token,
        inFunctionType
            ? fasta.MemberKind.GeneralizedFunctionType
            : fasta.MemberKind.StaticMethod)) as FormalParameterList;
  }

  @override
  FunctionBody parseFunctionBody(
      bool mayBeEmpty, ParserErrorCode emptyErrorCode, bool inExpression) {
    return _run((parser) => (token) =>
            parser.parseFunctionBody(token, inExpression, mayBeEmpty))
        as FunctionBody;
  }

  @override
  Statement parseStatement2() {
    return _run((parser) => parser.parseStatement) as Statement;
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

  @override
  TypeAnnotation parseTypeAnnotation(bool inExpression) {
    return _run((parser) => parser.parseType) as TypeAnnotation;
  }

  @override
  TypeArgumentList parseTypeArgumentList() {
    return _run((parser) => parser.parseTypeArgumentsOpt) as TypeArgumentList;
  }

  @override
  TypeName parseTypeName(bool inExpression) {
    return _run((parser) => parser.parseType) as TypeName;
  }

  @override
  TypeParameter parseTypeParameter() {
    return _run((parser) => parser.parseTypeVariable) as TypeParameter;
  }

  @override
  TypeParameterList parseTypeParameterList() {
    return _run((parser) => parser.parseTypeVariablesOpt) as TypeParameterList;
  }

  /**
   * Runs a single parser function (returned by [getParseFunction]), and returns
   * the result as an analyzer AST. It checks that the parse consumed all of the
   * tokens and that there were [nodeCount] AST nodes created (unless the node
   * count is negative).
   */
  Object _run(ParseFunction getParseFunction(fasta.Parser parser),
      {int nodeCount: 1}) {
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
    if (nodeCount >= 0) {
      expect(_astBuilder.stack, hasLength(nodeCount));
    }
    if (nodeCount != 1) {
      return _astBuilder.stack.values;
    }
    return _astBuilder.pop();
  }
}

@reflectiveTest
class RecoveryParserTest_Fasta extends FastaParserTestCase
    with RecoveryParserTestMixin {
  @override
  @failingTest
  void test_additiveExpression_missing_LHS() {
    // TODO(brianwilkerson) Unhandled compile-time error:
    // '+' is not a prefix operator.
    super.test_additiveExpression_missing_LHS();
  }

  @override
  @failingTest
  void test_additiveExpression_missing_LHS_RHS() {
    // TODO(brianwilkerson) Unhandled compile-time error:
    // '+' is not a prefix operator.
    super.test_additiveExpression_missing_LHS_RHS();
  }

  @override
  @failingTest
  void test_additiveExpression_missing_RHS() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_additiveExpression_missing_RHS();
  }

  @override
  @failingTest
  void test_additiveExpression_missing_RHS_super() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_additiveExpression_missing_RHS_super();
  }

  @override
  @failingTest
  void test_additiveExpression_precedence_multiplicative_left() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_additiveExpression_precedence_multiplicative_left();
  }

  @override
  @failingTest
  void test_additiveExpression_precedence_multiplicative_right() {
    // TODO(brianwilkerson) Unhandled compile-time error:
    // '+' is not a prefix operator.
    super.test_additiveExpression_precedence_multiplicative_right();
  }

  @override
  @failingTest
  void test_additiveExpression_super() {
    // TODO(brianwilkerson) Unhandled compile-time error:
    // '+' is not a prefix operator.
    super.test_additiveExpression_super();
  }

  @override
  @failingTest
  void test_assignableSelector() {
    // TODO(brianwilkerson) Failed to use all tokens.
    super.test_assignableSelector();
  }

  @override
  @failingTest
  void test_assignmentExpression_missing_compound1() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_assignmentExpression_missing_compound1();
  }

  @override
  @failingTest
  void test_assignmentExpression_missing_compound2() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_assignmentExpression_missing_compound2();
  }

  @override
  @failingTest
  void test_assignmentExpression_missing_compound3() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_assignmentExpression_missing_compound3();
  }

  @override
  @failingTest
  void test_assignmentExpression_missing_LHS() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_assignmentExpression_missing_LHS();
  }

  @override
  @failingTest
  void test_assignmentExpression_missing_RHS() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_assignmentExpression_missing_RHS();
  }

  @override
  @failingTest
  void test_bitwiseAndExpression_missing_LHS() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_bitwiseAndExpression_missing_LHS();
  }

  @override
  @failingTest
  void test_bitwiseAndExpression_missing_LHS_RHS() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_bitwiseAndExpression_missing_LHS_RHS();
  }

  @override
  @failingTest
  void test_bitwiseAndExpression_missing_RHS() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_bitwiseAndExpression_missing_RHS();
  }

  @override
  @failingTest
  void test_bitwiseAndExpression_missing_RHS_super() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_bitwiseAndExpression_missing_RHS_super();
  }

  @override
  @failingTest
  void test_bitwiseAndExpression_precedence_equality_left() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_bitwiseAndExpression_precedence_equality_left();
  }

  @override
  @failingTest
  void test_bitwiseAndExpression_precedence_equality_right() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_bitwiseAndExpression_precedence_equality_right();
  }

  @override
  @failingTest
  void test_bitwiseAndExpression_super() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_bitwiseAndExpression_super();
  }

  @override
  @failingTest
  void test_bitwiseOrExpression_missing_LHS() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_bitwiseOrExpression_missing_LHS();
  }

  @override
  @failingTest
  void test_bitwiseOrExpression_missing_LHS_RHS() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_bitwiseOrExpression_missing_LHS_RHS();
  }

  @override
  @failingTest
  void test_bitwiseOrExpression_missing_RHS() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_bitwiseOrExpression_missing_RHS();
  }

  @override
  @failingTest
  void test_bitwiseOrExpression_missing_RHS_super() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_bitwiseOrExpression_missing_RHS_super();
  }

  @override
  @failingTest
  void test_bitwiseOrExpression_precedence_xor_left() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_bitwiseOrExpression_precedence_xor_left();
  }

  @override
  @failingTest
  void test_bitwiseOrExpression_precedence_xor_right() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_bitwiseOrExpression_precedence_xor_right();
  }

  @override
  @failingTest
  void test_bitwiseOrExpression_super() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_bitwiseOrExpression_super();
  }

  @override
  @failingTest
  void test_bitwiseXorExpression_missing_LHS() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_bitwiseXorExpression_missing_LHS();
  }

  @override
  @failingTest
  void test_bitwiseXorExpression_missing_LHS_RHS() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_bitwiseXorExpression_missing_LHS_RHS();
  }

  @override
  @failingTest
  void test_bitwiseXorExpression_missing_RHS() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_bitwiseXorExpression_missing_RHS();
  }

  @override
  @failingTest
  void test_bitwiseXorExpression_missing_RHS_super() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_bitwiseXorExpression_missing_RHS_super();
  }

  @override
  @failingTest
  void test_bitwiseXorExpression_precedence_and_left() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_bitwiseXorExpression_precedence_and_left();
  }

  @override
  @failingTest
  void test_bitwiseXorExpression_precedence_and_right() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_bitwiseXorExpression_precedence_and_right();
  }

  @override
  @failingTest
  void test_bitwiseXorExpression_super() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_bitwiseXorExpression_super();
  }

  @override
  @failingTest
  void test_classTypeAlias_withBody() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_classTypeAlias_withBody();
  }

  @override
  @failingTest
  void test_conditionalExpression_missingElse() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_conditionalExpression_missingElse();
  }

  @override
  @failingTest
  void test_conditionalExpression_missingThen() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_conditionalExpression_missingThen();
  }

  @override
  @failingTest
  void test_declarationBeforeDirective() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.DIRECTIVE_AFTER_DECLARATION, found 0
    super.test_declarationBeforeDirective();
  }

  @override
  @failingTest
  void test_equalityExpression_missing_LHS() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_equalityExpression_missing_LHS();
  }

  @override
  @failingTest
  void test_equalityExpression_missing_LHS_RHS() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_equalityExpression_missing_LHS_RHS();
  }

  @override
  @failingTest
  void test_equalityExpression_missing_RHS() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_equalityExpression_missing_RHS();
  }

  @override
  @failingTest
  void test_equalityExpression_missing_RHS_super() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_equalityExpression_missing_RHS_super();
  }

  @override
  @failingTest
  void test_equalityExpression_precedence_relational_left() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_equalityExpression_precedence_relational_left();
  }

  @override
  @failingTest
  void test_equalityExpression_precedence_relational_right() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_equalityExpression_precedence_relational_right();
  }

  @override
  @failingTest
  void test_equalityExpression_super() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_equalityExpression_super();
  }

  @override
  @failingTest
  void test_expressionList_multiple_end() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_expressionList_multiple_end();
  }

  @override
  @failingTest
  void test_expressionList_multiple_middle() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_expressionList_multiple_middle();
  }

  @override
  @failingTest
  void test_expressionList_multiple_start() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.MISSING_IDENTIFIER, found 0
    super.test_expressionList_multiple_start();
  }

  @override
  @failingTest
  void test_functionExpression_in_ConstructorFieldInitializer() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_functionExpression_in_ConstructorFieldInitializer();
  }

  @override
  @failingTest
  void test_functionExpression_named() {
    // TODO(brianwilkerson) Unhandled compile-time error:
    // A function expression can't have a name.
    super.test_functionExpression_named();
  }

  @override
  @failingTest
  void test_importDirectivePartial_as() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_importDirectivePartial_as();
  }

  @override
  @failingTest
  void test_importDirectivePartial_hide() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_importDirectivePartial_hide();
  }

  @override
  @failingTest
  void test_importDirectivePartial_show() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_importDirectivePartial_show();
  }

  @override
  @failingTest
  void test_incomplete_conditionalExpression() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_incomplete_conditionalExpression();
  }

  @override
  @failingTest
  void test_incomplete_constructorInitializers_empty() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_incomplete_constructorInitializers_empty();
  }

  @override
  @failingTest
  void test_incomplete_constructorInitializers_missingEquals() {
    // TODO(brianwilkerson) exception:
    //   NoSuchMethodError: The getter 'thisKeyword' was called on null.
    //   Receiver: null
    //   Tried calling: thisKeyword
    //   dart:core                                                          Object.noSuchMethod
    //   package:analyzer/src/fasta/ast_builder.dart 440:42                 AstBuilder.endInitializers
    //   test/generated/parser_fasta_listener.dart 872:14                   ForwardingTestListener.endInitializers
    //   package:front_end/src/fasta/parser/parser.dart 1942:14             Parser.parseInitializers
    //   package:front_end/src/fasta/parser/parser.dart 1923:14             Parser.parseInitializersOpt
    //   package:front_end/src/fasta/parser/parser.dart 2412:13             Parser.parseMethod
    //   package:front_end/src/fasta/parser/parser.dart 2316:11             Parser.parseMember
    super.test_incomplete_constructorInitializers_missingEquals();
  }

  @override
  @failingTest
  void test_incomplete_constructorInitializers_variable() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.MISSING_ASSIGNMENT_IN_INITIALIZER, found 0
    super.test_incomplete_constructorInitializers_variable();
  }

  @override
  @failingTest
  void test_incomplete_returnType() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_incomplete_returnType();
  }

  @override
  @failingTest
  void test_incomplete_topLevelFunction() {
    // TODO(brianwilkerson) exception:
    //   NoSuchMethodError: Class '_KernelLibraryBuilder' has no instance method 'addCompileTimeError'.
    //   Receiver: Instance of '_KernelLibraryBuilder'
    //   Tried calling: addCompileTimeError(Instance of 'MessageCode', 6, Instance of '_Uri')
    //   dart:core                                                          Object.noSuchMethod
    //   package:analyzer/src/generated/parser_fasta.dart 20:60             _KernelLibraryBuilder.noSuchMethod
    //   package:analyzer/src/fasta/ast_builder.dart 1956:13                AstBuilder.addCompileTimeError
    //   package:front_end/src/fasta/source/stack_listener.dart 271:5       StackListener.handleRecoverableError
    //   package:front_end/src/fasta/parser/parser.dart 4078:16             Parser.reportRecoverableError
    super.test_incomplete_topLevelFunction();
  }

  @override
  @failingTest
  void test_incomplete_topLevelVariable() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_incomplete_topLevelVariable();
  }

  @override
  @failingTest
  void test_incomplete_topLevelVariable_const() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_incomplete_topLevelVariable_const();
  }

  @override
  @failingTest
  void test_incomplete_topLevelVariable_final() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_incomplete_topLevelVariable_final();
  }

  @override
  @failingTest
  void test_incomplete_topLevelVariable_var() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_incomplete_topLevelVariable_var();
  }

  @override
  @failingTest
  void test_incompleteField_const() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_incompleteField_const();
  }

  @override
  @failingTest
  void test_incompleteField_final() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_incompleteField_final();
  }

  @override
  @failingTest
  void test_incompleteField_var() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_incompleteField_var();
  }

  @override
  @failingTest
  void test_incompleteForEach() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_incompleteForEach();
  }

  @override
  @failingTest
  void test_incompleteLocalVariable_atTheEndOfBlock() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_incompleteLocalVariable_atTheEndOfBlock();
  }

  @override
  @failingTest
  void test_incompleteLocalVariable_beforeIdentifier() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_incompleteLocalVariable_beforeIdentifier();
  }

  @override
  @failingTest
  void test_incompleteLocalVariable_beforeKeyword() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_incompleteLocalVariable_beforeKeyword();
  }

  @override
  @failingTest
  void test_incompleteLocalVariable_beforeNextBlock() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_incompleteLocalVariable_beforeNextBlock();
  }

  @override
  @failingTest
  void test_incompleteLocalVariable_parameterizedType() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_incompleteLocalVariable_parameterizedType();
  }

  @override
  @failingTest
  void test_incompleteTypeArguments_field() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_incompleteTypeArguments_field();
  }

  @override
  @failingTest
  void test_incompleteTypeParameters() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_incompleteTypeParameters();
  }

  @override
  @failingTest
  void test_invalidFunctionBodyModifier() {
    // TODO(brianwilkerson) exception:
    //   NoSuchMethodError: Class '_KernelLibraryBuilder' has no instance method 'addCompileTimeError'.
    //   Receiver: Instance of '_KernelLibraryBuilder'
    //   Tried calling: addCompileTimeError(Instance of 'MessageCode', 5, Instance of '_Uri')
    //   dart:core                                                          Object.noSuchMethod
    //   package:analyzer/src/generated/parser_fasta.dart 20:60             _KernelLibraryBuilder.noSuchMethod
    //   package:analyzer/src/fasta/ast_builder.dart 1956:13                AstBuilder.addCompileTimeError
    //   package:front_end/src/fasta/source/stack_listener.dart 271:5       StackListener.handleRecoverableError
    //   package:front_end/src/fasta/parser/parser.dart 4078:16             Parser.reportRecoverableError
    super.test_invalidFunctionBodyModifier();
  }

  @override
  @failingTest
  void test_isExpression_noType() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_isExpression_noType();
  }

  @override
  @failingTest
  void test_keywordInPlaceOfIdentifier() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_keywordInPlaceOfIdentifier();
  }

  @override
  @failingTest
  void test_logicalAndExpression_missing_LHS() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_logicalAndExpression_missing_LHS();
  }

  @override
  @failingTest
  void test_logicalAndExpression_missing_LHS_RHS() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_logicalAndExpression_missing_LHS_RHS();
  }

  @override
  @failingTest
  void test_logicalAndExpression_missing_RHS() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_logicalAndExpression_missing_RHS();
  }

  @override
  @failingTest
  void test_logicalAndExpression_precedence_bitwiseOr_left() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_logicalAndExpression_precedence_bitwiseOr_left();
  }

  @override
  @failingTest
  void test_logicalAndExpression_precedence_bitwiseOr_right() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_logicalAndExpression_precedence_bitwiseOr_right();
  }

  @override
  @failingTest
  void test_logicalOrExpression_missing_LHS() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_logicalOrExpression_missing_LHS();
  }

  @override
  @failingTest
  void test_logicalOrExpression_missing_LHS_RHS() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_logicalOrExpression_missing_LHS_RHS();
  }

  @override
  @failingTest
  void test_logicalOrExpression_missing_RHS() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_logicalOrExpression_missing_RHS();
  }

  @override
  @failingTest
  void test_logicalOrExpression_precedence_logicalAnd_left() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_logicalOrExpression_precedence_logicalAnd_left();
  }

  @override
  @failingTest
  void test_logicalOrExpression_precedence_logicalAnd_right() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_logicalOrExpression_precedence_logicalAnd_right();
  }

  @override
  @failingTest
  void test_missing_commaInArgumentList() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_missing_commaInArgumentList();
  }

  @override
  @failingTest
  void test_missingComma_beforeNamedArgument() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_missingComma_beforeNamedArgument();
  }

  @override
  @failingTest
  void test_missingGet() {
    // TODO(brianwilkerson) exception:
    //   NoSuchMethodError: Class '_KernelLibraryBuilder' has no instance method 'addCompileTimeError'.
    //   Receiver: Instance of '_KernelLibraryBuilder'
    //   Tried calling: addCompileTimeError(Instance of 'Message', 17, Instance of '_Uri')
    //   dart:core                                                          Object.noSuchMethod
    //   package:analyzer/src/generated/parser_fasta.dart 20:60             _KernelLibraryBuilder.noSuchMethod
    //   package:analyzer/src/fasta/ast_builder.dart 1956:13                AstBuilder.addCompileTimeError
    //   package:front_end/src/fasta/source/stack_listener.dart 271:5       StackListener.handleRecoverableError
    //   package:front_end/src/fasta/parser/parser.dart 4099:16             Parser.reportRecoverableErrorWithToken
    //   package:front_end/src/fasta/parser/parser.dart 1744:7              Parser.checkFormals
    //    package:front_end/src/fasta/parser/parser.dart 2406:5              Parser.parseMethod
    super.test_missingGet();
  }

  @override
  @failingTest
  void test_missingIdentifier_afterAnnotation() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_missingIdentifier_afterAnnotation();
  }

  @override
  @failingTest
  void test_missingSemicolon_varialeDeclarationList() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE, found 0;
    // 1 errors of type ParserErrorCode.EXPECTED_TOKEN, found 0;
    // 0 errors of type ParserErrorCode.EXTRANEOUS_MODIFIER, found 1 (8)
    super.test_missingSemicolon_varialeDeclarationList();
  }

  @override
  @failingTest
  void test_multiplicativeExpression_missing_LHS() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_multiplicativeExpression_missing_LHS();
  }

  @override
  @failingTest
  void test_multiplicativeExpression_missing_LHS_RHS() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_multiplicativeExpression_missing_LHS_RHS();
  }

  @override
  @failingTest
  void test_multiplicativeExpression_missing_RHS() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_multiplicativeExpression_missing_RHS();
  }

  @override
  @failingTest
  void test_multiplicativeExpression_missing_RHS_super() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_multiplicativeExpression_missing_RHS_super();
  }

  @override
  @failingTest
  void test_multiplicativeExpression_precedence_unary_left() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_multiplicativeExpression_precedence_unary_left();
  }

  @override
  @failingTest
  void test_multiplicativeExpression_precedence_unary_right() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_multiplicativeExpression_precedence_unary_right();
  }

  @override
  @failingTest
  void test_multiplicativeExpression_super() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_multiplicativeExpression_super();
  }

  @override
  @failingTest
  void test_nonStringLiteralUri_import() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_nonStringLiteralUri_import();
  }

  @override
  @failingTest
  void test_prefixExpression_missing_operand_minus() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_prefixExpression_missing_operand_minus();
  }

  @override
  @failingTest
  void test_primaryExpression_argumentDefinitionTest() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_primaryExpression_argumentDefinitionTest();
  }

  @override
  @failingTest
  void test_relationalExpression_missing_LHS() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_relationalExpression_missing_LHS();
  }

  @override
  @failingTest
  void test_relationalExpression_missing_LHS_RHS() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_relationalExpression_missing_LHS_RHS();
  }

  @override
  @failingTest
  void test_relationalExpression_missing_RHS() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_relationalExpression_missing_RHS();
  }

  @override
  @failingTest
  void test_relationalExpression_precedence_shift_right() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_relationalExpression_precedence_shift_right();
  }

  @override
  @failingTest
  void test_shiftExpression_missing_LHS() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_shiftExpression_missing_LHS();
  }

  @override
  @failingTest
  void test_shiftExpression_missing_LHS_RHS() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_shiftExpression_missing_LHS_RHS();
  }

  @override
  @failingTest
  void test_shiftExpression_missing_RHS() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_shiftExpression_missing_RHS();
  }

  @override
  @failingTest
  void test_shiftExpression_missing_RHS_super() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_shiftExpression_missing_RHS_super();
  }

  @override
  @failingTest
  void test_shiftExpression_precedence_unary_left() {
    // TODO(brianwilkerson) Unhandled compile-time error:
    // '+' is not a prefix operator.
    super.test_shiftExpression_precedence_unary_left();
  }

  @override
  @failingTest
  void test_shiftExpression_precedence_unary_right() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_shiftExpression_precedence_unary_right();
  }

  @override
  @failingTest
  void test_shiftExpression_super() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_shiftExpression_super();
  }

  @override
  @failingTest
  void test_typedef_eof() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_typedef_eof();
  }

  @override
  @failingTest
  void test_unaryPlus() {
    // TODO(brianwilkerson) Unhandled compile-time error:
    // '+' is not a prefix operator.
    super.test_unaryPlus();
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
  Scope createNestedScope(String debugName, {bool isModifiable: true}) {
    return new Scope.nested(this, debugName, isModifiable: isModifiable);
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

@reflectiveTest
class SimpleParserTest_Fasta extends FastaParserTestCase
    with SimpleParserTestMixin {
  @override
  @failingTest
  void test_parseCommentAndMetadata_mcm() {
    // TODO(brianwilkerson) Does not find comment if not before first annotation
    super.test_parseCommentAndMetadata_mcm();
  }

  @override
  @failingTest
  void test_parseCommentAndMetadata_mcmc() {
    // TODO(brianwilkerson) Does not find comment if not before first annotation
    super.test_parseCommentAndMetadata_mcmc();
  }

  @override
  @failingTest
  void test_parseConstructorName_named_noPrefix() {
    // TODO(brianwilkerson) exception:
    // NoSuchMethodError: Class 'ParserProxy' has no instance method 'parseConstructorName'.
    super.test_parseConstructorName_named_noPrefix();
  }

  @override
  @failingTest
  void test_parseConstructorName_named_prefixed() {
    // TODO(brianwilkerson) exception:
    // NoSuchMethodError: Class 'ParserProxy' has no instance method 'parseConstructorName'.
    super.test_parseConstructorName_named_prefixed();
  }

  @override
  @failingTest
  void test_parseConstructorName_unnamed_noPrefix() {
    // TODO(brianwilkerson) exception:
    // NoSuchMethodError: Class 'ParserProxy' has no instance method 'parseConstructorName'.
    super.test_parseConstructorName_unnamed_noPrefix();
  }

  @override
  @failingTest
  void test_parseConstructorName_unnamed_prefixed() {
    // TODO(brianwilkerson) exception:
    // NoSuchMethodError: Class 'ParserProxy' has no instance method 'parseConstructorName'.
    super.test_parseConstructorName_unnamed_prefixed();
  }

  @override
  @failingTest
  void test_parseDocumentationComment_block() {
    // TODO(brianwilkerson) exception:
    // NoSuchMethodError: Class 'ParserProxy' has no instance method 'parseDocumentationCommentTokens'.
    super.test_parseDocumentationComment_block();
  }

  @override
  @failingTest
  void test_parseDocumentationComment_block_withReference() {
    // TODO(brianwilkerson) exception:
    // NoSuchMethodError: Class 'ParserProxy' has no instance method 'parseDocumentationCommentTokens'.
    super.test_parseDocumentationComment_block_withReference();
  }

  @override
  @failingTest
  void test_parseDocumentationComment_endOfLine() {
    // TODO(brianwilkerson) exception:
    // NoSuchMethodError: Class 'ParserProxy' has no instance method 'parseDocumentationCommentTokens'.
    super.test_parseDocumentationComment_endOfLine();
  }

  @override
  @failingTest
  void test_parseDottedName_multiple() {
    // TODO(brianwilkerson) exception:
    // NoSuchMethodError: Class 'ParserProxy' has no instance method 'parseDottedName'.
    super.test_parseDottedName_multiple();
  }

  @override
  @failingTest
  void test_parseDottedName_single() {
    // TODO(brianwilkerson) exception:
    // NoSuchMethodError: Class 'ParserProxy' has no instance method 'parseDottedName'.
    super.test_parseDottedName_single();
  }

  @override
  @failingTest
  void test_parseExtendsClause() {
    // TODO(brianwilkerson) exception:
    // NoSuchMethodError: Class 'ParserProxy' has no instance method 'parseExtendsClause'.
    super.test_parseExtendsClause();
  }

  @override
  @failingTest
  void test_parseFinalConstVarOrType_const_functionType() {
    // TODO(brianwilkerson) exception:
    // NoSuchMethodError: Class 'ParserProxy' has no instance method 'parseFinalConstVarOrType'.
    super.test_parseFinalConstVarOrType_const_functionType();
  }

  @override
  @failingTest
  void test_parseFinalConstVarOrType_const_namedType() {
    // TODO(brianwilkerson) exception:
    // NoSuchMethodError: Class 'ParserProxy' has no instance method 'parseFinalConstVarOrType'.
    super.test_parseFinalConstVarOrType_const_namedType();
  }

  @override
  @failingTest
  void test_parseFinalConstVarOrType_const_noType() {
    // TODO(brianwilkerson) exception:
    // NoSuchMethodError: Class 'ParserProxy' has no instance method 'parseFinalConstVarOrType'.
    super.test_parseFinalConstVarOrType_const_noType();
  }

  @override
  @failingTest
  void test_parseFinalConstVarOrType_final_functionType() {
    // TODO(brianwilkerson) exception:
    // NoSuchMethodError: Class 'ParserProxy' has no instance method 'parseFinalConstVarOrType'.
    super.test_parseFinalConstVarOrType_final_functionType();
  }

  @override
  @failingTest
  void test_parseFinalConstVarOrType_final_namedType() {
    // TODO(brianwilkerson) exception:
    // NoSuchMethodError: Class 'ParserProxy' has no instance method 'parseFinalConstVarOrType'.
    super.test_parseFinalConstVarOrType_final_namedType();
  }

  @override
  @failingTest
  void test_parseFinalConstVarOrType_final_noType() {
    // TODO(brianwilkerson) exception:
    // NoSuchMethodError: Class 'ParserProxy' has no instance method 'parseFinalConstVarOrType'.
    super.test_parseFinalConstVarOrType_final_noType();
  }

  @override
  @failingTest
  void test_parseFinalConstVarOrType_final_prefixedType() {
    // TODO(brianwilkerson) exception:
    // NoSuchMethodError: Class 'ParserProxy' has no instance method 'parseFinalConstVarOrType'.
    super.test_parseFinalConstVarOrType_final_prefixedType();
  }

  @override
  @failingTest
  void test_parseFinalConstVarOrType_type_function() {
    // TODO(brianwilkerson) exception:
    // NoSuchMethodError: Class 'ParserProxy' has no instance method 'parseFinalConstVarOrType'.
    super.test_parseFinalConstVarOrType_type_function();
  }

  @override
  @failingTest
  void test_parseFinalConstVarOrType_type_parameterized() {
    // TODO(brianwilkerson) exception:
    // NoSuchMethodError: Class 'ParserProxy' has no instance method 'parseFinalConstVarOrType'.
    super.test_parseFinalConstVarOrType_type_parameterized();
  }

  @override
  @failingTest
  void test_parseFinalConstVarOrType_type_prefixed() {
    // TODO(brianwilkerson) exception:
    // NoSuchMethodError: Class 'ParserProxy' has no instance method 'parseFinalConstVarOrType'.
    super.test_parseFinalConstVarOrType_type_prefixed();
  }

  @override
  @failingTest
  void test_parseFinalConstVarOrType_type_prefixed_noIdentifier() {
    // TODO(brianwilkerson) exception:
    // NoSuchMethodError: Class 'ParserProxy' has no instance method 'parseFinalConstVarOrType'.
    super.test_parseFinalConstVarOrType_type_prefixed_noIdentifier();
  }

  @override
  @failingTest
  void test_parseFinalConstVarOrType_type_prefixedAndParameterized() {
    // TODO(brianwilkerson) exception:
    // NoSuchMethodError: Class 'ParserProxy' has no instance method 'parseFinalConstVarOrType'.
    super.test_parseFinalConstVarOrType_type_prefixedAndParameterized();
  }

  @override
  @failingTest
  void test_parseFinalConstVarOrType_type_simple() {
    // TODO(brianwilkerson) exception:
    // NoSuchMethodError: Class 'ParserProxy' has no instance method 'parseFinalConstVarOrType'.
    super.test_parseFinalConstVarOrType_type_simple();
  }

  @override
  @failingTest
  void test_parseFinalConstVarOrType_type_simple_noIdentifier_inFunctionType() {
    // TODO(brianwilkerson) exception:
    // NoSuchMethodError: Class 'ParserProxy' has no instance method 'parseFinalConstVarOrType'.
    super
        .test_parseFinalConstVarOrType_type_simple_noIdentifier_inFunctionType();
  }

  @override
  @failingTest
  void test_parseFinalConstVarOrType_var() {
    // TODO(brianwilkerson) exception:
    // NoSuchMethodError: Class 'ParserProxy' has no instance method 'parseFinalConstVarOrType'.
    super.test_parseFinalConstVarOrType_var();
  }

  @override
  @failingTest
  void test_parseFinalConstVarOrType_void() {
    // TODO(brianwilkerson) exception:
    // NoSuchMethodError: Class 'ParserProxy' has no instance method 'parseFinalConstVarOrType'.
    super.test_parseFinalConstVarOrType_void();
  }

  @override
  @failingTest
  void test_parseFinalConstVarOrType_void_identifier() {
    // TODO(brianwilkerson) exception:
    // NoSuchMethodError: Class 'ParserProxy' has no instance method 'parseFinalConstVarOrType'.
    super.test_parseFinalConstVarOrType_void_identifier();
  }

  @override
  @failingTest
  void test_parseFinalConstVarOrType_void_noIdentifier() {
    // TODO(brianwilkerson) exception:
    // NoSuchMethodError: Class 'ParserProxy' has no instance method 'parseFinalConstVarOrType'.
    super.test_parseFinalConstVarOrType_void_noIdentifier();
  }

  @override
  @failingTest
  void test_parseFunctionBody_block() {
    // TODO(brianwilkerson) exception:
    //   'package:front_end/src/fasta/source/stack_listener.dart': Failed assertion: line 311 pos 12: 'arrayLength > 0': is not true.
    //   dart:core                                                          _AssertionError._throwNew
    //   package:front_end/src/fasta/source/stack_listener.dart 311:12      Stack.pop
    //   package:front_end/src/fasta/source/stack_listener.dart 95:25       StackListener.pop
    //   package:analyzer/src/fasta/ast_builder.dart 287:18                 AstBuilder.endBlockFunctionBody
    //   test/generated/parser_fasta_listener.dart 592:14                   ForwardingTestListener.endBlockFunctionBody
    //   package:front_end/src/fasta/parser/parser.dart 2648:14             Parser.parseFunctionBody
    super.test_parseFunctionBody_block();
  }

  @override
  @failingTest
  void test_parseFunctionBody_block_async() {
    // TODO(brianwilkerson) The method 'parseFunctionBody' does not handle
    // preceding modifiers.
    super.test_parseFunctionBody_block_async();
  }

  @override
  @failingTest
  void test_parseFunctionBody_block_asyncGenerator() {
    // TODO(brianwilkerson) The method 'parseFunctionBody' does not handle
    // preceding modifiers.
    super.test_parseFunctionBody_block_asyncGenerator();
  }

  @override
  @failingTest
  void test_parseFunctionBody_block_syncGenerator() {
    // TODO(brianwilkerson) The method 'parseFunctionBody' does not handle
    // preceding modifiers.
    super.test_parseFunctionBody_block_syncGenerator();
  }

  @override
  @failingTest
  void test_parseFunctionBody_empty() {
    // TODO(brianwilkerson) exception:
    //   'package:front_end/src/fasta/source/stack_listener.dart': Failed assertion: line 311 pos 12: 'arrayLength > 0': is not true.
    //   dart:core                                                          _AssertionError._throwNew
    //   package:front_end/src/fasta/source/stack_listener.dart 311:12      Stack.pop
    //   package:front_end/src/fasta/source/stack_listener.dart 95:25       StackListener.pop
    //   package:analyzer/src/fasta/ast_builder.dart 269:5                  AstBuilder.handleEmptyFunctionBody
    //   test/generated/parser_fasta_listener.dart 1171:14                  ForwardingTestListener.handleEmptyFunctionBody
    //   package:front_end/src/fasta/parser/parser.dart 2607:16             Parser.parseFunctionBody
    super.test_parseFunctionBody_empty();
  }

  @override
  @failingTest
  void test_parseFunctionBody_expression() {
    // TODO(brianwilkerson) exception:
    //   'package:front_end/src/fasta/source/stack_listener.dart': Failed assertion: line 311 pos 12: 'arrayLength > 0': is not true.
    //   dart:core                                                          _AssertionError._throwNew
    //   package:front_end/src/fasta/source/stack_listener.dart 311:12      Stack.pop
    //   package:front_end/src/fasta/source/stack_listener.dart 95:25       StackListener.pop
    //   package:analyzer/src/fasta/ast_builder.dart 379:18                 AstBuilder.handleExpressionFunctionBody
    //   test/generated/parser_fasta_listener.dart 1177:14                  ForwardingTestListener.handleExpressionFunctionBody
    //   package:front_end/src/fasta/parser/parser.dart 2614:18             Parser.parseFunctionBody
    super.test_parseFunctionBody_expression();
  }

  @override
  @failingTest
  void test_parseFunctionBody_expression_async() {
    // TODO(brianwilkerson) The method 'parseFunctionBody' does not handle
    // preceding modifiers.
    super.test_parseFunctionBody_expression_async();
  }

  @override
  @failingTest
  void test_parseIdentifierList_multiple() {
    // TODO(brianwilkerson) exception:
    // NoSuchMethodError: Class 'ParserProxy' has no instance method 'parseIdentifierList'.
    super.test_parseIdentifierList_multiple();
  }

  @override
  @failingTest
  void test_parseIdentifierList_single() {
    // TODO(brianwilkerson) exception:
    // NoSuchMethodError: Class 'ParserProxy' has no instance method 'parseIdentifierList'.
    super.test_parseIdentifierList_single();
  }

  @override
  @failingTest
  void test_parseImplementsClause_multiple() {
    // TODO(brianwilkerson) exception:
    // NoSuchMethodError: Class 'ParserProxy' has no instance method 'parseImplementsClause'.
    super.test_parseImplementsClause_multiple();
  }

  @override
  @failingTest
  void test_parseImplementsClause_single() {
    // TODO(brianwilkerson) exception:
    // NoSuchMethodError: Class 'ParserProxy' has no instance method 'parseImplementsClause'.
    super.test_parseImplementsClause_single();
  }

  @override
  @failingTest
  void test_parseLibraryIdentifier_multiple() {
    // TODO(brianwilkerson) exception:
    // NoSuchMethodError: Class 'ParserProxy' has no instance method 'parseLibraryIdentifier'.
    super.test_parseLibraryIdentifier_multiple();
  }

  @override
  @failingTest
  void test_parseLibraryIdentifier_single() {
    // TODO(brianwilkerson) exception:
    // NoSuchMethodError: Class 'ParserProxy' has no instance method 'parseLibraryIdentifier'.
    super.test_parseLibraryIdentifier_single();
  }

  @override
  @failingTest
  void test_parseModifiers_abstract() {
    // TODO(brianwilkerson) exception:
    // NoSuchMethodError: Class 'ParserProxy' has no instance method 'parseModifiers'.
    super.test_parseModifiers_abstract();
  }

  @override
  @failingTest
  void test_parseModifiers_const() {
    // TODO(brianwilkerson) exception:
    // NoSuchMethodError: Class 'ParserProxy' has no instance method 'parseModifiers'.
    super.test_parseModifiers_const();
  }

  @override
  @failingTest
  void test_parseModifiers_covariant() {
    // TODO(brianwilkerson) exception:
    // NoSuchMethodError: Class 'ParserProxy' has no instance method 'parseModifiers'.
    super.test_parseModifiers_covariant();
  }

  @override
  @failingTest
  void test_parseModifiers_external() {
    // TODO(brianwilkerson) exception:
    // NoSuchMethodError: Class 'ParserProxy' has no instance method 'parseModifiers'.
    super.test_parseModifiers_external();
  }

  @override
  @failingTest
  void test_parseModifiers_factory() {
    // TODO(brianwilkerson) exception:
    // NoSuchMethodError: Class 'ParserProxy' has no instance method 'parseModifiers'.
    super.test_parseModifiers_factory();
  }

  @override
  @failingTest
  void test_parseModifiers_final() {
    // TODO(brianwilkerson) exception:
    // NoSuchMethodError: Class 'ParserProxy' has no instance method 'parseModifiers'.
    super.test_parseModifiers_final();
  }

  @override
  @failingTest
  void test_parseModifiers_static() {
    // TODO(brianwilkerson) exception:
    // NoSuchMethodError: Class 'ParserProxy' has no instance method 'parseModifiers'.
    super.test_parseModifiers_static();
  }

  @override
  @failingTest
  void test_parseModifiers_var() {
    // TODO(brianwilkerson) exception:
    // NoSuchMethodError: Class 'ParserProxy' has no instance method 'parseModifiers'.
    super.test_parseModifiers_var();
  }

  @override
//  @failingTest
  void test_parseReturnType_void() {
    // TODO(brianwilkerson) Passes, but ought to fail.
    super.test_parseReturnType_void();
  }

  @override
  @failingTest
  void test_parseTypeArgumentList_empty() {
    // TODO(brianwilkerson) Does not recover from an empty list.
    super.test_parseTypeArgumentList_empty();
  }

  @override
  @failingTest
  void test_parseTypeArgumentList_nested_withComment_double() {
    // TODO(brianwilkerson) Does not capture comment when splitting '>>' into
    // two tokens.
    super.test_parseTypeArgumentList_nested_withComment_double();
  }

  @override
  @failingTest
  void test_parseTypeArgumentList_nested_withComment_tripple() {
    // TODO(brianwilkerson) Does not capture comment when splitting '>>' into
    // two tokens.
    super.test_parseTypeArgumentList_nested_withComment_tripple();
  }

  @override
  @failingTest
  void test_parseTypeParameterList_parameterizedWithTrailingEquals() {
    super.test_parseTypeParameterList_parameterizedWithTrailingEquals();
  }

  @override
  @failingTest
  void test_parseTypeParameterList_single() {
    // TODO(brianwilkerson) Does not use all tokens.
    super.test_parseTypeParameterList_single();
  }

  @override
  @failingTest
  void test_parseTypeParameterList_withTrailingEquals() {
    super.test_parseTypeParameterList_withTrailingEquals();
  }

  @override
  @failingTest
  void test_parseVariableDeclaration_equals() {
    // TODO(brianwilkerson) exception:
    // NoSuchMethodError: Class 'ParserProxy' has no instance method 'parseVariableDeclaration'.
    super.test_parseVariableDeclaration_equals();
  }

  @override
  @failingTest
  void test_parseVariableDeclaration_noEquals() {
    // TODO(brianwilkerson) exception:
    // NoSuchMethodError: Class 'ParserProxy' has no instance method 'parseVariableDeclaration'.
    super.test_parseVariableDeclaration_noEquals();
  }

  @override
  @failingTest
  void test_parseWithClause_multiple() {
    // TODO(brianwilkerson) exception:
    // NoSuchMethodError: Class 'ParserProxy' has no instance method 'parseWithClause'.
    super.test_parseWithClause_multiple();
  }

  @override
  @failingTest
  void test_parseWithClause_single() {
    // TODO(brianwilkerson) exception:
    // NoSuchMethodError: Class 'ParserProxy' has no instance method 'parseWithClause'.
    super.test_parseWithClause_single();
  }
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
    // TODO(brianwilkerson) Does not handle optional trailing comma.
    super.test_parseAssertStatement_trailingComma_message();
  }

  @override
  @failingTest
  void test_parseAssertStatement_trailingComma_noMessage() {
    // TODO(brianwilkerson) Does not handle optional trailing comma.
    super.test_parseAssertStatement_trailingComma_noMessage();
  }

  @override
  @failingTest
  void test_parseBreakStatement_noLabel() {
    // TODO(brianwilkerson)
    // Expected 1 errors of type ParserErrorCode.BREAK_OUTSIDE_OF_LOOP, found 0
    super.test_parseBreakStatement_noLabel();
  }

  @override
  @failingTest
  void test_parseContinueStatement_label() {
    // TODO(brianwilkerson)
    // Expected 1 errors of type ParserErrorCode.CONTINUE_OUTSIDE_OF_LOOP, found 0
    super.test_parseContinueStatement_label();
  }

  @override
  @failingTest
  void test_parseContinueStatement_noLabel() {
    // TODO(brianwilkerson)
    // Expected 1 errors of type ParserErrorCode.CONTINUE_OUTSIDE_OF_LOOP, found 0
    super.test_parseContinueStatement_noLabel();
  }

  @override
  @failingTest
  void test_parseStatement_emptyTypeArgumentList() {
    // TODO(brianwilkerson) Does not recover from empty list.
    super.test_parseStatement_emptyTypeArgumentList();
  }
}

/**
 * Tests of the fasta parser based on [TopLevelParserTestMixin].
 */
@reflectiveTest
class TopLevelParserTest_Fasta extends FastaParserTestCase
    with TopLevelParserTestMixin {
  void test_parseClassDeclaration_native_allowed() {
    allowNativeClause = true;
    test_parseClassDeclaration_native();
  }

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
  void test_parseCompilationUnit_abstractAsPrefix_parameterized() {
    // TODO(danrubel): built-in "abstract" cannot be used as a type
    super.test_parseCompilationUnit_abstractAsPrefix_parameterized();
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

  @override
  @failingTest
  void test_parseCompilationUnitMember_abstractAsPrefix() {
    // TODO(danrubel): built-in "abstract" cannot be used as a prefix
    super.test_parseCompilationUnitMember_abstractAsPrefix();
  }

  @failingTest
  void test_parseCompilationUnitMember_abstractAsPrefix2() {
    // TODO(danrubel): should not be generating an error
    super.test_parseCompilationUnitMember_abstractAsPrefix();
    assertNoErrors();
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
}
