// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library engine.incremental_scanner_test;

import 'package:analyzer/src/generated/incremental_scanner.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:unittest/unittest.dart';

import '../reflective_tests.dart';
import 'test_support.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(IncrementalScannerTest);
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

  void fail_insert_comment_afterIdentifier() {
    // "a + b"
    // "a /* TODO */ + b"
    _scan("a", "", " /* TODO */", " + b");
    _assertTokens(0, 1, ["a", "+", "b"]);
    _assertComments(1, ["/* TODO */"]);
    expect(_incrementalScanner.hasNonWhitespaceChange, isFalse);
  }

  void fail_insert_comment_beforeIdentifier() {
    // "a + b"
    // "a + /* TODO */ b"
    _scan("a + ", "", "/* TODO */ ", "b");
    _assertTokens(1, 2, ["a", "+", "b"]);
    _assertComments(2, ["/* TODO */"]);
    expect(_incrementalScanner.hasNonWhitespaceChange, isFalse);
  }

  void fail_insert_inComment() {
    // "a /* TO */ b"
    // "a /* TODO */ b"
    _scan("a /* TO", "", "DO", " */ b");
    _assertTokens(0, 1, ["a", "b"]);
    _assertComments(1, ["/* TODO */"]);
    expect(_incrementalScanner.hasNonWhitespaceChange, isFalse);
  }

  void test_delete_identifier_beginning() {
    // "abs + b;"
    // "s + b;"
    _scan("", "ab", "", "s + b;");
    _assertTokens(-1, 1, ["s", "+", "b", ";"]);
    expect(_incrementalScanner.hasNonWhitespaceChange, isTrue);
  }

  void test_delete_identifier_end() {
    // "abs + b;"
    // "a + b;"
    _scan("a", "bs", "", " + b;");
    _assertTokens(-1, 1, ["a", "+", "b", ";"]);
    expect(_incrementalScanner.hasNonWhitespaceChange, isTrue);
  }

  void test_delete_identifier_middle() {
    // "abs + b;"
    // "as + b;"
    _scan("a", "b", "", "s + b;");
    _assertTokens(-1, 1, ["as", "+", "b", ";"]);
    expect(_incrementalScanner.hasNonWhitespaceChange, isTrue);
  }

  void test_delete_mergeTokens() {
    // "a + b + c;"
    // "ac;"
    _scan("a", " + b + ", "", "c;");
    _assertTokens(-1, 1, ["ac", ";"]);
    expect(_incrementalScanner.hasNonWhitespaceChange, isTrue);
  }

  void test_delete_whitespace() {
    // "a + b + c;"
    // "a+ b + c;"
    _scan("a", " ", "", "+ b + c;");
    _assertTokens(1, 2, ["a", "+", "b", "+", "c", ";"]);
    expect(_incrementalScanner.hasNonWhitespaceChange, isFalse);
  }

  void test_insert_convertOneFunctionToTwo_noOverlap() {
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

  void test_insert_identifierAndPeriod() {
    // "a + b;"
    // "a + x.b;"
    _scan("a + ", "", "x.", "b;");
    _assertTokens(1, 4, ["a", "+", "x", ".", "b", ";"]);
  }

  void test_insert_inIdentifier_left_firstToken() {
    // "a + b;"
    // "xa + b;"
    _scan("", "", "x", "a + b;");
    _assertTokens(-1, 1, ["xa", "+", "b", ";"]);
    expect(_incrementalScanner.hasNonWhitespaceChange, isTrue);
  }

  void test_insert_inIdentifier_left_lastToken() {
    // "a + b"
    // "a + xb"
    _scan("a + ", "", "x", "b");
    _assertTokens(1, 3, ["a", "+", "xb"]);
    expect(_incrementalScanner.hasNonWhitespaceChange, isTrue);
  }

  void test_insert_inIdentifier_left_middleToken() {
    // "a + b;"
    // "a + xb;"
    _scan("a + ", "", "x", "b;");
    _assertTokens(1, 3, ["a", "+", "xb", ";"]);
    expect(_incrementalScanner.hasNonWhitespaceChange, isTrue);
  }

  void test_insert_inIdentifier_middle() {
    // "cat;"
    // "cart;"
    _scan("ca", "", "r", "t;");
    _assertTokens(-1, 1, ["cart", ";"]);
    expect(_incrementalScanner.hasNonWhitespaceChange, isTrue);
  }

  void test_insert_inIdentifier_right_firstToken() {
    // "a + b;"
    // "abs + b;"
    _scan("a", "", "bs", " + b;");
    _assertTokens(-1, 1, ["abs", "+", "b", ";"]);
    expect(_incrementalScanner.hasNonWhitespaceChange, isTrue);
  }

  void test_insert_inIdentifier_right_lastToken() {
    // "a + b"
    // "a + bc"
    _scan("a + b", "", "c", "");
    _assertTokens(1, 3, ["a", "+", "bc"]);
    expect(_incrementalScanner.hasNonWhitespaceChange, isTrue);
  }

  void test_insert_inIdentifier_right_middleToken() {
    // "a + b;"
    // "a + by;"
    _scan("a + b", "", "y", ";");
    _assertTokens(1, 3, ["a", "+", "by", ";"]);
    expect(_incrementalScanner.hasNonWhitespaceChange, isTrue);
  }

  void test_insert_newIdentifier_noSpaceBefore() {
    // "a; c;"
    // "a;b c;"
    _scan("a;", "", "b", " c;");
    _assertTokens(1, 3, ["a", ";", "b", "c", ";"]);
    expect(_incrementalScanner.hasNonWhitespaceChange, isTrue);
  }

  void test_insert_newIdentifier_spaceBefore() {
    // "a; c;"
    // "a; b c;"
    _scan("a; ", "", "b ", "c;");
    _assertTokens(1, 3, ["a", ";", "b", "c", ";"]);
    expect(_incrementalScanner.hasNonWhitespaceChange, isTrue);
  }

  void test_insert_periodAndIdentifier() {
    // "a + b;"
    // "a + b.x;"
    _scan("a + b", "", ".x", ";");
    _assertTokens(2, 5, ["a", "+", "b", ".", "x", ";"]);
  }

  void test_insert_period_afterIdentifier() {
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

  void test_insert_splitIdentifier() {
    // "cob;"
    // "cow.b;"
    _scan("co", "", "w.", "b;");
    _assertTokens(-1, 3, ["cow", ".", "b", ";"]);
    expect(_incrementalScanner.hasNonWhitespaceChange, isTrue);
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
    // "//comment1", "//comment2", "a + b;"
    // "//comment1", "//comment2", "a  + b;"
    _scan(r'''
//comment1
//comment2
a''', "", " ", " + b;");
    _assertTokens(1, 2, ["a", "+", "b", ";"]);
    expect(_incrementalScanner.hasNonWhitespaceChange, isFalse);
  }

  void test_replace_identifier_beginning() {
    // "bell + b;"
    // "fell + b;"
    _scan("", "b", "f", "ell + b;");
    _assertTokens(-1, 1, ["fell", "+", "b", ";"]);
    expect(_incrementalScanner.hasNonWhitespaceChange, isTrue);
  }

  void test_replace_identifier_end() {
    // "bell + b;"
    // "belt + b;"
    _scan("bel", "l", "t", " + b;");
    _assertTokens(-1, 1, ["belt", "+", "b", ";"]);
    expect(_incrementalScanner.hasNonWhitespaceChange, isTrue);
  }

  void test_replace_identifier_middle() {
    // "first + b;"
    // "frost + b;"
    _scan("f", "ir", "ro", "st + b;");
    _assertTokens(-1, 1, ["frost", "+", "b", ";"]);
    expect(_incrementalScanner.hasNonWhitespaceChange, isTrue);
  }

  void test_replace_multiple_partialFirstAndLast() {
    // "aa + bb;"
    // "ab * ab;"
    _scan("a", "a + b", "b * a", "b;");
    _assertTokens(-1, 3, ["ab", "*", "ab", ";"]);
    expect(_incrementalScanner.hasNonWhitespaceChange, isTrue);
  }

  void test_replace_operator_oneForMany() {
    // "a + b;"
    // "a * c - b;"
    _scan("a ", "+", "* c -", " b;");
    _assertTokens(0, 4, ["a", "*", "c", "-", "b", ";"]);
    expect(_incrementalScanner.hasNonWhitespaceChange, isTrue);
  }

  void test_replace_operator_oneForOne() {
    // "a + b;"
    // "a * b;"
    _scan("a ", "+", "*", " b;");
    _assertTokens(0, 2, ["a", "*", "b", ";"]);
    expect(_incrementalScanner.hasNonWhitespaceChange, isTrue);
  }

  /**
   * Assert that the comments associated with the token at the given [index]
   * have lexemes that match the given list of lexemes, both in number and in
   * content.
   */
  void _assertComments(int index, List<String> lexemes) {
    Token token = _incrementalTokens;
    for (int i = 0; i < index; i++) {
      token = token.next;
    }
    Token comment = token.precedingComments;
    if (lexemes.isEmpty) {
      expect(
          comment,
          isNull,
          reason: "No comments expected but comments found");
    }
    int count = 0;
    for (String lexeme in lexemes) {
      if (comment == null) {
        fail("Expected ${lexemes.length} comments but found $count");
      }
      expect(comment.lexeme, lexeme);
      count++;
      comment = comment.next;
    }
    if (comment != null) {
      while (comment != null) {
        count++;
        comment = comment.next;
      }
      fail("Expected ${lexemes.length} comments but found $count");
    }
  }

  /**
   * Assert that the [expected] token is equal to the [actual] token.
   */
  void _assertEqualTokens(Token actual, Token expected) {
    expect(actual.type, same(expected.type), reason: "Wrong type for token");
    expect(actual.lexeme, expected.lexeme, reason: "Wrong lexeme for token");
    expect(
        actual.offset,
        expected.offset,
        reason: "Wrong offset for token ('${actual.lexeme}' != '${expected.lexeme}')");
    expect(
        actual.length,
        expected.length,
        reason: "Wrong length for token ('${actual.lexeme}' != '${expected.lexeme}')");
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
      _assertEqualTokens(incrementalToken, modifiedTokens);
      Token incrementalComment = incrementalToken.precedingComments;
      Token modifiedComment = modifiedTokens.precedingComments;
      while (incrementalComment != null && modifiedComment != null) {
        _assertEqualTokens(incrementalComment, modifiedComment);
        incrementalComment = incrementalComment.next;
        modifiedComment = modifiedComment.next;
      }
      expect(
          incrementalComment,
          isNull,
          reason: "Too many comment tokens preceeding '${incrementalToken.lexeme}'");
      expect(
          modifiedComment,
          isNull,
          reason: "Not enough comment tokens preceeding '${incrementalToken.lexeme}'");
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
