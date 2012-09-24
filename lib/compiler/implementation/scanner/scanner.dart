// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Scanner {
  Token tokenize();
}

/**
 * Common base class for a Dart scanner.
 */
class AbstractScanner<T extends SourceString> implements Scanner {
  abstract int advance();
  abstract int nextByte();

  /**
   * Returns the current character or byte depending on the underlying input
   * kind. For example, [StringScanner] operates on [String] and thus returns
   * characters (Unicode codepoints represented as int) whereas
   * [ByteArrayScanner] operates on byte arrays and thus returns bytes.
   */
  abstract int peek();

  /**
   * Appends a fixed token based on whether the current char is [choice] or not.
   * If the current char is [choice] a fixed token whose kind and content
   * is determined by [yes] is appended, otherwise a fixed token whose kind
   * and content is determined by [no] is appended.
   */
  abstract int select(int choice, PrecedenceInfo yes, PrecedenceInfo no);

  /**
   * Appends a fixed token whose kind and content is determined by [info].
   */
  abstract void appendPrecedenceToken(PrecedenceInfo info);

  /**
   * Appends a token whose kind is determined by [info] and content is [value].
   */
  abstract void appendStringToken(PrecedenceInfo info, String value);

  /**
   * Appends a token whose kind is determined by [info] and content is defined
   * by the SourceString [value].
   */
  abstract void appendByteStringToken(PrecedenceInfo info, T value);

  /**
   * Appends a keyword token whose kind is determined by [keyword].
   */
  abstract void appendKeywordToken(Keyword keyword);
  abstract void appendWhiteSpace(int next);
  abstract void appendEofToken();

  /**
   * Creates an ASCII SourceString whose content begins at the source byte
   * offset [start] and ends at [offset] bytes from the current byte offset of
   * the scanner. For example, if the current byte offset is 10,
   * [:asciiString(0,-1):] creates an ASCII SourceString whose content is found
   * at the [0,9[ byte interval of the source text.
   */
  abstract T asciiString(int start, int offset);
  abstract T utf8String(int start, int offset);
  abstract Token firstToken();
  abstract Token previousToken();
  abstract void beginToken();
  abstract void addToCharOffset(int offset);
  abstract int get charOffset;
  abstract int get byteOffset;
  abstract void appendBeginGroup(PrecedenceInfo info, String value);
  abstract int appendEndGroup(PrecedenceInfo info, String value, int openKind);
  abstract void appendGt(PrecedenceInfo info, String value);
  abstract void appendGtGt(PrecedenceInfo info, String value);
  abstract void appendGtGtGt(PrecedenceInfo info, String value);
  abstract void appendComment();

  /**
   * We call this method to discard '<' from the "grouping" stack
   * (maintained by subclasses).
   *
   * [PartialParser.skipExpression] relies on the fact that we do not
   * create groups for stuff like:
   * [:a = b < c, d = e > f:].
   *
   * In other words, this method is called when the scanner recognizes
   * something which cannot possibly be part of a type
   * parameter/argument list.
   */
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
    if (next === $SPACE || next === $TAB || next === $LF || next === $CR) {
      appendWhiteSpace(next);
      next = advance();
      while (next === $SPACE) {
        appendWhiteSpace(next);
        next = advance();
      }
      return next;
    }

    if ($a <= next && next <= $z) {
      if ($r === next) {
        return tokenizeRawStringKeywordOrIdentifier(next);
      }
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
      appendPrecedenceToken(BACKSLASH_INFO);
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
      appendPrecedenceToken(COMMA_INFO);
      return advance();
    }

    if (next === $COLON) {
      appendPrecedenceToken(COLON_INFO);
      return advance();
    }

    if (next === $SEMICOLON) {
      appendPrecedenceToken(SEMICOLON_INFO);
      // Type parameters and arguments cannot contain semicolon.
      discardOpenLt();
      return advance();
    }

    if (next === $QUESTION) {
      appendPrecedenceToken(QUESTION_INFO);
      return advance();
    }

    if (next === $CLOSE_SQUARE_BRACKET) {
      return appendEndGroup(CLOSE_SQUARE_BRACKET_INFO, "]",
                            OPEN_SQUARE_BRACKET_TOKEN);
    }

    if (next === $BACKPING) {
      appendPrecedenceToken(BACKPING_INFO);
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

    // TODO(aprelev@gmail.com) Remove deprecated raw string literals
    if (next === $AT) {
      return tokenizeAtOrRawString(next);
    }

    if (next === $DQ || next === $SQ) {
      return tokenizeString(next, byteOffset, false);
    }

    if (next === $PERIOD) {
      return tokenizeDotsOrNumber(next);
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
      return error(new SourceString("unexpected character $next"));
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
    appendPrecedenceToken(HASH_INFO);
    return advance();
  }

  int tokenizeTilde(int next) {
    // ~ ~/ ~/=
    next = advance();
    if (next === $SLASH) {
      return select($EQ, TILDE_SLASH_EQ_INFO, TILDE_SLASH_INFO);
    } else {
      appendPrecedenceToken(TILDE_INFO);
      return next;
    }
  }

  int tokenizeOpenSquareBracket(int next) {
    // [ [] []=
    next = advance();
    if (next === $CLOSE_SQUARE_BRACKET) {
      Token token = previousToken();
      if (token is KeywordToken && token.value.stringValue === 'operator') {
        return select($EQ, INDEX_EQ_INFO, INDEX_INFO);
      }
    }
    appendBeginGroup(OPEN_SQUARE_BRACKET_INFO, "[");
    return next;
  }

  int tokenizeCaret(int next) {
    // ^ ^=
    return select($EQ, CARET_EQ_INFO, CARET_INFO);
  }

  int tokenizeBar(int next) {
    // | || |=
    next = advance();
    if (next === $BAR) {
      appendPrecedenceToken(BAR_BAR_INFO);
      return advance();
    } else if (next === $EQ) {
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
    if (next === $AMPERSAND) {
      appendPrecedenceToken(AMPERSAND_AMPERSAND_INFO);
      return advance();
    } else if (next === $EQ) {
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
    if (next === $MINUS) {
      appendPrecedenceToken(MINUS_MINUS_INFO);
      return advance();
    } else if (next === $EQ) {
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
    if ($PLUS === next) {
      appendPrecedenceToken(PLUS_PLUS_INFO);
      return advance();
    } else if ($EQ === next) {
      appendPrecedenceToken(PLUS_EQ_INFO);
      return advance();
    } else {
      appendPrecedenceToken(PLUS_INFO);
      return next;
    }
  }

  int tokenizeExclamation(int next) {
    // ! != !==
    next = advance();
    if (next === $EQ) {
      return select($EQ, BANG_EQ_EQ_INFO, BANG_EQ_INFO);
    }
    appendPrecedenceToken(BANG_INFO);
    return next;
  }

  int tokenizeEquals(int next) {
    // = == ===

    // Type parameters and arguments cannot contain any token that
    // starts with '='.
    discardOpenLt();

    next = advance();
    if (next === $EQ) {
      return select($EQ, EQ_EQ_EQ_INFO, EQ_EQ_INFO);
    } else if (next === $GT) {
      appendPrecedenceToken(FUNCTION_INFO);
      return advance();
    }
    appendPrecedenceToken(EQ_INFO);
    return next;
  }

  int tokenizeGreaterThan(int next) {
    // > >= >> >>= >>> >>>=
    next = advance();
    if ($EQ === next) {
      appendPrecedenceToken(GT_EQ_INFO);
      return advance();
    } else if ($GT === next) {
      next = advance();
      if ($EQ === next) {
        appendPrecedenceToken(GT_GT_EQ_INFO);
        return advance();
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
      appendPrecedenceToken(LT_EQ_INFO);
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
          return error(const SourceString("hex digit expected"));
        }
        appendByteStringToken(HEXADECIMAL_INFO, asciiString(start, 0));
        return next;
      }
    }
  }

  int tokenizeDotsOrNumber(int next) {
    int start = byteOffset;
    next = advance();
    if (($0 <= next && next <= $9)) {
      return tokenizeFractionPart(next, start);
    } else if ($PERIOD === next) {
      return select($PERIOD, PERIOD_PERIOD_PERIOD_INFO, PERIOD_PERIOD_INFO);
    } else {
      appendPrecedenceToken(PERIOD_INFO);
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
      if ($PERIOD === next) {
        return select($PERIOD, PERIOD_PERIOD_PERIOD_INFO, PERIOD_PERIOD_INFO);
      }
      // TODO(ahe): Wrong offset for the period.
      appendPrecedenceToken(PERIOD_INFO);
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
          return error(const SourceString("digit expected"));
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
      appendPrecedenceToken(SLASH_EQ_INFO);
      return advance();
    } else {
      appendPrecedenceToken(SLASH_INFO);
      return next;
    }
  }

  int tokenizeSingleLineComment(int next) {
    while (true) {
      next = advance();
      if ($LF === next || $CR === next || $EOF === next) {
        appendComment();
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
            next = advance();
            appendComment();
            return next;
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

  int tokenizeRawStringKeywordOrIdentifier(int next) {
    int nextnext = peek();
    if (nextnext === $DQ || nextnext === $SQ) {
      int start = byteOffset;
      next = advance();
      return tokenizeString(next, start, true);
    }
    return tokenizeKeywordOrIdentifier(next, true);
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
    bool isDynamicBuiltIn = false;

    if (next === $D) {
      next = advance();
      if (next === $y) {
        next = advance();
        if (next === $n) {
          next = advance();
          if (next === $a) {
            next = advance();
            if (next === $m) {
              next = advance();
              if (next === $i) {
                next = advance();
                if (next === $c) {
                  isDynamicBuiltIn = true;
                  next = advance();
                }
              }
            }
          }
        }
      }
    }

    while (true) {
      if (($a <= next && next <= $z) ||
          ($A <= next && next <= $Z) ||
          ($0 <= next && next <= $9) ||
          next === $_ ||
          (next === $$ && allowDollar)) {
        isDynamicBuiltIn = false;
        next = advance();
      } else if ((next < 128) || (next === $NBSP)) {
        // Identifier ends here.
        if (start == byteOffset) {
          return error(const SourceString("expected identifier"));
        } else if (isDynamicBuiltIn) {
          appendKeywordToken(Keyword.DYNAMIC);
        } else if (isAscii) {
          appendByteStringToken(IDENTIFIER_INFO, asciiString(start, 0));
        } else {
          appendByteStringToken(BAD_INPUT_INFO, utf8String(start, -1));
        }
        return next;
      } else {
        isDynamicBuiltIn = false;
        int nonAsciiStart = byteOffset;
        do {
          next = nextByte();
          if (next === $NBSP) break;
        } while (next > 127);
        String string = utf8String(nonAsciiStart, -1).slowToString();
        isAscii = false;
        int byteLength = nonAsciiStart - byteOffset;
        addToCharOffset(string.length - byteLength);
      }
    }
  }

  int tokenizeAtOrRawString(int next) {
    int start = byteOffset;
    next = advance();
    if (next === $DQ || next === $SQ) {
      return tokenizeString(next, start, true);
    } else {
      appendPrecedenceToken(AT_INFO);
      return next;
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
        return error(const SourceString("unterminated string literal"));
      }
      next = advance();
    }
    appendByteStringToken(STRING_INFO, utf8String(start, 0));
    return advance();
  }

  int tokenizeStringInterpolation(int start) {
    appendByteStringToken(STRING_INFO, utf8String(start, -1));
    beginToken(); // $ starts here.
    int next = advance();
    if (next === $OPEN_CURLY_BRACKET) {
      return tokenizeInterpolatedExpression(next, start);
    } else {
      return tokenizeInterpolatedIdentifier(next, start);
    }
  }

  int tokenizeInterpolatedExpression(int next, int start) {
    appendBeginGroup(STRING_INTERPOLATION_INFO, "\${");
    beginToken(); // The expression starts here.
    next = advance();
    while (next !== $EOF && next !== $STX) {
      next = bigSwitch(next);
    }
    if (next === $EOF) return next;
    next = advance();
    beginToken(); // The string interpolation suffix starts here.
    return next;
  }

  int tokenizeInterpolatedIdentifier(int next, int start) {
    appendPrecedenceToken(STRING_INTERPOLATION_IDENTIFIER_INFO);
    beginToken(); // The identifier starts here.
    next = tokenizeKeywordOrIdentifier(next, false);
    beginToken(); // The string interpolation suffix starts here.
    return next;
  }

  int tokenizeSingleLineRawString(int next, int quoteChar, int start) {
    next = advance();
    while (next != $EOF) {
      if (next === quoteChar) {
        appendByteStringToken(STRING_INFO, utf8String(start, 0));
        return advance();
      } else if (next === $LF || next === $CR) {
        return error(const SourceString("unterminated string literal"));
      }
      next = advance();
    }
    return error(const SourceString("unterminated string literal"));
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
    return error(const SourceString("unterminated string literal"));
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
    return error(const SourceString("unterminated string literal"));
  }

  int error(SourceString message) {
    appendByteStringToken(BAD_INPUT_INFO, message);
    return advance(); // Ensure progress.
  }
}
