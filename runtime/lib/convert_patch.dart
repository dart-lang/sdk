// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_internal" show POWERS_OF_TEN;

// JSON conversion.

@patch
_parseJson(String source, reviver(key, value)) {
  _BuildJsonListener listener;
  if (reviver == null) {
    listener = new _BuildJsonListener();
  } else {
    listener = new _ReviverJsonListener(reviver);
  }
  var parser = new _JsonStringParser(listener);
  parser.chunk = source;
  parser.chunkEnd = source.length;
  parser.parse(0);
  parser.close();
  return listener.result;
}

@patch
class Utf8Decoder {
  @patch
  Converter<List<int>, T> fuse<T>(Converter<String, T> next) {
    if (next is JsonDecoder) {
      return new _JsonUtf8Decoder(next._reviver, this._allowMalformed)
          as dynamic/*=Converter<List<int>, T>*/;
    }
    // TODO(lrn): Recognize a fused decoder where the next step is JsonDecoder.
    return super.fuse/*<T>*/(next);
  }

  // Allow intercepting of UTF-8 decoding when built-in lists are passed.
  @patch
  static String _convertIntercepted(
      bool allowMalformed, List<int> codeUnits, int start, int end) {
    return null; // This call was not intercepted.
  }
}

class _JsonUtf8Decoder extends Converter<List<int>, Object> {
  final _Reviver _reviver;
  final bool _allowMalformed;

  _JsonUtf8Decoder(this._reviver, this._allowMalformed);

  Object convert(List<int> input) {
    var parser = _JsonUtf8DecoderSink._createParser(_reviver, _allowMalformed);
    parser.chunk = input;
    parser.chunkEnd = input.length;
    parser.parse(0);
    return parser.result;
  }

  ByteConversionSink startChunkedConversion(Sink<Object> sink) {
    return new _JsonUtf8DecoderSink(_reviver, sink, _allowMalformed);
  }
}

//// Implementation ///////////////////////////////////////////////////////////

// Simple API for JSON parsing.

/**
 * Listener for parsing events from [_ChunkedJsonParser].
 */
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

  /**
   * Read out the final result of parsing a JSON string.
   *
   * Must only be called when the entire input has been parsed.
   */
  get result;
}

/**
 * A [_JsonListener] that builds data objects from the parser events.
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

  void handleString(String value) {
    this.value = value;
  }

  void handleNumber(num value) {
    this.value = value;
  }

  void handleBool(bool value) {
    this.value = value;
  }

  void handleNull() {
    this.value = null;
  }

  void beginObject() {
    pushContainer();
    currentContainer = <String, dynamic>{};
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

/**
 * Buffer holding parts of a numeral.
 *
 * The buffer contains the characters of a JSON number.
 * These are all ASCII, so an [Uint8List] is used as backing store.
 *
 * This buffer is used when a JSON number is split between separate chunks.
 *
 */
class _NumberBuffer {
  static const int minCapacity = 16;
  static const int kDefaultOverhead = 5;
  Uint8List list;
  int length = 0;
  _NumberBuffer(int initialCapacity)
      : list = new Uint8List(_initialCapacity(initialCapacity));

  int get capacity => list.length;

  // Pick an initial capacity greater than the first part's size.
  // The typical use case has two parts, this is the attempt at
  // guessing the size of the second part without overdoing it.
  // The default estimate of the second part is [kDefaultOverhead],
  // then round to multiplum of four, and return the result,
  // or [minCapacity] if that is greater.
  static int _initialCapacity(int minCapacity) {
    minCapacity += kDefaultOverhead;
    if (minCapacity < minCapacity) return minCapacity;
    minCapacity = (minCapacity + 3) & ~3; // Round to multiple of four.
    return minCapacity;
  }

  // Grows to the exact size asked for.
  void ensureCapacity(int newCapacity) {
    Uint8List list = this.list;
    if (newCapacity <= list.length) return;
    Uint8List newList = new Uint8List(newCapacity);
    newList.setRange(0, list.length, list, 0);
    this.list = newList;
  }

  String getString() {
    String result = new String.fromCharCodes(list, 0, length);
    return result;
  }

  // TODO(lrn): See if parsing of numbers can be abstracted to something
  // not only working on strings, but also on char-code lists, without lossing
  // performance.
  int parseInt() => int.parse(getString());
  double parseDouble() => double.parse(getString());
}

/**
 * Chunked JSON parser.
 *
 * Receives inputs in chunks, gives access to individual parts of the input,
 * and stores input state between chunks.
 *
 * Implementations include [String] and UTF-8 parsers.
 */
abstract class _ChunkedJsonParser {
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
  static const int TOP_LEVEL = 0;
  static const int INSIDE_ARRAY = 1;
  static const int INSIDE_OBJECT = 2;
  static const int AFTER_COLON = 3; // Always inside object.

  static const int ALLOW_STRING_MASK = 8; // Allowed if zero.
  static const int ALLOW_VALUE_MASK = 4; // Allowed if zero.
  static const int ALLOW_VALUE = 0;
  static const int STRING_ONLY = 4;
  static const int NO_VALUES = 12;

  // Objects and arrays are "empty" until their first property/element.
  // At this position, they may either have an entry or a close-bracket.
  static const int EMPTY = 0;
  static const int NON_EMPTY = 16;
  static const int EMPTY_MASK = 16; // Empty if zero.

  // Actual states               : Context | Is empty? | Next?
  static const int STATE_INITIAL = TOP_LEVEL | EMPTY | ALLOW_VALUE;
  static const int STATE_END = TOP_LEVEL | NON_EMPTY | NO_VALUES;

  static const int STATE_ARRAY_EMPTY = INSIDE_ARRAY | EMPTY | ALLOW_VALUE;
  static const int STATE_ARRAY_VALUE = INSIDE_ARRAY | NON_EMPTY | NO_VALUES;
  static const int STATE_ARRAY_COMMA = INSIDE_ARRAY | NON_EMPTY | ALLOW_VALUE;

  static const int STATE_OBJECT_EMPTY = INSIDE_OBJECT | EMPTY | STRING_ONLY;
  static const int STATE_OBJECT_KEY = INSIDE_OBJECT | NON_EMPTY | NO_VALUES;
  static const int STATE_OBJECT_COLON = AFTER_COLON | NON_EMPTY | ALLOW_VALUE;
  static const int STATE_OBJECT_VALUE = AFTER_COLON | NON_EMPTY | NO_VALUES;
  static const int STATE_OBJECT_COMMA = INSIDE_OBJECT | NON_EMPTY | STRING_ONLY;

  // Bits set in state after successfully reading a value.
  // This transitions the state to expect the next punctuation.
  static const int VALUE_READ_BITS = NON_EMPTY | NO_VALUES;

  // Character code constants.
  static const int BACKSPACE = 0x08;
  static const int TAB = 0x09;
  static const int NEWLINE = 0x0a;
  static const int CARRIAGE_RETURN = 0x0d;
  static const int FORM_FEED = 0x0c;
  static const int SPACE = 0x20;
  static const int QUOTE = 0x22;
  static const int PLUS = 0x2b;
  static const int COMMA = 0x2c;
  static const int MINUS = 0x2d;
  static const int DECIMALPOINT = 0x2e;
  static const int SLASH = 0x2f;
  static const int CHAR_0 = 0x30;
  static const int CHAR_9 = 0x39;
  static const int COLON = 0x3a;
  static const int CHAR_E = 0x45;
  static const int LBRACKET = 0x5b;
  static const int BACKSLASH = 0x5c;
  static const int RBRACKET = 0x5d;
  static const int CHAR_a = 0x61;
  static const int CHAR_b = 0x62;
  static const int CHAR_e = 0x65;
  static const int CHAR_f = 0x66;
  static const int CHAR_l = 0x6c;
  static const int CHAR_n = 0x6e;
  static const int CHAR_r = 0x72;
  static const int CHAR_s = 0x73;
  static const int CHAR_t = 0x74;
  static const int CHAR_u = 0x75;
  static const int LBRACE = 0x7b;
  static const int RBRACE = 0x7d;

  // State of partial value at chunk split.
  static const int NO_PARTIAL = 0;
  static const int PARTIAL_STRING = 1;
  static const int PARTIAL_NUMERAL = 2;
  static const int PARTIAL_KEYWORD = 3;
  static const int MASK_PARTIAL = 3;

  // Partial states for numerals. Values can be |'ed with PARTIAL_NUMERAL.
  static const int NUM_SIGN = 0; // After initial '-'.
  static const int NUM_ZERO = 4; // After '0' as first digit.
  static const int NUM_DIGIT = 8; // After digit, no '.' or 'e' seen.
  static const int NUM_DOT = 12; // After '.'.
  static const int NUM_DOT_DIGIT = 16; // After a decimal digit (after '.').
  static const int NUM_E = 20; // After 'e' or 'E'.
  static const int NUM_E_SIGN = 24; // After '-' or '+' after 'e' or 'E'.
  static const int NUM_E_DIGIT = 28; // After exponent digit.
  static const int NUM_SUCCESS = 32; // Never stored as partial state.

  // Partial states for strings.
  static const int STR_PLAIN = 0; // Inside string, but not escape.
  static const int STR_ESCAPE = 4; // After '\'.
  static const int STR_U = 16; // After '\u' and 0-3 hex digits.
  static const int STR_U_COUNT_SHIFT = 2; // Hex digit count in bits 2-3.
  static const int STR_U_VALUE_SHIFT = 5; // Hex digit value in bits 5+.

  // Partial states for keywords.
  static const int KWD_TYPE_MASK = 12;
  static const int KWD_TYPE_SHIFT = 2;
  static const int KWD_NULL = 0; // Prefix of "null" seen.
  static const int KWD_TRUE = 4; // Prefix of "true" seen.
  static const int KWD_FALSE = 8; // Prefix of "false" seen.
  static const int KWD_COUNT_SHIFT = 4; // Prefix length in bits 4+.

  // Mask used to mask off two lower bits.
  static const int TWO_BIT_MASK = 3;

  final _JsonListener listener;

  // The current parsing state.
  int state = STATE_INITIAL;
  List<int> states = <int>[];

  /**
   * Stores tokenizer state between chunks.
   *
   * This state is stored when a chunk stops in the middle of a
   * token (string, numeral, boolean or null).
   *
   * The partial state is used to continue parsing on the next chunk.
   * The previous chunk is not retained, any data needed are stored in
   * this integer, or in the [buffer] field as a string-building buffer
   * or a [_NumberBuffer].
   *
   * Prefix state stored in [prefixState] as bits.
   *
   *            ..00 : No partial value (NO_PARTIAL).
   *
   *         ..00001 : Partial string, not inside escape.
   *         ..00101 : Partial string, after '\'.
   *     ..vvvv1dd01 : Partial \u escape.
   *                   The 'dd' bits (2-3) encode the number of hex digits seen.
   *                   Bits 5-16 encode the value of the hex digits seen so far.
   *
   *        ..0ddd10 : Partial numeral.
   *                   The `ddd` bits store the parts of in the numeral seen so
   *                   far, as the constants `NUM_*` defined above.
   *                   The characters of the numeral are stored in [buffer]
   *                   as a [_NumberBuffer].
   *
   *      ..0ddd0011 : Partial 'null' keyword.
   *      ..0ddd0111 : Partial 'true' keyword.
   *      ..0ddd1011 : Partial 'false' keyword.
   *                   For all three keywords, the `ddd` bits encode the number
   *                   of letters seen.
   */
  int partialState = NO_PARTIAL;

  /**
   * Extra data stored while parsing a primitive value.
   * May be set during parsing, always set at chunk end if a value is partial.
   *
   * May contain a string buffer while parsing strings.
   */
  var buffer = null;

  _ChunkedJsonParser(this.listener);

  /**
   * Push the current parse [state] on a stack.
   *
   * State is pushed when a new array or object literal starts,
   * so the parser can go back to the correct value when the literal ends.
   */
  void saveState(int state) {
    states.add(state);
  }

  /**
   * Restore a state pushed with [saveState].
   */
  int restoreState() {
    return states.removeLast(); // Throws if empty.
  }

  /**
   * Finalizes the parsing.
   *
   * Throws if the source read so far doesn't end up with a complete
   * parsed value. That means it must not be inside a list or object
   * literal, and any partial value read should also be a valid complete
   * value.
   *
   * The only valid partial state is a number that ends in a digit, and
   * only if the number is the entire JSON value being parsed
   * (otherwise it would be inside a list or object).
   * Such a number will be completed. Any other partial state is an error.
   */
  void close() {
    if (partialState != NO_PARTIAL) {
      int partialType = partialState & MASK_PARTIAL;
      if (partialType == PARTIAL_NUMERAL) {
        int numState = partialState & ~MASK_PARTIAL;
        // A partial number might be a valid number if we know it's done.
        // There is an unnecessary overhead if input is a single number,
        // but this is assumed to be rare.
        _NumberBuffer buffer = this.buffer;
        this.buffer = null;
        finishChunkNumber(numState, 0, 0, buffer);
      } else if (partialType == PARTIAL_STRING) {
        fail(chunkEnd, "Unterminated string");
      } else {
        assert(partialType == PARTIAL_KEYWORD);
        fail(chunkEnd); // Incomplete literal.
      }
    }
    if (state != STATE_END) {
      fail(chunkEnd);
    }
  }

  /**
   * Read out the result after successfully closing the parser.
   *
   * The parser is closed by calling [close] or calling [addSourceChunk] with
   * `true` as second (`isLast`) argument.
   */
  Object get result {
    return listener.result;
  }

  /** Sets the current source chunk. */
  void set chunk(var source);

  /**
   * Length of current chunk.
   *
   * The valid arguments to [getChar] are 0 .. `chunkEnd - 1`.
   */
  int get chunkEnd;

  /**
   * Returns the chunk itself.
   *
   * Only used by [fail] to include the chunk in the thrown [FormatException].
   */
  get chunk;

  /**
   * Get charcacter/code unit of current chunk.
   *
   * The [index] must be non-negative and less than `chunkEnd`.
   * In practive, [index] will be no smaller than the `start` argument passed
   * to [parse].
   */
  int getChar(int index);

  /**
   * Copy ASCII characters from start to end of chunk into a list.
   *
   * Used for number buffer (always copies ASCII, so encoding is not important).
   */
  void copyCharsToList(int start, int end, List<int> target, int offset);

  /**
   * Build a string using input code units.
   *
   * Creates a string buffer and enables adding characters and slices
   * to that buffer.
   * The buffer is stored in the [buffer] field. If the string is unterminated,
   * the same buffer is used to continue parsing in the next chunk.
   */
  void beginString();
  /**
   * Add single character code to string being built.
   *
   * Used for unparsed escape sequences.
   */
  void addCharToString(int charCode);

  /**
   * Adds slice of current chunk to string being built.
   *
   * The [start] positions is inclusive, [end] is exclusive.
   */
  void addSliceToString(int start, int end);

  /** Finalizes the string being built and returns it as a String. */
  String endString();

  /**
   * Extracts a literal string from a slice of the current chunk.
   *
   * No interpretation of the content is performed, except for converting
   * the source format to string.
   * This can be implemented more or less efficiently depending on the
   * underlying source.
   *
   * This is used for string literals that contain no escapes.
   *
   * The [bits] integer is an upper bound on the code point in the range
   * from `start` to `end`.
   * Usually found by doing bitwise or of all the values.
   * The function may choose to optimize depending on the value.
   */
  String getString(int start, int end, int bits);

  /**
   * Parse a slice of the current chunk as an integer.
   *
   * The format is expected to be correct.
   */
  int parseInt(int start, int end) {
    const int asciiBits = 0x7f; // Integer literals are ASCII only.
    return int.parse(getString(start, end, asciiBits));
  }

  /**
   * Parse a slice of the current chunk as a double.
   *
   * The format is expected to be correct.
   * This is used by [parseNumber] when the double value cannot be
   * built exactly during parsing.
   */
  double parseDouble(int start, int end) {
    const int asciiBits = 0x7f; // Double literals are ASCII only.
    return double.parse(getString(start, end, asciiBits));
  }

  /**
   * Create a _NumberBuffer containing the digits from [start] to [chunkEnd].
   *
   * This creates a number buffer and initializes it with the part of the
   * number literal ending the current chunk
   */
  void createNumberBuffer(int start) {
    assert(start >= 0);
    assert(start < chunkEnd);
    int length = chunkEnd - start;
    var buffer = new _NumberBuffer(length);
    copyCharsToList(start, chunkEnd, buffer.list, 0);
    buffer.length = length;
    return buffer;
  }

  /**
   * Continues parsing a partial value.
   */
  int parsePartial(int position) {
    if (position == chunkEnd) return position;
    int partialState = this.partialState;
    assert(partialState != NO_PARTIAL);
    int partialType = partialState & MASK_PARTIAL;
    this.partialState = NO_PARTIAL;
    partialState = partialState & ~MASK_PARTIAL;
    assert(partialType != 0);
    if (partialType == PARTIAL_STRING) {
      position = parsePartialString(position, partialState);
    } else if (partialType == PARTIAL_NUMERAL) {
      position = parsePartialNumber(position, partialState);
    } else if (partialType == PARTIAL_KEYWORD) {
      position = parsePartialKeyword(position, partialState);
    }
    return position;
  }

  /**
   * Parses the remainder of a number into the number buffer.
   *
   * Syntax is checked while pasing.
   * Starts at position, which is expected to be the start of the chunk,
   * and returns the index of the first non-number-literal character found,
   * or chunkEnd if the entire chunk is a valid number continuation.
   * Throws if a syntax error is detected.
   */
  int parsePartialNumber(int position, int state) {
    int start = position;
    // Primitive implementation, can be optimized.
    _NumberBuffer buffer = this.buffer;
    this.buffer = null;
    int end = chunkEnd;
    toBailout:
    {
      if (position == end) break toBailout;
      int char = getChar(position);
      int digit = char ^ CHAR_0;
      if (state == NUM_SIGN) {
        if (digit <= 9) {
          if (digit == 0) {
            state = NUM_ZERO;
          } else {
            state = NUM_DIGIT;
          }
          position++;
          if (position == end) break toBailout;
          char = getChar(position);
          digit = char ^ CHAR_0;
        } else {
          return fail(position);
        }
      }
      if (state == NUM_ZERO) {
        // JSON does not allow insignificant leading zeros (e.g., "09").
        if (digit <= 9) return fail(position);
        state = NUM_DIGIT;
      }
      while (state == NUM_DIGIT) {
        if (digit > 9) {
          if (char == DECIMALPOINT) {
            state = NUM_DOT;
          } else if ((char | 0x20) == CHAR_e) {
            state = NUM_E;
          } else {
            finishChunkNumber(state, start, position, buffer);
            return position;
          }
        }
        position++;
        if (position == end) break toBailout;
        char = getChar(position);
        digit = char ^ CHAR_0;
      }
      if (state == NUM_DOT) {
        if (digit > 9) return fail(position);
        state = NUM_DOT_DIGIT;
      }
      while (state == NUM_DOT_DIGIT) {
        if (digit > 9) {
          if ((char | 0x20) == CHAR_e) {
            state = NUM_E;
          } else {
            finishChunkNumber(state, start, position, buffer);
            return position;
          }
        }
        position++;
        if (position == end) break toBailout;
        char = getChar(position);
        digit = char ^ CHAR_0;
      }
      if (state == NUM_E) {
        if (char == PLUS || char == MINUS) {
          state = NUM_E_SIGN;
          position++;
          if (position == end) break toBailout;
          char = getChar(position);
          digit = char ^ CHAR_0;
        }
      }
      assert(state >= NUM_E);
      while (digit <= 9) {
        state = NUM_E_DIGIT;
        position++;
        if (position == end) break toBailout;
        char = getChar(position);
        digit = char ^ CHAR_0;
      }
      finishChunkNumber(state, start, position, buffer);
      return position;
    }
    // Bailout code in case the current chunk ends while parsing the numeral.
    assert(position == end);
    continueChunkNumber(state, start, buffer);
    return chunkEnd;
  }

  /**
   * Continues parsing a partial string literal.
   *
   * Handles partial escapes and then hands the parsing off to
   * [parseStringToBuffer].
   */
  int parsePartialString(int position, int partialState) {
    if (partialState == STR_PLAIN) {
      return parseStringToBuffer(position);
    }
    if (partialState == STR_ESCAPE) {
      position = parseStringEscape(position);
      // parseStringEscape sets partialState if it sees the end.
      if (position == chunkEnd) return position;
      return parseStringToBuffer(position);
    }
    assert((partialState & STR_U) != 0);
    int value = partialState >> STR_U_VALUE_SHIFT;
    int count = (partialState >> STR_U_COUNT_SHIFT) & TWO_BIT_MASK;
    for (int i = count; i < 4; i++, position++) {
      if (position == chunkEnd) return chunkStringEscapeU(i, value);
      int char = getChar(position);
      int digit = parseHexDigit(char);
      if (digit < 0) fail(position, "Invalid hex digit");
      value = 16 * value + digit;
    }
    addCharToString(value);
    return parseStringToBuffer(position);
  }

  /**
   * Continues parsing a partial keyword.
   */
  int parsePartialKeyword(int position, int partialState) {
    int keywordType = partialState & KWD_TYPE_MASK;
    int count = partialState >> KWD_COUNT_SHIFT;
    int keywordTypeIndex = keywordType >> KWD_TYPE_SHIFT;
    String keyword = const ["null", "true", "false"][keywordTypeIndex];
    assert(count < keyword.length);
    do {
      if (position == chunkEnd) {
        this.partialState =
            PARTIAL_KEYWORD | keywordType | (count << KWD_COUNT_SHIFT);
        return chunkEnd;
      }
      int expectedChar = keyword.codeUnitAt(count);
      if (getChar(position) != expectedChar) return fail(position);
      position++;
      count++;
    } while (count < keyword.length);
    if (keywordType == KWD_NULL) {
      listener.handleNull();
    } else {
      listener.handleBool(keywordType == KWD_TRUE);
    }
    return position;
  }

  /** Convert hex-digit to its value. Returns -1 if char is not a hex digit. */
  int parseHexDigit(int char) {
    int digit = char ^ 0x30;
    if (digit <= 9) return digit;
    int letter = (char | 0x20) ^ 0x60;
    // values 1 .. 6 are 'a' through 'f'
    if (letter <= 6 && letter > 0) return letter + 9;
    return -1;
  }

  /**
   * Parses the current chunk as a chunk of JSON.
   *
   * Starts parsing at [position] and continues until [chunkEnd].
   * Continues parsing where the previous chunk (if any) ended.
   */
  void parse(int position) {
    int length = chunkEnd;
    if (partialState != NO_PARTIAL) {
      position = parsePartial(position);
      if (position == length) return;
    }
    int state = this.state;
    while (position < length) {
      int char = getChar(position);
      switch (char) {
        case SPACE:
        case CARRIAGE_RETURN:
        case NEWLINE:
        case TAB:
          position++;
          break;
        case QUOTE:
          if ((state & ALLOW_STRING_MASK) != 0) return fail(position);
          state |= VALUE_READ_BITS;
          position = parseString(position + 1);
          break;
        case LBRACKET:
          if ((state & ALLOW_VALUE_MASK) != 0) return fail(position);
          listener.beginArray();
          saveState(state);
          state = STATE_ARRAY_EMPTY;
          position++;
          break;
        case LBRACE:
          if ((state & ALLOW_VALUE_MASK) != 0) return fail(position);
          listener.beginObject();
          saveState(state);
          state = STATE_OBJECT_EMPTY;
          position++;
          break;
        case CHAR_n:
          if ((state & ALLOW_VALUE_MASK) != 0) return fail(position);
          state |= VALUE_READ_BITS;
          position = parseNull(position);
          break;
        case CHAR_f:
          if ((state & ALLOW_VALUE_MASK) != 0) return fail(position);
          state |= VALUE_READ_BITS;
          position = parseFalse(position);
          break;
        case CHAR_t:
          if ((state & ALLOW_VALUE_MASK) != 0) return fail(position);
          state |= VALUE_READ_BITS;
          position = parseTrue(position);
          break;
        case COLON:
          if (state != STATE_OBJECT_KEY) return fail(position);
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
            return fail(position);
          }
          break;
        case RBRACKET:
          if (state == STATE_ARRAY_EMPTY) {
            listener.endArray();
          } else if (state == STATE_ARRAY_VALUE) {
            listener.arrayElement();
            listener.endArray();
          } else {
            return fail(position);
          }
          state = restoreState() | VALUE_READ_BITS;
          position++;
          break;
        case RBRACE:
          if (state == STATE_OBJECT_EMPTY) {
            listener.endObject();
          } else if (state == STATE_OBJECT_VALUE) {
            listener.propertyValue();
            listener.endObject();
          } else {
            return fail(position);
          }
          state = restoreState() | VALUE_READ_BITS;
          position++;
          break;
        default:
          if ((state & ALLOW_VALUE_MASK) != 0) fail(position);
          state |= VALUE_READ_BITS;
          if (char == null) print("$chunk - $position");
          position = parseNumber(char, position);
          break;
      }
    }
    this.state = state;
  }

  /**
   * Parses a "true" literal starting at [position].
   *
   * The character `source[position]` must be "t".
   */
  int parseTrue(int position) {
    assert(getChar(position) == CHAR_t);
    if (chunkEnd < position + 4) {
      return parseKeywordPrefix(position, "true", KWD_TRUE);
    }
    if (getChar(position + 1) != CHAR_r ||
        getChar(position + 2) != CHAR_u ||
        getChar(position + 3) != CHAR_e) {
      return fail(position);
    }
    listener.handleBool(true);
    return position + 4;
  }

  /**
   * Parses a "false" literal starting at [position].
   *
   * The character `source[position]` must be "f".
   */
  int parseFalse(int position) {
    assert(getChar(position) == CHAR_f);
    if (chunkEnd < position + 5) {
      return parseKeywordPrefix(position, "false", KWD_FALSE);
    }
    if (getChar(position + 1) != CHAR_a ||
        getChar(position + 2) != CHAR_l ||
        getChar(position + 3) != CHAR_s ||
        getChar(position + 4) != CHAR_e) {
      return fail(position);
    }
    listener.handleBool(false);
    return position + 5;
  }

  /**
   * Parses a "null" literal starting at [position].
   *
   * The character `source[position]` must be "n".
   */
  int parseNull(int position) {
    assert(getChar(position) == CHAR_n);
    if (chunkEnd < position + 4) {
      return parseKeywordPrefix(position, "null", KWD_NULL);
    }
    if (getChar(position + 1) != CHAR_u ||
        getChar(position + 2) != CHAR_l ||
        getChar(position + 3) != CHAR_l) {
      return fail(position);
    }
    listener.handleNull();
    return position + 4;
  }

  int parseKeywordPrefix(int position, String chars, int type) {
    assert(getChar(position) == chars.codeUnitAt(0));
    int length = chunkEnd;
    int start = position;
    int count = 1;
    while (++position < length) {
      int char = getChar(position);
      if (char != chars.codeUnitAt(count)) return fail(start);
      count++;
    }
    this.partialState = PARTIAL_KEYWORD | type | (count << KWD_COUNT_SHIFT);
    return length;
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
    int end = chunkEnd;
    int bits = 0;
    while (position < end) {
      int char = getChar(position++);
      bits |= char; // Includes final '"', but that never matters.
      // BACKSLASH is larger than QUOTE and SPACE.
      if (char > BACKSLASH) {
        continue;
      }
      if (char == BACKSLASH) {
        beginString();
        int sliceEnd = position - 1;
        if (start < sliceEnd) addSliceToString(start, sliceEnd);
        return parseStringToBuffer(sliceEnd);
      }
      if (char == QUOTE) {
        listener.handleString(getString(start, position - 1, bits));
        return position;
      }
      if (char < SPACE) {
        return fail(position - 1, "Control character in string");
      }
    }
    beginString();
    if (start < end) addSliceToString(start, end);
    return chunkString(STR_PLAIN);
  }

  /**
   * Sets up a partial string state.
   *
   * The state is either not inside an escape, or right after a backslash.
   * For partial strings ending inside a Unicode escape, use
   * [chunkStringEscapeU].
   */
  int chunkString(int stringState) {
    partialState = PARTIAL_STRING | stringState;
    return chunkEnd;
  }

  /**
   * Sets up a partial string state for a partially parsed Unicode escape.
   *
   * The partial string state includes the current [buffer] and the
   * number of hex digits of the Unicode seen so far (e.g., for `"\u30')
   * the state knows that two digits have been seen, and what their value is.
   *
   * Returns [chunkEnd] so it can be used as part of a return statement.
   */
  int chunkStringEscapeU(int count, int value) {
    partialState = PARTIAL_STRING |
        STR_U |
        (count << STR_U_COUNT_SHIFT) |
        (value << STR_U_VALUE_SHIFT);
    return chunkEnd;
  }

  /**
   * Parses the remainder of a string literal into a buffer.
   *
   * The buffer is stored in [buffer] and its underlying format depends on
   * the input chunk type. For example UTF-8 decoding happens in the
   * buffer, not in the parser, since all significant JSON characters are ASCII.
   *
   * This function scans through the string literal for escapes, and copies
   * slices of non-escape characters using [addSliceToString].
   */
  int parseStringToBuffer(position) {
    int end = chunkEnd;
    int start = position;
    while (true) {
      if (position == end) {
        if (position > start) {
          addSliceToString(start, position);
        }
        return chunkString(STR_PLAIN);
      }
      int char = getChar(position++);
      if (char > BACKSLASH) continue;
      if (char < SPACE) {
        return fail(position - 1); // Control character in string.
      }
      if (char == QUOTE) {
        int quotePosition = position - 1;
        if (quotePosition > start) {
          addSliceToString(start, quotePosition);
        }
        listener.handleString(endString());
        return position;
      }
      if (char != BACKSLASH) {
        continue;
      }
      // Handle escape.
      if (position - 1 > start) {
        addSliceToString(start, position - 1);
      }
      if (position == end) return chunkString(STR_ESCAPE);
      position = parseStringEscape(position);
      if (position == end) return position;
      start = position;
    }
    return -1; // UNREACHABLE.
  }

  /**
   * Parse a string escape.
   *
   * Position is right after the initial backslash.
   * The following escape is parsed into a character code which is added to
   * the current string buffer using [addCharToString].
   *
   * Returns position after the last character of the escape.
   */
  int parseStringEscape(int position) {
    int char = getChar(position++);
    int length = chunkEnd;
    switch (char) {
      case CHAR_b:
        char = BACKSPACE;
        break;
      case CHAR_f:
        char = FORM_FEED;
        break;
      case CHAR_n:
        char = NEWLINE;
        break;
      case CHAR_r:
        char = CARRIAGE_RETURN;
        break;
      case CHAR_t:
        char = TAB;
        break;
      case SLASH:
      case BACKSLASH:
      case QUOTE:
        break;
      case CHAR_u:
        int hexStart = position - 1;
        int value = 0;
        for (int i = 0; i < 4; i++) {
          if (position == length) return chunkStringEscapeU(i, value);
          char = getChar(position++);
          int digit = char ^ 0x30;
          value *= 16;
          if (digit <= 9) {
            value += digit;
          } else {
            digit = (char | 0x20) - CHAR_a;
            if (digit < 0 || digit > 5) {
              return fail(hexStart, "Invalid unicode escape");
            }
            value += digit + 10;
          }
        }
        char = value;
        break;
      default:
        if (char < SPACE) return fail(position, "Control character in string");
        return fail(position, "Unrecognized string escape");
    }
    addCharToString(char);
    if (position == length) return chunkString(STR_PLAIN);
    return position;
  }

  /// Sets up a partial numeral state.
  /// Returns chunkEnd to allow easy one-line bailout tests.
  int beginChunkNumber(int state, int start) {
    int end = chunkEnd;
    int length = end - start;
    var buffer = new _NumberBuffer(length);
    copyCharsToList(start, end, buffer.list, 0);
    buffer.length = length;
    this.buffer = buffer;
    this.partialState = PARTIAL_NUMERAL | state;
    return end;
  }

  void addNumberChunk(_NumberBuffer buffer, int start, int end, int overhead) {
    int length = end - start;
    int count = buffer.length;
    int newCount = count + length;
    int newCapacity = newCount + overhead;
    buffer.ensureCapacity(newCapacity);
    copyCharsToList(start, end, buffer.list, count);
    buffer.length = newCount;
  }

  // Continues an already chunked number across an entire chunk.
  int continueChunkNumber(int state, int start, _NumberBuffer buffer) {
    int end = chunkEnd;
    addNumberChunk(buffer, start, end, _NumberBuffer.kDefaultOverhead);
    this.buffer = buffer;
    this.partialState = PARTIAL_NUMERAL | state;
    return end;
  }

  int finishChunkNumber(int state, int start, int end, _NumberBuffer buffer) {
    if (state == NUM_ZERO) {
      listener.handleNumber(0);
      return end;
    }
    if (end > start) {
      addNumberChunk(buffer, start, end, 0);
    }
    if (state == NUM_DIGIT) {
      listener.handleNumber(buffer.parseInt());
    } else if (state == NUM_DOT_DIGIT || state == NUM_E_DIGIT) {
      listener.handleNumber(buffer.parseDouble());
    } else {
      fail(chunkEnd, "Unterminated number literal");
    }
    return end;
  }

  int parseNumber(int char, int position) {
    // Also called on any unexpected character.
    // Format:
    //  '-'?('0'|[1-9][0-9]*)('.'[0-9]+)?([eE][+-]?[0-9]+)?
    int start = position;
    int length = chunkEnd;
    // Collects an int value while parsing. Used for both an integer literal,
    // an the exponent part of a double literal.
    int intValue = 0;
    double doubleValue = 0.0; // Collect double value while parsing.
    int sign = 1;
    bool isDouble = false;
    // Break this block when the end of the number literal is reached.
    // At that time, position points to the next character, and isDouble
    // is set if the literal contains a decimal point or an exponential.
    if (char == MINUS) {
      sign = -1;
      position++;
      if (position == length) return beginChunkNumber(NUM_SIGN, start);
      char = getChar(position);
    }
    int digit = char ^ CHAR_0;
    if (digit > 9) {
      if (sign < 0) {
        fail(position, "Missing expected digit");
      } else {
        // If it doesn't even start out as a numeral.
        fail(position, "Unexpected character");
      }
    }
    if (digit == 0) {
      position++;
      if (position == length) return beginChunkNumber(NUM_ZERO, start);
      char = getChar(position);
      digit = char ^ CHAR_0;
      // If starting with zero, next character must not be digit.
      if (digit <= 9) fail(position);
    } else {
      do {
        intValue = 10 * intValue + digit;
        position++;
        if (position == length) return beginChunkNumber(NUM_DIGIT, start);
        char = getChar(position);
        digit = char ^ CHAR_0;
      } while (digit <= 9);
    }
    if (char == DECIMALPOINT) {
      isDouble = true;
      doubleValue = intValue.toDouble();
      intValue = 0;
      position++;
      if (position == length) return beginChunkNumber(NUM_DOT, start);
      char = getChar(position);
      digit = char ^ CHAR_0;
      if (digit > 9) fail(position);
      do {
        doubleValue = 10.0 * doubleValue + digit;
        intValue -= 1;
        position++;
        if (position == length) return beginChunkNumber(NUM_DOT_DIGIT, start);
        char = getChar(position);
        digit = char ^ CHAR_0;
      } while (digit <= 9);
    }
    if ((char | 0x20) == CHAR_e) {
      if (!isDouble) {
        doubleValue = intValue.toDouble();
        intValue = 0;
        isDouble = true;
      }
      position++;
      if (position == length) return beginChunkNumber(NUM_E, start);
      char = getChar(position);
      int expSign = 1;
      int exponent = 0;
      if (char == PLUS || char == MINUS) {
        expSign = 0x2C - char; // -1 for MINUS, +1 for PLUS
        position++;
        if (position == length) return beginChunkNumber(NUM_E_SIGN, start);
        char = getChar(position);
      }
      digit = char ^ CHAR_0;
      if (digit > 9) {
        fail(position, "Missing expected digit");
      }
      do {
        exponent = 10 * exponent + digit;
        position++;
        if (position == length) return beginChunkNumber(NUM_E_DIGIT, start);
        char = getChar(position);
        digit = char ^ CHAR_0;
      } while (digit <= 9);
      intValue += expSign * exponent;
    }
    if (!isDouble) {
      listener.handleNumber(sign * intValue);
      return position;
    }
    // Double values at or above this value (2 ** 53) may have lost precission.
    // Only trust results that are below this value.
    const double maxExactDouble = 9007199254740992.0;
    if (doubleValue < maxExactDouble) {
      int exponent = intValue;
      double signedMantissa = doubleValue * sign;
      if (exponent >= -22) {
        if (exponent < 0) {
          listener.handleNumber(signedMantissa / POWERS_OF_TEN[-exponent]);
          return position;
        }
        if (exponent == 0) {
          listener.handleNumber(signedMantissa);
          return position;
        }
        if (exponent <= 22) {
          listener.handleNumber(signedMantissa * POWERS_OF_TEN[exponent]);
          return position;
        }
      }
    }
    // If the value is outside the range +/-maxExactDouble or
    // exponent is outside the range +/-22, then we can't trust simple double
    // arithmetic to get the exact result, so we use the system double parsing.
    listener.handleNumber(parseDouble(start, position));
    return position;
  }

  fail(int position, [String message]) {
    if (message == null) {
      message = "Unexpected character";
      if (position == chunkEnd) message = "Unexpected end of input";
    }
    throw new FormatException(message, chunk, position);
  }
}

/**
 * Chunked JSON parser that parses [String] chunks.
 */
class _JsonStringParser extends _ChunkedJsonParser {
  String chunk;
  int chunkEnd;

  _JsonStringParser(_JsonListener listener) : super(listener);

  int getChar(int position) => chunk.codeUnitAt(position);

  String getString(int start, int end, int bits) {
    return chunk.substring(start, end);
  }

  void beginString() {
    this.buffer = new StringBuffer();
  }

  void addSliceToString(int start, int end) {
    StringBuffer buffer = this.buffer;
    buffer.write(chunk.substring(start, end));
  }

  void addCharToString(int charCode) {
    StringBuffer buffer = this.buffer;
    buffer.writeCharCode(charCode);
  }

  String endString() {
    StringBuffer buffer = this.buffer;
    this.buffer = null;
    return buffer.toString();
  }

  void copyCharsToList(int start, int end, List target, int offset) {
    int length = end - start;
    for (int i = 0; i < length; i++) {
      target[offset + i] = chunk.codeUnitAt(start + i);
    }
  }

  double parseDouble(int start, int end) {
    return _parseDouble(chunk, start, end);
  }
}

@patch
class JsonDecoder {
  @patch
  StringConversionSink startChunkedConversion(Sink<Object> sink) {
    return new _JsonStringDecoderSink(this._reviver, sink);
  }
}

/**
 * Implements the chunked conversion from a JSON string to its corresponding
 * object.
 *
 * The sink only creates one object, but its input can be chunked.
 */
class _JsonStringDecoderSink extends StringConversionSinkBase {
  _ChunkedJsonParser _parser;
  Function _reviver;
  final Sink<Object> _sink;

  _JsonStringDecoderSink(reviver, this._sink)
      : _reviver = reviver,
        _parser = _createParser(reviver);

  static _ChunkedJsonParser _createParser(reviver) {
    _BuildJsonListener listener;
    if (reviver == null) {
      listener = new _BuildJsonListener();
    } else {
      listener = new _ReviverJsonListener(reviver);
    }
    return new _JsonStringParser(listener);
  }

  void addSlice(String chunk, int start, int end, bool isLast) {
    _parser.chunk = chunk;
    _parser.chunkEnd = end;
    _parser.parse(start);
    if (isLast) _parser.close();
  }

  void add(String chunk) {
    addSlice(chunk, 0, chunk.length, false);
  }

  void close() {
    _parser.close();
    var decoded = _parser.result;
    _sink.add(decoded);
    _sink.close();
  }

  ByteConversionSink asUtf8Sink(bool allowMalformed) {
    _parser = null;
    return new _JsonUtf8DecoderSink(_reviver, _sink, allowMalformed);
  }
}

class _Utf8StringBuffer {
  static const int INITIAL_CAPACITY = 32;
  // Partial state encoding.
  static const int MASK_TWO_BIT = 0x03;
  static const int MASK_SIZE = MASK_TWO_BIT;
  static const int SHIFT_MISSING = 2;
  static const int SHIFT_VALUE = 4;
  static const int NO_PARTIAL = 0;

  // UTF-8 encoding and limits.
  static const int MAX_ASCII = 127;
  static const int MAX_TWO_BYTE = 0x7ff;
  static const int MAX_THREE_BYTE = 0xffff;
  static const int MAX_UNICODE = 0X10ffff;
  static const int MASK_TWO_BYTE = 0x1f;
  static const int MASK_THREE_BYTE = 0x0f;
  static const int MASK_FOUR_BYTE = 0x07;
  static const int MASK_CONTINUE_TAG = 0xC0;
  static const int MASK_CONTINUE_VALUE = 0x3f;
  static const int CONTINUE_TAG = 0x80;

  // UTF-16 surrogate encoding.
  static const int LEAD_SURROGATE = 0xD800;
  static const int TAIL_SURROGATE = 0xDC00;
  static const int SHIFT_HIGH_SURROGATE = 10;
  static const int MASK_LOW_SURROGATE = 0x3ff;

  // The internal buffer starts as Uint8List, but may change to Uint16List
  // if the string contains non-Latin-1 characters.
  List<int> buffer = new Uint8List(INITIAL_CAPACITY);
  // Number of elements in buffer.
  int length = 0;
  // Partial decoding state, for cases where an UTF-8 sequences is split
  // between chunks.
  int partialState = NO_PARTIAL;
  // Whether all characters so far have been Latin-1 (and the buffer is
  // still a Uint8List). Set to false when the first non-Latin-1 character
  // is encountered, and the buffer is then also converted to a Uint16List.
  bool isLatin1 = true;
  // If allowing malformed, invalid UTF-8 sequences are converted to
  // U+FFFD.
  bool allowMalformed;

  _Utf8StringBuffer(this.allowMalformed);

  /**
   * Parse the continuation of a multi-byte UTF-8 sequence.
   *
   * Parse [utf8] from [position] to [end]. If the sequence extends beyond
   * `end`, store the partial state in [partialState], and continue from there
   * on the next added slice.
   *
   * The [size] is the number of expected continuation bytes total,
   * and [missing] is the number of remaining continuation bytes.
   * The [size] is used to detect overlong encodings.
   * The [value] is the value collected so far.
   *
   * When called after seeing the first multi-byte marker, the [size] and
   * [missing] values are always the same, but they may differ if continuing
   * after a partial sequence.
   */
  int addContinuation(
      List<int> utf8, int position, int end, int size, int missing, int value) {
    int codeEnd = position + missing;
    do {
      if (position == end) {
        missing = codeEnd - position;
        partialState =
            size | (missing << SHIFT_MISSING) | (value << SHIFT_VALUE);
        return end;
      }
      int char = utf8[position];
      if ((char & MASK_CONTINUE_TAG) != CONTINUE_TAG) {
        if (allowMalformed) {
          addCharCode(0xFFFD);
          return position;
        }
        throw new FormatException(
            "Expected UTF-8 continuation byte, "
            "found $char",
            utf8,
            position);
      }
      value = 64 * value + (char & MASK_CONTINUE_VALUE);
      position++;
    } while (position < codeEnd);
    if (value <= const [0, MAX_ASCII, MAX_TWO_BYTE, MAX_THREE_BYTE][size]) {
      // Over-long encoding.
      if (allowMalformed) {
        value = 0xFFFD;
      } else {
        throw new FormatException(
            "Invalid encoding: U+${value.toRadixString(16).padLeft(4, '0')}"
            " encoded in ${size + 1} bytes.",
            utf8,
            position - 1);
      }
    }
    addCharCode(value);
    return position;
  }

  void addCharCode(int char) {
    assert(char >= 0);
    assert(char <= MAX_UNICODE);
    if (partialState != NO_PARTIAL) {
      if (allowMalformed) {
        partialState = NO_PARTIAL;
        addCharCode(0xFFFD);
      } else {
        throw new FormatException("Incomplete UTF-8 sequence");
      }
    }
    if (isLatin1 && char > 0xff) {
      _to16Bit(); // Also grows a little if close to full.
    }
    int length = this.length;
    if (char <= MAX_THREE_BYTE) {
      if (length == buffer.length) _grow();
      buffer[length] = char;
      this.length = length + 1;
      return;
    }
    if (length + 2 > buffer.length) _grow();
    int bits = char - 0x10000;
    buffer[length] = LEAD_SURROGATE | (bits >> SHIFT_HIGH_SURROGATE);
    buffer[length + 1] = TAIL_SURROGATE | (bits & MASK_LOW_SURROGATE);
    this.length = length + 2;
  }

  void _to16Bit() {
    assert(isLatin1);
    Uint16List newBuffer;
    if ((length + INITIAL_CAPACITY) * 2 <= buffer.length) {
      // Reuse existing buffer if it's big enough.
      newBuffer = new Uint16List.view(buffer.buffer);
    } else {
      int newCapacity = buffer.length;
      if (newCapacity - length < INITIAL_CAPACITY) {
        newCapacity = length + INITIAL_CAPACITY;
      }
      newBuffer = new Uint16List(newCapacity);
    }
    newBuffer.setRange(0, length, buffer);
    buffer = newBuffer;
    isLatin1 = false;
  }

  void _grow() {
    int newCapacity = buffer.length * 2;
    List newBuffer;
    if (isLatin1) {
      newBuffer = new Uint8List(newCapacity);
    } else {
      newBuffer = new Uint16List(newCapacity);
    }
    newBuffer.setRange(0, length, buffer);
    buffer = newBuffer;
  }

  void addSlice(List<int> utf8, int position, int end) {
    assert(position < end);
    if (partialState > 0) {
      int continueByteCount = (partialState & MASK_TWO_BIT);
      int missing = (partialState >> SHIFT_MISSING) & MASK_TWO_BIT;
      int value = partialState >> SHIFT_VALUE;
      partialState = NO_PARTIAL;
      position = addContinuation(
          utf8, position, end, continueByteCount, missing, value);
      if (position == end) return;
    }
    // Keep index and capacity in local variables while looping over
    // ASCII characters.
    int index = length;
    int capacity = buffer.length;
    while (position < end) {
      int char = utf8[position];
      if (char <= MAX_ASCII) {
        if (index == capacity) {
          length = index;
          _grow();
          capacity = buffer.length;
        }
        buffer[index++] = char;
        position++;
        continue;
      }
      length = index;
      if ((char & MASK_CONTINUE_TAG) == CONTINUE_TAG) {
        if (allowMalformed) {
          addCharCode(0xFFFD);
          position++;
        } else {
          throw new FormatException(
              "Unexepected UTF-8 continuation byte", utf8, position);
        }
      } else if (char < 0xE0) {
        // C0-DF
        // Two-byte.
        position = addContinuation(
            utf8, position + 1, end, 1, 1, char & MASK_TWO_BYTE);
      } else if (char < 0xF0) {
        // E0-EF
        // Three-byte.
        position = addContinuation(
            utf8, position + 1, end, 2, 2, char & MASK_THREE_BYTE);
      } else if (char < 0xF8) {
        // F0-F7
        // Four-byte.
        position = addContinuation(
            utf8, position + 1, end, 3, 3, char & MASK_FOUR_BYTE);
      } else {
        if (allowMalformed) {
          addCharCode(0xFFFD);
          position++;
        } else {
          throw new FormatException(
              "Invalid UTF-8 byte: $char", utf8, position);
        }
      }
      index = length;
      capacity = buffer.length;
    }
    length = index;
  }

  String toString() {
    if (partialState != NO_PARTIAL) {
      if (allowMalformed) {
        partialState = NO_PARTIAL;
        addCharCode(0xFFFD);
      } else {
        int continueByteCount = (partialState & MASK_TWO_BIT);
        int missing = (partialState >> SHIFT_MISSING) & MASK_TWO_BIT;
        int value = partialState >> SHIFT_VALUE;
        int seenByteCount = continueByteCount - missing + 1;
        List source = new Uint8List(seenByteCount);
        while (seenByteCount > 1) {
          seenByteCount--;
          source[seenByteCount] = CONTINUE_TAG | (value & MASK_CONTINUE_VALUE);
          value >>= 6;
        }
        source[0] = value | (0x3c0 >> (continueByteCount - 1));
        throw new FormatException(
            "Incomplete UTF-8 sequence", source, source.length);
      }
    }
    return new String.fromCharCodes(buffer, 0, length);
  }
}

/**
 * Chunked JSON parser that parses UTF-8 chunks.
 */
class _JsonUtf8Parser extends _ChunkedJsonParser {
  final bool allowMalformed;
  List<int> chunk;
  int chunkEnd;

  _JsonUtf8Parser(_JsonListener listener, this.allowMalformed)
      : super(listener);

  int getChar(int position) => chunk[position];

  String getString(int start, int end, int bits) {
    const int maxAsciiChar = 0x7f;
    if (bits <= maxAsciiChar) {
      return new String.fromCharCodes(chunk, start, end);
    }
    beginString();
    if (start < end) addSliceToString(start, end);
    String result = endString();
    return result;
  }

  void beginString() {
    this.buffer = new _Utf8StringBuffer(allowMalformed);
  }

  void addSliceToString(int start, int end) {
    _Utf8StringBuffer buffer = this.buffer;
    buffer.addSlice(chunk, start, end);
  }

  void addCharToString(int charCode) {
    _Utf8StringBuffer buffer = this.buffer;
    buffer.addCharCode(charCode);
  }

  String endString() {
    _Utf8StringBuffer buffer = this.buffer;
    this.buffer = null;
    return buffer.toString();
  }

  void copyCharsToList(int start, int end, List target, int offset) {
    int length = end - start;
    target.setRange(offset, offset + length, chunk, start);
  }

  double parseDouble(int start, int end) {
    String string = getString(start, end, 0x7f);
    return _parseDouble(string, 0, string.length);
  }
}

double _parseDouble(String source, int start, int end) native "Double_parse";

/**
 * Implements the chunked conversion from a UTF-8 encoding of JSON
 * to its corresponding object.
 */
class _JsonUtf8DecoderSink extends ByteConversionSinkBase {
  _JsonUtf8Parser _parser;
  final Sink<Object> _sink;

  _JsonUtf8DecoderSink(reviver, this._sink, bool allowMalformed)
      : _parser = _createParser(reviver, allowMalformed);

  static _ChunkedJsonParser _createParser(reviver, bool allowMalformed) {
    _BuildJsonListener listener;
    if (reviver == null) {
      listener = new _BuildJsonListener();
    } else {
      listener = new _ReviverJsonListener(reviver);
    }
    return new _JsonUtf8Parser(listener, allowMalformed);
  }

  void addSlice(List<int> chunk, int start, int end, bool isLast) {
    _addChunk(chunk, start, end);
    if (isLast) close();
  }

  void add(List<int> chunk) {
    _addChunk(chunk, 0, chunk.length);
  }

  void _addChunk(List<int> chunk, int start, int end) {
    _parser.chunk = chunk;
    _parser.chunkEnd = end;
    _parser.parse(start);
  }

  void close() {
    _parser.close();
    var decoded = _parser.result;
    _sink.add(decoded);
    _sink.close();
  }
}
