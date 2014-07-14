// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:typed_data";

// JSON conversion.

patch _parseJson(String json, reviver(var key, var value)) {
  _BuildJsonListener listener;
  if (reviver == null) {
    listener = new _BuildJsonListener();
  } else {
    listener = new _ReviverJsonListener(reviver);
  }
  new _JsonParser(json, listener).parse();
  return listener.result;
}

//// Implementation ///////////////////////////////////////////////////////////

// Simple API for JSON parsing.

abstract class _JsonListener {
  void handleString(String value) {}
  void handleNumber(num value) {}
  void handleBool(bool value) {}
  void handleNull() {}
  void beginObject() {}
  void propertyName() {}
  void propertyValue() {}
  void endObject() {}
  void beginArray() {}
  void arrayElement() {}
  void endArray() {}
}

/**
 * A [JsonListener] that builds data objects from the parser events.
 *
 * This is a simple stack-based object builder. It keeps the most recently
 * seen value in a variable, and uses it depending on the following event.
 */
class _BuildJsonListener extends _JsonListener {
  /**
   * Stack used to handle nested containers.
   *
   * The current container is pushed on the stack when a new one is
   * started. If the container is a [Map], there is also a current [key]
   * which is also stored on the stack.
   */
  List stack = [];
  /** The current [Map] or [List] being built. */
  var currentContainer;
  /** The most recently read property key. */
  String key;
  /** The most recently read value. */
  var value;

  /** Pushes the currently active container (and key, if a [Map]). */
  void pushContainer() {
    if (currentContainer is Map) stack.add(key);
    stack.add(currentContainer);
  }

  /** Pops the top container from the [stack], including a key if applicable. */
  void popContainer() {
    value = currentContainer;
    currentContainer = stack.removeLast();
    if (currentContainer is Map) key = stack.removeLast();
  }

  void handleString(String value) { this.value = value; }
  void handleNumber(num value) { this.value = value; }
  void handleBool(bool value) { this.value = value; }
  void handleNull() { this.value = null; }

  void beginObject() {
    pushContainer();
    currentContainer = {};
  }

  void propertyName() {
    key = value;
    value = null;
  }

  void propertyValue() {
    Map map = currentContainer;
    map[key] = value;
    key = value = null;
  }

  void endObject() {
    popContainer();
  }

  void beginArray() {
    pushContainer();
    currentContainer = [];
  }

  void arrayElement() {
    List list = currentContainer;
    currentContainer.add(value);
    value = null;
  }

  void endArray() {
    popContainer();
  }

  /** Read out the final result of parsing a JSON string. */
  get result {
    assert(currentContainer == null);
    return value;
  }
}

class _ReviverJsonListener extends _BuildJsonListener {
  final _Reviver reviver;
  _ReviverJsonListener(reviver(key, value)) : this.reviver = reviver;

  void arrayElement() {
    List list = currentContainer;
    value = reviver(list.length, value);
    super.arrayElement();
  }

  void propertyValue() {
    value = reviver(key, value);
    super.propertyValue();
  }

  get result {
    return reviver(null, value);
  }
}

class _JsonParser {
  // A simple non-recursive state-based parser for JSON.
  //
  // Literal values accepted in states ARRAY_EMPTY, ARRAY_COMMA, OBJECT_COLON
  // and strings also in OBJECT_EMPTY, OBJECT_COMMA.
  //               VALUE  STRING  :  ,  }  ]        Transitions to
  // EMPTY            X      X                   -> END
  // ARRAY_EMPTY      X      X             @     -> ARRAY_VALUE / pop
  // ARRAY_VALUE                     @     @     -> ARRAY_COMMA / pop
  // ARRAY_COMMA      X      X                   -> ARRAY_VALUE
  // OBJECT_EMPTY            X          @        -> OBJECT_KEY / pop
  // OBJECT_KEY                   @              -> OBJECT_COLON
  // OBJECT_COLON     X      X                   -> OBJECT_VALUE
  // OBJECT_VALUE                    @  @        -> OBJECT_COMMA / pop
  // OBJECT_COMMA            X                   -> OBJECT_KEY
  // END
  // Starting a new array or object will push the current state. The "pop"
  // above means restoring this state and then marking it as an ended value.
  // X means generic handling, @ means special handling for just that
  // state - that is, values are handled generically, only punctuation
  // cares about the current state.
  // Values for states are chosen so bits 0 and 1 tell whether
  // a string/value is allowed, and setting bits 0 through 2 after a value
  // gets to the next state (not empty, doesn't allow a value).

  // State building-block constants.
  static const int INSIDE_ARRAY = 1;
  static const int INSIDE_OBJECT = 2;
  static const int AFTER_COLON = 3;  // Always inside object.

  static const int ALLOW_STRING_MASK = 8;  // Allowed if zero.
  static const int ALLOW_VALUE_MASK = 4;  // Allowed if zero.
  static const int ALLOW_VALUE = 0;
  static const int STRING_ONLY = 4;
  static const int NO_VALUES = 12;

  // Objects and arrays are "empty" until their first property/element.
  static const int EMPTY = 0;
  static const int NON_EMPTY = 16;
  static const int EMPTY_MASK = 16;  // Empty if zero.


  static const int VALUE_READ_BITS = NO_VALUES | NON_EMPTY;

  // Actual states.
  static const int STATE_INITIAL      = EMPTY | ALLOW_VALUE;
  static const int STATE_END          = NON_EMPTY | NO_VALUES;

  static const int STATE_ARRAY_EMPTY  = INSIDE_ARRAY | EMPTY | ALLOW_VALUE;
  static const int STATE_ARRAY_VALUE  = INSIDE_ARRAY | NON_EMPTY | NO_VALUES;
  static const int STATE_ARRAY_COMMA  = INSIDE_ARRAY | NON_EMPTY | ALLOW_VALUE;

  static const int STATE_OBJECT_EMPTY = INSIDE_OBJECT | EMPTY | STRING_ONLY;
  static const int STATE_OBJECT_KEY   = INSIDE_OBJECT | NON_EMPTY | NO_VALUES;
  static const int STATE_OBJECT_COLON = AFTER_COLON | NON_EMPTY | ALLOW_VALUE;
  static const int STATE_OBJECT_VALUE = AFTER_COLON | NON_EMPTY | NO_VALUES;
  static const int STATE_OBJECT_COMMA = INSIDE_OBJECT | NON_EMPTY | STRING_ONLY;

  // Character code constants.
  static const int BACKSPACE       = 0x08;
  static const int TAB             = 0x09;
  static const int NEWLINE         = 0x0a;
  static const int CARRIAGE_RETURN = 0x0d;
  static const int FORM_FEED       = 0x0c;
  static const int SPACE           = 0x20;
  static const int QUOTE           = 0x22;
  static const int PLUS            = 0x2b;
  static const int COMMA           = 0x2c;
  static const int MINUS           = 0x2d;
  static const int DECIMALPOINT    = 0x2e;
  static const int SLASH           = 0x2f;
  static const int CHAR_0          = 0x30;
  static const int CHAR_9          = 0x39;
  static const int COLON           = 0x3a;
  static const int CHAR_E          = 0x45;
  static const int LBRACKET        = 0x5b;
  static const int BACKSLASH       = 0x5c;
  static const int RBRACKET        = 0x5d;
  static const int CHAR_a          = 0x61;
  static const int CHAR_b          = 0x62;
  static const int CHAR_e          = 0x65;
  static const int CHAR_f          = 0x66;
  static const int CHAR_l          = 0x6c;
  static const int CHAR_n          = 0x6e;
  static const int CHAR_r          = 0x72;
  static const int CHAR_s          = 0x73;
  static const int CHAR_t          = 0x74;
  static const int CHAR_u          = 0x75;
  static const int LBRACE          = 0x7b;
  static const int RBRACE          = 0x7d;

  final String source;
  final _JsonListener listener;
  _JsonParser(this.source, this.listener);

  /** Parses [source], or throws if it fails. */
  void parse() {
    final List<int> states = <int>[];
    int state = STATE_INITIAL;
    int position = 0;
    int length = source.length;
    while (position < length) {
      int char = source.codeUnitAt(position);
      switch (char) {
        case SPACE:
        case CARRIAGE_RETURN:
        case NEWLINE:
        case TAB:
          position++;
          break;
        case QUOTE:
          if ((state & ALLOW_STRING_MASK) != 0) fail(position);
          position = parseString(position + 1);
          state |= VALUE_READ_BITS;
          break;
        case LBRACKET:
          if ((state & ALLOW_VALUE_MASK) != 0) fail(position);
          listener.beginArray();
          states.add(state);
          state = STATE_ARRAY_EMPTY;
          position++;
          break;
        case LBRACE:
          if ((state & ALLOW_VALUE_MASK) != 0) fail(position);
          listener.beginObject();
          states.add(state);
          state = STATE_OBJECT_EMPTY;
          position++;
          break;
        case CHAR_n:
          if ((state & ALLOW_VALUE_MASK) != 0) fail(position);
          position = parseNull(position);
          state |= VALUE_READ_BITS;
          break;
        case CHAR_f:
          if ((state & ALLOW_VALUE_MASK) != 0) fail(position);
          position = parseFalse(position);
          state |= VALUE_READ_BITS;
          break;
        case CHAR_t:
          if ((state & ALLOW_VALUE_MASK) != 0) fail(position);
          position = parseTrue(position);
          state |= VALUE_READ_BITS;
          break;
        case COLON:
          if (state != STATE_OBJECT_KEY) fail(position);
          listener.propertyName();
          state = STATE_OBJECT_COLON;
          position++;
          break;
        case COMMA:
          if (state == STATE_OBJECT_VALUE) {
            listener.propertyValue();
            state = STATE_OBJECT_COMMA;
            position++;
          } else if (state == STATE_ARRAY_VALUE) {
            listener.arrayElement();
            state = STATE_ARRAY_COMMA;
            position++;
          } else {
            fail(position);
          }
          break;
        case RBRACKET:
          if (state == STATE_ARRAY_EMPTY) {
            listener.endArray();
          } else if (state == STATE_ARRAY_VALUE) {
            listener.arrayElement();
            listener.endArray();
          } else {
            fail(position);
          }
          state = states.removeLast() | VALUE_READ_BITS;
          position++;
          break;
        case RBRACE:
          if (state == STATE_OBJECT_EMPTY) {
            listener.endObject();
          } else if (state == STATE_OBJECT_VALUE) {
            listener.propertyValue();
            listener.endObject();
          } else {
            fail(position);
          }
          state = states.removeLast() | VALUE_READ_BITS;
          position++;
          break;
        default:
          if ((state & ALLOW_VALUE_MASK) != 0) fail(position);
          position = parseNumber(char, position);
          state |= VALUE_READ_BITS;
          break;
      }
    }
    if (state != STATE_END) fail(position);
  }

  /**
   * Parses a "true" literal starting at [position].
   *
   * [:source[position]:] must be "t".
   */
  int parseTrue(int position) {
    assert(source.codeUnitAt(position) == CHAR_t);
    if (source.length < position + 4) fail(position, "Unexpected identifier");
    if (source.codeUnitAt(position + 1) != CHAR_r ||
        source.codeUnitAt(position + 2) != CHAR_u ||
        source.codeUnitAt(position + 3) != CHAR_e) {
      fail(position);
    }
    listener.handleBool(true);
    return position + 4;
  }

  /**
   * Parses a "false" literal starting at [position].
   *
   * [:source[position]:] must be "f".
   */
  int parseFalse(int position) {
    assert(source.codeUnitAt(position) == CHAR_f);
    if (source.length < position + 5) fail(position, "Unexpected identifier");
    if (source.codeUnitAt(position + 1) != CHAR_a ||
        source.codeUnitAt(position + 2) != CHAR_l ||
        source.codeUnitAt(position + 3) != CHAR_s ||
        source.codeUnitAt(position + 4) != CHAR_e) {
      fail(position);
    }
    listener.handleBool(false);
    return position + 5;
  }

  /**
   * Parses a "null" literal starting at [position].
   *
   * [:source[position]:] must be "n".
   */
  int parseNull(int position) {
    assert(source.codeUnitAt(position) == CHAR_n);
    if (source.length < position + 4) fail(position, "Unexpected identifier");
    if (source.codeUnitAt(position + 1) != CHAR_u ||
        source.codeUnitAt(position + 2) != CHAR_l ||
        source.codeUnitAt(position + 3) != CHAR_l) {
      fail(position);
    }
    listener.handleNull();
    return position + 4;
  }

  /**
   * Parses a string value.
   *
   * Initial [position] is right after the initial quote.
   * Returned position right after the final quote.
   */
  int parseString(int position) {
    // Format: '"'([^\x00-\x1f\\\"]|'\\'[bfnrt/\\"])*'"'
    // Initial position is right after first '"'.
    int start = position;
    while (position < source.length) {
      int char = source.codeUnitAt(position++);
      // BACKSLASH is larger than QUOTE and SPACE.
      if (char > BACKSLASH) {
        continue;
      }
      if (char == BACKSLASH) {
        return parseStringWithEscapes(start, position - 1);
      }
      if (char == QUOTE) {
        listener.handleString(source.substring(start, position - 1));
        return position;
      }
      if (char < SPACE) {
        fail(position - 1, "Control character in string");
      }
    }
    fail(start - 1, "Unterminated string");
  }

  int parseStringWithEscapes(start, position) {
    // Backslash escape detected. Collect character codes for rest of string.
    int firstEscape = position;
    List<int> chars = <int>[];
    for (int i = start; i < firstEscape; i++) {
      chars.add(source.codeUnitAt(i));
    }
    position++;
    while (true) {
      if (position == source.length) {
        fail(start - 1, "Unterminated string");
      }
      int char = source.codeUnitAt(position);
      switch (char) {
        case CHAR_b: char = BACKSPACE; break;
        case CHAR_f: char = FORM_FEED; break;
        case CHAR_n: char = NEWLINE; break;
        case CHAR_r: char = CARRIAGE_RETURN; break;
        case CHAR_t: char = TAB; break;
        case SLASH:
        case BACKSLASH:
        case QUOTE:
          break;
        case CHAR_u:
          int hexStart = position - 1;
          int value = 0;
          for (int i = 0; i < 4; i++) {
            position++;
            if (position == source.length) {
              fail(start - 1, "Unterminated string");
            }
            char = source.codeUnitAt(position);
            char -= 0x30;
            if (char < 0) fail(hexStart, "Invalid unicode escape");
            if (char < 10) {
              value = value * 16 + char;
            } else {
              char = (char | 0x20) - 0x31;
              if (char < 0 || char > 5) {
                fail(hexStart, "Invalid unicode escape");
              }
              value = value * 16 + char + 10;
            }
          }
          char = value;
          break;
        default:
          if (char < SPACE) fail(position, "Control character in string");
          fail(position, "Unrecognized string escape");
      }
      do {
        chars.add(char);
        position++;
        if (position == source.length) fail(start - 1, "Unterminated string");
        char = source.codeUnitAt(position);
        if (char == QUOTE) {
          String result = new String.fromCharCodes(chars);
          listener.handleString(result);
          return position + 1;
        }
        if (char < SPACE) {
          fail(position, "Control character in string");
        }
      } while (char != BACKSLASH);
      position++;
    }
  }

  int parseNumber(int char, int position) {
    // Also called on any unexpected character.
    // Format:
    //  '-'?('0'|[1-9][0-9]*)('.'[0-9]+)?([eE][+-]?[0-9]+)?
    int start = position;
    int length = source.length;
    int intValue = 0;  // Collect int value while parsing.
    int intSign = 1;
    bool isDouble = false;
    // Break this block when the end of the number literal is reached.
    // At that time, position points to the next character, and isDouble
    // is set if the literal contains a decimal point or an exponential.
    parsing: {
      if (char == MINUS) {
        intSign = -1;
        position++;
        if (position == length) fail(position, "Missing expected digit");
        char = source.codeUnitAt(position);
      }
      if (char < CHAR_0 || char > CHAR_9) {
        if (negative) {
          fail(position, "Missing expected digit");
        } else {
          // If it doesn't even start out as a numeral.
          fail(position, "Unexpected character");
        }
      }
      if (char == CHAR_0) {
        position++;
        if (position == length) break parsing;
        char = source.codeUnitAt(position);
        if (CHAR_0 <= char && char <= CHAR_9) {
          fail(position);
        }
      } else {
        do {
          intValue = intValue * 10 + (char - CHAR_0);
          position++;
          if (position == length) break parsing;
          char = source.codeUnitAt(position);
        } while (CHAR_0 <= char && char <= CHAR_9);
      }
      if (char == DECIMALPOINT) {
        isDouble = true;
        position++;
        if (position == length) fail(position, "Missing expected digit");
        char = source.codeUnitAt(position);
        if (char < CHAR_0 || char > CHAR_9) fail(position);
        do {
          position++;
          if (position == length) break parsing;
          char = source.codeUnitAt(position);
        } while (CHAR_0 <= char && char <= CHAR_9);
      }
      if (char == CHAR_e || char == CHAR_E) {
        isDouble = true;
        position++;
        if (position == length) fail(position, "Missing expected digit");
        char = source.codeUnitAt(position);
        if (char == PLUS || char == MINUS) {
          position++;
          if (position == length) fail(position, "Missing expected digit");
          char = source.codeUnitAt(position);
        }
        if (char < CHAR_0 || char > CHAR_9) {
          fail(position, "Missing expected digit");
        }
        do {
          position++;
          if (position == length) break parsing;
          char = source.codeUnitAt(position);
        } while (CHAR_0 <= char && char <= CHAR_9);
      }
    }
    if (!isDouble) {
      listener.handleNumber(intSign * intValue);
      return position;
    }
    // This correctly creates -0.0 for doubles.
    listener.handleNumber(_parseDouble(source, start, position));
    return position;
  }

  static double _parseDouble(String source, int start, int end)
      native "Double_parse";

  void fail(int position, [String message]) {
    if (message == null) message = "Unexpected character";
    throw new FormatException(message, source, position);
  }
}

// UTF-8 conversion.

patch class _Utf8Encoder {
  /* patch */ static List<int> _createBuffer(int size) => new Uint8List(size);
}
