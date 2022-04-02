// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.15

// Utilities for converting between JavaScript source-code Strings and the
// String value they represent.

import 'characters.dart' as char_codes;

class StringToSourceKind {
  /// [true] if preferable to use double quotes, [false] if preferable to use
  /// single quotes.
  final bool doubleQuotes;

  /// [true] if contents require no escaping with the preferred quoting.
  final bool simple;

  const StringToSourceKind({required this.doubleQuotes, required this.simple});

  String get quote => doubleQuotes ? '"' : "'";
}

class StringToSource {
  const StringToSource();

  static StringToSourceKind analyze(String value, {required bool utf8}) {
    final ascii = !utf8;
    int singleQuotes = 0;
    int doubleQuotes = 0;
    int otherEscapes = 0;
    int unpairedSurrogates = 0;

    for (int rune in value.runes) {
      if (rune == char_codes.$BACKSLASH) {
        ++otherEscapes;
      } else if (rune == char_codes.$SQ) {
        ++singleQuotes;
      } else if (rune == char_codes.$DQ) {
        ++doubleQuotes;
      } else if (rune == char_codes.$LF ||
          rune == char_codes.$CR ||
          rune == char_codes.$LS ||
          rune == char_codes.$PS) {
        // Line terminators.
        ++otherEscapes;
      } else if (rune == char_codes.$BS ||
          rune == char_codes.$TAB ||
          rune == char_codes.$VTAB ||
          rune == char_codes.$FF) {
        ++otherEscapes;
      } else if (ascii &&
          (rune < char_codes.$SPACE || rune >= char_codes.$DEL)) {
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
      {required bool utf8}) {
    for (int rune in string.runes) {
      String? escape = _irregularEscape(rune, kind.doubleQuotes);
      if (escape != null) {
        sb.write(escape);
        continue;
      }
      if (rune == char_codes.$LS ||
          rune == char_codes.$PS ||
          _isUnpairedSurrogate(rune) ||
          !utf8 && (rune < char_codes.$SPACE || rune >= char_codes.$DEL)) {
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

  static String? _irregularEscape(int code, bool useDoubleQuotes) {
    switch (code) {
      case char_codes.$SQ:
        return useDoubleQuotes ? r"'" : r"\'";
      case char_codes.$DQ:
        return useDoubleQuotes ? r'\"' : r'"';
      case char_codes.$BACKSLASH:
        return r'\\';
      case char_codes.$BS:
        return r'\b';
      case char_codes.$TAB:
        return r'\t';
      case char_codes.$LF:
        return r'\n';
      case char_codes.$VTAB:
        return r'\v';
      case char_codes.$FF:
        return r'\f';
      case char_codes.$CR:
        return r'\r';
    }
    return null;
  }
}
