// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Decode a lax JSON encoded text, that is, JSON with Dart-like comments and
/// trailing commas.
///
/// This is used together with `load.dart` and `save.dart` to allow for an easy
/// editing of a human-readable source-map file.

library lazon;

decode(String text) {
  return new _Decoder(text)._decode();
}

class _Decoder {
  static final int LF = '\n'.codeUnits.single;
  static final int CR = '\r'.codeUnits.single;
  static final int BACKSPACE = '\b'.codeUnits.single;
  static final int FORMFEED = '\f'.codeUnits.single;
  static final int TAB = '\t'.codeUnits.single;
  static final int SPACE = ' '.codeUnits.single;
  static final int SLASH = '/'.codeUnits.single;
  static final int STAR = '*'.codeUnits.single;
  static final int QUOTE = '"'.codeUnits.single;
  static final int BACKSLASH = '\\'.codeUnits.single;
  static final int COMMA = ','.codeUnits.single;
  static final int COLON = ':'.codeUnits.single;
  static final int LEFT_BRACE = '{'.codeUnits.single;
  static final int RIGHT_BRACE = '}'.codeUnits.single;
  static final int LEFT_BRACKET = '['.codeUnits.single;
  static final int RIGHT_BRACKET = ']'.codeUnits.single;
  static final int T = 't'.codeUnits.single;
  static final List<int> TRUE = 'true'.codeUnits;
  static final int F = 'f'.codeUnits.single;
  static final List<int> FALSE = 'false'.codeUnits;
  static final int N = 'n'.codeUnits.single;
  static final List<int> NULL = 'null'.codeUnits;
  static final int B = 'b'.codeUnits.single;
  static final int R = 'r'.codeUnits.single;
  static final int U = 'u'.codeUnits.single;

  final List<int> codeUnits;
  final int length;
  int position = 0;

  _Decoder(String text)
      : codeUnits = text.codeUnits,
        length = text.length;

  _decode() {
    var result = _decodeValue();
    _trimWhitespace();
    if (position != codeUnits.length) {
      throw new ArgumentError("Unexpected trailing text: "
          "'${new String.fromCharCodes(codeUnits, position)}'.");
    }
    return result;
  }

  _decodeValue() {
    var result;
    _trimWhitespace();
    if (position < codeUnits.length) {
      int codeUnit = codeUnits[position];
      if (codeUnit == QUOTE) {
        result = _decodeString();
      } else if (codeUnit == LEFT_BRACE) {
        result = _decodeMap();
      } else if (codeUnit == LEFT_BRACKET) {
        result = _decodeList();
      } else if (codeUnit == T) {
        result = _decodeTrue();
      } else if (codeUnit == F) {
        result = _decodeFalse();
      } else if (codeUnit == N) {
        result = _decodeNull();
      } else {
        result = _decodeNumber();
      }
    } else {
      throw new ArgumentError("No value found in text: "
          "'${new String.fromCharCodes(codeUnits, 0)}'.");
    }
    return result;
  }

  void _trimWhitespace() {
    OUTER:
    while (position < codeUnits.length) {
      int codeUnit = codeUnits[position];
      if (codeUnit == SLASH) {
        if (position + 1 < codeUnits.length) {
          int nextCodeUnit = codeUnits[position + 1];
          if (nextCodeUnit == SLASH) {
            position += 2;
            while (position < codeUnits.length) {
              codeUnit = codeUnits[position];
              if (codeUnit == LF || codeUnit == CR) {
                continue OUTER;
              }
              position++;
            }
          } else if (nextCodeUnit == STAR) {
            position += 2;
            while (position < codeUnits.length) {
              codeUnit = codeUnits[position];
              if (codeUnit == STAR &&
                  position + 1 < codeUnits.length &&
                  codeUnits[position + 1] == SLASH) {
                position += 2;
                continue OUTER;
              }
              position++;
            }
          }
        }
        break;
      } else if (codeUnit == LF ||
          codeUnit == CR ||
          codeUnit == TAB ||
          codeUnit == SPACE) {
        position++;
      } else {
        break;
      }
    }
  }

  String _decodeString() {
    int codeUnit = codeUnits[position];
    if (codeUnit != QUOTE) {
      _fail();
    }
    position++;
    List<int> charCodes = <int>[];
    while (position < length) {
      codeUnit = codeUnits[position];
      if (codeUnit == QUOTE) {
        break;
      } else if (codeUnit == BACKSLASH) {
        if (position + 1 >= length) {
          _fail();
        }
        codeUnit = codeUnits[++position];
        if (codeUnit == B) {
          codeUnit = BACKSPACE;
        } else if (codeUnit == F) {
          codeUnit = FORMFEED;
        } else if (codeUnit == N) {
          codeUnit = LF;
        } else if (codeUnit == R) {
          codeUnit = CR;
        } else if (codeUnit == T) {
          codeUnit = TAB;
        } else if (codeUnit == U) {
          throw new UnsupportedError('unicode escapes');
        } else if (codeUnit == QUOTE ||
            codeUnit == SLASH ||
            codeUnit == BACKSLASH) {
          // Ok.
        } else {
          _fail();
        }
      }
      charCodes.add(codeUnit);
      position++;
    }
    if (codeUnit != QUOTE) {
      _fail();
    }
    position++;
    return new String.fromCharCodes(charCodes);
  }

  Map _decodeMap() {
    int codeUnit = codeUnits[position];
    if (codeUnit != LEFT_BRACE) {
      _fail();
    }
    position++;
    _trimWhitespace();
    Map result = {};
    while (position < length) {
      codeUnit = codeUnits[position];
      if (codeUnit == RIGHT_BRACE) {
        break;
      }
      String key = _decodeString();
      _trimWhitespace();
      if (position < length) {
        codeUnit = codeUnits[position];
        if (codeUnit == COLON) {
          position++;
          _trimWhitespace();
        } else {
          _fail();
        }
      } else {
        _fail();
      }
      var value = _decodeValue();
      result[key] = value;
      _trimWhitespace();
      if (position < length) {
        codeUnit = codeUnits[position];
        if (codeUnit == COMMA) {
          position++;
          _trimWhitespace();
          continue;
        } else {
          break;
        }
      }
    }

    if (codeUnit != RIGHT_BRACE) {
      _fail();
    }
    position++;
    return result;
  }

  List _decodeList() {
    int codeUnit = codeUnits[position];
    if (codeUnit != LEFT_BRACKET) {
      _fail();
    }
    position++;
    _trimWhitespace();
    List result = [];
    while (position < length) {
      codeUnit = codeUnits[position];
      if (codeUnit == RIGHT_BRACKET) {
        break;
      }
      result.add(_decodeValue());
      _trimWhitespace();
      if (position < length) {
        codeUnit = codeUnits[position];
        if (codeUnit == COMMA) {
          position++;
          _trimWhitespace();
          continue;
        } else {
          break;
        }
      }
    }

    if (codeUnit != RIGHT_BRACKET) {
      _fail();
    }
    position++;
    return result;
  }

  bool _decodeTrue() {
    match(TRUE);
    return true;
  }

  bool _decodeFalse() {
    match(FALSE);
    return false;
  }

  Null _decodeNull() {
    match(NULL);
    return null;
  }

  void match(List<int> codes) {
    if (position + codes.length > length) {
      _fail();
    }
    for (int i = 0; i < codes.length; i++) {
      if (codes[i] != codeUnits[position + i]) {
        _fail();
      }
    }
    position += codes.length;
  }

  num _decodeNumber() {
    throw new UnsupportedError('_decodeNumber');
  }

  void _fail() {
    throw new ArgumentError("Unexpected value: "
        "'${new String.fromCharCodes(codeUnits, position)}'.");
  }
}
