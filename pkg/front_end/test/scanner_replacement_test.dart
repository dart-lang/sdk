// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/error_token.dart';
import 'package:_fe_analyzer_shared/src/scanner/errors.dart'
    show ScannerErrorCode, translateErrorToken;
import 'package:_fe_analyzer_shared/src/scanner/scanner.dart';
import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'scanner_test.dart';

void main() {
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
  @override
  Token scanWithListener(
    String source,
    ErrorListener listener, {
    ScannerConfiguration? configuration,
  }) {
    // Process the source similar to
    // pkg/analyzer/lib/src/dart/scanner/scanner.dart
    // to simulate replacing the analyzer scanner

    ScannerResult result = scanString(
      source,
      configuration: configuration,
      includeComments: true,
    );

    Token tokens = result.tokens;
    assertValidTokenStream(tokens, errorsFirst: true);
    assertValidBeginTokens(tokens);

    // The scanner pretends there is an additional line at EOF
    result.lineStarts.removeLast();

    return extractErrors(tokens, listener);
  }

  void _assertOpenClosePair(String source) {
    BeginToken open = _scan(source) as BeginToken;
    Token close = open.next!;
    expect(close.next!.isEof, isTrue);
    expect(open.endGroup, close);
    expect(open.isSynthetic, isFalse);
    expect(close.isSynthetic, isFalse);
  }

  void _assertOpenOnly(String source, String expectedCloser) {
    ErrorListener listener = new ErrorListener();
    BeginToken open = scanWithListener(source, listener) as BeginToken;
    Token close = open.next!;
    expect(close.next!.isEof, isTrue);
    expect(open.endGroup, close);
    expect(open.isSynthetic, isFalse);
    expect(close.isSynthetic, isTrue);
    listener.assertErrors([
      new TestError(1, ScannerErrorCode.expectedToken, [expectedCloser]),
    ]);
  }

  void test_double_error() {
    String source = "3457e";
    ErrorListener listener = new ErrorListener();
    Token token = scanWithListener(source, listener);
    expect(token.type, TokenType.DOUBLE);
    expect(token.offset, 0);
    expect(token.isSynthetic, isTrue);
    // the invalid token is updated to be valid ...
    expect(token.lexeme, source + "0");
    // ... but the length does *not* include the additional character
    // so as to be true to the original source.
    expect(token.length, source.length);
    expect(token.next!.isEof, isTrue);
    expect(listener.errors, hasLength(1));
    TestError error = listener.errors[0];
    expect(error.diagnosticCode, ScannerErrorCode.missingDigit);
    expect(error.offset, source.length - 1);
  }

  @override
  void test_lt() {
    // The scanner does not automatically insert a closer for '<'
    // because it could be part of an expression rather than an opener
    BeginToken lt = _scan('<') as BeginToken;
    expect(lt.next!.isEof, isTrue);
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

  @override
  void test_open_paren() {
    _assertOpenOnly('(', ')');
  }

  void test_open_paren_with_close() {
    _assertOpenClosePair('( )');
  }

  @override
  void test_open_square_bracket() {
    _assertOpenOnly('[', ']');
  }

  void test_open_square_bracket_with_close() {
    _assertOpenClosePair('[ ]');
  }

  @override
  void test_mismatched_opener_in_interpolation() {
    // When openers and closers are mismatched,
    // the scanner favors considering the opener to be mismatched
    // and inserts synthetic closers as needed.
    // r'"${({(}}"' is parsed as r'"${({()})}"'
    // where both ')' are synthetic
    ErrorListener listener = new ErrorListener();
    var stringStart = scanWithListener(r'"${({(}}"', listener);
    BeginToken interpolationStart = stringStart.next as BeginToken;
    BeginToken openParen1 = interpolationStart.next as BeginToken;
    BeginToken openBrace = openParen1.next as BeginToken;
    BeginToken openParen2 = openBrace.next as BeginToken;
    var closeParen2 = openParen2.next!;
    var closeBrace = closeParen2.next!;
    var closeParen1 = closeBrace.next!;
    var interpolationEnd = closeParen1.next!;
    var stringEnd = interpolationEnd.next!;
    var eof = stringEnd.next!;

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
      new TestError(6, ScannerErrorCode.expectedToken, [')']),
      new TestError(7, ScannerErrorCode.expectedToken, [')']),
    ]);
  }

  @override
  void test_unmatched_openers() {
    ErrorListener listener = new ErrorListener();
    // The scanner inserts missing closers except for '<'
    BeginToken openBrace = scanWithListener('{[(<', listener) as BeginToken;
    BeginToken openBracket = openBrace.next as BeginToken;
    BeginToken openParen = openBracket.next as BeginToken;
    BeginToken openLT = openParen.next as BeginToken;
    var closeParen = openLT.next!;
    var closeBracket = closeParen.next!;
    var closeBrace = closeBracket.next!;
    var eof = closeBrace.next!;

    expect(openBrace.endGroup, same(closeBrace));
    expect(openBracket.endGroup, same(closeBracket));
    expect(openParen.endGroup, same(closeParen));
    expect(eof.isEof, true);

    listener.assertErrors([
      new TestError(4, ScannerErrorCode.expectedToken, [')']),
      new TestError(4, ScannerErrorCode.expectedToken, [']']),
      new TestError(4, ScannerErrorCode.expectedToken, ['}']),
    ]);
  }

  Token _scan(String source) {
    ErrorListener listener = new ErrorListener();
    Token token = scanWithListener(source, listener);
    listener.assertNoErrors();
    return token;
  }

  Token extractErrors(Token firstToken, ErrorListener listener) {
    var token = firstToken;
    // The default recovery strategy used by scanString
    // places all error tokens at the head of the stream.
    while (token.type == TokenType.BAD_INPUT) {
      translateErrorToken(token as ErrorToken, (
        ScannerErrorCode errorCode,
        int offset,
        List<Object>? arguments,
      ) {
        listener.errors.add(new TestError(offset, errorCode, arguments));
      });
      token = token.next!;
    }
    if (!token.previous!.isEof) {
      new Token.eof(-1).setNext(token);
    }
    return token;
  }

  /// Assert that the tokens in the stream are correctly connected prev/next.
  void assertValidTokenStream(Token firstToken, {bool errorsFirst = false}) {
    Token token = firstToken;
    Token previous = token.previous!;
    expect(previous.isEof, isTrue, reason: 'Missing leading EOF');
    expect(previous.next, token, reason: 'Invalid leading EOF');
    expect(previous.previous, previous, reason: 'Invalid leading EOF');
    if (errorsFirst) {
      while (!token.isEof && token is ErrorToken) {
        token = token.next!;
      }
    }
    var isNotErrorToken = isNot(const TypeMatcher<ErrorToken>());
    while (!token.isEof) {
      if (errorsFirst) expect(token, isNotErrorToken);
      previous = token;
      token = token.next!;
      expect(token, isNotNull, reason: previous.toString());
      expect(token.previous, previous, reason: token.toString());
    }
    expect(token.next, token, reason: 'Invalid trailing EOF');
  }

  /// Assert that all [BeginToken] has a valid `endGroup`
  /// that is in the stream.
  void assertValidBeginTokens(Token firstToken) {
    var openerStack = <BeginToken>[];
    var errorStack = <ErrorToken>[];
    Token token = firstToken;
    while (!token.isEof) {
      if (token is BeginToken) {
        if (token.lexeme != '<') {
          expect(token.endGroup, isNotNull, reason: token.lexeme);
        }
        if (token.endGroup != null) openerStack.add(token);
      } else if (openerStack.isNotEmpty && openerStack.last.endGroup == token) {
        BeginToken beginToken = openerStack.removeLast();
        if (token.isSynthetic) {
          ErrorToken errorToken = errorStack.removeAt(0);
          expect(errorToken.begin, beginToken);
        }
      } else if (token is UnmatchedToken) {
        errorStack.add(token);
      }
      token = token.next!;
    }
    expect(openerStack, isEmpty, reason: 'Missing closers');
    expect(errorStack, isEmpty, reason: 'Extra error tokens');
  }
}
