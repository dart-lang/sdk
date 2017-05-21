// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/fasta/token_utils.dart';
import 'package:front_end/src/fasta/scanner/error_token.dart' as fasta;
import 'package:front_end/src/fasta/scanner/string_scanner.dart' as fasta;
import 'package:front_end/src/fasta/scanner/token.dart' as fasta;
import 'package:front_end/src/fasta/scanner/token_constants.dart' as fasta;
import 'package:front_end/src/scanner/errors.dart';
import 'package:front_end/src/scanner/token.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'scanner_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ScannerTest_Fasta);
    defineReflectiveTests(ScannerTest_Fasta_Direct);
    defineReflectiveTests(ScannerTest_Fasta_Roundtrip);
  });
}

@reflectiveTest
class ScannerTest_Fasta extends ScannerTestBase {
  @override
  Token scanWithListener(String source, ErrorListener listener,
      {bool genericMethodComments: false,
      bool lazyAssignmentOperators: false}) {
    var scanner = new fasta.StringScanner(source,
        includeComments: true,
        scanGenericMethodComments: genericMethodComments,
        scanLazyAssignmentOperators: lazyAssignmentOperators);
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

  @override
  @failingTest
  void test_incomplete_string_interpolation() {
    // TODO(danrubel): fix ToAnalyzerTokenStreamConverter_WithListener
    // to handle synthetic closers in token stream
    super.test_incomplete_string_interpolation();
  }

  @override
  @failingTest
  void test_mismatched_closer() {
    // TODO(paulberry,ahe): Fasta and analyzer recover this error differently.
    // Figure out which recovery technique we want the front end to use.
    super.test_mismatched_closer();
  }

  @override
  @failingTest
  void test_mismatched_opener() {
    // TODO(paulberry,ahe): Fasta and analyzer recover this error differently.
    // Figure out which recovery technique we want the front end to use.
    super.test_mismatched_opener();
  }

  @override
  void test_mismatched_opener_in_interpolation() {
    // When openers and closers are mismatched,
    // fasta favors considering the opener to be mismatched
    // and inserts synthetic closers as needed.
    // r'"${({(}}"' is parsed as r'"${({()})}"'
    // where both ')' are synthetic
    var stringStart = _scan(r'"${({(}}"');
    var interpolationStart = stringStart.next as BeginToken;
    var openParen1 = interpolationStart.next as BeginToken;
    var openBrace = openParen1.next as BeginToken;
    var openParen2 = openBrace.next as BeginToken;
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
  @failingTest
  void test_string_multi_unterminated() {
    // TODO(paulberry,ahe): bad error recovery.
    super.test_string_multi_unterminated();
  }

  @override
  @failingTest
  void test_string_multi_unterminated_interpolation_block() {
    // TODO(paulberry,ahe): bad error recovery.
    super.test_string_multi_unterminated_interpolation_block();
  }

  @override
  @failingTest
  void test_string_multi_unterminated_interpolation_identifier() {
    // TODO(paulberry,ahe): bad error recovery.
    super.test_string_multi_unterminated_interpolation_identifier();
  }

  @override
  @failingTest
  void test_string_raw_multi_unterminated() {
    // TODO(paulberry,ahe): bad error recovery.
    super.test_string_raw_multi_unterminated();
  }

  @override
  @failingTest
  void test_string_raw_simple_unterminated_eof() {
    // TODO(paulberry,ahe): bad error recovery.
    super.test_string_raw_simple_unterminated_eof();
  }

  @override
  @failingTest
  void test_string_raw_simple_unterminated_eol() {
    // TODO(paulberry,ahe): bad error recovery.
    super.test_string_raw_simple_unterminated_eol();
  }

  @override
  @failingTest
  void test_string_simple_unterminated_eof() {
    // TODO(paulberry,ahe): bad error recovery.
    super.test_string_simple_unterminated_eof();
  }

  @override
  @failingTest
  void test_string_simple_unterminated_eol() {
    // TODO(paulberry,ahe): bad error recovery.
    super.test_string_simple_unterminated_eol();
  }

  @override
  @failingTest
  void test_string_simple_unterminated_interpolation_block() {
    // TODO(paulberry,ahe): bad error recovery.
    super.test_string_simple_unterminated_interpolation_block();
  }

  @override
  @failingTest
  void test_string_simple_unterminated_interpolation_identifier() {
    // TODO(paulberry,ahe): bad error recovery.
    super.test_string_simple_unterminated_interpolation_identifier();
  }

  @override
  void test_unmatched_openers() {
    var openBrace = _scan('{[(') as BeginToken;
    var openBracket = openBrace.next as BeginToken;
    var openParen = openBracket.next as BeginToken;
    var closeParen = openParen.next;
    var closeBracket = closeParen.next;
    var closeBrace = closeBracket.next;
    expect(closeBrace.next.type, TokenType.EOF);
    expect(openBrace.endToken, same(closeBrace));
    expect(openBracket.endToken, same(closeBracket));
    expect(openParen.endToken, same(closeParen));
  }

  Token _scan(String source,
      {bool genericMethodComments: false,
      bool lazyAssignmentOperators: false}) {
    ErrorListener listener = new ErrorListener();
    Token token = scanWithListener(source, listener,
        genericMethodComments: genericMethodComments,
        lazyAssignmentOperators: lazyAssignmentOperators);
    listener.assertNoErrors();
    return token;
  }
}

/// Base class for scanner tests that examine the token stream in Fasta format.
abstract class ScannerTest_Fasta_Base {
  Token scan(String source);

  void test_match_angle_brackets() {
    var x = scan('x<y>');
    var lessThan = x.next as fasta.BeginGroupToken;
    var y = lessThan.next;
    var greaterThan = y.next;
    expect(greaterThan.next.isEof, isTrue);
    expect(lessThan.endGroup, same(greaterThan));
  }

  void test_match_angle_brackets_gt_gt() {
    // When a ">>" appears in the token stream, Fasta's scanner matches it to
    // the outer "<".  The inner "<" is left unmatched.
    var x = scan('x<y<z>>');
    var lessThan1 = x.next as fasta.BeginGroupToken;
    var y = lessThan1.next;
    var lessThan2 = y.next as fasta.BeginGroupToken;
    var z = lessThan2.next;
    var greaterThans = z.next;
    expect(greaterThans.next.isEof, isTrue);
    expect(lessThan1.endGroup, same(greaterThans));
    expect(lessThan2.endGroup, isNull);
  }

  void test_match_angle_brackets_interrupted_by_close_brace() {
    // A "}" appearing in the token stream interrupts matching of "<" and ">".
    var openBrace = scan('{x<y}>z') as fasta.BeginGroupToken;
    var x = openBrace.next;
    var lessThan = x.next as fasta.BeginGroupToken;
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
    var openBracket = scan('[x<y]>z') as fasta.BeginGroupToken;
    var x = openBracket.next;
    var lessThan = x.next as fasta.BeginGroupToken;
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
    var openParen = scan('(x<y)>z') as fasta.BeginGroupToken;
    var x = openParen.next;
    var lessThan = x.next as fasta.BeginGroupToken;
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
    var lessThan = x.next as fasta.BeginGroupToken;
    var beginString = lessThan.next;
    var beginInterpolation = beginString.next as fasta.BeginGroupToken;
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
    var lessThan = x.next as fasta.BeginGroupToken;
    var openBrace = lessThan.next as fasta.BeginGroupToken;
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
    var lessThan = x.next as fasta.BeginGroupToken;
    var y = lessThan.next;
    var openBracket = y.next as fasta.BeginGroupToken;
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
    var lessThan = x.next as fasta.BeginGroupToken;
    var y = lessThan.next;
    var openParen = y.next as fasta.BeginGroupToken;
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
    var lessThan1 = x.next as fasta.BeginGroupToken;
    var y = lessThan1.next;
    var lessThan2 = y.next as fasta.BeginGroupToken;
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
    var lessThan = x.next as fasta.BeginGroupToken;
    var y = lessThan.next;
    var greaterThans = y.next;
    var z = greaterThans.next;
    expect(z.next.isEof, isTrue);
    expect(lessThan.endGroup, isNull);
  }
}

/// Scanner tests that exercise the Fasta scanner directly.
@reflectiveTest
class ScannerTest_Fasta_Direct extends ScannerTest_Fasta_Base {
  @override
  Token scan(String source) {
    var scanner = new fasta.StringScanner(source, includeComments: true);
    return scanner.tokenize();
  }
}

/// Scanner tests that exercise the Fasta scanner, then convert the tokens to
/// analyzer tokens, then convert back to Fasta tokens before checking
/// assertions.
@reflectiveTest
class ScannerTest_Fasta_Roundtrip extends ScannerTest_Fasta_Base {
  @override
  Token scan(String source) {
    var scanner = new fasta.StringScanner(source, includeComments: true);
    var fastaTokenStream = scanner.tokenize();
    var analyzerTokenStream = new ToAnalyzerTokenStreamConverter_NoErrors()
        .convertTokens(fastaTokenStream);
    return fromAnalyzerTokenStream(analyzerTokenStream);
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
