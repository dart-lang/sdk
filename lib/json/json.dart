// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("json");

// Pure Dart implementation of JSON protocol.

/**
 * Utility class to parse JSON and serialize objects to JSON.
 */
class JSON {
  /**
   * Parses [:json:] and build the corresponding object.
   */
  static parse(String json) {
    return _JsonParser.parse(json);
  }

  /**
   * Serializes [:object:] into JSON string.
   */
  static String stringify(Object object) {
    return JsonStringifier.stringify(object);
  }
}

//// Implementation ///////////////////////////////////////////////////////////

// TODO(ajohnsen): Introduce when we have a common exception interface for json.
class JSONParseException {
  JSONParseException(int position, String message) :
      position = position,
      message = 'JSONParseException: $message, at offset $position';

  String toString() => message;

  final String message;
  final int position;
}

class _JsonParser {
  static final int BACKSPACE = 8;
  static final int TAB = 9;
  static final int NEW_LINE = 10;
  static final int FORM_FEED = 12;
  static final int CARRIAGE_RETURN = 13;
  static final int SPACE = 32;
  static final int QUOTE = 34;
  static final int PLUS = 43;
  static final int COMMA = 44;
  static final int MINUS = 45;
  static final int DOT = 46;
  static final int SLASH = 47;
  static final int CHAR_0 = 48;
  static final int CHAR_1 = 49;
  static final int CHAR_2 = 50;
  static final int CHAR_3 = 51;
  static final int CHAR_4 = 52;
  static final int CHAR_5 = 53;
  static final int CHAR_6 = 54;
  static final int CHAR_7 = 55;
  static final int CHAR_8 = 56;
  static final int CHAR_9 = 57;
  static final int COLON = 58;
  static final int CHAR_CAPITAL_E = 69;
  static final int LBRACKET = 91;
  static final int BACKSLASH = 92;
  static final int RBRACKET = 93;
  static final int CHAR_B = 98;
  static final int CHAR_E = 101;
  static final int CHAR_F = 102;
  static final int CHAR_N = 110;
  static final int CHAR_R = 114;
  static final int CHAR_T = 116;
  static final int CHAR_U = 117;
  static final int LBRACE = 123;
  static final int RBRACE = 125;

  static final int STRING_LITERAL = QUOTE;
  static final int NUMBER_LITERAL = MINUS;
  static final int NULL_LITERAL = CHAR_N;
  static final int FALSE_LITERAL = CHAR_F;
  static final int TRUE_LITERAL = CHAR_T;

  static final int WHITESPACE = SPACE;

  static final int LAST_ASCII = RBRACE;

  static final String NULL_STRING = "null";
  static final String TRUE_STRING = "true";
  static final String FALSE_STRING = "false";


  static parse(String json) {
    return new _JsonParser._internal(json)._parseToplevel();
  }

  _JsonParser._internal(String json) : this.json = '${json} ' {
    if (tokens !== null) return;

    // Use a list as jump-table, faster then switch and if.
    tokens = new List<int>(LAST_ASCII + 1);
    tokens[TAB] = WHITESPACE;
    tokens[NEW_LINE] = WHITESPACE;
    tokens[CARRIAGE_RETURN] = WHITESPACE;
    tokens[SPACE] = WHITESPACE;
    tokens[CHAR_0] = NUMBER_LITERAL;
    tokens[CHAR_1] = NUMBER_LITERAL;
    tokens[CHAR_2] = NUMBER_LITERAL;
    tokens[CHAR_3] = NUMBER_LITERAL;
    tokens[CHAR_4] = NUMBER_LITERAL;
    tokens[CHAR_5] = NUMBER_LITERAL;
    tokens[CHAR_6] = NUMBER_LITERAL;
    tokens[CHAR_7] = NUMBER_LITERAL;
    tokens[CHAR_8] = NUMBER_LITERAL;
    tokens[CHAR_9] = NUMBER_LITERAL;
    tokens[MINUS] = NUMBER_LITERAL;
    tokens[LBRACE] = LBRACE;
    tokens[RBRACE] = RBRACE;
    tokens[LBRACKET] = LBRACKET;
    tokens[RBRACKET] = RBRACKET;
    tokens[QUOTE] = STRING_LITERAL;
    tokens[COLON] = COLON;
    tokens[COMMA] = COMMA;
    tokens[CHAR_N] = NULL_LITERAL;
    tokens[CHAR_T] = TRUE_LITERAL;
    tokens[CHAR_F] = FALSE_LITERAL;
  }

  _parseToplevel() {
    final result = _parseValue();
    if (_token() !== null) {
      _error('Junk at the end of JSON input');
    }
    return result;
  }

  _parseValue() {
    final int token = _token();
    if (token === null) {
      _error('Nothing to parse');
    }
    switch (token) {
      case STRING_LITERAL: return _parseString();
      case NUMBER_LITERAL: return _parseNumber();
      case NULL_LITERAL: return _expectKeyword(NULL_STRING, null);
      case FALSE_LITERAL: return _expectKeyword(FALSE_STRING, false);
      case TRUE_LITERAL: return _expectKeyword(TRUE_STRING, true);
      case LBRACE: return _parseObject();
      case LBRACKET: return _parseList();

      default:
        _error('Unexpected token');
    }
  }

  Object _expectKeyword(String word, Object value) {
    for (int i = 0; i < word.length; i++) {
      // Implicit end check in _char().
      if (_char() != word.charCodeAt(i)) _error("Expected keyword '$word'");
      position++;
    }
    return value;
  }

  _parseObject() {
    final object = {};

    position++;  // Eat '{'.

    if (!_isToken(RBRACE)) {
      while (true) {
        final String key = _parseString();
        if (!_isToken(COLON)) _error("Expected ':' when parsing object");
        position++;
        object[key] = _parseValue();

        if (!_isToken(COMMA)) break;
        position++;  // Skip ','.
      };

      if (!_isToken(RBRACE)) _error("Expected '}' at end of object");
    }
    position++;

    return object;
  }

  _parseList() {
    final list = [];

    position++;  // Eat '['.

    if (!_isToken(RBRACKET)) {
      while (true) {
        list.add(_parseValue());

        if (!_isToken(COMMA)) break;
        position++;
      };

      if (!_isToken(RBRACKET)) _error("Expected ']' at end of list");
    }
    position++;

    return list;
  }

  String _parseString() {
    if (!_isToken(STRING_LITERAL)) _error("Expected string literal");

    position++;  // Eat '"'.

    List<int> charCodes = new List<int>();
    while (true) {
      int c = _char();
      if (c == QUOTE) {
        position++;
        break;
      }
      if (c == BACKSLASH) {
        position++;
        if (position == json.length) {
          _error('\\ at the end of input');
        }

        switch (_char()) {
          case QUOTE:
            c = QUOTE;
            break;
          case BACKSLASH:
            c = BACKSLASH;
            break;
          case SLASH:
            c = SLASH;
            break;
          case CHAR_B:
            c = BACKSPACE;
            break;
          case CHAR_N:
            c = NEW_LINE;
            break;
          case CHAR_R:
            c = CARRIAGE_RETURN;
            break;
          case CHAR_F:
            c = FORM_FEED;
            break;
          case CHAR_T:
            c = TAB;
            break;
          case CHAR_U:
            if (position + 5 > json.length) {
              _error('Invalid unicode esacape sequence');
            }
            final codeString = json.substring(position + 1, position + 5);
            try {
              c = Math.parseInt('0x${codeString}');
            } catch (var e) {
              _error('Invalid unicode esacape sequence');
            }
            position += 4;
            break;
          default:
            _error('Invalid esacape sequence in string literal');
        }
      }
      charCodes.add(c);
      position++;
    }

    return new String.fromCharCodes(charCodes);
  }

  num _parseNumber() {
    if (!_isToken(NUMBER_LITERAL)) _error("Expected number literal");

    final int startPos = position;
    if (_isChar(MINUS)) position++;
    if (_isChar(CHAR_0)) {
      position++;
    } else if (_isDigit()) {
      position++;
      while (_isDigit()) position++;
    } else {
      _error("Expected digit when parsing number");
    }

    bool isInt = true;
    if (_isChar(DOT)) {
      position++;
      if (_isDigit()) {
        isInt = false;
        while (_isDigit()) position++;
      } else {
        position--;  // No digit, backtrack.
      }
    }

    if (_isChar(CHAR_E) || _isChar(CHAR_CAPITAL_E)) {
      int backtrackTo = position;
      position++;
      if (_isChar(MINUS) || _isChar(PLUS)) position++;
      if (_isDigit()) {
        position++;
        isInt = false;
        while (_isDigit()) position++;
      } else {
        position = backtrackTo;  // No digit, backtrack.
      }
    }

    String number = json.substring(startPos, position);
    if (isInt) {
      return Math.parseInt(number);
    } else {
      return Math.parseDouble(number);
    }
  }

  bool _isChar(int char) => _char() == char;

  bool _isDigit() {
    int char = _char();
    return char >= CHAR_0 && char <= CHAR_9;
  }

  bool _isToken(int tokenKind) => _token() == tokenKind;

  int _char() {
    if (position >= json.length) {
      _error("Unexpected end of JSON stream");
    }
    return json.charCodeAt(position);
  }

  int _token() {
    while (true) {
      if (position >= json.length) return null;
      int char = json.charCodeAt(position);
      int token = tokens[char];
      if (token === WHITESPACE) {
        position++;
        continue;
      }
      if (token === null) _error("Invalid JSON token");
      return token;
    }
  }

  void _error(String message) {
    throw message;
  }

  final String json;
  int position = 0;
  static List<int> tokens;
}

// TODO: proper base class.
class JsonUnsupportedObjectType {
  const JsonUnsupportedObjectType();
}

class JsonStringifier {
  static String stringify(final object) {
    JsonStringifier stringifier = new JsonStringifier._internal();
    stringifier._stringify(object);
    return stringifier._result;
  }

  JsonStringifier._internal()
      : _sb = new StringBuffer(), _seen = new List<Object>() {}
  StringBuffer _sb;
  List<Object> _seen;  // TODO: that should be identity set.
  String get _result() { return _sb.toString(); }

  static String _numberToString(num x) {
    // TODO: need some more investigation what to do with precision
    // of double values.
    switch (true) {
      case x is int:
        return x.toString();

      case x is double:
        return x.toString();

      default:
        return x.toDouble().toString();
    }
  }

  // ('0' + x) or ('a' + x - 10)
  static int _hexDigit(int x) => x < 10 ? 48 + x : 87 + x;

  static void _escape(StringBuffer sb, String s) {
    final int length = s.length;
    bool needsEscape = false;
    final charCodes = new List<int>();
    for (int i = 0; i < length; i++) {
      int charCode = s.charCodeAt(i);
      if (charCode < 32) {
        needsEscape = true;
        charCodes.add(_JsonParser.BACKSLASH);
        switch (charCode) {
        case _JsonParser.BACKSPACE:
          charCodes.add(_JsonParser.CHAR_B);
          break;
        case _JsonParser.TAB:
          charCodes.add(_JsonParser.CHAR_T);
          break;
        case _JsonParser.NEW_LINE:
          charCodes.add(_JsonParser.CHAR_N);
          break;
        case _JsonParser.FORM_FEED:
          charCodes.add(_JsonParser.CHAR_F);
          break;
        case _JsonParser.CARRIAGE_RETURN:
          charCodes.add(_JsonParser.CHAR_R);
          break;
        default:
          charCodes.add(_JsonParser.CHAR_U);
          charCodes.add(_hexDigit((charCode >> 12) & 0xf));
          charCodes.add(_hexDigit((charCode >> 8) & 0xf));
          charCodes.add(_hexDigit((charCode >> 4) & 0xf));
          charCodes.add(_hexDigit(charCode & 0xf));
          break;
        }
      } else if (charCode == _JsonParser.QUOTE ||
          charCode == _JsonParser.BACKSLASH) {
        needsEscape = true;
        charCodes.add(_JsonParser.BACKSLASH);
        charCodes.add(charCode);
      } else {
        charCodes.add(charCode);
      }
    }
    sb.add(needsEscape ? new String.fromCharCodes(charCodes) : s);
  }

  void _checkCycle(final object) {
    // TODO: use Iterables.
    for (int i = 0; i < _seen.length; i++) {
      if (_seen[i] === object) {
        throw 'Cyclic structure';
      }
    }
    _seen.add(object);
  }

  void _stringify(final object) {
    switch (true) {
      case object is num:
        // TODO: use writeOn.
        _sb.add(_numberToString(object));
        return;

      case object === true:
        _sb.add('true');
        return;

      case object === false:
        _sb.add('false');
        return;

      case object === null:
        _sb.add('null');
        return;

      case object is String:
        _sb.add('"');
        _escape(_sb, object);
        _sb.add('"');
        return;

      case object is List:
        _checkCycle(object);
        List a = object;
        _sb.add('[');
        if (a.length > 0) {
          _stringify(a[0]);
          // TODO: switch to Iterables.
          for (int i = 1; i < a.length; i++) {
            _sb.add(',');
            _stringify(a[i]);
          }
        }
        _sb.add(']');
        _seen.removeLast();
        return;

      case object is Map:
        _checkCycle(object);
        Map<String, Object> m = object;
        _sb.add('{');
        bool first = true;
        m.forEach((String key, Object value) {
          if (!first) {
            _sb.add(',"');
          } else {
            _sb.add('"');
          }
          _escape(_sb, key);
          _sb.add('":');
          _stringify(value);
          first = false;
        });
        _sb.add('}');
        _seen.removeLast();
        return;

      default:
        throw const JsonUnsupportedObjectType();
    }
  }
}
