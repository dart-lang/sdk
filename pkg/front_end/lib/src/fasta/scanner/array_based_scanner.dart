// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.scanner.array_based_scanner;

import 'error_token.dart' show ErrorToken, UnmatchedToken;

import '../../scanner/token.dart'
    show
        BeginToken,
        BeginTokenWithComment,
        Keyword,
        KeywordTokenWithComment,
        SyntheticToken,
        Token,
        TokenType,
        TokenWithComment;

import '../../scanner/token.dart' as analyzer show StringToken;

import 'token_constants.dart'
    show
        LT_TOKEN,
        OPEN_CURLY_BRACKET_TOKEN,
        OPEN_PAREN_TOKEN,
        STRING_INTERPOLATION_TOKEN;

import 'characters.dart' show $LF, $STX;

import 'abstract_scanner.dart' show AbstractScanner, closeBraceInfoFor;

import '../util/link.dart' show Link;

abstract class ArrayBasedScanner extends AbstractScanner {
  bool hasErrors = false;

  ArrayBasedScanner(bool includeComments, bool scanGenericMethodComments,
      {int numberOfBytesHint})
      : super(includeComments, scanGenericMethodComments,
            numberOfBytesHint: numberOfBytesHint);

  /**
   * The stack of open groups, e.g [: { ... ( .. :]
   * Each BeginToken has a pointer to the token where the group
   * ends. This field is set when scanning the end group token.
   */
  Link<BeginToken> groupingStack = const Link<BeginToken>();

  /**
   * Appends a fixed token whose kind and content is determined by [type].
   * Appends an *operator* token from [type].
   *
   * An operator token represent operators like ':', '.', ';', '&&', '==', '--',
   * '=>', etc.
   */
  void appendPrecedenceToken(TokenType type) {
    appendToken(new TokenWithComment(type, tokenStart, comments));
  }

  /**
   * Appends a fixed token based on whether the current char is [choice] or not.
   * If the current char is [choice] a fixed token whose kind and content
   * is determined by [yes] is appended, otherwise a fixed token whose kind
   * and content is determined by [no] is appended.
   */
  int select(int choice, TokenType yes, TokenType no) {
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
    String syntax = keyword.lexeme;
    // Type parameters and arguments cannot contain 'this'.
    if (identical(syntax, 'this')) {
      discardOpenLt();
    }
    appendToken(new KeywordTokenWithComment(keyword, tokenStart, comments));
  }

  void appendEofToken() {
    beginToken();
    discardOpenLt();
    while (!groupingStack.isEmpty) {
      unmatchedBeginGroup(groupingStack.head);
      groupingStack = groupingStack.tail;
    }
    appendToken(new Token.eof(tokenStart, comments));
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
   * Appends a token that begins a new group, represented by [type].
   * Group begin tokens are '{', '(', '[', '<' and '${'.
   */
  void appendBeginGroup(TokenType type) {
    Token token = new BeginTokenWithComment(type, tokenStart, comments);
    appendToken(token);

    // { [ ${ cannot appear inside a type parameters / arguments.
    if (!identical(type.kind, LT_TOKEN) &&
        !identical(type.kind, OPEN_PAREN_TOKEN)) {
      discardOpenLt();
    }
    groupingStack = groupingStack.prepend(token);
  }

  /**
   * Appends a token that begins an end group, represented by [type].
   * It handles the group end tokens '}', ')' and ']'. The tokens '>' and
   * '>>' are handled separately by [appendGt] and [appendGtGt].
   */
  int appendEndGroup(TokenType type, int openKind) {
    assert(!identical(openKind, LT_TOKEN)); // openKind is < for > and >>
    if (!discardBeginGroupUntil(openKind)) {
      // No begin group found. Just continue.
      appendPrecedenceToken(type);
      return advance();
    }
    appendPrecedenceToken(type);
    Token close = tail;
    BeginToken begin = groupingStack.head;
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
   * If a begin group token matches [openKind],
   * then discard begin group tokens up to that match and return `true`,
   * otherwise return `false`.
   * This recovers nicely from from situations like "{[}" and "{foo());}",
   * but not "foo(() {bar());});
   */
  bool discardBeginGroupUntil(int openKind) {
    Link<BeginToken> originalStack = groupingStack;

    bool first = true;
    do {
      // Don't report unmatched errors for <; it is also the less-than operator.
      discardOpenLt();
      if (groupingStack.isEmpty) break; // recover
      BeginToken begin = groupingStack.head;
      if (openKind == begin.kind ||
          (openKind == OPEN_CURLY_BRACKET_TOKEN &&
              begin.kind == STRING_INTERPOLATION_TOKEN)) {
        if (first) {
          // If the expected opener has been found on the first pass
          // then no recovery necessary.
          return true;
        }
        break; // recover
      }
      first = false;
      groupingStack = groupingStack.tail;
    } while (!groupingStack.isEmpty);

    // If the stack does not have any opener of the given type,
    // then return without discarding anything.
    // This recovers nicely from from situations like "{foo());}".
    if (groupingStack.isEmpty) {
      groupingStack = originalStack;
      return false;
    }

    // Insert synthetic closers and report errors for any unbalanced openers.
    // This recovers nicely from from situations like "{[}".
    while (!identical(originalStack, groupingStack)) {
      // Don't report unmatched errors for <; it is also the less-than operator.
      if (!identical(groupingStack.head.kind, LT_TOKEN))
        unmatchedBeginGroup(originalStack.head);
      originalStack = originalStack.tail;
    }
    return true;
  }

  /**
   * Appends a token for '>'.
   * This method does not issue unmatched errors, because > is also the
   * greater-than operator. It does not necessarily have to close a group.
   */
  void appendGt(TokenType type) {
    appendPrecedenceToken(type);
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
  void appendGtGt(TokenType type) {
    appendPrecedenceToken(type);
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

  void appendErrorToken(ErrorToken token) {
    hasErrors = true;
    appendToken(token);
  }

  @override
  void appendSubstringToken(TokenType type, int start, bool asciiOnly,
      [int extraOffset = 0]) {
    appendToken(createSubstringToken(type, start, asciiOnly, extraOffset));
  }

  @override
  void appendSyntheticSubstringToken(
      TokenType type, int start, bool asciiOnly, String closingQuotes) {
    appendToken(
        createSyntheticSubstringToken(type, start, asciiOnly, closingQuotes));
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
  analyzer.StringToken createSubstringToken(
      TokenType type, int start, bool asciiOnly,
      [int extraOffset = 0]);

  /**
   * Returns a new synthetic substring from the scan offset [start]
   * to the current [scanOffset] plus the [closingQuotes].
   * The [closingQuotes] are appended to the unterminated string
   * literal's lexeme but the returned token's length will *not* include
   * those closing quotes so as to be true to the original source.
   */
  analyzer.StringToken createSyntheticSubstringToken(
      TokenType type, int start, bool asciiOnly, String closingQuotes);

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

  /**
   * This method is called to discard '${' from the "grouping" stack.
   *
   * This method is called when the scanner finds an unterminated
   * interpolation expression.
   */
  void discardInterpolation() {
    while (!groupingStack.isEmpty) {
      BeginToken beginToken = groupingStack.head;
      unmatchedBeginGroup(beginToken);
      groupingStack = groupingStack.tail;
      if (identical(beginToken.kind, STRING_INTERPOLATION_TOKEN)) break;
    }
  }

  void unmatchedBeginGroup(BeginToken begin) {
    // We want to ensure that unmatched BeginTokens are reported as
    // errors.  However, the diet parser assumes that groups are well-balanced
    // and will never look at the endGroup token.  This is a nice property that
    // allows us to skip quickly over correct code. By inserting an additional
    // synthetic token in the stream, we can keep ignoring endGroup tokens.
    //
    // [begin] --next--> [tail]
    // [begin] --endG--> [synthetic] --next--> [next] --next--> [tail]
    //
    // This allows the diet parser to skip from [begin] via endGroup to
    // [synthetic] and ignore the [synthetic] token (assuming it's correct),
    // then the error will be reported when parsing the [next] token.
    //
    // For example, tokenize("{[1};") produces:
    //
    // SymbolToken({) --endGroup------------------------+
    //      |                                           |
    //     next                                         |
    //      v                                           |
    // SymbolToken([) --endGroup--+                     |
    //      |                     |                     |
    //     next                   |                     |
    //      v                     |                     |
    // StringToken(1)             |                     |
    //      |                     |                     |
    //     next                   |                     |
    //      v                     |                     |
    // SymbolToken(])<------------+ <-- Synthetic token |
    //      |                                           |
    //     next                                         |
    //      v                                           |
    // UnmatchedToken([)                                |
    //      |                                           |
    //     next                                         |
    //      v                                           |
    // SymbolToken(})<----------------------------------+
    //      |
    //     next
    //      v
    // SymbolToken(;)
    //      |
    //     next
    //      v
    //     EOF
    TokenType type = closeBraceInfoFor(begin);
    appendToken(new SyntheticToken(type, tokenStart));
    begin.endGroup = tail;
    appendErrorToken(new UnmatchedToken(begin));
  }
}
