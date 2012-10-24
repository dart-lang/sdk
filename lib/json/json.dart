// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("dart:json");

#import('dart:math');

// JSON parsing and serialization.

/**
 * Error thrown by JSON serialization if an object cannot be serialized.
 *
 * The [unsupportedObject] field holds that object that failed to be serialized.
 *
 * If an isn't directly serializable, the serializer calls the 'toJson' method
 * on the object. If that call fails, the error will be stored in the [cause]
 * field. If the call returns an object that isn't directly serializable,
 * the [cause] will be null.
 */
class JsonUnsupportedObjectError {
  // TODO: proper base class.
  /** The object that could not be serialized. */
  final unsupportedObject;
  /** The exception thrown by object's [:toJson:] method, if any. */
  final cause;
  JsonUnsupportedObjectError(this.unsupportedObject) : cause = null;
  JsonUnsupportedObjectError.withCause(this.unsupportedObject, this.cause);

  String toString() {
    if (cause != null) {
      return "Calling toJson method on object failed.";
    } else {
      return "Object toJson method returns non-serializable value.";
    }
  }
}


/**
 * Utility class to parse JSON and serialize objects to JSON.
 */
class JSON {
  /**
   * Parses [json] and build the corresponding parsed JSON value.
   *
   * Parsed JSON values are of the types [num], [String], [bool], [Null],
   * [List]s of parsed JSON values or [Map]s from [String] to parsed
   * JSON values.
   *
   * Throws [JSONParseException] if the input is not valid JSON text.
   */
  static parse(String json) {
    return _JsonParser.parse(json);
  }

  /**
   * Serializes [object] into a JSON string.
   *
   * Directly serializable types are [num], [String], [bool], [Null], [List]
   * and [Map].
   * For [List], the elements must all be serializable.
   * For [Map], the keys must be [String] and the values must be serializable.
   * If a value is any other type is attempted serialized, a "toJson()" method
   * is invoked on the object and the result, which must be a directly
   * serializable type, is serialized instead of the original value.
   * If the object does not support this method, throws, or returns a
   * value that is not directly serializable, a [JsonUnsupportedObjectError]
   * exception is thrown. If the call throws (including the case where there
   * is no nullary "toJson" method, the error is caught and stored in the
   * [JsonUnsupportedObjectError]'s [:cause:] field.
   *
   * Objects should not change during serialization.
   * If an object is serialized more than once, [stringify] is allowed to cache
   * the JSON text for it. I.e., if an object changes after it is first
   * serialized, the new values may or may not be reflected in the result.
   */
  static String stringify(Object object) {
    return _JsonStringifier.stringify(object);
  }

  /**
   * Serializes [object] into [output] stream.
   *
   * Performs the same operations as [stringify] but outputs the resulting
   * string to an existing [StringBuffer] instead of creating a new [String].
   *
   * If serialization fails by throwing, some data might have been added to
   * [output], but it won't contain valid JSON text.
   */
  static void printOn(Object object, StringBuffer output) {
    return _JsonStringifier.printOn(object, output);
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
  static const int BACKSPACE = 8;
  static const int TAB = 9;
  static const int NEW_LINE = 10;
  static const int FORM_FEED = 12;
  static const int CARRIAGE_RETURN = 13;
  static const int SPACE = 32;
  static const int QUOTE = 34;
  static const int PLUS = 43;
  static const int COMMA = 44;
  static const int MINUS = 45;
  static const int DOT = 46;
  static const int SLASH = 47;
  static const int CHAR_0 = 48;
  static const int CHAR_1 = 49;
  static const int CHAR_2 = 50;
  static const int CHAR_3 = 51;
  static const int CHAR_4 = 52;
  static const int CHAR_5 = 53;
  static const int CHAR_6 = 54;
  static const int CHAR_7 = 55;
  static const int CHAR_8 = 56;
  static const int CHAR_9 = 57;
  static const int COLON = 58;
  static const int CHAR_CAPITAL_E = 69;
  static const int LBRACKET = 91;
  static const int BACKSLASH = 92;
  static const int RBRACKET = 93;
  static const int CHAR_B = 98;
  static const int CHAR_E = 101;
  static const int CHAR_F = 102;
  static const int CHAR_N = 110;
  static const int CHAR_R = 114;
  static const int CHAR_T = 116;
  static const int CHAR_U = 117;
  static const int LBRACE = 123;
  static const int RBRACE = 125;

  static const int STRING_LITERAL = QUOTE;
  static const int NUMBER_LITERAL = MINUS;
  static const int NULL_LITERAL = CHAR_N;
  static const int FALSE_LITERAL = CHAR_F;
  static const int TRUE_LITERAL = CHAR_T;

  static const int WHITESPACE = SPACE;

  static const int LAST_ASCII = RBRACE;

  static const String NULL_STRING = "null";
  static const String TRUE_STRING = "true";
  static const String FALSE_STRING = "false";

  static List<int> tokens;

  final String json;
  final int length;
  int position = 0;

  static parse(String json) {
    return new _JsonParser(json).parseToplevel();
  }

  _JsonParser(String json)
      : json = json,
        length = json.length {
    if (tokens != null) return;

    // Use a list as jump-table. It is faster than switch and if.
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

  parseToplevel() {
    final result = parseValue();
    if (token() != null) {
      error('Junk at the end of JSON input');
    }
    return result;
  }

  parseValue() {
    final int token = token();
    if (token == null) {
      error('Nothing to parse');
    }
    switch (token) {
      case STRING_LITERAL: return parseString();
      case NUMBER_LITERAL: return parseNumber();
      case NULL_LITERAL: return expectKeyword(NULL_STRING, null);
      case FALSE_LITERAL: return expectKeyword(FALSE_STRING, false);
      case TRUE_LITERAL: return expectKeyword(TRUE_STRING, true);
      case LBRACE: return parseObject();
      case LBRACKET: return parseList();

      default:
        error('Unexpected token');
    }
  }

  Object expectKeyword(String word, Object value) {
    for (int i = 0; i < word.length; i++) {
      // Implicit end check in char().
      if (char() != word.charCodeAt(i)) error("Expected keyword '$word'");
      position++;
    }
    return value;
  }

  parseObject() {
    final object = {};

    position++;  // Eat '{'.

    if (!isToken(RBRACE)) {
      while (true) {
        final String key = parseString();
        if (!isToken(COLON)) error("Expected ':' when parsing object");
        position++;
        object[key] = parseValue();

        if (!isToken(COMMA)) break;
        position++;  // Skip ','.
      };

      if (!isToken(RBRACE)) error("Expected '}' at end of object");
    }
    position++;

    return object;
  }

  parseList() {
    final list = [];

    position++;  // Eat '['.

    if (!isToken(RBRACKET)) {
      while (true) {
        list.add(parseValue());

        if (!isToken(COMMA)) break;
        position++;
      };

      if (!isToken(RBRACKET)) error("Expected ']' at end of list");
    }
    position++;

    return list;
  }

  String parseString() {
    if (!isToken(STRING_LITERAL)) error("Expected string literal");

    position++;  // Eat '"'.

    List<int> charCodes = new List<int>();
    while (true) {
      int c = char();
      if (c == QUOTE) {
        position++;
        break;
      }
      if (c == BACKSLASH) {
        position++;
        if (position == length) {
          error('\\ at the end of input');
        }

        switch (char()) {
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
            if (position + 5 > length) {
              error('Invalid unicode esacape sequence');
            }
            final codeString = json.substring(position + 1, position + 5);
            try {
              c = int.parse('0x${codeString}');
            } catch (e) {
              error('Invalid unicode esacape sequence');
            }
            position += 4;
            break;
          default:
            error('Invalid esacape sequence in string literal');
        }
      }
      charCodes.add(c);
      position++;
    }

    return new String.fromCharCodes(charCodes);
  }

  num parseNumber() {
    if (!isToken(NUMBER_LITERAL)) error('Expected number literal');

    final int startPos = position;
    int char = char();
    if (identical(char, MINUS)) char = nextChar();
    if (identical(char, CHAR_0)) {
      char = nextChar();
    } else if (isDigit(char)) {
      char = nextChar();
      while (isDigit(char)) char = nextChar();
    } else {
      error('Expected digit when parsing number');
    }

    bool isInt = true;
    if (identical(char, DOT)) {
      char = nextChar();
      if (isDigit(char)) {
        char = nextChar();
        isInt = false;
        while (isDigit(char)) char = nextChar();
      } else {
        error('Expected digit following comma');
      }
    }

    if (identical(char, CHAR_E) || identical(char, CHAR_CAPITAL_E)) {
      char = nextChar();
      if (identical(char, MINUS) || identical(char, PLUS)) char = nextChar();
      if (isDigit(char)) {
        char = nextChar();
        isInt = false;
        while (isDigit(char)) char = nextChar();
      } else {
        error('Expected digit following \'e\' or \'E\'');
      }
    }

    String number = json.substring(startPos, position);
    if (isInt) {
      return int.parse(number);
    } else {
      return double.parse(number);
    }
  }

  bool isChar(int char) {
    if (position >= length) return false;
    return json.charCodeAt(position) == char;
  }

  bool isDigit(int char) {
    return char >= CHAR_0 && char <= CHAR_9;
  }

  bool isToken(int tokenKind) => token() == tokenKind;

  int char() {
    if (position >= length) {
      error('Unexpected end of JSON stream');
    }
    return json.charCodeAt(position);
  }

  int nextChar() {
    position++;
    if (position >= length) return 0;
    return json.charCodeAt(position);
  }

  int token() {
    while (true) {
      if (position >= length) return null;
      int char = json.charCodeAt(position);
      int token = tokens[char];
      if (identical(token, WHITESPACE)) {
        position++;
        continue;
      }
      if (token == null) return 0;
      return token;
    }
  }

  void error(String message) {
    throw message;
  }
}

class _JsonStringifier {
  StringBuffer sb;
  List<Object> seen;  // TODO: that should be identity set.

  _JsonStringifier(this.sb) : seen = [];

  static String stringify(final object) {
    StringBuffer output = new StringBuffer();
    _JsonStringifier stringifier = new _JsonStringifier(output);
    stringifier.stringifyValue(object);
    return output.toString();
  }

  static void printOn(final object, StringBuffer output) {
    _JsonStringifier stringifier = new _JsonStringifier(output);
    stringifier.stringifyValue(object);
  }

  static String numberToString(num x) {
    return x.toString();
  }

  // ('0' + x) or ('a' + x - 10)
  static int hexDigit(int x) => x < 10 ? 48 + x : 87 + x;

  static void escape(StringBuffer sb, String s) {
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
          charCodes.add(hexDigit((charCode >> 12) & 0xf));
          charCodes.add(hexDigit((charCode >> 8) & 0xf));
          charCodes.add(hexDigit((charCode >> 4) & 0xf));
          charCodes.add(hexDigit(charCode & 0xf));
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

  void checkCycle(final object) {
    // TODO: use Iterables.
    for (int i = 0; i < seen.length; i++) {
      if (identical(seen[i], object)) {
        throw 'Cyclic structure';
      }
    }
    seen.add(object);
  }

  void stringifyValue(final object) {
    // Tries stringifying object directly. If it's not a simple value, List or
    // Map, call toJson() to get a custom representation and try serializing
    // that.
    if (!stringifyJsonValue(object)) {
      checkCycle(object);
      try {
        var customJson = object.toJson();
        if (!stringifyJsonValue(customJson)) {
          throw new JsonUnsupportedObjectError(object);
        }
        seen.removeLast();
      } catch (e) {
        throw new JsonUnsupportedObjectError.withCause(object, e);
      }
    }
  }

  /**
   * Serializes a [num], [String], [bool], [Null], [List] or [Map] value.
   *
   * Returns true if the value is one of these types, and false if not.
   * If a value is both a [List] and a [Map], it's serialized as a [List].
   */
  bool stringifyJsonValue(final object) {
    if (object is num) {
      // TODO: use writeOn.
      sb.add(numberToString(object));
      return true;
    } else if (identical(object, true)) {
      sb.add('true');
      return true;
    } else if (identical(object, false)) {
      sb.add('false');
       return true;
    } else if (object == null) {
      sb.add('null');
      return true;
    } else if (object is String) {
      sb.add('"');
      escape(sb, object);
      sb.add('"');
      return true;
    } else if (object is List) {
      checkCycle(object);
      List a = object;
      sb.add('[');
      if (a.length > 0) {
        stringifyValue(a[0]);
        // TODO: switch to Iterables.
        for (int i = 1; i < a.length; i++) {
          sb.add(',');
          stringifyValue(a[i]);
        }
      }
      sb.add(']');
      seen.removeLast();
      return true;
    } else if (object is Map) {
      checkCycle(object);
      Map<String, Object> m = object;
      sb.add('{');
      bool first = true;
      m.forEach((String key, Object value) {
        if (!first) {
          sb.add(',"');
        } else {
          sb.add('"');
        }
        escape(sb, key);
        sb.add('":');
        stringifyValue(value);
        first = false;
      });
      sb.add('}');
      seen.removeLast();
      return true;
    } else {
      return false;
    }
  }
}
