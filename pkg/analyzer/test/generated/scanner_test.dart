// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine.scanner_test;

import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_collection.dart' show TokenMap;
import 'package:unittest/unittest.dart';

import '../reflective_tests.dart';
import 'test_support.dart';


main() {
  groupSep = ' | ';
  runReflectiveTests(CharSequenceReaderTest);
  runReflectiveTests(IncrementalScannerTest);
  runReflectiveTests(KeywordStateTest);
  runReflectiveTests(ScannerTest);
  runReflectiveTests(TokenTypeTest);
}

class CharSequenceReaderTest {
  void test_advance() {
    CharSequenceReader reader = new CharSequenceReader("x");
    expect(reader.advance(), 0x78);
    expect(reader.advance(), -1);
    expect(reader.advance(), -1);
  }

  void test_creation() {
    expect(new CharSequenceReader("x"), isNotNull);
  }

  void test_getOffset() {
    CharSequenceReader reader = new CharSequenceReader("x");
    expect(reader.offset, -1);
    reader.advance();
    expect(reader.offset, 0);
    reader.advance();
    expect(reader.offset, 0);
  }

  void test_getString() {
    CharSequenceReader reader = new CharSequenceReader("xyzzy");
    reader.offset = 3;
    expect(reader.getString(1, 0), "yzz");
    expect(reader.getString(2, 1), "zzy");
  }

  void test_peek() {
    CharSequenceReader reader = new CharSequenceReader("xy");
    expect(reader.peek(), 0x78);
    expect(reader.peek(), 0x78);
    reader.advance();
    expect(reader.peek(), 0x79);
    expect(reader.peek(), 0x79);
    reader.advance();
    expect(reader.peek(), -1);
    expect(reader.peek(), -1);
  }

  void test_setOffset() {
    CharSequenceReader reader = new CharSequenceReader("xyz");
    reader.offset = 2;
    expect(reader.offset, 2);
  }
}

class IncrementalScannerTest extends EngineTestCase {
  /**
   * The first token from the token stream resulting from parsing the original
   * source, or `null` if [scan] has not been invoked.
   */
  Token _originalTokens;

  /**
   * The scanner used to perform incremental scanning, or `null` if [scan] has
   * not been invoked.
   */
  IncrementalScanner _incrementalScanner;

  /**
   * The first token from the token stream resulting from performing an
   * incremental scan, or `null` if [scan] has not been invoked.
   */
  Token _incrementalTokens;

  void fail_insert_beginning() {
    // This is currently reporting the changed range as being from 0 to 5, but
    // that would force us to re-parse both classes, which is clearly
    // sub-optimal.
    //
    // "class B {}"
    // "class A {} class B {}"
    _scan("", "", "class A {} ", "class B {}");
    _assertTokens(-1, 4, ["class", "A", "{", "}", "class", "B", "{", "}"]);
    expect(_incrementalScanner.hasNonWhitespaceChange, isTrue);
  }

  void test_delete_identifier_beginning() {
    // "abs + b;"
    // "s + b;")
    _scan("", "ab", "", "s + b;");
    _assertTokens(-1, 1, ["s", "+", "b", ";"]);
    expect(_incrementalScanner.hasNonWhitespaceChange, isTrue);
  }

  void test_delete_identifier_end() {
    // "abs + b;"
    // "a + b;")
    _scan("a", "bs", "", " + b;");
    _assertTokens(-1, 1, ["a", "+", "b", ";"]);
    expect(_incrementalScanner.hasNonWhitespaceChange, isTrue);
  }

  void test_delete_identifier_middle() {
    // "abs + b;"
    // "as + b;")
    _scan("a", "b", "", "s + b;");
    _assertTokens(-1, 1, ["as", "+", "b", ";"]);
    expect(_incrementalScanner.hasNonWhitespaceChange, isTrue);
  }

  void test_delete_mergeTokens() {
    // "a + b + c;"
    // "ac;")
    _scan("a", " + b + ", "", "c;");
    _assertTokens(-1, 1, ["ac", ";"]);
    expect(_incrementalScanner.hasNonWhitespaceChange, isTrue);
  }

  void test_delete_whitespace() {
    // "a + b + c;"
    // "a+ b + c;")
    _scan("a", " ", "", "+ b + c;");
    _assertTokens(1, 2, ["a", "+", "b", "+", "c", ";"]);
    expect(_incrementalScanner.hasNonWhitespaceChange, isFalse);
  }

  void test_insert_afterIdentifier_firstToken() {
    // "a + b;"
    // "abs + b;"
    _scan("a", "", "bs", " + b;");
    _assertTokens(-1, 1, ["abs", "+", "b", ";"]);
    _assertReplaced(1, "+");
    expect(_incrementalScanner.hasNonWhitespaceChange, isTrue);
  }

  void test_insert_afterIdentifier_lastToken() {
    // "a + b"
    // "a + bc")
    _scan("a + b", "", "c", "");
    _assertTokens(1, 3, ["a", "+", "bc"]);
    expect(_incrementalScanner.hasNonWhitespaceChange, isTrue);
  }

  void test_insert_afterIdentifier_middleToken() {
    // "a + b;"
    // "a + by;"
    _scan("a + b", "", "y", ";");
    _assertTokens(1, 3, ["a", "+", "by", ";"]);
    expect(_incrementalScanner.hasNonWhitespaceChange, isTrue);
  }

  void test_insert_beforeIdentifier() {
    // "a + b;"
    // "a + xb;")
    _scan("a + ", "", "x", "b;");
    _assertTokens(1, 3, ["a", "+", "xb", ";"]);
    expect(_incrementalScanner.hasNonWhitespaceChange, isTrue);
  }

  void test_insert_beforeIdentifier_firstToken() {
    // "a + b;"
    // "xa + b;"
    _scan("", "", "x", "a + b;");
    _assertTokens(-1, 1, ["xa", "+", "b", ";"]);
    expect(_incrementalScanner.hasNonWhitespaceChange, isTrue);
  }

  void test_insert_convertOneFunctionToTwo() {
    // "f() {}"
    // "f() => 0; g() {}"
    _scan("f()", "", " => 0; g()", " {}");
    _assertTokens(
        2,
        9,
        ["f", "(", ")", "=>", "0", ";", "g", "(", ")", "{", "}"]);
    expect(_incrementalScanner.hasNonWhitespaceChange, isTrue);
  }

  void test_insert_convertOneFunctionToTwo_overlap() {
    // "f() {}"
    // "f() {} g() {}"
    _scan("f() {", "", "} g() {", "}");
    _assertTokens(4, 10, ["f", "(", ")", "{", "}", "g", "(", ")", "{", "}"]);
    expect(_incrementalScanner.hasNonWhitespaceChange, isTrue);
  }

  void test_insert_end() {
    // "class A {}"
    // "class A {} class B {}"
    _scan("class A {}", "", " class B {}", "");
    _assertTokens(3, 8, ["class", "A", "{", "}", "class", "B", "{", "}"]);
    expect(_incrementalScanner.hasNonWhitespaceChange, isTrue);
  }

  void test_insert_insideIdentifier() {
    // "cob;"
    // "cow.b;"
    _scan("co", "", "w.", "b;");
    _assertTokens(-1, 3, ["cow", ".", "b", ";"]);
    expect(_incrementalScanner.hasNonWhitespaceChange, isTrue);
  }

  void test_insert_newIdentifier_noSpaceBefore() {
    // "a; c;"
    // "a;b c;"
    _scan("a;", "", "b", " c;");
    _assertTokens(1, 3, ["a", ";", "b", "c", ";"]);
    _assertReplaced(1, ";");
    expect(_incrementalScanner.hasNonWhitespaceChange, isTrue);
  }

  void test_insert_newIdentifier_spaceBefore() {
    // "a; c;"
    // "a; b c;"
    _scan("a; ", "", "b ", "c;");
    _assertTokens(1, 3, ["a", ";", "b", "c", ";"]);
    expect(_incrementalScanner.hasNonWhitespaceChange, isTrue);
  }

  void test_insert_period() {
    // "a + b;"
    // "a + b.;"
    _scan("a + b", "", ".", ";");
    _assertTokens(2, 4, ["a", "+", "b", ".", ";"]);
  }

  void test_insert_period_betweenIdentifiers_left() {
    // "a b;"
    // "a. b;"
    _scan("a", "", ".", " b;");
    _assertTokens(0, 2, ["a", ".", "b", ";"]);
    expect(_incrementalScanner.hasNonWhitespaceChange, isTrue);
  }

  void test_insert_period_betweenIdentifiers_middle() {
    // "a  b;"
    // "a . b;"
    _scan("a ", "", ".", " b;");
    _assertTokens(0, 2, ["a", ".", "b", ";"]);
    expect(_incrementalScanner.hasNonWhitespaceChange, isTrue);
  }

  void test_insert_period_betweenIdentifiers_right() {
    // "a b;"
    // "a .b;"
    _scan("a ", "", ".", "b;");
    _assertTokens(0, 2, ["a", ".", "b", ";"]);
  }

  void test_insert_period_insideExistingIdentifier() {
    // "ab;"
    // "a.b;"
    _scan("a", "", ".", "b;");
    _assertTokens(-1, 3, ["a", ".", "b", ";"]);
    expect(_incrementalScanner.hasNonWhitespaceChange, isTrue);
  }

  void test_insert_periodAndIdentifier() {
    // "a + b;"
    // "a + b.x;"
    _scan("a + b", "", ".x", ";");
    _assertTokens(2, 5, ["a", "+", "b", ".", "x", ";"]);
  }

  void test_insert_whitespace_beginning_beforeToken() {
    // "a + b;"
    // " a + b;"
    _scan("", "", " ", "a + b;");
    _assertTokens(0, 1, ["a", "+", "b", ";"]);
    expect(_incrementalScanner.hasNonWhitespaceChange, isFalse);
  }

  void test_insert_whitespace_betweenTokens() {
    // "a + b;"
    // "a  + b;"
    _scan("a ", "", " ", "+ b;");
    _assertTokens(1, 2, ["a", "+", "b", ";"]);
    expect(_incrementalScanner.hasNonWhitespaceChange, isFalse);
  }

  void test_insert_whitespace_end_afterToken() {
    // "a + b;"
    // "a + b; "
    _scan("a + b;", "", " ", "");
    _assertTokens(3, 4, ["a", "+", "b", ";"]);
    expect(_incrementalScanner.hasNonWhitespaceChange, isFalse);
  }

  void test_insert_whitespace_end_afterWhitespace() {
    // "a + b; "
    // "a + b;  "
    _scan("a + b; ", "", " ", "");
    _assertTokens(3, 4, ["a", "+", "b", ";"]);
    expect(_incrementalScanner.hasNonWhitespaceChange, isFalse);
  }

  void test_insert_whitespace_withMultipleComments() {
    // "//comment", "//comment2", "a + b;"
    // "//comment", "//comment2", "a  + b;"
    _scan(r'''
//comment
//comment2
a''', "", " ", " + b;");
    _assertTokens(1, 2, ["a", "+", "b", ";"]);
    expect(_incrementalScanner.hasNonWhitespaceChange, isFalse);
  }

  void test_replace_identifier_beginning() {
    // "bell + b;"
    // "fell + b;")
    _scan("", "b", "f", "ell + b;");
    _assertTokens(-1, 1, ["fell", "+", "b", ";"]);
    expect(_incrementalScanner.hasNonWhitespaceChange, isTrue);
  }

  void test_replace_identifier_end() {
    // "bell + b;"
    // "belt + b;")
    _scan("bel", "l", "t", " + b;");
    _assertTokens(-1, 1, ["belt", "+", "b", ";"]);
    expect(_incrementalScanner.hasNonWhitespaceChange, isTrue);
  }

  void test_replace_identifier_middle() {
    // "first + b;"
    // "frost + b;")
    _scan("f", "ir", "ro", "st + b;");
    _assertTokens(-1, 1, ["frost", "+", "b", ";"]);
    expect(_incrementalScanner.hasNonWhitespaceChange, isTrue);
  }

  void test_replace_multiple_partialFirstAndLast() {
    // "aa + bb;"
    // "ab * ab;")
    _scan("a", "a + b", "b * a", "b;");
    _assertTokens(-1, 3, ["ab", "*", "ab", ";"]);
    expect(_incrementalScanner.hasNonWhitespaceChange, isTrue);
  }

  void test_replace_operator_oneForMany() {
    // "a + b;"
    // "a * c - b;")
    _scan("a ", "+", "* c -", " b;");
    _assertTokens(0, 4, ["a", "*", "c", "-", "b", ";"]);
    expect(_incrementalScanner.hasNonWhitespaceChange, isTrue);
  }

  void test_replace_operator_oneForOne() {
    // "a + b;"
    // "a * b;")
    _scan("a ", "+", "*", " b;");
    _assertTokens(0, 2, ["a", "*", "b", ";"]);
    expect(_incrementalScanner.hasNonWhitespaceChange, isTrue);
  }

  void test_tokenMap() {
    // "main() {a + b;}"
    // "main() { a + b;}"
    _scan("main() {", "", " ", "a + b;}");
    TokenMap tokenMap = _incrementalScanner.tokenMap;
    Token oldToken = _originalTokens;
    while (oldToken.type != TokenType.EOF) {
      Token newToken = tokenMap.get(oldToken);
      expect(newToken, isNot(same(oldToken)));
      expect(newToken.type, same(oldToken.type));
      expect(newToken.lexeme, oldToken.lexeme);
      oldToken = oldToken.next;
    }
    expect(_incrementalScanner.hasNonWhitespaceChange, isFalse);
  }

  /**
   * Assert that the token at the given [offset] was replaced with a new token
   * having the given [lexeme].
   */
  void _assertReplaced(int offset, String lexeme) {
    Token oldToken = _originalTokens;
    for (int i = 0; i < offset; i++) {
      oldToken = oldToken.next;
    }
    expect(oldToken.lexeme, lexeme);
    Token newToken = _incrementalScanner.tokenMap.get(oldToken);
    expect(newToken, isNotNull);
    expect(newToken.lexeme, lexeme);
    expect(newToken, isNot(same(oldToken)));
  }

  /**
   * Assert that the result of the incremental scan matches the given list of
   * [lexemes] and that the left and right tokens correspond to the tokens at
   * the [leftIndex] and [rightIndex].
   */
  void _assertTokens(int leftIndex, int rightIndex, List<String> lexemes) {
    int count = lexemes.length;
    expect(
        leftIndex >= -1 && leftIndex < count,
        isTrue,
        reason: "Invalid left index");
    expect(
        rightIndex >= 0 && rightIndex <= count,
        isTrue,
        reason: "Invalid right index");
    Token leftToken = null;
    Token rightToken = null;
    Token token = _incrementalTokens;
    if (leftIndex < 0) {
      leftToken = token.previous;
    }
    for (int i = 0; i < count; i++) {
      expect(token.lexeme, lexemes[i]);
      if (i == leftIndex) {
        leftToken = token;
      }
      if (i == rightIndex) {
        rightToken = token;
      }
      token = token.next;
    }
    if (rightIndex >= count) {
      rightToken = token;
    }
    expect(token.type, same(TokenType.EOF), reason: "Too many tokens");
    if (leftIndex >= 0) {
      expect(leftToken, isNotNull);
    }
    expect(
        _incrementalScanner.leftToken,
        same(leftToken),
        reason: "Invalid left token");
    if (rightIndex >= 0) {
      expect(rightToken, isNotNull);
    }
    expect(
        _incrementalScanner.rightToken,
        same(rightToken),
        reason: "Invalid right token");
  }

  /**
   * Given a description of the original and modified contents, perform an
   * incremental scan of the two pieces of text. Verify that the incremental
   * scan produced the same tokens as those that would be produced by a full
   * scan of the new contents.
   *
   * The original content is the concatenation of the [prefix], [removed] and
   * [suffix] fragments. The modeified content is the concatenation of the
   * [prefix], [added] and [suffix] fragments.
   */
  void _scan(String prefix, String removed, String added, String suffix) {
    //
    // Compute the information needed to perform the test.
    //
    String originalContents = "$prefix$removed$suffix";
    String modifiedContents = "$prefix$added$suffix";
    int replaceStart = prefix.length;
    Source source = new TestSource();
    //
    // Scan the original contents.
    //
    GatheringErrorListener originalListener = new GatheringErrorListener();
    Scanner originalScanner = new Scanner(
        source,
        new CharSequenceReader(originalContents),
        originalListener);
    _originalTokens = originalScanner.tokenize();
    expect(_originalTokens, isNotNull);
    //
    // Scan the modified contents.
    //
    GatheringErrorListener modifiedListener = new GatheringErrorListener();
    Scanner modifiedScanner = new Scanner(
        source,
        new CharSequenceReader(modifiedContents),
        modifiedListener);
    Token modifiedTokens = modifiedScanner.tokenize();
    expect(modifiedTokens, isNotNull);
    //
    // Incrementally scan the modified contents.
    //
    GatheringErrorListener incrementalListener = new GatheringErrorListener();
    _incrementalScanner = new IncrementalScanner(
        source,
        new CharSequenceReader(modifiedContents),
        incrementalListener);
    _incrementalTokens = _incrementalScanner.rescan(
        _originalTokens,
        replaceStart,
        removed.length,
        added.length);
    //
    // Validate that the results of the incremental scan are the same as the
    // full scan of the modified source.
    //
    Token incrementalToken = _incrementalTokens;
    expect(incrementalToken, isNotNull);
    while (incrementalToken.type != TokenType.EOF &&
        modifiedTokens.type != TokenType.EOF) {
      expect(
          incrementalToken.type,
          same(modifiedTokens.type),
          reason: "Wrong type for token");
      expect(
          incrementalToken.offset,
          modifiedTokens.offset,
          reason: "Wrong offset for token");
      expect(
          incrementalToken.length,
          modifiedTokens.length,
          reason: "Wrong length for token");
      expect(
          incrementalToken.lexeme,
          modifiedTokens.lexeme,
          reason: "Wrong lexeme for token");
      incrementalToken = incrementalToken.next;
      modifiedTokens = modifiedTokens.next;
    }
    expect(
        incrementalToken.type,
        same(TokenType.EOF),
        reason: "Too many tokens");
    expect(
        modifiedTokens.type,
        same(TokenType.EOF),
        reason: "Not enough tokens");
    // TODO(brianwilkerson) Verify that the errors are correct?
  }
}

class KeywordStateTest {
  void test_KeywordState() {
    //
    // Generate the test data to be scanned.
    //
    List<Keyword> keywords = Keyword.values;
    int keywordCount = keywords.length;
    List<String> textToTest = new List<String>(keywordCount * 3);
    for (int i = 0; i < keywordCount; i++) {
      String syntax = keywords[i].syntax;
      textToTest[i] = syntax;
      textToTest[i + keywordCount] = "${syntax}x";
      textToTest[i + keywordCount * 2] = syntax.substring(0, syntax.length - 1);
    }
    //
    // Scan each of the identifiers.
    //
    KeywordState firstState = KeywordState.KEYWORD_STATE;
    for (int i = 0; i < textToTest.length; i++) {
      String text = textToTest[i];
      int index = 0;
      int length = text.length;
      KeywordState state = firstState;
      while (index < length && state != null) {
        state = state.next(text.codeUnitAt(index));
        index++;
      }
      if (i < keywordCount) {
        // keyword
        expect(state, isNotNull);
        expect(state.keyword(), isNotNull);
        expect(state.keyword(), keywords[i]);
      } else if (i < keywordCount * 2) {
        // keyword + "x"
        expect(state, isNull);
      } else {
        // keyword.substring(0, keyword.length() - 1)
        expect(state, isNotNull);
      }
    }
  }
}

class ScannerTest {
  void fail_incomplete_string_interpolation() {
    // https://code.google.com/p/dart/issues/detail?id=18073
    _assertErrorAndTokens(
        ScannerErrorCode.UNTERMINATED_STRING_LITERAL,
        9,
        "\"foo \${bar",
        [
            new StringToken(TokenType.STRING, "\"foo ", 0),
            new StringToken(TokenType.STRING_INTERPOLATION_EXPRESSION, "\${", 5),
            new StringToken(TokenType.IDENTIFIER, "bar", 7)]);
  }

  void test_ampersand() {
    _assertToken(TokenType.AMPERSAND, "&");
  }

  void test_ampersand_ampersand() {
    _assertToken(TokenType.AMPERSAND_AMPERSAND, "&&");
  }

  void test_ampersand_eq() {
    _assertToken(TokenType.AMPERSAND_EQ, "&=");
  }

  void test_at() {
    _assertToken(TokenType.AT, "@");
  }

  void test_backping() {
    _assertToken(TokenType.BACKPING, "`");
  }

  void test_backslash() {
    _assertToken(TokenType.BACKSLASH, "\\");
  }

  void test_bang() {
    _assertToken(TokenType.BANG, "!");
  }

  void test_bang_eq() {
    _assertToken(TokenType.BANG_EQ, "!=");
  }

  void test_bar() {
    _assertToken(TokenType.BAR, "|");
  }

  void test_bar_bar() {
    _assertToken(TokenType.BAR_BAR, "||");
  }

  void test_bar_eq() {
    _assertToken(TokenType.BAR_EQ, "|=");
  }

  void test_caret() {
    _assertToken(TokenType.CARET, "^");
  }

  void test_caret_eq() {
    _assertToken(TokenType.CARET_EQ, "^=");
  }

  void test_close_curly_bracket() {
    _assertToken(TokenType.CLOSE_CURLY_BRACKET, "}");
  }

  void test_close_paren() {
    _assertToken(TokenType.CLOSE_PAREN, ")");
  }

  void test_close_quare_bracket() {
    _assertToken(TokenType.CLOSE_SQUARE_BRACKET, "]");
  }

  void test_colon() {
    _assertToken(TokenType.COLON, ":");
  }

  void test_comma() {
    _assertToken(TokenType.COMMA, ",");
  }

  void test_comment_disabled_multi() {
    Scanner scanner = new Scanner(
        null,
        new CharSequenceReader("/* comment */ "),
        AnalysisErrorListener.NULL_LISTENER);
    scanner.preserveComments = false;
    Token token = scanner.tokenize();
    expect(token, isNotNull);
    expect(token.precedingComments, isNull);
  }

  void test_comment_multi() {
    _assertComment(TokenType.MULTI_LINE_COMMENT, "/* comment */");
  }

  void test_comment_multi_unterminated() {
    _assertError(ScannerErrorCode.UNTERMINATED_MULTI_LINE_COMMENT, 3, "/* x");
  }

  void test_comment_nested() {
    _assertComment(
        TokenType.MULTI_LINE_COMMENT,
        "/* comment /* within a */ comment */");
  }

  void test_comment_single() {
    _assertComment(TokenType.SINGLE_LINE_COMMENT, "// comment");
  }

  void test_double_both_e() {
    _assertToken(TokenType.DOUBLE, "0.123e4");
  }

  void test_double_both_E() {
    _assertToken(TokenType.DOUBLE, "0.123E4");
  }

  void test_double_fraction() {
    _assertToken(TokenType.DOUBLE, ".123");
  }

  void test_double_fraction_e() {
    _assertToken(TokenType.DOUBLE, ".123e4");
  }

  void test_double_fraction_E() {
    _assertToken(TokenType.DOUBLE, ".123E4");
  }

  void test_double_missingDigitInExponent() {
    _assertError(ScannerErrorCode.MISSING_DIGIT, 1, "1e");
  }

  void test_double_whole_e() {
    _assertToken(TokenType.DOUBLE, "12e4");
  }

  void test_double_whole_E() {
    _assertToken(TokenType.DOUBLE, "12E4");
  }

  void test_eq() {
    _assertToken(TokenType.EQ, "=");
  }

  void test_eq_eq() {
    _assertToken(TokenType.EQ_EQ, "==");
  }

  void test_gt() {
    _assertToken(TokenType.GT, ">");
  }

  void test_gt_eq() {
    _assertToken(TokenType.GT_EQ, ">=");
  }

  void test_gt_gt() {
    _assertToken(TokenType.GT_GT, ">>");
  }

  void test_gt_gt_eq() {
    _assertToken(TokenType.GT_GT_EQ, ">>=");
  }

  void test_hash() {
    _assertToken(TokenType.HASH, "#");
  }

  void test_hexidecimal() {
    _assertToken(TokenType.HEXADECIMAL, "0x1A2B3C");
  }

  void test_hexidecimal_missingDigit() {
    _assertError(ScannerErrorCode.MISSING_HEX_DIGIT, 1, "0x");
  }

  void test_identifier() {
    _assertToken(TokenType.IDENTIFIER, "result");
  }

  void test_illegalChar_cyrillicLetter_middle() {
    _assertError(ScannerErrorCode.ILLEGAL_CHARACTER, 5, "Shche\u0433lov");
  }

  void test_illegalChar_cyrillicLetter_start() {
    _assertError(ScannerErrorCode.ILLEGAL_CHARACTER, 0, "\u0429");
  }

  void test_illegalChar_nbsp() {
    _assertError(ScannerErrorCode.ILLEGAL_CHARACTER, 0, "\u00A0");
  }

  void test_illegalChar_notLetter() {
    _assertError(ScannerErrorCode.ILLEGAL_CHARACTER, 0, "\u0312");
  }

  void test_index() {
    _assertToken(TokenType.INDEX, "[]");
  }

  void test_index_eq() {
    _assertToken(TokenType.INDEX_EQ, "[]=");
  }

  void test_int() {
    _assertToken(TokenType.INT, "123");
  }

  void test_int_initialZero() {
    _assertToken(TokenType.INT, "0123");
  }

  void test_keyword_abstract() {
    _assertKeywordToken("abstract");
  }

  void test_keyword_as() {
    _assertKeywordToken("as");
  }

  void test_keyword_assert() {
    _assertKeywordToken("assert");
  }

  void test_keyword_break() {
    _assertKeywordToken("break");
  }

  void test_keyword_case() {
    _assertKeywordToken("case");
  }

  void test_keyword_catch() {
    _assertKeywordToken("catch");
  }

  void test_keyword_class() {
    _assertKeywordToken("class");
  }

  void test_keyword_const() {
    _assertKeywordToken("const");
  }

  void test_keyword_continue() {
    _assertKeywordToken("continue");
  }

  void test_keyword_default() {
    _assertKeywordToken("default");
  }

  void test_keyword_deferred() {
    _assertKeywordToken("deferred");
  }

  void test_keyword_do() {
    _assertKeywordToken("do");
  }

  void test_keyword_dynamic() {
    _assertKeywordToken("dynamic");
  }

  void test_keyword_else() {
    _assertKeywordToken("else");
  }

  void test_keyword_enum() {
    _assertKeywordToken("enum");
  }

  void test_keyword_export() {
    _assertKeywordToken("export");
  }

  void test_keyword_extends() {
    _assertKeywordToken("extends");
  }

  void test_keyword_factory() {
    _assertKeywordToken("factory");
  }

  void test_keyword_false() {
    _assertKeywordToken("false");
  }

  void test_keyword_final() {
    _assertKeywordToken("final");
  }

  void test_keyword_finally() {
    _assertKeywordToken("finally");
  }

  void test_keyword_for() {
    _assertKeywordToken("for");
  }

  void test_keyword_get() {
    _assertKeywordToken("get");
  }

  void test_keyword_if() {
    _assertKeywordToken("if");
  }

  void test_keyword_implements() {
    _assertKeywordToken("implements");
  }

  void test_keyword_import() {
    _assertKeywordToken("import");
  }

  void test_keyword_in() {
    _assertKeywordToken("in");
  }

  void test_keyword_is() {
    _assertKeywordToken("is");
  }

  void test_keyword_library() {
    _assertKeywordToken("library");
  }

  void test_keyword_new() {
    _assertKeywordToken("new");
  }

  void test_keyword_null() {
    _assertKeywordToken("null");
  }

  void test_keyword_operator() {
    _assertKeywordToken("operator");
  }

  void test_keyword_part() {
    _assertKeywordToken("part");
  }

  void test_keyword_rethrow() {
    _assertKeywordToken("rethrow");
  }

  void test_keyword_return() {
    _assertKeywordToken("return");
  }

  void test_keyword_set() {
    _assertKeywordToken("set");
  }

  void test_keyword_static() {
    _assertKeywordToken("static");
  }

  void test_keyword_super() {
    _assertKeywordToken("super");
  }

  void test_keyword_switch() {
    _assertKeywordToken("switch");
  }

  void test_keyword_this() {
    _assertKeywordToken("this");
  }

  void test_keyword_throw() {
    _assertKeywordToken("throw");
  }

  void test_keyword_true() {
    _assertKeywordToken("true");
  }

  void test_keyword_try() {
    _assertKeywordToken("try");
  }

  void test_keyword_typedef() {
    _assertKeywordToken("typedef");
  }

  void test_keyword_var() {
    _assertKeywordToken("var");
  }

  void test_keyword_void() {
    _assertKeywordToken("void");
  }

  void test_keyword_while() {
    _assertKeywordToken("while");
  }

  void test_keyword_with() {
    _assertKeywordToken("with");
  }

  void test_lineInfo_multilineComment() {
    String source = "/*\r *\r */";
    _assertLineInfo(
        source,
        [
            new ScannerTest_ExpectedLocation(0, 1, 1),
            new ScannerTest_ExpectedLocation(4, 2, 2),
            new ScannerTest_ExpectedLocation(source.length - 1, 3, 3)]);
  }

  void test_lineInfo_multilineString() {
    String source = "'''a\r\nbc\r\nd'''";
    _assertLineInfo(
        source,
        [
            new ScannerTest_ExpectedLocation(0, 1, 1),
            new ScannerTest_ExpectedLocation(7, 2, 2),
            new ScannerTest_ExpectedLocation(source.length - 1, 3, 4)]);
  }

  void test_lineInfo_simpleClass() {
    String source =
        "class Test {\r\n    String s = '...';\r\n    int get x => s.MISSING_GETTER;\r\n}";
    _assertLineInfo(
        source,
        [
            new ScannerTest_ExpectedLocation(0, 1, 1),
            new ScannerTest_ExpectedLocation(source.indexOf("MISSING_GETTER"), 3, 20),
            new ScannerTest_ExpectedLocation(source.length - 1, 4, 1)]);
  }

  void test_lineInfo_slashN() {
    String source = "class Test {\n}";
    _assertLineInfo(
        source,
        [
            new ScannerTest_ExpectedLocation(0, 1, 1),
            new ScannerTest_ExpectedLocation(source.indexOf("}"), 2, 1)]);
  }

  void test_lt() {
    _assertToken(TokenType.LT, "<");
  }

  void test_lt_eq() {
    _assertToken(TokenType.LT_EQ, "<=");
  }

  void test_lt_lt() {
    _assertToken(TokenType.LT_LT, "<<");
  }

  void test_lt_lt_eq() {
    _assertToken(TokenType.LT_LT_EQ, "<<=");
  }

  void test_minus() {
    _assertToken(TokenType.MINUS, "-");
  }

  void test_minus_eq() {
    _assertToken(TokenType.MINUS_EQ, "-=");
  }

  void test_minus_minus() {
    _assertToken(TokenType.MINUS_MINUS, "--");
  }

  void test_open_curly_bracket() {
    _assertToken(TokenType.OPEN_CURLY_BRACKET, "{");
  }

  void test_open_paren() {
    _assertToken(TokenType.OPEN_PAREN, "(");
  }

  void test_open_square_bracket() {
    _assertToken(TokenType.OPEN_SQUARE_BRACKET, "[");
  }

  void test_openSquareBracket() {
    _assertToken(TokenType.OPEN_SQUARE_BRACKET, "[");
  }

  void test_percent() {
    _assertToken(TokenType.PERCENT, "%");
  }

  void test_percent_eq() {
    _assertToken(TokenType.PERCENT_EQ, "%=");
  }

  void test_period() {
    _assertToken(TokenType.PERIOD, ".");
  }

  void test_period_period() {
    _assertToken(TokenType.PERIOD_PERIOD, "..");
  }

  void test_period_period_period() {
    _assertToken(TokenType.PERIOD_PERIOD_PERIOD, "...");
  }

  void test_periodAfterNumberNotIncluded_identifier() {
    _assertTokens(
        "42.isEven()",
        [
            new StringToken(TokenType.INT, "42", 0),
            new Token(TokenType.PERIOD, 2),
            new StringToken(TokenType.IDENTIFIER, "isEven", 3),
            new Token(TokenType.OPEN_PAREN, 9),
            new Token(TokenType.CLOSE_PAREN, 10)]);
  }

  void test_periodAfterNumberNotIncluded_period() {
    _assertTokens(
        "42..isEven()",
        [
            new StringToken(TokenType.INT, "42", 0),
            new Token(TokenType.PERIOD_PERIOD, 2),
            new StringToken(TokenType.IDENTIFIER, "isEven", 4),
            new Token(TokenType.OPEN_PAREN, 10),
            new Token(TokenType.CLOSE_PAREN, 11)]);
  }

  void test_plus() {
    _assertToken(TokenType.PLUS, "+");
  }

  void test_plus_eq() {
    _assertToken(TokenType.PLUS_EQ, "+=");
  }

  void test_plus_plus() {
    _assertToken(TokenType.PLUS_PLUS, "++");
  }

  void test_question() {
    _assertToken(TokenType.QUESTION, "?");
  }

  void test_scriptTag_withArgs() {
    _assertToken(TokenType.SCRIPT_TAG, "#!/bin/dart -debug");
  }

  void test_scriptTag_withoutSpace() {
    _assertToken(TokenType.SCRIPT_TAG, "#!/bin/dart");
  }

  void test_scriptTag_withSpace() {
    _assertToken(TokenType.SCRIPT_TAG, "#! /bin/dart");
  }

  void test_semicolon() {
    _assertToken(TokenType.SEMICOLON, ";");
  }

  void test_setSourceStart() {
    int offsetDelta = 42;
    GatheringErrorListener listener = new GatheringErrorListener();
    Scanner scanner =
        new Scanner(null, new SubSequenceReader("a", offsetDelta), listener);
    scanner.setSourceStart(3, 9);
    scanner.tokenize();
    List<int> lineStarts = scanner.lineStarts;
    expect(lineStarts, isNotNull);
    expect(lineStarts.length, 3);
    expect(lineStarts[2], 33);
  }

  void test_slash() {
    _assertToken(TokenType.SLASH, "/");
  }

  void test_slash_eq() {
    _assertToken(TokenType.SLASH_EQ, "/=");
  }

  void test_star() {
    _assertToken(TokenType.STAR, "*");
  }

  void test_star_eq() {
    _assertToken(TokenType.STAR_EQ, "*=");
  }

  void test_startAndEnd() {
    Token token = _scan("a");
    Token previous = token.previous;
    expect(previous.next, token);
    expect(previous.previous, previous);
    Token next = token.next;
    expect(next.next, next);
    expect(next.previous, token);
  }

  void test_string_multi_double() {
    _assertToken(TokenType.STRING, "\"\"\"line1\nline2\"\"\"");
  }

  void test_string_multi_embeddedQuotes() {
    _assertToken(TokenType.STRING, "\"\"\"line1\n\"\"\nline2\"\"\"");
  }

  void test_string_multi_embeddedQuotes_escapedChar() {
    _assertToken(TokenType.STRING, "\"\"\"a\"\"\\tb\"\"\"");
  }

  void test_string_multi_interpolation_block() {
    _assertTokens(
        "\"Hello \${name}!\"",
        [
            new StringToken(TokenType.STRING, "\"Hello ", 0),
            new StringToken(TokenType.STRING_INTERPOLATION_EXPRESSION, "\${", 7),
            new StringToken(TokenType.IDENTIFIER, "name", 9),
            new Token(TokenType.CLOSE_CURLY_BRACKET, 13),
            new StringToken(TokenType.STRING, "!\"", 14)]);
  }

  void test_string_multi_interpolation_identifier() {
    _assertTokens(
        "\"Hello \$name!\"",
        [
            new StringToken(TokenType.STRING, "\"Hello ", 0),
            new StringToken(TokenType.STRING_INTERPOLATION_IDENTIFIER, "\$", 7),
            new StringToken(TokenType.IDENTIFIER, "name", 8),
            new StringToken(TokenType.STRING, "!\"", 12)]);
  }

  void test_string_multi_single() {
    _assertToken(TokenType.STRING, "'''string'''");
  }

  void test_string_multi_slashEnter() {
    _assertToken(TokenType.STRING, "'''\\\n'''");
  }

  void test_string_multi_unterminated() {
    _assertErrorAndTokens(
        ScannerErrorCode.UNTERMINATED_STRING_LITERAL,
        8,
        "'''string",
        [new StringToken(TokenType.STRING, "'''string", 0)]);
  }

  void test_string_multi_unterminated_interpolation_block() {
    _assertErrorAndTokens(
        ScannerErrorCode.UNTERMINATED_STRING_LITERAL,
        8,
        "'''\${name",
        [
            new StringToken(TokenType.STRING, "'''", 0),
            new StringToken(TokenType.STRING_INTERPOLATION_EXPRESSION, "\${", 3),
            new StringToken(TokenType.IDENTIFIER, "name", 5),
            new StringToken(TokenType.STRING, "", 9)]);
  }

  void test_string_multi_unterminated_interpolation_identifier() {
    _assertErrorAndTokens(
        ScannerErrorCode.UNTERMINATED_STRING_LITERAL,
        7,
        "'''\$name",
        [
            new StringToken(TokenType.STRING, "'''", 0),
            new StringToken(TokenType.STRING_INTERPOLATION_IDENTIFIER, "\$", 3),
            new StringToken(TokenType.IDENTIFIER, "name", 4),
            new StringToken(TokenType.STRING, "", 8)]);
  }

  void test_string_raw_multi_double() {
    _assertToken(TokenType.STRING, "r\"\"\"line1\nline2\"\"\"");
  }

  void test_string_raw_multi_single() {
    _assertToken(TokenType.STRING, "r'''string'''");
  }

  void test_string_raw_multi_unterminated() {
    String source = "r'''string";
    _assertErrorAndTokens(
        ScannerErrorCode.UNTERMINATED_STRING_LITERAL,
        9,
        source,
        [new StringToken(TokenType.STRING, source, 0)]);
  }

  void test_string_raw_simple_double() {
    _assertToken(TokenType.STRING, "r\"string\"");
  }

  void test_string_raw_simple_single() {
    _assertToken(TokenType.STRING, "r'string'");
  }

  void test_string_raw_simple_unterminated_eof() {
    String source = "r'string";
    _assertErrorAndTokens(
        ScannerErrorCode.UNTERMINATED_STRING_LITERAL,
        7,
        source,
        [new StringToken(TokenType.STRING, source, 0)]);
  }

  void test_string_raw_simple_unterminated_eol() {
    String source = "r'string";
    _assertErrorAndTokens(
        ScannerErrorCode.UNTERMINATED_STRING_LITERAL,
        8,
        "$source\n",
        [new StringToken(TokenType.STRING, source, 0)]);
  }

  void test_string_simple_double() {
    _assertToken(TokenType.STRING, "\"string\"");
  }

  void test_string_simple_escapedDollar() {
    _assertToken(TokenType.STRING, "'a\\\$b'");
  }

  void test_string_simple_interpolation_adjacentIdentifiers() {
    _assertTokens(
        "'\$a\$b'",
        [
            new StringToken(TokenType.STRING, "'", 0),
            new StringToken(TokenType.STRING_INTERPOLATION_IDENTIFIER, "\$", 1),
            new StringToken(TokenType.IDENTIFIER, "a", 2),
            new StringToken(TokenType.STRING, "", 3),
            new StringToken(TokenType.STRING_INTERPOLATION_IDENTIFIER, "\$", 3),
            new StringToken(TokenType.IDENTIFIER, "b", 4),
            new StringToken(TokenType.STRING, "'", 5)]);
  }

  void test_string_simple_interpolation_block() {
    _assertTokens(
        "'Hello \${name}!'",
        [
            new StringToken(TokenType.STRING, "'Hello ", 0),
            new StringToken(TokenType.STRING_INTERPOLATION_EXPRESSION, "\${", 7),
            new StringToken(TokenType.IDENTIFIER, "name", 9),
            new Token(TokenType.CLOSE_CURLY_BRACKET, 13),
            new StringToken(TokenType.STRING, "!'", 14)]);
  }

  void test_string_simple_interpolation_blockWithNestedMap() {
    _assertTokens(
        "'a \${f({'b' : 'c'})} d'",
        [
            new StringToken(TokenType.STRING, "'a ", 0),
            new StringToken(TokenType.STRING_INTERPOLATION_EXPRESSION, "\${", 3),
            new StringToken(TokenType.IDENTIFIER, "f", 5),
            new Token(TokenType.OPEN_PAREN, 6),
            new Token(TokenType.OPEN_CURLY_BRACKET, 7),
            new StringToken(TokenType.STRING, "'b'", 8),
            new Token(TokenType.COLON, 12),
            new StringToken(TokenType.STRING, "'c'", 14),
            new Token(TokenType.CLOSE_CURLY_BRACKET, 17),
            new Token(TokenType.CLOSE_PAREN, 18),
            new Token(TokenType.CLOSE_CURLY_BRACKET, 19),
            new StringToken(TokenType.STRING, " d'", 20)]);
  }

  void test_string_simple_interpolation_firstAndLast() {
    _assertTokens(
        "'\$greeting \$name'",
        [
            new StringToken(TokenType.STRING, "'", 0),
            new StringToken(TokenType.STRING_INTERPOLATION_IDENTIFIER, "\$", 1),
            new StringToken(TokenType.IDENTIFIER, "greeting", 2),
            new StringToken(TokenType.STRING, " ", 10),
            new StringToken(TokenType.STRING_INTERPOLATION_IDENTIFIER, "\$", 11),
            new StringToken(TokenType.IDENTIFIER, "name", 12),
            new StringToken(TokenType.STRING, "'", 16)]);
  }

  void test_string_simple_interpolation_identifier() {
    _assertTokens(
        "'Hello \$name!'",
        [
            new StringToken(TokenType.STRING, "'Hello ", 0),
            new StringToken(TokenType.STRING_INTERPOLATION_IDENTIFIER, "\$", 7),
            new StringToken(TokenType.IDENTIFIER, "name", 8),
            new StringToken(TokenType.STRING, "!'", 12)]);
  }

  void test_string_simple_interpolation_missingIdentifier() {
    _assertTokens(
        "'\$x\$'",
        [
            new StringToken(TokenType.STRING, "'", 0),
            new StringToken(TokenType.STRING_INTERPOLATION_IDENTIFIER, "\$", 1),
            new StringToken(TokenType.IDENTIFIER, "x", 2),
            new StringToken(TokenType.STRING, "", 3),
            new StringToken(TokenType.STRING_INTERPOLATION_IDENTIFIER, "\$", 3),
            new StringToken(TokenType.STRING, "'", 4)]);
  }

  void test_string_simple_interpolation_nonIdentifier() {
    _assertTokens(
        "'\$1'",
        [
            new StringToken(TokenType.STRING, "'", 0),
            new StringToken(TokenType.STRING_INTERPOLATION_IDENTIFIER, "\$", 1),
            new StringToken(TokenType.STRING, "1'", 2)]);
  }

  void test_string_simple_single() {
    _assertToken(TokenType.STRING, "'string'");
  }

  void test_string_simple_unterminated_eof() {
    String source = "'string";
    _assertErrorAndTokens(
        ScannerErrorCode.UNTERMINATED_STRING_LITERAL,
        6,
        source,
        [new StringToken(TokenType.STRING, source, 0)]);
  }

  void test_string_simple_unterminated_eol() {
    String source = "'string";
    _assertErrorAndTokens(
        ScannerErrorCode.UNTERMINATED_STRING_LITERAL,
        7,
        "$source\r",
        [new StringToken(TokenType.STRING, source, 0)]);
  }

  void test_string_simple_unterminated_interpolation_block() {
    _assertErrorAndTokens(
        ScannerErrorCode.UNTERMINATED_STRING_LITERAL,
        6,
        "'\${name",
        [
            new StringToken(TokenType.STRING, "'", 0),
            new StringToken(TokenType.STRING_INTERPOLATION_EXPRESSION, "\${", 1),
            new StringToken(TokenType.IDENTIFIER, "name", 3),
            new StringToken(TokenType.STRING, "", 7)]);
  }

  void test_string_simple_unterminated_interpolation_identifier() {
    _assertErrorAndTokens(
        ScannerErrorCode.UNTERMINATED_STRING_LITERAL,
        5,
        "'\$name",
        [
            new StringToken(TokenType.STRING, "'", 0),
            new StringToken(TokenType.STRING_INTERPOLATION_IDENTIFIER, "\$", 1),
            new StringToken(TokenType.IDENTIFIER, "name", 2),
            new StringToken(TokenType.STRING, "", 6)]);
  }

  void test_tilde() {
    _assertToken(TokenType.TILDE, "~");
  }

  void test_tilde_slash() {
    _assertToken(TokenType.TILDE_SLASH, "~/");
  }

  void test_tilde_slash_eq() {
    _assertToken(TokenType.TILDE_SLASH_EQ, "~/=");
  }

  void test_unclosedPairInInterpolation() {
    GatheringErrorListener listener = new GatheringErrorListener();
    _scanWithListener("'\${(}'", listener);
  }

  void _assertComment(TokenType commentType, String source) {
    //
    // Test without a trailing end-of-line marker
    //
    Token token = _scan(source);
    expect(token, isNotNull);
    expect(token.type, TokenType.EOF);
    Token comment = token.precedingComments;
    expect(comment, isNotNull);
    expect(comment.type, commentType);
    expect(comment.offset, 0);
    expect(comment.length, source.length);
    expect(comment.lexeme, source);
    //
    // Test with a trailing end-of-line marker
    //
    token = _scan("$source\n");
    expect(token, isNotNull);
    expect(token.type, TokenType.EOF);
    comment = token.precedingComments;
    expect(comment, isNotNull);
    expect(comment.type, commentType);
    expect(comment.offset, 0);
    expect(comment.length, source.length);
    expect(comment.lexeme, source);
  }

  /**
   * Assert that scanning the given source produces an error with the given code.
   *
   * @param expectedError the error that should be produced
   * @param expectedOffset the string offset that should be associated with the error
   * @param source the source to be scanned to produce the error
   */
  void _assertError(ScannerErrorCode expectedError, int expectedOffset,
      String source) {
    GatheringErrorListener listener = new GatheringErrorListener();
    _scanWithListener(source, listener);
    listener.assertErrors(
        [
            new AnalysisError.con2(
                null,
                expectedOffset,
                1,
                expectedError,
                [source.codeUnitAt(expectedOffset)])]);
  }

  /**
   * Assert that scanning the given source produces an error with the given code, and also produces
   * the given tokens.
   *
   * @param expectedError the error that should be produced
   * @param expectedOffset the string offset that should be associated with the error
   * @param source the source to be scanned to produce the error
   * @param expectedTokens the tokens that are expected to be in the source
   */
  void _assertErrorAndTokens(ScannerErrorCode expectedError, int expectedOffset,
      String source, List<Token> expectedTokens) {
    GatheringErrorListener listener = new GatheringErrorListener();
    Token token = _scanWithListener(source, listener);
    listener.assertErrors(
        [
            new AnalysisError.con2(
                null,
                expectedOffset,
                1,
                expectedError,
                [source.codeUnitAt(expectedOffset)])]);
    _checkTokens(token, expectedTokens);
  }

  /**
   * Assert that when scanned the given source contains a single keyword token with the same lexeme
   * as the original source.
   *
   * @param source the source to be scanned
   */
  void _assertKeywordToken(String source) {
    Token token = _scan(source);
    expect(token, isNotNull);
    expect(token.type, TokenType.KEYWORD);
    expect(token.offset, 0);
    expect(token.length, source.length);
    expect(token.lexeme, source);
    Object value = token.value();
    expect(value is Keyword, isTrue);
    expect((value as Keyword).syntax, source);
    token = _scan(" $source ");
    expect(token, isNotNull);
    expect(token.type, TokenType.KEYWORD);
    expect(token.offset, 1);
    expect(token.length, source.length);
    expect(token.lexeme, source);
    value = token.value();
    expect(value is Keyword, isTrue);
    expect((value as Keyword).syntax, source);
    expect(token.next.type, TokenType.EOF);
  }

  void _assertLineInfo(String source,
      List<ScannerTest_ExpectedLocation> expectedLocations) {
    GatheringErrorListener listener = new GatheringErrorListener();
    _scanWithListener(source, listener);
    listener.assertNoErrors();
    LineInfo info = listener.getLineInfo(new TestSource());
    expect(info, isNotNull);
    for (ScannerTest_ExpectedLocation expectedLocation in expectedLocations) {
      LineInfo_Location location = info.getLocation(expectedLocation._offset);
      expect(location.lineNumber, expectedLocation._lineNumber);
      expect(location.columnNumber, expectedLocation._columnNumber);
    }
  }

  /**
   * Assert that the token scanned from the given source has the expected type.
   *
   * @param expectedType the expected type of the token
   * @param source the source to be scanned to produce the actual token
   */
  Token _assertToken(TokenType expectedType, String source) {
    Token originalToken = _scan(source);
    expect(originalToken, isNotNull);
    expect(originalToken.type, expectedType);
    expect(originalToken.offset, 0);
    expect(originalToken.length, source.length);
    expect(originalToken.lexeme, source);
    if (expectedType == TokenType.SCRIPT_TAG) {
      // Adding space before the script tag is not allowed, and adding text at
      // the end changes nothing.
      return originalToken;
    } else if (expectedType == TokenType.SINGLE_LINE_COMMENT) {
      // Adding space to an end-of-line comment changes the comment.
      Token tokenWithSpaces = _scan(" $source");
      expect(tokenWithSpaces, isNotNull);
      expect(tokenWithSpaces.type, expectedType);
      expect(tokenWithSpaces.offset, 1);
      expect(tokenWithSpaces.length, source.length);
      expect(tokenWithSpaces.lexeme, source);
      return originalToken;
    } else if (expectedType == TokenType.INT ||
        expectedType == TokenType.DOUBLE) {
      Token tokenWithLowerD = _scan("${source}d");
      expect(tokenWithLowerD, isNotNull);
      expect(tokenWithLowerD.type, expectedType);
      expect(tokenWithLowerD.offset, 0);
      expect(tokenWithLowerD.length, source.length);
      expect(tokenWithLowerD.lexeme, source);
      Token tokenWithUpperD = _scan("${source}D");
      expect(tokenWithUpperD, isNotNull);
      expect(tokenWithUpperD.type, expectedType);
      expect(tokenWithUpperD.offset, 0);
      expect(tokenWithUpperD.length, source.length);
      expect(tokenWithUpperD.lexeme, source);
    }
    Token tokenWithSpaces = _scan(" $source ");
    expect(tokenWithSpaces, isNotNull);
    expect(tokenWithSpaces.type, expectedType);
    expect(tokenWithSpaces.offset, 1);
    expect(tokenWithSpaces.length, source.length);
    expect(tokenWithSpaces.lexeme, source);
    expect(originalToken.next.type, TokenType.EOF);
    return originalToken;
  }

  /**
   * Assert that when scanned the given source contains a sequence of tokens identical to the given
   * tokens.
   *
   * @param source the source to be scanned
   * @param expectedTokens the tokens that are expected to be in the source
   */
  void _assertTokens(String source, List<Token> expectedTokens) {
    Token token = _scan(source);
    _checkTokens(token, expectedTokens);
  }

  void _checkTokens(Token firstToken, List<Token> expectedTokens) {
    expect(firstToken, isNotNull);
    Token token = firstToken;
    for (int i = 0; i < expectedTokens.length; i++) {
      Token expectedToken = expectedTokens[i];
      expect(token.type, expectedToken.type, reason: "Wrong type for token $i");
      expect(
          token.offset,
          expectedToken.offset,
          reason: "Wrong offset for token $i");
      expect(
          token.length,
          expectedToken.length,
          reason: "Wrong length for token $i");
      expect(
          token.lexeme,
          expectedToken.lexeme,
          reason: "Wrong lexeme for token $i");
      token = token.next;
      expect(token, isNotNull);
    }
    expect(token.type, TokenType.EOF);
  }

  Token _scan(String source) {
    GatheringErrorListener listener = new GatheringErrorListener();
    Token token = _scanWithListener(source, listener);
    listener.assertNoErrors();
    return token;
  }

  Token _scanWithListener(String source, GatheringErrorListener listener) {
    Scanner scanner =
        new Scanner(null, new CharSequenceReader(source), listener);
    Token result = scanner.tokenize();
    listener.setLineInfo(new TestSource(), scanner.lineStarts);
    return result;
  }
}

/**
 * Instances of the class `ExpectedLocation` encode information about the expected location
 * of a given offset in source code.
 */
class ScannerTest_ExpectedLocation {
  final int _offset;

  final int _lineNumber;

  final int _columnNumber;

  ScannerTest_ExpectedLocation(this._offset, this._lineNumber,
      this._columnNumber);
}

/**
 * Instances of the class `TokenStreamValidator` are used to validate the correct construction
 * of a stream of tokens.
 */
class TokenStreamValidator {
  /**
   * Validate that the stream of tokens that starts with the given token is correct.
   *
   * @param token the first token in the stream of tokens to be validated
   */
  void validate(Token token) {
    StringBuffer buffer = new StringBuffer();
    _validateStream(buffer, token);
    if (buffer.length > 0) {
      fail(buffer.toString());
    }
  }

  void _validateStream(StringBuffer buffer, Token token) {
    if (token == null) {
      return;
    }
    Token previousToken = null;
    int previousEnd = -1;
    Token currentToken = token;
    while (currentToken != null && currentToken.type != TokenType.EOF) {
      _validateStream(buffer, currentToken.precedingComments);
      TokenType type = currentToken.type;
      if (type == TokenType.OPEN_CURLY_BRACKET ||
          type == TokenType.OPEN_PAREN ||
          type == TokenType.OPEN_SQUARE_BRACKET ||
          type == TokenType.STRING_INTERPOLATION_EXPRESSION) {
        if (currentToken is! BeginToken) {
          buffer.write("\r\nExpected BeginToken, found ");
          buffer.write(currentToken.runtimeType.toString());
          buffer.write(" ");
          _writeToken(buffer, currentToken);
        }
      }
      int currentStart = currentToken.offset;
      int currentLength = currentToken.length;
      int currentEnd = currentStart + currentLength - 1;
      if (currentStart <= previousEnd) {
        buffer.write("\r\nInvalid token sequence: ");
        _writeToken(buffer, previousToken);
        buffer.write(" followed by ");
        _writeToken(buffer, currentToken);
      }
      previousEnd = currentEnd;
      previousToken = currentToken;
      currentToken = currentToken.next;
    }
  }

  void _writeToken(StringBuffer buffer, Token token) {
    buffer.write("[");
    buffer.write(token.type);
    buffer.write(", '");
    buffer.write(token.lexeme);
    buffer.write("', ");
    buffer.write(token.offset);
    buffer.write(", ");
    buffer.write(token.length);
    buffer.write("]");
  }
}

class TokenTypeTest extends EngineTestCase {
  void test_isOperator() {
    expect(TokenType.AMPERSAND.isOperator, isTrue);
    expect(TokenType.AMPERSAND_AMPERSAND.isOperator, isTrue);
    expect(TokenType.AMPERSAND_EQ.isOperator, isTrue);
    expect(TokenType.BANG.isOperator, isTrue);
    expect(TokenType.BANG_EQ.isOperator, isTrue);
    expect(TokenType.BAR.isOperator, isTrue);
    expect(TokenType.BAR_BAR.isOperator, isTrue);
    expect(TokenType.BAR_EQ.isOperator, isTrue);
    expect(TokenType.CARET.isOperator, isTrue);
    expect(TokenType.CARET_EQ.isOperator, isTrue);
    expect(TokenType.EQ.isOperator, isTrue);
    expect(TokenType.EQ_EQ.isOperator, isTrue);
    expect(TokenType.GT.isOperator, isTrue);
    expect(TokenType.GT_EQ.isOperator, isTrue);
    expect(TokenType.GT_GT.isOperator, isTrue);
    expect(TokenType.GT_GT_EQ.isOperator, isTrue);
    expect(TokenType.INDEX.isOperator, isTrue);
    expect(TokenType.INDEX_EQ.isOperator, isTrue);
    expect(TokenType.IS.isOperator, isTrue);
    expect(TokenType.LT.isOperator, isTrue);
    expect(TokenType.LT_EQ.isOperator, isTrue);
    expect(TokenType.LT_LT.isOperator, isTrue);
    expect(TokenType.LT_LT_EQ.isOperator, isTrue);
    expect(TokenType.MINUS.isOperator, isTrue);
    expect(TokenType.MINUS_EQ.isOperator, isTrue);
    expect(TokenType.MINUS_MINUS.isOperator, isTrue);
    expect(TokenType.PERCENT.isOperator, isTrue);
    expect(TokenType.PERCENT_EQ.isOperator, isTrue);
    expect(TokenType.PERIOD_PERIOD.isOperator, isTrue);
    expect(TokenType.PLUS.isOperator, isTrue);
    expect(TokenType.PLUS_EQ.isOperator, isTrue);
    expect(TokenType.PLUS_PLUS.isOperator, isTrue);
    expect(TokenType.QUESTION.isOperator, isTrue);
    expect(TokenType.SLASH.isOperator, isTrue);
    expect(TokenType.SLASH_EQ.isOperator, isTrue);
    expect(TokenType.STAR.isOperator, isTrue);
    expect(TokenType.STAR_EQ.isOperator, isTrue);
    expect(TokenType.TILDE.isOperator, isTrue);
    expect(TokenType.TILDE_SLASH.isOperator, isTrue);
    expect(TokenType.TILDE_SLASH_EQ.isOperator, isTrue);
  }

  void test_isUserDefinableOperator() {
    expect(TokenType.AMPERSAND.isUserDefinableOperator, isTrue);
    expect(TokenType.BAR.isUserDefinableOperator, isTrue);
    expect(TokenType.CARET.isUserDefinableOperator, isTrue);
    expect(TokenType.EQ_EQ.isUserDefinableOperator, isTrue);
    expect(TokenType.GT.isUserDefinableOperator, isTrue);
    expect(TokenType.GT_EQ.isUserDefinableOperator, isTrue);
    expect(TokenType.GT_GT.isUserDefinableOperator, isTrue);
    expect(TokenType.INDEX.isUserDefinableOperator, isTrue);
    expect(TokenType.INDEX_EQ.isUserDefinableOperator, isTrue);
    expect(TokenType.LT.isUserDefinableOperator, isTrue);
    expect(TokenType.LT_EQ.isUserDefinableOperator, isTrue);
    expect(TokenType.LT_LT.isUserDefinableOperator, isTrue);
    expect(TokenType.MINUS.isUserDefinableOperator, isTrue);
    expect(TokenType.PERCENT.isUserDefinableOperator, isTrue);
    expect(TokenType.PLUS.isUserDefinableOperator, isTrue);
    expect(TokenType.SLASH.isUserDefinableOperator, isTrue);
    expect(TokenType.STAR.isUserDefinableOperator, isTrue);
    expect(TokenType.TILDE.isUserDefinableOperator, isTrue);
    expect(TokenType.TILDE_SLASH.isUserDefinableOperator, isTrue);
  }
}
