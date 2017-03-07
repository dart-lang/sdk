// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.scanner.array_based_scanner;

import 'error_token.dart' show ErrorToken;

import 'keyword.dart' show Keyword;

import 'precedence.dart' show COMMENT_INFO, EOF_INFO, PrecedenceInfo;

import 'token.dart'
    show BeginGroupToken, KeywordToken, StringToken, SymbolToken, Token;

import 'token_constants.dart'
    show LT_TOKEN, OPEN_CURLY_BRACKET_TOKEN, STRING_INTERPOLATION_TOKEN;

import 'characters.dart' show $LF, $STX;

import 'abstract_scanner.dart' show AbstractScanner;

import '../util/link.dart' show Link;

abstract class ArrayBasedScanner extends AbstractScanner {
  bool hasErrors = false;

  ArrayBasedScanner(bool includeComments, {int numberOfBytesHint})
      : super(includeComments, numberOfBytesHint: numberOfBytesHint);

  /**
   * The stack of open groups, e.g [: { ... ( .. :]
   * Each BeginGroupToken has a pointer to the token where the group
   * ends. This field is set when scanning the end group token.
   */
  Link<BeginGroupToken> groupingStack = const Link<BeginGroupToken>();

  /**
   * Append the given token to the [tail] of the current stream of tokens.
   */
  void appendToken(Token token) {
    tail.next = token;
    tail = tail.next;
    if (comments != null) {
      tail.precedingComments = comments;
      comments = null;
      commentsTail = null;
    }
  }

  /**
   * Appends a fixed token whose kind and content is determined by [info].
   * Appends an *operator* token from [info].
   *
   * An operator token represent operators like ':', '.', ';', '&&', '==', '--',
   * '=>', etc.
   */
  void appendPrecedenceToken(PrecedenceInfo info) {
    appendToken(new SymbolToken(info, tokenStart));
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
    // Type parameters and arguments cannot contain 'this'.
    if (identical(syntax, 'this')) {
      discardOpenLt();
    }
    appendToken(new KeywordToken(keyword, tokenStart));
  }

  void appendEofToken() {
    beginToken();
    discardOpenLt();
    while (!groupingStack.isEmpty) {
      unmatchedBeginGroup(groupingStack.head);
      groupingStack = groupingStack.tail;
    }
    appendToken(new SymbolToken(EOF_INFO, tokenStart));
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
    if (next == $LF) {
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
    lineStarts.add(stringOffset + 1);
  }

  /**
   * Appends a token that begins a new group, represented by [value].
   * Group begin tokens are '{', '(', '[' and '${'.
   */
  void appendBeginGroup(PrecedenceInfo info) {
    Token token = new BeginGroupToken(info, tokenStart);
    appendToken(token);

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
    Token newComment = createSubstringToken(COMMENT_INFO, start, asciiOnly);
    if (comments == null) {
      comments = newComment;
      commentsTail = comments;
    } else {
      commentsTail.next = newComment;
      commentsTail = commentsTail.next;
    }
  }

  void appendErrorToken(ErrorToken token) {
    hasErrors = true;
    appendToken(token);
  }

  void appendSubstringToken(PrecedenceInfo info, int start, bool asciiOnly,
      [int extraOffset = 0]) {
    appendToken(createSubstringToken(info, start, asciiOnly, extraOffset));
  }

  /**
   * Returns a new substring from the scan offset [start] to the current
   * [scanOffset] plus the [extraOffset]. For example, if the current
   * scanOffset is 10, then [appendSubstringToken(5, -1)] will append the
   * substring string [5,9).
   *
   * Note that [extraOffset] can only be used if the covered character(s) are
   * known to be ASCII.
   */
  StringToken createSubstringToken(
      PrecedenceInfo info, int start, bool asciiOnly,
      [int extraOffset = 0]);

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
    while (!groupingStack.isEmpty &&
        identical(groupingStack.head.kind, LT_TOKEN)) {
      groupingStack = groupingStack.tail;
    }
  }
}
