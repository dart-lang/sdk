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
import 'package:front_end/src/fasta/scanner/error_token.dart' show ErrorToken;
import 'package:front_end/src/fasta/scanner/string_scanner.dart';
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
  void test_parseClassMember_method_generic_comment_noReturnType() {
    // Ignored: Fasta does not support the generic comment syntax.
  }

  @override
  void test_parseClassMember_method_generic_comment_parameterType() {
    // Ignored: Fasta does not support the generic comment syntax.
  }

  @override
  void test_parseClassMember_method_generic_comment_returnType() {
    // Ignored: Fasta does not support the generic comment syntax.
  }

  @override
  void test_parseClassMember_method_generic_comment_returnType_bound() {
    // Ignored: Fasta does not support the generic comment syntax.
  }

  @override
  void test_parseClassMember_method_generic_comment_returnType_complex() {
    // Ignored: Fasta does not support the generic comment syntax.
  }

  @override
  void test_parseClassMember_method_generic_comment_void() {
    // Ignored: Fasta does not support the generic comment syntax.
  }

  @override
  void test_parseClassMember_method_static_generic_comment_returnType() {
    // Ignored: Fasta does not support the generic comment syntax.
  }
}

/**
 * Tests of the fasta parser based on [ComplexParserTestMixin].
 */
@reflectiveTest
class ComplexParserTest_Fasta extends FastaParserTestCase
    with ComplexParserTestMixin {
  @override
  void test_assignableExpression_arguments_normal_chain_typeArgumentComments() {
    // Ignored: Fasta does not support the generic comment syntax.
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
  void test_method_invalidTypeParameterExtendsComment() {
    // Fasta no longer supports type comment based syntax
    // super.test_method_invalidTypeParameterExtendsComment();
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
  void test_mixin_application_lacks_with_clause() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.EXPECTED_TOKEN, found 0
    super.test_mixin_application_lacks_with_clause();
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
  void test_unexpectedToken_endOfFieldDeclarationStatement() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.UNEXPECTED_TOKEN, found 0
    super.test_unexpectedToken_endOfFieldDeclarationStatement();
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
}

/**
 * Tests of the fasta parser based on [ExpressionParserTestMixin].
 */
@reflectiveTest
class ExpressionParserTest_Fasta extends FastaParserTestCase
    with ExpressionParserTestMixin {
  @override
  void
      test_parseAssignableExpression_expression_args_dot_typeArgumentComments() {
    // Ignored: Fasta does not support the generic comment syntax.
  }

  @override
  void
      test_parseAssignableExpression_identifier_args_dot_typeArgumentComments() {
    // Ignored: Fasta does not support the generic comment syntax.
  }

  @override
  void test_parseCascadeSection_ia_typeArgumentComments() {
    // Ignored: Fasta does not support the generic comment syntax.
  }

  @override
  void test_parseCascadeSection_ii_typeArgumentComments() {
    // Ignored: Fasta does not support the generic comment syntax.
  }

  @override
  void test_parseCascadeSection_pa_typeArgumentComments() {
    // Ignored: Fasta does not support the generic comment syntax.
  }

  @override
  void test_parseCascadeSection_paa_typeArgumentComments() {
    // Ignored: Fasta does not support the generic comment syntax.
  }

  @override
  void test_parseCascadeSection_paapaa_typeArgumentComments() {
    // Ignored: Fasta does not support the generic comment syntax.
  }

  @override
  void test_parseConstExpression_listLiteral_typed_genericComment() {
    // Ignored: Fasta does not support the generic comment syntax.
  }

  @override
  void test_parseConstExpression_mapLiteral_typed_genericComment() {
    // Ignored: Fasta does not support the generic comment syntax.
  }

  @override
  void test_parseExpression_superMethodInvocation_typeArgumentComments() {
    // Ignored: Fasta does not support the generic comment syntax.
  }

  @override
  void
      test_parseExpressionWithoutCascade_superMethodInvocation_typeArgumentComments() {
    // Ignored: Fasta does not support the generic comment syntax.
  }

  @override
  void test_parseFunctionExpression_typeParameterComments() {
    // Ignored: Fasta does not support the generic comment syntax.
  }

  @override
  void
      test_parseInstanceCreationExpression_qualifiedType_named_typeArgumentComments() {
    // Ignored: Fasta does not support the generic comment syntax.
  }

  @override
  void
      test_parseInstanceCreationExpression_qualifiedType_typeArgumentComments() {
    // Ignored: Fasta does not support the generic comment syntax.
  }

  @override
  @failingTest
  void test_parseInstanceCreationExpression_type_named_typeArgumentComments() {
    // TODO(brianwilkerson) Does not inject generic type arguments.
    super
        .test_parseInstanceCreationExpression_type_named_typeArgumentComments();
  }

  @override
  void test_parseInstanceCreationExpression_type_typeArgumentComments() {
    // Ignored: Fasta does not support the generic comment syntax.
  }

  @override
  void
      test_parsePostfixExpression_none_methodInvocation_question_dot_typeArgumentComments() {
    // Ignored: Fasta does not support the generic comment syntax.
  }

  @override
  void
      test_parsePostfixExpression_none_methodInvocation_typeArgumentComments() {
    // Ignored: Fasta does not support the generic comment syntax.
  }

  @override
  void test_parsePrimaryExpression_listLiteral_typed_genericComment() {
    // Ignored: Fasta does not support the generic comment syntax.
  }

  @override
  void test_parsePrimaryExpression_mapLiteral_typed_genericComment() {
    // Ignored: Fasta does not support the generic comment syntax.
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
  bool get enableGenericMethodComments => false;
  void set enableGenericMethodComments(bool enable) {}

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

  set enableOptionalNewAndConst(bool enable) {
    // ignored
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

  void assertErrors({List<ErrorCode> codes, List<ExpectedError> errors}) {
    if (codes != null) {
      if (!identical(codes, NO_ERROR_COMPARISON)) {
        assertErrorsWithCodes(codes);
      }
    } else if (errors != null) {
      listener.assertErrors(errors);
    } else {
      assertNoErrors();
    }
  }

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
  void createParser(String content, {int expectedEndOffset}) {
    var scanner = new StringScanner(content, includeComments: true);
    scanner.scanGenericMethodComments = enableGenericMethodComments;
    _fastaTokens = scanner.tokenize();
    _parserProxy = new ParserProxy(_fastaTokens,
        allowNativeClause: allowNativeClause,
        enableGenericMethodComments: enableGenericMethodComments,
        expectedEndOffset: expectedEndOffset);
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
    GatheringErrorListener listener =
        new GatheringErrorListener(checkRanges: true);

    CompilationUnit unit = parseCompilationUnit2(content, listener);

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

  CompilationUnit parseCompilationUnit2(
      String content, GatheringErrorListener listener) {
    // Scan tokens
    var source = new StringSource(content, 'parser_test_StringSource.dart');
    var scanner = new Scanner.fasta(source, listener);
    scanner.scanGenericMethodComments = enableGenericMethodComments;
    _fastaTokens = scanner.tokenize();

    // Run parser
    analyzer.Parser parser =
        new analyzer.Parser(source, listener, useFasta: true);
    CompilationUnit unit = parser.parseCompilationUnit(_fastaTokens);
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
    createParser('class __Test { __Test() : $code; }');
    CompilationUnit unit = _parserProxy.parseCompilationUnit2();
    assertNoErrors();
    var clazz = unit.declarations[0] as ClassDeclaration;
    var constructor = clazz.members[0] as ConstructorDeclaration;
    return constructor.initializers.single;
  }

  @override
  CompilationUnit parseDirectives(String source,
      [List<ErrorCode> errorCodes = const <ErrorCode>[]]) {
    createParser(source);
    CompilationUnit unit =
        _parserProxy.parseDirectives(_parserProxy.currentToken);
    expect(unit, isNotNull);
    expect(unit.declarations, hasLength(0));
    listener.assertErrorsWithCodes(errorCodes);
    return unit;
  }

  @override
  BinaryExpression parseEqualityExpression(String code) {
    return _parseExpression(code);
  }

  @override
  Expression parseExpression(String source,
      {List<ErrorCode> codes,
      List<ExpectedError> errors,
      int expectedEndOffset}) {
    createParser(source, expectedEndOffset: expectedEndOffset);
    Expression result = _parserProxy.parseExpression2();
    assertErrors(codes: codes, errors: errors);
    return result;
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
      List<ErrorCode> errorCodes: const <ErrorCode>[],
      List<ExpectedError> errors}) {
    createParser(code);
    FormalParameterList result =
        _parserProxy.parseFormalParameterList(inFunctionType: inFunctionType);
    assertErrors(codes: errors != null ? null : errorCodes, errors: errors);
    return result;
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
    createParser(code);
    Expression result = _parserProxy.parsePrimaryExpression();
    assertNoErrors();
    return result;
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
      {bool enableLazyAssignmentOperators, int expectedEndOffset}) {
    createParser(source, expectedEndOffset: expectedEndOffset);
    Statement statement = _parserProxy.parseStatement2();
    assertErrors(codes: NO_ERROR_COMPARISON);
    return statement;
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
  void test_parseNormalFormalParameter_function_noType_typeParameterComments() {
    // Ignored: Fasta does not support the generic comment syntax.
  }

  @override
  void test_parseNormalFormalParameter_function_type_typeParameterComments() {
    // Ignored: Fasta does not support the generic comment syntax.
  }

  @override
  void test_parseNormalFormalParameter_function_void_typeParameterComments() {
    // Ignored: Fasta does not support the generic comment syntax.
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
  void addCompileTimeError(Message message, int charOffset, int length, Uri uri,
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

  final int expectedEndOffset;

  /**
   * Creates a [ParserProxy] which is prepared to begin parsing at the given
   * Fasta token.
   */
  factory ParserProxy(analyzer.Token firstToken,
      {bool allowNativeClause: false,
      bool enableGenericMethodComments: false,
      int expectedEndOffset}) {
    var library = new KernelLibraryBuilderProxy();
    var member = new BuilderProxy();
    var scope = new ScopeProxy();
    TestSource source = new TestSource();
    var errorListener = new GatheringErrorListener(checkRanges: true);
    var errorReporter = new ErrorReporter(errorListener, source);
    return new ParserProxy._(
        firstToken, errorReporter, library, member, scope, errorListener,
        allowNativeClause: allowNativeClause,
        enableGenericMethodComments: enableGenericMethodComments,
        expectedEndOffset: expectedEndOffset);
  }

  ParserProxy._(
      analyzer.Token firstToken,
      ErrorReporter errorReporter,
      KernelLibraryBuilder library,
      Builder member,
      Scope scope,
      this._errorListener,
      {bool allowNativeClause: false,
      bool enableGenericMethodComments: false,
      this.expectedEndOffset})
      : super(firstToken, errorReporter, library, member, scope,
            allowNativeClause: allowNativeClause,
            enableGenericMethodComments: enableGenericMethodComments) {
    _eventListener = new ForwardingTestListener(astBuilder);
    fastaParser.listener = _eventListener;
  }

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Annotation parseAnnotation() {
    return _run('MetadataStar', () => super.parseAnnotation());
  }

  @override
  ArgumentList parseArgumentList() {
    return _run('unspecified', () => super.parseArgumentList());
  }

  @override
  ClassMember parseClassMember(String className) {
    return _run('ClassBody', () => super.parseClassMember(className));
  }

  List<Combinator> parseCombinators() {
    return _run('Import', () => super.parseCombinators());
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
    return _run('ConditionalUris', () => super.parseConfiguration());
  }

  @override
  DottedName parseDottedName() {
    return _run('unspecified', () => super.parseDottedName());
  }

  @override
  Expression parseExpression2() {
    return _run('unspecified', () => super.parseExpression2());
  }

  @override
  FormalParameterList parseFormalParameterList({bool inFunctionType: false}) {
    return _run('unspecified',
        () => super.parseFormalParameterList(inFunctionType: inFunctionType));
  }

  @override
  FunctionBody parseFunctionBody(
      bool mayBeEmpty, ParserErrorCode emptyErrorCode, bool inExpression) {
    Token lastToken;
    FunctionBody body = _run('unspecified', () {
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
  Expression parsePrimaryExpression() {
    return _run('unspecified', () => super.parsePrimaryExpression());
  }

  @override
  Statement parseStatement(Token token) {
    return _run('unspecified', () => super.parseStatement(token));
  }

  @override
  Statement parseStatement2() {
    return _run('unspecified', () => super.parseStatement2());
  }

  @override
  AnnotatedNode parseTopLevelDeclaration(bool isDirective) {
    return _run(
        'CompilationUnit', () => super.parseTopLevelDeclaration(isDirective));
  }

  @override
  TypeAnnotation parseTypeAnnotation(bool inExpression) {
    return _run('unspecified', () => super.parseTypeAnnotation(inExpression));
  }

  @override
  TypeArgumentList parseTypeArgumentList() {
    return _run('unspecified', () => super.parseTypeArgumentList());
  }

  @override
  TypeName parseTypeName(bool inExpression) {
    return _run('unspecified', () => super.parseTypeName(inExpression));
  }

  @override
  TypeParameter parseTypeParameter() {
    return _run('unspecified', () => super.parseTypeParameter());
  }

  @override
  TypeParameterList parseTypeParameterList() {
    return _run('unspecified', () => super.parseTypeParameterList());
  }

  /**
   * Runs the specified function and returns the result.
   * It checks the enclosing listener events,
   * that the parse consumed all of the tokens,
   * and that the result stack is empty.
   */
  _run(String enclosingEvent, f()) {
    _eventListener.begin(enclosingEvent);
    var result = f();
    _eventListener.end(enclosingEvent);
    String lexeme = currentToken is ErrorToken
        ? currentToken.runtimeType.toString()
        : currentToken.lexeme;
    if (expectedEndOffset == null) {
      expect(currentToken.isEof, isTrue, reason: lexeme);
    } else {
      expect(currentToken.offset, expectedEndOffset, reason: lexeme);
    }
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
  void test_expressionList_multiple_start() {
    // TODO(brianwilkerson) Wrong errors:
    // Expected 1 errors of type ParserErrorCode.MISSING_IDENTIFIER, found 0
    super.test_expressionList_multiple_start();
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
  void test_incompleteTypeArguments_field() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_incompleteTypeArguments_field();
  }

  @override
  @failingTest
  void test_isExpression_noType() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_isExpression_noType();
  }

  @override
  @failingTest
  void test_missingIdentifier_afterAnnotation() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_missingIdentifier_afterAnnotation();
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
  void test_parseInstanceCreation_noKeyword_noPrefix() {
    super.test_parseInstanceCreation_noKeyword_noPrefix();
  }

  @override
  @failingTest
  void test_parseInstanceCreation_noKeyword_prefix() {
    super.test_parseInstanceCreation_noKeyword_prefix();
  }

  @override
  @failingTest
  void test_parseTypeParameterList_single() {
    // TODO(brianwilkerson) Does not use all tokens.
    super.test_parseTypeParameterList_single();
  }
}

/**
 * Tests of the fasta parser based on [StatementParserTestMixin].
 */
@reflectiveTest
class StatementParserTest_Fasta extends FastaParserTestCase
    with StatementParserTestMixin {
  @override
  void test_parseFunctionDeclarationStatement_typeParameterComments() {
    // Ignored: Fasta does not support the generic comment syntax.
  }

  @override
  void
      test_parseStatement_functionDeclaration_noReturnType_typeParameterComments() {
    // Ignored: Fasta does not support the generic comment syntax.
  }

  @override
  void test_parseVariableDeclarationListAfterMetadata_const_typeComment() {
    // Ignored: Fasta does not support the generic comment syntax.
  }

  @override
  void test_parseVariableDeclarationListAfterMetadata_dynamic_typeComment() {
    // Ignored: Fasta does not support the generic comment syntax.
  }

  @override
  void test_parseVariableDeclarationListAfterMetadata_final_typeComment() {
    // Ignored: Fasta does not support the generic comment syntax.
  }

  @override
  void test_parseVariableDeclarationListAfterMetadata_type_typeComment() {
    // Ignored: Fasta does not support the generic comment syntax.
  }

  @override
  void test_parseVariableDeclarationListAfterMetadata_var_typeComment() {
    // Ignored: Fasta does not support the generic comment syntax.
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
}
