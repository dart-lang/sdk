// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// @docImport 'string_scanner.dart';
/// @docImport 'utf8_bytes_scanner.dart';
/// @docImport '../parser/class_member_parser.dart';
library _fe_analyzer_shared.scanner.abstract_scanner;

import 'dart:collection' show ListMixin;

import 'dart:typed_data' show Uint16List, Uint32List;

import 'internal_utils.dart' show isIdentifierChar;

import 'keyword_state.dart' show KeywordState, KeywordStateHelper;

import 'token.dart'
    show
        BeginToken,
        CommentToken,
        Keyword,
        KeywordToken,
        LanguageVersionToken,
        SyntheticToken,
        Token,
        TokenIsAExtension,
        TokenType;

import 'token.dart' as analyzer show StringToken;

import '../messages/codes.dart'
    show
        codeExpectedHexDigit,
        codeMissingExponent,
        codeUnexpectedDollarInString,
        codeUnexpectedSeparatorInNumber,
        codeUnterminatedComment;

import '../util/link.dart' show Link;

import 'characters.dart';

import 'error_token.dart'
    show
        NonAsciiIdentifierToken,
        UnmatchedToken,
        UnsupportedOperator,
        UnterminatedString,
        UnterminatedToken;

import 'token_impl.dart' show DartDocToken, StringTokenImpl;

import 'token_constants.dart';

import 'scanner.dart'
    show ErrorToken, Keyword, Scanner, buildUnexpectedCharacterToken;

typedef void LanguageVersionChanged(
  Scanner scanner,
  LanguageVersionToken languageVersion,
);

abstract class AbstractScanner implements Scanner {
  /**
   * A flag indicating whether character sequences `&&=` and `||=`
   * should be tokenized as the assignment operators
   * [AMPERSAND_AMPERSAND_EQ_TOKEN] and [BAR_BAR_EQ_TOKEN] respectively.
   * See issue https://github.com/dart-lang/sdk/issues/30340
   */
  static const bool LAZY_ASSIGNMENT_ENABLED = false;

  final bool includeComments;

  /// Called when the scanner detects a language version comment
  /// so that the listener can update the scanner configuration
  /// based upon the specified language version.
  final LanguageVersionChanged? languageVersionChanged;

  /// Experimental flag for enabling scanning of `>>>`.
  /// See https://github.com/dart-lang/language/issues/61
  /// and https://github.com/dart-lang/language/issues/60
  bool _enableTripleShift = false;

  /// If `true`, 'augment' is treated as a built-in identifier.
  bool _forAugmentationLibrary = false;

  /**
   * The string offset for the next token that will be created.
   *
   * Note that in the [Utf8BytesScanner], [stringOffset] and [scanOffset] values
   * are different. One string character can be encoded using multiple UTF-8
   * bytes.
   */
  int tokenStart = -1;

  /**
   * A pointer to the token stream created by this scanner. The first token
   * is a special token and not part of the source file. This is an
   * implementation detail to avoids special cases in the scanner. This token
   * is not exposed to clients of the scanner, which are expected to invoke
   * [firstToken] to access the token stream.
   */
  final Token tokens;

  /**
   * A pointer to the last scanned token.
   */
  Token tail;

  /**
   * A pointer to the last prepended error token.
   */
  Token errorTail;

  @override
  bool hasErrors = false;

  Token? openBraceWithMissingEndForPossibleRecovery;

  int? offsetForCurlyBracketRecoveryStart;

  /**
   * A pointer to the stream of comment tokens created by this scanner
   * before they are assigned to the [Token] precedingComments field
   * of a non-comment token. A value of `null` indicates no comment tokens.
   */
  CommentToken? comments;

  /**
   * A pointer to the last scanned comment token or `null` if none.
   */
  Token? commentsTail;

  @override
  final List<int> lineStarts;

  /**
   * The stack of open groups, e.g [: { ... ( .. :]
   * Each BeginToken has a pointer to the token where the group
   * ends. This field is set when scanning the end group token.
   */
  Link<BeginToken> groupingStack = const Link<BeginToken>();

  final bool inRecoveryOption;
  int recoveryCount = 0;
  final bool allowLazyStrings;

  AbstractScanner(
    ScannerConfiguration? config,
    bool includeComments,
    LanguageVersionChanged? languageVersionChanged, {
    required int numberOfBytesHint,
    bool allowLazyStrings = true,
  }) : this._(
         config,
         includeComments,
         languageVersionChanged,
         new Token.eof(/* offset = */ -1),
         numberOfBytesHint: numberOfBytesHint,
         allowLazyStrings: allowLazyStrings,
       );

  AbstractScanner._(
    ScannerConfiguration? config,
    this.includeComments,
    this.languageVersionChanged,
    Token newEofToken, {
    required int numberOfBytesHint,
    this.allowLazyStrings = true,
  }) : lineStarts = new LineStarts(numberOfBytesHint),
       inRecoveryOption = false,
       tokens = newEofToken,
       tail = newEofToken,
       errorTail = newEofToken {
    this.configuration = config;
  }

  AbstractScanner createRecoveryOptionScanner();

  AbstractScanner.recoveryOptionScanner(AbstractScanner copyFrom)
    : this._recoveryOptionScanner(copyFrom, new Token.eof(/* offset = */ -1));

  AbstractScanner._recoveryOptionScanner(
    AbstractScanner copyFrom,
    Token newEofToken,
  ) : lineStarts = [],
      includeComments = false,
      languageVersionChanged = null,
      inRecoveryOption = true,
      allowLazyStrings = true,
      tokens = newEofToken,
      tail = newEofToken,
      errorTail = newEofToken {
    this._enableTripleShift = copyFrom._enableTripleShift;
    this.tokenStart = copyFrom.tokenStart;
    this.groupingStack = copyFrom.groupingStack;
  }

  @override
  set configuration(ScannerConfiguration? config) {
    if (config != null) {
      _enableTripleShift = config.enableTripleShift;
      _forAugmentationLibrary = config.forAugmentationLibrary;
    }
  }

  /**
   * Advances and returns the next character.
   *
   * If the next character is non-ASCII, then the returned value depends on the
   * scanner implementation. The [Utf8BytesScanner] returns a UTF-8 byte, while
   * the [StringScanner] returns a UTF-16 code unit.
   *
   * The scanner ensures that [advance] is not invoked after it returned [$EOF].
   * This allows implementations to omit bound checks if the data structure ends
   * with '0'.
   */
  int advance();

  /**
   * Returns the current unicode character.
   *
   * If the current character is ASCII, then it is returned unchanged.
   *
   * The [Utf8BytesScanner] decodes the next unicode code point starting at the
   * current position. Note that every unicode character is returned as a single
   * code point, that is, for '\u{1d11e}' it returns 119070, and the following
   * [advance] returns the next character.
   *
   * The [StringScanner] returns the current character unchanged, which might
   * be a surrogate character. In the case of '\u{1d11e}', it returns the first
   * code unit 55348, and the following [advance] returns the second code unit
   * 56606.
   *
   * Invoking [currentAsUnicode] multiple times is safe, i.e.,
   * [:currentAsUnicode(next) == currentAsUnicode(currentAsUnicode(next)):].
   */
  int currentAsUnicode(int next);

  /**
   * Returns the character at the next position. Like in [advance], the
   * [Utf8BytesScanner] returns a UTF-8 byte, while the [StringScanner] returns
   * a UTF-16 code unit.
   */
  int peek();

  /**
   * Notifies the scanner that unicode characters were detected in either a
   * comment or a string literal between [startScanOffset] and the current
   * scan offset.
   */
  void handleUnicode(int startScanOffset);

  /**
   * Returns the current scan offset.
   *
   * In the [Utf8BytesScanner] this is the offset into the byte list, in the
   * [StringScanner] the offset in the source string.
   */
  int get scanOffset;

  /**
   * Returns the current string offset.
   *
   * In the [StringScanner] this is identical to the [scanOffset]. In the
   * [Utf8BytesScanner] it is computed based on encountered UTF-8 characters.
   */
  int get stringOffset;

  /**
   * Returns the first token scanned by this [Scanner].
   */
  Token firstToken() => tokens.next!;

  /**
   * Notifies that a new token starts at current offset.
   */
  @pragma("vm:prefer-inline")
  void beginToken() {
    tokenStart = stringOffset;
  }

  /**
   * Appends a substring from the scan offset [:start:] to the current
   * [:scanOffset:] plus the [:extraOffset:]. For example, if the current
   * scanOffset is 10, then [:appendSubstringToken(5, -1):] will append the
   * substring string [5,9).
   *
   * Note that [extraOffset] can only be used if the covered character(s) are
   * known to be ASCII.
   */
  void appendSubstringToken(
    TokenType type,
    int start,
    bool asciiOnly, [
    int extraOffset = 0,
  ]) {
    appendToken(
      createSubstringToken(
        type,
        start,
        asciiOnly,
        extraOffset,
        allowLazyStrings,
      ),
    );
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
    TokenType type,
    int start,
    bool asciiOnly,
    int extraOffset,
    bool allowLazy,
  );

  /**
   * Appends a substring from the scan offset [start] to the current
   * [scanOffset] plus [syntheticChars]. The additional char(s) will be added
   * to the unterminated string literal's lexeme but the returned
   * token's length will *not* include those additional char(s)
   * so as to be true to the original source.
   */
  void appendSyntheticSubstringToken(
    TokenType type,
    int start,
    bool asciiOnly,
    String syntheticChars,
  ) {
    appendToken(
      createSyntheticSubstringToken(type, start, asciiOnly, syntheticChars),
    );
  }

  /**
   * Returns a new synthetic substring from the scan offset [start]
   * to the current [scanOffset] plus the [syntheticChars].
   * The [syntheticChars] are appended to the unterminated string
   * literal's lexeme but the returned token's length will *not* include
   * those additional characters so as to be true to the original source.
   */
  analyzer.StringToken createSyntheticSubstringToken(
    TokenType type,
    int start,
    bool asciiOnly,
    String syntheticChars,
  );
  /**
   * Appends a fixed token whose kind and content is determined by [type].
   * Appends an *operator* token from [type].
   *
   * An operator token represent operators like ':', '.', ';', '&&', '==', '--',
   * '=>', etc.
   */
  void appendPrecedenceToken(TokenType type) {
    appendToken(new Token(type, tokenStart, comments));
  }

  /**
   * Appends a fixed token based on whether the current char is [choice] or not.
   * If the current char is [choice] a fixed token whose kind and content
   * is determined by [yes] is appended, otherwise a fixed token whose kind
   * and content is determined by [no] is appended.
   */
  int select(int choice, TokenType yes, TokenType no) {
    int next = advance();
    if (next == choice) {
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
    appendToken(new KeywordToken(keyword, tokenStart, comments));
  }

  int _getLineOf(Token token) {
    if (lineStarts.isEmpty) {
      // Coverage-ignore-block(suite): Not run.
      return -1;
    }
    final int offset = token.offset;
    int low = 0, high = lineStarts.length - 1;
    while (low < high) {
      int mid = high - ((high - low) >> 1); // Get middle, rounding up.
      int pivot = lineStarts[mid];
      if (pivot <= offset) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }
    return low;
  }

  /// Find the indentation of the logical line of [token].
  ///
  /// By logical take this as an example:
  ///
  /// ```
  ///   if (a &&
  ///       b) {
  ///   }
  /// ```
  ///
  /// the indentation of `{` should logically be the same as the indentation of
  /// `a` because it's the indentation of the `if`, even though the _line_ of a
  /// has a different indentation of the _line_ of `{`.
  int _spacesAtStartOfLogicalLineOf(Token token) {
    if (lineStarts.isEmpty) {
      // Coverage-ignore-block(suite): Not run.
      return -1;
    }

    // If the previous token is a `)`, e.g. if this is the start curly brace in
    // an if, we find the first token before the corresponding `(` (in this case
    // the if) in an attempt to find "the right" token to get the indentation
    // for - e.g. if the if is spread over several lines the given token itself
    // will - if formatted by the formatter - be indented more than the "if".
    if (token.isA(TokenType.OPEN_CURLY_BRACKET)) {
      if (token.previous == null) {
        // Coverage-ignore-block(suite): Not run.
        return -1;
      }
      Token previous = token.previous!;
      bool foundWanted = false;
      if (previous.isA(TokenType.CLOSE_PAREN)) {
        Token closeParen = token.previous!;
        Token? candidate = closeParen.previous;
        while (candidate != null) {
          if (candidate.endGroup == closeParen) break;
          if (candidate.isEof) break;
          if (candidate.endGroup != null) {
            if (candidate.endGroup!.offset > closeParen.offset) break;
          }
          candidate = candidate.previous;
        }
        if (candidate?.endGroup == closeParen && candidate!.previous != null) {
          token = candidate.previous!;
          if (token.isA(Keyword.IF) ||
              token.isA(Keyword.FOR) ||
              token.isA(Keyword.WHILE) ||
              token.isA(Keyword.SWITCH) ||
              token.isA(Keyword.CATCH)) {
            foundWanted = true;
          }
        }
      } else if (previous.isA(Keyword.ELSE) ||
          previous.isA(Keyword.TRY) ||
          previous.isA(Keyword.FINALLY)) {
        foundWanted = true;
      } else if (previous.isA(TokenType.EQ) &&
          (previous.previous?.isA(TokenType.IDENTIFIER) ?? false)) {
        // `someIdentifier = {`
        foundWanted = true;
      } else if (previous.isA(Keyword.CONST) &&
          (previous.previous?.isA(TokenType.EQ) ?? false) &&
          (previous.previous?.previous?.isA(TokenType.IDENTIFIER) ?? false)) {
        // `someIdentifier = const {`
        foundWanted = true;
      }
      if (!foundWanted) return -1;
    }

    // Now find the line of [token].
    final int lineIndex = _getLineOf(token);
    if (lineIndex == 0) {
      // Coverage-ignore-block(suite): Not run.
      // On first line.
      return tokens.next?.charOffset ?? -1;
    }

    // Find the first token of the line.
    int lineStartOfToken = lineStarts[lineIndex];
    Token? candidate = token.previous;
    while (candidate != null && candidate.offset >= lineStartOfToken) {
      candidate = candidate.previous;
    }
    if (candidate != null) {
      // candidate.next is the first token of the line.
      return candidate.next!.offset - lineStartOfToken;
    }

    // Coverage-ignore(suite): Not run.
    return -1;
  }

  /// If there was a single missing `}` when tokenizing, try to find the actual
  /// `{` that is missing the `}`.
  ///
  /// This is done by checking all `{` tokens between the one (currently)
  /// missing a `}` and the end of the token stream. For each we try to identify
  /// the indentation of the `{` and the indentation of the endGroup (i.e. the
  /// `}` it has been matched with). If the indentations mismatch we assume this
  /// is a bad match. There might be more bad matches because of how the curly
  /// braces are nested and we pick the last one, which should be the inner-most
  /// one and thus the one introducing the error: That is going to be the one
  /// that has "misaligned" the rest of the end-braces.
  int? getOffsetForCurlyBracketRecoveryStart() {
    if (openBraceWithMissingEndForPossibleRecovery == null) return null;
    Token? next = openBraceWithMissingEndForPossibleRecovery!.next;
    Token? lastMismatch;
    while (next != null && !next.isEof) {
      if (next.isA(TokenType.OPEN_CURLY_BRACKET)) {
        if (_getLineOf(next) != _getLineOf(next.endGroup!)) {
          int indentOfNext = _spacesAtStartOfLogicalLineOf(next);
          if (indentOfNext >= 0 &&
              indentOfNext != _spacesAtStartOfLogicalLineOf(next.endGroup!)) {
            lastMismatch = next;
          }
        }
      }
      next = next.next;
    }
    if (lastMismatch != null) {
      return lastMismatch.offset;
    }
    return null;
  }

  void appendEofToken() {
    beginToken();
    discardOpenLt();
    if (!groupingStack.isEmpty &&
        groupingStack.head.isA(TokenType.OPEN_CURLY_BRACKET) &&
        groupingStack.tail!.isEmpty) {
      // We have a single `{` that's missing a `}`. Maybe the user is typing?
      openBraceWithMissingEndForPossibleRecovery = groupingStack.head;
    }
    while (!groupingStack.isEmpty) {
      unmatchedBeginGroup(groupingStack.head);
      groupingStack = groupingStack.tail!;
    }
    appendToken(new Token.eof(tokenStart, comments));
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
    BeginToken token = new BeginToken(type, tokenStart, comments);
    appendToken(token);

    // { [ ${ cannot appear inside a type parameters / arguments.
    if (type.kind != LT_TOKEN && type.kind != OPEN_PAREN_TOKEN) {
      discardOpenLt();
    }
    groupingStack = groupingStack.prepend(token);
  }

  /**
   * Appends a token that begins an end group, represented by [type].
   * It handles the group end tokens '}', ')' and ']'. The tokens '>',
   * '>>' and '>>>' are handled separately by [appendGt], [appendGtGt]
   * and [appendGtGtGt].
   */
  int appendEndGroup(TokenType type, int openKind) {
    assert(openKind != LT_TOKEN); // openKind is < for > and >>
    bool foundMatchingBrace = discardBeginGroupUntil(openKind);
    return appendEndGroupInternal(foundMatchingBrace, type, openKind);
  }

  /// Append the end group (parenthesis, bracket etc).
  /// If [foundMatchingBrace] is true the grouping stack (stack of parenthesis
  /// etc) is updated, otherwise it's left alone.
  /// In effect, if [foundMatchingBrace] is false this end token is basically
  /// ignored, i.e. not really seen as an end group.
  int appendEndGroupInternal(
    bool foundMatchingBrace,
    TokenType type,
    int openKind,
  ) {
    if (!foundMatchingBrace) {
      // No begin group. Leave the grouping stack alone and just continue.
      appendPrecedenceToken(type);
      return advance();
    }
    appendPrecedenceToken(type);
    Token close = tail;
    BeginToken begin = groupingStack.head;
    if (begin.kind != openKind) {
      assert(
        begin.kind == STRING_INTERPOLATION_TOKEN &&
            openKind == OPEN_CURLY_BRACKET_TOKEN,
      );
      // We're ending an interpolated expression.
      begin.endGroup = close;
      groupingStack = groupingStack.tail!;
      // Using "start-of-text" to signal that we're back in string
      // scanning mode.
      return $STX;
    }
    begin.endGroup = close;
    groupingStack = groupingStack.tail!;
    return advance();
  }

  /**
   * Appends a token for '>'.
   * This method does not issue unmatched errors, because > is also the
   * greater-than operator. It does not necessarily have to close a group.
   */
  void appendGt(TokenType type) {
    appendPrecedenceToken(type);
    if (groupingStack.isEmpty) return;
    if (groupingStack.head.kind == LT_TOKEN) {
      groupingStack.head.endGroup = tail;
      groupingStack = groupingStack.tail!;
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
    if (groupingStack.head.kind == LT_TOKEN) {
      // Don't assign endGroup: in "T<U<V>>", the '>>' token closes the outer
      // '<', the inner '<' is left without endGroup.
      groupingStack = groupingStack.tail!;
    }
    if (groupingStack.isEmpty) return;
    if (groupingStack.head.kind == LT_TOKEN) {
      groupingStack.head.endGroup = tail;
      groupingStack = groupingStack.tail!;
    }
  }

  /// Appends a token for '>>>'.
  ///
  /// This method does not issue unmatched errors, because >>> is also the
  /// triple shift operator. It does not necessarily have to close a group.
  void appendGtGtGt(TokenType type) {
    appendPrecedenceToken(type);
    if (groupingStack.isEmpty) return;

    // Don't assign endGroup: in "T<U<V<X>>>", the '>>>' token closes the
    // outer '<', all the inner '<' are left without endGroups.
    if (groupingStack.head.kind == LT_TOKEN) {
      groupingStack = groupingStack.tail!;
    }
    if (groupingStack.isEmpty) return;
    if (groupingStack.head.kind == LT_TOKEN) {
      groupingStack = groupingStack.tail!;
    }
    if (groupingStack.isEmpty) return;
    if (groupingStack.head.kind == LT_TOKEN) {
      groupingStack.head.endGroup = tail;
      groupingStack = groupingStack.tail!;
    }
  }

  /// Prepend [token] to the token stream.
  void prependErrorToken(ErrorToken token) {
    hasErrors = true;
    if (errorTail == tail) {
      appendToken(token);
      errorTail = tail;
    } else {
      token.next = errorTail.next;
      token.next!.previous = token;
      errorTail.next = token;
      token.previous = errorTail;
      errorTail = errorTail.next!;
    }
  }

  /**
   * Returns a new comment from the scan offset [start] to the current
   * [scanOffset] plus the [extraOffset]. For example, if the current
   * scanOffset is 10, then [appendSubstringToken(5, -1)] will append the
   * substring string [5,9).
   *
   * Note that [extraOffset] can only be used if the covered character(s) are
   * known to be ASCII.
   */
  CommentToken createCommentToken(
    TokenType type,
    int start,
    bool asciiOnly, [
    int extraOffset = 0,
  ]);

  /**
   * Returns a new dartdoc from the scan offset [start] to the current
   * [scanOffset] plus the [extraOffset]. For example, if the current
   * scanOffset is 10, then [appendSubstringToken(5, -1)] will append the
   * substring string [5,9).
   *
   * Note that [extraOffset] can only be used if the covered character(s) are
   * known to be ASCII.
   */
  DartDocToken createDartDocToken(
    TokenType type,
    int start,
    bool asciiOnly, [
    int extraOffset = 0,
  ]);

  /**
   * Returns a new language version token from the scan offset [start]
   * to the current [scanOffset] similar to createCommentToken.
   */
  LanguageVersionToken createLanguageVersionToken(
    int start,
    int major,
    int minor,
  );

  /**
   * If a begin group token matches [openKind],
   * then discard begin group tokens up to that match and return `true`,
   * otherwise return `false`.
   * This recovers nicely from situations like "{[}" and "{foo());}",
   * but not "foo(() {bar());});"
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
      groupingStack = groupingStack.tail!;
    } while (!groupingStack.isEmpty);

    recoveryCount++;

    // If the stack does not have any opener of the given type,
    // then return without discarding anything.
    // This recovers nicely from situations like "{foo());}".
    if (groupingStack.isEmpty) {
      groupingStack = originalStack;
      return false;
    }

    // We found a matching group somewhere in the stack, but generally don't
    // know if we should recover by inserting synthetic closers or
    // basically ignore the current token.
    // We're in a recovery setting so we're allowed to be 'relatively slow' ---
    // try both and see which is better (i.e. gives fewest rewrites later).
    // To not get exponential runtime we will not do this nested though.
    // E.g. we can recover "{[}" as "{[]}" (better) or (with . for ignored
    // tokens) "{[.".
    // Or we can recover "[(])]" as "[()].." or "[(.)]" (better).
    if (!inRecoveryOption) {
      TokenType type;
      switch (openKind) {
        case OPEN_SQUARE_BRACKET_TOKEN:
          type = TokenType.CLOSE_SQUARE_BRACKET;
          break;
        case OPEN_CURLY_BRACKET_TOKEN:
          type = TokenType.CLOSE_CURLY_BRACKET;
          break;
        case OPEN_PAREN_TOKEN:
          type = TokenType.CLOSE_PAREN;
          break;
        // Coverage-ignore(suite): Not run.
        default:
          throw new StateError("Unexpected openKind");
      }

      // Option #1: Insert synthetic closers.
      int option1Recoveries;
      {
        AbstractScanner option1 = createRecoveryOptionScanner();
        option1.insertSyntheticClosers(originalStack, groupingStack);
        option1Recoveries = option1.recoveryOptionTokenizer(
          option1.appendEndGroupInternal(
            /* foundMatchingBrace = */ true,
            type,
            openKind,
          ),
        );
        option1Recoveries += option1.groupingStack.slowLength();
      }

      // Option #2: ignore this token.
      int option2Recoveries;
      {
        AbstractScanner option2 = createRecoveryOptionScanner();
        option2.groupingStack = originalStack;
        option2Recoveries = option2.recoveryOptionTokenizer(
          option2.appendEndGroupInternal(
            /* foundMatchingBrace = */ false,
            type,
            openKind,
          ),
        );
        // We add 1 to make this option pay for ignoring this token.
        option2Recoveries += option2.groupingStack.slowLength() + 1;
      }

      // The option-runs might have set invalid endGroup pointers. Reset them.
      for (
        Link<BeginToken> link = originalStack;
        link.isNotEmpty;
        link = link.tail!
      ) {
        link.head.endToken = null;
      }

      if (option2Recoveries < option1Recoveries) {
        // Perform option #2 recovery.
        groupingStack = originalStack;
        return false;
      }
      // option #1 is the default, so fall though.
    }

    // Insert synthetic closers and report errors for any unbalanced openers.
    // This recovers nicely from situations like "{[}".
    insertSyntheticClosers(originalStack, groupingStack);
    return true;
  }

  void insertSyntheticClosers(
    Link<BeginToken> originalStack,
    Link<BeginToken> entryToUse,
  ) {
    // Insert synthetic closers and report errors for any unbalanced openers.
    // This recovers nicely from situations like "{[}".
    while (!identical(originalStack, entryToUse)) {
      // Don't report unmatched errors for <; it is also the less-than operator.
      if (entryToUse.head.kind != LT_TOKEN) {
        unmatchedBeginGroup(originalStack.head);
      }
      originalStack = originalStack.tail!;
    }
  }

  /**
   * This method is called to discard '<' from the "grouping" stack.
   *
   * [ClassMemberParser.skipExpression] relies on the fact that we do not
   * create groups for stuff like:
   * [:a = b < c, d = e > f:].
   *
   * In other words, this method is called when the scanner recognizes
   * something which cannot possibly be part of a type parameter/argument
   * list, like the '=' in the above example.
   */
  void discardOpenLt() {
    while (!groupingStack.isEmpty && groupingStack.head.kind == LT_TOKEN) {
      groupingStack = groupingStack.tail!;
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
      groupingStack = groupingStack.tail!;
      if (beginToken.kind == STRING_INTERPOLATION_TOKEN) break;
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
    appendToken(new SyntheticToken(type, tokenStart)..beforeSynthetic = tail);
    begin.endGroup = tail;
    prependErrorToken(new UnmatchedToken(begin));
    recoveryCount++;
  }

  /// Return true when at EOF.
  bool atEndOfFile();

  @override
  Token tokenize() {
    while (!atEndOfFile()) {
      int next = advance();

      // Scan the header looking for a language version
      if (next != $EOF) {
        Token oldTail = tail;
        next = bigHeaderSwitch(next);
        if (next != $EOF && tail.kind == SCRIPT_TOKEN) {
          oldTail = tail;
          next = bigHeaderSwitch(next);
        }
        while (next != $EOF && tail == oldTail) {
          next = bigHeaderSwitch(next);
        }
        next = next;
      }

      while (next != $EOF) {
        next = bigSwitch(next);
      }
      assert(atEndOfFile());
      appendEofToken();
    }

    // Always pretend that there's a line at the end of the file.
    lineStarts.add(stringOffset + 1);

    return firstToken();
  }

  /// Tokenize a (small) part of the data. Used for recovery "option testing".
  ///
  /// Returns the number of recoveries performed.
  int recoveryOptionTokenizer(int next) {
    int iterations = 0;
    while (!atEndOfFile()) {
      while (next != $EOF) {
        // TODO(jensj): Look at number of lines, tokens, parenthesis stack,
        // semi-colon etc, not just number of iterations.
        next = bigSwitch(next);
        iterations++;

        if (iterations > 100) {
          // Coverage-ignore-block(suite): Not run.
          return recoveryCount;
        }
      }
      assert(atEndOfFile());
    }
    return recoveryCount;
  }

  int bigHeaderSwitch(int next) {
    if (next != $SLASH) {
      return bigSwitch(next);
    }
    beginToken();
    if ($SLASH != peek()) {
      return tokenizeSlashOrComment(next);
    }
    return tokenizeLanguageVersionOrSingleLineComment(next);
  }

  /// Skip past spaces. Returns the latest character not consumed
  /// (i.e. the latest character that is not a space).
  int skipSpaces();

  int bigSwitch(int next) {
    beginToken();
    if (next == $SPACE || next == $TAB || next == $CR) {
      return skipSpaces();
    }
    if (next == $LF) {
      lineStarts.add(stringOffset + 1); // +1, the line starts after the $LF.
      return skipSpaces();
    }

    int nextLower = next | 0x20;

    if ($a <= nextLower && nextLower <= $z) {
      if ($r == next) {
        return tokenizeRawStringKeywordOrIdentifier(next);
      }
      return tokenizeKeywordOrIdentifier(next, /* allowDollar = */ true);
    }

    if (next == $CLOSE_PAREN) {
      return appendEndGroup(TokenType.CLOSE_PAREN, OPEN_PAREN_TOKEN);
    }

    if (next == $OPEN_PAREN) {
      appendBeginGroup(TokenType.OPEN_PAREN);
      return advance();
    }

    if (next == $SEMICOLON) {
      appendPrecedenceToken(TokenType.SEMICOLON);
      // Type parameters and arguments cannot contain semicolon.
      discardOpenLt();
      return advance();
    }

    if (next == $PERIOD) {
      return tokenizeDotsOrNumber(next);
    }

    if (next == $COMMA) {
      appendPrecedenceToken(TokenType.COMMA);
      return advance();
    }

    if (next == $EQ) {
      return tokenizeEquals(next);
    }

    if (next == $CLOSE_CURLY_BRACKET) {
      if (offsetForCurlyBracketRecoveryStart != null &&
          !groupingStack.isEmpty &&
          groupingStack.head.isA(TokenType.OPEN_CURLY_BRACKET) &&
          groupingStack.head.offset == offsetForCurlyBracketRecoveryStart) {
        // This instance of the scanner was instructed to recover this
        // opening curly bracket.
        unmatchedBeginGroup(groupingStack.head);
        groupingStack = groupingStack.tail!;
      }
      return appendEndGroup(
        TokenType.CLOSE_CURLY_BRACKET,
        OPEN_CURLY_BRACKET_TOKEN,
      );
    }

    if (next == $SLASH) {
      return tokenizeSlashOrComment(next);
    }

    if (next == $OPEN_CURLY_BRACKET) {
      appendBeginGroup(TokenType.OPEN_CURLY_BRACKET);
      return advance();
    }

    if (next == $DQ || next == $SQ) {
      return tokenizeString(next, scanOffset, /* raw = */ false);
    }

    if (next == $_) {
      return tokenizeKeywordOrIdentifier(next, /* allowDollar = */ true);
    }

    if (next == $COLON) {
      appendPrecedenceToken(TokenType.COLON);
      return advance();
    }

    if (next == $LT) {
      return tokenizeLessThan(next);
    }

    if (next == $GT) {
      return tokenizeGreaterThan(next);
    }

    if (next == $BANG) {
      return tokenizeExclamation(next);
    }

    if (next == $OPEN_SQUARE_BRACKET) {
      return tokenizeOpenSquareBracket(next);
    }

    if (next == $CLOSE_SQUARE_BRACKET) {
      return appendEndGroup(
        TokenType.CLOSE_SQUARE_BRACKET,
        OPEN_SQUARE_BRACKET_TOKEN,
      );
    }

    if (next == $AT) {
      return tokenizeAt(next);
    }

    if (next >= $1 && next <= $9) {
      return tokenizeNumber(next);
    }

    if (next == $AMPERSAND) {
      return tokenizeAmpersand(next);
    }

    if (next == $0) {
      return tokenizeHexOrNumber(next);
    }

    if (next == $QUESTION) {
      return tokenizeQuestion(next);
    }

    if (next == $BAR) {
      return tokenizeBar(next);
    }

    if (next == $PLUS) {
      return tokenizePlus(next);
    }

    if (next == $$) {
      return tokenizeKeywordOrIdentifier(next, /* allowDollar = */ true);
    }

    if (next == $MINUS) {
      return tokenizeMinus(next);
    }

    if (next == $STAR) {
      return tokenizeMultiply(next);
    }

    if (next == $CARET) {
      return tokenizeCaret(next);
    }

    if (next == $TILDE) {
      return tokenizeTilde(next);
    }

    if (next == $PERCENT) {
      return tokenizePercent(next);
    }

    if (next == $BACKPING) {
      // Coverage-ignore-block(suite): Not run.
      // Hit when parsing doc comments in the analyzer.
      appendPrecedenceToken(TokenType.BACKPING);
      return advance();
    }

    if (next == $BACKSLASH) {
      // Hit when parsing doc comments in the analyzer.
      appendPrecedenceToken(TokenType.BACKSLASH);
      return advance();
    }

    if (next == $HASH) {
      return tokenizeTag(next);
    }

    if (next < 0x1f) {
      return unexpected(next);
    }

    next = currentAsUnicode(next);

    return unexpected(next);
  }

  int tokenizeTag(int next) {
    // # or #!.*[\n\r]
    if (scanOffset == 0) {
      if (peek() == $BANG) {
        int start = scanOffset;
        bool asciiOnly = true;
        do {
          next = advance();
          if (next > 127) asciiOnly = false;
        } while (next != $LF && next != $CR && next != $EOF);
        if (!asciiOnly) {
          handleUnicode(start);
        }
        appendSubstringToken(TokenType.SCRIPT_TAG, start, asciiOnly);
        return next;
      }
    }
    appendPrecedenceToken(TokenType.HASH);
    return advance();
  }

  int tokenizeTilde(int next) {
    // ~ ~/ ~/=
    next = advance();
    if (next == $SLASH) {
      return select($EQ, TokenType.TILDE_SLASH_EQ, TokenType.TILDE_SLASH);
    } else {
      appendPrecedenceToken(TokenType.TILDE);
      return next;
    }
  }

  int tokenizeOpenSquareBracket(int next) {
    // [ [] []=
    next = advance();
    if (next == $CLOSE_SQUARE_BRACKET) {
      return select($EQ, TokenType.INDEX_EQ, TokenType.INDEX);
    }
    appendBeginGroup(TokenType.OPEN_SQUARE_BRACKET);
    return next;
  }

  int tokenizeCaret(int next) {
    // ^ ^=
    return select($EQ, TokenType.CARET_EQ, TokenType.CARET);
  }

  int tokenizeQuestion(int next) {
    // ? ?. ?.. ?? ??=
    next = advance();
    if (next == $QUESTION) {
      return select(
        $EQ,
        TokenType.QUESTION_QUESTION_EQ,
        TokenType.QUESTION_QUESTION,
      );
    } else if (next == $PERIOD) {
      next = advance();
      if ($PERIOD == next) {
        appendPrecedenceToken(TokenType.QUESTION_PERIOD_PERIOD);
        return advance();
      }
      appendPrecedenceToken(TokenType.QUESTION_PERIOD);
      return next;
    } else {
      appendPrecedenceToken(TokenType.QUESTION);
      return next;
    }
  }

  int tokenizeBar(int next) {
    // | || |= ||=
    next = advance();
    if (next == $BAR) {
      next = advance();
      // Coverage-ignore(suite): Not run.
      if (LAZY_ASSIGNMENT_ENABLED && next == $EQ) {
        appendPrecedenceToken(TokenType.BAR_BAR_EQ);
        return advance();
      }
      appendPrecedenceToken(TokenType.BAR_BAR);
      return next;
    } else if (next == $EQ) {
      appendPrecedenceToken(TokenType.BAR_EQ);
      return advance();
    } else {
      appendPrecedenceToken(TokenType.BAR);
      return next;
    }
  }

  int tokenizeAmpersand(int next) {
    // && &= & &&=
    next = advance();
    if (next == $AMPERSAND) {
      next = advance();
      // Coverage-ignore(suite): Not run.
      if (LAZY_ASSIGNMENT_ENABLED && next == $EQ) {
        appendPrecedenceToken(TokenType.AMPERSAND_AMPERSAND_EQ);
        return advance();
      }
      appendPrecedenceToken(TokenType.AMPERSAND_AMPERSAND);
      return next;
    } else if (next == $EQ) {
      appendPrecedenceToken(TokenType.AMPERSAND_EQ);
      return advance();
    } else {
      appendPrecedenceToken(TokenType.AMPERSAND);
      return next;
    }
  }

  int tokenizePercent(int next) {
    // % %=
    return select($EQ, TokenType.PERCENT_EQ, TokenType.PERCENT);
  }

  int tokenizeMultiply(int next) {
    // * *=
    return select($EQ, TokenType.STAR_EQ, TokenType.STAR);
  }

  int tokenizeMinus(int next) {
    // - -- -=
    next = advance();
    if (next == $MINUS) {
      appendPrecedenceToken(TokenType.MINUS_MINUS);
      return advance();
    } else if (next == $EQ) {
      appendPrecedenceToken(TokenType.MINUS_EQ);
      return advance();
    } else {
      appendPrecedenceToken(TokenType.MINUS);
      return next;
    }
  }

  int tokenizePlus(int next) {
    // + ++ +=
    next = advance();
    if ($PLUS == next) {
      appendPrecedenceToken(TokenType.PLUS_PLUS);
      return advance();
    } else if ($EQ == next) {
      appendPrecedenceToken(TokenType.PLUS_EQ);
      return advance();
    } else {
      appendPrecedenceToken(TokenType.PLUS);
      return next;
    }
  }

  int tokenizeExclamation(int next) {
    // ! !=
    // !== is kept for user-friendly error reporting.

    next = advance();
    if (next == $EQ) {
      //was `return select($EQ, TokenType.BANG_EQ_EQ, TokenType.BANG_EQ);`
      int next = advance();
      if (next == $EQ) {
        appendPrecedenceToken(TokenType.BANG_EQ_EQ);
        prependErrorToken(new UnsupportedOperator(tail, tokenStart));
        return advance();
      } else {
        appendPrecedenceToken(TokenType.BANG_EQ);
        return next;
      }
    }
    appendPrecedenceToken(TokenType.BANG);
    return next;
  }

  int tokenizeEquals(int next) {
    // = == =>
    // === is kept for user-friendly error reporting.

    // Type parameters and arguments cannot contain any token that
    // starts with '='.
    discardOpenLt();

    next = advance();
    if (next == $EQ) {
      // was `return select($EQ, TokenType.EQ_EQ_EQ, TokenType.EQ_EQ);`
      int next = advance();
      if (next == $EQ) {
        appendPrecedenceToken(TokenType.EQ_EQ_EQ);
        prependErrorToken(new UnsupportedOperator(tail, tokenStart));
        return advance();
      } else {
        appendPrecedenceToken(TokenType.EQ_EQ);
        return next;
      }
    } else if (next == $GT) {
      appendPrecedenceToken(TokenType.FUNCTION);
      return advance();
    }
    appendPrecedenceToken(TokenType.EQ);
    return next;
  }

  int tokenizeGreaterThan(int next) {
    // > >= >> >>= >>> >>>=
    next = advance();
    if ($EQ == next) {
      // Saw `>=` only.
      appendPrecedenceToken(TokenType.GT_EQ);
      return advance();
    } else if ($GT == next) {
      // Saw `>>` so far.
      next = advance();
      if ($EQ == next) {
        // Saw `>>=` only.
        appendPrecedenceToken(TokenType.GT_GT_EQ);
        return advance();
      } else if (_enableTripleShift && $GT == next) {
        // Saw `>>>` so far.
        next = advance();
        if ($EQ == next) {
          // Saw `>>>=` only.
          appendPrecedenceToken(TokenType.GT_GT_GT_EQ);
          return advance();
        } else {
          // Saw `>>>` only.
          appendGtGtGt(TokenType.GT_GT_GT);
          return next;
        }
      } else {
        // Saw `>>` only.
        appendGtGt(TokenType.GT_GT);
        return next;
      }
    } else {
      // Saw `>` only.
      appendGt(TokenType.GT);
      return next;
    }
  }

  int tokenizeLessThan(int next) {
    // < <= << <<=
    next = advance();
    if ($EQ == next) {
      appendPrecedenceToken(TokenType.LT_EQ);
      return advance();
    } else if ($LT == next) {
      return select($EQ, TokenType.LT_LT_EQ, TokenType.LT_LT);
    } else {
      appendBeginGroup(TokenType.LT);
      return next;
    }
  }

  int tokenizeNumber(int next) {
    int start = scanOffset;
    bool hasSeparators = false;
    bool previousWasSeparator = false;
    while (true) {
      next = advance();
      if ($0 <= next && next <= $9) {
        previousWasSeparator = false;
        continue;
      } else if (next == $_) {
        hasSeparators = true;
        previousWasSeparator = true;
        continue;
      } else if (next == $e || next == $E) {
        if (previousWasSeparator) {
          // Not allowed.
          prependErrorToken(
            new UnterminatedToken(
              codeUnexpectedSeparatorInNumber,
              start,
              stringOffset,
            ),
          );
        }
        return tokenizeFractionPart(next, start, hasSeparators);
      } else {
        if (next == $PERIOD) {
          if (previousWasSeparator) {
            // Not allowed.
            prependErrorToken(
              new UnterminatedToken(
                codeUnexpectedSeparatorInNumber,
                start,
                stringOffset,
              ),
            );
          }
          int nextnext = peek();
          if ($0 <= nextnext && nextnext <= $9) {
            // Use the peeked character.
            advance();
            return tokenizeFractionPart(nextnext, start, hasSeparators);
          } else {
            TokenType tokenType = hasSeparators
                ? TokenType.INT_WITH_SEPARATORS
                : TokenType.INT;
            appendSubstringToken(tokenType, start, /* asciiOnly = */ true);
            return next;
          }
        }
        if (previousWasSeparator) {
          // End of the number is a separator; not allowed.
          prependErrorToken(
            new UnterminatedToken(
              codeUnexpectedSeparatorInNumber,
              start,
              stringOffset,
            ),
          );
        }
        TokenType tokenType = hasSeparators
            ? TokenType.INT_WITH_SEPARATORS
            : TokenType.INT;
        appendSubstringToken(tokenType, start, /* asciiOnly = */ true);
        return next;
      }
    }
  }

  int tokenizeHexOrNumber(int next) {
    int x = peek();
    if (x == $x || x == $X) {
      return tokenizeHex(next);
    }
    return tokenizeNumber(next);
  }

  int tokenizeHex(int next) {
    int start = scanOffset;
    next = advance(); // Advance past the $x or $X.
    bool hasDigits = false;
    bool hasSeparators = false;
    bool previousWasSeparator = false;
    while (true) {
      next = advance();
      if (($0 <= next && next <= $9) ||
          ($A <= next && next <= $F) ||
          ($a <= next && next <= $f)) {
        hasDigits = true;
        previousWasSeparator = false;
      } else if (next == $_) {
        if (!hasDigits) {
          // Not allowed.
          prependErrorToken(
            new UnterminatedToken(
              codeUnexpectedSeparatorInNumber,
              start,
              stringOffset,
            ),
          );
        }
        hasSeparators = true;
        previousWasSeparator = true;
      } else {
        if (!hasDigits) {
          prependErrorToken(
            new UnterminatedToken(codeExpectedHexDigit, start, stringOffset),
          );
          // Recovery
          appendSyntheticSubstringToken(
            TokenType.HEXADECIMAL,
            start,
            /* asciiOnly = */ true,
            "0",
          );
          return next;
        }
        if (previousWasSeparator) {
          // End of the number is a separator; not allowed.
          prependErrorToken(
            new UnterminatedToken(
              codeUnexpectedSeparatorInNumber,
              start,
              stringOffset,
            ),
          );
        }
        TokenType tokenType = hasSeparators
            ? TokenType.HEXADECIMAL_WITH_SEPARATORS
            : TokenType.HEXADECIMAL;
        appendSubstringToken(tokenType, start, /* asciiOnly = */ true);
        return next;
      }
    }
  }

  int tokenizeDotsOrNumber(int next) {
    int start = scanOffset;
    next = advance();
    if (($0 <= next && next <= $9)) {
      return tokenizeFractionPart(next, start, /* hasSeparators = */ false);
    } else if ($PERIOD == next) {
      next = advance();
      if (next == $PERIOD) {
        next = advance();
        if (next == $QUESTION) {
          appendPrecedenceToken(TokenType.PERIOD_PERIOD_PERIOD_QUESTION);
          return advance();
        } else {
          appendPrecedenceToken(TokenType.PERIOD_PERIOD_PERIOD);
          return next;
        }
      } else {
        appendPrecedenceToken(TokenType.PERIOD_PERIOD);
        return next;
      }
    } else {
      appendPrecedenceToken(TokenType.PERIOD);
      return next;
    }
  }

  /// [next] has to be in [0-9eE].
  int tokenizeFractionPart(int next, int start, bool hasSeparators) {
    assert(($0 <= next && next <= $9) || ($e == next || $E == next));
    bool done = false;
    bool previousWasSeparator = false;
    LOOP:
    while (!done) {
      if ($0 <= next && next <= $9) {
        previousWasSeparator = false;
      } else if ($_ == next) {
        hasSeparators = true;
        previousWasSeparator = true;
      } else if ($e == next || $E == next) {
        if (previousWasSeparator) {
          // Not allowed.
          prependErrorToken(
            new UnterminatedToken(
              codeUnexpectedSeparatorInNumber,
              start,
              stringOffset,
            ),
          );
        }
        previousWasSeparator = false;
        next = advance();
        while (next == $_) {
          prependErrorToken(
            new UnterminatedToken(
              codeUnexpectedSeparatorInNumber,
              start,
              stringOffset,
            ),
          );
          hasSeparators = true;
          previousWasSeparator = true;
          next = advance();
        }
        if (next == $PLUS || next == $MINUS) {
          previousWasSeparator = false;
          next = advance();
        }
        bool hasExponentDigits = false;
        while (true) {
          if ($0 <= next && next <= $9) {
            hasExponentDigits = true;
            previousWasSeparator = false;
          } else if (next == $_) {
            if (!hasExponentDigits) {
              prependErrorToken(
                new UnterminatedToken(
                  codeUnexpectedSeparatorInNumber,
                  start,
                  stringOffset,
                ),
              );
            }
            hasSeparators = true;
            previousWasSeparator = true;
          } else {
            if (!hasExponentDigits) {
              appendSyntheticSubstringToken(
                hasSeparators
                    ? TokenType.DOUBLE_WITH_SEPARATORS
                    : TokenType.DOUBLE,
                start,
                /* asciiOnly = */ true,
                '0',
              );
              prependErrorToken(
                new UnterminatedToken(
                  codeMissingExponent,
                  tokenStart,
                  stringOffset,
                ),
              );
              return next;
            }
            break;
          }
          next = advance();
        }
        if (previousWasSeparator) {
          // End of the number is a separator; not allowed.
          prependErrorToken(
            new UnterminatedToken(
              codeUnexpectedSeparatorInNumber,
              start,
              stringOffset,
            ),
          );
        }

        done = true;
        continue LOOP;
      } else {
        if (previousWasSeparator) {
          // End of the number is a separator; not allowed.
          prependErrorToken(
            new UnterminatedToken(
              codeUnexpectedSeparatorInNumber,
              start,
              stringOffset,
            ),
          );
        }
        done = true;
        continue LOOP;
      }
      next = advance();
    }
    TokenType tokenType = hasSeparators
        ? TokenType.DOUBLE_WITH_SEPARATORS
        : TokenType.DOUBLE;
    appendSubstringToken(tokenType, start, /* asciiOnly = */ true);
    return next;
  }

  int tokenizeSlashOrComment(int next) {
    int start = scanOffset;
    next = advance();
    if ($STAR == next) {
      return tokenizeMultiLineComment(next, start);
    } else if ($SLASH == next) {
      return tokenizeSingleLineComment(next, start);
    } else if ($EQ == next) {
      appendPrecedenceToken(TokenType.SLASH_EQ);
      return advance();
    } else {
      appendPrecedenceToken(TokenType.SLASH);
      return next;
    }
  }

  int tokenizeLanguageVersionOrSingleLineComment(int next) {
    assert(next == $SLASH);
    int start = scanOffset;
    next = advance();
    assert(next == $SLASH);

    // Dart doc
    if ($SLASH == peek()) {
      return tokenizeSingleLineComment(next, start);
    }

    // "@dart"
    next = advance();
    while ($SPACE == next) {
      next = advance();
    }
    if ($AT != next) {
      return tokenizeSingleLineCommentRest(next, start, /* dartdoc = */ false);
    }
    next = advance();
    if ($d != next) {
      return tokenizeSingleLineCommentRest(next, start, /* dartdoc = */ false);
    }
    next = advance();
    if ($a != next) {
      return tokenizeSingleLineCommentRest(next, start, /* dartdoc = */ false);
    }
    next = advance();
    if ($r != next) {
      return tokenizeSingleLineCommentRest(next, start, /* dartdoc = */ false);
    }
    next = advance();
    if ($t != next) {
      return tokenizeSingleLineCommentRest(next, start, /* dartdoc = */ false);
    }
    next = advance();

    // "="
    while ($SPACE == next) {
      next = advance();
    }
    if ($EQ != next) {
      return tokenizeSingleLineCommentRest(next, start, /* dartdoc = */ false);
    }
    next = advance();

    // major
    while ($SPACE == next) {
      next = advance();
    }
    int major = 0;
    int majorStart = scanOffset;
    while (isDigit(next)) {
      major = major * 10 + next - $0;
      next = advance();
    }
    if (scanOffset == majorStart) {
      return tokenizeSingleLineCommentRest(next, start, /* dartdoc = */ false);
    }

    // minor
    if ($PERIOD != next) {
      return tokenizeSingleLineCommentRest(next, start, /* dartdoc = */ false);
    }
    next = advance();
    int minor = 0;
    int minorStart = scanOffset;
    while (isDigit(next)) {
      minor = minor * 10 + next - $0;
      next = advance();
    }
    if (scanOffset == minorStart) {
      return tokenizeSingleLineCommentRest(next, start, /* dartdoc = */ false);
    }

    // trailing spaces
    while ($SPACE == next) {
      next = advance();
    }
    if (next != $LF && next != $CR && next != $EOF) {
      return tokenizeSingleLineCommentRest(next, start, /* dartdoc = */ false);
    }

    LanguageVersionToken languageVersion = createLanguageVersionToken(
      start,
      major,
      minor,
    );
    if (languageVersionChanged != null) {
      // TODO(danrubel): make this required and remove the languageVersion field
      languageVersionChanged!(this, languageVersion);
    }
    if (includeComments) {
      _appendToCommentStream(languageVersion);
    }
    return next;
  }

  int tokenizeSingleLineComment(int next, int start) {
    next = advance();
    bool dartdoc = $SLASH == next;
    return tokenizeSingleLineCommentRest(next, start, dartdoc);
  }

  /// Scan until line end (or eof). Returns true if the skipped data is ascii
  /// only and false otherwise. To get the end-of-line (or eof) character call
  /// [current].
  bool scanUntilLineEnd();

  /// Get the current character, i.e. the latest response from [advance].
  int current();

  int tokenizeSingleLineCommentRest(int next, int start, bool dartdoc) {
    bool asciiOnly = true;
    if (next > 127) asciiOnly = false;
    if ($LF == next || $CR == next || $EOF == next) {
      _tokenizeSingleLineCommentAppend(asciiOnly, start, dartdoc);
      return next;
    }
    asciiOnly &= scanUntilLineEnd();
    _tokenizeSingleLineCommentAppend(asciiOnly, start, dartdoc);
    return current();
  }

  void _tokenizeSingleLineCommentAppend(
    bool asciiOnly,
    int start,
    bool dartdoc,
  ) {
    if (!asciiOnly) handleUnicode(start);
    if (dartdoc) {
      appendDartDoc(start, TokenType.SINGLE_LINE_COMMENT, asciiOnly);
    } else {
      appendComment(start, TokenType.SINGLE_LINE_COMMENT, asciiOnly);
    }
  }

  int tokenizeMultiLineComment(int next, int start) {
    bool asciiOnlyComment = true; // Track if the entire comment is ASCII.
    bool asciiOnlyLines = true; // Track ASCII since the last handleUnicode.
    int unicodeStart = start;
    int nesting = 1;
    next = advance();
    bool dartdoc = $STAR == next;
    while (true) {
      if ($EOF == next) {
        if (!asciiOnlyLines) {
          handleUnicode(unicodeStart);
        }
        prependErrorToken(
          new UnterminatedToken(
            codeUnterminatedComment,
            tokenStart,
            stringOffset,
          ),
        );
        advanceAfterError();
        break;
      } else if ($STAR == next) {
        next = advance();
        if ($SLASH == next) {
          --nesting;
          if (0 == nesting) {
            if (!asciiOnlyLines) handleUnicode(unicodeStart);
            next = advance();
            if (dartdoc) {
              appendDartDoc(
                start,
                TokenType.MULTI_LINE_COMMENT,
                asciiOnlyComment,
              );
            } else {
              appendComment(
                start,
                TokenType.MULTI_LINE_COMMENT,
                asciiOnlyComment,
              );
            }
            break;
          } else {
            next = advance();
          }
        }
      } else if ($SLASH == next) {
        next = advance();
        if ($STAR == next) {
          next = advance();
          ++nesting;
        }
      } else if (next == $LF) {
        if (!asciiOnlyLines) {
          // Synchronize the string offset in the utf8 scanner.
          handleUnicode(unicodeStart);
          asciiOnlyLines = true;
          unicodeStart = scanOffset;
        }
        lineFeedInMultiline();
        next = advance();
      } else {
        if (next > 127) {
          asciiOnlyLines = false;
          asciiOnlyComment = false;
        }
        next = advance();
      }
    }
    return next;
  }

  void appendComment(int start, TokenType type, bool asciiOnly) {
    if (!includeComments) return;
    CommentToken newComment = createCommentToken(type, start, asciiOnly);
    _appendToCommentStream(newComment);
  }

  void appendDartDoc(int start, TokenType type, bool asciiOnly) {
    if (!includeComments) return;
    CommentToken newComment = createDartDocToken(type, start, asciiOnly);
    _appendToCommentStream(newComment);
  }

  /**
   * Append the given token to the [tail] of the current stream of tokens.
   */
  void appendToken(Token token) {
    tail.next = token;
    token.previous = tail;
    tail = token;
    if (comments != null && comments == token.precedingComments) {
      comments = null;
      commentsTail = null;
    } else {
      // It is the responsibility of the caller to construct the token
      // being appended with preceding comments if any
      assert(comments == null || token.isSynthetic || token is ErrorToken);
    }
  }

  void _appendToCommentStream(CommentToken newComment) {
    if (comments == null) {
      comments = newComment;
      commentsTail = comments;
    } else {
      commentsTail!.next = newComment;
      commentsTail!.next!.previous = commentsTail;
      commentsTail = commentsTail!.next;
    }
  }

  int tokenizeRawStringKeywordOrIdentifier(int next) {
    // [next] is $r.
    int nextnext = peek();
    if (nextnext == $DQ || nextnext == $SQ) {
      int start = scanOffset;
      next = advance();
      return tokenizeString(next, start, /* raw = */ true);
    }
    return tokenizeKeywordOrIdentifier(next, /* allowDollar = */ true);
  }

  int tokenizeKeywordOrIdentifier(int next, bool allowDollar) {
    KeywordState state = KeywordStateHelper.table;
    int start = scanOffset;
    // We allow a leading capital character.
    if ($A <= next && next <= $z) {
      state = state.next(next);
      next = advance();
    }
    while (!state.isNull && $a <= next && next <= $z) {
      state = state.next(next);
      next = advance();
    }
    if (state.isNull) {
      return tokenizeIdentifier(next, start, allowDollar);
    }
    Keyword? keyword = state.keyword;
    if (keyword == null) {
      return tokenizeIdentifier(next, start, allowDollar);
    }
    if (!_forAugmentationLibrary && keyword == Keyword.AUGMENT) {
      return tokenizeIdentifier(next, start, allowDollar);
    }
    if (($A <= next && next <= $Z) ||
        ($0 <= next && next <= $9) ||
        next == $_ ||
        (allowDollar && next == $$)) {
      return tokenizeIdentifier(next, start, allowDollar);
    } else {
      appendKeywordToken(keyword);
      return next;
    }
  }

  int passIdentifierCharAllowDollar();

  /**
   * [allowDollar] can exclude '$', which is not allowed as part of a string
   * interpolation identifier.
   */
  int tokenizeIdentifier(int next, int start, bool allowDollar) {
    if (allowDollar) {
      // Normal case is to allow dollar.
      if (isIdentifierChar(next, /* allowDollar = */ true)) {
        next = passIdentifierCharAllowDollar();
        appendSubstringToken(
          TokenType.IDENTIFIER,
          start,
          /* asciiOnly = */ true,
        );
      } else {
        // Identifier ends here.
        if (start == scanOffset) {
          return unexpected(next);
        } else {
          appendSubstringToken(
            TokenType.IDENTIFIER,
            start,
            /* asciiOnly = */ true,
          );
        }
      }
    } else {
      while (true) {
        if (isIdentifierChar(next, /* allowDollar = */ false)) {
          next = advance();
        } else {
          // Identifier ends here.
          if (start == scanOffset) {
            return unexpected(next);
          } else {
            appendSubstringToken(
              TokenType.IDENTIFIER,
              start,
              /* asciiOnly = */ true,
            );
          }
          break;
        }
      }
    }
    return next;
  }

  int tokenizeAt(int next) {
    appendPrecedenceToken(TokenType.AT);
    return advance();
  }

  int tokenizeString(int next, int start, bool raw) {
    int quoteChar = next;
    next = advance();
    if (quoteChar == next) {
      next = advance();
      if (quoteChar == next) {
        // Multiline string.
        return tokenizeMultiLineString(quoteChar, start, raw);
      } else {
        // Empty string.
        appendSubstringToken(TokenType.STRING, start, /* asciiOnly = */ true);
        return next;
      }
    }
    if (raw) {
      return tokenizeSingleLineRawString(next, quoteChar, start);
    } else {
      return tokenizeSingleLineString(next, quoteChar, start);
    }
  }

  /**
   * [next] is the first character after the quote.
   * [quoteStart] is the scanOffset of the quote.
   *
   * The token contains a substring of the source file, including the
   * string quotes, backslashes for escaping. For interpolated strings,
   * the parts before and after are separate tokens.
   *
   *   "a $b c"
   *
   * gives StringToken("a $), StringToken(b) and StringToken( c").
   */
  int tokenizeSingleLineString(int next, int quoteChar, int quoteStart) {
    int start = quoteStart;
    bool asciiOnly = true;
    while (next != quoteChar) {
      if (next == $BACKSLASH) {
        next = advance();
      } else if (next == $$) {
        if (!asciiOnly) {
          handleUnicode(start);
        }
        next = tokenizeStringInterpolation(start, asciiOnly);
        start = scanOffset;
        asciiOnly = true;
        continue;
      }
      if (next <= $CR && (next == $LF || next == $CR || next == $EOF)) {
        if (!asciiOnly) {
          handleUnicode(start);
        }
        unterminatedString(
          quoteChar,
          quoteStart,
          start,
          asciiOnly: asciiOnly,
          isMultiLine: false,
          isRaw: false,
        );
        return next;
      }
      if (next > 127) asciiOnly = false;
      next = advance();
    }
    if (!asciiOnly) handleUnicode(start);
    // Advance past the quote character.
    next = advance();
    appendSubstringToken(TokenType.STRING, start, asciiOnly);
    return next;
  }

  int tokenizeStringInterpolation(int start, bool asciiOnly) {
    appendSubstringToken(TokenType.STRING, start, asciiOnly);
    beginToken(); // $ starts here.
    int next = advance();
    if (next == $OPEN_CURLY_BRACKET) {
      return tokenizeInterpolatedExpression(next);
    } else {
      return tokenizeInterpolatedIdentifier(next);
    }
  }

  int tokenizeInterpolatedExpression(int next) {
    appendBeginGroup(TokenType.STRING_INTERPOLATION_EXPRESSION);
    beginToken(); // The expression starts here.
    next = advance(); // Move past the curly bracket.
    while (next != $EOF && next != $STX) {
      next = bigSwitch(next);
    }
    if (next == $EOF) {
      beginToken();
      discardInterpolation();
      return next;
    }
    next = advance(); // Move past the $STX.
    beginToken(); // The string interpolation suffix starts here.
    return next;
  }

  int tokenizeInterpolatedIdentifier(int next) {
    appendPrecedenceToken(TokenType.STRING_INTERPOLATION_IDENTIFIER);

    if ($a <= next && next <= $z || $A <= next && next <= $Z || next == $_) {
      beginToken(); // The identifier starts here.
      next = tokenizeKeywordOrIdentifier(next, /* allowDollar = */ false);
    } else {
      beginToken(); // The synthetic identifier starts here.
      appendSyntheticSubstringToken(
        TokenType.IDENTIFIER,
        scanOffset,
        /* asciiOnly = */ true,
        '',
      );
      prependErrorToken(
        new UnterminatedToken(
          codeUnexpectedDollarInString,
          tokenStart,
          stringOffset,
        ),
      );
    }
    beginToken(); // The string interpolation suffix starts here.
    return next;
  }

  int tokenizeSingleLineRawString(int next, int quoteChar, int quoteStart) {
    bool asciiOnly = true;
    while (next != $EOF) {
      if (next == quoteChar) {
        if (!asciiOnly) {
          handleUnicode(quoteStart);
        }
        next = advance();
        appendSubstringToken(TokenType.STRING, quoteStart, asciiOnly);
        return next;
      } else if (next == $LF || next == $CR) {
        if (!asciiOnly) {
          handleUnicode(quoteStart);
        }
        unterminatedString(
          quoteChar,
          quoteStart,
          quoteStart,
          asciiOnly: asciiOnly,
          isMultiLine: false,
          isRaw: true,
        );
        return next;
      } else if (next > 127) {
        asciiOnly = false;
      }
      next = advance();
    }
    if (!asciiOnly) {
      handleUnicode(quoteStart);
    }
    unterminatedString(
      quoteChar,
      quoteStart,
      quoteStart,
      asciiOnly: asciiOnly,
      isMultiLine: false,
      isRaw: true,
    );
    return next;
  }

  int tokenizeMultiLineRawString(int quoteChar, int quoteStart) {
    bool asciiOnlyString = true;
    bool asciiOnlyLine = true;
    int unicodeStart = quoteStart;
    int next = advance(); // Advance past the (last) quote (of three).
    outer:
    while (next != $EOF) {
      while (next != quoteChar) {
        if (next == $LF) {
          if (!asciiOnlyLine) {
            // Synchronize the string offset in the utf8 scanner.
            handleUnicode(unicodeStart);
            asciiOnlyLine = true;
            unicodeStart = scanOffset;
          }
          lineFeedInMultiline();
        } else if (next > 127) {
          asciiOnlyLine = false;
          asciiOnlyString = false;
        }
        next = advance();
        if (next == $EOF) break outer;
      }
      next = advance();
      if (next == quoteChar) {
        next = advance();
        if (next == quoteChar) {
          if (!asciiOnlyLine) {
            handleUnicode(unicodeStart);
          }
          next = advance();
          appendSubstringToken(TokenType.STRING, quoteStart, asciiOnlyString);
          return next;
        }
      }
    }
    if (!asciiOnlyLine) {
      handleUnicode(unicodeStart);
    }
    unterminatedString(
      quoteChar,
      quoteStart,
      quoteStart,
      asciiOnly: asciiOnlyLine,
      isMultiLine: true,
      isRaw: true,
    );
    return next;
  }

  int tokenizeMultiLineString(int quoteChar, int quoteStart, bool raw) {
    if (raw) {
      return tokenizeMultiLineRawString(quoteChar, quoteStart);
    }
    int start = quoteStart;
    bool asciiOnlyString = true;
    bool asciiOnlyLine = true;
    int unicodeStart = start;
    int next = advance(); // Advance past the (last) quote (of three).
    while (next != $EOF) {
      if (next == $$) {
        if (!asciiOnlyLine) {
          handleUnicode(unicodeStart);
        }
        next = tokenizeStringInterpolation(start, asciiOnlyString);
        start = scanOffset;
        unicodeStart = start;
        asciiOnlyString = true; // A new string token is created for the rest.
        asciiOnlyLine = true;
        continue;
      }
      if (next == quoteChar) {
        next = advance();
        if (next == quoteChar) {
          next = advance();
          if (next == quoteChar) {
            if (!asciiOnlyLine) {
              handleUnicode(unicodeStart);
            }
            next = advance();
            appendSubstringToken(TokenType.STRING, start, asciiOnlyString);
            return next;
          }
        }
        continue;
      }
      if (next == $BACKSLASH) {
        next = advance();
        if (next == $EOF) {
          break;
        }
      }
      if (next == $LF) {
        if (!asciiOnlyLine) {
          // Synchronize the string offset in the utf8 scanner.
          handleUnicode(unicodeStart);
          asciiOnlyLine = true;
          unicodeStart = scanOffset;
        }
        lineFeedInMultiline();
      } else if (next > 127) {
        asciiOnlyString = false;
        asciiOnlyLine = false;
      }
      next = advance();
    }
    if (!asciiOnlyLine) {
      handleUnicode(unicodeStart);
    }
    unterminatedString(
      quoteChar,
      quoteStart,
      start,
      asciiOnly: asciiOnlyString,
      isMultiLine: true,
      isRaw: false,
    );
    return next;
  }

  int unexpected(int character) {
    ErrorToken errorToken = buildUnexpectedCharacterToken(
      character,
      tokenStart,
    );
    if (errorToken is NonAsciiIdentifierToken) {
      int charOffset;
      List<int> codeUnits = <int>[];
      if (tail.isA(TokenType.IDENTIFIER) && tail.charEnd == tokenStart) {
        charOffset = tail.charOffset;
        codeUnits.addAll(tail.lexeme.codeUnits);
        tail = tail.previous!;
      } else {
        charOffset = errorToken.charOffset;
      }
      codeUnits.add(errorToken.character);
      prependErrorToken(errorToken);
      int next = advanceAfterError();
      while (isIdentifierChar(next, /* allowDollar = */ true)) {
        codeUnits.add(next);
        next = advance();
      }
      appendToken(
        new StringTokenImpl.fromString(
          TokenType.IDENTIFIER,
          new String.fromCharCodes(codeUnits),
          charOffset,
          precedingComments: comments,
        ),
      );
      return next;
    } else {
      prependErrorToken(errorToken);
      return advanceAfterError();
    }
  }

  void unterminatedString(
    int quoteChar,
    int quoteStart,
    int start, {
    required bool asciiOnly,
    required bool isMultiLine,
    required bool isRaw,
  }) {
    String suffix = new String.fromCharCodes(
      isMultiLine ? [quoteChar, quoteChar, quoteChar] : [quoteChar],
    );
    String prefix = isRaw ? 'r$suffix' : suffix;

    appendSyntheticSubstringToken(TokenType.STRING, start, asciiOnly, suffix);
    // Ensure that the error is reported on a visible token
    int errorStart = tokenStart < stringOffset ? tokenStart : quoteStart;
    prependErrorToken(new UnterminatedString(prefix, errorStart, stringOffset));
  }

  int advanceAfterError() {
    if (atEndOfFile()) return $EOF;
    return advance(); // Ensure progress.
  }
}

TokenType closeBraceInfoFor(BeginToken begin) {
  return const {
    '(': TokenType.CLOSE_PAREN,
    '[': TokenType.CLOSE_SQUARE_BRACKET,
    '{': TokenType.CLOSE_CURLY_BRACKET,
    '<': TokenType.GT,
    r'${': TokenType.CLOSE_CURLY_BRACKET,
  }[begin.lexeme]!;
}

class LineStarts extends Object with ListMixin<int> {
  List<int> array;
  int arrayLength = 0;

  LineStarts(int numberOfBytesHint)
    : array = _createInitialArray(numberOfBytesHint) {
    // The first line starts at character offset 0.
    add(/* value = */ 0);
  }

  // Implement abstract members used by [ListMixin]

  @override
  int get length => arrayLength;

  @override
  int operator [](int index) {
    assert(index < arrayLength);
    return array[index];
  }

  @override
  // Coverage-ignore(suite): Not run.
  void set length(int newLength) {
    if (newLength > array.length) {
      grow(newLength);
    }
    arrayLength = newLength;
  }

  @override
  // Coverage-ignore(suite): Not run.
  void operator []=(int index, int value) {
    if (value > 65535 && array is! Uint32List) {
      switchToUint32(array.length);
    }
    array[index] = value;
  }

  // Specialize methods from [ListMixin].
  @override
  void add(int value) {
    if (arrayLength >= array.length) {
      grow(/* newLengthMinimum = */ 0);
    }
    if (value > 65535 &&
        // Coverage-ignore(suite): Not run.
        array is! Uint32List) {
      // Coverage-ignore-block(suite): Not run.
      switchToUint32(array.length);
    }
    array[arrayLength++] = value;
  }

  // Helper methods.

  void grow(int newLengthMinimum) {
    int newLength = array.length * 2;
    if (newLength < newLengthMinimum) newLength = newLengthMinimum;

    if (array is Uint16List) {
      final Uint16List newArray = new Uint16List(newLength);
      newArray.setRange(/* start = */ 0, arrayLength, array);
      array = newArray;
    } else {
      // Coverage-ignore-block(suite): Not run.
      switchToUint32(newLength);
    }
  }

  // Coverage-ignore(suite): Not run.
  void switchToUint32(int newLength) {
    final Uint32List newArray = new Uint32List(newLength);
    newArray.setRange(/* start = */ 0, arrayLength, array);
    array = newArray;
  }

  static List<int> _createInitialArray(int numberOfBytesHint) {
    // Let's assume we have on average 22 bytes per line.
    final int expectedNumberOfLines = 1 + (numberOfBytesHint ~/ 22);

    if (numberOfBytesHint > 65535) {
      // Coverage-ignore-block(suite): Not run.
      return new Uint32List(expectedNumberOfLines);
    } else {
      return new Uint16List(expectedNumberOfLines);
    }
  }
}

/// [ScannerConfiguration] contains information for configuring which tokens
/// the scanner produces based upon the Dart language level.
class ScannerConfiguration {
  static const ScannerConfiguration nonNullable = const ScannerConfiguration();

  /// Experimental flag for enabling scanning of `>>>`.
  /// See https://github.com/dart-lang/language/issues/61
  /// and https://github.com/dart-lang/language/issues/60
  final bool enableTripleShift;

  /// If `true`, 'augment' is treated as a built-in identifier.
  final bool forAugmentationLibrary;

  const ScannerConfiguration({
    this.enableTripleShift = false,
    this.forAugmentationLibrary = false,
  });
}
