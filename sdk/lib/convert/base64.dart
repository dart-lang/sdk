// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.convert;

/**
 * An instance of [Base64Codec].
 *
 * This instance provides a convenient access to
 * [base64](https://tools.ietf.org/html/rfc4648) encoding and decoding.
 *
 * It encodes and decodes using the default base64 alphabet, does not allow
 * any invalid characters when decoding, and requires padding.
 *
 * Examples:
 *
 *     var encoded = BASE64.encode([0x62, 0x6c, 0xc3, 0xa5, 0x62, 0xc3, 0xa6,
 *                                  0x72, 0x67, 0x72, 0xc3, 0xb8, 0x64]);
 *     var decoded = BASE64.decode("YmzDpWLDpnJncsO4ZAo=");
 */
const Base64Codec BASE64 = const Base64Codec();

// Constants used in more than one class.
const int _paddingChar = 0x3d;  // '='.

/**
 * A [base64](https://tools.ietf.org/html/rfc4648) encoder and decoder.
 *
 * A [Base64Codec] allows base64 encoding bytes into ASCII strings and
 * decoding valid encodings back to bytes.
 *
 * This implementation only handles the simplest RFC 4648 base-64 encoding.
 * It does not allow invalid characters when decoding and it requires,
 * and generates, padding so that the input is always a multiple of four
 * characters.
 */
class Base64Codec extends Codec<List<int>, String> {
  const Base64Codec();

  Base64Encoder get encoder => const Base64Encoder();

  Base64Decoder get decoder => const Base64Decoder();
}

// ------------------------------------------------------------------------
// Encoder
// ------------------------------------------------------------------------

/**
 * Base-64 encoding converter.
 *
 * Encodes lists of bytes using base64 encoding.
 * The result are ASCII strings using a restricted alphabet.
 */
class Base64Encoder extends Converter<List<int>, String> {
  const Base64Encoder();

  String convert(List<int> input) {
    if (input.isEmpty) return "";
    var encoder = new _Base64Encoder();
    Uint8List buffer = encoder.encode(input, 0, input.length, true);
    return new String.fromCharCodes(buffer);
  }

  ByteConversionSink startChunkedConversion(Sink<String> sink) {
    if (sink is StringConversionSink) {
      return new _Utf8Base64EncoderSink(sink.asUtf8Sink(false));
    }
    return new _AsciiBase64EncoderSink(sink);
  }

  Stream<String> bind(Stream<List<int>> stream) {
    return new Stream<String>.eventTransformed(
        stream,
        (EventSink sink) =>
            new _ConverterStreamEventSink<List<int>, String>(this, sink));
  }
}

/**
 * Helper class for encoding bytes to BASE-64.
 */
class _Base64Encoder {
  /** The RFC 4648 base64 encoding alphabet. */
  static const String _base64Alphabet =
      "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

  /** Shift-count to extract the values stored in [_state]. */
  static const int _valueShift = 2;

  /** Mask to extract the count value stored in [_state]. */
  static const int _countMask = 3;

  static const int _sixBitMask = 0x3F;

  /**
   * Intermediate state between chunks.
   *
   * Encoding handles three bytes at a time.
   * If fewer than three bytes has been seen, this value encodes
   * the number of bytes seen (0, 1 or 2) and their values.
   */
  int _state = 0;

  /** Encode count and bits into a value to be stored in [_state]. */
  static int _encodeState(int count, int bits) {
    assert(count <= _countMask);
    return bits << _valueShift | count;
  }

  /** Extract bits from encoded state. */
  static int _stateBits(int state) => state >> _valueShift;

  /** Extract count from encoded state. */
  static int _stateCount(int state) => state & _countMask;

  /**
   * Create a [Uint8List] with the provided length.
   */
  Uint8List createBuffer(int bufferLength) => new Uint8List(bufferLength);

  /**
   * Encode [bytes] from [start] to [end] and the bits in [_state].
   *
   * Returns a [Uint8List] of the ASCII codes of the encoded data.
   *
   * If the input, including left over [_state] from earlier encodings,
   * are not a multiple of three bytes, then the partial state is stored
   * back into [_state].
   * If [isLast] is true, partial state is encoded in the output instead,
   * with the necessary padding.
   *
   * Returns `null` if there is no output.
   */
  Uint8List encode(List<int> bytes, int start, int end, bool isLast) {
    assert(0 <= start);
    assert(start <= end);
    assert(bytes == null || end <= bytes.length);
    int length = end - start;

    int count = _stateCount(_state);
    int byteCount = (count + length);
    int fullChunks = byteCount ~/ 3;
    int partialChunkLength = byteCount - fullChunks * 3;
    int bufferLength = fullChunks * 4;
    if (isLast && partialChunkLength > 0) {
      bufferLength += 4;  // Room for padding.
    }
    var output = createBuffer(bufferLength);
    _state = encodeChunk(bytes, start, end, isLast, output, 0, _state);
    if (bufferLength > 0) return output;
    // If the input plus the data in state is still less than three bytes,
    // there may not be any output.
    return null;
  }

  static int encodeChunk(List<int> bytes, int start, int end, bool isLast,
                          Uint8List output, int outputIndex, int state) {
    int bits = _stateBits(state);
    // Count number of missing bytes in three-byte chunk.
    int expectedChars = 3 - _stateCount(state);

    // The input must be a list of bytes (integers in the range 0..255).
    // The value of `byteOr` will be the bitwise or of all the values in
    // `bytes` and a later check will validate that they were all valid bytes.
    int byteOr = 0;
    for (int i = start; i < end; i++) {
      int byte = bytes[i];
      byteOr |= byte;
      bits = ((bits << 8) | byte) & 0xFFFFFF;  // Never store more than 24 bits.
      expectedChars--;
      if (expectedChars == 0) {
        output[outputIndex++] =
            _base64Alphabet.codeUnitAt((bits >> 18) & _sixBitMask);
        output[outputIndex++] =
            _base64Alphabet.codeUnitAt((bits >> 12) & _sixBitMask);
        output[outputIndex++] =
            _base64Alphabet.codeUnitAt((bits >> 6) & _sixBitMask);
        output[outputIndex++] =
            _base64Alphabet.codeUnitAt(bits & _sixBitMask);
        expectedChars = 3;
        bits = 0;
      }
    }
    if (byteOr >= 0 && byteOr <= 255) {
      if (isLast && expectedChars < 3) {
        writeFinalChunk(output, outputIndex, 3 - expectedChars, bits);
        return 0;
      }
      return _encodeState(3 - expectedChars, bits);
    }

    // There was an invalid byte value somewhere in the input - find it!
    int i = start;
    while (i < end) {
      int byte = bytes[i];
      if (byte < 0 || byte > 255) break;
      i++;
    }
    throw new ArgumentError.value(bytes,
        "Not a byte value at index $i: 0x${bytes[i].toRadixString(16)}");
  }

  /**
   * Writes a final encoded four-character chunk.
   *
   * Only used when the [_state] contains a partial (1 or 2 byte)
   * input.
   */
  static void writeFinalChunk(Uint8List output, int outputIndex,
                              int count, int bits) {
    assert(count > 0);
    if (count == 1) {
      output[outputIndex++] =
          _base64Alphabet.codeUnitAt((bits >> 2) & _sixBitMask);
      output[outputIndex++] =
          _base64Alphabet.codeUnitAt((bits << 4) & _sixBitMask);
      output[outputIndex++] = _paddingChar;
      output[outputIndex++] = _paddingChar;
    } else {
      assert(count == 2);
      output[outputIndex++] =
          _base64Alphabet.codeUnitAt((bits >> 10) & _sixBitMask);
      output[outputIndex++] =
          _base64Alphabet.codeUnitAt((bits >> 4) & _sixBitMask);
      output[outputIndex++] =
          _base64Alphabet.codeUnitAt((bits << 2) & _sixBitMask);
      output[outputIndex++] = _paddingChar;
    }
  }
}

class _BufferCachingBase64Encoder extends _Base64Encoder {
  /**
   * Reused buffer.
   *
   * When the buffer isn't released to the sink, only used to create another
   * value (a string), the buffer can be reused between chunks.
   */
  Uint8List bufferCache;

  Uint8List createBuffer(int bufferLength) {
    if (bufferCache == null || bufferCache.length < bufferLength) {
      bufferCache = new Uint8List(bufferLength);
    }
    // Return a view of the buffer, so it has the reuested length.
    return new Uint8List.view(bufferCache.buffer, 0, bufferLength);
  }
}

abstract class _Base64EncoderSink extends ByteConversionSinkBase {
  void add(List<int> source) {
    _add(source, 0, source.length, false);
  }

  void close() {
    _add(null, 0, 0, true);
  }

  void addSlice(List<int> source, int start, int end, bool isLast) {
    if (end == null) throw new ArgumentError.notNull("end");
    RangeError.checkValidRange(start, end, source.length);
    _add(source, start, end, isLast);
  }

  void _add(List<int> source, int start, int end, bool isLast);
}

class _AsciiBase64EncoderSink extends _Base64EncoderSink {
  final _Base64Encoder _encoder = new _BufferCachingBase64Encoder();

  final ChunkedConversionSink<String> _sink;

  _AsciiBase64EncoderSink(this._sink);

  void _add(List<int> source, int start, int end, bool isLast) {
    Uint8List buffer = _encoder.encode(source, start, end, isLast);
    if (buffer != null) {
      String string = new String.fromCharCodes(buffer);
      _sink.add(string);
    }
    if (isLast) {
      _sink.close();
    }
  }
}

class _Utf8Base64EncoderSink extends _Base64EncoderSink {
  final ByteConversionSink _sink;
  final _Base64Encoder _encoder = new _Base64Encoder();

  _Utf8Base64EncoderSink(this._sink);

  void _add(List<int> source, int start, int end, bool isLast) {
    Uint8List buffer = _encoder.encode(source, start, end, isLast);
    if (buffer != null) {
      _sink.addSlice(buffer, 0, buffer.length, isLast);
    }
  }
}

// ------------------------------------------------------------------------
// Decoder
// ------------------------------------------------------------------------

class Base64Decoder extends Converter<String, List<int>> {
  const Base64Decoder();

  List<int> convert(String input) {
    if (input.isEmpty) return new Uint8List(0);
    int length = input.length;
    if (length % 4 != 0) {
      throw new FormatException("Invalid length, must be multiple of four",
                                input, length);
    }
    var decoder = new _Base64Decoder();
    Uint8List buffer = decoder.decode(input, 0, input.length);
    decoder.close(input, input.length);
    return buffer;
  }

  StringConversionSink startChunkedConversion(Sink<List<int>> sink) {
    return new _Base64DecoderSink(sink);
  }
}

/**
 * Helper class implementing base64 decoding with intermediate state.
 */
class _Base64Decoder {
  /** Shift-count to extract the values stored in [_state]. */
  static const int _valueShift = 2;

  /** Mask to extract the count value stored in [_state]. */
  static const int _countMask = 3;

  /** Invalid character in decoding table. */
  static const int _invalid = -2;

  /** Padding character in decoding table. */
  static const int _padding = -1;

  // Shorthands to make the table more readable.
  static const int __ = _invalid;
  static const int _p = _padding;

  /**
   * Mapping from ASCII characters to their index in the base64 alphabet.
   *
   * Uses [_invalid] for invalid indices and [_padding] for the padding
   * character.
   */
  static final List<int> _inverseAlphabet = new Int8List.fromList([
    __, __, __, __, __, __, __, __, __, __, __, __, __, __, __, __,
    __, __, __, __, __, __, __, __, __, __, __, __, __, __, __, __,
    __, __, __, __, __, __, __, __, __, __, __, 62, __, __, __, 63,
    52, 53, 54, 55, 56, 57, 58, 59, 60, 61, __, __, __, _p, __, __,
    __,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14,
    15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, __, __, __, __, __,
    __, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
    41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, __, __, __, __, __,
  ]);

  /**
   * Maintains the intermediate state of a partly-decoded input.
   *
   * BASE-64 is decoded in chunks of four characters. If a chunk does not
   * contain a full block, the decoded bits (six per character) of the
   * available characters are stored in [_state] until the next call to
   * [_decode] or [_close].
   *
   * If no padding has been seen, the value is
   *   `numberOfCharactersSeen | (decodedBits << 2)`
   * where `numberOfCharactersSeen` is between 0 and 3 and decoded bits
   * contains six bits per seen character.
   *
   * If padding has been seen the value is negative. It's the bitwise negation
   * of the number of remanining allowed padding characters (always ~0 or ~1).
   *
   * A state of `0` or `~0` are valid places to end decoding, all other values
   * mean that a four-character block has not been completed.
   */
  int _state = 0;

  /**
   * Encodes [count] and [bits] as a value to be stored in [_state].
   */
  static int _encodeCharacterState(int count, int bits) {
    assert(count == (count & _countMask));
    return (bits << _valueShift | count);
  }

  /**
   * Extracts count from a [_state] value.
   */
  static int _stateCount(int state) {
    assert(state >= 0);
    return state & _countMask;
  }

  /**
   * Extracts value bits from a [_state] value.
   */
  static int _stateBits(int state) {
    assert(state >= 0);
    return state >> _valueShift;
  }

  /**
   * Encodes a number of expected padding characters to be stored in [_state].
   */
  static int _encodePaddingState(int expectedPadding) {
    assert(expectedPadding >= 0);
    assert(expectedPadding <= 1);
    return -expectedPadding - 1;  // ~expectedPadding adapted to dart2js.
  }

  /**
   * Extracts expected padding character count from a [_state] value.
   */
  static int _statePadding(int state) {
    assert(state < 0);
    return -state - 1;  // ~state adapted to dart2js.
  }

  static bool _hasSeenPadding(int state) => state < 0;

  /**
   * Decodes [input] from [start] to [end].
   *
   * Returns a [Uint8List] with the decoded bytes.
   * If a previous call had an incomplete four-character block, the bits from
   * those are included in decoding
   */
  Uint8List decode(String input, int start, int end) {
    assert(0 <= start);
    assert(start <= end);
    assert(end <= input.length);
    if (_hasSeenPadding(_state)) {
      _state = _checkPadding(input, start, end, _state);
      return null;
    }
    if (start == end) return new Uint8List(0);
    Uint8List buffer = _allocateBuffer(input, start, end, _state);
    _state = decodeChunk(input, start, end, buffer, 0, _state);
    return buffer;
  }

  /** Checks that [_state] represents a valid decoding. */
  void close(String input, int end) {
    if (_state < _encodePaddingState(0)) {
      throw new FormatException("Missing padding character", input, end);
    }
    if (_state > 0) {
      throw new FormatException("Invalid length, must be multiple of four",
                                input, end);
    }
    _state = _encodePaddingState(0);
  }

  /**
   * Decodes [input] from [start] to [end].
   *
   * Includes the state returned by a previous call in the decoding.
   * Writes the decoding to [output] at [outIndex], and there must
   * be room in the output.
   */
  static int decodeChunk(String input, int start, int end,
                          Uint8List output, int outIndex,
                          int state) {
    assert(!_hasSeenPadding(state));
    const int asciiMask = 127;
    const int asciiMax = 127;
    const int eightBitMask = 0xFF;
    const int bitsPerCharacter = 6;

    int bits = _stateBits(state);
    int count = _stateCount(state);
    // String contents should be all ASCII.
    // Instead of checking for each character, we collect the bitwise-or of
    // all the characters in `charOr` and later validate that all characters
    // were ASCII.
    int charOr = 0;
    for (int i = start; i < end; i++) {
      var char = input.codeUnitAt(i);
      charOr |= char;
      int code = _inverseAlphabet[char & asciiMask];
      if (code >= 0) {
        bits = ((bits << bitsPerCharacter) | code) & 0xFFFFFF;
        count = (count + 1) & 3;
        if (count == 0) {
          assert(outIndex + 3 <= output.length);
          output[outIndex++] = (bits >> 16) & eightBitMask;
          output[outIndex++] = (bits >> 8) & eightBitMask;
          output[outIndex++] = bits & eightBitMask;
          bits = 0;
        }
        continue;
      } else if (code == _padding && count > 1) {
        if (count == 3) {
          if ((bits & 0x03) != 0) {
            throw new FormatException(
                "Invalid encoding before padding", input, i);
          }
          output[outIndex++] = bits >> 10;
          output[outIndex++] = bits >> 2;
        } else {
          if ((bits & 0x0F) != 0) {
            throw new FormatException(
                "Invalid encoding before padding", input, i);
          }
          output[outIndex++] = bits >> 4;
        }
        int expectedPadding = 3 - count;
        state = _encodePaddingState(expectedPadding);
        return _checkPadding(input, i + 1, end, state);
      }
      throw new FormatException("Invalid character", input, i);
    }
    if (charOr >= 0 && charOr <= asciiMax) {
      return _encodeCharacterState(count, bits);
    }
    // There is an invalid (non-ASCII) character in the input.
    int i;
    for (i = start; i < end; i++) {
      int char = input.codeUnitAt(i);
      if (char < 0 || char > asciiMax) break;
    }
    throw new FormatException("Invalid character", input, i);
  }

  /**
   * Allocates a buffer with room for the decoding of a substring of [input].
   *
   * Includes room for the characters in [state], and handles padding correctly.
   */
  static Uint8List _allocateBuffer(String input, int start, int end,
                                   int state) {
    assert(state >= 0);
    int padding = 0;
    int length = _stateCount(state) + (end - start);
    if (end > start && input.codeUnitAt(end - 1) == _paddingChar) {
      padding++;
      if (end - 1 > start && input.codeUnitAt(end - 2) == _paddingChar) {
        padding++;
      }
    }
    // Three bytes per full four bytes in the input.
    int bufferLength = (length >> 2) * 3;
    // If padding was seen, then remove the padding if it was counter, or
    // add the last partial chunk it it wasn't counted.
    int remainderLength = length & 3;
    if (remainderLength == 0) {
      bufferLength -= padding;
    } else if (padding != 0 && remainderLength - padding > 1) {
      bufferLength += remainderLength - 1 - padding;
    }
    if (bufferLength > 0) return new Uint8List(bufferLength);
    // If the input plus state is less than four characters, no buffer
    // is needed.
    return null;
  }

  /**
   * Check that the remainder of the string is valid padding.
   *
   * That means zero or one padding character (depending on [_state])
   * and nothing else.
   */
  static int _checkPadding(String input, int start, int end, int state) {
    assert(_hasSeenPadding(state));
    if (start == end) return state;
    int expectedPadding = _statePadding(state);
    if (expectedPadding > 0) {
      int firstChar = input.codeUnitAt(start);
      if (firstChar != _paddingChar) {
        throw new FormatException("Missing padding character", input, start);
      }
      state = _encodePaddingState(0);
      start++;
    }
    if (start != end) {
      throw new FormatException("Invalid character after padding",
                                input, start);
    }
    return state;
  }
}

class _Base64DecoderSink extends StringConversionSinkBase {
  /** Output sink */
  final ChunkedConversionSink<List<int>> _sink;
  final _Base64Decoder _decoder = new _Base64Decoder();

  _Base64DecoderSink(this._sink);

  void add(String string) {
    if (string.isEmpty) return;
    Uint8List buffer = _decoder.decode(string, 0, string.length);
    if (buffer != null) _sink.add(buffer);
  }

  void close() {
    _decoder.close(null, null);
    _sink.close();
  }

  void addSlice(String string, int start, int end, bool isLast) {
    end = RangeError.checkValidRange(start, end, string.length);
    if (start == end) return;
    Uint8List buffer = _decoder.decode(string, start, end);
    if (buffer != null) _sink.add(buffer);
    if (isLast) {
      _decoder.close(string, end);
      _sink.close();
    }
  }
}
