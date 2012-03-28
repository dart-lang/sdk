// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface Scanner {
  Token tokenize();
}

/**
 * Common base class for a Dart scanner.
 */
class AbstractScanner<T> implements Scanner {
  abstract int advance();
  abstract int nextByte();
  abstract int peek();
  abstract int select(int choice, PrecedenceInfo yes, PrecedenceInfo no);
  abstract void appendPrecenceToken(PrecedenceInfo info);
  abstract void appendStringToken(PrecedenceInfo info, String value);
  abstract void appendByteStringToken(PrecedenceInfo info, T value);
  abstract void appendKeywordToken(Keyword keyword);
  abstract void appendWhiteSpace(int next);
  abstract void appendEofToken();
  abstract T asciiString(int start, int offset);
  abstract T utf8String(int start, int offset);
  abstract Token firstToken();
  abstract void beginToken();
  abstract void addToCharOffset(int offset);
  abstract int get charOffset();
  abstract int get byteOffset();
  abstract void appendBeginGroup(PrecedenceInfo info, String value);
  abstract int appendEndGroup(PrecedenceInfo info, String value, int openKind);
  abstract void appendGt(PrecedenceInfo info, String value);
  abstract void appendGtGt(PrecedenceInfo info, String value);
  abstract void appendGtGtGt(PrecedenceInfo info, String value);
  abstract void discardOpenLt();

  // TODO(ahe): Move this class to implementation.

  Token tokenize() {
    int next = advance();
    while (next !== $EOF) {
      next = bigSwitch(next);
    }
    appendEofToken();
    return firstToken();
  }

  int bigSwitch(int next) {
    beginToken();
    if (next === $TAB || next === $LF || next === $CR || next === $SPACE) {
      appendWhiteSpace(next);
      return advance();
    }

    if ($a <= next && next <= $z) {
      return tokenizeKeywordOrIdentifier(next, true);
    }

    if (($A <= next && next <= $Z) || next === $_ || next === $$) {
      return tokenizeIdentifier(next, byteOffset, true);
    }

    if (next === $LT) {
      return tokenizeLessThan(next);
    }

    if (next === $GT) {
      return tokenizeGreaterThan(next);
    }

    if (next === $EQ) {
      return tokenizeEquals(next);
    }

    if (next === $BANG) {
      return tokenizeExclamation(next);
    }

    if (next === $PLUS) {
      return tokenizePlus(next);
    }

    if (next === $MINUS) {
      return tokenizeMinus(next);
    }

    if (next === $STAR) {
      return tokenizeMultiply(next);
    }

    if (next === $PERCENT) {
      return tokenizePercent(next);
    }

    if (next === $AMPERSAND) {
      return tokenizeAmpersand(next);
    }

    if (next === $BAR) {
      return tokenizeBar(next);
    }

    if (next === $CARET) {
      return tokenizeCaret(next);
    }

    if (next === $OPEN_SQUARE_BRACKET) {
      return tokenizeOpenSquareBracket(next);
    }

    if (next === $TILDE) {
      return tokenizeTilde(next);
    }

    if (next === $BACKSLASH) {
      appendPrecenceToken(BACKSLASH_INFO);
      return advance();
    }

    if (next === $HASH) {
      return tokenizeTag(next);
    }

    if (next === $OPEN_PAREN) {
      appendBeginGroup(OPEN_PAREN_INFO, "(");
      return advance();
    }

    if (next === $CLOSE_PAREN) {
      return appendEndGroup(CLOSE_PAREN_INFO, ")", OPEN_PAREN_TOKEN);
    }

    if (next === $COMMA) {
      appendPrecenceToken(COMMA_INFO);
      return advance();
    }

    if (next === $COLON) {
      appendPrecenceToken(COLON_INFO);
      return advance();
    }

    if (next === $SEMICOLON) {
      appendPrecenceToken(SEMICOLON_INFO);
      discardOpenLt();
      return advance();
    }

    if (next === $QUESTION) {
      appendPrecenceToken(QUESTION_INFO);
      return advance();
    }

    if (next === $CLOSE_SQUARE_BRACKET) {
      return appendEndGroup(CLOSE_SQUARE_BRACKET_INFO, "]",
                            OPEN_SQUARE_BRACKET_TOKEN);
    }

    if (next === $BACKPING) {
      appendPrecenceToken(BACKPING_INFO);
      return advance();
    }

    if (next === $OPEN_CURLY_BRACKET) {
      appendBeginGroup(OPEN_CURLY_BRACKET_INFO, "{");
      return advance();
    }

    if (next === $CLOSE_CURLY_BRACKET) {
      return appendEndGroup(CLOSE_CURLY_BRACKET_INFO, "}",
                            OPEN_CURLY_BRACKET_TOKEN);
    }

    if (next === $SLASH) {
      return tokenizeSlashOrComment(next);
    }

    if (next === $AT) {
      return tokenizeRawString(next);
    }

    if (next === $DQ || next === $SQ) {
      return tokenizeString(next, byteOffset, false);
    }

    if (next === $PERIOD) {
      return tokenizeDotOrNumber(next);
    }

    if (next === $0) {
      return tokenizeHexOrNumber(next);
    }

    // TODO(ahe): Would a range check be faster?
    if (next === $1 || next === $2 || next === $3 || next === $4 ||  next === $5
        || next === $6 || next === $7 || next === $8 || next === $9) {
      return tokenizeNumber(next);
    }

    if (next === $EOF) {
      return $EOF;
    }
    if (next < 0x1f) {
      throw new MalformedInputException("illegal character $next", charOffset);
    }

    // The following are non-ASCII characters.

    if (next === $NBSP) {
      appendWhiteSpace(next);
      return advance();
    }

    return tokenizeIdentifier(next, byteOffset, true);
  }

  int tokenizeTag(int next) {
    // # or #!.*[\n\r]
    if (byteOffset === 0) {
      if (peek() === $BANG) {
        do {
          next = advance();
        } while (next !== $LF && next !== $CR && next !== $EOF);
        return next;
      }
    }
    appendPrecenceToken(HASH_INFO);
    return advance();
  }

  int tokenizeTilde(int next) {
    // ~ ~/ ~/=
    next = advance();
    if (next === $SLASH) {
      return select($EQ, TILDE_SLASH_EQ_INFO, TILDE_SLASH_INFO);
    } else {
      appendPrecenceToken(TILDE_INFO);
      return next;
    }
  }

  int tokenizeOpenSquareBracket(int next) {
    // [ [] []=
    next = advance();
    if (next === $CLOSE_SQUARE_BRACKET) {
      return select($EQ, INDEX_EQ_INFO, INDEX_INFO);
    } else {
      appendBeginGroup(OPEN_SQUARE_BRACKET_INFO, "[");
      return next;
    }
  }

  int tokenizeCaret(int next) {
    // ^ ^=
    return select($EQ, CARET_EQ_INFO, CARET_INFO);
  }

  int tokenizeBar(int next) {
    // | || |=
    next = advance();
    if (next === $BAR) {
      appendPrecenceToken(BAR_BAR_INFO);
      return advance();
    } else if (next === $EQ) {
      appendPrecenceToken(BAR_EQ_INFO);
      return advance();
    } else {
      appendPrecenceToken(BAR_INFO);
      return next;
    }
  }

  int tokenizeAmpersand(int next) {
    // && &= &
    next = advance();
    if (next === $AMPERSAND) {
      appendPrecenceToken(AMPERSAND_AMPERSAND_INFO);
      return advance();
    } else if (next === $EQ) {
      appendPrecenceToken(AMPERSAND_EQ_INFO);
      return advance();
    } else {
      appendPrecenceToken(AMPERSAND_INFO);
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
    if (next === $MINUS) {
      appendPrecenceToken(MINUS_MINUS_INFO);
      return advance();
    } else if (next === $EQ) {
      appendPrecenceToken(MINUS_EQ_INFO);
      return advance();
    } else {
      appendPrecenceToken(MINUS_INFO);
      return next;
    }
  }


  int tokenizePlus(int next) {
    // + ++ +=
    next = advance();
    if ($PLUS === next) {
      appendPrecenceToken(PLUS_PLUS_INFO);
      return advance();
    } else if ($EQ === next) {
      appendPrecenceToken(PLUS_EQ_INFO);
      return advance();
    } else {
      appendPrecenceToken(PLUS_INFO);
      return next;
    }
  }

  int tokenizeExclamation(int next) {
    // ! != !==
    next = advance();
    if (next === $EQ) {
      return select($EQ, BANG_EQ_EQ_INFO, BANG_EQ_INFO);
    }
    appendPrecenceToken(BANG_INFO);
    return next;
  }

  int tokenizeEquals(int next) {
    // = == ===
    next = advance();
    if (next === $EQ) {
      return select($EQ, EQ_EQ_EQ_INFO, EQ_EQ_INFO);
    } else if (next === $GT) {
      appendPrecenceToken(FUNCTION_INFO);
      return advance();
    }
    appendPrecenceToken(EQ_INFO);
    return next;
  }

  int tokenizeGreaterThan(int next) {
    // > >= >> >>= >>> >>>=
    next = advance();
    if ($EQ === next) {
      appendPrecenceToken(GT_EQ_INFO);
      return advance();
    } else if ($GT === next) {
      next = advance();
      if ($EQ === next) {
        appendPrecenceToken(GT_GT_EQ_INFO);
        return advance();
      } else if ($GT === next) {
        next = advance();
        if (next === $EQ) {
          appendPrecenceToken(GT_GT_GT_EQ_INFO);
          return advance();
        } else {
          appendGtGtGt(GT_GT_GT_INFO, ">>>");
          return next;
        }
      } else {
        appendGtGt(GT_GT_INFO, ">>");
        return next;
      }
    } else {
      appendGt(GT_INFO, ">");
      return next;
    }
  }

  int tokenizeLessThan(int next) {
    // < <= << <<=
    next = advance();
    if ($EQ === next) {
      appendPrecenceToken(LT_EQ_INFO);
      return advance();
    } else if ($LT === next) {
      return select($EQ, LT_LT_EQ_INFO, LT_LT_INFO);
    } else {
      appendBeginGroup(LT_INFO, "<");
      return next;
    }
  }

  int tokenizeNumber(int next) {
    int start = byteOffset;
    while (true) {
      next = advance();
      if ($0 <= next && next <= $9) {
        continue;
      } else if (next === $PERIOD) {
        return tokenizeFractionPart(advance(), start);
      } else if (next === $e || next === $E || next === $d || next === $D) {
        return tokenizeFractionPart(next, start);
      } else {
        appendByteStringToken(INT_INFO, asciiString(start, 0));
        return next;
      }
    }
  }

  int tokenizeHexOrNumber(int next) {
    int x = peek();
    if (x === $x || x === $X) {
      advance();
      return tokenizeHex(x);
    }
    return tokenizeNumber(next);
  }

  int tokenizeHex(int next) {
    int start = byteOffset - 1;
    bool hasDigits = false;
    while (true) {
      next = advance();
      if (($0 <= next && next <= $9)
          || ($A <= next && next <= $F)
          || ($a <= next && next <= $f)) {
        hasDigits = true;
      } else {
        if (!hasDigits) {
          throw new MalformedInputException("hex digit expected", charOffset);
        }
        appendByteStringToken(HEXADECIMAL_INFO, asciiString(start, 0));
        return next;
      }
    }
  }

  int tokenizeDotOrNumber(int next) {
    int start = byteOffset;
    next = advance();
    if (($0 <= next && next <= $9)) {
      return tokenizeFractionPart(next, start);
    } else if ($PERIOD === next) {
      return select($PERIOD, PERIOD_PERIOD_PERIOD_INFO, PERIOD_PERIOD_INFO);
    } else {
      appendPrecenceToken(PERIOD_INFO);
      return next;
    }
  }

  int tokenizeFractionPart(int next, int start) {
    bool done = false;
    bool hasDigit = false;
    LOOP: while (!done) {
      if ($0 <= next && next <= $9) {
        hasDigit = true;
      } else if ($e === next || $E === next) {
        hasDigit = true;
        next = tokenizeExponent(advance());
        done = true;
        continue LOOP;
      } else {
        done = true;
        continue LOOP;
      }
      next = advance();
    }
    if (!hasDigit) {
      appendByteStringToken(INT_INFO, asciiString(start, -1));
      // TODO(ahe): Wrong offset for the period.
      appendPrecenceToken(PERIOD_INFO);
      return bigSwitch(next);
    }
    if (next === $d || next === $D) {
      next = advance();
    }
    appendByteStringToken(DOUBLE_INFO, asciiString(start, 0));
    return next;
  }

  int tokenizeExponent(int next) {
    if (next === $PLUS || next === $MINUS) {
      next = advance();
    }
    bool hasDigits = false;
    while (true) {
      if ($0 <= next && next <= $9) {
        hasDigits = true;
      } else {
        if (!hasDigits) {
          throw new MalformedInputException("digit expected", charOffset);
        }
        return next;
      }
      next = advance();
    }
  }

  int tokenizeSlashOrComment(int next) {
    next = advance();
    if ($STAR === next) {
      return tokenizeMultiLineComment(next);
    } else if ($SLASH === next) {
      return tokenizeSingleLineComment(next);
    } else if ($EQ === next) {
      appendPrecenceToken(SLASH_EQ_INFO);
      return advance();
    } else {
      appendPrecenceToken(SLASH_INFO);
      return next;
    }
  }

  int tokenizeSingleLineComment(int next) {
    while (true) {
      next = advance();
      if ($LF === next || $CR === next || $EOF === next) {
        return next;
      }
    }
  }

  int tokenizeMultiLineComment(int next) {
    int nesting = 1;
    next = advance();
    while (true) {
      if ($EOF === next) {
        // TODO(ahe): Report error.
        return next;
      } else if ($STAR === next) {
        next = advance();
        if ($SLASH === next) {
          --nesting;
          if (0 === nesting) {
            return advance();
          } else {
            next = advance();
          }
        }
      } else if ($SLASH === next) {
        next = advance();
        if ($STAR === next) {
          next = advance();
          ++nesting;
        }
      } else {
        next = advance();
      }
    }
  }

  int tokenizeKeywordOrIdentifier(int next, bool allowDollar) {
    KeywordState state = KeywordState.KEYWORD_STATE;
    int start = byteOffset;
    while (state !== null && $a <= next && next <= $z) {
      state = state.next(next);
      next = advance();
    }
    if (state === null || state.keyword === null) {
      return tokenizeIdentifier(next, start, allowDollar);
    }
    if (($A <= next && next <= $Z) ||
        ($0 <= next && next <= $9) ||
        next === $_ ||
        next === $$) {
      return tokenizeIdentifier(next, start, allowDollar);
    } else if (next < 128) {
      appendKeywordToken(state.keyword);
      return next;
    } else {
      return tokenizeIdentifier(next, start, allowDollar);
    }
  }

  int tokenizeIdentifier(int next, int start, bool allowDollar) {
    bool isAscii = true;
    while (true) {
      if (($a <= next && next <= $z) ||
          ($A <= next && next <= $Z) ||
          ($0 <= next && next <= $9) ||
          next === $_ ||
          (next === $$ && allowDollar)) {
        next = advance();
      } else if (next < 128) {
        if (isAscii) {
          appendByteStringToken(IDENTIFIER_INFO, asciiString(start, 0));
        } else {
          appendByteStringToken(IDENTIFIER_INFO, utf8String(start, -1));
        }
        return next;
      } else {
        int nonAsciiStart = byteOffset;
        do {
          next = nextByte();
        } while (next > 127);
        String string = utf8String(nonAsciiStart, -1).slowToString();
        isAscii = false;
        int byteLength = nonAsciiStart - byteOffset;
        addToCharOffset(string.length - byteLength);
      }
    }
  }

  int tokenizeRawString(int next) {
    int start = byteOffset;
    next = advance();
    if (next === $DQ || next === $SQ) {
      return tokenizeString(next, start, true);
    } else {
      throw new MalformedInputException("expected ' or \"", charOffset);
    }
  }

  int tokenizeString(int next, int start, bool raw) {
    int quoteChar = next;
    next = advance();
    if (quoteChar === next) {
      next = advance();
      if (quoteChar === next) {
        // Multiline string.
        return tokenizeMultiLineString(quoteChar, start, raw);
      } else {
        // Empty string.
        appendByteStringToken(STRING_INFO, utf8String(start, -1));
        return next;
      }
    }
    if (raw) {
      return tokenizeSingleLineRawString(next, quoteChar, start);
    } else {
      return tokenizeSingleLineString(next, quoteChar, start);
    }
  }

  static bool isHexDigit(int character) {
    if ($0 <= character && character <= $9) return true;
    character |= 0x20;
    return ($a <= character && character <= $f);
  }

  int tokenizeSingleLineString(int next, int quoteChar, int start) {
    while (next !== quoteChar) {
      if (next === $BACKSLASH) {
        next = advance();
      } else if (next === $$) {
        next = tokenizeStringInterpolation(start);
        start = byteOffset;
        continue;
      }
      if (next <= $CR && (next === $LF || next === $CR || next === $EOF)) {
        throw new MalformedInputException("unterminated string literal",
                                          charOffset);
      }
      next = advance();
    }
    appendByteStringToken(STRING_INFO, utf8String(start, 0));
    return advance();
  }

  int tokenizeStringInterpolation(int start) {
    beginToken();
    int next = advance();
    if (next === $OPEN_CURLY_BRACKET) {
      return tokenizeInterpolatedExpression(next, start);
    } else {
      return tokenizeInterpolatedIdentifier(next, start);
    }
  }

  int tokenizeInterpolatedExpression(int next, int start) {
    appendByteStringToken(STRING_INFO, utf8String(start, -2));
    appendBeginGroup(STRING_INTERPOLATION_INFO, "\${");
    next = advance();
    while (next !== $EOF && next !== $STX) {
      next = bigSwitch(next);
    }
    if (next === $EOF) return next;
    return advance();
  }

  int tokenizeInterpolatedIdentifier(int next, int start) {
    appendByteStringToken(STRING_INFO, utf8String(start, -2));
    appendBeginGroup(STRING_INTERPOLATION_INFO, "\${");
    next = tokenizeKeywordOrIdentifier(next, false);
    appendEndGroup(CLOSE_CURLY_BRACKET_INFO, "}", OPEN_CURLY_BRACKET_TOKEN);
    return next;
  }

  int tokenizeSingleLineRawString(int next, int quoteChar, int start) {
    next = advance();
    while (next != $EOF) {
      if (next === quoteChar) {
        appendByteStringToken(STRING_INFO, utf8String(start, 0));
        return advance();
      } else if (next === $LF || next === $CR) {
        throw new MalformedInputException("unterminated string literal",
                                          charOffset);
      }
      next = advance();
    }
    throw new MalformedInputException("unterminated string literal",
                                      charOffset);
  }

  int tokenizeMultiLineRawString(int quoteChar, int start) {
    int next = advance();
    outer: while (next !== $EOF) {
      while (next !== quoteChar) {
        next = advance();
        if (next === $EOF) break outer;
      }
      next = advance();
      if (next === quoteChar) {
        next = advance();
        if (next === quoteChar) {
          appendByteStringToken(STRING_INFO, utf8String(start, 0));
          return advance();
        }
      }
    }
    throw new MalformedInputException("unterminated string literal",
                                      charOffset);
  }

  int tokenizeMultiLineString(int quoteChar, int start, bool raw) {
    if (raw) return tokenizeMultiLineRawString(quoteChar, start);
    int next = advance();
    while (next !== $EOF) {
      if (next === $$) {
        next = tokenizeStringInterpolation(start);
        start = byteOffset;
        continue;
      }
      if (next === quoteChar) {
        next = advance();
        if (next === quoteChar) {
          next = advance();
          if (next === quoteChar) {
            appendByteStringToken(STRING_INFO, utf8String(start, 0));
            return advance();
          }
        }
        continue;
      }
      if (next === $BACKSLASH) {
        next = advance();
        if (next === $EOF) break;
      }
      next = advance();
    }
    throw new MalformedInputException("unterminated string literal",
                                      charOffset);
  }
}

class MalformedInputException {
  final String message;
  final position;
  MalformedInputException(this.message, this.position);
  toString() => message;
}
