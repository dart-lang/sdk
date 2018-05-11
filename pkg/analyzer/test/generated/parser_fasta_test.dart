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
import 'package:front_end/src/fasta/kernel/kernel_builder.dart';
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
  @failingTest
  @override
  void test_parseAwaitExpression_inSync() {
    super.test_parseAwaitExpression_inSync();
  }

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
  void test_method_invalidTypeParameterComments() {
    // Ignored: Fasta does not support the generic comment syntax.
  }

  @override
  void test_method_invalidTypeParameterExtendsComment() {
    // Fasta no longer supports type comment based syntax
    // super.test_method_invalidTypeParameterExtendsComment();
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
  Expression parsePrimaryExpression(String code,
      {int expectedEndOffset, List<ExpectedError> errors}) {
    createParser(code, expectedEndOffset: expectedEndOffset);
    Expression result = _parserProxy.parsePrimaryExpression();
    assertErrors(codes: null, errors: errors);
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
    var member = new BuilderProxy();
    var scope = new ScopeProxy();
    TestSource source = new TestSource();
    var errorListener = new GatheringErrorListener(checkRanges: true);
    var errorReporter = new ErrorReporter(errorListener, source);
    return new ParserProxy._(
        firstToken, errorReporter, null, member, scope, errorListener,
        allowNativeClause: allowNativeClause,
        enableGenericMethodComments: enableGenericMethodComments,
        expectedEndOffset: expectedEndOffset);
  }

  ParserProxy._(analyzer.Token firstToken, ErrorReporter errorReporter,
      Uri fileUri, Builder member, Scope scope, this._errorListener,
      {bool allowNativeClause: false,
      bool enableGenericMethodComments: false,
      this.expectedEndOffset})
      : super(firstToken, errorReporter, fileUri, member, scope,
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
    parseExpression("== is", codes: [
      ParserErrorCode.EXPECTED_TYPE_NAME,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
  }

  @override
  @failingTest
  void test_incompleteTypeArguments_field() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_incompleteTypeArguments_field();
  }

  @override
  @failingTest
  void test_missingIdentifier_afterAnnotation() {
    // TODO(brianwilkerson) reportUnrecoverableErrorWithToken
    super.test_missingIdentifier_afterAnnotation();
  }

  @override
  void test_relationalExpression_missing_LHS_RHS() {
    parseExpression("is", codes: [
      ParserErrorCode.EXPECTED_TYPE_NAME,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
  }

  @override
  void test_relationalExpression_precedence_shift_right() {
    parseExpression("<< is", codes: [
      ParserErrorCode.EXPECTED_TYPE_NAME,
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
  declare(String name, Builder builder, Uri fileUri) {
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
