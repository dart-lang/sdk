// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:convert';

import 'package:analyzer/src/fasta/token_utils.dart';
import 'package:front_end/src/fasta/fasta_codes.dart';
import 'package:front_end/src/fasta/scanner.dart' as usedForFuzzTesting;
import 'package:front_end/src/fasta/scanner/error_token.dart' as fasta;
import 'package:front_end/src/fasta/scanner/string_scanner.dart' as fasta;
import 'package:front_end/src/fasta/scanner/token.dart' as fasta;
import 'package:front_end/src/fasta/scanner/token_constants.dart' as fasta;
import 'package:front_end/src/fasta/scanner/utf8_bytes_scanner.dart' as fasta;
import 'package:front_end/src/scanner/errors.dart';
import 'package:front_end/src/scanner/token.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'scanner_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ScannerTest_Fasta);
    defineReflectiveTests(ScannerTest_Fasta_FuzzTestAPI);
    defineReflectiveTests(ScannerTest_Fasta_UTF8);
    defineReflectiveTests(ScannerTest_Fasta_Direct);
    defineReflectiveTests(ScannerTest_Fasta_Direct_UTF8);
  });
}

@reflectiveTest
class ScannerTest_Fasta_FuzzTestAPI {
  test_API() {
    // These two API are used when fuzz testing the scanner.
    String source = 'class A { }';

    usedForFuzzTesting.ScannerResult result =
        usedForFuzzTesting.scanString(source);
    expect(result?.hasErrors, isFalse);
    expect(result.tokens?.type, same(Keyword.CLASS));

    // UTF8 encode source with trailing zero
    List<int> bytes = UTF8.encode(source).toList();
    bytes.add(0);

    result = usedForFuzzTesting.scan(bytes);
    expect(result?.hasErrors, isFalse);
    expect(result.tokens?.type, same(Keyword.CLASS));
  }
}

@reflectiveTest
class ScannerTest_Fasta_UTF8 extends ScannerTest_Fasta {
  @override
  createScanner(String source, {bool genericMethodComments: false}) {
    List<int> encoded = UTF8.encode(source).toList(growable: true);
    encoded.add(0); // Ensure 0 terminted bytes for UTF8 scanner
    return new fasta.Utf8BytesScanner(encoded,
        includeComments: true,
        scanGenericMethodComments: genericMethodComments);
  }

  test_invalid_utf8() {
    printBytes(List<int> bytes) {
      var hex = bytes.map((b) => '0x${b.toRadixString(16).toUpperCase()}');
      print('$bytes\n[${hex.join(', ')}]');
      try {
        UTF8.decode(bytes);
      } catch (e) {
        // Bad UTF-8 encoding
        print('  This is invalid UTF-8, but scanner should not crash.');
      }
    }

    scanBytes(List<int> bytes) {
      try {
        return usedForFuzzTesting.scan(bytes);
      } catch (e) {
        print('Failed scanning bytes:');
        printBytes(bytes);
        rethrow;
      }
    }

    for (int byte0 = 1; byte0 <= 0xFF; ++byte0) {
      for (int byte1 = 1; byte1 <= 0xFF; ++byte1) {
        List<int> bytes = [byte0, byte1, 0];
        scanBytes(bytes);
      }
    }
  }
}

@reflectiveTest
class ScannerTest_Fasta extends ScannerTestBase {
  ScannerTest_Fasta() {
    usingFasta = true;
  }

  createScanner(String source, {bool genericMethodComments: false}) =>
      new fasta.StringScanner(source,
          includeComments: true,
          scanGenericMethodComments: genericMethodComments);

  @override
  Token scanWithListener(String source, ErrorListener listener,
      {bool genericMethodComments: false,
      bool lazyAssignmentOperators: false}) {
    var scanner =
        createScanner(source, genericMethodComments: genericMethodComments);
    var token = scanner.tokenize();
    return new ToAnalyzerTokenStreamConverter_WithListener(listener)
        .convertTokens(token);
  }

  void test_comments() {
    const source = '''
       /// Doc comment before class
       /// second line
       /// third
       class Foo {
         // Random comment
         Object someField; // trailing comment
         dynamic secondField;
         /// Method doc
         void someMethod(/* comment before closing paren */) {
           // body comment
         }
         /** Doc comment 2 */
         Foo2 bar() => new Baz();
       } // EOF comment
    ''';

    Token scanSource({bool includeComments}) {
      return new fasta.StringScanner(source, includeComments: includeComments)
          .tokenize();
    }

    int tokenCount = 0;
    Token token = scanSource(includeComments: false);
    while (!token.isEof) {
      ++tokenCount;
      // Assert no comments
      expect(token.precedingComments, isNull);
      expect(token.type.kind, isNot(fasta.COMMENT_TOKEN));
      token = token.next;
    }
    expect(token.precedingComments, isNull);
    expect(tokenCount, 26);

    tokenCount = 0;
    int previousEnd = 0;
    int spotCheckCount = 0;
    int commentTokenCount = 0;
    token = scanSource(includeComments: true);
    while (!token.isEof) {
      ++tokenCount;
      // Assert valid comments
      fasta.CommentToken comment = token.precedingComments;
      while (comment != null) {
        ++commentTokenCount;
        expect(comment.type.kind, fasta.COMMENT_TOKEN);
        expect(comment.charOffset, greaterThanOrEqualTo(previousEnd));
        previousEnd = comment.charOffset + comment.charCount;
        comment = comment.next;
      }
      expect(token.type.kind, isNot(fasta.COMMENT_TOKEN));
      expect(token.charOffset, greaterThanOrEqualTo(previousEnd));
      previousEnd = token.charOffset + token.charCount;

      // Spot check for specific token/comment combinations
      if (token.lexeme == 'class') {
        ++spotCheckCount;
        expect(token.precedingComments?.lexeme, '/// Doc comment before class');
        expect(token.precedingComments?.next?.lexeme, '/// second line');
        expect(token.precedingComments?.next?.next?.lexeme, '/// third');
        expect(token.precedingComments?.next?.next?.next, isNull);
      } else if (token.lexeme == 'Foo2') {
        ++spotCheckCount;
        expect(token.precedingComments?.lexeme, '/** Doc comment 2 */');
      } else if (token.lexeme == ')') {
        if (token.precedingComments != null) {
          ++spotCheckCount;
          expect(token.precedingComments?.lexeme,
              '/* comment before closing paren */');
          expect(token.precedingComments?.next, isNull);
        }
      }

      token = token.next;
    }
    expect(tokenCount, 26);
    expect(spotCheckCount, 3);
    expect(commentTokenCount, 9);
    expect(token.precedingComments?.lexeme, '// EOF comment');
  }

  void test_CommentToken_remove() {
    const code = '''
/// aaa
/// bbbb
/// ccccc
main() {}
''';

    Token token;
    fasta.CommentToken c1;
    fasta.CommentToken c2;
    fasta.CommentToken c3;

    void prepareTokens() {
      token = new fasta.StringScanner(code, includeComments: true).tokenize();

      expect(token.type.kind, fasta.IDENTIFIER_TOKEN);

      c1 = token.precedingComments;
      c2 = c1.next;
      c3 = c2.next;
      expect(c3.next, isNull);

      expect(c1.parent, token);
      expect(c2.parent, token);
      expect(c3.parent, token);

      expect(c1.lexeme, '/// aaa');
      expect(c2.lexeme, '/// bbbb');
      expect(c3.lexeme, '/// ccccc');
    }

    // Remove the first token.
    {
      prepareTokens();
      c1.remove();
      expect(token.precedingComments, c2);
      expect(c2.next, c3);
      expect(c3.next, isNull);
    }

    // Remove the second token.
    {
      prepareTokens();
      c2.remove();
      expect(token.precedingComments, c1);
      expect(c1.next, c3);
      expect(c3.next, isNull);
    }

    // Remove the last token.
    {
      prepareTokens();
      c3.remove();
      expect(token.precedingComments, c1);
      expect(c1.next, c2);
      expect(c2.next, isNull);
    }
  }

  void test_double_error() {
    String source = "3457e";
    ErrorListener listener = new ErrorListener();
    Token token = scanWithListener(source, listener);
    expect(token, isNotNull);
    expect(token.type, TokenType.DOUBLE);
    expect(token.offset, 0);
    expect(token.isSynthetic, isTrue);
    // the invalid token is updated to be valid ...
    expect(token.lexeme, source + "0");
    // ... but the length does *not* include the additional character
    // so as to be true to the original source.
    expect(token.length, source.length);
    expect(token.next.isEof, isTrue);
    expect(listener.errors, hasLength(1));
    TestError error = listener.errors[0];
    expect(error.errorCode, ScannerErrorCode.MISSING_DIGIT);
    expect(error.offset, source.length - 1);
  }

  @override
  void test_mismatched_opener_in_interpolation() {
    // When openers and closers are mismatched,
    // fasta favors considering the opener to be mismatched
    // and inserts synthetic closers as needed.
    // r'"${({(}}"' is parsed as r'"${({()})}"'
    // where both ')' are synthetic
    ErrorListener listener = new ErrorListener();
    BeginToken interpolationStart =
        scanWithListener(r'"${({(}}"', listener).next;
    BeginToken openParen1 = interpolationStart.next;
    BeginToken openBrace = openParen1.next;
    BeginToken openParen2 = openBrace.next;
    var closeParen2 = openParen2.next;
    var closeBrace = closeParen2.next;
    var closeParen1 = closeBrace.next;
    var interpolationEnd = closeParen1.next;
    var stringEnd = interpolationEnd.next;
    expect(stringEnd.next.type, TokenType.EOF);
    expect(interpolationStart.endToken, same(interpolationEnd));
    expect(openParen1.endToken, same(closeParen1));
    expect(openBrace.endToken, same(closeBrace));
    expect(openParen2.endToken, same(closeParen2));
    listener.assertErrors([
      new TestError(3, ScannerErrorCode.EXPECTED_TOKEN, [')']),
      new TestError(5, ScannerErrorCode.EXPECTED_TOKEN, [')']),
    ]);
  }

  void test_next_previous() {
    const source = 'int a; /*1*/ /*2*/ /*3*/ B f(){if (a < 2) {}}';
    Token token =
        new fasta.StringScanner(source, includeComments: true).tokenize();
    while (!token.isEof) {
      expect(token.next.previous, token);
      fasta.CommentToken commentToken = token.precedingComments;
      while (commentToken != null) {
        if (commentToken.next != null) {
          expect(commentToken.next.previous, commentToken);
        }
        commentToken = commentToken.next;
      }
      token = token.next;
    }
  }

  @override
  void test_unmatched_openers() {
    ErrorListener listener = new ErrorListener();
    BeginToken openBrace = scanWithListener('{[(', listener);
    BeginToken openBracket = openBrace.next;
    BeginToken openParen = openBracket.next;
    var closeParen = openParen.next;
    var closeBracket = closeParen.next;
    var closeBrace = closeBracket.next;
    expect(closeBrace.next.type, TokenType.EOF);
    expect(openBrace.endToken, same(closeBrace));
    expect(openBracket.endToken, same(closeBracket));
    expect(openParen.endToken, same(closeParen));
    listener.assertErrors([
      new TestError(0, ScannerErrorCode.EXPECTED_TOKEN, ['}']),
      new TestError(1, ScannerErrorCode.EXPECTED_TOKEN, [']']),
      new TestError(2, ScannerErrorCode.EXPECTED_TOKEN, [')']),
    ]);
  }
}

/// Base class for scanner tests that examine the token stream in Fasta format.
abstract class ScannerTest_Fasta_Base {
  Token scan(String source);

  expectToken(Token token, TokenType type, int offset, int length,
      {bool isSynthetic: false, String lexeme}) {
    String description = '${token.type} $token';
    expect(token.type, type, reason: description);
    expect(token.offset, offset, reason: description);
    expect(token.length, length, reason: description);
    expect(token.isSynthetic, isSynthetic, reason: description);
    if (lexeme != null) {
      expect(token.lexeme, lexeme, reason: description);
    }
  }

  void test_string_simple_interpolation_missingIdentifier() {
    Token token = scan("'\$x\$'");
    expectToken(token, TokenType.STRING, 0, 1, lexeme: "'");

    token = token.next;
    expectToken(token, TokenType.STRING_INTERPOLATION_IDENTIFIER, 1, 1);

    token = token.next;
    expectToken(token, TokenType.IDENTIFIER, 2, 1, lexeme: 'x');

    token = token.next;
    expectToken(token, TokenType.STRING, 3, 0, lexeme: '', isSynthetic: true);

    token = token.next;
    expectToken(token, TokenType.STRING_INTERPOLATION_IDENTIFIER, 3, 1);

    token = token.next;
    expectToken(token, TokenType.IDENTIFIER, 4, 0,
        lexeme: '', isSynthetic: true);

    token = token.next;
    expect((token as fasta.ErrorToken).errorCode,
        same(codeUnexpectedDollarInString));

    token = token.next;
    expectToken(token, TokenType.STRING, 4, 1, lexeme: "'");
  }

  void test_string_simple_unterminated_interpolation_block() {
    Token token = scan(r'"foo ${bar');
    expectToken(token, TokenType.STRING, 0, 5, lexeme: '"foo ');

    token = token.next;
    expectToken(token, TokenType.STRING_INTERPOLATION_EXPRESSION, 5, 2);
    BeginToken interpolationStart = token;

    token = token.next;
    expectToken(token, TokenType.IDENTIFIER, 7, 3, lexeme: 'bar');

    // Expect interpolation to be terminated before string is closed
    token = token.next;
    expectToken(token, TokenType.CLOSE_CURLY_BRACKET, 10, 0,
        isSynthetic: true, lexeme: '}');
    expect(interpolationStart.endToken, same(token));

    token = token.next;
    expect((token as fasta.ErrorToken).errorCode, same(codeUnmatchedToken));
    expect((token as fasta.UnmatchedToken).begin, same(interpolationStart));

    token = token.next;
    expectToken(token, TokenType.STRING, 10, 0, isSynthetic: true, lexeme: '"');

    token = token.next;
    expect((token as fasta.ErrorToken).errorCode, same(codeUnterminatedString));
    expect((token as fasta.UnterminatedString).start, '"');
  }

  void test_string_simple_unterminated_interpolation_block2() {
    Token token = scan(r'"foo ${bar(baz[');
    expectToken(token, TokenType.STRING, 0, 5, lexeme: '"foo ');

    token = token.next;
    expectToken(token, TokenType.STRING_INTERPOLATION_EXPRESSION, 5, 2);
    BeginToken interpolationStart = token;

    token = token.next;
    expectToken(token, TokenType.IDENTIFIER, 7, 3, lexeme: 'bar');

    token = token.next;
    expectToken(token, TokenType.OPEN_PAREN, 10, 1);
    BeginToken openParen = token;

    token = token.next;
    expectToken(token, TokenType.IDENTIFIER, 11, 3, lexeme: 'baz');

    token = token.next;
    expectToken(token, TokenType.OPEN_SQUARE_BRACKET, 14, 1);
    BeginToken openSquareBracket = token;

    token = token.next;
    expectToken(token, TokenType.CLOSE_SQUARE_BRACKET, 15, 0,
        isSynthetic: true, lexeme: ']');
    expect(openSquareBracket.endToken, same(token));

    token = token.next;
    expect((token as fasta.ErrorToken).errorCode, same(codeUnmatchedToken));
    expect((token as fasta.UnmatchedToken).begin, same(openSquareBracket));

    token = token.next;
    expectToken(token, TokenType.CLOSE_PAREN, 15, 0,
        isSynthetic: true, lexeme: ')');
    expect(openParen.endToken, same(token));

    token = token.next;
    expect((token as fasta.ErrorToken).errorCode, same(codeUnmatchedToken));
    expect((token as fasta.UnmatchedToken).begin, same(openParen));

    token = token.next;
    expectToken(token, TokenType.CLOSE_CURLY_BRACKET, 15, 0,
        isSynthetic: true, lexeme: '}');
    expect(interpolationStart.endToken, same(token));

    token = token.next;
    expect((token as fasta.ErrorToken).errorCode, same(codeUnmatchedToken));
    expect((token as fasta.UnmatchedToken).begin, same(interpolationStart));

    token = token.next;
    expectToken(token, TokenType.STRING, 15, 0, isSynthetic: true, lexeme: '"');

    token = token.next;
    expect((token as fasta.ErrorToken).errorCode, same(codeUnterminatedString));
    expect((token as fasta.UnterminatedString).start, '"');
  }

  void test_string_simple_missing_interpolation_identifier() {
    Token token = scan(r'"foo $');
    expectToken(token, TokenType.STRING, 0, 5, lexeme: '"foo ');

    token = token.next;
    expectToken(token, TokenType.STRING_INTERPOLATION_IDENTIFIER, 5, 1);

    token = token.next;
    expectToken(token, TokenType.IDENTIFIER, 6, 0,
        isSynthetic: true, lexeme: '');

    token = token.next;
    expect((token as fasta.ErrorToken).errorCode,
        same(codeUnexpectedDollarInString));

    token = token.next;
    expectToken(token, TokenType.STRING, 6, 0, isSynthetic: true, lexeme: '"');

    token = token.next;
    expect((token as fasta.ErrorToken).errorCode, same(codeUnterminatedString));
    expect((token as fasta.UnterminatedString).start, '"');
  }

  void test_string_multi_unterminated() {
    Token token = scan("'''string");
    expectToken(token, TokenType.STRING, 0, 9,
        lexeme: "'''string'''", isSynthetic: true);

    token = token.next;
    expect((token as fasta.ErrorToken).errorCode, same(codeUnterminatedString));
    expect((token as fasta.UnterminatedString).start, "'''");
  }

  void test_string_raw_multi_unterminated() {
    Token token = scan("r'''string");
    expectToken(token, TokenType.STRING, 0, 10,
        lexeme: "r'''string'''", isSynthetic: true);

    token = token.next;
    expect((token as fasta.ErrorToken).errorCode, same(codeUnterminatedString));
    expect((token as fasta.UnterminatedString).start, "r'''");
  }

  void test_string_raw_simple_unterminated_eof() {
    Token token = scan("r'string");
    expectToken(token, TokenType.STRING, 0, 8,
        lexeme: "r'string'", isSynthetic: true);

    token = token.next;
    expect((token as fasta.ErrorToken).errorCode, same(codeUnterminatedString));
    expect((token as fasta.UnterminatedString).start, "r'");
  }

  void test_string_raw_simple_unterminated_eol() {
    Token token = scan("r'string\n");
    expectToken(token, TokenType.STRING, 0, 8,
        lexeme: "r'string'", isSynthetic: true);

    token = token.next;
    expect((token as fasta.ErrorToken).errorCode, same(codeUnterminatedString));
    expect((token as fasta.UnterminatedString).start, "r'");
  }

  void test_string_simple_unterminated_eof() {
    Token token = scan("'string");
    expectToken(token, TokenType.STRING, 0, 7,
        lexeme: "'string'", isSynthetic: true);

    token = token.next;
    expect((token as fasta.ErrorToken).errorCode, same(codeUnterminatedString));
    expect((token as fasta.UnterminatedString).start, "'");
  }

  void test_string_simple_unterminated_eol() {
    Token token = scan("'string\n");
    expectToken(token, TokenType.STRING, 0, 7,
        lexeme: "'string'", isSynthetic: true);

    token = token.next;
    expect((token as fasta.ErrorToken).errorCode, same(codeUnterminatedString));
    expect((token as fasta.UnterminatedString).start, "'");
  }

  void test_match_angle_brackets() {
    var x = scan('x<y>');
    BeginToken lessThan = x.next;
    var y = lessThan.next;
    var greaterThan = y.next;
    expect(greaterThan.next.isEof, isTrue);
    expect(lessThan.endGroup, same(greaterThan));
  }

  void test_match_angle_brackets_gt_gt() {
    // When a ">>" appears in the token stream, Fasta's scanner matches it to
    // the outer "<".  The inner "<" is left unmatched.
    var x = scan('x<y<z>>');
    BeginToken lessThan1 = x.next;
    var y = lessThan1.next;
    BeginToken lessThan2 = y.next;
    var z = lessThan2.next;
    var greaterThans = z.next;
    expect(greaterThans.next.isEof, isTrue);
    expect(lessThan1.endGroup, same(greaterThans));
    expect(lessThan2.endGroup, isNull);
  }

  void test_match_angle_brackets_interrupted_by_close_brace() {
    // A "}" appearing in the token stream interrupts matching of "<" and ">".
    BeginToken openBrace = scan('{x<y}>z');
    var x = openBrace.next;
    BeginToken lessThan = x.next;
    var y = lessThan.next;
    var closeBrace = y.next;
    var greaterThan = closeBrace.next;
    var z = greaterThan.next;
    expect(z.next.isEof, isTrue);
    expect(openBrace.endGroup, same(closeBrace));
    expect(lessThan.endGroup, isNull);
  }

  void test_match_angle_brackets_interrupted_by_close_bracket() {
    // A "]" appearing in the token stream interrupts matching of "<" and ">".
    BeginToken openBracket = scan('[x<y]>z');
    var x = openBracket.next;
    BeginToken lessThan = x.next;
    var y = lessThan.next;
    var closeBracket = y.next;
    var greaterThan = closeBracket.next;
    var z = greaterThan.next;
    expect(z.next.isEof, isTrue);
    expect(openBracket.endGroup, same(closeBracket));
    expect(lessThan.endGroup, isNull);
  }

  void test_match_angle_brackets_interrupted_by_close_paren() {
    // A ")" appearing in the token stream interrupts matching of "<" and ">".
    BeginToken openParen = scan('(x<y)>z');
    var x = openParen.next;
    BeginToken lessThan = x.next;
    var y = lessThan.next;
    var closeParen = y.next;
    var greaterThan = closeParen.next;
    var z = greaterThan.next;
    expect(z.next.isEof, isTrue);
    expect(openParen.endGroup, same(closeParen));
    expect(lessThan.endGroup, isNull);
  }

  void test_match_angle_brackets_interrupted_by_interpolation_expr() {
    // A "${" appearing in the token stream interrupts matching of "<" and ">".
    var x = scan(r'x<"${y>z}"');
    BeginToken lessThan = x.next;
    var beginString = lessThan.next;
    BeginToken beginInterpolation = beginString.next;
    var y = beginInterpolation.next;
    var greaterThan = y.next;
    var z = greaterThan.next;
    var endInterpolation = z.next;
    var endString = endInterpolation.next;
    expect(endString.next.isEof, isTrue);
    expect(lessThan.endGroup, isNull);
    expect(beginInterpolation.endGroup, same(endInterpolation));
  }

  void test_match_angle_brackets_interrupted_by_open_brace() {
    // A "{" appearing in the token stream interrupts matching of "<" and ">".
    var x = scan('x<{y>z}');
    BeginToken lessThan = x.next;
    BeginToken openBrace = lessThan.next;
    var y = openBrace.next;
    var greaterThan = y.next;
    var z = greaterThan.next;
    var closeBrace = z.next;
    expect(closeBrace.next.isEof, isTrue);
    expect(lessThan.endGroup, isNull);
    expect(openBrace.endGroup, same(closeBrace));
  }

  void test_match_angle_brackets_interrupted_by_open_bracket() {
    // A "[" appearing in the token stream interrupts matching of "<" and ">".
    var x = scan('x<y[z>a]');
    BeginToken lessThan = x.next;
    var y = lessThan.next;
    BeginToken openBracket = y.next;
    var z = openBracket.next;
    var greaterThan = z.next;
    var a = greaterThan.next;
    var closeBracket = a.next;
    expect(closeBracket.next.isEof, isTrue);
    expect(lessThan.endGroup, isNull);
    expect(openBracket.endGroup, same(closeBracket));
  }

  void test_match_angle_brackets_interrupted_by_open_paren() {
    // A "(" appearing in the token stream interrupts matching of "<" and ">".
    var x = scan('x<y(z>a)');
    BeginToken lessThan = x.next;
    var y = lessThan.next;
    BeginToken openParen = y.next;
    var z = openParen.next;
    var greaterThan = z.next;
    var a = greaterThan.next;
    var closeParen = a.next;
    expect(closeParen.next.isEof, isTrue);
    expect(lessThan.endGroup, isNull);
    expect(openParen.endGroup, same(closeParen));
  }

  void test_match_angle_brackets_nested() {
    var x = scan('x<y<z>,a>');
    BeginToken lessThan1 = x.next;
    var y = lessThan1.next;
    BeginToken lessThan2 = y.next;
    var z = lessThan2.next;
    var greaterThan1 = z.next;
    var comma = greaterThan1.next;
    var a = comma.next;
    var greaterThan2 = a.next;
    expect(greaterThan2.next.isEof, isTrue);
    expect(lessThan1.endGroup, same(greaterThan2));
    expect(lessThan2.endGroup, same(greaterThan1));
  }

  void test_match_angle_brackets_unmatched_gt_gt() {
    // When a ">>" appears in the token stream and there is no outer "<",
    // Fasta's scanner leaves the inner "<" unmatched.
    var x = scan('x<y>>z');
    BeginToken lessThan = x.next;
    var y = lessThan.next;
    var greaterThans = y.next;
    var z = greaterThans.next;
    expect(z.next.isEof, isTrue);
    expect(lessThan.endGroup, isNull);
  }
}

/// Scanner tests that exercise the Fasta scanner directly.
@reflectiveTest
class ScannerTest_Fasta_Direct_UTF8 extends ScannerTest_Fasta_Direct {
  createScanner(String source, {bool includeComments}) {
    List<int> encoded = UTF8.encode(source).toList(growable: true);
    encoded.add(0); // Ensure 0 terminted bytes for UTF8 scanner
    return new fasta.Utf8BytesScanner(encoded,
        includeComments: includeComments);
  }
}

/// Scanner tests that exercise the Fasta scanner directly.
@reflectiveTest
class ScannerTest_Fasta_Direct extends ScannerTest_Fasta_Base {
  createScanner(String source, {bool includeComments}) =>
      new fasta.StringScanner(source, includeComments: includeComments);

  @override
  Token scan(String source) {
    return createScanner(source, includeComments: true).tokenize();
  }

  void test_linestarts() {
    var scanner = createScanner("var\r\ni\n=\n1;\n");
    var token = scanner.tokenize();
    expect(token.lexeme, 'var');
    var lineStarts = scanner.lineStarts;
    expect(lineStarts, orderedEquals([0, 5, 7, 9, 12, 13]));
  }

  void test_linestarts_synthetic_string() {
    var scanner = createScanner("var\r\ns\n=\n'eh'\n'eh\n;\n");
    Token firstToken = scanner.tokenize();
    expect(firstToken.lexeme, 'var');
    var lineStarts = scanner.lineStarts;
    expect(lineStarts, orderedEquals([0, 5, 7, 9, 14, 18, 20, 21]));
    var token = firstToken;
    int index = 0;
    while (!token.isEof) {
      if (token is fasta.ErrorToken) {
        expect(token.charOffset, 14,
            reason: 'error token : $token, ${token.type}');
        expect(token.charCount, 3,
            reason: 'error token : $token, ${token.type}');
      } else {
        expect(token.charOffset, lineStarts[index],
            reason: 'token # $index : $token, ${token.type}');
        ++index;
      }
      token = token.next;
    }
  }

  void test_linestarts_synthetic_string_utf8() {
    var scanner = createScanner("var\r\ns\n=\n'éh'\n'éh\n;\n");
    Token firstToken = scanner.tokenize();
    expect(firstToken.lexeme, 'var');
    var lineStarts = scanner.lineStarts;
    expect(lineStarts, orderedEquals([0, 5, 7, 9, 14, 18, 20, 21]));
    var token = firstToken;
    int index = 0;
    while (!token.isEof) {
      if (token is! fasta.ErrorToken) {
        expect(token.charOffset, lineStarts[index],
            reason: 'token # $index : $token, ${token.type}');
        ++index;
      }
      token = token.next;
    }
  }
}

/// Override of [ToAnalyzerTokenStreamConverter] that verifies that there are no
/// errors.
class ToAnalyzerTokenStreamConverter_NoErrors
    extends ToAnalyzerTokenStreamConverter {
  @override
  void reportError(
      ScannerErrorCode errorCode, int offset, List<Object> arguments) {
    fail('Unexpected error: $errorCode, $offset, $arguments');
  }
}

/// Override of [ToAnalyzerTokenStreamConverter] that records errors in an
/// [ErrorListener].
class ToAnalyzerTokenStreamConverter_WithListener
    extends ToAnalyzerTokenStreamConverter {
  final ErrorListener _listener;

  ToAnalyzerTokenStreamConverter_WithListener(this._listener);

  @override
  void reportError(
      ScannerErrorCode errorCode, int offset, List<Object> arguments) {
    _listener.errors.add(new TestError(offset, errorCode, arguments));
  }
}
