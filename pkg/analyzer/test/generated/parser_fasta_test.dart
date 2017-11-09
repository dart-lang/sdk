// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart' as analyzer;
import 'package:analyzer/dart/ast/token.dart' show Token, TokenType;
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart' show ErrorReporter;
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/parser.dart' as analyzer;
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/string_source.dart';
import 'package:front_end/src/fasta/fasta_codes.dart'
    show LocatedMessage, Message;
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
    with ClassMemberParserTestMixin {}

/**
 * Tests of the fasta parser based on [ComplexParserTestMixin].
 */
@reflectiveTest
class ComplexParserTest_Fasta extends FastaParserTestCase
    with ComplexParserTestMixin {
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
    // TODO(brianwilkerson) Fix highlight region.
    // This is highlighting the '@', but should highlight the whole annotation.
    super.test_annotationOnEnumConstant_first();
  }

  @override
  @failingTest
  void test_annotationOnEnumConstant_middle() {
    // TODO(brianwilkerson) Fix highlight region.
    // This is highlighting the '@', but should highlight the whole annotation.
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
  void test_classTypeAlias_abstractAfterEq() {
    // TODO(brianwilkerson) Does not recover.
    super.test_classTypeAlias_abstractAfterEq();
  }

  @override
  @failingTest
  void test_constConstructorWithBody() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.CONST_CONSTRUCTOR_WITH_BODY, found 0
    //
    // This error is produced by kernel, rather than in the parser.
    super.test_constConstructorWithBody();
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
  void test_covariantConstructor() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.COVARIANT_CONSTRUCTOR, found 0;
    // 0 errors of type ParserErrorCode.EXTRANEOUS_MODIFIER, found 1 (10)
    super.test_covariantConstructor();
  }

  @override
  @failingTest
  void test_duplicateLabelInSwitchStatement() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.DUPLICATE_LABEL_IN_SWITCH_STATEMENT, found 0
    super.test_duplicateLabelInSwitchStatement();
  }

  @override
  @failingTest
  void test_equalityCannotBeEqualityOperand_eq_eq() {
    // TODO(brianwilkerson) Does not recover (fails to parse all tokens).
    super.test_equalityCannotBeEqualityOperand_eq_eq();
  }

  @override
  @failingTest
  void test_equalityCannotBeEqualityOperand_eq_neq() {
    // TODO(brianwilkerson) Does not recover (fails to parse all tokens).
    super.test_equalityCannotBeEqualityOperand_eq_neq();
  }

  @override
  @failingTest
  void test_equalityCannotBeEqualityOperand_neq_eq() {
    // TODO(brianwilkerson) Does not recover (fails to parse all tokens).
    super.test_equalityCannotBeEqualityOperand_neq_eq();
  }

  @override
  @failingTest
  void test_expectedCaseOrDefault() {
    // TODO(brianwilkerson) Does not recover.
    //   Bad state: No element
    //   dart:core                                                          List.last
    //   package:analyzer/src/fasta/ast_builder.dart 951:13                 AstBuilder.endSwitchCase
    //   test/generated/parser_fasta_listener.dart 1010:14                  ForwardingTestListener.endSwitchCase
    //   package:front_end/src/fasta/parser/parser.dart 3991:14             Parser.parseSwitchCase
    //   package:front_end/src/fasta/parser/parser.dart 3914:15             Parser.parseSwitchBlock
    //   package:front_end/src/fasta/parser/parser.dart 3900:13             Parser.parseSwitchStatement
    //   package:front_end/src/fasta/parser/parser.dart 2760:14             Parser.parseStatementX
    //   package:front_end/src/fasta/parser/parser.dart 2722:20             Parser.parseStatement
    //   test/generated/parser_fasta_test.dart 2903:39                      ParserProxy._run
    super.test_expectedCaseOrDefault();
  }

  @override
  @failingTest
  void test_expectedClassMember_inClass_afterType() {
    // TODO(brianwilkerson) Does not recover.
    //   Expected: an object with length of <1>
    //   Actual: <Instance of 'Stack'>
    //   Which: has length of <2>
    //
    //   package:test                                                       expect
    //   test/generated/parser_fasta_test.dart 2870:7                       ParserProxy._run
    //   test/generated/parser_fasta_test.dart 2750:18                      ParserProxy.parseClassMember
    super.test_expectedClassMember_inClass_afterType();
  }

  @override
  @failingTest
  void test_expectedClassMember_inClass_beforeType() {
    // TODO(brianwilkerson) Does not recover.
    //   Expected: an object with length of <1>
    //   Actual: <Instance of 'Stack'>
    //   Which: has length of <2>
    //
    //   package:test                                                       expect
    //   test/generated/parser_fasta_test.dart 2870:7                       ParserProxy._run
    //   test/generated/parser_fasta_test.dart 2750:18                      ParserProxy.parseClassMember
    super.test_expectedClassMember_inClass_beforeType();
  }

  @override
  @failingTest
  void test_expectedExecutable_inClass_afterVoid() {
    // TODO(brianwilkerson) Does not recover.
    //   Expected: an object with length of <1>
    //   Actual: <Instance of 'Stack'>
    //   Which: has length of <2>
    //
    //   package:test                                                       expect
    //   test/generated/parser_fasta_test.dart 2870:7                       ParserProxy._run
    //   test/generated/parser_fasta_test.dart 2750:18                      ParserProxy.parseClassMember
    super.test_expectedExecutable_inClass_afterVoid();
  }

  @override
  @failingTest
  void test_expectedExecutable_topLevel_afterType() {
    // TODO(brianwilkerson) Does not recover.
    //   Expected CompilationUnit, but found [CompilationUnit, TopLevelMember]
    //   package:test                                                       fail
    //   test/generated/parser_fasta_listener.dart 50:7                     ForwardingTestListener.expectIn
    //   test/generated/parser_fasta_listener.dart 1030:5                   ForwardingTestListener.endTopLevelDeclaration
    //   package:front_end/src/fasta/parser/parser.dart 264:14              Parser.parseTopLevelDeclaration
    //   test/generated/parser_fasta_test.dart 2815:22                      ParserProxy.parseTopLevelDeclaration
    super.test_expectedExecutable_topLevel_afterType();
  }

  @override
  @failingTest
  void test_expectedExecutable_topLevel_afterVoid() {
    // TODO(brianwilkerson) Does not recover.
    //   Expected CompilationUnit, but found [CompilationUnit, TopLevelMember]
    //   package:test                                                       fail
    //   test/generated/parser_fasta_listener.dart 50:7                     ForwardingTestListener.expectIn
    //   test/generated/parser_fasta_listener.dart 1030:5                   ForwardingTestListener.endTopLevelDeclaration
    //   package:front_end/src/fasta/parser/parser.dart 264:14              Parser.parseTopLevelDeclaration
    //   test/generated/parser_fasta_test.dart 2815:22                      ParserProxy.parseTopLevelDeclaration
    super.test_expectedExecutable_topLevel_afterVoid();
  }

  @override
  @failingTest
  void test_expectedExecutable_topLevel_beforeType() {
    // TODO(brianwilkerson) Does not recover.
    //   Expected: true
    //   Actual: <false>
    //
    //   package:test                                                       expect
    //   test/generated/parser_fasta_test.dart 2852:5                       ParserProxy.parseTopLevelDeclaration
    super.test_expectedExecutable_topLevel_beforeType();
  }

  @override
  @failingTest
  void test_expectedExecutable_topLevel_eof() {
    // TODO(brianwilkerson) Does not recover.
    //   Expected CompilationUnit, but found [CompilationUnit, TopLevelMember]
    //   package:test                                                       fail
    //   test/generated/parser_fasta_listener.dart 50:7                     ForwardingTestListener.expectIn
    //   test/generated/parser_fasta_listener.dart 1030:5                   ForwardingTestListener.endTopLevelDeclaration
    //   package:front_end/src/fasta/parser/parser.dart 264:14              Parser.parseTopLevelDeclaration
    //   test/generated/parser_fasta_test.dart 2851:22                      ParserProxy.parseTopLevelDeclaration
    super.test_expectedExecutable_topLevel_eof();
  }

  @override
  @failingTest
  void test_expectedInterpolationIdentifier() {
    // TODO(brianwilkerson) Does not recover.
    //   RangeError: Value not in range: -1
    //   dart:core                                                          _StringBase.substring
    //   package:front_end/src/fasta/quote.dart 130:12                      unescapeLastStringPart
    //   package:analyzer/src/fasta/ast_builder.dart 187:17                 AstBuilder.endLiteralString
    //   test/generated/parser_fasta_listener.dart 896:14                   ForwardingTestListener.endLiteralString
    //   package:front_end/src/fasta/parser/parser.dart 3497:14             Parser.parseSingleLiteralString
    //   package:front_end/src/fasta/parser/parser.dart 3434:13             Parser.parseLiteralString
    //   package:front_end/src/fasta/parser/parser.dart 3133:14             Parser.parsePrimary
    //   package:front_end/src/fasta/parser/parser.dart 3097:14             Parser.parseUnaryExpression
    //   package:front_end/src/fasta/parser/parser.dart 2968:13             Parser.parsePrecedenceExpression
    //   package:front_end/src/fasta/parser/parser.dart 2942:11             Parser.parseExpression
    //   test/generated/parser_fasta_test.dart 2929:39                      ParserProxy._run
    super.test_expectedInterpolationIdentifier();
  }

  @override
  @failingTest
  void test_expectedInterpolationIdentifier_emptyString() {
    // TODO(brianwilkerson) Does not recover.
    //   RangeError: Value not in range: -1
    //   dart:core                                                          _StringBase.substring
    //   package:front_end/src/fasta/quote.dart 130:12                      unescapeLastStringPart
    //   package:analyzer/src/fasta/ast_builder.dart 187:17                 AstBuilder.endLiteralString
    //   test/generated/parser_fasta_listener.dart 896:14                   ForwardingTestListener.endLiteralString
    //   package:front_end/src/fasta/parser/parser.dart 3497:14             Parser.parseSingleLiteralString
    //   package:front_end/src/fasta/parser/parser.dart 3434:13             Parser.parseLiteralString
    //   package:front_end/src/fasta/parser/parser.dart 3133:14             Parser.parsePrimary
    //   package:front_end/src/fasta/parser/parser.dart 3097:14             Parser.parseUnaryExpression
    //   package:front_end/src/fasta/parser/parser.dart 2968:13             Parser.parsePrecedenceExpression
    //   package:front_end/src/fasta/parser/parser.dart 2942:11             Parser.parseExpression
    //   test/generated/parser_fasta_test.dart 2929:39                      ParserProxy._run
    super.test_expectedInterpolationIdentifier_emptyString();
  }

  @override
  @failingTest
  void test_expectedListOrMapLiteral() {
    // TODO(brianwilkerson) Does not recover.
    //   type 'IntegerLiteralImpl' is not a subtype of type 'TypedLiteral' in type cast where
    //   IntegerLiteralImpl is from package:analyzer/src/dart/ast/ast.dart
    //   TypedLiteral is from package:analyzer/dart/ast/ast.dart
    //
    //   dart:core                                                          Object._as
    //   test/generated/parser_fasta_test.dart 2480:48                      FastaParserTestCase.parseListOrMapLiteral
    super.test_expectedListOrMapLiteral();
  }

  @override
  @failingTest
  void test_expectedStringLiteral() {
    // TODO(brianwilkerson) Does not recover.
    //   type 'IntegerLiteralImpl' is not a subtype of type 'StringLiteral' of 'literal' where
    //   IntegerLiteralImpl is from package:analyzer/src/dart/ast/ast.dart
    //   StringLiteral is from package:analyzer/dart/ast/ast.dart
    //
    //   test/generated/parser_test.dart 2652:29                            FastaParserTestCase&ErrorParserTestMixin.test_expectedStringLiteral
    super.test_expectedStringLiteral();
  }

  @override
  @failingTest
  void test_expectedToken_commaMissingInArgumentList() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.EXPECTED_TOKEN, found 0
    super.test_expectedToken_commaMissingInArgumentList();
  }

  @override
  @failingTest
  void test_expectedToken_parseStatement_afterVoid() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.EXPECTED_TOKEN, found 0;
    // 1 errors of type ParserErrorCode.MISSING_IDENTIFIER, found 0
    super.test_expectedToken_parseStatement_afterVoid();
  }

  @override
  @failingTest
  void test_expectedToken_whileMissingInDoStatement() {
    // TODO(brianwilkerson) Does not recover.
    //   NoSuchMethodError: Class 'SimpleToken' has no instance getter 'endGroup'.
    //   Receiver: Instance of 'SimpleToken'
    //   Tried calling: endGroup
    //   dart:core                                                          Object.noSuchMethod
    //   package:front_end/src/fasta/parser/parser.dart 3212:26             Parser.parseParenthesizedExpression
    //   package:front_end/src/fasta/parser/parser.dart 3781:13             Parser.parseDoWhileStatement
    //   package:front_end/src/fasta/parser/parser.dart 2756:14             Parser.parseStatementX
    //   package:front_end/src/fasta/parser/parser.dart 2722:20             Parser.parseStatement
    //   test/generated/parser_fasta_test.dart 2973:39                      ParserProxy._run
    super.test_expectedToken_whileMissingInDoStatement();
  }

  @override
  @failingTest
  void test_expectedTypeName_as_void() {
    // TODO(brianwilkerson) Does not recover.
    //   Expected: true
    //   Actual: <false>
    //
    //   package:test                                                       expect
    //   test/generated/parser_fasta_test.dart 2974:5                       ParserProxy._run
    //   test/generated/parser_fasta_test.dart 2661:34                      FastaParserTestCase._runParser
    super.test_expectedTypeName_as_void();
  }

  @override
  @failingTest
  void test_expectedTypeName_is_void() {
    // TODO(brianwilkerson) Does not recover.
    //   Expected: true
    //   Actual: <false>
    //
    //   package:test                                                       expect
    //   test/generated/parser_fasta_test.dart 2999:5                       ParserProxy._run
    super.test_expectedTypeName_is_void();
  }

  @override
  @failingTest
  void test_extraCommaInParameterList() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.MISSING_IDENTIFIER, found 0;
    // 1 errors of type ParserErrorCode.EXPECTED_TOKEN, found 0
    super.test_extraCommaInParameterList();
  }

  @override
  @failingTest
  void test_extraCommaTrailingNamedParameterGroup() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.NORMAL_BEFORE_OPTIONAL_PARAMETERS, found 0;
    // 1 errors of type ParserErrorCode.MISSING_IDENTIFIER, found 0
    super.test_extraCommaTrailingNamedParameterGroup();
  }

  @override
  @failingTest
  void test_extraCommaTrailingPositionalParameterGroup() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.NORMAL_BEFORE_OPTIONAL_PARAMETERS, found 0;
    // 1 errors of type ParserErrorCode.MISSING_IDENTIFIER, found 0
    super.test_extraCommaTrailingPositionalParameterGroup();
  }

  @override
  @failingTest
  void test_factoryWithInitializers() {
    // TODO(brianwilkerson) Does not recover.
    //   Internal problem: Compiler cannot run without a compiler context.
    //   Tip: Are calls to the compiler wrapped in CompilerContext.runInContext?
    //   package:front_end/src/fasta/compiler_context.dart 81:7             CompilerContext.current
    //   package:front_end/src/fasta/problems.dart 29:25                    internalProblem
    //   package:front_end/src/fasta/problems.dart 41:10                    unhandled
    //   package:analyzer/src/fasta/ast_builder.dart 1506:7                 AstBuilder.endFactoryMethod
    //   test/generated/parser_fasta_listener.dart 731:14                   ForwardingTestListener.endFactoryMethod
    //   package:front_end/src/fasta/parser/parser.dart 2465:14             Parser.parseFactoryMethod
    //   package:front_end/src/fasta/parser/parser.dart 2240:15             Parser.parseMember
    //   test/generated/parser_fasta_test.dart 3051:39                      ParserProxy._run
    super.test_factoryWithInitializers();
  }

  @override
  @failingTest
  void test_fieldInitializerOutsideConstructor() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR, found 0
    super.test_fieldInitializerOutsideConstructor();
  }

  @override
  @failingTest
  void test_functionTypedParameter_const() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.FUNCTION_TYPED_PARAMETER_VAR, found 0;
    // 0 errors of type ParserErrorCode.EXTRANEOUS_MODIFIER, found 1 (8)
    super.test_functionTypedParameter_const();
  }

  @override
  @failingTest
  void test_functionTypedParameter_final() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.FUNCTION_TYPED_PARAMETER_VAR, found 0
    super.test_functionTypedParameter_final();
  }

  @override
  @failingTest
  void test_functionTypedParameter_incomplete1() {
    // TODO(brianwilkerson) Does not recover.
    //   type 'FormalParameterListImpl' is not a subtype of type 'TypeParameterList' of 'typeParameters' where
    //   FormalParameterListImpl is from package:analyzer/src/dart/ast/ast.dart
    //   TypeParameterList is from package:analyzer/dart/ast/ast.dart
    //
    //   package:analyzer/src/fasta/ast_builder.dart 1122:40                AstBuilder.endTopLevelMethod
    //   package:front_end/src/fasta/parser/parser.dart 1741:14             Parser.parseTopLevelMethod
    //   package:front_end/src/fasta/parser/parser.dart 1646:11             Parser.parseTopLevelMember
    //   package:front_end/src/fasta/parser/parser.dart 298:14              Parser._parseTopLevelDeclaration
    //   package:front_end/src/fasta/parser/parser.dart 263:13              Parser.parseTopLevelDeclaration
    //   package:front_end/src/fasta/parser/parser.dart 252:15              Parser.parseUnit
    //   package:analyzer/src/generated/parser_fasta.dart 77:33             _Parser2.parseCompilationUnit2
    //   package:analyzer/src/generated/parser_fasta.dart 72:12             _Parser2.parseCompilationUnit
    //   test/generated/parser_fasta_test.dart 2543:35                      FastaParserTestCase.parseCompilationUnit
    super.test_functionTypedParameter_incomplete1();
  }

  @override
  @failingTest
  void test_functionTypedParameter_var() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.FUNCTION_TYPED_PARAMETER_VAR, found 0
    super.test_functionTypedParameter_var();
  }

  @override
  @failingTest
  void test_genericFunctionType_extraLessThan() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.UNEXPECTED_TOKEN, found 0;
    // 0 errors of type ParserErrorCode.EXTRANEOUS_MODIFIER, found 1 (52)
    super.test_genericFunctionType_extraLessThan();
  }

  @override
  @failingTest
  void test_getterInFunction_block_noReturnType() {
    // TODO(brianwilkerson) Does not recover.
    //   type 'ExpressionStatementImpl' is not a subtype of type 'FunctionDeclarationStatement' of 'statement' where
    //   ExpressionStatementImpl is from package:analyzer/src/dart/ast/ast.dart
    //   FunctionDeclarationStatement is from package:analyzer/dart/ast/ast.dart
    //
    //   test/generated/parser_test.dart 3019:9                             FastaParserTestCase&ErrorParserTestMixin.test_getterInFunction_block_noReturnType
    super.test_getterInFunction_block_noReturnType();
  }

  @override
  @failingTest
  void test_getterInFunction_block_returnType() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.GETTER_IN_FUNCTION, found 0
    super.test_getterInFunction_block_returnType();
  }

  @override
  @failingTest
  void test_getterInFunction_expression_noReturnType() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.GETTER_IN_FUNCTION, found 0
    super.test_getterInFunction_expression_noReturnType();
  }

  @override
  @failingTest
  void test_getterInFunction_expression_returnType() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.GETTER_IN_FUNCTION, found 0
    super.test_getterInFunction_expression_returnType();
  }

  void test_getterNativeWithBody() {
    createParser('String get m native "str" => 0;');
    parser.parseClassMember('C') as MethodDeclaration;
    if (!allowNativeClause) {
      assertErrorsWithCodes([
        ParserErrorCode.NATIVE_CLAUSE_SHOULD_BE_ANNOTATION,
        ParserErrorCode.EXTERNAL_METHOD_WITH_BODY,
      ]);
    } else {
      assertErrorsWithCodes([
        ParserErrorCode.EXTERNAL_METHOD_WITH_BODY,
      ]);
    }
  }

  @override
  @failingTest
  void test_illegalAssignmentToNonAssignable_postfix_minusMinus_literal() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE, found 0
    super.test_illegalAssignmentToNonAssignable_postfix_minusMinus_literal();
  }

  @override
  @failingTest
  void test_illegalAssignmentToNonAssignable_postfix_plusPlus_literal() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE, found 0
    super.test_illegalAssignmentToNonAssignable_postfix_plusPlus_literal();
  }

  @override
  @failingTest
  void test_illegalAssignmentToNonAssignable_postfix_plusPlus_parenthesized() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE, found 0
    super
        .test_illegalAssignmentToNonAssignable_postfix_plusPlus_parenthesized();
  }

  @override
  @failingTest
  void test_illegalAssignmentToNonAssignable_primarySelectorPostfix() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE, found 0
    super.test_illegalAssignmentToNonAssignable_primarySelectorPostfix();
  }

  @override
  @failingTest
  void test_illegalAssignmentToNonAssignable_superAssigned() {
    // TODO(brianwilkerson) Does not recover.
    //   Expected: true
    //   Actual: <false>
    //
    //   package:test                                                       expect
    //   test/generated/parser_fasta_test.dart 3157:5                       ParserProxy._run
    super.test_illegalAssignmentToNonAssignable_superAssigned();
  }

  @override
  @failingTest
  void test_illegalAssignmentToNonAssignable_superAssigned_failing() {
    // TODO(brianwilkerson) Does not recover.
    //   Expected: true
    //   Actual: <false>
    //
    //   package:test                                                       expect
    //   test/generated/parser_fasta_test.dart 3157:5                       ParserProxy._run
    super.test_illegalAssignmentToNonAssignable_superAssigned_failing();
  }

  @override
  @failingTest
  void test_initializedVariableInForEach() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.INITIALIZED_VARIABLE_IN_FOR_EACH, found 0
    super.test_initializedVariableInForEach();
  }

  @override
  @failingTest
  void test_invalidCodePoint() {
    // TODO(brianwilkerson) Does not recover.
    //   Internal problem: Compiler cannot run without a compiler context.
    //   Tip: Are calls to the compiler wrapped in CompilerContext.runInContext?
    //   package:front_end/src/fasta/compiler_context.dart 81:7             CompilerContext.current
    //   package:front_end/src/fasta/command_line_reporting.dart 112:30     shouldThrowOn
    //   package:front_end/src/fasta/deprecated_problems.dart 41:7          deprecated_inputError
    //   package:front_end/src/fasta/quote.dart 181:5                       unescapeCodeUnits.error
    //   package:front_end/src/fasta/quote.dart 251:40                      unescapeCodeUnits
    //   package:front_end/src/fasta/quote.dart 147:13                      unescape
    //   package:front_end/src/fasta/quote.dart 135:10                      unescapeString
    //   package:analyzer/src/fasta/ast_builder.dart 159:22                 AstBuilder.endLiteralString
    //   test/generated/parser_fasta_listener.dart 896:14                   ForwardingTestListener.endLiteralString
    //   package:front_end/src/fasta/parser/parser.dart 3497:14             Parser.parseSingleLiteralString
    //   package:front_end/src/fasta/parser/parser.dart 3434:13             Parser.parseLiteralString
    //   package:front_end/src/fasta/parser/parser.dart 3133:14             Parser.parsePrimary
    //   package:front_end/src/fasta/parser/parser.dart 3097:14             Parser.parseUnaryExpression
    //   package:front_end/src/fasta/parser/parser.dart 2968:13             Parser.parsePrecedenceExpression
    //   package:front_end/src/fasta/parser/parser.dart 2942:11             Parser.parseExpression
    //   test/generated/parser_fasta_test.dart 3196:39                      ParserProxy._run
    super.test_invalidCodePoint();
  }

  @override
  @failingTest
  void test_invalidCommentReference__new_nonIdentifier() {
    // TODO(brianwilkerson) Parsing comment references not yet supported.
    super.test_invalidCommentReference__new_nonIdentifier();
  }

  @override
  @failingTest
  void test_invalidCommentReference__new_tooMuch() {
    // TODO(brianwilkerson) Parsing comment references not yet supported.
    super.test_invalidCommentReference__new_tooMuch();
  }

  @override
  @failingTest
  void test_invalidCommentReference__nonNew_nonIdentifier() {
    // TODO(brianwilkerson) Parsing comment references not yet supported.
    super.test_invalidCommentReference__nonNew_nonIdentifier();
  }

  @override
  @failingTest
  void test_invalidCommentReference__nonNew_tooMuch() {
    // TODO(brianwilkerson) Parsing comment references not yet supported.
    super.test_invalidCommentReference__nonNew_tooMuch();
  }

  @override
  @failingTest
  void test_invalidConstructorName_with() {
    // TODO(brianwilkerson) Does not recover.
    //   type 'DeclaredSimpleIdentifier' is not a subtype of type 'TypeAnnotation' of 'returnType' where
    //   DeclaredSimpleIdentifier is from package:analyzer/src/dart/ast/ast.dart
    //   TypeAnnotation is from package:analyzer/dart/ast/ast.dart
    //
    //   package:analyzer/src/fasta/ast_builder.dart 1620:33                AstBuilder.endMethod
    //   test/generated/parser_fasta_listener.dart 926:14                   ForwardingTestListener.endMethod
    //   package:front_end/src/fasta/parser/parser.dart 2433:14             Parser.parseMethod
    //   package:front_end/src/fasta/parser/parser.dart 2323:11             Parser.parseMember
    //   test/generated/parser_fasta_test.dart 3179:39                      ParserProxy._run
    super.test_invalidConstructorName_with();
  }

  @override
  @failingTest
  void test_invalidHexEscape_invalidDigit() {
    // TODO(brianwilkerson) Does not recover.
    //   Internal problem: Compiler cannot run without a compiler context.
    //   Tip: Are calls to the compiler wrapped in CompilerContext.runInContext?
    //   package:front_end/src/fasta/compiler_context.dart 81:7             CompilerContext.current
    //   package:front_end/src/fasta/command_line_reporting.dart 112:30     shouldThrowOn
    //   package:front_end/src/fasta/deprecated_problems.dart 41:7          deprecated_inputError
    //   package:front_end/src/fasta/quote.dart 181:5                       unescapeCodeUnits.error
    //   package:front_end/src/fasta/quote.dart 221:47                      unescapeCodeUnits
    //   package:front_end/src/fasta/quote.dart 147:13                      unescape
    //   package:front_end/src/fasta/quote.dart 135:10                      unescapeString
    //   package:analyzer/src/fasta/ast_builder.dart 159:22                 AstBuilder.endLiteralString
    //   test/generated/parser_fasta_listener.dart 896:14                   ForwardingTestListener.endLiteralString
    //   package:front_end/src/fasta/parser/parser.dart 3497:14             Parser.parseSingleLiteralString
    //   package:front_end/src/fasta/parser/parser.dart 3434:13             Parser.parseLiteralString
    //   package:front_end/src/fasta/parser/parser.dart 3133:14             Parser.parsePrimary
    //   package:front_end/src/fasta/parser/parser.dart 3097:14             Parser.parseUnaryExpression
    //   package:front_end/src/fasta/parser/parser.dart 2968:13             Parser.parsePrecedenceExpression
    //   package:front_end/src/fasta/parser/parser.dart 2942:11             Parser.parseExpression
    //   test/generated/parser_fasta_test.dart 3196:39                      ParserProxy._run
    super.test_invalidHexEscape_invalidDigit();
  }

  @override
  @failingTest
  void test_invalidHexEscape_tooFewDigits() {
    // TODO(brianwilkerson) Does not recover.
    //   Internal problem: Compiler cannot run without a compiler context.
    //   Tip: Are calls to the compiler wrapped in CompilerContext.runInContext?
    //   package:front_end/src/fasta/compiler_context.dart 81:7             CompilerContext.current
    //   package:front_end/src/fasta/command_line_reporting.dart 112:30     shouldThrowOn
    //   package:front_end/src/fasta/deprecated_problems.dart 41:7          deprecated_inputError
    //   package:front_end/src/fasta/quote.dart 181:5                       unescapeCodeUnits.error
    //   package:front_end/src/fasta/quote.dart 217:52                      unescapeCodeUnits
    //   package:front_end/src/fasta/quote.dart 147:13                      unescape
    //   package:front_end/src/fasta/quote.dart 135:10                      unescapeString
    //   package:analyzer/src/fasta/ast_builder.dart 159:22                 AstBuilder.endLiteralString
    //   test/generated/parser_fasta_listener.dart 896:14                   ForwardingTestListener.endLiteralString
    //   package:front_end/src/fasta/parser/parser.dart 3497:14             Parser.parseSingleLiteralString
    //   package:front_end/src/fasta/parser/parser.dart 3434:13             Parser.parseLiteralString
    //   package:front_end/src/fasta/parser/parser.dart 3133:14             Parser.parsePrimary
    //   package:front_end/src/fasta/parser/parser.dart 3097:14             Parser.parseUnaryExpression
    //   package:front_end/src/fasta/parser/parser.dart 2968:13             Parser.parsePrecedenceExpression
    //   package:front_end/src/fasta/parser/parser.dart 2942:11             Parser.parseExpression
    //   test/generated/parser_fasta_test.dart 3196:39                      ParserProxy._run
    super.test_invalidHexEscape_tooFewDigits();
  }

  @override
  @failingTest
  void test_invalidInterpolationIdentifier_startWithDigit() {
    // TODO(brianwilkerson) Does not recover.
    //   RangeError: Value not in range: -1
    //   dart:core                                                          _StringBase.substring
    //   package:front_end/src/fasta/quote.dart 130:12                      unescapeLastStringPart
    //   package:analyzer/src/fasta/ast_builder.dart 181:17                 AstBuilder.endLiteralString
    //   test/generated/parser_fasta_listener.dart 896:14                   ForwardingTestListener.endLiteralString
    //   package:front_end/src/fasta/parser/parser.dart 3497:14             Parser.parseSingleLiteralString
    //   package:front_end/src/fasta/parser/parser.dart 3434:13             Parser.parseLiteralString
    //   package:front_end/src/fasta/parser/parser.dart 3133:14             Parser.parsePrimary
    //   package:front_end/src/fasta/parser/parser.dart 3097:14             Parser.parseUnaryExpression
    //   package:front_end/src/fasta/parser/parser.dart 2968:13             Parser.parsePrecedenceExpression
    //   package:front_end/src/fasta/parser/parser.dart 2942:11             Parser.parseExpression
    //   test/generated/parser_fasta_test.dart 3196:39                      ParserProxy._run
    super.test_invalidInterpolationIdentifier_startWithDigit();
  }

  @override
  @failingTest
  void test_invalidLiteralInConfiguration() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.INVALID_LITERAL_IN_CONFIGURATION, found 0
    super.test_invalidLiteralInConfiguration();
  }

  @override
  @failingTest
  void test_invalidOperator() {
    // TODO(brianwilkerson) Does not recover.
    //   type 'SimpleIdentifierImpl' is not a subtype of type 'TypeAnnotation' of 'returnType' where
    //   SimpleIdentifierImpl is from package:analyzer/src/dart/ast/ast.dart
    //   TypeAnnotation is from package:analyzer/dart/ast/ast.dart
    //
    //   package:analyzer/src/fasta/ast_builder.dart 1620:33                AstBuilder.endMethod
    //   test/generated/parser_fasta_listener.dart 926:14                   ForwardingTestListener.endMethod
    //   package:front_end/src/fasta/parser/parser.dart 2433:14             Parser.parseMethod
    //   package:front_end/src/fasta/parser/parser.dart 2323:11             Parser.parseMember
    //   test/generated/parser_fasta_test.dart 3196:39                      ParserProxy._run
    super.test_invalidOperator();
  }

  @override
  @failingTest
  void test_invalidOperatorAfterSuper_assignableExpression() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.INVALID_OPERATOR_FOR_SUPER, found 0
    super.test_invalidOperatorAfterSuper_assignableExpression();
  }

  @override
  @failingTest
  void test_invalidOperatorAfterSuper_primaryExpression() {
    // TODO(brianwilkerson) Does not recover.
    //   Expected: true
    //   Actual: <false>
    //
    //   package:test                                                       expect
    //   test/generated/parser_fasta_test.dart 3197:5                       ParserProxy._run
    super.test_invalidOperatorAfterSuper_primaryExpression();
  }

  @override
  @failingTest
  void test_invalidOperatorForSuper() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.INVALID_OPERATOR_FOR_SUPER, found 0
    super.test_invalidOperatorForSuper();
  }

  @override
  @failingTest
  void test_invalidStarAfterAsync() {
    // TODO(brianwilkerson) Does not recover.
    //   Expected: an object with length of <1>
    //   Actual: <Instance of 'Stack'>
    //   Which: has length of <0>
    //
    //   package:test                                                       expect
    //   test/generated/parser_fasta_test.dart 3290:7                       ParserProxy._run
    super.test_invalidStarAfterAsync();
  }

  @override
  @failingTest
  void test_invalidSync() {
    // TODO(brianwilkerson) Does not recover.
    //   Expected: an object with length of <1>
    //   Actual: <Instance of 'Stack'>
    //   Which: has length of <0>
    //
    //   package:test                                                       expect
    //   test/generated/parser_fasta_test.dart 3290:7                       ParserProxy._run
    super.test_invalidSync();
  }

  @override
  @failingTest
  void test_invalidTopLevelVar() {
    // TODO(danrubel) Does not recover.
    //  'package:analyzer/src/fasta/ast_builder.dart': Failed assertion:
    //      line 238 pos 12: 'token.isKeywordOrIdentifier': is not true.
    //  dart:core-patch/errors_patch.dart 35                               _AssertionError._doThrowNew
    //  dart:core-patch/errors_patch.dart 31                               _AssertionError._throwNew
    //  package:analyzer/src/fasta/ast_builder.dart 238:12                 AstBuilder.handleIdentifier
    //  package:front_end/src/fasta/parser/parser.dart 1639:14             Parser.ensureIdentifier
    //  package:front_end/src/fasta/parser/parser.dart 2594:13             Parser.parseFields
    //  package:front_end/src/fasta/parser/parser.dart 2565:11             Parser.parseTopLevelMember
    //  package:front_end/src/fasta/parser/parser.dart 377:14              Parser.parseTopLevelDeclarationImpl
    //  package:front_end/src/fasta/parser/parser.dart 300:15              Parser.parseUnit
    //  package:analyzer/src/generated/parser_fasta.dart 85:33             _Parser2.parseCompilationUnit2
    super.test_invalidTopLevelVar();
  }

  @failingTest
  void test_invalidTypedef() {
    // TODO(danrubel) Does not recover.
    //  'package:analyzer/src/fasta/ast_builder.dart': Failed assertion:
    //      line 238 pos 12: 'token.isKeywordOrIdentifier': is not true.
    //  dart:core-patch/errors_patch.dart 35                               _AssertionError._doThrowNew
    //  dart:core-patch/errors_patch.dart 31                               _AssertionError._throwNew
    //  package:analyzer/src/fasta/ast_builder.dart 238:12                 AstBuilder.handleIdentifier
    //  package:front_end/src/fasta/parser/parser.dart 1639:14             Parser.ensureIdentifier
    //  package:front_end/src/fasta/parser/parser.dart 2594:13             Parser.parseFields
    //  package:front_end/src/fasta/parser/parser.dart 2565:11             Parser.parseTopLevelMember
    //  package:front_end/src/fasta/parser/parser.dart 377:14              Parser.parseTopLevelDeclarationImpl
    //  package:front_end/src/fasta/parser/parser.dart 300:15              Parser.parseUnit
    //  package:analyzer/src/generated/parser_fasta.dart 85:33             _Parser2.parseCompilationUnit2
    super.test_invalidTypedef();
  }

  @override
  @failingTest
  void test_invalidUnicodeEscape_incomplete_noDigits() {
    // TODO(brianwilkerson) Does not recover.
    //   Internal problem: Compiler cannot run without a compiler context.
    //   Tip: Are calls to the compiler wrapped in CompilerContext.runInContext?
    //   package:front_end/src/fasta/compiler_context.dart 81:7             CompilerContext.current
    //   package:front_end/src/fasta/command_line_reporting.dart 112:30     shouldThrowOn
    //   package:front_end/src/fasta/deprecated_problems.dart 41:7          deprecated_inputError
    //   package:front_end/src/fasta/quote.dart 181:5                       unescapeCodeUnits.error
    //   package:front_end/src/fasta/quote.dart 232:54                      unescapeCodeUnits
    //   package:front_end/src/fasta/quote.dart 147:13                      unescape
    //   package:front_end/src/fasta/quote.dart 135:10                      unescapeString
    //   package:analyzer/src/fasta/ast_builder.dart 159:22                 AstBuilder.endLiteralString
    //   test/generated/parser_fasta_listener.dart 896:14                   ForwardingTestListener.endLiteralString
    //   package:front_end/src/fasta/parser/parser.dart 3497:14             Parser.parseSingleLiteralString
    //   package:front_end/src/fasta/parser/parser.dart 3434:13             Parser.parseLiteralString
    //   package:front_end/src/fasta/parser/parser.dart 3133:14             Parser.parsePrimary
    //   package:front_end/src/fasta/parser/parser.dart 3097:14             Parser.parseUnaryExpression
    //   package:front_end/src/fasta/parser/parser.dart 2968:13             Parser.parsePrecedenceExpression
    //   package:front_end/src/fasta/parser/parser.dart 2942:11             Parser.parseExpression
    //   package:front_end/src/fasta/parser/parser.dart 2862:13             Parser.parseExpressionStatement
    //   package:front_end/src/fasta/parser/parser.dart 2790:14             Parser.parseStatementX
    //   package:front_end/src/fasta/parser/parser.dart 2722:20             Parser.parseStatement
    //   test/generated/parser_fasta_test.dart 3287:39                      ParserProxy._run
    super.test_invalidUnicodeEscape_incomplete_noDigits();
  }

  @override
  @failingTest
  void test_invalidUnicodeEscape_incomplete_someDigits() {
    // TODO(brianwilkerson) Does not recover.
    //   Internal problem: Compiler cannot run without a compiler context.
    //   Tip: Are calls to the compiler wrapped in CompilerContext.runInContext?
    //   package:front_end/src/fasta/compiler_context.dart 81:7             CompilerContext.current
    //   package:front_end/src/fasta/command_line_reporting.dart 112:30     shouldThrowOn
    //   package:front_end/src/fasta/deprecated_problems.dart 41:7          deprecated_inputError
    //   package:front_end/src/fasta/quote.dart 181:5                       unescapeCodeUnits.error
    //   package:front_end/src/fasta/quote.dart 232:54                      unescapeCodeUnits
    //   package:front_end/src/fasta/quote.dart 147:13                      unescape
    //   package:front_end/src/fasta/quote.dart 135:10                      unescapeString
    //   package:analyzer/src/fasta/ast_builder.dart 159:22                 AstBuilder.endLiteralString
    //   test/generated/parser_fasta_listener.dart 896:14                   ForwardingTestListener.endLiteralString
    //   package:front_end/src/fasta/parser/parser.dart 3497:14             Parser.parseSingleLiteralString
    //   package:front_end/src/fasta/parser/parser.dart 3434:13             Parser.parseLiteralString
    //   package:front_end/src/fasta/parser/parser.dart 3133:14             Parser.parsePrimary
    //   package:front_end/src/fasta/parser/parser.dart 3097:14             Parser.parseUnaryExpression
    //   package:front_end/src/fasta/parser/parser.dart 2968:13             Parser.parsePrecedenceExpression
    //   package:front_end/src/fasta/parser/parser.dart 2942:11             Parser.parseExpression
    //   package:front_end/src/fasta/parser/parser.dart 2862:13             Parser.parseExpressionStatement
    //   package:front_end/src/fasta/parser/parser.dart 2790:14             Parser.parseStatementX
    //   package:front_end/src/fasta/parser/parser.dart 2722:20             Parser.parseStatement
    //   test/generated/parser_fasta_test.dart 3287:39                      ParserProxy._run
    super.test_invalidUnicodeEscape_incomplete_someDigits();
  }

  @override
  @failingTest
  void test_invalidUnicodeEscape_invalidDigit() {
    // TODO(brianwilkerson) Does not recover.
    //   Internal problem: Compiler cannot run without a compiler context.
    //   Tip: Are calls to the compiler wrapped in CompilerContext.runInContext?
    //   package:front_end/src/fasta/compiler_context.dart 81:7             CompilerContext.current
    //   package:front_end/src/fasta/command_line_reporting.dart 112:30     shouldThrowOn
    //   package:front_end/src/fasta/deprecated_problems.dart 41:7          deprecated_inputError
    //   package:front_end/src/fasta/quote.dart 181:5                       unescapeCodeUnits.error
    //   package:front_end/src/fasta/quote.dart 240:54                      unescapeCodeUnits
    //   package:front_end/src/fasta/quote.dart 147:13                      unescape
    //   package:front_end/src/fasta/quote.dart 135:10                      unescapeString
    //   package:analyzer/src/fasta/ast_builder.dart 159:22                 AstBuilder.endLiteralString
    //   test/generated/parser_fasta_listener.dart 896:14                   ForwardingTestListener.endLiteralString
    //   package:front_end/src/fasta/parser/parser.dart 3497:14             Parser.parseSingleLiteralString
    //   package:front_end/src/fasta/parser/parser.dart 3434:13             Parser.parseLiteralString
    //   package:front_end/src/fasta/parser/parser.dart 3133:14             Parser.parsePrimary
    //   package:front_end/src/fasta/parser/parser.dart 3097:14             Parser.parseUnaryExpression
    //   package:front_end/src/fasta/parser/parser.dart 2968:13             Parser.parsePrecedenceExpression
    //   package:front_end/src/fasta/parser/parser.dart 2942:11             Parser.parseExpression
    //   package:front_end/src/fasta/parser/parser.dart 2862:13             Parser.parseExpressionStatement
    //   package:front_end/src/fasta/parser/parser.dart 2790:14             Parser.parseStatementX
    //   package:front_end/src/fasta/parser/parser.dart 2722:20             Parser.parseStatement
    //   test/generated/parser_fasta_test.dart 3287:39                      ParserProxy._run
    super.test_invalidUnicodeEscape_invalidDigit();
  }

  @override
  @failingTest
  void test_invalidUnicodeEscape_tooFewDigits_fixed() {
    // TODO(brianwilkerson) Does not recover.
    //   Internal problem: Compiler cannot run without a compiler context.
    //   Tip: Are calls to the compiler wrapped in CompilerContext.runInContext?
    //   package:front_end/src/fasta/compiler_context.dart 81:7             CompilerContext.current
    //   package:front_end/src/fasta/command_line_reporting.dart 112:30     shouldThrowOn
    //   package:front_end/src/fasta/deprecated_problems.dart 41:7          deprecated_inputError
    //   package:front_end/src/fasta/quote.dart 181:5                       unescapeCodeUnits.error
    //   package:front_end/src/fasta/quote.dart 240:54                      unescapeCodeUnits
    //   package:front_end/src/fasta/quote.dart 147:13                      unescape
    //   package:front_end/src/fasta/quote.dart 135:10                      unescapeString
    //   package:analyzer/src/fasta/ast_builder.dart 159:22                 AstBuilder.endLiteralString
    //   test/generated/parser_fasta_listener.dart 896:14                   ForwardingTestListener.endLiteralString
    //   package:front_end/src/fasta/parser/parser.dart 3497:14             Parser.parseSingleLiteralString
    //   package:front_end/src/fasta/parser/parser.dart 3434:13             Parser.parseLiteralString
    //   package:front_end/src/fasta/parser/parser.dart 3133:14             Parser.parsePrimary
    //   package:front_end/src/fasta/parser/parser.dart 3097:14             Parser.parseUnaryExpression
    //   package:front_end/src/fasta/parser/parser.dart 2968:13             Parser.parsePrecedenceExpression
    //   package:front_end/src/fasta/parser/parser.dart 2942:11             Parser.parseExpression
    //   package:front_end/src/fasta/parser/parser.dart 2862:13             Parser.parseExpressionStatement
    //   package:front_end/src/fasta/parser/parser.dart 2790:14             Parser.parseStatementX
    //   package:front_end/src/fasta/parser/parser.dart 2722:20             Parser.parseStatement
    //   test/generated/parser_fasta_test.dart 3287:39                      ParserProxy._run
    super.test_invalidUnicodeEscape_tooFewDigits_fixed();
  }

  @override
  @failingTest
  void test_invalidUnicodeEscape_tooFewDigits_variable() {
    // TODO(brianwilkerson) Does not recover.
    //   Internal problem: Compiler cannot run without a compiler context.
    //   Tip: Are calls to the compiler wrapped in CompilerContext.runInContext?
    //   package:front_end/src/fasta/compiler_context.dart 81:7             CompilerContext.current
    //   package:front_end/src/fasta/command_line_reporting.dart 112:30     shouldThrowOn
    //   package:front_end/src/fasta/deprecated_problems.dart 41:7          deprecated_inputError
    //   package:front_end/src/fasta/quote.dart 181:5                       unescapeCodeUnits.error
    //   package:front_end/src/fasta/quote.dart 235:49                      unescapeCodeUnits
    //   package:front_end/src/fasta/quote.dart 147:13                      unescape
    //   package:front_end/src/fasta/quote.dart 135:10                      unescapeString
    //   package:analyzer/src/fasta/ast_builder.dart 159:22                 AstBuilder.endLiteralString
    //   test/generated/parser_fasta_listener.dart 896:14                   ForwardingTestListener.endLiteralString
    //   package:front_end/src/fasta/parser/parser.dart 3497:14             Parser.parseSingleLiteralString
    //   package:front_end/src/fasta/parser/parser.dart 3434:13             Parser.parseLiteralString
    //   package:front_end/src/fasta/parser/parser.dart 3133:14             Parser.parsePrimary
    //   package:front_end/src/fasta/parser/parser.dart 3097:14             Parser.parseUnaryExpression
    //   package:front_end/src/fasta/parser/parser.dart 2968:13             Parser.parsePrecedenceExpression
    //   package:front_end/src/fasta/parser/parser.dart 2942:11             Parser.parseExpression
    //   package:front_end/src/fasta/parser/parser.dart 2862:13             Parser.parseExpressionStatement
    //   package:front_end/src/fasta/parser/parser.dart 2790:14             Parser.parseStatementX
    //   package:front_end/src/fasta/parser/parser.dart 2722:20             Parser.parseStatement
    //   test/generated/parser_fasta_test.dart 3287:39                      ParserProxy._run
    super.test_invalidUnicodeEscape_tooFewDigits_variable();
  }

  @override
  @failingTest
  void test_invalidUnicodeEscape_tooManyDigits_variable() {
    // TODO(brianwilkerson) Does not recover.
    //   Internal problem: Compiler cannot run without a compiler context.
    //   Tip: Are calls to the compiler wrapped in CompilerContext.runInContext?
    //   package:front_end/src/fasta/compiler_context.dart 81:7             CompilerContext.current
    //   package:front_end/src/fasta/command_line_reporting.dart 112:30     shouldThrowOn
    //   package:front_end/src/fasta/deprecated_problems.dart 41:7          deprecated_inputError
    //   package:front_end/src/fasta/quote.dart 181:5                       unescapeCodeUnits.error
    //   package:front_end/src/fasta/quote.dart 251:40                      unescapeCodeUnits
    //   package:front_end/src/fasta/quote.dart 147:13                      unescape
    //   package:front_end/src/fasta/quote.dart 135:10                      unescapeString
    //   package:analyzer/src/fasta/ast_builder.dart 159:22                 AstBuilder.endLiteralString
    //   test/generated/parser_fasta_listener.dart 896:14                   ForwardingTestListener.endLiteralString
    //   package:front_end/src/fasta/parser/parser.dart 3497:14             Parser.parseSingleLiteralString
    //   package:front_end/src/fasta/parser/parser.dart 3434:13             Parser.parseLiteralString
    //   package:front_end/src/fasta/parser/parser.dart 3133:14             Parser.parsePrimary
    //   package:front_end/src/fasta/parser/parser.dart 3097:14             Parser.parseUnaryExpression
    //   package:front_end/src/fasta/parser/parser.dart 2968:13             Parser.parsePrecedenceExpression
    //   package:front_end/src/fasta/parser/parser.dart 2942:11             Parser.parseExpression
    //   package:front_end/src/fasta/parser/parser.dart 2862:13             Parser.parseExpressionStatement
    //   package:front_end/src/fasta/parser/parser.dart 2790:14             Parser.parseStatementX
    //   package:front_end/src/fasta/parser/parser.dart 2722:20             Parser.parseStatement
    //   test/generated/parser_fasta_test.dart 3287:39                      ParserProxy._run
    super.test_invalidUnicodeEscape_tooManyDigits_variable();
  }

  @override
  @failingTest
  void test_localFunctionDeclarationModifier_abstract() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.LOCAL_FUNCTION_DECLARATION_MODIFIER, found 0
    super.test_localFunctionDeclarationModifier_abstract();
  }

  @override
  @failingTest
  void test_localFunctionDeclarationModifier_external() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.LOCAL_FUNCTION_DECLARATION_MODIFIER, found 0
    super.test_localFunctionDeclarationModifier_external();
  }

  @override
  @failingTest
  void test_localFunctionDeclarationModifier_factory() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.LOCAL_FUNCTION_DECLARATION_MODIFIER, found 0
    super.test_localFunctionDeclarationModifier_factory();
  }

  @override
  @failingTest
  void test_localFunctionDeclarationModifier_static() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.LOCAL_FUNCTION_DECLARATION_MODIFIER, found 0
    super.test_localFunctionDeclarationModifier_static();
  }

  @override
  @failingTest
  void test_method_invalidTypeParameterComments() {
    // TODO(brianwilkerson) Does not recover.
    //   type 'DeclaredSimpleIdentifier' is not a subtype of type 'TypeAnnotation' of 'returnType' where
    //   DeclaredSimpleIdentifier is from package:analyzer/src/dart/ast/ast.dart
    //   TypeAnnotation is from package:analyzer/dart/ast/ast.dart
    //
    //   package:analyzer/src/fasta/ast_builder.dart 1620:33                AstBuilder.endMethod
    //   test/generated/parser_fasta_listener.dart 926:14                   ForwardingTestListener.endMethod
    //   package:front_end/src/fasta/parser/parser.dart 2433:14             Parser.parseMethod
    //   package:front_end/src/fasta/parser/parser.dart 2323:11             Parser.parseMember
    //   test/generated/parser_fasta_test.dart 3438:39                      ParserProxy._run
    super.test_method_invalidTypeParameterComments();
  }

  @override
  @failingTest
  void test_method_invalidTypeParameterExtends() {
    // TODO(brianwilkerson) Does not recover.
    //   type 'FormalParameterListImpl' is not a subtype of type 'TypeParameterList' of 'typeParameters' where
    //   FormalParameterListImpl is from package:analyzer/src/dart/ast/ast.dart
    //   TypeParameterList is from package:analyzer/dart/ast/ast.dart
    //
    //   package:analyzer/src/fasta/ast_builder.dart 1618:40                AstBuilder.endMethod
    //   test/generated/parser_fasta_listener.dart 926:14                   ForwardingTestListener.endMethod
    //   package:front_end/src/fasta/parser/parser.dart 2433:14             Parser.parseMethod
    //   package:front_end/src/fasta/parser/parser.dart 2323:11             Parser.parseMember
    //   test/generated/parser_fasta_test.dart 3438:39                      ParserProxy._run
    super.test_method_invalidTypeParameterExtends();
  }

  @override
  @failingTest
  void test_method_invalidTypeParameterExtendsComment() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 2 errors of type ParserErrorCode.EXPECTED_TOKEN, found 0;
    // 2 errors of type ParserErrorCode.MISSING_IDENTIFIER, found 0;
    // 1 errors of type ParserErrorCode.MISSING_FUNCTION_BODY, found 0
    super.test_method_invalidTypeParameterExtendsComment();
  }

  @override
  @failingTest
  void test_method_invalidTypeParameters() {
    // TODO(brianwilkerson) Does not recover.
    //   type 'DeclaredSimpleIdentifier' is not a subtype of type 'TypeAnnotation' of 'returnType' where
    //   DeclaredSimpleIdentifier is from package:analyzer/src/dart/ast/ast.dart
    //   TypeAnnotation is from package:analyzer/dart/ast/ast.dart
    //
    //   package:analyzer/src/fasta/ast_builder.dart 1620:33                AstBuilder.endMethod
    //   test/generated/parser_fasta_listener.dart 926:14                   ForwardingTestListener.endMethod
    //   package:front_end/src/fasta/parser/parser.dart 2433:14             Parser.parseMethod
    //   package:front_end/src/fasta/parser/parser.dart 2323:11             Parser.parseMember
    //   test/generated/parser_fasta_test.dart 3438:39                      ParserProxy._run
    super.test_method_invalidTypeParameters();
  }

  @override
  @failingTest
  void test_missingAssignableSelector_identifiersAssigned() {
    // TODO(brianwilkerson) Does not recover.
    //   Expected: true
    //   Actual: <false>
    //
    //   package:test                                                       expect
    //   test/generated/parser_fasta_test.dart 3439:5                       ParserProxy._run
    super.test_missingAssignableSelector_identifiersAssigned();
  }

  @override
  @failingTest
  void test_missingAssignableSelector_prefix_minusMinus_literal() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, found 0
    super.test_missingAssignableSelector_prefix_minusMinus_literal();
  }

  @override
  @failingTest
  void test_missingAssignableSelector_prefix_plusPlus_literal() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, found 0
    super.test_missingAssignableSelector_prefix_plusPlus_literal();
  }

  @override
  @failingTest
  void test_missingAssignableSelector_superPrimaryExpression() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, found 0
    super.test_missingAssignableSelector_superPrimaryExpression();
  }

  @override
  @failingTest
  void test_missingAssignableSelector_superPropertyAccessAssigned() {
    // TODO(brianwilkerson) Does not recover.
    //   Expected: true
    //   Actual: <false>
    //
    //   package:test                                                       expect
    //   test/generated/parser_fasta_test.dart 3488:5                       ParserProxy._run
    super.test_missingAssignableSelector_superPropertyAccessAssigned();
  }

  @override
  @failingTest
  void test_missingClosingParenthesis() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ScannerErrorCode.EXPECTED_TOKEN, found 0
    super.test_missingClosingParenthesis();
  }

  @override
  @failingTest
  void test_missingEnumBody() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.MISSING_ENUM_BODY, found 0
    super.test_missingEnumBody();
  }

  @override
  @failingTest
  void test_missingExpressionInThrow() {
    // TODO(brianwilkerson) Does not recover.
    //   type 'RethrowExpressionImpl' is not a subtype of type 'ThrowExpression' of 'expression' where
    //   RethrowExpressionImpl is from package:analyzer/src/dart/ast/ast.dart
    //   ThrowExpression is from package:analyzer/dart/ast/ast.dart
    //
    //   test/generated/parser_test.dart 3492:59                            FastaParserTestCase&ErrorParserTestMixin.test_missingExpressionInThrow_withCascade
    super.test_missingExpressionInThrow();
  }

  @override
  @failingTest
  void test_missingFunctionBody_invalid() {
    // TODO(brianwilkerson) Does not recover.
    //   Expected: an object with length of <1>
    //   Actual: <Instance of 'Stack'>
    //   Which: has length of <0>
    //
    //   package:test                                                       expect
    //   test/generated/parser_fasta_test.dart 3506:7                       ParserProxy._run
    super.test_missingFunctionBody_invalid();
  }

  @override
  @failingTest
  void test_missingFunctionParameters_local_nonVoid_block() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.MISSING_FUNCTION_PARAMETERS, found 0
    super.test_missingFunctionParameters_local_nonVoid_block();
  }

  @override
  @failingTest
  void test_missingFunctionParameters_local_nonVoid_expression() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.MISSING_FUNCTION_PARAMETERS, found 0
    super.test_missingFunctionParameters_local_nonVoid_expression();
  }

  @override
  @failingTest
  void test_missingFunctionParameters_local_void_block() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.MISSING_FUNCTION_PARAMETERS, found 0
    super.test_missingFunctionParameters_local_void_block();
  }

  @override
  @failingTest
  void test_missingFunctionParameters_local_void_expression() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.MISSING_FUNCTION_PARAMETERS, found 0
    super.test_missingFunctionParameters_local_void_expression();
  }

  @override
  @failingTest
  void test_missingFunctionParameters_topLevel_void_block() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.MISSING_FUNCTION_PARAMETERS, found 0
    super.test_missingFunctionParameters_topLevel_void_block();
  }

  @override
  @failingTest
  void test_missingFunctionParameters_topLevel_void_expression() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.MISSING_FUNCTION_PARAMETERS, found 0
    super.test_missingFunctionParameters_topLevel_void_expression();
  }

  @override
  @failingTest
  void test_missingIdentifier_afterOperator() {
    // TODO(brianwilkerson) Does not recover.
    //   'package:front_end/src/fasta/source/stack_listener.dart': Failed assertion: line 311 pos 12: 'arrayLength > 0': is not true.
    //   dart:core                                                          _AssertionError._throwNew
    //   package:front_end/src/fasta/source/stack_listener.dart 311:12      Stack.pop
    //   package:front_end/src/fasta/source/stack_listener.dart 95:25       StackListener.pop
    //   package:analyzer/src/fasta/ast_builder.dart 345:25                 AstBuilder.handleBinaryExpression
    //   test/generated/parser_fasta_listener.dart 1127:14                  ForwardingTestListener.handleBinaryExpression
    //   package:front_end/src/fasta/parser/parser.dart 3016:20             Parser.parsePrecedenceExpression
    //   package:front_end/src/fasta/parser/parser.dart 2942:11             Parser.parseExpression
    //   test/generated/parser_fasta_test.dart 3544:39                      ParserProxy._run
    super.test_missingIdentifier_afterOperator();
  }

  @override
  @failingTest
  void test_missingIdentifier_beforeClosingCurly() {
    // TODO(brianwilkerson) Does not recover.
    //   Expected: an object with length of <1>
    //   Actual: <Instance of 'Stack'>
    //   Which: has length of <2>
    //
    //   package:test                                                       expect
    //   test/generated/parser_fasta_test.dart 3547:7                       ParserProxy._run
    super.test_missingIdentifier_beforeClosingCurly();
  }

  @override
  @failingTest
  void test_missingKeywordOperator() {
    // TODO(brianwilkerson) Does not recover.
    //   type 'DeclaredSimpleIdentifier' is not a subtype of type 'TypeAnnotation' of 'returnType' where
    //   DeclaredSimpleIdentifier is from package:analyzer/src/dart/ast/ast.dart
    //   TypeAnnotation is from package:analyzer/dart/ast/ast.dart
    //
    //   package:analyzer/src/fasta/ast_builder.dart 1620:33                AstBuilder.endMethod
    //   test/generated/parser_fasta_listener.dart 926:14                   ForwardingTestListener.endMethod
    //   package:front_end/src/fasta/parser/parser.dart 2433:14             Parser.parseMethod
    //   package:front_end/src/fasta/parser/parser.dart 2323:11             Parser.parseMember
    //   test/generated/parser_fasta_test.dart 3544:39                      ParserProxy._run
    super.test_missingKeywordOperator();
  }

  @override
  @failingTest
  void test_missingKeywordOperator_parseClassMember() {
    // TODO(brianwilkerson) Does not recover.
    //   type 'DeclaredSimpleIdentifier' is not a subtype of type 'TypeAnnotation' of 'returnType' where
    //   DeclaredSimpleIdentifier is from package:analyzer/src/dart/ast/ast.dart
    //   TypeAnnotation is from package:analyzer/dart/ast/ast.dart
    //
    //   package:analyzer/src/fasta/ast_builder.dart 1620:33                AstBuilder.endMethod
    //   test/generated/parser_fasta_listener.dart 926:14                   ForwardingTestListener.endMethod
    //   package:front_end/src/fasta/parser/parser.dart 2433:14             Parser.parseMethod
    //   package:front_end/src/fasta/parser/parser.dart 2323:11             Parser.parseMember
    //   test/generated/parser_fasta_test.dart 3544:39                      ParserProxy._run
    super.test_missingKeywordOperator_parseClassMember();
  }

  @override
  @failingTest
  void test_missingKeywordOperator_parseClassMember_afterTypeName() {
    // TODO(brianwilkerson) Does not recover.
    //   type 'DeclaredSimpleIdentifier' is not a subtype of type 'TypeAnnotation' of 'returnType' where
    //   DeclaredSimpleIdentifier is from package:analyzer/src/dart/ast/ast.dart
    //   TypeAnnotation is from package:analyzer/dart/ast/ast.dart
    //
    //   package:analyzer/src/fasta/ast_builder.dart 1620:33                AstBuilder.endMethod
    //   test/generated/parser_fasta_listener.dart 926:14                   ForwardingTestListener.endMethod
    //   package:front_end/src/fasta/parser/parser.dart 2433:14             Parser.parseMethod
    //   package:front_end/src/fasta/parser/parser.dart 2323:11             Parser.parseMember
    //   test/generated/parser_fasta_test.dart 3544:39                      ParserProxy._run
    super.test_missingKeywordOperator_parseClassMember_afterTypeName();
  }

  @override
  @failingTest
  void test_missingKeywordOperator_parseClassMember_afterVoid() {
    // TODO(brianwilkerson) Does not recover.
    //   type 'DeclaredSimpleIdentifier' is not a subtype of type 'TypeAnnotation' of 'returnType' where
    //   DeclaredSimpleIdentifier is from package:analyzer/src/dart/ast/ast.dart
    //   TypeAnnotation is from package:analyzer/dart/ast/ast.dart
    //
    //   package:analyzer/src/fasta/ast_builder.dart 1620:33                AstBuilder.endMethod
    //   test/generated/parser_fasta_listener.dart 926:14                   ForwardingTestListener.endMethod
    //   package:front_end/src/fasta/parser/parser.dart 2433:14             Parser.parseMethod
    //   package:front_end/src/fasta/parser/parser.dart 2323:11             Parser.parseMember
    //   test/generated/parser_fasta_test.dart 3593:39                      ParserProxy._run
    super.test_missingKeywordOperator_parseClassMember_afterVoid();
  }

  @override
  @failingTest
  void test_missingMethodParameters_void_block() {
    // TODO(brianwilkerson) Does not recover.
    //   Expected: true
    //   Actual: <false>
    //
    //   package:test                                                       expect
    //   test/generated/parser_fasta_test.dart 3594:5                       ParserProxy._run
    super.test_missingMethodParameters_void_block();
  }

  @override
  @failingTest
  void test_missingMethodParameters_void_expression() {
    // TODO(brianwilkerson) Does not recover.
    //   Expected: true
    //   Actual: <false>
    //
    //   package:test                                                       expect
    //   test/generated/parser_fasta_test.dart 3594:5                       ParserProxy._run
    super.test_missingMethodParameters_void_expression();
  }

  @override
  @failingTest
  void test_missingNameForNamedParameter_colon() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPE, found 0;
    // 1 errors of type ParserErrorCode.MISSING_NAME_FOR_NAMED_PARAMETER, found 0
    super.test_missingNameForNamedParameter_colon();
  }

  @override
  @failingTest
  void test_missingNameForNamedParameter_equals() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPE, found 0;
    // 1 errors of type ParserErrorCode.MISSING_NAME_FOR_NAMED_PARAMETER, found 0
    super.test_missingNameForNamedParameter_equals();
  }

  @override
  @failingTest
  void test_missingNameForNamedParameter_noDefault() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.MISSING_NAME_FOR_NAMED_PARAMETER, found 0
    super.test_missingNameForNamedParameter_noDefault();
  }

  @override
  @failingTest
  void test_missingNameInLibraryDirective() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.MISSING_NAME_IN_LIBRARY_DIRECTIVE, found 0
    super.test_missingNameInLibraryDirective();
  }

  @override
  @failingTest
  void test_missingNameInPartOfDirective() {
    // TODO(brianwilkerson) Does not recover.
    //   type 'KeywordToken' is not a subtype of type 'Comment' of 'comment' where
    //   KeywordToken is from package:front_end/src/scanner/token.dart
    //   Comment is from package:analyzer/dart/ast/ast.dart
    //
    //   package:analyzer/src/fasta/ast_builder.dart 1457:23                AstBuilder.endPartOf
    //   package:front_end/src/fasta/parser/parser.dart 499:14              Parser.parsePartOf
    //   package:front_end/src/fasta/parser/parser.dart 467:14              Parser.parsePartOrPartOf
    //   package:front_end/src/fasta/parser/parser.dart 296:14              Parser._parseTopLevelDeclaration
    //   package:front_end/src/fasta/parser/parser.dart 263:13              Parser.parseTopLevelDeclaration
    //   package:front_end/src/fasta/parser/parser.dart 252:15              Parser.parseUnit
    //   package:analyzer/src/generated/parser_fasta.dart 77:33             _Parser2.parseCompilationUnit2
    //   package:analyzer/src/generated/parser_fasta.dart 72:12             _Parser2.parseCompilationUnit
    //   test/generated/parser_fasta_test.dart 3016:35                      FastaParserTestCase.parseCompilationUnit
    super.test_missingNameInPartOfDirective();
  }

  @override
  @failingTest
  void test_missingStatement() {
    // TODO(brianwilkerson) Does not recover.
    //   'package:front_end/src/fasta/source/stack_listener.dart': Failed assertion: line 311 pos 12: 'arrayLength > 0': is not true.
    //   dart:core                                                          _AssertionError._throwNew
    //   package:front_end/src/fasta/source/stack_listener.dart 311:12      Stack.pop
    //   package:front_end/src/fasta/source/stack_listener.dart 95:25       StackListener.pop
    //   package:analyzer/src/fasta/ast_builder.dart 262:34                 AstBuilder.endExpressionStatement
    //   test/generated/parser_fasta_listener.dart 724:14                   ForwardingTestListener.endExpressionStatement
    //   package:front_end/src/fasta/parser/parser.dart 2863:14             Parser.parseExpressionStatement
    //   package:front_end/src/fasta/parser/parser.dart 2790:14             Parser.parseStatementX
    //   package:front_end/src/fasta/parser/parser.dart 2722:20             Parser.parseStatement
    //   test/generated/parser_fasta_test.dart 3640:39                      ParserProxy._run
    super.test_missingStatement();
  }

  @override
  @failingTest
  void test_missingStatement_afterVoid() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.MISSING_STATEMENT, found 0
    super.test_missingStatement_afterVoid();
  }

  @override
  @failingTest
  void test_missingTerminatorForParameterGroup_named() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ScannerErrorCode.EXPECTED_TOKEN, found 0
    super.test_missingTerminatorForParameterGroup_named();
  }

  @override
  @failingTest
  void test_missingTerminatorForParameterGroup_optional() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ScannerErrorCode.EXPECTED_TOKEN, found 0
    super.test_missingTerminatorForParameterGroup_optional();
  }

  @override
  @failingTest
  void test_missingVariableInForEach() {
    // TODO(brianwilkerson) Does not recover.
    //   type 'BinaryExpressionImpl' is not a subtype of type 'VariableDeclarationStatement' in type cast where
    //   BinaryExpressionImpl is from package:analyzer/src/dart/ast/ast.dart
    //   VariableDeclarationStatement is from package:analyzer/dart/ast/ast.dart
    //
    //   dart:core                                                          Object._as
    //   package:analyzer/src/fasta/ast_builder.dart 797:45                 AstBuilder.endForIn
    //   test/generated/parser_fasta_listener.dart 751:14                   ForwardingTestListener.endForIn
    //   package:front_end/src/fasta/parser/parser.dart 3755:14             Parser.parseForInRest
    //   package:front_end/src/fasta/parser/parser.dart 3695:14             Parser.parseForStatement
    //   package:front_end/src/fasta/parser/parser.dart 2745:14             Parser.parseStatementX
    //   package:front_end/src/fasta/parser/parser.dart 2722:20             Parser.parseStatement
    //   test/generated/parser_fasta_test.dart 3671:39                      ParserProxy._run
    super.test_missingVariableInForEach();
  }

  @override
  @failingTest
  void test_mixedParameterGroups_namedPositional() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.MIXED_PARAMETER_GROUPS, found 0
    super.test_mixedParameterGroups_namedPositional();
  }

  @override
  @failingTest
  void test_mixedParameterGroups_positionalNamed() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.MIXED_PARAMETER_GROUPS, found 0
    super.test_mixedParameterGroups_positionalNamed();
  }

  @override
  @failingTest
  void test_mixin_application_lacks_with_clause() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.EXPECTED_TOKEN, found 0
    super.test_mixin_application_lacks_with_clause();
  }

  @override
  @failingTest
  void test_multipleNamedParameterGroups() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.MULTIPLE_NAMED_PARAMETER_GROUPS, found 0
    super.test_multipleNamedParameterGroups();
  }

  @override
  @failingTest
  void test_multiplePositionalParameterGroups() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.MULTIPLE_POSITIONAL_PARAMETER_GROUPS, found 0
    super.test_multiplePositionalParameterGroups();
  }

  @override
  @failingTest
  void test_multipleVariablesInForEach() {
    // TODO(brianwilkerson) Does not recover.
    //   Bad state: Too many elements
    //   dart:collection                                                    Object&ListMixin.single
    //   package:analyzer/src/fasta/ast_builder.dart 808:38                 AstBuilder.endForIn
    //   test/generated/parser_fasta_listener.dart 751:14                   ForwardingTestListener.endForIn
    //   package:front_end/src/fasta/parser/parser.dart 3755:14             Parser.parseForInRest
    //   package:front_end/src/fasta/parser/parser.dart 3695:14             Parser.parseForStatement
    //   package:front_end/src/fasta/parser/parser.dart 2745:14             Parser.parseStatementX
    //   package:front_end/src/fasta/parser/parser.dart 2722:20             Parser.parseStatement
    //   test/generated/parser_fasta_test.dart 3702:39                      ParserProxy._run
    super.test_multipleVariablesInForEach();
  }

  @override
  @failingTest
  void test_namedFunctionExpression() {
    // TODO(brianwilkerson) Does not recover.
    //   Internal problem: Compiler cannot run without a compiler context.
    //   Tip: Are calls to the compiler wrapped in CompilerContext.runInContext?
    //   package:front_end/src/fasta/compiler_context.dart 81:7             CompilerContext.current
    //   package:front_end/src/fasta/problems.dart 29:25                    internalProblem
    //   package:front_end/src/fasta/problems.dart 41:10                    unhandled
    //   package:front_end/src/fasta/source/stack_listener.dart 126:5       StackListener.logEvent
    //   package:analyzer/src/fasta/ast_builder.dart 1548:5                 AstBuilder.endNamedFunctionExpression
    //   test/generated/parser_fasta_listener.dart 938:14                   ForwardingTestListener.endNamedFunctionExpression
    //   package:front_end/src/fasta/parser/parser.dart 2520:16             Parser.parseNamedFunctionRest
    //   package:front_end/src/fasta/parser/parser.dart 1379:16             Parser.parseType
    //   package:front_end/src/fasta/parser/parser.dart 3365:14             Parser.parseSendOrFunctionLiteral
    //   package:front_end/src/fasta/parser/parser.dart 3127:14             Parser.parsePrimary
    //   test/generated/parser_fasta_test.dart 3320:31                      FastaParserTestCase.parsePrimaryExpression.<fn>.<fn>
    //   test/generated/parser_fasta_test.dart 3702:39                      ParserProxy._run
    super.test_namedFunctionExpression();
  }

  @override
  @failingTest
  void test_namedParameterOutsideGroup() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.NAMED_PARAMETER_OUTSIDE_GROUP, found 0
    super.test_namedParameterOutsideGroup();
  }

  @override
  @failingTest
  void test_nonConstructorFactory_field() {
    // TODO(brianwilkerson) Does not recover.
    //   Internal problem: Compiler cannot run without a compiler context.
    //   Tip: Are calls to the compiler wrapped in CompilerContext.runInContext?
    //   package:front_end/src/fasta/compiler_context.dart 81:7             CompilerContext.current
    //   package:front_end/src/fasta/problems.dart 29:25                    internalProblem
    //   package:front_end/src/fasta/problems.dart 41:10                    unhandled
    //   package:analyzer/src/fasta/ast_builder.dart 1498:7                 AstBuilder.endFactoryMethod
    //   test/generated/parser_fasta_listener.dart 731:14                   ForwardingTestListener.endFactoryMethod
    //   package:front_end/src/fasta/parser/parser.dart 2465:14             Parser.parseFactoryMethod
    //   package:front_end/src/fasta/parser/parser.dart 2240:15             Parser.parseMember
    //   test/generated/parser_fasta_test.dart 3702:39                      ParserProxy._run
    super.test_nonConstructorFactory_field();
  }

  @override
  @failingTest
  void test_nonConstructorFactory_method() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.NON_CONSTRUCTOR_FACTORY, found 0
    super.test_nonConstructorFactory_method();
  }

  @override
  @failingTest
  void test_nonIdentifierLibraryName_library() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.NON_IDENTIFIER_LIBRARY_NAME, found 0
    super.test_nonIdentifierLibraryName_library();
  }

  @override
  @failingTest
  void test_nonIdentifierLibraryName_partOf() {
    // TODO(brianwilkerson) Does not recover.
    //   type 'IntegerLiteralImpl' is not a subtype of type 'List<SimpleIdentifier>' of 'components' where
    //   IntegerLiteralImpl is from package:analyzer/src/dart/ast/ast.dart
    //   List is from dart:core
    //   SimpleIdentifier is from package:analyzer/dart/ast/ast.dart
    //
    //   package:analyzer/src/dart/ast/ast_factory.dart 665:62              AstFactoryImpl.libraryIdentifier
    //   package:analyzer/src/fasta/ast_builder.dart 1451:18                AstBuilder.endPartOf
    //   package:front_end/src/fasta/parser/parser.dart 499:14              Parser.parsePartOf
    //   package:front_end/src/fasta/parser/parser.dart 467:14              Parser.parsePartOrPartOf
    //   package:front_end/src/fasta/parser/parser.dart 296:14              Parser._parseTopLevelDeclaration
    //   package:front_end/src/fasta/parser/parser.dart 263:13              Parser.parseTopLevelDeclaration
    //   package:front_end/src/fasta/parser/parser.dart 252:15              Parser.parseUnit
    //   package:analyzer/src/generated/parser_fasta.dart 77:33             _Parser2.parseCompilationUnit2
    //   package:analyzer/src/generated/parser_fasta.dart 72:12             _Parser2.parseCompilationUnit
    //   test/generated/parser_fasta_test.dart 3125:35                      FastaParserTestCase.parseCompilationUnit
    super.test_nonIdentifierLibraryName_partOf();
  }

  @override
  @failingTest
  void test_nonUserDefinableOperator() {
    // TODO(brianwilkerson) Does not recover.
    //   type 'SimpleIdentifierImpl' is not a subtype of type 'TypeAnnotation' of 'returnType' where
    //   SimpleIdentifierImpl is from package:analyzer/src/dart/ast/ast.dart
    //   TypeAnnotation is from package:analyzer/dart/ast/ast.dart
    //
    //   package:analyzer/src/fasta/ast_builder.dart 1620:33                AstBuilder.endMethod
    //   test/generated/parser_fasta_listener.dart 926:14                   ForwardingTestListener.endMethod
    //   package:front_end/src/fasta/parser/parser.dart 2433:14             Parser.parseMethod
    //   package:front_end/src/fasta/parser/parser.dart 2323:11             Parser.parseMember
    //   test/generated/parser_fasta_test.dart 3766:39                      ParserProxy._run
    super.test_nonUserDefinableOperator();
  }

  @override
  @failingTest
  void test_optionalAfterNormalParameters_named() {
    // TODO(brianwilkerson) Does not recover.
    //   type 'FormalParameterListImpl' is not a subtype of type 'TypeParameterList' of 'typeParameters' where
    //   FormalParameterListImpl is from package:analyzer/src/dart/ast/ast.dart
    //   TypeParameterList is from package:analyzer/dart/ast/ast.dart
    //
    //   package:analyzer/src/fasta/ast_builder.dart 1122:40                AstBuilder.endTopLevelMethod
    //   package:front_end/src/fasta/parser/parser.dart 1741:14             Parser.parseTopLevelMethod
    //   package:front_end/src/fasta/parser/parser.dart 1646:11             Parser.parseTopLevelMember
    //   package:front_end/src/fasta/parser/parser.dart 298:14              Parser._parseTopLevelDeclaration
    //   package:front_end/src/fasta/parser/parser.dart 263:13              Parser.parseTopLevelDeclaration
    //   package:front_end/src/fasta/parser/parser.dart 252:15              Parser.parseUnit
    //   package:analyzer/src/generated/parser_fasta.dart 77:33             _Parser2.parseCompilationUnit2
    //   package:analyzer/src/generated/parser_fasta.dart 72:12             _Parser2.parseCompilationUnit
    //   test/generated/parser_fasta_test.dart 3189:35                      FastaParserTestCase.parseCompilationUnit
    super.test_optionalAfterNormalParameters_named();
  }

  @override
  @failingTest
  void test_optionalAfterNormalParameters_positional() {
    // TODO(brianwilkerson) Does not recover.
    //   type 'FormalParameterListImpl' is not a subtype of type 'TypeParameterList' of 'typeParameters' where
    //   FormalParameterListImpl is from package:analyzer/src/dart/ast/ast.dart
    //   TypeParameterList is from package:analyzer/dart/ast/ast.dart
    //
    //   package:analyzer/src/fasta/ast_builder.dart 1122:40                AstBuilder.endTopLevelMethod
    //   package:front_end/src/fasta/parser/parser.dart 1741:14             Parser.parseTopLevelMethod
    //   package:front_end/src/fasta/parser/parser.dart 1646:11             Parser.parseTopLevelMember
    //   package:front_end/src/fasta/parser/parser.dart 298:14              Parser._parseTopLevelDeclaration
    //   package:front_end/src/fasta/parser/parser.dart 263:13              Parser.parseTopLevelDeclaration
    //   package:front_end/src/fasta/parser/parser.dart 252:15              Parser.parseUnit
    //   package:analyzer/src/generated/parser_fasta.dart 77:33             _Parser2.parseCompilationUnit2
    //   package:analyzer/src/generated/parser_fasta.dart 72:12             _Parser2.parseCompilationUnit
    //   test/generated/parser_fasta_test.dart 3189:35                      FastaParserTestCase.parseCompilationUnit
    super.test_optionalAfterNormalParameters_positional();
  }

  @override
  @failingTest
  void test_parseCascadeSection_missingIdentifier() {
    // TODO(brianwilkerson) Testing at too low a level.
    super.test_parseCascadeSection_missingIdentifier();
  }

  @override
  @failingTest
  void test_parseCascadeSection_missingIdentifier_typeArguments() {
    // TODO(brianwilkerson) Testing at too low a level.
    super.test_parseCascadeSection_missingIdentifier_typeArguments();
  }

  @override
  @failingTest
  void test_positionalParameterOutsideGroup() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.POSITIONAL_PARAMETER_OUTSIDE_GROUP, found 0
    super.test_positionalParameterOutsideGroup();
  }

  @override
  @failingTest
  void test_redirectingConstructorWithBody_named() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.REDIRECTING_CONSTRUCTOR_WITH_BODY, found 0
    super.test_redirectingConstructorWithBody_named();
  }

  @override
  @failingTest
  void test_redirectingConstructorWithBody_unnamed() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.REDIRECTING_CONSTRUCTOR_WITH_BODY, found 0
    super.test_redirectingConstructorWithBody_unnamed();
  }

  @override
  @failingTest
  void test_redirectionInNonFactoryConstructor() {
    // TODO(brianwilkerson) Does not recover.
    //   type '_RedirectingFactoryBody' is not a subtype of type 'FunctionBody' of 'body' where
    //   _RedirectingFactoryBody is from package:analyzer/src/fasta/ast_builder.dart
    //   FunctionBody is from package:analyzer/dart/ast/ast.dart
    //
    //   package:analyzer/src/fasta/ast_builder.dart 1613:25                AstBuilder.endMethod
    //   test/generated/parser_fasta_listener.dart 926:14                   ForwardingTestListener.endMethod
    //   package:front_end/src/fasta/parser/parser.dart 2433:14             Parser.parseMethod
    //   package:front_end/src/fasta/parser/parser.dart 2323:11             Parser.parseMember
    //   test/generated/parser_fasta_test.dart 3766:39                      ParserProxy._run
    super.test_redirectionInNonFactoryConstructor();
  }

  @override
  @failingTest
  void test_setterInFunction_block() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.SETTER_IN_FUNCTION, found 0
    super.test_setterInFunction_block();
  }

  @override
  @failingTest
  void test_setterInFunction_expression() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.SETTER_IN_FUNCTION, found 0
    super.test_setterInFunction_expression();
  }

  @override
  @failingTest
  void test_staticConstructor() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.STATIC_CONSTRUCTOR, found 0
    super.test_staticConstructor();
  }

  @override
  @failingTest
  void test_staticGetterWithoutBody() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.STATIC_GETTER_WITHOUT_BODY, found 0
    super.test_staticGetterWithoutBody();
  }

  @override
  @failingTest
  void test_staticSetterWithoutBody() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.STATIC_SETTER_WITHOUT_BODY, found 0
    super.test_staticSetterWithoutBody();
  }

  @override
  @failingTest
  void test_string_unterminated_interpolation_block() {
    // TODO(brianwilkerson) Does not recover.
    //   RangeError: Value not in range: -1
    //   dart:core                                                          _StringBase.substring
    //   package:front_end/src/fasta/quote.dart 130:12                      unescapeLastStringPart
    //   package:analyzer/src/fasta/ast_builder.dart 181:17                 AstBuilder.endLiteralString
    //   package:front_end/src/fasta/parser/parser.dart 3497:14             Parser.parseSingleLiteralString
    //   package:front_end/src/fasta/parser/parser.dart 3434:13             Parser.parseLiteralString
    //   package:front_end/src/fasta/parser/parser.dart 3133:14             Parser.parsePrimary
    //   package:front_end/src/fasta/parser/parser.dart 3097:14             Parser.parseUnaryExpression
    //   package:front_end/src/fasta/parser/parser.dart 2968:13             Parser.parsePrecedenceExpression
    //   package:front_end/src/fasta/parser/parser.dart 2942:11             Parser.parseExpression
    //   package:front_end/src/fasta/parser/parser.dart 2862:13             Parser.parseExpressionStatement
    //   package:front_end/src/fasta/parser/parser.dart 2790:14             Parser.parseStatementX
    //   package:front_end/src/fasta/parser/parser.dart 2722:20             Parser.parseStatement
    //   package:front_end/src/fasta/parser/parser.dart 3792:15             Parser.parseBlock
    //   package:front_end/src/fasta/parser/parser.dart 2732:14             Parser.parseStatementX
    //   package:front_end/src/fasta/parser/parser.dart 2722:20             Parser.parseStatement
    //   package:front_end/src/fasta/parser/parser.dart 2652:15             Parser.parseFunctionBody
    //   package:front_end/src/fasta/parser/parser.dart 1737:13             Parser.parseTopLevelMethod
    //   package:front_end/src/fasta/parser/parser.dart 1646:11             Parser.parseTopLevelMember
    //   package:front_end/src/fasta/parser/parser.dart 298:14              Parser._parseTopLevelDeclaration
    //   package:front_end/src/fasta/parser/parser.dart 263:13              Parser.parseTopLevelDeclaration
    //   package:front_end/src/fasta/parser/parser.dart 252:15              Parser.parseUnit
    //   package:analyzer/src/generated/parser_fasta.dart 77:33             _Parser2.parseCompilationUnit2
    //   package:analyzer/src/generated/parser_fasta.dart 72:12             _Parser2.parseCompilationUnit
    //   test/generated/parser_fasta_test.dart 3272:35                      FastaParserTestCase.parseCompilationUnit
    super.test_string_unterminated_interpolation_block();
  }

  @override
  @failingTest
  void test_switchHasCaseAfterDefaultCase() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.SWITCH_HAS_CASE_AFTER_DEFAULT_CASE, found 0
    super.test_switchHasCaseAfterDefaultCase();
  }

  @override
  @failingTest
  void test_switchHasCaseAfterDefaultCase_repeated() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 2 errors of type ParserErrorCode.SWITCH_HAS_CASE_AFTER_DEFAULT_CASE, found 0
    super.test_switchHasCaseAfterDefaultCase_repeated();
  }

  @override
  @failingTest
  void test_switchHasMultipleDefaultCases() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.SWITCH_HAS_MULTIPLE_DEFAULT_CASES, found 0
    super.test_switchHasMultipleDefaultCases();
  }

  @override
  @failingTest
  void test_switchHasMultipleDefaultCases_repeated() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 2 errors of type ParserErrorCode.SWITCH_HAS_MULTIPLE_DEFAULT_CASES, found 0
    super.test_switchHasMultipleDefaultCases_repeated();
  }

  @override
  @failingTest
  void test_topLevelOperator_withoutOperator() {
    super.test_topLevelOperator_withoutOperator();
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
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE, found 0;
    // 1 errors of type ParserErrorCode.EXPECTED_TOKEN, found 0;
    // 1 errors of type ParserErrorCode.MISSING_IDENTIFIER, found 0;
    // 0 errors of type ParserErrorCode.EXTRANEOUS_MODIFIER, found 1 (8)
    super.test_topLevelVariable_withMetadata();
  }

  @override
  @failingTest
  void test_typedef_incomplete() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.UNEXPECTED_TOKEN, found 0;
    // 1 errors of type ParserErrorCode.EXPECTED_TOKEN, found 0;
    // 1 errors of type ParserErrorCode.EXPECTED_EXECUTABLE, found 0
    super.test_typedef_incomplete();
  }

  @override
  @failingTest
  void test_typedef_namedFunction() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.MISSING_TYPEDEF_PARAMETERS, found 0;
    // 1 errors of type ParserErrorCode.MISSING_IDENTIFIER, found 0;
    // 1 errors of type ParserErrorCode.UNEXPECTED_TOKEN, found 0;
    // 1 errors of type ParserErrorCode.EXPECTED_EXECUTABLE, found 0
    super.test_typedef_namedFunction();
  }

  @override
  @failingTest
  void test_unexpectedTerminatorForParameterGroup_named() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.UNEXPECTED_TERMINATOR_FOR_PARAMETER_GROUP, found 0
    super.test_unexpectedTerminatorForParameterGroup_named();
  }

  @override
  @failingTest
  void test_unexpectedTerminatorForParameterGroup_optional() {
    // TODO(brianwilkerson) Wrong errors:
    //Expected 1 errors of type ParserErrorCode.UNEXPECTED_TERMINATOR_FOR_PARAMETER_GROUP, found 0
    super.test_unexpectedTerminatorForParameterGroup_optional();
  }

  @override
  @failingTest
  void test_unexpectedToken_endOfFieldDeclarationStatement() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.UNEXPECTED_TOKEN, found 0
    super.test_unexpectedToken_endOfFieldDeclarationStatement();
  }

  @override
  @failingTest
  void test_unexpectedToken_invalidPostfixExpression() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.UNEXPECTED_TOKEN, found 0
    super.test_unexpectedToken_invalidPostfixExpression();
  }

  @override
  @failingTest
  void test_unexpectedToken_returnInExpressionFunctionBody() {
    // TODO(brianwilkerson) Does not recover.
    //   type 'FormalParameterListImpl' is not a subtype of type 'Token' of 'asyncKeyword' where
    //   FormalParameterListImpl is from package:analyzer/src/dart/ast/ast.dart
    //   Token is from package:front_end/src/scanner/token.dart
    //
    //   package:analyzer/src/fasta/ast_builder.dart 380:26                 AstBuilder.handleExpressionFunctionBody
    //   package:front_end/src/fasta/parser/parser.dart 2621:18             Parser.parseFunctionBody
    //   package:front_end/src/fasta/parser/parser.dart 1737:13             Parser.parseTopLevelMethod
    //   package:front_end/src/fasta/parser/parser.dart 1646:11             Parser.parseTopLevelMember
    //   package:front_end/src/fasta/parser/parser.dart 298:14              Parser._parseTopLevelDeclaration
    //   package:front_end/src/fasta/parser/parser.dart 263:13              Parser.parseTopLevelDeclaration
    //   package:front_end/src/fasta/parser/parser.dart 252:15              Parser.parseUnit
    //   package:analyzer/src/generated/parser_fasta.dart 77:33             _Parser2.parseCompilationUnit2
    //   package:analyzer/src/generated/parser_fasta.dart 72:12             _Parser2.parseCompilationUnit
    //   test/generated/parser_fasta_test.dart 3371:35                      FastaParserTestCase.parseCompilationUnit
    super.test_unexpectedToken_returnInExpressionFunctionBody();
  }

  @override
  @failingTest
  void test_unexpectedToken_semicolonBetweenClassMembers() {
    // TODO(brianwilkerson) Does not recover.
    //   Expected ClassBody, but found [CompilationUnit, ClassOrNamedMixinApplication, ClassDeclaration, ClassBody, Member]
    //   package:test                                                       fail
    //   test/generated/parser_fasta_listener.dart 50:7                     ForwardingTestListener.expectIn
    //   test/generated/parser_fasta_listener.dart 55:5                     ForwardingTestListener.end
    //   test/generated/parser_fasta_listener.dart 615:5                    ForwardingTestListener.endClassBody
    //   package:front_end/src/fasta/parser/parser.dart 2220:14             Parser.parseClassBody
    //   package:front_end/src/fasta/parser/parser.dart 897:13              Parser.parseClass
    //   package:front_end/src/fasta/parser/parser.dart 850:14              Parser.parseClassOrNamedMixinApplication
    //   package:front_end/src/fasta/parser/parser.dart 283:14              Parser._parseTopLevelDeclaration
    //   package:front_end/src/fasta/parser/parser.dart 263:13              Parser.parseTopLevelDeclaration
    //   test/generated/parser_fasta_test.dart 3896:22                      ParserProxy.parseTopLevelDeclaration
    super.test_unexpectedToken_semicolonBetweenClassMembers();
  }

  @override
  @failingTest
  void test_unexpectedToken_semicolonBetweenCompilationUnitMembers() {
    // TODO(brianwilkerson) Does not recover.
    //   Internal problem: Compiler cannot run without a compiler context.
    //   Tip: Are calls to the compiler wrapped in CompilerContext.runInContext?
    //   package:front_end/src/fasta/compiler_context.dart 81:7             CompilerContext.current
    //   package:front_end/src/fasta/problems.dart 29:25                    internalProblem
    //   package:front_end/src/fasta/source/stack_listener.dart 148:7       StackListener.checkEmpty
    //   package:analyzer/src/fasta/ast_builder.dart 1163:5                 AstBuilder.endCompilationUnit
    //   package:front_end/src/fasta/parser/parser.dart 255:14              Parser.parseUnit
    //   package:analyzer/src/generated/parser_fasta.dart 77:33             _Parser2.parseCompilationUnit2
    //   package:analyzer/src/generated/parser_fasta.dart 72:12             _Parser2.parseCompilationUnit
    //   test/generated/parser_fasta_test.dart 3371:35                      FastaParserTestCase.parseCompilationUnit
    super.test_unexpectedToken_semicolonBetweenCompilationUnitMembers();
  }

  @override
  @failingTest
  void test_useOfUnaryPlusOperator() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.MISSING_IDENTIFIER, found 0
    super.test_useOfUnaryPlusOperator();
  }

  @override
  void test_varAndType_local() {
    // The inherited test is marked as failing.
    super.test_varAndType_local();
  }

  @override
  void test_varAndType_parameter() {
    // The inherited test is marked as failing.
    super.test_varAndType_parameter();
  }

  @override
  @failingTest
  void test_varAsTypeName_as() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.VAR_AS_TYPE_NAME, found 0
    super.test_varAsTypeName_as();
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
  void test_wrongTerminatorForParameterGroup_named() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.WRONG_TERMINATOR_FOR_PARAMETER_GROUP, found 0;
    // 1 errors of type ScannerErrorCode.EXPECTED_TOKEN, found 0
    super.test_wrongTerminatorForParameterGroup_named();
  }

  @override
  @failingTest
  void test_wrongTerminatorForParameterGroup_optional() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.WRONG_TERMINATOR_FOR_PARAMETER_GROUP, found 0;
    // 1 errors of type ScannerErrorCode.EXPECTED_TOKEN, found 0
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
  void test_parseInstanceCreationExpression_type_named_typeArgumentComments() {
    // TODO(brianwilkerson) Does not inject generic type arguments.
    super
        .test_parseInstanceCreationExpression_type_named_typeArgumentComments();
  }

  @override
  @failingTest
  void test_parseUnaryExpression_decrement_super() {
    // TODO(brianwilkerson) Does not recover.
    // Expected: TokenType:<MINUS>
    //   Actual: TokenType:<MINUS_MINUS>
    super.test_parseUnaryExpression_decrement_super();
  }

  @override
  @failingTest
  void test_parseUnaryExpression_decrement_super_withComment() {
    // TODO(brianwilkerson) Does not recover.
    // Expected: TokenType:<MINUS>
    //   Actual: TokenType:<MINUS_MINUS>
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
  static final List<ErrorCode> NO_ERROR_COMPARISON = <ErrorCode>[];
  ParserProxy _parserProxy;

  analyzer.Token _fastaTokens;

  @override
  bool allowNativeClause = false;

  /**
   * Whether generic method comments should be enabled for the test.
   */
  bool enableGenericMethodComments = false;

  @override
  set enableLazyAssignmentOperators(bool value) {
    // Lazy assignment operators are always enabled
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
  ExpectedError expectedError(ErrorCode code, int offset, int length) =>
      new ExpectedError(
          _toFastaGeneratedAnalyzerErrorCode(code), offset, length);

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
      {List<ErrorCode> codes, List<ExpectedError> errors}) {
    // Scan tokens
    var source = new StringSource(content, 'parser_test_StringSource.dart');
    GatheringErrorListener listener =
        new GatheringErrorListener(checkRanges: true);
    var scanner = new Scanner.fasta(source, listener);
    scanner.scanGenericMethodComments = enableGenericMethodComments;
    _fastaTokens = scanner.tokenize();

    // Run parser
    analyzer.Parser parser =
        new analyzer.Parser(source, listener, useFasta: true);
    CompilationUnit unit = parser.parseCompilationUnit(_fastaTokens);
    expect(unit, isNotNull);

    // Assert and return result
    if (codes != null) {
      listener
          .assertErrorsWithCodes(_toFastaGeneratedAnalyzerErrorCodes(codes));
    } else if (errors != null) {
      listener.assertErrors(errors);
    } else {
      listener.assertNoErrors();
    }
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
    // TODO(paulberry,ahe,danrubel): analyzer parser has the ability to
    // stop parsing as soon as the first non-directive is encountered; this is
    // useful for quickly traversing an import graph.  Consider adding a similar
    // ability to Fasta's parser.
    throw 'fasta parser does not have a method that just parses directives'
        ' and stops when it finds the first declaration or EOF.';
  }

  @override
  BinaryExpression parseEqualityExpression(String code) {
    return _parseExpression(code);
  }

  @override
  Expression parseExpression(String source,
      {List<ErrorCode> codes, List<ExpectedError> errors}) {
    return _runParser(source, (parser) => parser.parseExpression,
        codes: codes, errors: errors) as Expression;
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
              return parser
                  .parseFormalParametersRequiredOpt(
                      parser.syntheticPreviousToken(token),
                      inFunctionType
                          ? fasta.MemberKind.GeneralizedFunctionType
                          : fasta.MemberKind.NonStaticMethod)
                  .next;
            },
        codes: errorCodes) as FormalParameterList;
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
        (parser) => (token) => parser.parsePrimary(
            parser.syntheticPreviousToken(token),
            IdentifierContext.expression)) as Expression;
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
    return _runParser(
        source,
        (parser) => (token) =>
            parser.parseStatementOpt(parser.syntheticPreviousToken(token)).next,
        codes: NO_ERROR_COMPARISON) as Statement;
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
      {List<ErrorCode> codes, List<ExpectedError> errors}) {
    createParser(source);
    Object result = _parserProxy._run(getParseFunction);
    if (codes != null) {
      if (!identical(codes, NO_ERROR_COMPARISON)) {
        assertErrorsWithCodes(codes);
      }
    } else if (errors != null) {
      listener.assertErrors(errors);
    } else {
      assertNoErrors();
    }
    return result;
  }

  ErrorCode _toFastaGeneratedAnalyzerErrorCode(ErrorCode code) {
    if (code == ParserErrorCode.ABSTRACT_ENUM ||
        code == ParserErrorCode.ABSTRACT_TOP_LEVEL_FUNCTION ||
        code == ParserErrorCode.ABSTRACT_TOP_LEVEL_VARIABLE ||
        code == ParserErrorCode.ABSTRACT_TYPEDEF ||
        code == ParserErrorCode.CONST_ENUM ||
        code == ParserErrorCode.CONST_TYPEDEF ||
        code == ParserErrorCode.COVARIANT_TOP_LEVEL_DECLARATION ||
        code == ParserErrorCode.FINAL_CLASS ||
        code == ParserErrorCode.FINAL_ENUM ||
        code == ParserErrorCode.FINAL_TYPEDEF ||
        code == ParserErrorCode.STATIC_TOP_LEVEL_DECLARATION)
      return ParserErrorCode.EXTRANEOUS_MODIFIER;
    return code;
  }

  List<ErrorCode> _toFastaGeneratedAnalyzerErrorCodes(
          List<ErrorCode> expectedErrorCodes) =>
      expectedErrorCodes.map(_toFastaGeneratedAnalyzerErrorCode).toList();
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
    // TODO(brianwilkerson) Does not recover.
    super.test_parseFormalParameterList_prefixedType_partial();
  }

  @override
  @failingTest
  void test_parseFormalParameterList_prefixedType_partial2() {
    // TODO(brianwilkerson) Does not recover.
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
      {bool silent: false, bool wasHandled: false, LocatedMessage context}) {
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
class ParserProxy extends analyzer.ParserAdapter {
  /**
   * The error listener to which scanner and parser errors will be reported.
   */
  final GatheringErrorListener _errorListener;

  ForwardingTestListener _eventListener;

  /**
   * Creates a [ParserProxy] which is prepared to begin parsing at the given
   * Fasta token.
   */
  factory ParserProxy(analyzer.Token firstToken,
      {bool allowNativeClause: false,
      bool enableGenericMethodComments: false}) {
    var library = new KernelLibraryBuilderProxy();
    var member = new BuilderProxy();
    var scope = new ScopeProxy();
    TestSource source = new TestSource();
    var errorListener = new GatheringErrorListener(checkRanges: true);
    var errorReporter = new ErrorReporter(errorListener, source);
    return new ParserProxy._(
        firstToken, errorReporter, library, member, scope, errorListener,
        allowNativeClause: allowNativeClause,
        enableGenericMethodComments: enableGenericMethodComments);
  }

  ParserProxy._(
      analyzer.Token firstToken,
      ErrorReporter errorReporter,
      KernelLibraryBuilder library,
      Builder member,
      Scope scope,
      this._errorListener,
      {bool allowNativeClause: false,
      bool enableGenericMethodComments: false})
      : super(firstToken, errorReporter, library, member, scope,
            allowNativeClause: allowNativeClause,
            enableGenericMethodComments: enableGenericMethodComments) {
    _eventListener = new ForwardingTestListener(astBuilder);
    fastaParser.listener = _eventListener;
  }

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Annotation parseAnnotation() {
    return _run2('MetadataStar', () => super.parseAnnotation());
  }

  @override
  ArgumentList parseArgumentList() {
    return _run2('unspecified', () => super.parseArgumentList());
  }

  @override
  ClassMember parseClassMember(String className) {
    return _run2('ClassBody', () => super.parseClassMember(className));
  }

  List<Combinator> parseCombinators() {
    return _run2('Import', () => super.parseCombinators());
  }

  @override
  CompilationUnit parseCompilationUnit2() {
    CompilationUnit result = super.parseCompilationUnit2();
    expect(currentToken.isEof, isTrue, reason: currentToken.lexeme);
    expect(astBuilder.stack, hasLength(0));
    _eventListener.expectEmpty();
    return result;
  }

  @override
  Configuration parseConfiguration() {
    return _run2('ConditionalUris', () => super.parseConfiguration());
  }

  @override
  FormalParameterList parseFormalParameterList({bool inFunctionType: false}) {
    return _run2('unspecified',
        () => super.parseFormalParameterList(inFunctionType: inFunctionType));
  }

  @override
  FunctionBody parseFunctionBody(
      bool mayBeEmpty, ParserErrorCode emptyErrorCode, bool inExpression) {
    Token lastToken;
    FunctionBody body = _run2('unspecified', () {
      FunctionBody body =
          super.parseFunctionBody(mayBeEmpty, emptyErrorCode, inExpression);
      lastToken = currentToken;
      currentToken = currentToken.next;
      return body;
    });
    if (!inExpression) {
      if (![';', '}'].contains(lastToken.lexeme)) {
        fail('Expected ";" or "}", but found: ${lastToken.lexeme}');
      }
    }
    return body;
  }

  @override
  Statement parseStatement(Token token) {
    return _run2('unspecified', () => super.parseStatement(token));
  }

  @override
  Statement parseStatement2() {
    return parseStatement(currentToken);
  }

  @override
  AnnotatedNode parseTopLevelDeclaration(bool isDirective) {
    return _run2(
        'CompilationUnit', () => super.parseTopLevelDeclaration(isDirective));
  }

  @override
  TypeAnnotation parseTypeAnnotation(bool inExpression) {
    return _run2('unspecified', () => super.parseTypeAnnotation(inExpression));
  }

  @override
  TypeArgumentList parseTypeArgumentList() {
    return _run2('unspecified', () => super.parseTypeArgumentList());
  }

  @override
  TypeName parseTypeName(bool inExpression) {
    return _run2('unspecified', () => super.parseTypeName(inExpression));
  }

  @override
  TypeParameter parseTypeParameter() {
    return _run((parser) => (token) =>
            parser.parseTypeVariable(parser.syntheticPreviousToken(token)))
        as TypeParameter;
  }

  @override
  TypeParameterList parseTypeParameterList() {
    return _run((parser) => (token) => parser
        .parseTypeVariablesOpt(parser.syntheticPreviousToken(token))
        .next) as TypeParameterList;
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
      parseFunction = getParseFunction(fastaParser);
    } else {
      parseFunction = fastaParser.parseUnit;
      // firstToken should be set by beginCompilationUnit event.
    }
    currentToken = parseFunction(currentToken);
    expect(currentToken.isEof, isTrue, reason: currentToken.lexeme);
    if (nodeCount >= 0) {
      expect(astBuilder.stack, hasLength(nodeCount));
    }
    if (nodeCount != 1) {
      return astBuilder.stack.values;
    }
    return astBuilder.pop();
  }

  /**
   * Runs the specified function and returns the result.
   * It checks the enclosing listener events,
   * that the parse consumed all of the tokens,
   * and that the result stack is empty.
   */
  _run2(String enclosingEvent, f()) {
    _eventListener.begin(enclosingEvent);
    var result = f();
    _eventListener.end(enclosingEvent);
    expect(currentToken.isEof, isTrue, reason: currentToken.lexeme);
    expect(astBuilder.stack, hasLength(0));
    expect(astBuilder.directives, hasLength(0));
    expect(astBuilder.declarations, hasLength(0));
    return result;
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
  void test_classTypeAlias_withBody() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_classTypeAlias_withBody();
  }

  @override
  void test_equalityExpression_precedence_relational_left() {
    // Fasta recovers differently. It takes the `is` to be an identifier and
    // assumes that the right operand of the `==` is the only missing identifier.
    parseExpression("is ==", codes: [
//      ParserErrorCode.EXPECTED_TYPE_NAME,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
  }

  @override
  void test_equalityExpression_precedence_relational_right() {
    // Fasta recovers differently. It takes the `is` to be an identifier and
    // assumes that it is the right operand of the `==`.
    parseExpression("== is", codes: [
//      ParserErrorCode.EXPECTED_TYPE_NAME,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
  }

  @override
  @failingTest
  void test_equalityExpression_super() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_equalityExpression_super();
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
  void test_primaryExpression_argumentDefinitionTest() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_primaryExpression_argumentDefinitionTest();
  }

  @override
  void test_relationalExpression_missing_LHS_RHS() {
    // Fasta recovers differently. It takes the `is` to be an identifier.
    parseExpression("is", codes: [
//      ParserErrorCode.EXPECTED_TYPE_NAME,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
  }

  @override
  void test_relationalExpression_precedence_shift_right() {
    // Fasta recovers differently. It takes the `is` to be an identifier and
    // assumes that it is the right operand of the `<<`.
    parseExpression("<< is", codes: [
//      ParserErrorCode.EXPECTED_TYPE_NAME,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
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
}

/**
 * Tests of the fasta parser based on [StatementParserTestMixin].
 */
@reflectiveTest
class StatementParserTest_Fasta extends FastaParserTestCase
    with StatementParserTestMixin {
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

  void test_parseClassDeclaration_native_allowedWithFields() {
    allowNativeClause = true;
    createParser(r'''
class A native 'something' {
  final int x;
  A() {}
}
''');
    CompilationUnitMember member = parseFullCompilationUnitMember();
    expect(member, isNotNull);
    assertNoErrors();
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
  void test_parseCompilationUnit_builtIn_asFunctionName_withTypeParameter() {
    // Fasta correctly parses these, while analyzer does not.
    super.test_parseCompilationUnit_builtIn_asFunctionName_withTypeParameter();
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
}
