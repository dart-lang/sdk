// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract
class ArrayBasedScanner<S extends SourceString> extends AbstractScanner<S> {
  int get charOffset => byteOffset + extraCharOffset;
  final Token tokens;
  Token tail;
  int tokenStart;
  int byteOffset;
  final bool includeComments;

  /** Since the input is UTF8, some characters are represented by more
   * than one byte. [extraCharOffset] tracks the difference. */
  int extraCharOffset;
  Link<BeginGroupToken> groupingStack = const Link<BeginGroupToken>();

  ArrayBasedScanner(this.includeComments)
    : this.extraCharOffset = 0,
      this.tokenStart = -1,
      this.byteOffset = -1,
      this.tokens = new Token(EOF_INFO, -1) {
    this.tail = this.tokens;
  }

  int advance() {
    int next = nextByte();
    return next;
  }

  int select(int choice, PrecedenceInfo yes, PrecedenceInfo no) {
    int next = advance();
    if (identical(next, choice)) {
      appendPrecedenceToken(yes);
      return advance();
    } else {
      appendPrecedenceToken(no);
      return next;
    }
  }

  void appendPrecedenceToken(PrecedenceInfo info) {
    tail.next = new Token(info, tokenStart);
    tail = tail.next;
  }

  void appendStringToken(PrecedenceInfo info, String value) {
    tail.next = new StringToken(info, value, tokenStart);
    tail = tail.next;
  }

  void appendKeywordToken(Keyword keyword) {
    String syntax = keyword.syntax;

    // Type parameters and arguments cannot contain 'this' or 'super'.
    if (identical(syntax, 'this') || identical(syntax, 'super')) discardOpenLt();
    tail.next = new KeywordToken(keyword, tokenStart);
    tail = tail.next;
  }

  void appendEofToken() {
    tail.next = new Token(EOF_INFO, charOffset);
    tail = tail.next;
    // EOF points to itself so there's always infinite look-ahead.
    tail.next = tail;
    discardOpenLt();
    while (!groupingStack.isEmpty()) {
      BeginGroupToken begin = groupingStack.head;
      begin.endGroup = tail;
      groupingStack = groupingStack.tail;
    }
  }

  void beginToken() {
    tokenStart = charOffset;
  }

  Token firstToken() {
    return tokens.next;
  }

  Token previousToken() {
    return tail;
  }

  void addToCharOffset(int offset) {
    extraCharOffset += offset;
  }

  void appendWhiteSpace(int next) {
    // Do nothing, we don't collect white space.
  }

  void appendBeginGroup(PrecedenceInfo info, String value) {
    Token token = new BeginGroupToken(info, value, tokenStart);
    tail.next = token;
    tail = tail.next;
    if (!identical(info.kind, LT_TOKEN)) discardOpenLt();
    groupingStack = groupingStack.prepend(token);
  }

  int appendEndGroup(PrecedenceInfo info, String value, int openKind) {
    assert(!identical(openKind, LT_TOKEN));
    appendStringToken(info, value);
    discardOpenLt();
    if (groupingStack.isEmpty()) {
      return advance();
    }
    BeginGroupToken begin = groupingStack.head;
    if (!identical(begin.kind, openKind)) {
      if (!identical(openKind, OPEN_CURLY_BRACKET_TOKEN) ||
          !identical(begin.kind, STRING_INTERPOLATION_TOKEN)) {
        // Not ending string interpolation.
        return error(new SourceString('Unmatched ${begin.stringValue}'));
      }
      // We're ending an interpolated expression.
      begin.endGroup = tail;
      groupingStack = groupingStack.tail;
      // Using "start-of-text" to signal that we're back in string
      // scanning mode.
      return $STX;
    }
    begin.endGroup = tail;
    groupingStack = groupingStack.tail;
    return advance();
  }

  void appendGt(PrecedenceInfo info, String value) {
    appendStringToken(info, value);
    if (groupingStack.isEmpty()) return;
    if (identical(groupingStack.head.kind, LT_TOKEN)) {
      groupingStack.head.endGroup = tail;
      groupingStack = groupingStack.tail;
    }
  }

  void appendGtGt(PrecedenceInfo info, String value) {
    appendStringToken(info, value);
    if (groupingStack.isEmpty()) return;
    if (identical(groupingStack.head.kind, LT_TOKEN)) {
      groupingStack = groupingStack.tail;
    }
    if (groupingStack.isEmpty()) return;
    if (identical(groupingStack.head.kind, LT_TOKEN)) {
      groupingStack.head.endGroup = tail;
      groupingStack = groupingStack.tail;
    }
  }

  void appendGtGtGt(PrecedenceInfo info, String value) {
    appendStringToken(info, value);
    if (groupingStack.isEmpty()) return;
    if (identical(groupingStack.head.kind, LT_TOKEN)) {
      groupingStack = groupingStack.tail;
    }
    if (groupingStack.isEmpty()) return;
    if (identical(groupingStack.head.kind, LT_TOKEN)) {
      groupingStack = groupingStack.tail;
    }
    if (groupingStack.isEmpty()) return;
    if (identical(groupingStack.head.kind, LT_TOKEN)) {
      groupingStack.head.endGroup = tail;
      groupingStack = groupingStack.tail;
    }
  }

  void appendComment() {
    if (!includeComments) return;
    SourceString value = utf8String(tokenStart, -1);
    appendByteStringToken(COMMENT_INFO, value);
  }

  void discardOpenLt() {
    while (!groupingStack.isEmpty()
        && identical(groupingStack.head.kind, LT_TOKEN)) {
      groupingStack = groupingStack.tail;
    }
  }

  // TODO(ahe): make class abstract instead of adding an abstract method.
  abstract peek();
}
