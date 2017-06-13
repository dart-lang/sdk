// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/parser/token_stream_rewriter.dart';
import 'package:front_end/src/fasta/scanner/token.dart';
import 'package:front_end/src/scanner/token.dart'
    show BeginToken, Token, TokenType;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TokenStreamRewriterTest_NoPrevious);
    defineReflectiveTests(TokenStreamRewriterTest_UsingPrevious);
  });
}

/// Abstract base class for tests of [TokenStreamRewriter].
abstract class TokenStreamRewriterTest {
  /// Indicates whether the tests should set up [Token.previous].
  bool get setPrevious;

  void test_insert_at_end() {
    var a = _makeToken(0, 'a');
    var b = _makeToken(1, 'b');
    var eof = _link([a]);
    var rewriter = new TokenStreamRewriter(a);
    rewriter.insertTokenBefore(b, eof);
    expect(rewriter.firstToken, same(a));
    expect(a.next, same(b));
    expect(b.next, same(eof));
    expect(eof.previous, same(b));
    expect(b.previous, same(a));
  }

  void test_insert_at_start() {
    var a = _makeToken(0, 'a');
    var b = _makeToken(1, 'b');
    _link([b]);
    var rewriter = new TokenStreamRewriter(b);
    rewriter.insertTokenBefore(a, b);
    expect(rewriter.firstToken, same(a));
    expect(a.next, same(b));
    expect(a.previous.next, same(a));
    expect(b.previous, same(a));
  }

  void test_resume_at_previous_insertion_point() {
    var a = _makeToken(0, 'a');
    var b = _makeToken(1, 'b');
    var c = _makeToken(2, 'c');
    var d = _makeToken(3, 'd');
    var e = _makeToken(4, 'e');
    _link([a, b, e]);
    var rewriter = new TokenStreamRewriter(a);
    rewriter.insertTokenBefore(d, e);
    expect(b.next, same(d));
    expect(d.next, same(e));
    a.next = null;
    // The next call to rewriter should be able to find the insertion point
    // without using a.next.
    rewriter.insertTokenBefore(c, d);
    expect(b.next, same(c));
    expect(c.next, same(d));
  }

  void test_second_insertion_earlier_in_stream() {
    var a = _makeToken(0, 'a');
    var b = _makeToken(1, 'b');
    var c = _makeToken(2, 'c');
    var d = _makeToken(3, 'd');
    var e = _makeToken(4, 'e');
    _link([a, c, e]);
    var rewriter = new TokenStreamRewriter(a);
    rewriter.insertTokenBefore(d, e);
    expect(c.next, same(d));
    expect(d.next, same(e));
    // The next call to rewriter should be able to find the insertion point
    // even though it is before the insertion point used above.
    rewriter.insertTokenBefore(b, c);
    expect(a.next, same(b));
    expect(b.next, same(c));
  }

  void test_skip_group() {
    var a = _makeBeginGroupToken(0);
    var b = _makeToken(1, 'b');
    var c = _makeToken(2, 'c');
    var d = _makeToken(3, 'd');
    var e = _makeToken(4, 'e');
    a.endGroup = c;
    _link([a, b, c, e]);
    // The rewriter should skip from a to c when finding the insertion position;
    // we test this by corrupting b's next pointer.
    b.next = null;
    var rewriter = new TokenStreamRewriter(a);
    rewriter.insertTokenBefore(d, e);
    expect(c.next, same(d));
    expect(d.next, same(e));
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

  BeginToken _makeBeginGroupToken(int charOffset) {
    return new BeginToken(TokenType.OPEN_PAREN, charOffset);
  }

  StringToken _makeToken(int charOffset, String text) {
    return new StringToken.fromString(null, text, charOffset);
  }
}

/// Concrete implementation of [TokenStreamRewriterTest] in which
/// [Token.previous] values are set to null.
///
/// This forces [TokenStreamRewriter] to use its more complex heursitc for
/// finding previous tokens.
@reflectiveTest
class TokenStreamRewriterTest_NoPrevious extends TokenStreamRewriterTest {
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
  bool get setPrevious => true;
}
