// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' show UTF8;

import 'package:front_end/src/fasta/scanner/precedence.dart'
    show BAD_INPUT_INFO, EOF_INFO;
import 'package:front_end/src/fasta/scanner/recover.dart'
    show defaultRecoveryStrategy;
import 'package:front_end/src/fasta/scanner.dart' as fasta;
import 'package:front_end/src/scanner/token.dart' as analyzer;
import 'package:front_end/src/scanner/errors.dart'
    show ScannerErrorCode, translateErrorToken;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'scanner_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ScannerTest_Replacement);
  });
}

/// Scanner tests that use the analyzer scanner, then convert the resulting
/// token stream into a Fasta token stream, then convert back to an analyzer
/// token stream before verifying assertions.
///
/// These tests help to validate the correctness of the analyzer->Fasta token
/// stream conversion.
@reflectiveTest
class ScannerTest_Replacement extends ScannerTest {
  @override
  analyzer.Token scanWithListener(String source, ErrorListener listener,
      {bool genericMethodComments: false,
      bool lazyAssignmentOperators: false}) {
    if (genericMethodComments) {
      // Fasta doesn't support generic method comments.
      // TODO(danrubel): once the analyzer toolchain no longer needs generic
      // method comments, remove tests that exercise them.
      fail('No generic method comment support in Fasta');
    }
    // Note: Fasta always supports lazy assignment operators (`&&=` and `||=`),
    // so we can ignore the `lazyAssignmentOperators` flag.
    // TODO(danrubel): once lazyAssignmentOperators are fully supported by
    // Dart, remove this flag.
    fasta.ScannerResult result = fasta.scanString(source,
        includeComments: true,
        recover: ((List<int> bytes, fasta.Token tokens, List<int> lineStarts) {
          // perform recovery as a separate step
          // so that the token stream can be validated before and after recovery
          return tokens;
        }));
    fasta.Token tokens = result.tokens;
    assertValidTokenStream(tokens);
    if (result.hasErrors) {
      List<int> bytes = UTF8.encode(source);
      tokens = defaultRecoveryStrategy(bytes, tokens, result.lineStarts);
      assertValidTokenStream(tokens);
    }
    return extractErrors(tokens, listener);
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
  void test_double_missingDigitInExponent() {
    // TODO(danrubel): investigate and fix
    super.test_double_missingDigitInExponent();
  }

  @override
  @failingTest
  void test_hexidecimal_missingDigit() {
    // TODO(danrubel): investigate and fix
    super.test_hexidecimal_missingDigit();
  }

  @override
  @failingTest
  void test_mismatched_closer() {
    // TODO(danrubel): investigate and fix
    super.test_mismatched_closer();
  }

  @override
  @failingTest
  void test_mismatched_opener() {
    // TODO(danrubel): investigate and fix
    super.test_mismatched_opener();
  }

  @override
  @failingTest
  void test_mismatched_opener_in_interpolation() {
    // TODO(danrubel): investigate and fix
    super.test_mismatched_opener_in_interpolation();
  }

  @override
  @failingTest
  void test_string_multi_unterminated() {
    // See defaultRecoveryStrategy recoverString
    super.test_string_multi_unterminated();
  }

  @override
  @failingTest
  void test_string_multi_unterminated_interpolation_block() {
    // See defaultRecoveryStrategy recoverString
    super.test_string_multi_unterminated_interpolation_block();
  }

  @override
  @failingTest
  void test_string_multi_unterminated_interpolation_identifier() {
    // See defaultRecoveryStrategy recoverString
    super.test_string_multi_unterminated_interpolation_identifier();
  }

  @override
  @failingTest
  void test_string_raw_multi_unterminated() {
    // See defaultRecoveryStrategy recoverString
    super.test_string_raw_multi_unterminated();
  }

  @override
  @failingTest
  void test_string_raw_simple_unterminated_eof() {
    // See defaultRecoveryStrategy recoverString
    super.test_string_raw_simple_unterminated_eof();
  }

  @override
  @failingTest
  void test_string_raw_simple_unterminated_eol() {
    // See defaultRecoveryStrategy recoverString
    super.test_string_raw_simple_unterminated_eol();
  }

  @override
  @failingTest
  void test_string_simple_interpolation_missingIdentifier() {
    // See defaultRecoveryStrategy recoverStringInterpolation
    super.test_string_simple_interpolation_missingIdentifier();
  }

  @override
  @failingTest
  void test_string_simple_interpolation_nonIdentifier() {
    // See defaultRecoveryStrategy recoverStringInterpolation
    super.test_string_simple_interpolation_nonIdentifier();
  }

  @override
  @failingTest
  void test_string_simple_unterminated_eof() {
    // See defaultRecoveryStrategy recoverString
    super.test_string_simple_unterminated_eof();
  }

  @override
  @failingTest
  void test_string_simple_unterminated_eol() {
    // See defaultRecoveryStrategy recoverString
    super.test_string_simple_unterminated_eol();
  }

  @override
  @failingTest
  void test_string_simple_unterminated_interpolation_block() {
    // See defaultRecoveryStrategy recoverString
    super.test_string_simple_unterminated_interpolation_block();
  }

  @override
  @failingTest
  void test_string_simple_unterminated_interpolation_identifier() {
    // See defaultRecoveryStrategy recoverString
    super.test_string_simple_unterminated_interpolation_identifier();
  }

  @failingTest
  @override
  void test_unmatched_openers() {
    // fasta recovery inserts closers
    var openBrace = _scan('{[(<') as analyzer.BeginToken;
    var openBracket = openBrace.next as analyzer.BeginToken;
    var openParen = openBracket.next as analyzer.BeginToken;
    var openLT = openParen.next as analyzer.BeginToken;
    var closeGT = openLT.next;
    var closeParen = closeGT.next;
    var closeBracket = closeParen.next;
    var closeBrace = closeBracket.next;
    expect(closeBrace.next.type, analyzer.TokenType.EOF);

    expect(openBrace.endToken, closeBrace);
    expect(openBracket.endToken, closeBracket);
    expect(openParen.endToken, closeParen);
    expect(openLT.endToken, closeGT);
  }

  analyzer.Token _scan(String source,
      {bool genericMethodComments: false,
      bool lazyAssignmentOperators: false}) {
    ErrorListener listener = new ErrorListener();
    analyzer.Token token = scanWithListener(source, listener,
        genericMethodComments: genericMethodComments,
        lazyAssignmentOperators: lazyAssignmentOperators);
    listener.assertNoErrors();
    return token;
  }

  analyzer.Token extractErrors(fasta.Token firstToken, ErrorListener listener) {
    var token = firstToken;
    // The default recovery strategy used by scanString
    // places all error tokens at the head of the stream.
    while (token.info == BAD_INPUT_INFO) {
      translateErrorToken(token,
          (ScannerErrorCode errorCode, int offset, List<Object> arguments) {
        listener.errors.add(new TestError(offset, errorCode, arguments));
      });
      token = token.next;
    }
    if (!token.previousToken.isEof) {
      var head = new fasta.SymbolToken(EOF_INFO, -1);
      token.previous = head;
      head.next = token;
    }
    return token;
  }

  /// Assert that the tokens in the stream are correctly connected prev/next.
  void assertValidTokenStream(fasta.Token firstToken) {
    fasta.Token token = firstToken;
    fasta.Token previous = token.previousToken;
    expect(previous.isEof, isTrue, reason: 'Missing leading EOF');
    expect(previous.next, token, reason: 'Invalid leading EOF');
    expect(previous.previous, previous, reason: 'Invalid leading EOF');
    while (!token.isEof) {
      previous = token;
      token = token.next;
      expect(token, isNotNull, reason: previous.toString());
      expect(token.previous, previous, reason: token.toString());
    }
    expect(token.next, token, reason: 'Invalid trailing EOF');
  }
}
