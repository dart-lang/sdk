// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.convert;

/** The Unicode Replacement character `U+FFFD` (�). */
const int UNICODE_REPLACEMENT_CHARACTER_RUNE = 0xFFFD;

/** The Unicode Byte Order Marker (BOM) character `U+FEFF`. */
const int UNICODE_BOM_CHARACTER_RUNE = 0xFEFF;

/**
 * An instance of the default implementation of the [Utf8Codec].
 *
 * This instance provides a convenient access to the most common UTF-8
 * use cases.
 *
 * Examples:
 *
 *     var encoded = UTF8.encode("Îñţérñåţîöñåļîžåţîờñ");
 *     var decoded = UTF8.decode([0x62, 0x6c, 0xc3, 0xa5, 0x62, 0xc3, 0xa6,
 *                                0x72, 0x67, 0x72, 0xc3, 0xb8, 0x64]);
 */
const Utf8Codec UTF8 = const Utf8Codec();

/**
 * A [Utf8Codec] encodes strings to utf-8 code units (bytes) and decodes
 * UTF-8 code units to strings.
 */
class Utf8Codec extends Encoding {
  final bool _allowMalformed;

  /**
   * Instantiates a new [Utf8Codec].
   *
   * The optional [allowMalformed] argument defines how [decoder] (and [decode])
   * deal with invalid or unterminated character sequences.
   *
   * If it is `true` (and not overriden at the method invocation) [decode] and
   * the [decoder] replace invalid (or unterminated) octet
   * sequences with the Unicode Replacement character `U+FFFD` (�). Otherwise
   * they throw a [FormatException].
   */
  const Utf8Codec({ bool allowMalformed: false })
      : _allowMalformed = allowMalformed;

  String get name => "utf-8";

  /**
   * Decodes the UTF-8 [codeUnits] (a list of unsigned 8-bit integers) to the
   * corresponding string.
   *
   * If the [codeUnits] start with a leading [UNICODE_BOM_CHARACTER_RUNE] this
   * character is discarded.
   *
   * If [allowMalformed] is `true` the decoder replaces invalid (or
   * unterminated) character sequences with the Unicode Replacement character
   * `U+FFFD` (�). Otherwise it throws a [FormatException].
   *
   * If [allowMalformed] is not given, it defaults to the `allowMalformed` that
   * was used to instantiate `this`.
   */
  String decode(List<int> codeUnits, { bool allowMalformed }) {
    if (allowMalformed == null) allowMalformed = _allowMalformed;
    return new Utf8Decoder(allowMalformed: allowMalformed).convert(codeUnits);
  }

  Converter<String, List<int>> get encoder => new Utf8Encoder();
  Converter<List<int>, String> get decoder {
    return new Utf8Decoder(allowMalformed: _allowMalformed);
  }
}

/**
 * This class converts strings to their UTF-8 code units (a list of
 * unsigned 8-bit integers).
 */
class Utf8Encoder extends Converter<String, List<int>> {

  const Utf8Encoder();

  /**
   * Converts [string] to its UTF-8 code units (a list of
   * unsigned 8-bit integers).
   */
  List<int> convert(String string) {
    // Create a new encoder with a length that is guaranteed to be big enough.
    // A single code unit uses at most 3 bytes. Two code units at most 4.
    _Utf8Encoder encoder = new _Utf8Encoder.withBufferSize(string.length * 3);
    int endPosition = encoder._fillBuffer(string, 0, string.length);
    assert(endPosition >= string.length - 1);
    if (endPosition != string.length) {
      int lastCodeUnit = string.codeUnitAt(string.length - 1);
      assert(_isLeadSurrogate(lastCodeUnit));
      // We use a non-surrogate as `nextUnit` so that _writeSurrogate just
      // writes the lead-surrogate.
      bool wasCombined = encoder._writeSurrogate(lastCodeUnit, 0);
      assert(!wasCombined);
    }
    return encoder._buffer.sublist(0, encoder._bufferIndex);
  }

  /**
   * Starts a chunked conversion.
   *
   * The converter works more efficiently if the given [sink] is a
   * [ByteConversionSink].
   */
  StringConversionSink startChunkedConversion(Sink<List<int>> sink) {
    if (sink is! ByteConversionSink) {
      sink = new ByteConversionSink.from(sink);
    }
    return new _Utf8EncoderSink(sink);
  }

  // Override the base-classes bind, to provide a better type.
  Stream<List<int>> bind(Stream<String> stream) => super.bind(stream);
}

/**
 * This class encodes Strings to UTF-8 code units (unsigned 8 bit integers).
 */
// TODO(floitsch): make this class public.
class _Utf8Encoder {
  int _carry = 0;
  int _bufferIndex = 0;
  final List<int> _buffer;

  static const _DEFAULT_BYTE_BUFFER_SIZE = 1024;

  _Utf8Encoder() : this.withBufferSize(_DEFAULT_BYTE_BUFFER_SIZE);

  _Utf8Encoder.withBufferSize(int bufferSize)
      : _buffer = _createBuffer(bufferSize);

  // TODO(11971): Always use Uint8List.
  /**
   * Allow an implementation to pick the most efficient way of storing bytes.
   */
  external static List<int> _createBuffer(int size);

  /**
   * Tries to combine the given [leadingSurrogate] with the [nextCodeUnit] and
   * writes it to [_buffer].
   *
   * Returns true if the [nextCodeUnit] was combined with the
   * [leadingSurrogate]. If it wasn't then nextCodeUnit was not a trailing
   * surrogate and has not been written yet.
   *
   * It is safe to pass 0 for [nextCodeUnit] in which case only the leading
   * surrogate is written.
   */
  bool _writeSurrogate(int leadingSurrogate, int nextCodeUnit) {
    if (_isTailSurrogate(nextCodeUnit)) {
      int rune = _combineSurrogatePair(leadingSurrogate, nextCodeUnit);
      // If the rune is encoded with 2 code-units then it must be encoded
      // with 4 bytes in UTF-8.
      assert(rune > _THREE_BYTE_LIMIT);
      assert(rune <= _FOUR_BYTE_LIMIT);
      _buffer[_bufferIndex++] = 0xF0 | (rune >> 18);
      _buffer[_bufferIndex++] = 0x80 | ((rune >> 12) & 0x3f);
      _buffer[_bufferIndex++] = 0x80 | ((rune >> 6) & 0x3f);
      _buffer[_bufferIndex++] = 0x80 | (rune & 0x3f);
      return true;
    } else {
      // TODO(floitsch): allow to throw on malformed strings.
      // Encode the half-surrogate directly into UTF-8. This yields
      // invalid UTF-8, but we started out with invalid UTF-16.

      // Surrogates are always encoded in 3 bytes in UTF-8.
      _buffer[_bufferIndex++] = 0xE0 | (leadingSurrogate >> 12);
      _buffer[_bufferIndex++] = 0x80 | ((leadingSurrogate >> 6) & 0x3f);
      _buffer[_bufferIndex++] = 0x80 | (leadingSurrogate & 0x3f);
      return false;
    }
  }

  /**
   * Fills the [_buffer] with as many characters as possible.
   *
   * Does not encode any trailing lead-surrogate. This must be done by the
   * caller.
   *
   * Returns the position in the string. The returned index points to the
   * first code unit that hasn't been encoded.
   */
  int _fillBuffer(String str, int start, int end) {
    if (start != end && _isLeadSurrogate(str.codeUnitAt(end - 1))) {
      // Don't handle a trailing lead-surrogate in this loop. The caller has
      // to deal with those.
      end--;
    }
    int stringIndex;
    for (stringIndex = start; stringIndex < end; stringIndex++) {
      int codeUnit = str.codeUnitAt(stringIndex);
      // ASCII has the same representation in UTF-8 and UTF-16.
      if (codeUnit <= _ONE_BYTE_LIMIT) {
        if (_bufferIndex >= _buffer.length) break;
        _buffer[_bufferIndex++] = codeUnit;
      } else if (_isLeadSurrogate(codeUnit)) {
        if (_bufferIndex + 3 >= _buffer.length) break;
        // Note that it is safe to read the next code unit. We decremented
        // [end] above when the last valid code unit was a leading surrogate.
        int nextCodeUnit = str.codeUnitAt(stringIndex + 1);
        bool wasCombined = _writeSurrogate(codeUnit, nextCodeUnit);
        if (wasCombined) stringIndex++;
      } else {
        int rune = codeUnit;
        if (rune <= _TWO_BYTE_LIMIT) {
          if (_bufferIndex + 1 >= _buffer.length) break;
          _buffer[_bufferIndex++] = 0xC0 | (rune >> 6);
          _buffer[_bufferIndex++] = 0x80 | (rune & 0x3f);
        } else {
          assert(rune <= _THREE_BYTE_LIMIT);
          if (_bufferIndex + 2 >= _buffer.length) break;
          _buffer[_bufferIndex++] = 0xE0 | (rune >> 12);
          _buffer[_bufferIndex++] = 0x80 | ((rune >> 6) & 0x3f);
          _buffer[_bufferIndex++] = 0x80 | (rune & 0x3f);
        }
      }
    }
    return stringIndex;
  }
}

/**
 * This class encodes chunked strings to UTF-8 code units (unsigned 8-bit
 * integers).
 */
class _Utf8EncoderSink extends _Utf8Encoder with StringConversionSinkMixin {

  final ByteConversionSink _sink;

  _Utf8EncoderSink(this._sink);

  void close() {
    if (_carry != 0) {
      // addSlice will call close again, but then the carry must be equal to 0.
      addSlice("", 0, 0, true);
      return;
    }
    _sink.close();
  }

  void addSlice(String str, int start, int end, bool isLast) {
    _bufferIndex = 0;

    if (start == end && !isLast) {
      return;
    }

    if (_carry != 0) {
      int nextCodeUnit = 0;
      if (start != end) {
        nextCodeUnit = str.codeUnitAt(start);
      } else {
        assert(isLast);
      }
      bool wasCombined = _writeSurrogate(_carry, nextCodeUnit);
      // Either we got a non-empty string, or we must not have been combined.
      assert(!wasCombined || start != end );
      if (wasCombined) start++;
      _carry = 0;
    }
    do {
      start = _fillBuffer(str, start, end);
      bool isLastSlice = isLast && (start == end);
      if (start == end - 1 && _isLeadSurrogate(str.codeUnitAt(start))) {
        if (isLast && _bufferIndex < _buffer.length - 3) {
          // There is still space for the last incomplete surrogate.
          // We use a non-surrogate as second argument. This way the
          // function will just add the surrogate-half to the buffer.
          bool hasBeenCombined = _writeSurrogate(str.codeUnitAt(start), 0);
          assert(!hasBeenCombined);
        } else {
          // Otherwise store it in the carry. If isLast is true, then
          // close will flush the last carry.
          _carry = str.codeUnitAt(start);
        }
        start++;
      }
      _sink.addSlice(_buffer, 0, _bufferIndex, isLastSlice);
      _bufferIndex = 0;
    } while (start < end);
    if (isLast) close();
  }

  // TODO(floitsch): implement asUtf8Sink. Sligthly complicated because it
  // needs to deal with malformed input.
}

/**
 * This class converts UTF-8 code units (lists of unsigned 8-bit integers)
 * to a string.
 */
class Utf8Decoder extends Converter<List<int>, String> {
  final bool _allowMalformed;

  /**
   * Instantiates a new [Utf8Decoder].
   *
   * The optional [allowMalformed] argument defines how [convert] deals
   * with invalid or unterminated character sequences.
   *
   * If it is `true` [convert] replaces invalid (or unterminated) character
   * sequences with the Unicode Replacement character `U+FFFD` (�). Otherwise
   * it throws a [FormatException].
   */
  const Utf8Decoder({ bool allowMalformed: false })
      : this._allowMalformed = allowMalformed;

  /**
   * Converts the UTF-8 [codeUnits] (a list of unsigned 8-bit integers) to the
   * corresponding string.
   *
   * If the [codeUnits] start with a leading [UNICODE_BOM_CHARACTER_RUNE] this
   * character is discarded.
   */
  String convert(List<int> codeUnits) {
    StringBuffer buffer = new StringBuffer();
    _Utf8Decoder decoder = new _Utf8Decoder(buffer, _allowMalformed);
    decoder.convert(codeUnits, 0, codeUnits.length);
    decoder.close();
    return buffer.toString();
  }

  /**
   * Starts a chunked conversion.
   *
   * The converter works more efficiently if the given [sink] is a
   * [StringConversionSink].
   */
  ByteConversionSink startChunkedConversion(Sink<String> sink) {
    StringConversionSink stringSink;
    if (sink is StringConversionSink) {
      stringSink = sink;
    } else {
      stringSink = new StringConversionSink.from(sink);
    }
    return stringSink.asUtf8Sink(_allowMalformed);
  }

  // Override the base-classes bind, to provide a better type.
  Stream<String> bind(Stream<List<int>> stream) => super.bind(stream);
}

// UTF-8 constants.
const int _ONE_BYTE_LIMIT = 0x7f;   // 7 bits
const int _TWO_BYTE_LIMIT = 0x7ff;  // 11 bits
const int _THREE_BYTE_LIMIT = 0xffff;  // 16 bits
const int _FOUR_BYTE_LIMIT = 0x10ffff;  // 21 bits, truncated to Unicode max.

// UTF-16 constants.
const int _SURROGATE_MASK = 0xF800;
const int _SURROGATE_TAG_MASK = 0xFC00;
const int _SURROGATE_VALUE_MASK = 0x3FF;
const int _LEAD_SURROGATE_MIN = 0xD800;
const int _TAIL_SURROGATE_MIN = 0xDC00;

bool _isSurrogate(int codeUnit) =>
    (codeUnit & _SURROGATE_MASK) == _LEAD_SURROGATE_MIN;
bool _isLeadSurrogate(int codeUnit) =>
    (codeUnit & _SURROGATE_TAG_MASK) == _LEAD_SURROGATE_MIN;
bool _isTailSurrogate(int codeUnit) =>
    (codeUnit & _SURROGATE_TAG_MASK) == _TAIL_SURROGATE_MIN;
int _combineSurrogatePair(int lead, int tail) =>
    0x10000 + ((lead & _SURROGATE_VALUE_MASK) << 10)
            | (tail & _SURROGATE_VALUE_MASK);


/**
 * Decodes UTF-8.
 *
 * The decoder handles chunked input.
 */
// TODO(floitsch): make this class public.
class _Utf8Decoder {
  final bool _allowMalformed;
  final StringSink _stringSink;
  bool _isFirstCharacter = true;
  int _value = 0;
  int _expectedUnits = 0;
  int _extraUnits = 0;

  _Utf8Decoder(this._stringSink, this._allowMalformed);

  bool get hasPartialInput => _expectedUnits > 0;

  // Limits of one through four byte encodings.
  static const List<int> _LIMITS = const <int>[
      _ONE_BYTE_LIMIT,
      _TWO_BYTE_LIMIT,
      _THREE_BYTE_LIMIT,
      _FOUR_BYTE_LIMIT ];

  void close() {
    flush();
  }

  /**
   * Flushes this decoder as if closed.
   *
   * This method throws if the input was partial and the decoder was
   * constructed with `allowMalformed` set to `false`.
   */
  void flush() {
    if (hasPartialInput) {
      if (!_allowMalformed) {
        throw new FormatException("Unfinished UTF-8 octet sequence");
      }
      _stringSink.writeCharCode(UNICODE_REPLACEMENT_CHARACTER_RUNE);
      _value = 0;
      _expectedUnits = 0;
      _extraUnits = 0;
    }
  }

  void convert(List<int> codeUnits, int startIndex, int endIndex) {
    int value = _value;
    int expectedUnits = _expectedUnits;
    int extraUnits = _extraUnits;
    int singleBytesCount = 0;
    _value = 0;
    _expectedUnits = 0;
    _extraUnits = 0;

    void addSingleBytes(int from, int to) {
      assert(singleBytesCount > 0);
      assert(from >= startIndex && from <= endIndex);
      assert(to >= startIndex && to <= endIndex);
      if (from == 0 && to == codeUnits.length) {
        _stringSink.write(new String.fromCharCodes(codeUnits));
      } else {
        _stringSink.write(
            new String.fromCharCodes(codeUnits.sublist(from, to)));
      }
      singleBytesCount = 0;
    }

    int i = startIndex;
    loop: while (true) {
      multibyte: if (expectedUnits > 0) {
        do {
          if (i == endIndex) {
            break loop;
          }
          int unit = codeUnits[i];
          if ((unit & 0xC0) != 0x80) {
            expectedUnits = 0;
            if (!_allowMalformed) {
              throw new FormatException(
                  "Bad UTF-8 encoding 0x${unit.toRadixString(16)}");
            }
            _isFirstCharacter = false;
            _stringSink.writeCharCode(UNICODE_REPLACEMENT_CHARACTER_RUNE);
            break multibyte;
          } else {
            value = (value << 6) | (unit & 0x3f);
            expectedUnits--;
            i++;
          }
        } while (expectedUnits > 0);
        if (value <= _LIMITS[extraUnits - 1]) {
          // Overly long encoding. The value could be encoded with a shorter
          // encoding.
          if (!_allowMalformed) {
            throw new FormatException(
                "Overlong encoding of 0x${value.toRadixString(16)}");
          }
          expectedUnits = extraUnits = 0;
          value = UNICODE_REPLACEMENT_CHARACTER_RUNE;
        }
        if (value > _FOUR_BYTE_LIMIT) {
          if (!_allowMalformed) {
            throw new FormatException("Character outside valid Unicode range: "
                                      "0x${value.toRadixString(16)}");
          }
          value = UNICODE_REPLACEMENT_CHARACTER_RUNE;
        }
        if (!_isFirstCharacter || value != UNICODE_BOM_CHARACTER_RUNE) {
          _stringSink.writeCharCode(value);
        }
        _isFirstCharacter = false;
      }

      while (i < endIndex) {
        int unit = codeUnits[i++];
        // TODO(floitsch): the way we test we could potentially allow
        // units that are too large, if they happen to have the
        // right bit-pattern. (Same is true for the multibyte loop above).
        // TODO(floitsch): optimize this loop. See:
        // https://codereview.chromium.org/22929022/diff/1/sdk/lib/convert/utf.dart?column_width=80
        if (unit < 0) {
          // TODO(floitsch): should this be unit <= 0 ?
          if (singleBytesCount > 0) {
            int to = i - 1;
            addSingleBytes(to - singleBytesCount, to);
          }
          if (!_allowMalformed) {
            throw new FormatException(
                "Negative UTF-8 code unit: -0x${(-unit).toRadixString(16)}");
          }
          _stringSink.writeCharCode(UNICODE_REPLACEMENT_CHARACTER_RUNE);
        } else if (unit <= _ONE_BYTE_LIMIT) {
          _isFirstCharacter = false;
          singleBytesCount++;
        } else {
          if (singleBytesCount > 0) {
            int to = i - 1;
            addSingleBytes(to - singleBytesCount, to);
          }
          if ((unit & 0xE0) == 0xC0) {
            value = unit & 0x1F;
            expectedUnits = extraUnits = 1;
            continue loop;
          }
          if ((unit & 0xF0) == 0xE0) {
            value = unit & 0x0F;
            expectedUnits = extraUnits = 2;
            continue loop;
          }
          // 0xF5, 0xF6 ... 0xFF never appear in valid UTF-8 sequences.
          if ((unit & 0xF8) == 0xF0 && unit < 0xF5) {
            value = unit & 0x07;
            expectedUnits = extraUnits = 3;
            continue loop;
          }
          if (!_allowMalformed) {
            throw new FormatException(
                "Bad UTF-8 encoding 0x${unit.toRadixString(16)}");
          }
          value = UNICODE_REPLACEMENT_CHARACTER_RUNE;
          expectedUnits = extraUnits = 0;
          _isFirstCharacter = false;
          _stringSink.writeCharCode(value);
        }
      }
      break loop;
    }
    if (singleBytesCount > 0) {
      addSingleBytes(i - singleBytesCount, endIndex);
    }
    if (expectedUnits > 0) {
      _value = value;
      _expectedUnits = expectedUnits;
      _extraUnits = extraUnits;
    }
  }
}
