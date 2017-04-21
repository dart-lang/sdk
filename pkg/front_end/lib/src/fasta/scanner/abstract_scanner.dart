// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.scanner.abstract_scanner;

import 'dart:collection' show ListMixin;

import 'dart:typed_data' show Uint16List, Uint32List;

import '../scanner.dart'
    show ErrorToken, Scanner, buildUnexpectedCharacterToken;

import 'error_token.dart' show UnterminatedToken;

import 'keyword.dart' show KeywordState, Keyword;

import 'precedence.dart';

import 'token.dart' show BeginGroupToken, CommentToken, SymbolToken, Token;

import 'token_constants.dart';

import 'characters.dart';

abstract class AbstractScanner implements Scanner {
  final bool includeComments;

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
  final Token tokens = new SymbolToken.eof(-1);

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

  AbstractScanner(this.includeComments, {int numberOfBytesHint})
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
  void appendSubstringToken(PrecedenceInfo info, int start, bool asciiOnly,
      [int extraOffset]);

  /** Documentation in subclass [ArrayBasedScanner]. */
  void appendPrecedenceToken(PrecedenceInfo info);

  /** Documentation in subclass [ArrayBasedScanner]. */
  int select(int choice, PrecedenceInfo yes, PrecedenceInfo no);

  /** Documentation in subclass [ArrayBasedScanner]. */
  void appendKeywordToken(Keyword keyword);

  /** Documentation in subclass [ArrayBasedScanner]. */
  void appendEofToken();

  /** Documentation in subclass [ArrayBasedScanner]. */
  void appendWhiteSpace(int next);

  /** Documentation in subclass [ArrayBasedScanner]. */
  void lineFeedInMultiline();

  /** Documentation in subclass [ArrayBasedScanner]. */
  void appendBeginGroup(PrecedenceInfo info);

  /** Documentation in subclass [ArrayBasedScanner]. */
  int appendEndGroup(PrecedenceInfo info, int openKind);

  /** Documentation in subclass [ArrayBasedScanner]. */
  void appendGt(PrecedenceInfo info);

  /** Documentation in subclass [ArrayBasedScanner]. */
  void appendGtGt(PrecedenceInfo info);

  /** Documentation in subclass [ArrayBasedScanner]. */
  void appendComment(start, PrecedenceInfo info, bool asciiOnly);

  /** Documentation in subclass [ArrayBasedScanner]. */
  void appendDartDoc(start, PrecedenceInfo info, bool asciiOnly);

  /// Append [token] to the token stream.
  void appendErrorToken(ErrorToken token);

  /** Documentation in subclass [ArrayBasedScanner]. */
  void discardOpenLt();

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
      return appendEndGroup(CLOSE_PAREN_INFO, OPEN_PAREN_TOKEN);
    }

    if (identical(next, $OPEN_PAREN)) {
      appendBeginGroup(OPEN_PAREN_INFO);
      return advance();
    }

    if (identical(next, $SEMICOLON)) {
      appendPrecedenceToken(SEMICOLON_INFO);
      // Type parameters and arguments cannot contain semicolon.
      discardOpenLt();
      return advance();
    }

    if (identical(next, $PERIOD)) {
      return tokenizeDotsOrNumber(next);
    }

    if (identical(next, $COMMA)) {
      appendPrecedenceToken(COMMA_INFO);
      return advance();
    }

    if (identical(next, $EQ)) {
      return tokenizeEquals(next);
    }

    if (identical(next, $CLOSE_CURLY_BRACKET)) {
      return appendEndGroup(CLOSE_CURLY_BRACKET_INFO, OPEN_CURLY_BRACKET_TOKEN);
    }

    if (identical(next, $SLASH)) {
      return tokenizeSlashOrComment(next);
    }

    if (identical(next, $OPEN_CURLY_BRACKET)) {
      appendBeginGroup(OPEN_CURLY_BRACKET_INFO);
      return advance();
    }

    if (identical(next, $DQ) || identical(next, $SQ)) {
      return tokenizeString(next, scanOffset, false);
    }

    if (identical(next, $_)) {
      return tokenizeKeywordOrIdentifier(next, true);
    }

    if (identical(next, $COLON)) {
      appendPrecedenceToken(COLON_INFO);
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
          CLOSE_SQUARE_BRACKET_INFO, OPEN_SQUARE_BRACKET_TOKEN);
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
      appendPrecedenceToken(BACKPING_INFO);
      return advance();
    }

    if (identical(next, $BACKSLASH)) {
      appendPrecedenceToken(BACKSLASH_INFO);
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
        appendSubstringToken(SCRIPT_INFO, start, asciiOnly);
        return next;
      }
    }
    appendPrecedenceToken(HASH_INFO);
    return advance();
  }

  int tokenizeTilde(int next) {
    // ~ ~/ ~/=
    next = advance();
    if (identical(next, $SLASH)) {
      return select($EQ, TILDE_SLASH_EQ_INFO, TILDE_SLASH_INFO);
    } else {
      appendPrecedenceToken(TILDE_INFO);
      return next;
    }
  }

  int tokenizeOpenSquareBracket(int next) {
    // [ [] []=
    next = advance();
    if (identical(next, $CLOSE_SQUARE_BRACKET)) {
      return select($EQ, INDEX_EQ_INFO, INDEX_INFO);
    }
    appendBeginGroup(OPEN_SQUARE_BRACKET_INFO);
    return next;
  }

  int tokenizeCaret(int next) {
    // ^ ^=
    return select($EQ, CARET_EQ_INFO, CARET_INFO);
  }

  int tokenizeQuestion(int next) {
    // ? ?. ?? ??=
    next = advance();
    if (identical(next, $QUESTION)) {
      return select($EQ, QUESTION_QUESTION_EQ_INFO, QUESTION_QUESTION_INFO);
    } else if (identical(next, $PERIOD)) {
      appendPrecedenceToken(QUESTION_PERIOD_INFO);
      return advance();
    } else {
      appendPrecedenceToken(QUESTION_INFO);
      return next;
    }
  }

  int tokenizeBar(int next) {
    // | || |=
    next = advance();
    if (identical(next, $BAR)) {
      appendPrecedenceToken(BAR_BAR_INFO);
      return advance();
    } else if (identical(next, $EQ)) {
      appendPrecedenceToken(BAR_EQ_INFO);
      return advance();
    } else {
      appendPrecedenceToken(BAR_INFO);
      return next;
    }
  }

  int tokenizeAmpersand(int next) {
    // && &= &
    next = advance();
    if (identical(next, $AMPERSAND)) {
      appendPrecedenceToken(AMPERSAND_AMPERSAND_INFO);
      return advance();
    } else if (identical(next, $EQ)) {
      appendPrecedenceToken(AMPERSAND_EQ_INFO);
      return advance();
    } else {
      appendPrecedenceToken(AMPERSAND_INFO);
      return next;
    }
  }

  int tokenizePercent(int next) {
    // % %=
    return select($EQ, PERCENT_EQ_INFO, PERCENT_INFO);
  }

  int tokenizeMultiply(int next) {
    // * *=
    return select($EQ, STAR_EQ_INFO, STAR_INFO);
  }

  int tokenizeMinus(int next) {
    // - -- -=
    next = advance();
    if (identical(next, $MINUS)) {
      appendPrecedenceToken(MINUS_MINUS_INFO);
      return advance();
    } else if (identical(next, $EQ)) {
      appendPrecedenceToken(MINUS_EQ_INFO);
      return advance();
    } else {
      appendPrecedenceToken(MINUS_INFO);
      return next;
    }
  }

  int tokenizePlus(int next) {
    // + ++ +=
    next = advance();
    if (identical($PLUS, next)) {
      appendPrecedenceToken(PLUS_PLUS_INFO);
      return advance();
    } else if (identical($EQ, next)) {
      appendPrecedenceToken(PLUS_EQ_INFO);
      return advance();
    } else {
      appendPrecedenceToken(PLUS_INFO);
      return next;
    }
  }

  int tokenizeExclamation(int next) {
    // ! !=
    // !== is kept for user-friendly error reporting.

    next = advance();
    if (identical(next, $EQ)) {
      return select($EQ, BANG_EQ_EQ_INFO, BANG_EQ_INFO);
    }
    appendPrecedenceToken(BANG_INFO);
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
      return select($EQ, EQ_EQ_EQ_INFO, EQ_EQ_INFO);
    } else if (identical(next, $GT)) {
      appendPrecedenceToken(FUNCTION_INFO);
      return advance();
    }
    appendPrecedenceToken(EQ_INFO);
    return next;
  }

  int tokenizeGreaterThan(int next) {
    // > >= >> >>=
    next = advance();
    if (identical($EQ, next)) {
      appendPrecedenceToken(GT_EQ_INFO);
      return advance();
    } else if (identical($GT, next)) {
      next = advance();
      if (identical($EQ, next)) {
        appendPrecedenceToken(GT_GT_EQ_INFO);
        return advance();
      } else {
        appendGtGt(GT_GT_INFO);
        return next;
      }
    } else {
      appendGt(GT_INFO);
      return next;
    }
  }

  int tokenizeLessThan(int next) {
    // < <= << <<=
    next = advance();
    if (identical($EQ, next)) {
      appendPrecedenceToken(LT_EQ_INFO);
      return advance();
    } else if (identical($LT, next)) {
      return select($EQ, LT_LT_EQ_INFO, LT_LT_INFO);
    } else {
      appendBeginGroup(LT_INFO);
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
        appendSubstringToken(INT_INFO, start, true);
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
        appendSubstringToken(HEXADECIMAL_INFO, start, true);
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
      return select($PERIOD, PERIOD_PERIOD_PERIOD_INFO, PERIOD_PERIOD_INFO);
    } else {
      appendPrecedenceToken(PERIOD_INFO);
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
      appendSubstringToken(INT_INFO, start, true, -1);

      // TODO(ahe): Wrong offset for the period. Cannot call beginToken because
      // the scanner already advanced past the period.
      if (identical($PERIOD, next)) {
        return select($PERIOD, PERIOD_PERIOD_PERIOD_INFO, PERIOD_PERIOD_INFO);
      }
      appendPrecedenceToken(PERIOD_INFO);
      return next;
    }
    appendSubstringToken(DOUBLE_INFO, start, true);
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
      appendPrecedenceToken(SLASH_EQ_INFO);
      return advance();
    } else {
      appendPrecedenceToken(SLASH_INFO);
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
          appendDartDoc(start, SINGLE_LINE_COMMENT_INFO, asciiOnly);
        } else {
          appendComment(start, SINGLE_LINE_COMMENT_INFO, asciiOnly);
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
              appendDartDoc(start, MULTI_LINE_COMMENT_INFO, asciiOnlyComment);
            } else {
              appendComment(start, MULTI_LINE_COMMENT_INFO, asciiOnlyComment);
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
          appendSubstringToken(IDENTIFIER_INFO, start, true);
        }
        break;
      }
    }
    return next;
  }

  int tokenizeAt(int next) {
    appendPrecedenceToken(AT_INFO);
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
        appendSubstringToken(STRING_INFO, start, true);
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
        return unterminatedString(quoteChar);
      }
      if (next > 127) asciiOnly = false;
      next = advance();
    }
    if (!asciiOnly) handleUnicode(start);
    // Advance past the quote character.
    next = advance();
    appendSubstringToken(STRING_INFO, start, asciiOnly);
    return next;
  }

  int tokenizeStringInterpolation(int start, bool asciiOnly) {
    appendSubstringToken(STRING_INFO, start, asciiOnly);
    beginToken(); // $ starts here.
    int next = advance();
    if (identical(next, $OPEN_CURLY_BRACKET)) {
      return tokenizeInterpolatedExpression(next);
    } else {
      return tokenizeInterpolatedIdentifier(next);
    }
  }

  int tokenizeInterpolatedExpression(int next) {
    appendBeginGroup(STRING_INTERPOLATION_INFO);
    beginToken(); // The expression starts here.
    next = advance(); // Move past the curly bracket.
    while (!identical(next, $EOF) && !identical(next, $STX)) {
      next = bigSwitch(next);
    }
    if (identical(next, $EOF)) return next;
    next = advance(); // Move past the $STX.
    beginToken(); // The string interpolation suffix starts here.
    return next;
  }

  int tokenizeInterpolatedIdentifier(int next) {
    appendPrecedenceToken(STRING_INTERPOLATION_IDENTIFIER_INFO);

    if ($a <= next && next <= $z ||
        $A <= next && next <= $Z ||
        identical(next, $_)) {
      beginToken(); // The identifier starts here.
      next = tokenizeKeywordOrIdentifier(next, false);
    } else {
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
        appendSubstringToken(STRING_INFO, start, asciiOnly);
        return next;
      } else if (identical(next, $LF) || identical(next, $CR)) {
        if (!asciiOnly) handleUnicode(start);
        return unterminatedRawString(quoteChar);
      } else if (next > 127) {
        asciiOnly = false;
      }
      next = advance();
    }
    if (!asciiOnly) handleUnicode(start);
    return unterminatedRawString(quoteChar);
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
          appendSubstringToken(STRING_INFO, start, asciiOnlyString);
          return next;
        }
      }
    }
    if (!asciiOnlyLine) handleUnicode(unicodeStart);
    return unterminatedRawMultiLineString(quoteChar);
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
            appendSubstringToken(STRING_INFO, start, asciiOnlyString);
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
    return unterminatedMultiLineString(quoteChar);
  }

  int unexpected(int character) {
    appendErrorToken(buildUnexpectedCharacterToken(character, tokenStart));
    return advanceAfterError(true);
  }

  int unterminated(String prefix, {bool shouldAdvance: true}) {
    appendErrorToken(new UnterminatedToken(prefix, tokenStart, stringOffset));
    return advanceAfterError(shouldAdvance);
  }

  int unterminatedString(int quoteChar) {
    return unterminated(new String.fromCharCodes([quoteChar]));
  }

  int unterminatedRawString(int quoteChar) {
    return unterminated('r${new String.fromCharCodes([quoteChar])}');
  }

  int unterminatedMultiLineString(int quoteChar) {
    return unterminated(
        new String.fromCharCodes([quoteChar, quoteChar, quoteChar]));
  }

  int unterminatedRawMultiLineString(int quoteChar) {
    return unterminated(
        'r${new String.fromCharCodes([quoteChar, quoteChar, quoteChar])}');
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

PrecedenceInfo closeBraceInfoFor(BeginGroupToken begin) {
  return const {
    '(': CLOSE_PAREN_INFO,
    '[': CLOSE_SQUARE_BRACKET_INFO,
    '{': CLOSE_CURLY_BRACKET_INFO,
    '<': GT_INFO,
    r'${': CLOSE_CURLY_BRACKET_INFO,
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
