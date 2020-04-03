// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/parser/token_stream_rewriter.dart';
import 'package:_fe_analyzer_shared/src/scanner/scanner.dart'
    show ScannerResult, scanString;
import 'package:_fe_analyzer_shared/src/scanner/token.dart' show Token;
import 'package:_fe_analyzer_shared/src/scanner/token_impl.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TokenStreamGhostWriterTest);
    defineReflectiveTests(TokenStreamRewriterTest_NoPrevious);
    defineReflectiveTests(TokenStreamRewriterTest_UsingPrevious);
  });
}

/// Abstract base class for tests of [TokenStreamRewriter].
abstract class TokenStreamRewriterTest {
  /// Indicates whether the tests should set up [Token.previous].
  bool get setPrevious;

  void test_insertParens() {
    var a = _makeToken(0, 'a');
    var b = _makeToken(1, 'b');
    var eof = _link([a, b]);
    var rewriter = new TokenStreamRewriterImpl();
    var openParen = rewriter.insertParens(a, false);
    var closeParen = openParen.next;

    expect(openParen.lexeme, '(');
    expect(closeParen.lexeme, ')');

    expect(a.next, same(openParen));
    expect(openParen.next, same(closeParen));
    expect(closeParen.next, same(b));
    expect(b.next, same(eof));

    expect(b.previous, same(closeParen));
    expect(closeParen.previous, same(openParen));
    expect(openParen.previous, same(a));
  }

  void test_insertParensWithIdentifier() {
    var a = _makeToken(0, 'a');
    var b = _makeToken(1, 'b');
    var eof = _link([a, b]);
    var rewriter = new TokenStreamRewriterImpl();
    var openParen = rewriter.insertParens(a, true);
    var identifier = openParen.next;
    var closeParen = identifier.next;

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
  }

  void test_insertSyntheticIdentifier() {
    var a = _makeToken(0, 'a');
    var b = _makeToken(1, 'b');
    var eof = _link([a, b]);
    var rewriter = new TokenStreamRewriterImpl();
    var identifier = rewriter.insertSyntheticIdentifier(a);

    expect(identifier.lexeme, '');
    expect(identifier.isSynthetic, isTrue);

    expect(a.next, same(identifier));
    expect(identifier.next, same(b));
    expect(b.next, same(eof));

    expect(b.previous, same(identifier));
    expect(identifier.previous, same(a));
  }

  void test_insertToken_end() {
    var a = _makeToken(0, 'a');
    var b = _makeToken(1, 'b');
    var eof = _link([a]);
    var rewriter = new TokenStreamRewriterImpl();
    expect(rewriter.insertToken(a, b), same(b));
    expect(a.next, same(b));
    expect(b.next, same(eof));
    expect(eof.previous, same(b));
    expect(b.previous, same(a));
  }

  void test_insertToken_middle() {
    var a = _makeToken(0, 'a');
    var b = _makeToken(1, 'b');
    var c = _makeToken(2, 'c');
    _link([a, c]);
    var rewriter = new TokenStreamRewriterImpl();
    rewriter.insertToken(a, b);
    expect(a.next, same(b));
    expect(b.next, same(c));
  }

  void test_insertToken_second_insertion_earlier_in_stream() {
    var a = _makeToken(0, 'a');
    var b = _makeToken(1, 'b');
    var c = _makeToken(2, 'c');
    var d = _makeToken(3, 'd');
    var e = _makeToken(4, 'e');
    _link([a, c, e]);
    var rewriter = new TokenStreamRewriterImpl();
    rewriter.insertToken(c, d);
    expect(c.next, same(d));
    expect(d.next, same(e));
    // The next call to rewriter should be able to find the insertion point
    // even though it is before the insertion point used above.
    rewriter.insertToken(a, b);
    expect(a.next, same(b));
    expect(b.next, same(c));
  }

  void test_moveSynthetic() {
    ScannerResult scanResult = scanString('Foo(bar; baz=0;');
    expect(scanResult.hasErrors, isTrue);
    Token open = scanResult.tokens.next.next;
    expect(open.lexeme, '(');
    Token close = open.endGroup;
    expect(close.isSynthetic, isTrue);
    expect(close.next.isEof, isTrue);
    var rewriter = new TokenStreamRewriterImpl();

    Token result = rewriter.moveSynthetic(open.next, close);
    expect(result, close);
    expect(open.endGroup, close);
    expect(open.next.next, close);
    expect(close.next.isEof, isFalse);
  }

  void test_replaceTokenFollowing_multiple() {
    var a = _makeToken(0, 'a');
    var b = _makeToken(1, 'b');
    var c = _makeToken(2, 'c');
    var d = _makeToken(3, 'd');
    var e = _makeToken(4, 'e');
    var f = _makeToken(5, 'f');
    _link([a, b, e, f]);
    _link([c, d]);
    var rewriter = new TokenStreamRewriterImpl();
    rewriter.replaceTokenFollowing(b, c);
    expect(a.next, same(b));
    expect(b.next, same(c));
    expect(c.next, same(d));
    expect(d.next, same(f));
  }

  void test_replaceTokenFollowing_single() {
    var a = _makeToken(0, 'a');
    var b = _makeToken(1, 'b');
    var c = _makeToken(2, 'c');
    var d = _makeToken(3, 'd');
    _link([a, b, d]);
    var rewriter = new TokenStreamRewriterImpl();
    rewriter.replaceTokenFollowing(a, c);
    expect(a.next, same(c));
    expect(c.next, same(d));
  }

  /// Links together the given [tokens] and adds an EOF token to the end of the
  /// token stream.
  ///
  /// The EOF token is returned.
  Token _link(Iterable<Token> tokens) {
    Token head = new Token.eof(-1);
    if (!setPrevious) head.previous = null;
    for (var token in tokens) {
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
}

@reflectiveTest
class TokenStreamGhostWriterTest extends TokenStreamRewriterTest {
  @override
  bool get setPrevious => false;

  void test_insertParens() {
    var a = _makeToken(0, 'a');
    var b = _makeToken(1, 'b');
    var eof = _link([a, b]);
    var rewriter = new TokenStreamGhostWriter();
    var openParen = rewriter.insertParens(a, false);
    var closeParen = openParen.next;

    expect(openParen.lexeme, '(');
    expect(closeParen.lexeme, ')');

    expect(a.next, same(b));
    expect(openParen.next, same(closeParen));
    expect(closeParen.next, same(b));
    expect(b.next, same(eof));

    expect(b.previous, isNull);
    expect(closeParen.previous, isNull);
    expect(openParen.previous, isNull);
  }

  void test_insertParensWithIdentifier() {
    var a = _makeToken(0, 'a');
    var b = _makeToken(1, 'b');
    var eof = _link([a, b]);
    var rewriter = new TokenStreamGhostWriter();
    var openParen = rewriter.insertParens(a, true);
    var identifier = openParen.next;
    var closeParen = identifier.next;

    expect(openParen.lexeme, '(');
    expect(identifier.lexeme, '');
    expect(identifier.isSynthetic, isTrue);
    expect(closeParen.lexeme, ')');

    expect(a.next, same(b));
    expect(openParen.next, same(identifier));
    expect(identifier.next, same(closeParen));
    expect(closeParen.next, same(b));
    expect(b.next, same(eof));

    expect(b.previous, isNull);
    expect(closeParen.previous, isNull);
    expect(identifier.previous, isNull);
    expect(openParen.previous, isNull);
  }

  void test_insertSyntheticIdentifier() {
    var a = _makeToken(0, 'a');
    var b = _makeToken(1, 'b');
    var eof = _link([a, b]);
    var rewriter = new TokenStreamGhostWriter();
    var identifier = rewriter.insertSyntheticIdentifier(a);

    expect(identifier.lexeme, '');
    expect(identifier.isSynthetic, isTrue);

    expect(a.next, same(b));
    expect(identifier.next, same(b));
    expect(b.next, same(eof));

    expect(b.previous, isNull);
    expect(identifier.previous, isNull);
  }

  void test_insertToken_end() {
    var a = _makeToken(0, 'a');
    var b = _makeToken(1, 'b');
    var eof = _link([a]);
    var rewriter = new TokenStreamGhostWriter();

    expect(rewriter.insertToken(a, b), same(b));
    expect(a.next, same(eof));
    expect(b.next, same(eof));

    expect(eof.previous, isNull);
    expect(b.previous, isNull);
  }

  void test_insertToken_middle() {
    var a = _makeToken(0, 'a');
    var b = _makeToken(1, 'b');
    var c = _makeToken(2, 'c');
    _link([a, c]);

    var rewriter = new TokenStreamGhostWriter();
    rewriter.insertToken(a, b);
    expect(a.next, same(c));
    expect(b.next, same(c));

    expect(a.previous, isNull);
    expect(b.previous, isNull);
    expect(c.previous, isNull);
  }

  void test_insertToken_second_insertion_earlier_in_stream() {
    var a = _makeToken(0, 'a');
    var b = _makeToken(1, 'b');
    var c = _makeToken(2, 'c');
    var d = _makeToken(3, 'd');
    var e = _makeToken(4, 'e');
    _link([a, c, e]);
    var rewriter = new TokenStreamGhostWriter();

    rewriter.insertToken(c, d);
    expect(c.next, same(e));
    expect(d.next, same(e));

    // The next call to rewriter should be able to find the insertion point
    // even though it is before the insertion point used above.
    rewriter.insertToken(a, b);
    expect(a.next, same(c));
    expect(b.next, same(c));

    expect(a.previous, isNull);
    expect(b.previous, isNull);
    expect(c.previous, isNull);
    expect(d.previous, isNull);
    expect(e.previous, isNull);
  }

  void test_moveSynthetic() {
    ScannerResult scanResult = scanString('Foo(bar; baz=0;');
    expect(scanResult.hasErrors, isTrue);
    Token open = scanResult.tokens.next.next;
    expect(open.lexeme, '(');
    Token semicolon = open.next.next;
    expect(semicolon.lexeme, ';');
    Token close = open.endGroup;
    expect(close.isSynthetic, isTrue);
    expect(close.next.isEof, isTrue);
    Token semicolon2 = close.previous;
    expect(semicolon2.lexeme, ';');
    var rewriter = new TokenStreamGhostWriter();

    Token newClose = rewriter.moveSynthetic(open.next, close);
    expect(newClose, isNot(same(close)));
    expect(newClose.next, same(semicolon));
    expect(open.endGroup, close);
    expect(open.next.next, semicolon);
    expect(close.next.isEof, isTrue);

    expect(newClose.previous, isNull);
    expect(close.next.previous, close);
    expect(close.previous, semicolon2);
  }

  void test_replaceTokenFollowing_multiple() {
    var a = _makeToken(0, 'a');
    var b = _makeToken(1, 'b');
    var c = _makeToken(2, 'c');
    var d = _makeToken(3, 'd');
    var e = _makeToken(4, 'e');
    var f = _makeToken(5, 'f');
    _link([a, b, e, f]);
    _link([c, d]);
    var rewriter = new TokenStreamGhostWriter();
    Token result = rewriter.replaceTokenFollowing(b, c);

    expect(result, same(c));
    expect(a.next, same(b));
    expect(b.next, same(e));
    expect(e.next, same(f));
    expect(c.next, same(d));
    expect(d.next, same(f));

    expect(a.previous, isNull);
    expect(b.previous, isNull);
    expect(c.previous, isNull);
    expect(d.previous, isNull);
    expect(e.previous, isNull);
  }

  void test_replaceTokenFollowing_single() {
    var a = _makeToken(0, 'a');
    var b = _makeToken(1, 'b');
    var c = _makeToken(2, 'c');
    var d = _makeToken(3, 'd');
    _link([a, b, d]);
    var rewriter = new TokenStreamGhostWriter();
    Token result = rewriter.replaceTokenFollowing(a, c);

    expect(result, same(c));
    expect(a.next, same(b));
    expect(b.next, same(d));
    expect(c.next, same(d));

    expect(a.previous, isNull);
    expect(b.previous, isNull);
    expect(c.previous, isNull);
  }
}
