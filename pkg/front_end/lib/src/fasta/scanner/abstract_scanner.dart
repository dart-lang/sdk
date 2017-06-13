// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.scanner.abstract_scanner;

import 'dart:collection' show ListMixin;

import 'dart:typed_data' show Uint16List, Uint32List;

import '../../scanner/token.dart' show BeginToken, Token, TokenType;

import '../scanner.dart'
    show ErrorToken, Keyword, Scanner, buildUnexpectedCharacterToken;

import 'error_token.dart' show UnterminatedToken;

import 'keyword_state.dart' show KeywordState;

import 'token.dart' show CommentToken, DartDocToken;

import 'token_constants.dart';

import 'characters.dart';

abstract class AbstractScanner implements Scanner {
  final bool includeComments;

  /**
   * A flag indicating whether to parse generic method comments, of the form
   * `/*=T*/` and `/*<T>*/`.  The flag [includeComments] must be set to `true`.
   */
  bool scanGenericMethodComments = false;

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
  final Token tokens = new Token.eof(-1);

  /**
   * A pointer to the last scanned token.
   */
  Token tail;

  /**
   * A pointer to the stream of comment tokens created by this scanner
   * before they are assigned to the [Token] precedingComments field
   * of a non-comment token. A value of `null` indicates no comment tokens.
   */
  CommentToken comments;

  /**
   * A pointer to the last scanned comment token or `null` if none.
   */
  Token commentsTail;

  final List<int> lineStarts;

  AbstractScanner(this.includeComments, this.scanGenericMethodComments,
      {int numberOfBytesHint})
      : lineStarts = new LineStarts(numberOfBytesHint) {
    this.tail = this.tokens;
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
   * Returns the character at the next poisition. Like in [advance], the
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
  Token firstToken() => tokens.next;

  /**
   * Notifies that a new token starts at current offset.
   */
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
  void appendSubstringToken(TokenType type, int start, bool asciiOnly,
      [int extraOffset]);

  /**
   * Appends a substring from the scan offset [start] to the current
   * [scanOffset] plus [closingQuotes]. The closing quote(s) will be added
   * to the unterminated string literal's lexeme but the returned
   * token's length will *not* include those closing quotes
   * so as to be true to the original source.
   */
  void appendSyntheticSubstringToken(
      TokenType type, int start, bool asciiOnly, String closingQuotes);

  /** Documentation in subclass [ArrayBasedScanner]. */
  void appendPrecedenceToken(TokenType type);

  /** Documentation in subclass [ArrayBasedScanner]. */
  int select(int choice, TokenType yes, TokenType no);

  /** Documentation in subclass [ArrayBasedScanner]. */
  void appendKeywordToken(Keyword keyword);

  /** Documentation in subclass [ArrayBasedScanner]. */
  void appendEofToken();

  /** Documentation in subclass [ArrayBasedScanner]. */
  void appendWhiteSpace(int next);

  /** Documentation in subclass [ArrayBasedScanner]. */
  void lineFeedInMultiline();

  /** Documentation in subclass [ArrayBasedScanner]. */
  void appendBeginGroup(TokenType type);

  /** Documentation in subclass [ArrayBasedScanner]. */
  int appendEndGroup(TokenType type, int openKind);

  /** Documentation in subclass [ArrayBasedScanner]. */
  void appendGt(TokenType type);

  /** Documentation in subclass [ArrayBasedScanner]. */
  void appendGtGt(TokenType type);

  /// Append [token] to the token stream.
  void appendErrorToken(ErrorToken token);

  /**
   * Returns a new comment from the scan offset [start] to the current
   * [scanOffset] plus the [extraOffset]. For example, if the current
   * scanOffset is 10, then [appendSubstringToken(5, -1)] will append the
   * substring string [5,9).
   *
   * Note that [extraOffset] can only be used if the covered character(s) are
   * known to be ASCII.
   */
  CommentToken createCommentToken(TokenType type, int start, bool asciiOnly,
      [int extraOffset = 0]);

  /**
   * Returns a new dartdoc from the scan offset [start] to the current
   * [scanOffset] plus the [extraOffset]. For example, if the current
   * scanOffset is 10, then [appendSubstringToken(5, -1)] will append the
   * substring string [5,9).
   *
   * Note that [extraOffset] can only be used if the covered character(s) are
   * known to be ASCII.
   */
  DartDocToken createDartDocToken(TokenType type, int start, bool asciiOnly,
      [int extraOffset = 0]);

  /** Documentation in subclass [ArrayBasedScanner]. */
  void discardOpenLt();

  /** Documentation in subclass [ArrayBasedScanner]. */
  void discardInterpolation();

  /// Return true when at EOF.
  bool atEndOfFile();

  Token tokenize() {
    while (!atEndOfFile()) {
      int next = advance();
      while (!identical(next, $EOF)) {
        next = bigSwitch(next);
      }
      if (atEndOfFile()) {
        appendEofToken();
      } else {
        unexpected($EOF);
      }
    }

    // Always pretend that there's a line at the end of the file.
    lineStarts.add(stringOffset + 1);

    return firstToken();
  }

  int bigSwitch(int next) {
    beginToken();
    if (identical(next, $SPACE) ||
        identical(next, $TAB) ||
        identical(next, $LF) ||
        identical(next, $CR)) {
      appendWhiteSpace(next);
      next = advance();
      // Sequences of spaces are common, so advance through them fast.
      while (identical(next, $SPACE)) {
        // We don't invoke [:appendWhiteSpace(next):] here for efficiency,
        // assuming that it does not do anything for space characters.
        next = advance();
      }
      return next;
    }

    int nextLower = next | 0x20;

    if ($a <= nextLower && nextLower <= $z) {
      if (identical($r, next)) {
        return tokenizeRawStringKeywordOrIdentifier(next);
      }
      return tokenizeKeywordOrIdentifier(next, true);
    }

    if (identical(next, $CLOSE_PAREN)) {
      return appendEndGroup(TokenType.CLOSE_PAREN, OPEN_PAREN_TOKEN);
    }

    if (identical(next, $OPEN_PAREN)) {
      appendBeginGroup(TokenType.OPEN_PAREN);
      return advance();
    }

    if (identical(next, $SEMICOLON)) {
      appendPrecedenceToken(TokenType.SEMICOLON);
      // Type parameters and arguments cannot contain semicolon.
      discardOpenLt();
      return advance();
    }

    if (identical(next, $PERIOD)) {
      return tokenizeDotsOrNumber(next);
    }

    if (identical(next, $COMMA)) {
      appendPrecedenceToken(TokenType.COMMA);
      return advance();
    }

    if (identical(next, $EQ)) {
      return tokenizeEquals(next);
    }

    if (identical(next, $CLOSE_CURLY_BRACKET)) {
      return appendEndGroup(
          TokenType.CLOSE_CURLY_BRACKET, OPEN_CURLY_BRACKET_TOKEN);
    }

    if (identical(next, $SLASH)) {
      return tokenizeSlashOrComment(next);
    }

    if (identical(next, $OPEN_CURLY_BRACKET)) {
      appendBeginGroup(TokenType.OPEN_CURLY_BRACKET);
      return advance();
    }

    if (identical(next, $DQ) || identical(next, $SQ)) {
      return tokenizeString(next, scanOffset, false);
    }

    if (identical(next, $_)) {
      return tokenizeKeywordOrIdentifier(next, true);
    }

    if (identical(next, $COLON)) {
      appendPrecedenceToken(TokenType.COLON);
      return advance();
    }

    if (identical(next, $LT)) {
      return tokenizeLessThan(next);
    }

    if (identical(next, $GT)) {
      return tokenizeGreaterThan(next);
    }

    if (identical(next, $BANG)) {
      return tokenizeExclamation(next);
    }

    if (identical(next, $OPEN_SQUARE_BRACKET)) {
      return tokenizeOpenSquareBracket(next);
    }

    if (identical(next, $CLOSE_SQUARE_BRACKET)) {
      return appendEndGroup(
          TokenType.CLOSE_SQUARE_BRACKET, OPEN_SQUARE_BRACKET_TOKEN);
    }

    if (identical(next, $AT)) {
      return tokenizeAt(next);
    }

    if (next >= $1 && next <= $9) {
      return tokenizeNumber(next);
    }

    if (identical(next, $AMPERSAND)) {
      return tokenizeAmpersand(next);
    }

    if (identical(next, $0)) {
      return tokenizeHexOrNumber(next);
    }

    if (identical(next, $QUESTION)) {
      return tokenizeQuestion(next);
    }

    if (identical(next, $BAR)) {
      return tokenizeBar(next);
    }

    if (identical(next, $PLUS)) {
      return tokenizePlus(next);
    }

    if (identical(next, $$)) {
      return tokenizeKeywordOrIdentifier(next, true);
    }

    if (identical(next, $MINUS)) {
      return tokenizeMinus(next);
    }

    if (identical(next, $STAR)) {
      return tokenizeMultiply(next);
    }

    if (identical(next, $CARET)) {
      return tokenizeCaret(next);
    }

    if (identical(next, $TILDE)) {
      return tokenizeTilde(next);
    }

    if (identical(next, $PERCENT)) {
      return tokenizePercent(next);
    }

    if (identical(next, $BACKPING)) {
      appendPrecedenceToken(TokenType.BACKPING);
      return advance();
    }

    if (identical(next, $BACKSLASH)) {
      appendPrecedenceToken(TokenType.BACKSLASH);
      return advance();
    }

    if (identical(next, $HASH)) {
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
      if (identical(peek(), $BANG)) {
        int start = scanOffset;
        bool asciiOnly = true;
        do {
          next = advance();
          if (next > 127) asciiOnly = false;
        } while (!identical(next, $LF) &&
            !identical(next, $CR) &&
            !identical(next, $EOF));
        if (!asciiOnly) handleUnicode(start);
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
    if (identical(next, $SLASH)) {
      return select($EQ, TokenType.TILDE_SLASH_EQ, TokenType.TILDE_SLASH);
    } else {
      appendPrecedenceToken(TokenType.TILDE);
      return next;
    }
  }

  int tokenizeOpenSquareBracket(int next) {
    // [ [] []=
    next = advance();
    if (identical(next, $CLOSE_SQUARE_BRACKET)) {
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
    // ? ?. ?? ??=
    next = advance();
    if (identical(next, $QUESTION)) {
      return select(
          $EQ, TokenType.QUESTION_QUESTION_EQ, TokenType.QUESTION_QUESTION);
    } else if (identical(next, $PERIOD)) {
      appendPrecedenceToken(TokenType.QUESTION_PERIOD);
      return advance();
    } else {
      appendPrecedenceToken(TokenType.QUESTION);
      return next;
    }
  }

  int tokenizeBar(int next) {
    // | || |= ||=
    next = advance();
    if (identical(next, $BAR)) {
      next = advance();
      if (identical(next, $EQ)) {
        appendPrecedenceToken(TokenType.BAR_BAR_EQ);
        return advance();
      }
      appendPrecedenceToken(TokenType.BAR_BAR);
      return next;
    } else if (identical(next, $EQ)) {
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
    if (identical(next, $AMPERSAND)) {
      next = advance();
      if (identical(next, $EQ)) {
        appendPrecedenceToken(TokenType.AMPERSAND_AMPERSAND_EQ);
        return advance();
      }
      appendPrecedenceToken(TokenType.AMPERSAND_AMPERSAND);
      return next;
    } else if (identical(next, $EQ)) {
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
    if (identical(next, $MINUS)) {
      appendPrecedenceToken(TokenType.MINUS_MINUS);
      return advance();
    } else if (identical(next, $EQ)) {
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
    if (identical($PLUS, next)) {
      appendPrecedenceToken(TokenType.PLUS_PLUS);
      return advance();
    } else if (identical($EQ, next)) {
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
    if (identical(next, $EQ)) {
      return select($EQ, TokenType.BANG_EQ_EQ, TokenType.BANG_EQ);
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
    if (identical(next, $EQ)) {
      return select($EQ, TokenType.EQ_EQ_EQ, TokenType.EQ_EQ);
    } else if (identical(next, $GT)) {
      appendPrecedenceToken(TokenType.FUNCTION);
      return advance();
    }
    appendPrecedenceToken(TokenType.EQ);
    return next;
  }

  int tokenizeGreaterThan(int next) {
    // > >= >> >>=
    next = advance();
    if (identical($EQ, next)) {
      appendPrecedenceToken(TokenType.GT_EQ);
      return advance();
    } else if (identical($GT, next)) {
      next = advance();
      if (identical($EQ, next)) {
        appendPrecedenceToken(TokenType.GT_GT_EQ);
        return advance();
      } else {
        appendGtGt(TokenType.GT_GT);
        return next;
      }
    } else {
      appendGt(TokenType.GT);
      return next;
    }
  }

  int tokenizeLessThan(int next) {
    // < <= << <<=
    next = advance();
    if (identical($EQ, next)) {
      appendPrecedenceToken(TokenType.LT_EQ);
      return advance();
    } else if (identical($LT, next)) {
      return select($EQ, TokenType.LT_LT_EQ, TokenType.LT_LT);
    } else {
      appendBeginGroup(TokenType.LT);
      return next;
    }
  }

  int tokenizeNumber(int next) {
    int start = scanOffset;
    while (true) {
      next = advance();
      if ($0 <= next && next <= $9) {
        continue;
      } else if (identical(next, $e) || identical(next, $E)) {
        return tokenizeFractionPart(next, start);
      } else {
        if (identical(next, $PERIOD)) {
          int nextnext = peek();
          if ($0 <= nextnext && nextnext <= $9) {
            return tokenizeFractionPart(advance(), start);
          }
        }
        appendSubstringToken(TokenType.INT, start, true);
        return next;
      }
    }
  }

  int tokenizeHexOrNumber(int next) {
    int x = peek();
    if (identical(x, $x) || identical(x, $X)) {
      return tokenizeHex(next);
    }
    return tokenizeNumber(next);
  }

  int tokenizeHex(int next) {
    int start = scanOffset;
    next = advance(); // Advance past the $x or $X.
    bool hasDigits = false;
    while (true) {
      next = advance();
      if (($0 <= next && next <= $9) ||
          ($A <= next && next <= $F) ||
          ($a <= next && next <= $f)) {
        hasDigits = true;
      } else {
        if (!hasDigits) {
          unterminated('0x', shouldAdvance: false);
          return next;
        }
        appendSubstringToken(TokenType.HEXADECIMAL, start, true);
        return next;
      }
    }
  }

  int tokenizeDotsOrNumber(int next) {
    int start = scanOffset;
    next = advance();
    if (($0 <= next && next <= $9)) {
      return tokenizeFractionPart(next, start);
    } else if (identical($PERIOD, next)) {
      return select(
          $PERIOD, TokenType.PERIOD_PERIOD_PERIOD, TokenType.PERIOD_PERIOD);
    } else {
      appendPrecedenceToken(TokenType.PERIOD);
      return next;
    }
  }

  int tokenizeFractionPart(int next, int start) {
    bool done = false;
    bool hasDigit = false;
    LOOP:
    while (!done) {
      if ($0 <= next && next <= $9) {
        hasDigit = true;
      } else if (identical($e, next) || identical($E, next)) {
        hasDigit = true;
        next = advance();
        if (identical(next, $PLUS) || identical(next, $MINUS)) {
          next = advance();
        }
        bool hasExponentDigits = false;
        while (true) {
          if ($0 <= next && next <= $9) {
            hasExponentDigits = true;
          } else {
            if (!hasExponentDigits) {
              unterminated('1e', shouldAdvance: false);
              return next;
            }
            break;
          }
          next = advance();
        }

        done = true;
        continue LOOP;
      } else {
        done = true;
        continue LOOP;
      }
      next = advance();
    }
    if (!hasDigit) {
      // Reduce offset, we already advanced to the token past the period.
      appendSubstringToken(TokenType.INT, start, true, -1);

      // TODO(ahe): Wrong offset for the period. Cannot call beginToken because
      // the scanner already advanced past the period.
      if (identical($PERIOD, next)) {
        return select(
            $PERIOD, TokenType.PERIOD_PERIOD_PERIOD, TokenType.PERIOD_PERIOD);
      }
      appendPrecedenceToken(TokenType.PERIOD);
      return next;
    }
    appendSubstringToken(TokenType.DOUBLE, start, true);
    return next;
  }

  int tokenizeSlashOrComment(int next) {
    int start = scanOffset;
    next = advance();
    if (identical($STAR, next)) {
      return tokenizeMultiLineComment(next, start);
    } else if (identical($SLASH, next)) {
      return tokenizeSingleLineComment(next, start);
    } else if (identical($EQ, next)) {
      appendPrecedenceToken(TokenType.SLASH_EQ);
      return advance();
    } else {
      appendPrecedenceToken(TokenType.SLASH);
      return next;
    }
  }

  int tokenizeSingleLineComment(int next, int start) {
    bool asciiOnly = true;
    bool dartdoc = identical($SLASH, peek());
    while (true) {
      next = advance();
      if (next > 127) asciiOnly = false;
      if (identical($LF, next) ||
          identical($CR, next) ||
          identical($EOF, next)) {
        if (!asciiOnly) handleUnicode(start);
        if (dartdoc) {
          appendDartDoc(start, TokenType.SINGLE_LINE_COMMENT, asciiOnly);
        } else {
          appendComment(start, TokenType.SINGLE_LINE_COMMENT, asciiOnly);
        }
        return next;
      }
    }
  }

  int tokenizeMultiLineComment(int next, int start) {
    bool asciiOnlyComment = true; // Track if the entire comment is ASCII.
    bool asciiOnlyLines = true; // Track ASCII since the last handleUnicode.
    int unicodeStart = start;
    int nesting = 1;
    next = advance();
    bool dartdoc = identical($STAR, next);
    while (true) {
      if (identical($EOF, next)) {
        if (!asciiOnlyLines) handleUnicode(unicodeStart);
        unterminated('/*');
        break;
      } else if (identical($STAR, next)) {
        next = advance();
        if (identical($SLASH, next)) {
          --nesting;
          if (0 == nesting) {
            if (!asciiOnlyLines) handleUnicode(unicodeStart);
            next = advance();
            if (dartdoc) {
              appendDartDoc(
                  start, TokenType.MULTI_LINE_COMMENT, asciiOnlyComment);
            } else {
              appendComment(
                  start, TokenType.MULTI_LINE_COMMENT, asciiOnlyComment);
            }
            break;
          } else {
            next = advance();
          }
        }
      } else if (identical($SLASH, next)) {
        next = advance();
        if (identical($STAR, next)) {
          next = advance();
          ++nesting;
        }
      } else if (identical(next, $LF)) {
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
    if (scanGenericMethodComments) {
      String value = newComment.lexeme;
      int length = value.length;
      if (length > 5 &&
          value.codeUnitAt(0) == $SLASH &&
          value.codeUnitAt(1) == $STAR &&
          value.codeUnitAt(2) == $EQ) {
        newComment = new CommentToken.fromString(
            TokenType.GENERIC_METHOD_TYPE_ASSIGN, value, start);
      } else if (length > 6 &&
          value.codeUnitAt(0) == $SLASH &&
          value.codeUnitAt(1) == $STAR &&
          value.codeUnitAt(2) == $LT &&
          value.codeUnitAt(length - 1) == $SLASH &&
          value.codeUnitAt(length - 2) == $STAR &&
          value.codeUnitAt(length - 3) == $GT) {
        newComment = new CommentToken.fromString(
            TokenType.GENERIC_METHOD_TYPE_LIST, value, start);
      }
    }
    _appendToCommentStream(newComment);
  }

  void appendDartDoc(int start, TokenType type, bool asciiOnly) {
    if (!includeComments) return;
    Token newComment = createDartDocToken(type, start, asciiOnly);
    _appendToCommentStream(newComment);
  }

  /**
   * Append the given token to the [tail] of the current stream of tokens.
   */
  void appendToken(Token token) {
    tail.next = token;
    tail.next.previous = tail;
    tail = tail.next;
    if (comments != null && comments == token.precedingComments) {
      comments = null;
      commentsTail = null;
    } else {
      // It is the responsibility of the caller to construct the token
      // being appended with preceeding comments if any
      assert(comments == null || token.isSynthetic);
    }
  }

  void _appendToCommentStream(Token newComment) {
    if (comments == null) {
      comments = newComment;
      commentsTail = comments;
    } else {
      commentsTail.next = newComment;
      commentsTail.next.previous = commentsTail;
      commentsTail = commentsTail.next;
    }
  }

  int tokenizeRawStringKeywordOrIdentifier(int next) {
    // [next] is $r.
    int nextnext = peek();
    if (identical(nextnext, $DQ) || identical(nextnext, $SQ)) {
      int start = scanOffset;
      next = advance();
      return tokenizeString(next, start, true);
    }
    return tokenizeKeywordOrIdentifier(next, true);
  }

  int tokenizeKeywordOrIdentifier(int next, bool allowDollar) {
    KeywordState state = KeywordState.KEYWORD_STATE;
    int start = scanOffset;
    // We allow a leading capital character.
    if ($A <= next && next <= $Z) {
      state = state.nextCapital(next);
      next = advance();
    } else if ($a <= next && next <= $z) {
      // Do the first next call outside the loop to avoid an additional test
      // and to make the loop monomorphic.
      state = state.next(next);
      next = advance();
    }
    while (state != null && $a <= next && next <= $z) {
      state = state.next(next);
      next = advance();
    }
    if (state == null || state.keyword == null) {
      return tokenizeIdentifier(next, start, allowDollar);
    }
    if (($A <= next && next <= $Z) ||
        ($0 <= next && next <= $9) ||
        identical(next, $_) ||
        identical(next, $$)) {
      return tokenizeIdentifier(next, start, allowDollar);
    } else {
      appendKeywordToken(state.keyword);
      return next;
    }
  }

  /**
   * [allowDollar] can exclude '$', which is not allowed as part of a string
   * interpolation identifier.
   */
  int tokenizeIdentifier(int next, int start, bool allowDollar) {
    while (true) {
      if (($a <= next && next <= $z) ||
          ($A <= next && next <= $Z) ||
          ($0 <= next && next <= $9) ||
          identical(next, $_) ||
          (identical(next, $$) && allowDollar)) {
        next = advance();
      } else {
        // Identifier ends here.
        if (start == scanOffset) {
          return unexpected(next);
        } else {
          appendSubstringToken(TokenType.IDENTIFIER, start, true);
        }
        break;
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
    if (identical(quoteChar, next)) {
      next = advance();
      if (identical(quoteChar, next)) {
        // Multiline string.
        return tokenizeMultiLineString(quoteChar, start, raw);
      } else {
        // Empty string.
        appendSubstringToken(TokenType.STRING, start, true);
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
   * [start] is the scanOffset of the quote.
   *
   * The token contains a substring of the source file, including the
   * string quotes, backslashes for escaping. For interpolated strings,
   * the parts before and after are separate tokens.
   *
   *   "a $b c"
   *
   * gives StringToken("a $), StringToken(b) and StringToken( c").
   */
  int tokenizeSingleLineString(int next, int quoteChar, int start) {
    bool asciiOnly = true;
    while (!identical(next, quoteChar)) {
      if (identical(next, $BACKSLASH)) {
        next = advance();
      } else if (identical(next, $$)) {
        if (!asciiOnly) handleUnicode(start);
        next = tokenizeStringInterpolation(start, asciiOnly);
        start = scanOffset;
        asciiOnly = true;
        continue;
      }
      if (next <= $CR &&
          (identical(next, $LF) ||
              identical(next, $CR) ||
              identical(next, $EOF))) {
        if (!asciiOnly) handleUnicode(start);
        return unterminatedString(quoteChar, start,
            asciiOnly: asciiOnly, isMultiLine: false, isRaw: false);
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
    if (identical(next, $OPEN_CURLY_BRACKET)) {
      return tokenizeInterpolatedExpression(next);
    } else {
      return tokenizeInterpolatedIdentifier(next);
    }
  }

  int tokenizeInterpolatedExpression(int next) {
    appendBeginGroup(TokenType.STRING_INTERPOLATION_EXPRESSION);
    beginToken(); // The expression starts here.
    next = advance(); // Move past the curly bracket.
    while (!identical(next, $EOF) && !identical(next, $STX)) {
      next = bigSwitch(next);
    }
    if (identical(next, $EOF)) {
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

    if ($a <= next && next <= $z ||
        $A <= next && next <= $Z ||
        identical(next, $_)) {
      beginToken(); // The identifier starts here.
      next = tokenizeKeywordOrIdentifier(next, false);
    } else {
      beginToken(); // The synthetic identifier starts here.
      appendSyntheticSubstringToken(TokenType.IDENTIFIER, scanOffset, true, '');
      unterminated(r'$', shouldAdvance: false);
    }
    beginToken(); // The string interpolation suffix starts here.
    return next;
  }

  int tokenizeSingleLineRawString(int next, int quoteChar, int start) {
    bool asciiOnly = true;
    while (next != $EOF) {
      if (identical(next, quoteChar)) {
        if (!asciiOnly) handleUnicode(start);
        next = advance();
        appendSubstringToken(TokenType.STRING, start, asciiOnly);
        return next;
      } else if (identical(next, $LF) || identical(next, $CR)) {
        if (!asciiOnly) handleUnicode(start);
        return unterminatedString(quoteChar, start,
            asciiOnly: asciiOnly, isMultiLine: false, isRaw: true);
      } else if (next > 127) {
        asciiOnly = false;
      }
      next = advance();
    }
    if (!asciiOnly) handleUnicode(start);
    return unterminatedString(quoteChar, start,
        asciiOnly: asciiOnly, isMultiLine: false, isRaw: true);
  }

  int tokenizeMultiLineRawString(int quoteChar, int start) {
    bool asciiOnlyString = true;
    bool asciiOnlyLine = true;
    int unicodeStart = start;
    int next = advance(); // Advance past the (last) quote (of three).
    outer:
    while (!identical(next, $EOF)) {
      while (!identical(next, quoteChar)) {
        if (identical(next, $LF)) {
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
        if (identical(next, $EOF)) break outer;
      }
      next = advance();
      if (identical(next, quoteChar)) {
        next = advance();
        if (identical(next, quoteChar)) {
          if (!asciiOnlyLine) handleUnicode(unicodeStart);
          next = advance();
          appendSubstringToken(TokenType.STRING, start, asciiOnlyString);
          return next;
        }
      }
    }
    if (!asciiOnlyLine) handleUnicode(unicodeStart);
    return unterminatedString(quoteChar, start,
        asciiOnly: asciiOnlyLine, isMultiLine: true, isRaw: true);
  }

  int tokenizeMultiLineString(int quoteChar, int start, bool raw) {
    if (raw) return tokenizeMultiLineRawString(quoteChar, start);
    bool asciiOnlyString = true;
    bool asciiOnlyLine = true;
    int unicodeStart = start;
    int next = advance(); // Advance past the (last) quote (of three).
    while (!identical(next, $EOF)) {
      if (identical(next, $$)) {
        if (!asciiOnlyLine) handleUnicode(unicodeStart);
        next = tokenizeStringInterpolation(start, asciiOnlyString);
        start = scanOffset;
        unicodeStart = start;
        asciiOnlyString = true; // A new string token is created for the rest.
        asciiOnlyLine = true;
        continue;
      }
      if (identical(next, quoteChar)) {
        next = advance();
        if (identical(next, quoteChar)) {
          next = advance();
          if (identical(next, quoteChar)) {
            if (!asciiOnlyLine) handleUnicode(unicodeStart);
            next = advance();
            appendSubstringToken(TokenType.STRING, start, asciiOnlyString);
            return next;
          }
        }
        continue;
      }
      if (identical(next, $BACKSLASH)) {
        next = advance();
        if (identical(next, $EOF)) break;
      }
      if (identical(next, $LF)) {
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
    if (!asciiOnlyLine) handleUnicode(unicodeStart);
    return unterminatedString(quoteChar, start,
        asciiOnly: asciiOnlyString, isMultiLine: true, isRaw: false);
  }

  int unexpected(int character) {
    appendErrorToken(buildUnexpectedCharacterToken(character, tokenStart));
    return advanceAfterError(true);
  }

  int unterminated(String prefix, {bool shouldAdvance: true}) {
    appendErrorToken(new UnterminatedToken(prefix, tokenStart, stringOffset));
    return advanceAfterError(shouldAdvance);
  }

  int unterminatedString(int quoteChar, int start,
      {bool asciiOnly, bool isMultiLine, bool isRaw}) {
    String suffix = new String.fromCharCodes(
        isMultiLine ? [quoteChar, quoteChar, quoteChar] : [quoteChar]);
    String prefix = isRaw ? 'r$suffix' : suffix;

    appendSyntheticSubstringToken(TokenType.STRING, start, asciiOnly, suffix);
    beginToken();
    return unterminated(prefix);
  }

  int advanceAfterError(bool shouldAdvance) {
    if (atEndOfFile()) return $EOF;
    if (shouldAdvance) {
      return advance(); // Ensure progress.
    } else {
      return -1;
    }
  }
}

TokenType closeBraceInfoFor(BeginToken begin) {
  return const {
    '(': TokenType.CLOSE_PAREN,
    '[': TokenType.CLOSE_SQUARE_BRACKET,
    '{': TokenType.CLOSE_CURLY_BRACKET,
    '<': TokenType.GT,
    r'${': TokenType.CLOSE_CURLY_BRACKET,
  }[begin.lexeme];
}

class LineStarts extends Object with ListMixin<int> {
  List<int> array;
  int arrayLength = 0;

  LineStarts(int numberOfBytesHint) {
    // Let's assume the average Dart file is 300 bytes.
    if (numberOfBytesHint == null) numberOfBytesHint = 300;

    // Let's assume we have on average 22 bytes per line.
    final int expectedNumberOfLines = 1 + (numberOfBytesHint ~/ 22);

    if (numberOfBytesHint > 65535) {
      array = new Uint32List(expectedNumberOfLines);
    } else {
      array = new Uint16List(expectedNumberOfLines);
    }

    // The first line starts at character offset 0.
    add(0);
  }

  // Implement abstract members used by [ListMixin]

  int get length => arrayLength;

  int operator [](int index) {
    assert(index < arrayLength);
    return array[index];
  }

  void set length(int newLength) {
    if (newLength > array.length) {
      grow(newLength);
    }
    arrayLength = newLength;
  }

  void operator []=(int index, int value) {
    if (value > 65535 && array is! Uint32List) {
      switchToUint32(array.length);
    }
    array[index] = value;
  }

  // Specialize methods from [ListMixin].
  void add(int value) {
    if (arrayLength >= array.length) {
      grow(0);
    }
    if (value > 65535 && array is! Uint32List) {
      switchToUint32(array.length);
    }
    array[arrayLength++] = value;
  }

  // Helper methods.

  void grow(int newLengthMinimum) {
    int newLength = array.length * 2;
    if (newLength < newLengthMinimum) newLength = newLengthMinimum;

    if (array is Uint16List) {
      final newArray = new Uint16List(newLength);
      newArray.setRange(0, arrayLength, array);
      array = newArray;
    } else {
      switchToUint32(newLength);
    }
  }

  void switchToUint32(int newLength) {
    final newArray = new Uint32List(newLength);
    newArray.setRange(0, arrayLength, array);
    array = newArray;
  }
}
