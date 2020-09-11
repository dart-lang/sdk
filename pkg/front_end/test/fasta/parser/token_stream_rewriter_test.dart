// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/parser/token_stream_rewriter.dart';
import 'package:_fe_analyzer_shared/src/scanner/scanner.dart'
    show ScannerResult, scanString;
import 'package:_fe_analyzer_shared/src/scanner/token.dart'
    show ReplacementToken, Token, TokenType;
import 'package:_fe_analyzer_shared/src/scanner/token_impl.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TokenStreamRewriterTest_NoPrevious);
    defineReflectiveTests(TokenStreamRewriterTest_UsingPrevious);
    defineReflectiveTests(TokenStreamRewriterTest_Undoable);
  });
}

/// Abstract base class for tests of [TokenStreamRewriter].
abstract class TokenStreamRewriterTest {
  /// Indicates whether the tests should set up [Token.previous].
  bool get setPrevious;

  TokenStreamRewriter getTokenStreamRewriter();

  void setupDone(Token first) {}
  void normalTestDone(TokenStreamRewriter rewriter, Token first) {}

  void test_insertParens() {
    Token a = _makeToken(0, 'a');
    Token b = _makeToken(1, 'b');
    Token eof = _link([a, b]);
    setupDone(a);

    TokenStreamRewriter rewriter = getTokenStreamRewriter();
    Token openParen = rewriter.insertParens(a, false);
    Token closeParen = openParen.next;

    expect(openParen.lexeme, '(');
    expect(closeParen.lexeme, ')');

    expect(a.next, same(openParen));
    expect(openParen.next, same(closeParen));
    expect(closeParen.next, same(b));
    expect(b.next, same(eof));

    expect(b.previous, same(closeParen));
    expect(closeParen.previous, same(openParen));
    expect(openParen.previous, same(a));

    normalTestDone(rewriter, a);
  }

  void test_insertParensWithIdentifier() {
    Token a = _makeToken(0, 'a');
    Token b = _makeToken(1, 'b');
    Token eof = _link([a, b]);
    setupDone(a);

    TokenStreamRewriter rewriter = getTokenStreamRewriter();
    Token openParen = rewriter.insertParens(a, true);
    Token identifier = openParen.next;
    Token closeParen = identifier.next;

    expect(openParen.lexeme, '(');
    expect(identifier.lexeme, '');
    expect(identifier.isSynthetic, isTrue);
    expect(closeParen.lexeme, ')');

    expect(a.next, same(openParen));
    expect(openParen.next, same(identifier));
    expect(identifier.next, same(closeParen));
    expect(closeParen.next, same(b));
    expect(b.next, same(eof));

    expect(b.previous, same(closeParen));
    expect(closeParen.previous, same(identifier));
    expect(identifier.previous, same(openParen));
    expect(openParen.previous, same(a));

    normalTestDone(rewriter, a);
  }

  void test_insertSyntheticIdentifier() {
    Token a = _makeToken(0, 'a');
    Token b = _makeToken(1, 'b');
    Token eof = _link([a, b]);
    setupDone(a);

    TokenStreamRewriter rewriter = getTokenStreamRewriter();
    Token identifier = rewriter.insertSyntheticIdentifier(a);

    expect(identifier.lexeme, '');
    expect(identifier.isSynthetic, isTrue);

    expect(a.next, same(identifier));
    expect(identifier.next, same(b));
    expect(b.next, same(eof));

    expect(b.previous, same(identifier));
    expect(identifier.previous, same(a));

    normalTestDone(rewriter, a);
  }

  void test_insertToken_end() {
    Token a = _makeToken(0, 'a');
    Token b = _makeToken(1, 'b');
    Token eof = _link([a]);
    setupDone(a);

    TokenStreamRewriter rewriter = getTokenStreamRewriter();
    expect(rewriter.insertToken(a, b), same(b));
    expect(a.next, same(b));
    expect(b.next, same(eof));
    expect(eof.previous, same(b));
    expect(b.previous, same(a));

    normalTestDone(rewriter, a);
  }

  void test_insertToken_middle() {
    Token a = _makeToken(0, 'a');
    Token b = _makeToken(1, 'b');
    Token c = _makeToken(2, 'c');
    _link([a, c]);
    setupDone(a);

    TokenStreamRewriter rewriter = getTokenStreamRewriter();
    rewriter.insertToken(a, b);
    expect(a.next, same(b));
    expect(b.next, same(c));

    normalTestDone(rewriter, a);
  }

  void test_insertToken_second_insertion_earlier_in_stream() {
    Token a = _makeToken(0, 'a');
    Token b = _makeToken(1, 'b');
    Token c = _makeToken(2, 'c');
    Token d = _makeToken(3, 'd');
    Token e = _makeToken(4, 'e');
    _link([a, c, e]);
    setupDone(a);

    TokenStreamRewriter rewriter = getTokenStreamRewriter();
    rewriter.insertToken(c, d);
    expect(c.next, same(d));
    expect(d.next, same(e));
    // The next call to rewriter should be able to find the insertion point
    // even though it is before the insertion point used above.
    rewriter.insertToken(a, b);
    expect(a.next, same(b));
    expect(b.next, same(c));

    normalTestDone(rewriter, a);
  }

  void test_replaceNextTokenWithSyntheticToken_1() {
    Token a = _makeToken(0, 'a');
    StringToken b = _makeToken(5, 'b');
    b.precedingComments = new CommentToken.fromSubstring(
        TokenType.SINGLE_LINE_COMMENT, "Test comment", 1, 9, 1,
        canonicalize: true);
    Token c = _makeToken(10, 'c');
    _link([a, b, c]);
    setupDone(a);

    TokenStreamRewriter rewriter = getTokenStreamRewriter();
    ReplacementToken replacement =
        rewriter.replaceNextTokenWithSyntheticToken(a, TokenType.AMPERSAND);
    expect(b.offset, same(replacement.offset));
    expect(b.precedingComments, same(replacement.precedingComments));
    expect(replacement.replacedToken, same(b));

    expect(a.next, same(replacement));
    expect(replacement.next, same(c));
    expect(c.next.isEof, true);

    normalTestDone(rewriter, a);
  }

  void test_replaceNextTokenWithSyntheticToken_2() {
    Token a = _makeToken(0, 'a');
    StringToken b = _makeToken(5, 'b');
    b.precedingComments = new CommentToken.fromSubstring(
        TokenType.SINGLE_LINE_COMMENT, "Test comment", 1, 9, 1,
        canonicalize: true);
    _link([a, b]);
    setupDone(a);

    TokenStreamRewriter rewriter = getTokenStreamRewriter();
    ReplacementToken replacement =
        rewriter.replaceNextTokenWithSyntheticToken(a, TokenType.AMPERSAND);
    expect(b.offset, same(replacement.offset));
    expect(b.precedingComments, same(replacement.precedingComments));
    expect(replacement.replacedToken, same(b));

    expect(a.next, same(replacement));
    expect(replacement.next.isEof, true);

    normalTestDone(rewriter, a);
  }

  void test_moveSynthetic() {
    ScannerResult scanResult = scanString('Foo(bar; baz=0;');
    expect(scanResult.hasErrors, isTrue);
    Token firstToken = scanResult.tokens;
    setupDone(firstToken);

    Token open = scanResult.tokens.next.next;
    expect(open.lexeme, '(');
    Token close = open.endGroup;
    expect(close.isSynthetic, isTrue);
    expect(close.next.isEof, isTrue);
    TokenStreamRewriter rewriter = getTokenStreamRewriter();

    Token result = rewriter.moveSynthetic(open.next, close);
    expect(result, close);
    expect(open.endGroup, close);
    expect(open.next.next, close);
    expect(close.next.isEof, isFalse);

    normalTestDone(rewriter, firstToken);
  }

  void test_replaceTokenFollowing_multiple() {
    Token a = _makeToken(0, 'a');
    Token b = _makeToken(1, 'b');
    Token c = _makeToken(2, 'c');
    Token d = _makeToken(3, 'd');
    Token e = _makeToken(4, 'e');
    Token f = _makeToken(5, 'f');
    _link([a, b, e, f]);
    _link([c, d]);
    setupDone(a);

    TokenStreamRewriter rewriter = getTokenStreamRewriter();
    rewriter.replaceTokenFollowing(b, c);
    expect(a.next, same(b));
    expect(b.next, same(c));
    expect(c.next, same(d));
    expect(d.next, same(f));

    normalTestDone(rewriter, a);
  }

  void test_replaceTokenFollowing_single() {
    Token a = _makeToken(0, 'a');
    Token b = _makeToken(1, 'b');
    Token c = _makeToken(2, 'c');
    Token d = _makeToken(3, 'd');
    _link([a, b, d]);
    setupDone(a);

    TokenStreamRewriter rewriter = getTokenStreamRewriter();
    rewriter.replaceTokenFollowing(a, c);
    expect(a.next, same(c));
    expect(c.next, same(d));

    normalTestDone(rewriter, a);
  }

  /// Links together the given [tokens] and adds an EOF token to the end of the
  /// token stream.
  ///
  /// The EOF token is returned.
  Token _link(Iterable<Token> tokens) {
    Token head = new Token.eof(-1);
    if (!setPrevious) head.previous = null;
    for (Token token in tokens) {
      head.next = token;
      if (setPrevious) token.previous = head;
      head = token;
    }
    int eofOffset = head.charOffset + head.lexeme.length;
    if (eofOffset < 0) eofOffset = 0;
    Token eof = new Token.eof(eofOffset);
    if (!setPrevious) eof.previous = null;
    head.next = eof;
    if (setPrevious) eof.previous = head;
    return eof;
  }

  StringToken _makeToken(int charOffset, String text) {
    return new StringToken.fromString(null, text, charOffset);
  }
}

/// Concrete implementation of [TokenStreamRewriterTest] in which
/// [Token.previous] values are set to null.
///
/// This forces [TokenStreamRewriter] to use its more complex heuristic for
/// finding previous tokens.
@reflectiveTest
class TokenStreamRewriterTest_NoPrevious extends TokenStreamRewriterTest {
  @override
  bool get setPrevious => false;

  TokenStreamRewriter getTokenStreamRewriter() => new TokenStreamRewriterImpl();
}

/// Concrete implementation of [TokenStreamRewriterTest] in which
/// [Token.previous] values are set to non-null.
///
/// Since [TokenStreamRewriter] makes use of [Token.previous] when it can,
/// these tests do not exercise the more complex heuristics for finding previous
/// tokens.
@reflectiveTest
class TokenStreamRewriterTest_UsingPrevious extends TokenStreamRewriterTest {
  @override
  bool get setPrevious => true;

  TokenStreamRewriter getTokenStreamRewriter() => new TokenStreamRewriterImpl();
}

/// Concrete implementation of [TokenStreamRewriterTest] in which
/// the [UndoableTokenStreamRewriter] is used.
@reflectiveTest
class TokenStreamRewriterTest_Undoable extends TokenStreamRewriterTest {
  @override
  bool get setPrevious => true;

  TokenStreamRewriter getTokenStreamRewriter() =>
      new UndoableTokenStreamRewriter();

  List<CachedTokenSetup> setup;

  void setupDone(Token first) {
    setup = [];
    Token token = first;
    while (token != null && !token.isEof) {
      setup.add(new CachedTokenSetup(token));
      token = token.next;
    }
  }

  void normalTestDone(TokenStreamRewriter rewriter, Token first) {
    UndoableTokenStreamRewriter undoableTokenStreamRewriter = rewriter;
    undoableTokenStreamRewriter.undo();
    List<CachedTokenSetup> now = [];
    Token token = first;
    while (token != null && !token.isEof) {
      now.add(new CachedTokenSetup(token));
      token = token.next;
    }
    if (setup.length != now.length) {
      throw "Different length: ${setup.length} vs ${now.length}";
    }
    for (int i = 0; i < setup.length; i++) {
      if (setup[i] != now[i]) {
        throw "Different at $i: ${setup[i]} vs ${now[i]}";
      }
    }
    setup = null;
  }
}

class CachedTokenSetup {
  final Token token;
  final Token prev;
  final Token next;
  final Token precedingComments;

  CachedTokenSetup(this.token)
      : prev = token.previous,
        next = token.next,
        precedingComments = token.precedingComments;

  bool operator ==(Object other) {
    if (other is! CachedTokenSetup) return false;
    CachedTokenSetup o = other;
    return token == o.token &&
        prev == o.prev &&
        next == o.next &&
        precedingComments == o.precedingComments;
  }

  String toString() {
    return "CachedTokenSetup["
        "token = $token, "
        "prev = $prev, "
        "next = $next, "
        "precedingComments = $precedingComments"
        "]";
  }
}
