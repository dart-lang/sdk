// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class ArrayBasedScanner<S> extends AbstractScanner<S> {
  int get charOffset() => byteOffset + extraCharOffset;
  final Token tokens;
  Token tail;
  int tokenStart;
  int byteOffset;

  /** Since the input is UTF8, some characters are represented by more
   * than one byte. [extraCharOffset] tracks the difference. */
  int extraCharOffset;
  Link<BeginGroupToken> groupingStack = const EmptyLink<BeginGroupToken>();

  ArrayBasedScanner()
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
    if (next === choice) {
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
    tail.next = new KeywordToken(keyword, tokenStart);
    tail = tail.next;
  }

  void appendEofToken() {
    tail.next = new Token(EOF_INFO, charOffset);
    tail = tail.next;
    // EOF points to itself so there's always infinite look-ahead.
    tail.next = tail;
    discardOpenLt();
    if (!groupingStack.isEmpty()) {
      BeginGroupToken begin = groupingStack.head;
      throw new MalformedInputException('Unbalanced ${begin.stringValue}',
                                        begin);
    }
  }

  void beginToken() {
    tokenStart = charOffset;
  }

  Token firstToken() {
    return tokens.next;
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
    while (info.kind !== LT_TOKEN &&
           !groupingStack.isEmpty() &&
           groupingStack.head.kind === LT_TOKEN) {
      groupingStack = groupingStack.tail;
    }
    groupingStack = groupingStack.prepend(token);
  }

  int appendEndGroup(PrecedenceInfo info, String value, int openKind) {
    assert(openKind !== LT_TOKEN);
    appendStringToken(info, value);
    discardOpenLt();
    if (groupingStack.isEmpty()) {
      return advance();
    }
    BeginGroupToken begin = groupingStack.head;
    if (begin.kind !== openKind) {
      if (openKind !== OPEN_CURLY_BRACKET_TOKEN ||
          begin.kind !== STRING_INTERPOLATION_TOKEN) {
        // Not ending string interpolation.
        throw new MalformedInputException('Unmatched ${begin.stringValue}',
                                          begin);
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
    if (groupingStack.head.kind === LT_TOKEN) {
      groupingStack.head.endGroup = tail;
      groupingStack = groupingStack.tail;
    }
  }

  void appendGtGt(PrecedenceInfo info, String value) {
    appendStringToken(info, value);
    if (groupingStack.isEmpty()) return;
    if (groupingStack.head.kind === LT_TOKEN) {
      groupingStack = groupingStack.tail;
    }
    if (groupingStack.isEmpty()) return;
    if (groupingStack.head.kind === LT_TOKEN) {
      groupingStack.head.endGroup = tail;
      groupingStack = groupingStack.tail;
    }
  }

  void appendGtGtGt(PrecedenceInfo info, String value) {
    appendStringToken(info, value);
    if (groupingStack.isEmpty()) return;
    if (groupingStack.head.kind === LT_TOKEN) {
      groupingStack = groupingStack.tail;
    }
    if (groupingStack.isEmpty()) return;
    if (groupingStack.head.kind === LT_TOKEN) {
      groupingStack = groupingStack.tail;
    }
    if (groupingStack.isEmpty()) return;
    if (groupingStack.head.kind === LT_TOKEN) {
      groupingStack.head.endGroup = tail;
      groupingStack = groupingStack.tail;
    }
  }

  void discardOpenLt() {
    while (!groupingStack.isEmpty() && groupingStack.head.kind === LT_TOKEN) {
      groupingStack = groupingStack.tail;
    }
  }

  // TODO(ahe): make class abstract instead of adding an abstract method.
  abstract peek();
}
