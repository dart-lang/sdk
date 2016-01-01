// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check the validity of string literals.

library stringvalidator;

import 'dart:collection';

import 'common.dart';
import 'tokens/token.dart' show Token;
import 'tree/tree.dart';
import 'util/characters.dart';

class StringValidator {
  final DiagnosticReporter reporter;

  StringValidator(this.reporter);

  DartString validateInterpolationPart(Token token, StringQuoting quoting,
                                       {bool isFirst: false,
                                        bool isLast: false}) {
    String source = token.value;
    int leftQuote = 0;
    int rightQuote = 0;
    if (isFirst) leftQuote = quoting.leftQuoteLength;
    if (isLast) rightQuote = quoting.rightQuoteLength;
    String content = copyWithoutQuotes(source, leftQuote, rightQuote);
    return validateString(token,
                          token.charOffset + leftQuote,
                          content,
                          quoting);
  }

  static StringQuoting quotingFromString(String sourceString) {
    Iterator<int> source = sourceString.codeUnits.iterator;
    bool raw = false;
    int leftQuoteLength = 1;
    source.moveNext();
    int quoteChar = source.current;
    if (quoteChar == $r) {
      raw = true;
      source.moveNext();
      quoteChar = source.current;
    }
    assert(quoteChar == $SQ || quoteChar == $DQ);
    // String has at least one quote. Check it if has three.
    // If it only has two, the string must be an empty string literal,
    // and end after the second quote.
    if (source.moveNext() && source.current == quoteChar && source.moveNext()) {
      int code = source.current;
      assert(code == quoteChar);  // If not, there is a bug in the parser.
      leftQuoteLength = 3;

      // Check if a multiline string starts with optional whitespace followed by
      // a newline (CR, LF or CR+LF).
      // We also accept if the these characters are escaped by a backslash.
      int newLineLength = 1;
      while (true) {
        // Due to string-interpolations we are not guaranteed to see the
        // trailing quoting characters. The invocations to `moveNext()` may
        // therefore return false and the `current`-getter return `null`. The
        // code does not need to handle this specially (as it will not find the
        // newline characters).
        source.moveNext();
        code = source.current;
        if (code == $BACKSLASH) {
          newLineLength++;
          source.moveNext();
          code = source.current;
        }
        if (code == $TAB || code == $SPACE) {
          newLineLength++;
          continue;
        }
        if (code == $CR) {
          if (source.moveNext() && source.current == $LF) {
            newLineLength++;
          }
          leftQuoteLength += newLineLength;
        } else if (code == $LF) {
          leftQuoteLength += newLineLength;
        }
        break;
      }
    }
    return StringQuoting.getQuoting(quoteChar, raw, leftQuoteLength);
  }

  /**
   * Return the string [string] witout its [initial] first and [terminal] last
   * characters. This is intended to be used to remove quotes from string
   * literals (including an initial 'r' for raw strings).
   */
  String copyWithoutQuotes(String string, int initial, int terminal) {
    assert(0 <= initial);
    assert(0 <= terminal);
    assert(initial + terminal <= string.length);
    return string.substring(initial, string.length - terminal);
  }

  void stringParseError(String message, Token token, int offset) {
    reporter.reportErrorMessage(
        token, MessageKind.GENERIC, {'text': "$message @ $offset"});
  }

  /**
   * Validates the escape sequences and special characters of a string literal.
   * Returns a DartString if valid, and null if not.
   */
  DartString validateString(Token token,
                            int startOffset,
                            String string,
                            StringQuoting quoting) {
    // We need to check for invalid x and u escapes, for line
    // terminators in non-multiline strings, and for invalid Unicode
    // scalar values (either directly or as u-escape values).  We also check
    // for unpaired UTF-16 surrogates.
    int length = 0;
    int index = startOffset;
    bool containsEscape = false;
    bool previousWasLeadSurrogate = false;
    bool invalidUtf16 = false;
    var stringIter = string.codeUnits.iterator;
    for(HasNextIterator<int> iter = new HasNextIterator(stringIter);
        iter.hasNext;
        length++) {
      index++;
      int code = iter.next();
      if (code == $BACKSLASH) {
        if (quoting.raw) continue;
        containsEscape = true;
        if (!iter.hasNext) {
          stringParseError("Incomplete escape sequence",token, index);
          return null;
        }
        index++;
        code = iter.next();
        if (code == $x) {
          for (int i = 0; i < 2; i++) {
            if (!iter.hasNext) {
              stringParseError("Incomplete escape sequence", token, index);
              return null;
            }
            index++;
            code = iter.next();
            if (!isHexDigit(code)) {
              stringParseError("Invalid character in escape sequence",
                               token, index);
              return null;
            }
          }
          // A two-byte hex escape can't generate an invalid value.
          continue;
        } else if (code == $u) {
          index++;
          code = iter.hasNext ? iter.next() : 0;
          int value = 0;
          if (code == $OPEN_CURLY_BRACKET) {
            // expect 1-6 hex digits.
            int count = 0;
            while (iter.hasNext) {
              code = iter.next();
              index++;
              if (code == $CLOSE_CURLY_BRACKET) {
                break;
              }
              if (!isHexDigit(code)) {
                stringParseError("Invalid character in escape sequence",
                                 token, index);
                return null;
              }
              count++;
              value = value * 16 + hexDigitValue(code);
            }
            if (code != $CLOSE_CURLY_BRACKET || count == 0 || count > 6) {
              int errorPosition = index - count;
              if (count > 6) errorPosition += 6;
              stringParseError("Invalid character in escape sequence",
                               token, errorPosition);
              return null;
            }
          } else {
            // Expect four hex digits, including the one just read.
            for (int i = 0; i < 4; i++) {
              if (i > 0) {
                if (iter.hasNext) {
                  index++;
                  code = iter.next();
                } else {
                  code = 0;
                }
              }
              if (!isHexDigit(code)) {
                stringParseError("Invalid character in escape sequence",
                                 token, index);
                return null;
              }
              value = value * 16 + hexDigitValue(code);
            }
          }
          code = value;
        }
      }
      if (code >= 0x10000) length++;
      // This handles both unescaped characters and the value of unicode
      // escapes.
      if (previousWasLeadSurrogate) {
        if (!isUtf16TrailSurrogate(code)) {
          invalidUtf16 = true;
          break;
        }
        previousWasLeadSurrogate = false;
      } else if (isUtf16LeadSurrogate(code)) {
        previousWasLeadSurrogate = true;
      } else if (!isUnicodeScalarValue(code)) {
        invalidUtf16 = true;
        break;
      }
    }
    if (previousWasLeadSurrogate || invalidUtf16) {
      stringParseError("Invalid Utf16 surrogate", token, index);
      return null;
    }
    // String literal successfully validated.
    if (quoting.raw || !containsEscape) {
      // A string without escapes could just as well have been raw.
      return new DartString.rawString(string, length);
    }
    return new DartString.escapedString(string, length);
  }
}
