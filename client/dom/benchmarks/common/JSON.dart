// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Pure Dart implementation of JSON protocol.

/**
 * Utility class to parse JSON and serialize objects to JSON.
 */
class JSON {
  /**
   * Parses [:json:] and build the corresponding object.
   */
  static parse(String json) {
    return JsonParser.parse(json);
  }

  /**
   * Serializes [:object:] into JSON string.
   */
  static String stringify(Object object) {
    return JsonStringifier.stringify(object);
  }
}

//// Implementation ///////////////////////////////////////////////////////////

/**
 * Union-like class for JSON tokens.
 */
class JsonToken {
  static final int STRING = 0;
  static final int NUMBER = 1;
  static final int NULL = 2;
  static final int FALSE = 3;
  static final int TRUE = 4;
  static final int RBRACKET = 5;
  static final int LBRACKET = 6;
  static final int RBRACE = 7;
  static final int LBRACE = 8;
  static final int COLON = 9;
  static final int COMMA = 10;

  final int kind;
  final String _s;
  final num _n;

  String get str() {
    assert(kind == STRING);
    return _s;
  }

  num get number() {
    assert(kind == NUMBER);
    return _n;
  }

  const JsonToken._internal(this.kind, this._s, this._n);

  factory JsonToken.string(String s) {
    return new JsonToken._internal(STRING, s, 0);
  }
  factory JsonToken.number(num n) {
    return new JsonToken._internal(NUMBER, '', n);
  }
  factory JsonToken.atom(int kind) {
    return new JsonToken._internal(kind, '', 0);
  }

  String toString() {
    switch (kind) {
      case STRING:
        return 'STRING(${_s})';

      case NUMBER:
        return 'NUMBER(${_n})';

      case NULL:
        return 'ATOM(null)';

      case FALSE:
        return 'ATOM(false)';

      case TRUE:
        return 'ATOM(true)';

      case RBRACKET:
        return 'ATOM(])';

      case LBRACKET:
        return 'ATOM([)';

      case RBRACE:
        return 'ATOM(})';

      case LBRACE:
        return 'ATOM({)';

      case COLON:
        return 'ATOM(:)';

      case COMMA:
        return 'ATOM(,)';
    }
  }
}

typedef bool Predicate(int c);

class JsonTokenizer {
  static final int BACKSPACE = 8;  // '\b'.charCodeAt(0)
  static final int TAB = 9;  // '\t'.charCodeAt(0)
  static final int NEW_LINE = 10;  // '\n'.charCodeAt(0)
  static final int FORM_FEED = 12;  // '\f'.charCodeAt(0)
  static final int LINE_FEED = 13;  // '\r'.charCodeAt(0)
  static final int SPACE = 32;  // ' '.charCodeAt(0)
  static final int QUOTE = 34;  // '"'.charCodeAt(0)
  static final int PLUS = 43;  // '+'.charCodeAt(0)
  static final int COMMA = 44;  // ','.charCodeAt(0)
  static final int MINUS = 45;  // '-'.charCodeAt(0)
  static final int DOT = 46;  // '.'.charCodeAt(0)
  static final int BACKSLASH = 47;  // '/'.charCodeAt(0)
  static final int ZERO = 48;  // '0'.charCodeAt(0)
  static final int NINE = 57;  // '9'.charCodeAt(0)
  static final int COLON = 58;  // ':'.charCodeAt(0)
  static final int A_BIG = 65;  // 'A'.charCodeAt(0)
  static final int E_BIG = 69;  // 'E'.charCodeAt(0)
  static final int Z_BIG = 90;  // 'Z'.charCodeAt(0)
  static final int LBRACKET = 91;  // '['.charCodeAt(0)
  static final int SLASH = 92;  // '\\'.charCodeAt(0)
  static final int RBRACKET = 93;  // ']'.charCodeAt(0)
  static final int A_SMALL = 97;  // 'a'.charCodeAt(0)
  static final int B_SMALL = 98;  // 'b'.charCodeAt(0)
  static final int E_SMALL = 101;  // 'e'.charCodeAt(0)
  static final int Z_SMALL = 122;  // 'z'.charCodeAt(0)
  static final int LBRACE = 123;  // '{'.charCodeAt(0)
  static final int RBRACE = 125;  // '}'.charCodeAt(0)

  JsonTokenizer(String s) : _s = s + ' ', _pos = 0, _len = s.length + 1 {}

  /**
   * Fetches next token or [:null:] if the stream has been exhausted.
   */
  JsonToken next() {
    while (_pos < _len && isWhitespace(_s.charCodeAt(_pos))) {
      _pos++;
    }
    if (_pos == _len) {
      return null;
    }

    final int cur = _s.charCodeAt(_pos);
    switch (true) {
      case cur == QUOTE:
        _pos++;

        List<int> charCodes = new List<int>();
        while (_pos < _len) {
          int c = _s.charCodeAt(_pos);
          if (c == QUOTE) {
            break;
          }
          if (c == SLASH) {
            _pos++;
            if (_pos == _len) {
              throw '\\ at the end';
            }

            switch (_s[_pos]) {
              case '"':
                c = QUOTE;
                break;
              case '\\':
                c = SLASH;
                break;
              case '/':
                c = BACKSLASH;
                break;
              case 'b':
                c = BACKSPACE;
                break;
              case 'n':
                c = NEW_LINE;
                break;
              case 'r':
                c = LINE_FEED;
                break;
              case 'f':
                c = FORM_FEED;
                break;
              case 't':
                c = TAB;
                break;
              case 'u':
                if (_pos + 5 > _len) {
                  throw 'Invalid unicode esacape sequence: \\' +
                      _s.substring(_pos, _len);
                }
                final codeString = _s.substring(_pos + 1, _pos + 5);
                c = Math.parseInt('0x' + codeString);
                if (c >= 128) {
                  // TODO(jmessery): the VM doesn't support 2-byte strings yet
                  // see runtime/lib/string.cc:49
                  // So instead we replace these characters with '?'
                  c = '?'.charCodeAt(0);
                }
                _pos += 4;
                break;
              default:
                throw 'Invalid esacape sequence: \\' + _s[_pos];
            }
          }
          charCodes.add(c);
          _pos++;
        }
        if (_pos == _len) {
          throw 'Unmatched quote';
        }

        final String body = new String.fromCharCodes(charCodes);
        _pos++;
        return new JsonToken.string(body);

      case cur == MINUS || isDigit(cur):
        skipDigits() {
          _scanWhile((int c) => isDigit(c), 'Invalid number');
        }

        final int startPos = _pos;
        bool isInteger = true;
        _pos++;
        skipDigits();

        int c = _s.charCodeAt(_pos);
        if (c == DOT) {
          isInteger = false;
          _pos++;
          skipDigits();
          c = _s.charCodeAt(_pos);
        }

        if (c == E_SMALL || c == E_BIG) {
          // TODO: consider keeping E+ as an integer.
          isInteger = false;
          _pos++;
          c = _s.charCodeAt(_pos);
          if (c == PLUS || c == MINUS) {
            _pos++;
          }
          skipDigits();
        }

        final String body = _s.substring(startPos, _pos);
        return new JsonToken.number(
            isInteger ?  Math.parseInt(body) : Math.parseDouble(body));

      case cur == LBRACE:
        _pos++;
        return new JsonToken.atom(JsonToken.LBRACE);

      case cur == RBRACE:
        _pos++;
        return new JsonToken.atom(JsonToken.RBRACE);

      case cur == LBRACKET:
        _pos++;
        return new JsonToken.atom(JsonToken.LBRACKET);

      case cur == RBRACKET:
        _pos++;
        return new JsonToken.atom(JsonToken.RBRACKET);

      case cur == COMMA:
        _pos++;
        return new JsonToken.atom(JsonToken.COMMA);

      case cur == COLON:
        _pos++;
        return new JsonToken.atom(JsonToken.COLON);

      case isLetter(cur):
        final int startPos = _pos;
        _pos++;
        while (_pos < _len && isLetter(_s.charCodeAt(_pos))) {
          _pos++;
        }
        final String body = _s.substring(startPos, _pos);
        switch (body) {
          case 'null':
            return new JsonToken.atom(JsonToken.NULL);

          case 'false':
            return new JsonToken.atom(JsonToken.FALSE);

          case 'true':
            return new JsonToken.atom(JsonToken.TRUE);

          default:
            throw 'Unexpected sequence ${body}';
        }
        // TODO: Bogous, to please DartVM.
        return null;

      default:
        throw 'Invalid token';
    }
  }

  final String _s;
  int _pos;
  final int _len;

  void _scanWhile(Predicate predicate, String errorMsg) {
    while (_pos < _len && predicate(_s.charCodeAt(_pos))) {
      _pos++;
    }
    if (_pos == _len) {
      throw errorMsg;
    }
  }

  // TODO other kind of whitespace.
  static bool isWhitespace(int c) {
    return c == SPACE || c == TAB || c == NEW_LINE || c == LINE_FEED;
  }
  static bool isDigit(int c) {
    return (ZERO <= c) && (c <= NINE);
  }
  static bool isLetter(int c) {
     return ((A_SMALL <= c) && (c <= Z_SMALL)) || ((A_BIG <= c) && (c <= Z_BIG));
  }
}

class JsonParser {
  static parse(String json) {
    return new JsonParser._internal(json)._parseToplevel();
  }

  final JsonTokenizer _tokenizer;

  JsonParser._internal(String json) : _tokenizer = new JsonTokenizer(json) {}

  _parseToplevel() {
    JsonToken token = _tokenizer.next();
    final result = _parseValue(token);
    token = _tokenizer.next();
    if (token !== null) {
      throw 'Junk at the end';
    }
    return result;
  }

  _parseValue(final JsonToken token) {
    if (token === null) {
      throw 'Nothing to parse';
    }
    switch (token.kind) {
      case JsonToken.STRING:
        return token.str;

      case JsonToken.NUMBER:
        return token.number;

      case JsonToken.NULL:
        return null;

      case JsonToken.FALSE:
        return false;

      case JsonToken.TRUE:
        return true;

      case JsonToken.LBRACE:
        return _parseObject();

      case JsonToken.LBRACKET:
        return _parseList();

      default:
        throw 'Unexpected token: ${token}';
      }
  }

  _parseObject() {
    Map<String, Object> object = new Map<String, Object>();

    _parseSequence(JsonToken.RBRACE, (JsonToken token) {
      _assertTokenKind(token, JsonToken.STRING);

      final String key = token.str;

      token = _tokenizer.next();
      _assertTokenKind(token, JsonToken.COLON);

      token = _tokenizer.next();
      final value = _parseValue(token);

      object[key] = value;
    });

    return object;
  }

  _parseList() {
    List<Object> array = new List<Object>();

    _parseSequence(JsonToken.RBRACKET, (JsonToken token) {
      final value = _parseValue(token);
      array.add(value);
    });

    return array;
  }

  void _parseSequence(int endTokenKind, void parseElement(JsonToken token)) {
    JsonToken token = _tokenizer.next();
    if (token === null) {
      throw 'Unexpected end of stream';
    }
    if (token.kind == endTokenKind) {
      return;
    }

    parseElement(token);

    token = _tokenizer.next();
    if (token === null) {
      throw 'Expected either comma or terminator';
    }
    while (token.kind != endTokenKind) {
      _assertTokenKind(token, JsonToken.COMMA);

      token = _tokenizer.next();
      parseElement(token);

      token = _tokenizer.next();
    }
  }

  void _assertTokenKind(JsonToken token, int kind) {
    if (token === null || token.kind != kind) {
      throw 'Unexpected token kind: token = ${token}, expected kind = ${kind}';
    }
  }

  // TODO: consider factor out error throwing code and build more complicated
  // data structure to provide more info for a caller.
}

// TODO: proper base class.
class JsonUnsupportedObjectType {
  const JsonUnsupportedObjectType();
}

class JsonStringifier {
  static String stringify(final object) {
    JsonStringifier stringifier = new JsonStringifier._internal();

    stringifier._stringify(object);
    /*
    try {
      stringifier._stringify(object);
    } catch (JsonUnsupportedObjectType e) {
      return null;
      }*/
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

  // TODO: add others.
  static bool _needsEscape(int charCode) {
    return JsonTokenizer.QUOTE == charCode || JsonTokenizer.SLASH == charCode;
  }

  static void _escape(StringBuffer sb, String s) {
    // TODO: support \u code points.
    // TODO: use writeCodePoint when implemented.
    // TODO: use for each if implemented.
    final int length = s.length;
    bool needsEscape = false;
    final charCodes = new List<int>();
    for (int i = 0; i < length; i++) {
      final int charCode = s.charCodeAt(i);
      if (_needsEscape(charCode)) {
        charCodes.add(JsonTokenizer.SLASH);
        needsEscape = true;
      }
      charCodes.add(charCode);
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
        }
        // TODO: switch to Iterables.
        for (int i = 1; i < a.length; i++) {
          _sb.add(',');
          _stringify(a[i]);
        }
        _sb.add(']');
        return;

      case object is Map:
        _checkCycle(object);
        Map<String, Object> m = object;
        _sb.add('{');
        int counter = m.length;
        m.forEach((String key, Object value) {
          _stringify(key);
          _sb.add(':');
          _stringify(value);
          counter--;
          if (counter != 0) {
            _sb.add(',');
          }
        });
        _sb.add('}');
        return;

      default:
        throw const JsonUnsupportedObjectType();
    }
  }
}
