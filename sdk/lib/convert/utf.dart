// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.convert;

const UTF8 = const Utf8Codec();

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

  /**
   * Decodes the UTF-8 [codeUnits] (a list of unsigned 8-bit integers) to the
   * corresponding string.
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
 * A [Utf8Encoder] converts strings to their UTF-8 code units (a list of
 * unsigned 8-bit integers).
 */
class Utf8Encoder extends Converter<String, List<int>> {
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
}

/**
 * This class encodes Strings to UTF-8 code units (unsigned 8 bit integers).
 */
// TODO(floitsch): make this class public.
class _Utf8Encoder {
  int _carry = 0;
  int _bufferIndex = 0;
  final Uint8List _buffer;

  static const _DEFAULT_BYTE_BUFFER_SIZE = 1024;

  _Utf8Encoder() : this.withBufferSize(_DEFAULT_BYTE_BUFFER_SIZE);

  _Utf8Encoder.withBufferSize(int bufferSize)
      : _buffer = new Uint8List(bufferSize);

  /**
   * Tries to combine the given [leadingSurrogate] with the [nextCodeUnit] and
   * writes it to [_buffer].
   *
   * Returns true if the [nextCodeUnit] was combined with the
   * [leadingSurrogate]. If it wasn't then nextCodeUnit has not been written
   * yet.
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
      if (codeUnit < _ONE_BYTE_LIMIT) {
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
  Utf8Decoder({ bool allowMalformed: false })
      : this._allowMalformed = allowMalformed;

  /**
   * Converts the UTF-8 [codeUnits] (a list of unsigned 8-bit integers) to the
   * corresponding string.
   */
  String convert(List<int> codeUnits) {
    StringBuffer buffer = new StringBuffer();
    _Utf8Decoder decoder = new _Utf8Decoder(_allowMalformed);
    decoder.convert(codeUnits, 0, codeUnits.length, buffer);
    decoder.close(buffer);
    return buffer.toString();
  }
}

// UTF-8 constants.
const int _ONE_BYTE_LIMIT = 0x7f;   // 7 bytes
const int _TWO_BYTE_LIMIT = 0x7ff;  // 11 bytes
const int _THREE_BYTE_LIMIT = 0xffff;  // 16 bytes
const int _FOUR_BYTE_LIMIT = 0x10ffff;  // 21 bytes, truncated to Unicode max.

// UTF-16 constants.
const int _SURROGATE_MASK = 0xF800;
const int _SURROGATE_TAG_MASK = 0xFC00;
const int _SURROGATE_VALUE_MASK = 0x3FF;
const int _LEAD_SURROGATE_MIN = 0xD800;
const int _TAIL_SURROGATE_MIN = 0xDC00;

const int _REPLACEMENT_CHARACTER = 0xFFFD;
const int _BOM_CHARACTER = 0xFEFF;

bool _isSurrogate(int codeUnit) =>
    (codeUnit & _SURROGATE_MASK) == _LEAD_SURROGATE_MIN;
bool _isLeadSurrogate(int codeUnit) =>
    (codeUnit & _SURROGATE_TAG_MASK) == _LEAD_SURROGATE_MIN;
bool _isTailSurrogate(int codeUnit) =>
    (codeUnit & _SURROGATE_TAG_MASK) == _TAIL_SURROGATE_MIN;
int _combineSurrogatePair(int lead, int tail) =>
    0x10000 | ((lead & _SURROGATE_VALUE_MASK) << 10)
            | (tail & _SURROGATE_VALUE_MASK);


/**
 * Decodes UTF-8.
 *
 * The decoder handles chunked input.
 */
// TODO(floitsch): make this class public.
class _Utf8Decoder {
  final bool _allowMalformed;
  bool _isFirstCharacter = true;
  int _value = 0;
  int _expectedUnits = 0;
  int _extraUnits = 0;

  _Utf8Decoder(this._allowMalformed);

  bool get hasPartialInput => _expectedUnits > 0;

  // Limits of one through four byte encodings.
  static const List<int> _LIMITS = const <int>[
      _ONE_BYTE_LIMIT,
      _TWO_BYTE_LIMIT,
      _THREE_BYTE_LIMIT,
      _FOUR_BYTE_LIMIT ];

  void close(StringSink sink) {
    if (hasPartialInput) {
      if (!_allowMalformed) {
        throw new FormatException("Unfinished UTF-8 octet sequence");
      }
      sink.writeCharCode(_REPLACEMENT_CHARACTER);
    }
  }

  void convert(List<int> codeUnits, int startIndex, int endIndex,
               StringSink sink) {
    int value = _value;
    int expectedUnits = _expectedUnits;
    int extraUnits = _extraUnits;
    _value = 0;
    _expectedUnits = 0;
    _extraUnits = 0;

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
            sink.writeCharCode(_REPLACEMENT_CHARACTER);
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
          value = _REPLACEMENT_CHARACTER;
        }
        if (value > _FOUR_BYTE_LIMIT) {
          if (!_allowMalformed) {
            throw new FormatException("Character outside valid Unicode range: "
                                      "0x${value.toRadixString(16)}");
          }
          value = _REPLACEMENT_CHARACTER;
        }
        if (!_isFirstCharacter || value != _BOM_CHARACTER) {
          sink.writeCharCode(value);
        }
        _isFirstCharacter = false;
      }

      while (i < endIndex) {
        int unit = codeUnits[i++];
        if (unit <= _ONE_BYTE_LIMIT) {
          _isFirstCharacter = false;
          sink.writeCharCode(unit);
        } else {
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
          value = _REPLACEMENT_CHARACTER;
          expectedUnits = extraUnits = 0;
          _isFirstCharacter = false;
          sink.writeCharCode(value);
        }
      }
      break loop;
    }
    if (expectedUnits > 0) {
      _value = value;
      _expectedUnits = expectedUnits;
      _extraUnits = extraUnits;
    }
  }
}
