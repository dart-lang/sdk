// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/fasta/token_utils.dart';
import 'package:front_end/src/fasta/scanner/precedence.dart';
import 'package:front_end/src/scanner/token.dart';
import 'package:front_end/src/fasta/scanner/string_scanner.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'scanner_fasta_test.dart';
import 'scanner_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ScannerTest_RoundTrip);
  });
}

/// Scanner tests that use the analyzer scanner, then convert the resulting
/// token stream into a Fasta token stream, then convert back to an analyzer
/// token stream before verifying assertions.
///
/// These tests help to validate the correctness of the analyzer->Fasta token
/// stream conversion.
@reflectiveTest
class ScannerTest_RoundTrip extends ScannerTest {
  @override
  Token scanWithListener(String source, ErrorListener listener,
      {bool genericMethodComments: false,
      bool lazyAssignmentOperators: false}) {
    var analyzerToken = super.scanWithListener(source, listener,
        genericMethodComments: genericMethodComments,
        lazyAssignmentOperators: lazyAssignmentOperators);
    var fastaToken = fromAnalyzerTokenStream(analyzerToken);
    // Since [scanWithListener] reports errors to the listener, we don't
    // expect any error tokens in the Fasta token stream, so we convert using
    // ToAnalyzerTokenStreamConverter_NoErrors.
    return new ToAnalyzerTokenStreamConverter_NoErrors()
        .convertTokens(fastaToken);
  }

  @override
  @failingTest
  void test_ampersand_ampersand_eq() {
    // TODO(paulberry,ahe): Fasta scanner doesn't support lazy assignment
    // operators.
    super.test_ampersand_ampersand_eq();
  }

  @override
  @failingTest
  void test_bar_bar_eq() {
    // TODO(paulberry,ahe): Fasta scanner doesn't support lazy assignment
    // operators.
    super.test_bar_bar_eq();
  }

  @override
  @failingTest
  void test_comment_generic_method_type_assign() {
    // TODO(paulberry,ahe): Fasta scanner doesn't support generic comment
    // syntax.
    super.test_comment_generic_method_type_assign();
  }

  @override
  @failingTest
  void test_comment_generic_method_type_list() {
    // TODO(paulberry,ahe): Fasta scanner doesn't support generic comment
    // syntax.
    super.test_comment_generic_method_type_list();
  }

  @override
  @failingTest
  void test_scriptTag_withArgs() {
    // TODO(paulberry,ahe): Fasta scanner doesn't support script tag
    super.test_scriptTag_withArgs();
  }

  @override
  @failingTest
  void test_scriptTag_withoutSpace() {
    // TODO(paulberry,ahe): Fasta scanner doesn't support script tag
    super.test_scriptTag_withoutSpace();
  }

  @override
  @failingTest
  void test_scriptTag_withSpace() {
    // TODO(paulberry,ahe): Fasta scanner doesn't support script tag
    super.test_scriptTag_withSpace();
  }

  void test_pseudo_keywords() {
    var pseudoAnalyzerKeywords = new Set<Keyword>.from([
      Keyword.ABSTRACT,
      Keyword.AS,
      Keyword.COVARIANT,
      Keyword.DEFERRED,
      Keyword.DYNAMIC,
      Keyword.EXPORT,
      Keyword.EXTERNAL,
      Keyword.FACTORY,
      Keyword.GET,
      Keyword.IMPLEMENTS,
      Keyword.IMPORT,
      Keyword.LIBRARY,
      Keyword.OPERATOR,
      Keyword.PART,
      Keyword.SET,
      Keyword.STATIC,
      Keyword.TYPEDEF,
    ]);
    for (Keyword keyword in Keyword.values) {
      expect(keyword.isPseudoKeyword, pseudoAnalyzerKeywords.contains(keyword),
          reason: keyword.name);
    }
  }

  var allTokenTypes = new Set<TokenType>.from([
    TokenType.EOF,
    TokenType.DOUBLE,
    TokenType.HEXADECIMAL,
    TokenType.IDENTIFIER,
    TokenType.INT,
    TokenType.KEYWORD,
    TokenType.MULTI_LINE_COMMENT,
    TokenType.SCRIPT_TAG,
    TokenType.SINGLE_LINE_COMMENT,
    TokenType.STRING,
    TokenType.AMPERSAND,
    TokenType.AMPERSAND_AMPERSAND,
    TokenType.AMPERSAND_AMPERSAND_EQ,
    TokenType.AMPERSAND_EQ,
    TokenType.AT,
    TokenType.BANG,
    TokenType.BANG_EQ,
    TokenType.BAR,
    TokenType.BAR_BAR,
    TokenType.BAR_BAR_EQ,
    TokenType.BAR_EQ,
    TokenType.COLON,
    TokenType.COMMA,
    TokenType.CARET,
    TokenType.CARET_EQ,
    TokenType.CLOSE_CURLY_BRACKET,
    TokenType.CLOSE_PAREN,
    TokenType.CLOSE_SQUARE_BRACKET,
    TokenType.EQ,
    TokenType.EQ_EQ,
    TokenType.FUNCTION,
    TokenType.GT,
    TokenType.GT_EQ,
    TokenType.GT_GT,
    TokenType.GT_GT_EQ,
    TokenType.HASH,
    TokenType.INDEX,
    TokenType.INDEX_EQ,
    TokenType.LT,
    TokenType.LT_EQ,
    TokenType.LT_LT,
    TokenType.LT_LT_EQ,
    TokenType.MINUS,
    TokenType.MINUS_EQ,
    TokenType.MINUS_MINUS,
    TokenType.OPEN_CURLY_BRACKET,
    TokenType.OPEN_PAREN,
    TokenType.OPEN_SQUARE_BRACKET,
    TokenType.PERCENT,
    TokenType.PERCENT_EQ,
    TokenType.PERIOD,
    TokenType.PERIOD_PERIOD,
    TokenType.PLUS,
    TokenType.PLUS_EQ,
    TokenType.PLUS_PLUS,
    TokenType.QUESTION,
    TokenType.QUESTION_PERIOD,
    TokenType.QUESTION_QUESTION,
    TokenType.QUESTION_QUESTION_EQ,
    TokenType.SEMICOLON,
    TokenType.SLASH,
    TokenType.SLASH_EQ,
    TokenType.STAR,
    TokenType.STAR_EQ,
    TokenType.STRING_INTERPOLATION_EXPRESSION,
    TokenType.STRING_INTERPOLATION_IDENTIFIER,
    TokenType.TILDE,
    TokenType.TILDE_SLASH,
    TokenType.TILDE_SLASH_EQ,
    TokenType.BACKPING,
    TokenType.BACKSLASH,
    TokenType.PERIOD_PERIOD_PERIOD,
    TokenType.GENERIC_METHOD_TYPE_LIST,
    TokenType.GENERIC_METHOD_TYPE_ASSIGN,
  ]);

  void test_isOperator() {
    var operatorTokenTypes = new Set<TokenType>.from([
      TokenType.AMPERSAND,
      TokenType.AMPERSAND_AMPERSAND,
      TokenType.AMPERSAND_AMPERSAND_EQ,
      TokenType.AMPERSAND_EQ,
      TokenType.BANG,
      TokenType.BANG_EQ,
      TokenType.BAR,
      TokenType.BAR_BAR,
      TokenType.BAR_BAR_EQ,
      TokenType.BAR_EQ,
      TokenType.CARET,
      TokenType.CARET_EQ,
      TokenType.EQ,
      TokenType.EQ_EQ,
      TokenType.GT,
      TokenType.GT_EQ,
      TokenType.GT_GT,
      TokenType.GT_GT_EQ,
      TokenType.INDEX,
      TokenType.INDEX_EQ,
      TokenType.LT,
      TokenType.LT_EQ,
      TokenType.LT_LT,
      TokenType.LT_LT_EQ,
      TokenType.MINUS,
      TokenType.MINUS_EQ,
      TokenType.MINUS_MINUS,
      TokenType.PERCENT,
      TokenType.PERCENT_EQ,
      TokenType.PERIOD_PERIOD,
      TokenType.PLUS,
      TokenType.PLUS_EQ,
      TokenType.PLUS_PLUS,
      TokenType.QUESTION,
      TokenType.QUESTION_PERIOD,
      TokenType.QUESTION_QUESTION,
      TokenType.QUESTION_QUESTION_EQ,
      TokenType.SLASH,
      TokenType.SLASH_EQ,
      TokenType.STAR,
      TokenType.STAR_EQ,
      TokenType.TILDE,
      TokenType.TILDE_SLASH,
      TokenType.TILDE_SLASH_EQ,
    ]);

    void assertIsOperator(String source, bool isOperator) {
      if (source == null || source.isEmpty) return;
      var scanner = new StringScanner(source, includeComments: true);
      var token = scanner.tokenize();
      expect(token.isOperator, isOperator, reason: source);
    }

    var operatorLexemes =
        new Set.from(operatorTokenTypes.map((tt) => tt.lexeme));

    for (PrecedenceInfo info in PrecedenceInfo.all) {
      assertIsOperator(info.value, operatorLexemes.contains(info.value));
    }

    for (TokenType tt in new List.from(allTokenTypes)) {
      assertIsOperator(tt.lexeme, operatorTokenTypes.contains(tt));
    }
  }

  void test_precedence() {
    for (TokenType tt in allTokenTypes) {
      for (PrecedenceInfo info in PrecedenceInfo.all) {
        if (info.value == tt.lexeme || info.value == tt.name.toLowerCase()) {
          expect(tt.precedence, info.precedence, reason: tt.name);
        }
      }
    }
  }
}
