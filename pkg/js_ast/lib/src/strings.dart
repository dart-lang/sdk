// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Utilities for converting between JavaScript source-code Strings and the
// String value they represent.

import 'characters.dart' as charCodes;

class StringToSourceKind {
  /// [true] if preferable to use double quotes, [false] if preferable to use
  /// single quotes.
  final bool doubleQuotes;

  /// [true] if contents require no escaping with the preferred quoting.
  final bool simple;

  const StringToSourceKind({this.doubleQuotes, this.simple});

  String get quote => doubleQuotes ? '"' : "'";
}

class StringToSource {
  const StringToSource();

  static StringToSourceKind analyze(String value, {/*required*/ bool utf8}) {
    final ascii = !utf8;
    int singleQuotes = 0;
    int doubleQuotes = 0;
    int otherEscapes = 0;
    int unpairedSurrogates = 0;

    for (int rune in value.runes) {
      if (rune == charCodes.$BACKSLASH) {
        ++otherEscapes;
      } else if (rune == charCodes.$SQ) {
        ++singleQuotes;
      } else if (rune == charCodes.$DQ) {
        ++doubleQuotes;
      } else if (rune == charCodes.$LF ||
          rune == charCodes.$CR ||
          rune == charCodes.$LS ||
          rune == charCodes.$PS) {
        // Line terminators.
        ++otherEscapes;
      } else if (rune == charCodes.$BS ||
          rune == charCodes.$TAB ||
          rune == charCodes.$VTAB ||
          rune == charCodes.$FF) {
        ++otherEscapes;
      } else if (ascii && (rune < charCodes.$SPACE || rune >= charCodes.$DEL)) {
        ++otherEscapes;
      } else if (_isUnpairedSurrogate(rune)) {
        // Need to escape unpaired surrogates in a UTF8-encoded output otherwise
        // the output would be malformed.
        ++unpairedSurrogates;
      }
    }

    if (otherEscapes == 0 && unpairedSurrogates == 0) {
      if (doubleQuotes == 0) {
        return const StringToSourceKind(doubleQuotes: true, simple: true);
      }
      if (singleQuotes == 0) {
        return const StringToSourceKind(doubleQuotes: false, simple: true);
      }
    }

    return doubleQuotes <= singleQuotes
        ? const StringToSourceKind(doubleQuotes: true, simple: false)
        : const StringToSourceKind(doubleQuotes: false, simple: false);
  }

  static void writeString(
      StringBuffer sb, String string, StringToSourceKind kind,
      {/*required*/ bool utf8}) {
    for (int rune in string.runes) {
      String escape = _irregularEscape(rune, kind.doubleQuotes);
      if (escape != null) {
        sb.write(escape);
        continue;
      }
      if (rune == charCodes.$LS ||
          rune == charCodes.$PS ||
          _isUnpairedSurrogate(rune) ||
          !utf8 && (rune < charCodes.$SPACE || rune >= charCodes.$DEL)) {
        if (rune < 0x100) {
          sb.write(r'\x');
          sb.write(rune.toRadixString(16).padLeft(2, '0'));
        } else if (rune < 0x10000) {
          sb.write(r'\u');
          sb.write(rune.toRadixString(16).padLeft(4, '0'));
        } else {
          // Not all browsers accept the ES6 \u{zzzzzz} encoding, so emit two
          // surrogate pairs.
          var bits = rune - 0x10000;
          var leading = 0xD800 | (bits >> 10);
          var trailing = 0xDC00 | (bits & 0x3ff);
          sb.write(r'\u');
          sb.write(leading.toRadixString(16));
          sb.write(r'\u');
          sb.write(trailing.toRadixString(16));
        }
      } else {
        sb.writeCharCode(rune);
      }
    }
  }

  static bool _isUnpairedSurrogate(int code) => (code & 0xFFFFF800) == 0xD800;

  static String _irregularEscape(int code, bool useDoubleQuotes) {
    switch (code) {
      case charCodes.$SQ:
        return useDoubleQuotes ? r"'" : r"\'";
      case charCodes.$DQ:
        return useDoubleQuotes ? r'\"' : r'"';
      case charCodes.$BACKSLASH:
        return r'\\';
      case charCodes.$BS:
        return r'\b';
      case charCodes.$TAB:
        return r'\t';
      case charCodes.$LF:
        return r'\n';
      case charCodes.$VTAB:
        return r'\v';
      case charCodes.$FF:
        return r'\f';
      case charCodes.$CR:
        return r'\r';
    }
    return null;
  }
}
