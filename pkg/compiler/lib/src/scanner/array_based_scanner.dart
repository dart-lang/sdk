// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of scanner;

abstract class ArrayBasedScanner extends AbstractScanner {
  ArrayBasedScanner(SourceFile file, bool includeComments)
      : super(file, includeComments);

  /**
   * The stack of open groups, e.g [: { ... ( .. :]
   * Each BeginGroupToken has a pointer to the token where the group
   * ends. This field is set when scanning the end group token.
   */
  Link<BeginGroupToken> groupingStack = const Link<BeginGroupToken>();

  /**
   * Appends a fixed token whose kind and content is determined by [info].
   * Appends an *operator* token from [info].
   *
   * An operator token represent operators like ':', '.', ';', '&&', '==', '--',
   * '=>', etc.
   */
  void appendPrecedenceToken(PrecedenceInfo info) {
    tail.next = new SymbolToken(info, tokenStart);
    tail = tail.next;
  }

  /**
   * Appends a fixed token based on whether the current char is [choice] or not.
   * If the current char is [choice] a fixed token whose kind and content
   * is determined by [yes] is appended, otherwise a fixed token whose kind
   * and content is determined by [no] is appended.
   */
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

  /**
   * Appends a keyword token whose kind is determined by [keyword].
   */
  void appendKeywordToken(Keyword keyword) {
    String syntax = keyword.syntax;
    // Type parameters and arguments cannot contain 'this' or 'super'.
    if (identical(syntax, 'this') || identical(syntax, 'super')) {
      discardOpenLt();
    }
    tail.next = new KeywordToken(keyword, tokenStart);
    tail = tail.next;
  }

  void appendEofToken() {
    beginToken();
    discardOpenLt();
    while (!groupingStack.isEmpty) {
      unmatchedBeginGroup(groupingStack.head);
      groupingStack = groupingStack.tail;
    }
    tail.next = new SymbolToken(EOF_INFO, tokenStart);
    tail = tail.next;
    // EOF points to itself so there's always infinite look-ahead.
    tail.next = tail;
  }

  /**
   * Notifies scanning a whitespace character. Note that [appendWhiteSpace] is
   * not always invoked for [$SPACE] characters.
   *
   * This method is used by the scanners to track line breaks and create the
   * [lineStarts] map.
   */
  void appendWhiteSpace(int next) {
    if (next == $LF && file != null) {
      lineStarts.add(stringOffset + 1); // +1, the line starts after the $LF.
    }
  }

  /**
   * Notifies on [$LF] characters in multi-line comments or strings.
   *
   * This method is used by the scanners to track line breaks and create the
   * [lineStarts] map.
   */
  void lineFeedInMultiline() {
    if (file != null) {
      lineStarts.add(stringOffset + 1);
    }
  }

  /**
   * Appends a token that begins a new group, represented by [value].
   * Group begin tokens are '{', '(', '[' and '${'.
   */
  void appendBeginGroup(PrecedenceInfo info) {
    Token token = new BeginGroupToken(info, tokenStart);
    tail.next = token;
    tail = tail.next;

    // { (  [ ${ cannot appear inside a type parameters / arguments.
    if (!identical(info.kind, LT_TOKEN)) discardOpenLt();
    groupingStack = groupingStack.prepend(token);
  }

  /**
   * Appends a token that begins an end group, represented by [value].
   * It handles the group end tokens '}', ')' and ']'. The tokens '>' and
   * '>>' are handled separately bo [appendGt] and [appendGtGt].
   */
  int appendEndGroup(PrecedenceInfo info, int openKind) {
    assert(!identical(openKind, LT_TOKEN)); // openKind is < for > and >>
    discardBeginGroupUntil(openKind);
    appendPrecedenceToken(info);
    Token close = tail;
    if (groupingStack.isEmpty) {
      return advance();
    }
    BeginGroupToken begin = groupingStack.head;
    if (!identical(begin.kind, openKind)) {
      assert(begin.kind == STRING_INTERPOLATION_TOKEN &&
             openKind == OPEN_CURLY_BRACKET_TOKEN);
      // We're ending an interpolated expression.
      begin.endGroup = close;
      groupingStack = groupingStack.tail;
      // Using "start-of-text" to signal that we're back in string
      // scanning mode.
      return $STX;
    }
    begin.endGroup = close;
    groupingStack = groupingStack.tail;
    return advance();
  }

  /**
   * Discards begin group tokens until a match with [openKind] is found.
   * This recovers nicely from from a situation like "{[}".
   */
  void discardBeginGroupUntil(int openKind) {
    while (!groupingStack.isEmpty) {
      // Don't report unmatched errors for <; it is also the less-than operator.
      discardOpenLt();
      if (groupingStack.isEmpty) return;
      BeginGroupToken begin = groupingStack.head;
      if (openKind == begin.kind) return;
      if (openKind == OPEN_CURLY_BRACKET_TOKEN &&
          begin.kind == STRING_INTERPOLATION_TOKEN) return;
      unmatchedBeginGroup(begin);
      groupingStack = groupingStack.tail;
    }
  }

  /**
   * Appends a token for '>'.
   * This method does not issue unmatched errors, because > is also the
   * greater-than operator. It does not necessarily have to close a group.
   */
  void appendGt(PrecedenceInfo info) {
    appendPrecedenceToken(info);
    if (groupingStack.isEmpty) return;
    if (identical(groupingStack.head.kind, LT_TOKEN)) {
      groupingStack.head.endGroup = tail;
      groupingStack = groupingStack.tail;
    }
  }

  /**
   * Appends a token for '>>'.
   * This method does not issue unmatched errors, because >> is also the
   * shift operator. It does not necessarily have to close a group.
   */
  void appendGtGt(PrecedenceInfo info) {
    appendPrecedenceToken(info);
    if (groupingStack.isEmpty) return;
    if (identical(groupingStack.head.kind, LT_TOKEN)) {
      // Don't assign endGroup: in "T<U<V>>", the '>>' token closes the outer
      // '<', the inner '<' is left without endGroup.
      groupingStack = groupingStack.tail;
    }
    if (groupingStack.isEmpty) return;
    if (identical(groupingStack.head.kind, LT_TOKEN)) {
      groupingStack.head.endGroup = tail;
      groupingStack = groupingStack.tail;
    }
  }

  void appendComment(start, bool asciiOnly) {
    if (!includeComments) return;
    appendSubstringToken(COMMENT_INFO, start, asciiOnly);
  }

  void appendErrorToken(ErrorToken token) {
    tail.next = token;
    tail = token;
  }

  /**
   * This method is called to discard '<' from the "grouping" stack.
   *
   * [PartialParser.skipExpression] relies on the fact that we do not
   * create groups for stuff like:
   * [:a = b < c, d = e > f:].
   *
   * In other words, this method is called when the scanner recognizes
   * something which cannot possibly be part of a type parameter/argument
   * list, like the '=' in the above example.
   */
  void discardOpenLt() {
    while (!groupingStack.isEmpty
        && identical(groupingStack.head.kind, LT_TOKEN)) {
      groupingStack = groupingStack.tail;
    }
  }
}