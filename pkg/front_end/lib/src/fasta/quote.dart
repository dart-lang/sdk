// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.quote;

import 'errors.dart' show inputError, internalError;

import 'scanner/characters.dart'
    show
        $BACKSLASH,
        $BS,
        $CLOSE_CURLY_BRACKET,
        $CR,
        $FF,
        $LF,
        $OPEN_CURLY_BRACKET,
        $SPACE,
        $TAB,
        $VTAB,
        $b,
        $f,
        $n,
        $r,
        $t,
        $u,
        $v,
        $x,
        hexDigitValue,
        isHexDigit;

enum Quote {
  Single,
  Double,
  MultiLineSingle,
  MultiLineDouble,
  RawSingle,
  RawDouble,
  RawMultiLineSingle,
  RawMultiLineDouble,
}

Quote analyzeQuote(String first) {
  if (first.startsWith('"""')) return Quote.MultiLineDouble;
  if (first.startsWith('r"""')) return Quote.RawMultiLineDouble;
  if (first.startsWith("'''")) return Quote.MultiLineSingle;
  if (first.startsWith("r'''")) return Quote.RawMultiLineSingle;
  if (first.startsWith('"')) return Quote.Double;
  if (first.startsWith('r"')) return Quote.RawDouble;
  if (first.startsWith("'")) return Quote.Single;
  if (first.startsWith("r'")) return Quote.RawSingle;
  return internalError("Unexpected string literal: $first");
}

// Note: based on [StringValidator.quotingFromString]
// (pkg/compiler/lib/src/string_validator.dart).
int lengthOfOptionalWhitespacePrefix(String first, int start) {
  List<int> codeUnits = first.codeUnits;
  for (int i = start; i < codeUnits.length; i++) {
    int code = codeUnits[i];
    if (code == $BACKSLASH) {
      i++;
      if (i < codeUnits.length) {
        code = codeUnits[i];
      } else {
        break;
      }
    }
    if (code == $TAB || code == $SPACE) continue;
    if (code == $CR) {
      if (i + 1 < codeUnits.length && codeUnits[i + 1] == $LF) {
        i++;
      }
      return i + 1;
    }
    if (code == $LF) {
      return i + 1;
    }
    break; // Not a white-space character.
  }
  return start;
}

int firstQuoteLength(String first, Quote quote) {
  switch (quote) {
    case Quote.Single:
    case Quote.Double:
      return 1;

    case Quote.MultiLineSingle:
    case Quote.MultiLineDouble:
      return lengthOfOptionalWhitespacePrefix(first, 3);

    case Quote.RawSingle:
    case Quote.RawDouble:
      return 2;

    case Quote.RawMultiLineSingle:
    case Quote.RawMultiLineDouble:
      return lengthOfOptionalWhitespacePrefix(first, 4);
  }
  return internalError("Unhandled string quote: $quote");
}

int lastQuoteLength(Quote quote) {
  switch (quote) {
    case Quote.Single:
    case Quote.Double:
    case Quote.RawSingle:
    case Quote.RawDouble:
      return 1;

    case Quote.MultiLineSingle:
    case Quote.MultiLineDouble:
    case Quote.RawMultiLineSingle:
    case Quote.RawMultiLineDouble:
      return 3;
  }
  return internalError("Unhandled string quote: $quote");
}

String unescapeFirstStringPart(String first, Quote quote) {
  return unescape(first.substring(firstQuoteLength(first, quote)), quote);
}

String unescapeLastStringPart(String last, Quote quote) {
  return unescape(
      last.substring(0, last.length - lastQuoteLength(quote)), quote);
}

String unescapeString(String string) {
  Quote quote = analyzeQuote(string);
  return unescape(
      string.substring(firstQuoteLength(string, quote),
          string.length - lastQuoteLength(quote)),
      quote);
}

String unescape(String string, Quote quote) {
  switch (quote) {
    case Quote.Single:
    case Quote.Double:
      return !string.contains("\\")
          ? string
          : unescapeCodeUnits(string.codeUnits, false);

    case Quote.MultiLineSingle:
    case Quote.MultiLineDouble:
      return !string.contains("\\") && !string.contains("\r")
          ? string
          : unescapeCodeUnits(string.codeUnits, false);

    case Quote.RawSingle:
    case Quote.RawDouble:
      return string;

    case Quote.RawMultiLineSingle:
    case Quote.RawMultiLineDouble:
      return !string.contains("\r")
          ? string
          : unescapeCodeUnits(string.codeUnits, true);
  }
  return internalError("Internal error: Unexpected quote: $quote.");
}

const String incompleteSequence = "Incomplete escape sequence.";

const String invalidCharacter = "Invalid character in escape sequence.";

const String invalidCodePoint = "Invalid code point.";

// Note: based on
// [StringValidator.validateString](pkg/compiler/lib/src/string_validator.dart).
String unescapeCodeUnits(List<int> codeUnits, bool isRaw) {
  // Can't use Uint8List or Uint16List here, the code units may be larger.
  List<int> result = new List<int>(codeUnits.length);
  int resultOffset = 0;
  error(int offset, String message) {
    inputError(null, null, message);
  }

  for (int i = 0; i < codeUnits.length; i++) {
    int code = codeUnits[i];
    if (code == $CR) {
      if (i + 1 < codeUnits.length && codeUnits[i + 1] == $LF) {
        i++;
      }
      code = $LF;
    } else if (!isRaw && code == $BACKSLASH) {
      if (codeUnits.length == ++i) return error(i, incompleteSequence);
      code = codeUnits[i];

      /// `\n` for newline, equivalent to `\x0A`.
      /// `\r` for carriage return, equivalent to `\x0D`.
      /// `\f` for form feed, equivalent to `\x0C`.
      /// `\b` for backspace, equivalent to `\x08`.
      /// `\t` for tab, equivalent to `\x09`.
      /// `\v` for vertical tab, equivalent to `\x0B`.
      /// `\xXX` for hex escape.
      /// `\uXXXX` or `\u{XX?X?X?X?X?}` for Unicode hex escape.
      if (code == $n) {
        code = $LF;
      } else if (code == $r) {
        code = $CR;
      } else if (code == $f) {
        code = $FF;
      } else if (code == $b) {
        code = $BS;
      } else if (code == $t) {
        code = $TAB;
      } else if (code == $v) {
        code = $VTAB;
      } else if (code == $x) {
        // Expect exactly 2 hex digits.
        if (codeUnits.length <= i + 2) return error(i, incompleteSequence);
        code = 0;
        for (int j = 0; j < 2; j++) {
          int digit = codeUnits[++i];
          if (!isHexDigit(digit)) return error(i, invalidCharacter);
          code = (code << 4) + hexDigitValue(digit);
        }
      } else if (code == $u) {
        if (codeUnits.length == i + 1) return error(i, incompleteSequence);
        code = codeUnits[i + 1];
        if (code == $OPEN_CURLY_BRACKET) {
          // Expect 1-6 hex digits followed by '}'.
          if (codeUnits.length == ++i) return error(i, incompleteSequence);
          code = 0;
          for (int j = 0; j < 7; j++) {
            if (codeUnits.length == ++i) return error(i, incompleteSequence);
            int digit = codeUnits[i];
            if (j != 0 && digit == $CLOSE_CURLY_BRACKET) break;
            if (!isHexDigit(digit)) return error(i, invalidCharacter);
            code = (code << 4) + hexDigitValue(digit);
          }
        } else {
          // Expect exactly 4 hex digits.
          if (codeUnits.length <= i + 4) return error(i, incompleteSequence);
          code = 0;
          for (int j = 0; j < 4; j++) {
            int digit = codeUnits[++i];
            if (!isHexDigit(digit)) return error(i, invalidCharacter);
            code = (code << 4) + hexDigitValue(digit);
          }
        }
      } else {
        // Nothing, escaped character is passed through;
      }
      if (code > 0x10FFFF) return error(i, invalidCodePoint);
    }
    result[resultOffset++] = code;
  }
  return new String.fromCharCodes(result, 0, resultOffset);
}
