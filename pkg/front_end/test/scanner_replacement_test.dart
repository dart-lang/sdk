// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' show UTF8;

import 'package:front_end/src/fasta/scanner/recover.dart'
    show defaultRecoveryStrategy;
import 'package:front_end/src/fasta/scanner.dart' as fasta;
import 'package:front_end/src/fasta/scanner/token.dart' as fasta;
import 'package:front_end/src/fasta/scanner/error_token.dart' as fasta;
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
class ScannerTest_Replacement extends ScannerTestBase {
  ScannerTest_Replacement() {
    usingFasta = true;
  }

  @override
  analyzer.Token scanWithListener(String source, ErrorListener listener,
      {bool genericMethodComments: false,
      bool lazyAssignmentOperators: false}) {
    // Process the source similar to
    // pkg/analyzer/lib/src/dart/scanner/scanner.dart
    // to simulate replacing the analyzer scanner

    fasta.ScannerResult result = fasta.scanString(source,
        includeComments: true,
        scanGenericMethodComments: genericMethodComments,
        scanLazyAssignmentOperators: lazyAssignmentOperators,
        recover: ((List<int> bytes, fasta.Token tokens, List<int> lineStarts) {
      // perform recovery as a separate step
      // so that the token stream can be validated before and after recovery
      return tokens;
    }));

    fasta.Token tokens = result.tokens;
    assertValidTokenStream(tokens);
    assertValidBeginTokens(tokens);
    if (result.hasErrors) {
      List<int> bytes = UTF8.encode(source);
      tokens = defaultRecoveryStrategy(bytes, tokens, result.lineStarts);
      assertValidTokenStream(tokens, errorsFirst: true);
    }

    // fasta pretends there is an additional line at EOF
    result.lineStarts.removeLast();

    return extractErrors(tokens, listener);
  }

  void _assertOpenClosePair(String source) {
    analyzer.BeginToken open = _scan(source);
    fasta.Token close = open.next;
    expect(close.next.isEof, isTrue);
    expect(open.endGroup, close);
    expect(open.isSynthetic, isFalse);
    expect(close.isSynthetic, isFalse);
  }

  void _assertOpenOnly(String source, String expectedCloser) {
    ErrorListener listener = new ErrorListener();
    analyzer.BeginToken open = scanWithListener(source, listener);
    fasta.Token close = open.next;
    expect(close.next.isEof, isTrue);
    expect(open.endGroup, close);
    expect(open.isSynthetic, isFalse);
    expect(close.isSynthetic, isTrue);
    listener.assertErrors([
      new TestError(0, ScannerErrorCode.EXPECTED_TOKEN, [expectedCloser]),
    ]);
  }

  void test_lt() {
    // fasta does not automatically insert a closer for '<'
    // because it could be part of an expression rather than an opener
    analyzer.BeginToken lt = _scan('<');
    expect(lt.next.isEof, isTrue);
    expect(lt.isSynthetic, isFalse);
  }

  void test_lt_gt() {
    _assertOpenClosePair('< >');
  }

  @override
  void test_open_curly_bracket() {
    _assertOpenOnly('{', '}');
  }

  void test_open_curly_bracket_with_close() {
    _assertOpenClosePair('{ }');
  }

  void test_open_paren() {
    _assertOpenOnly('(', ')');
  }

  void test_open_paren_with_close() {
    _assertOpenClosePair('( )');
  }

  void test_open_square_bracket() {
    _assertOpenOnly('[', ']');
  }

  void test_open_square_bracket_with_close() {
    _assertOpenClosePair('[ ]');
  }

  @override
  void test_mismatched_opener_in_interpolation() {
    // When openers and closers are mismatched,
    // fasta favors considering the opener to be mismatched
    // and inserts synthetic closers as needed.
    // r'"${({(}}"' is parsed as r'"${({()})}"'
    // where both ')' are synthetic
    ErrorListener listener = new ErrorListener();
    var stringStart = scanWithListener(r'"${({(}}"', listener);
    analyzer.BeginToken interpolationStart = stringStart.next;
    analyzer.BeginToken openParen1 = interpolationStart.next;
    analyzer.BeginToken openBrace = openParen1.next;
    analyzer.BeginToken openParen2 = openBrace.next;
    var closeParen2 = openParen2.next;
    var closeBrace = closeParen2.next;
    var closeParen1 = closeBrace.next;
    var interpolationEnd = closeParen1.next;
    var stringEnd = interpolationEnd.next;
    var eof = stringEnd.next;

    expect(interpolationStart.endToken, same(interpolationEnd));
    expect(interpolationEnd.isSynthetic, isFalse);
    expect(openParen1.endToken, same(closeParen1));
    expect(closeParen1.isSynthetic, isTrue);
    expect(openBrace.endToken, same(closeBrace));
    expect(closeBrace.isSynthetic, isFalse);
    expect(openParen2.endToken, same(closeParen2));
    expect(closeParen2.isSynthetic, isTrue);
    expect(eof.isEof, isTrue);
    listener.assertErrors([
      new TestError(3, ScannerErrorCode.EXPECTED_TOKEN, [')']),
      new TestError(5, ScannerErrorCode.EXPECTED_TOKEN, [')']),
    ]);
  }

  @override
  void test_unmatched_openers() {
    ErrorListener listener = new ErrorListener();
    // fasta inserts missing closers except for '<'
    analyzer.BeginToken openBrace = scanWithListener('{[(<', listener);
    analyzer.BeginToken openBracket = openBrace.next;
    analyzer.BeginToken openParen = openBracket.next;
    analyzer.BeginToken openLT = openParen.next;
    var closeParen = openLT.next;
    var closeBracket = closeParen.next;
    var closeBrace = closeBracket.next;
    var eof = closeBrace.next;

    expect(openBrace.endGroup, same(closeBrace));
    expect(openBracket.endGroup, same(closeBracket));
    expect(openParen.endGroup, same(closeParen));
    expect(eof.isEof, true);

    listener.assertErrors([
      new TestError(2, ScannerErrorCode.EXPECTED_TOKEN, [')']),
      new TestError(1, ScannerErrorCode.EXPECTED_TOKEN, [']']),
      new TestError(0, ScannerErrorCode.EXPECTED_TOKEN, ['}']),
    ]);
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
    while (token.type == analyzer.TokenType.BAD_INPUT) {
      translateErrorToken(token,
          (ScannerErrorCode errorCode, int offset, List<Object> arguments) {
        listener.errors.add(new TestError(offset, errorCode, arguments));
      });
      token = token.next;
    }
    if (!token.previous.isEof) {
      var head = new analyzer.Token.eof(-1);
      token.previous = head;
      head.next = token;
    }
    return token;
  }

  /// Assert that the tokens in the stream are correctly connected prev/next.
  void assertValidTokenStream(fasta.Token firstToken,
      {bool errorsFirst: false}) {
    fasta.Token token = firstToken;
    fasta.Token previous = token.previous;
    expect(previous.isEof, isTrue, reason: 'Missing leading EOF');
    expect(previous.next, token, reason: 'Invalid leading EOF');
    expect(previous.previous, previous, reason: 'Invalid leading EOF');
    if (errorsFirst) {
      while (!token.isEof && token is fasta.ErrorToken) {
        token = token.next;
      }
    }
    var isNotErrorToken = isNot(new isInstanceOf<fasta.ErrorToken>());
    while (!token.isEof) {
      if (errorsFirst) expect(token, isNotErrorToken);
      previous = token;
      token = token.next;
      expect(token, isNotNull, reason: previous.toString());
      expect(token.previous, previous, reason: token.toString());
    }
    expect(token.next, token, reason: 'Invalid trailing EOF');
  }

  /// Assert that all [analyzer.BeginToken] has a valid `endGroup`
  /// that is in the stream.
  void assertValidBeginTokens(fasta.Token firstToken) {
    var openerStack = <analyzer.BeginToken>[];
    analyzer.BeginToken lastClosedGroup;
    fasta.Token token = firstToken;
    while (!token.isEof) {
      if (token is analyzer.BeginToken) {
        if (token.lexeme != '<')
          expect(token.endGroup, isNotNull, reason: token.lexeme);
        if (token.endGroup != null) openerStack.add(token);
      } else if (openerStack.isNotEmpty && openerStack.last.endGroup == token) {
        lastClosedGroup = openerStack.removeLast();
        expect(token.isSynthetic, token.next is fasta.UnmatchedToken,
            reason: 'Expect synthetic closer then error token, '
                'but found "$token" followed by "${token.next}"');
      } else if (token is fasta.UnmatchedToken) {
        expect(lastClosedGroup?.endGroup?.next, same(token),
            reason: 'Unexpected error token for group: $lastClosedGroup');
        expect(token.begin, lastClosedGroup);
      }
      token = token.next;
    }
    expect(openerStack, isEmpty, reason: 'Missing closers');
  }
}
