// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.convert;

/**
 * A [base64](https://tools.ietf.org/html/rfc4648) encoder and decoder.
 *
 * It encodes using the default base64 alphabet,
 * decodes using both the base64 and base64url alphabets,
 * does not allow invalid characters and requires padding.
 *
 * Examples:
 *
 *     var encoded = BASE64.encode([0x62, 0x6c, 0xc3, 0xa5, 0x62, 0xc3, 0xa6,
 *                                  0x72, 0x67, 0x72, 0xc3, 0xb8, 0x64]);
 *     var decoded = BASE64.decode("YmzDpWLDpnJncsO4ZAo=");
 */
const Base64Codec BASE64 = const Base64Codec();

/**
 * A [base64url](https://tools.ietf.org/html/rfc4648) encoder and decoder.
 *
 * It encodes and decodes using the base64url alphabet,
 * decodes using both the base64 and base64url alphabets,
 * does not allow invalid characters and requires padding.
 *
 * Examples:
 *
 *     var encoded = BASE64URL.encode([0x62, 0x6c, 0xc3, 0xa5, 0x62, 0xc3, 0xa6,
 *                                     0x72, 0x67, 0x72, 0xc3, 0xb8, 0x64]);
 *     var decoded = BASE64URL.decode("YmzDpWLDpnJncsO4ZAo=");
 */
const Base64Codec BASE64URL = const Base64Codec.urlSafe();

// Constants used in more than one class.
const int _paddingChar = 0x3d; // '='.

/**
 * A [base64](https://tools.ietf.org/html/rfc4648) encoder and decoder.
 *
 * A [Base64Codec] allows base64 encoding bytes into ASCII strings and
 * decoding valid encodings back to bytes.
 *
 * This implementation only handles the simplest RFC 4648 base64 and base64url
 * encodings.
 * It does not allow invalid characters when decoding and it requires,
 * and generates, padding so that the input is always a multiple of four
 * characters.
 */
class Base64Codec extends Codec<List<int>, String> {
  final Base64Encoder _encoder;
  const Base64Codec() : _encoder = const Base64Encoder();
  const Base64Codec.urlSafe() : _encoder = const Base64Encoder.urlSafe();

  Base64Encoder get encoder => _encoder;

  Base64Decoder get decoder => const Base64Decoder();

  /**
   * Validates and normalizes the base64 encoded data in [source].
   *
   * Only acts on the substring from [start] to [end], with [end]
   * defaulting to the end of the string.
   *
   * Normalization will:
   * * Unescape any `%`-escapes.
   * * Only allow valid characters (`A`-`Z`, `a`-`z`, `0`-`9`, `/` and `+`).
   * * Normalize a `_` or `-` character to `/` or `+`.
   * * Validate that existing padding (trailing `=` characters) is correct.
   * * If no padding exists, add correct padding if necessary and possible.
   * * Validate that the length is correct (a multiple of four).
   */
  String normalize(String source, [int start = 0, int end]) {
    end = RangeError.checkValidRange(start, end, source.length);
    const int percent = 0x25;
    const int equals = 0x3d;
    StringBuffer buffer = null;
    int sliceStart = start;
    var alphabet = _Base64Encoder._base64Alphabet;
    var inverseAlphabet = _Base64Decoder._inverseAlphabet;
    int firstPadding = -1;
    int firstPaddingSourceIndex = -1;
    int paddingCount = 0;
    for (int i = start; i < end;) {
      int sliceEnd = i;
      int char = source.codeUnitAt(i++);
      int originalChar = char;
      // Normalize char, keep originalChar to see if it matches the source.
      if (char == percent) {
        if (i + 2 <= end) {
          char = parseHexByte(source, i); // May be negative.
          i += 2;
          // We know that %25 isn't valid, but our table considers it
          // a potential padding start, so skip the checks.
          if (char == percent) char = -1;
        } else {
          // An invalid HEX escape (too short).
          // Just skip past the handling and reach the throw below.
          char = -1;
        }
      }
      // If char is negative here, hex-decoding failed in some way.
      if (0 <= char && char <= 127) {
        int value = inverseAlphabet[char];
        if (value >= 0) {
          char = alphabet.codeUnitAt(value);
          if (char == originalChar) continue;
        } else if (value == _Base64Decoder._padding) {
          // We have ruled out percent, so char is '='.
          if (firstPadding < 0) {
            // Mark position in normalized output where padding occurs.
            firstPadding = (buffer?.length ?? 0) + (sliceEnd - sliceStart);
            firstPaddingSourceIndex = sliceEnd;
          }
          paddingCount++;
          // It could have been an escaped equals (%3D).
          if (originalChar == equals) continue;
        }
        if (value != _Base64Decoder._invalid) {
          buffer ??= new StringBuffer();
          buffer.write(source.substring(sliceStart, sliceEnd));
          buffer.writeCharCode(char);
          sliceStart = i;
          continue;
        }
      }
      throw new FormatException("Invalid base64 data", source, sliceEnd);
    }
    if (buffer != null) {
      buffer.write(source.substring(sliceStart, end));
      if (firstPadding >= 0) {
        // There was padding in the source. Check that it is valid:
        // * result length a multiple of four
        // * one or two padding characters at the end.
        _checkPadding(source, firstPaddingSourceIndex, end, firstPadding,
            paddingCount, buffer.length);
      } else {
        // Length of last chunk (1-4 chars) in the encoding.
        int endLength = ((buffer.length - 1) % 4) + 1;
        if (endLength == 1) {
          // The data must have length 0, 2 or 3 modulo 4.
          throw new FormatException(
              "Invalid base64 encoding length ", source, end);
        }
        while (endLength < 4) {
          buffer.write("=");
          endLength++;
        }
      }
      return source.replaceRange(start, end, buffer.toString());
    }
    // Original was already normalized, only check padding.
    int length = end - start;
    if (firstPadding >= 0) {
      _checkPadding(source, firstPaddingSourceIndex, end, firstPadding,
          paddingCount, length);
    } else {
      // No padding given, so add some if needed it.
      int endLength = length % 4;
      if (endLength == 1) {
        // The data must have length 0, 2 or 3 modulo 4.
        throw new FormatException(
            "Invalid base64 encoding length ", source, end);
      }
      if (endLength > 1) {
        // There is no "insertAt" on String, but this works as well.
        source = source.replaceRange(end, end, (endLength == 2) ? "==" : "=");
      }
    }
    return source;
  }

  static int _checkPadding(String source, int sourceIndex, int sourceEnd,
      int firstPadding, int paddingCount, int length) {
    if (length % 4 != 0) {
      throw new FormatException(
          "Invalid base64 padding, padded length must be multiple of four, "
          "is $length",
          source,
          sourceEnd);
    }
    if (firstPadding + paddingCount != length) {
      throw new FormatException(
          "Invalid base64 padding, '=' not at the end", source, sourceIndex);
    }
    if (paddingCount > 2) {
      throw new FormatException(
          "Invalid base64 padding, more than two '=' characters",
          source,
          sourceIndex);
    }
  }
}

// ------------------------------------------------------------------------
// Encoder
// ------------------------------------------------------------------------

/**
 * Base64 and base64url encoding converter.
 *
 * Encodes lists of bytes using base64 or base64url encoding.
 *
 * The results are ASCII strings using a restricted alphabet.
 */
class Base64Encoder extends Converter<List<int>, String> {
  final bool _urlSafe;

  const Base64Encoder() : _urlSafe = false;
  const Base64Encoder.urlSafe() : _urlSafe = true;

  String convert(List<int> input) {
    if (input.isEmpty) return "";
    var encoder = new _Base64Encoder(_urlSafe);
    Uint8List buffer = encoder.encode(input, 0, input.length, true);
    return new String.fromCharCodes(buffer);
  }

  ByteConversionSink startChunkedConversion(Sink<String> sink) {
    if (sink is StringConversionSink) {
      return new _Utf8Base64EncoderSink(sink.asUtf8Sink(false), _urlSafe);
    }
    return new _AsciiBase64EncoderSink(sink, _urlSafe);
  }
}

/**
 * Helper class for encoding bytes to base64.
 */
class _Base64Encoder {
  /** The RFC 4648 base64 encoding alphabet. */
  static const String _base64Alphabet =
      "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

  /** The RFC 4648 base64url encoding alphabet. */
  static const String _base64urlAlphabet =
      "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";

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

  /** Alphabet used for encoding. */
  final String _alphabet;

  _Base64Encoder(bool urlSafe)
      : _alphabet = urlSafe ? _base64urlAlphabet : _base64Alphabet;

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
      bufferLength += 4; // Room for padding.
    }
    var output = createBuffer(bufferLength);
    _state =
        encodeChunk(_alphabet, bytes, start, end, isLast, output, 0, _state);
    if (bufferLength > 0) return output;
    // If the input plus the data in state is still less than three bytes,
    // there may not be any output.
    return null;
  }

  static int encodeChunk(String alphabet, List<int> bytes, int start, int end,
      bool isLast, Uint8List output, int outputIndex, int state) {
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
      bits = ((bits << 8) | byte) & 0xFFFFFF; // Never store more than 24 bits.
      expectedChars--;
      if (expectedChars == 0) {
        output[outputIndex++] = alphabet.codeUnitAt((bits >> 18) & _sixBitMask);
        output[outputIndex++] = alphabet.codeUnitAt((bits >> 12) & _sixBitMask);
        output[outputIndex++] = alphabet.codeUnitAt((bits >> 6) & _sixBitMask);
        output[outputIndex++] = alphabet.codeUnitAt(bits & _sixBitMask);
        expectedChars = 3;
        bits = 0;
      }
    }
    if (byteOr >= 0 && byteOr <= 255) {
      if (isLast && expectedChars < 3) {
        writeFinalChunk(alphabet, output, outputIndex, 3 - expectedChars, bits);
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
    throw new ArgumentError.value(
        bytes, "Not a byte value at index $i: 0x${bytes[i].toRadixString(16)}");
  }

  /**
   * Writes a final encoded four-character chunk.
   *
   * Only used when the [_state] contains a partial (1 or 2 byte)
   * input.
   */
  static void writeFinalChunk(
      String alphabet, Uint8List output, int outputIndex, int count, int bits) {
    assert(count > 0);
    if (count == 1) {
      output[outputIndex++] = alphabet.codeUnitAt((bits >> 2) & _sixBitMask);
      output[outputIndex++] = alphabet.codeUnitAt((bits << 4) & _sixBitMask);
      output[outputIndex++] = _paddingChar;
      output[outputIndex++] = _paddingChar;
    } else {
      assert(count == 2);
      output[outputIndex++] = alphabet.codeUnitAt((bits >> 10) & _sixBitMask);
      output[outputIndex++] = alphabet.codeUnitAt((bits >> 4) & _sixBitMask);
      output[outputIndex++] = alphabet.codeUnitAt((bits << 2) & _sixBitMask);
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

  _BufferCachingBase64Encoder(bool urlSafe) : super(urlSafe);

  Uint8List createBuffer(int bufferLength) {
    if (bufferCache == null || bufferCache.length < bufferLength) {
      bufferCache = new Uint8List(bufferLength);
    }
    // Return a view of the buffer, so it has the requested length.
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
  final Sink<String> _sink;
  final _Base64Encoder _encoder;

  _AsciiBase64EncoderSink(this._sink, bool urlSafe)
      : _encoder = new _BufferCachingBase64Encoder(urlSafe);

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
  final _Base64Encoder _encoder;

  _Utf8Base64EncoderSink(this._sink, bool urlSafe)
      : _encoder = new _Base64Encoder(urlSafe);

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

/**
 * Decoder for base64 encoded data.
 *
 * This decoder accepts both base64 and base64url ("url-safe") encodings.
 *
 * The encoding is required to be properly padded.
 */
class Base64Decoder extends Converter<String, List<int>> {
  const Base64Decoder();

  List<int> convert(String input, [int start = 0, int end]) {
    end = RangeError.checkValidRange(start, end, input.length);
    if (start == end) return new Uint8List(0);
    var decoder = new _Base64Decoder();
    Uint8List buffer = decoder.decode(input, start, end);
    decoder.close(input, end);
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
   *
   * Accepts the "URL-safe" alphabet as well (`-` and `_` are the
   * 62nd and 63rd alphabet characters), and considers `%` a padding
   * character, which must then be followed by `3D`, the percent-escape
   * for `=`.
   */
  static final List<int> _inverseAlphabet = new Int8List.fromList([
    __, __, __, __, __, __, __, __, __, __, __, __, __, __, __, __, //
    __, __, __, __, __, __, __, __, __, __, __, __, __, __, __, __, //
    __, __, __, __, __, _p, __, __, __, __, __, 62, __, 62, __, 63, //
    52, 53, 54, 55, 56, 57, 58, 59, 60, 61, __, __, __, _p, __, __, //
    __, 00, 01, 02, 03, 04, 05, 06, 07, 08, 09, 10, 11, 12, 13, 14, //
    15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, __, __, __, __, 63, //
    __, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, //
    41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, __, __, __, __, __, //
  ]);

  // Character constants.
  static const int _char_percent = 0x25; // '%'.
  static const int _char_3 = 0x33; // '3'.
  static const int _char_d = 0x64; // 'd'.

  /**
   * Maintains the intermediate state of a partly-decoded input.
   *
   * Base64 is decoded in chunks of four characters. If a chunk does not
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
   * of the number of remaining allowed padding characters (always ~0 or ~1).
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
    assert(expectedPadding <= 5);
    return -expectedPadding - 1; // ~expectedPadding adapted to dart2js.
  }

  /**
   * Extracts expected padding character count from a [_state] value.
   */
  static int _statePadding(int state) {
    assert(state < 0);
    return -state - 1; // ~state adapted to dart2js.
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
      throw new FormatException(
          "Invalid length, must be multiple of four", input, end);
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
  static int decodeChunk(String input, int start, int end, Uint8List output,
      int outIndex, int state) {
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
        if (charOr < 0 || charOr > asciiMax) break;
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
        // Expected padding is the number of expected padding characters,
        // where `=` counts as three and `%3D` counts as one per character.
        //
        // Expect either zero or one padding depending on count (2 or 3),
        // plus two more characters if the code was `%` (a partial padding).
        int expectedPadding = (3 - count) * 3;
        if (char == _char_percent) expectedPadding += 2;
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
  static Uint8List _allocateBuffer(
      String input, int start, int end, int state) {
    assert(state >= 0);
    int paddingStart = _trimPaddingChars(input, start, end);
    int length = _stateCount(state) + (paddingStart - start);
    // Three bytes per full four bytes in the input.
    int bufferLength = (length >> 2) * 3;
    // If padding was seen, then this is the last chunk, and the final partial
    // chunk should be decoded too.
    int remainderLength = length & 3;
    if (remainderLength != 0 && paddingStart < end) {
      bufferLength += remainderLength - 1;
    }
    if (bufferLength > 0) return new Uint8List(bufferLength);
    // If the input plus state is less than four characters, and it's not
    // at the end of input, no buffer is needed.
    return null;
  }

  /**
   * Returns the position of the start of padding at the end of the input.
   *
   * Returns the end of input if there is no padding.
   *
   * This is used to ensure that the decoding buffer has the exact size
   * it needs when input is valid, and at least enough bytes to reach the error
   * when input is invalid.
   *
   * Never count more than two padding sequences since any more than that
   * will raise an error anyway, and we only care about being precise for
   * successful conversions.
   */
  static int _trimPaddingChars(String input, int start, int end) {
    // This may count '%=' as two paddings. That's ok, it will err later,
    // but the buffer will be large enough to reach the error.
    int padding = 0;
    int index = end;
    int newEnd = end;
    while (index > start && padding < 2) {
      index--;
      int char = input.codeUnitAt(index);
      if (char == _paddingChar) {
        padding++;
        newEnd = index;
        continue;
      }
      if ((char | 0x20) == _char_d) {
        if (index == start) break;
        index--;
        char = input.codeUnitAt(index);
      }
      if (char == _char_3) {
        if (index == start) break;
        index--;
        char = input.codeUnitAt(index);
      }
      if (char == _char_percent) {
        padding++;
        newEnd = index;
        continue;
      }
      break;
    }
    return newEnd;
  }

  /**
   * Check that the remainder of the string is valid padding.
   *
   * Valid padding is a correct number (0, 1 or 2) of `=` characters
   * or `%3D` sequences depending on the number of preceding base64 characters.
   * The [state] parameter encodes which padding continuations are allowed
   * as the number of expected characters. That number is the number of
   * expected padding characters times 3 minus the number of padding characters
   * seen so far, where `=` counts as 3 counts as three characters,
   * and the padding sequence `%3D` counts as one character per character.
   *
   * The number of missing characters is always between 0 and 5 because we
   * only call this function after having seen at least one `=` or `%`
   * character.
   * If the number of missing characters is not 3 or 0, we have seen (at least)
   * a `%` character and expects the rest of the `%3D` sequence, and a `=` is
   * not allowed. When missing 3 characters, either `=` or `%` is allowed.
   *
   * When the value is 0, no more padding (or any other character) is allowed.
   */
  static int _checkPadding(String input, int start, int end, int state) {
    assert(_hasSeenPadding(state));
    if (start == end) return state;
    int expectedPadding = _statePadding(state);
    assert(expectedPadding >= 0);
    assert(expectedPadding < 6);
    while (expectedPadding > 0) {
      int char = input.codeUnitAt(start);
      if (expectedPadding == 3) {
        if (char == _paddingChar) {
          expectedPadding -= 3;
          start++;
          break;
        }
        if (char == _char_percent) {
          expectedPadding--;
          start++;
          if (start == end) break;
          char = input.codeUnitAt(start);
        } else {
          break;
        }
      }
      // Partial padding means we have seen part of a "%3D" escape.
      int expectedPartialPadding = expectedPadding;
      if (expectedPartialPadding > 3) expectedPartialPadding -= 3;
      if (expectedPartialPadding == 2) {
        // Expects '3'
        if (char != _char_3) break;
        start++;
        expectedPadding--;
        if (start == end) break;
        char = input.codeUnitAt(start);
      }
      // Expects 'D' or 'd'.
      if ((char | 0x20) != _char_d) break;
      start++;
      expectedPadding--;
      if (start == end) break;
    }
    if (start != end) {
      throw new FormatException("Invalid padding character", input, start);
    }
    return _encodePaddingState(expectedPadding);
  }
}

class _Base64DecoderSink extends StringConversionSinkBase {
  /** Output sink */
  final Sink<List<int>> _sink;
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
