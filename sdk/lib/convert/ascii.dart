// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.convert;

/**
 * An instance of the default implementation of the [AsciiCodec].
 *
 * This instance provides a convenient access to the most common ASCII
 * use cases.
 *
 * Examples:
 *
 *     var encoded = ASCII.encode("This is ASCII!");
 *     var decoded = ASCII.decode([0x54, 0x68, 0x69, 0x73, 0x20, 0x69, 0x73,
 *                                 0x20, 0x41, 0x53, 0x43, 0x49, 0x49, 0x21]);
 */
const AsciiCodec ASCII = const AsciiCodec();

const int _ASCII_MASK = 0x7F;

/**
 * An [AsciiCodec] allows encoding strings as ASCII bytes
 * and decoding ASCII bytes to strings.
 */
class AsciiCodec extends Encoding {
  final bool _allowInvalid;
  /**
   * Instantiates a new [AsciiCodec].
   *
   * If [allowInvalid] is true, the [decode] method and the converter
   * returned by [decoder] will default to allowing invalid values.
   * If allowing invalid values, the values will be decoded into the Unicode
   * Replacement character (U+FFFD). If not, an exception will be thrown.
   * Calls to the [decode] method can choose to override this default.
   *
   * Encoders will not accept invalid (non Latin-1) characters.
   */
  const AsciiCodec({bool allowInvalid: false}) : _allowInvalid = allowInvalid;

  String get name => "us-ascii";

  /**
   * Decodes the ASCII [bytes] (a list of unsigned 7-bit integers) to the
   * corresponding string.
   *
   * If [bytes] contains values that are not in the range 0 .. 127, the decoder
   * will eventually throw a [FormatException].
   *
   * If [allowInvalid] is not provided, it defaults to the value used to create
   * this [AsciiCodec].
   */
  String decode(List<int> bytes, { bool allowInvalid }) {
    if (allowInvalid == null) allowInvalid = _allowInvalid;
    if (allowInvalid) {
      return const AsciiDecoder(allowInvalid: true).convert(bytes);
    } else {
      return const AsciiDecoder(allowInvalid: false).convert(bytes);
    }
  }

  AsciiEncoder get encoder => const AsciiEncoder();

  AsciiDecoder get decoder =>
      _allowInvalid ? const AsciiDecoder(allowInvalid: true)
                    : const AsciiDecoder(allowInvalid: false);
}

// Superclass for [AsciiEncoder] and [Latin1Encoder].
// Generalizes common operations that only differ by a mask;
class _UnicodeSubsetEncoder extends Converter<String, List<int>> {
  final int _subsetMask;

  const _UnicodeSubsetEncoder(this._subsetMask);

  /**
   * Converts the [String] into a list of its code units.
   *
   * If [start] and [end] are provided, only the substring
   * `string.substring(start, end)` is used as input to the conversion.
   */
  List<int> convert(String string, [int start = 0, int end]) {
    int stringLength = string.length;
    RangeError.checkValidRange(start, end, stringLength);
    if (end == null) end = stringLength;
    int length = end - start;
    List result = new Uint8List(length);
    for (int i = 0; i < length; i++) {
      var codeUnit = string.codeUnitAt(start + i);
      if ((codeUnit & ~_subsetMask) != 0) {
        throw new ArgumentError("String contains invalid characters.");
      }
      result[i] = codeUnit;
    }
    return result;
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
    return new _UnicodeSubsetEncoderSink(_subsetMask, sink);
  }

  // Override the base-class' bind, to provide a better type.
  Stream<List<int>> bind(Stream<String> stream) => super.bind(stream);
}

/**
 * This class converts strings of only ASCII characters to bytes.
 */
class AsciiEncoder extends _UnicodeSubsetEncoder {
  const AsciiEncoder() : super(_ASCII_MASK);
}

/**
 * This class encodes chunked strings to bytes (unsigned 8-bit
 * integers).
 */
class _UnicodeSubsetEncoderSink extends StringConversionSinkBase {
  final ByteConversionSink _sink;
  final int _subsetMask;

  _UnicodeSubsetEncoderSink(this._subsetMask, this._sink);

  void close() {
    _sink.close();
  }

  void addSlice(String source, int start, int end, bool isLast) {
    RangeError.checkValidRange(start, end, source.length);
    for (int i = start; i < end; i++) {
      int codeUnit = source.codeUnitAt(i);
      if ((codeUnit & ~_subsetMask) != 0) {
        throw new ArgumentError(
            "Source contains invalid character with code point: $codeUnit.");
      }
    }
    _sink.add(source.codeUnits.sublist(start, end));
    if (isLast) {
      close();
    }
  }
}

/**
 * This class converts Latin-1 bytes (lists of unsigned 8-bit integers)
 * to a string.
 */
abstract class _UnicodeSubsetDecoder extends Converter<List<int>, String> {
  final bool _allowInvalid;
  final int _subsetMask;

  /**
   * Instantiates a new decoder.
   *
   * The [_allowInvalid] argument defines how [convert] deals
   * with invalid bytes.
   *
   * The [_subsetMask] argument is a bit mask used to define the subset
   * of Unicode being decoded. Use [_LATIN1_MASK] for Latin-1 (8-bit) or
   * [_ASCII_MASK] for ASCII (7-bit).
   *
   * If [_allowInvalid] is `true`, [convert] replaces invalid bytes with the
   * Unicode Replacement character `U+FFFD` (�).
   * Otherwise it throws a [FormatException].
   */
  const _UnicodeSubsetDecoder(this._allowInvalid, this._subsetMask);

  /**
   * Converts the [bytes] (a list of unsigned 7- or 8-bit integers) to the
   * corresponding string.
   *
   * If [start] and [end] are provided, only the sub-list of bytes from
   * `start` to `end` (`end` not inclusive) is used as input to the conversion.
   */
  String convert(List<int> bytes, [int start = 0, int end]) {
    int byteCount = bytes.length;
    RangeError.checkValidRange(start, end, byteCount);
    if (end == null) end = byteCount;
    int length = end - start;

    for (int i = start; i < end; i++) {
      int byte = bytes[i];
      if ((byte & ~_subsetMask) != 0) {
        if (!_allowInvalid) {
          throw new FormatException("Invalid value in input: $byte");
        }
        return _convertInvalid(bytes, start, end);
      }
    }
    return new String.fromCharCodes(bytes, start, end);
  }

  String _convertInvalid(List<int> bytes, int start, int end) {
    StringBuffer buffer = new StringBuffer();
    for (int i = start; i < end; i++) {
      int value = bytes[i];
      if ((value & ~_subsetMask) != 0) value = 0xFFFD;
      buffer.writeCharCode(value);
    }
    return buffer.toString();
  }

  /**
   * Starts a chunked conversion.
   *
   * The converter works more efficiently if the given [sink] is a
   * [StringConversionSink].
   */
  ByteConversionSink startChunkedConversion(Sink<String> sink);

  // Override the base-class's bind, to provide a better type.
  Stream<String> bind(Stream<List<int>> stream) => super.bind(stream);
}

class AsciiDecoder extends _UnicodeSubsetDecoder {
  const AsciiDecoder({bool allowInvalid: false})
      : super(allowInvalid, _ASCII_MASK);

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
    // TODO(lrn): Use asUtf16Sink when it becomes available. It
    // works just as well, is likely to have less decoding overhead,
    // and make adding U+FFFD easier.
    // At that time, merge this with _Latin1DecoderSink;
    if (_allowInvalid) {
      return new _ErrorHandlingAsciiDecoderSink(stringSink.asUtf8Sink(false));
    } else {
      return new _SimpleAsciiDecoderSink(stringSink);
    }
  }
}

class _ErrorHandlingAsciiDecoderSink extends ByteConversionSinkBase {
  ByteConversionSink _utf8Sink;
  _ErrorHandlingAsciiDecoderSink(this._utf8Sink);

  void close() {
    _utf8Sink.close();
  }

  void add(List<int> source) {
    addSlice(source, 0, source.length, false);
  }

  void addSlice(List<int> source, int start, int end, bool isLast) {
    RangeError.checkValidRange(start, end, source.length);
    for (int i = start; i < end; i++) {
      if ((source[i] & ~_ASCII_MASK) != 0) {
        if (i > start) _utf8Sink.addSlice(source, start, i, false);
        // Add UTF-8 encoding of U+FFFD.
        _utf8Sink.add(const<int>[0xEF, 0xBF, 0xBD]);
        start = i + 1;
      }
    }
    if (start < end) {
      _utf8Sink.addSlice(source, start, end, isLast);
    } else if (isLast) {
      close();
    }
  }
}

class _SimpleAsciiDecoderSink extends ByteConversionSinkBase {
  Sink _sink;
  _SimpleAsciiDecoderSink(this._sink);

  void close() {
    _sink.close();
  }

  void add(List<int> source) {
    for (int i = 0; i < source.length; i++) {
      if ((source[i] & ~_ASCII_MASK) != 0) {
        throw new FormatException("Source contains non-ASCII bytes.");
      }
    }
    _sink.add(new String.fromCharCodes(source));
  }

  void addSlice(List<int> source, int start, int end, bool isLast) {
    final int length = source.length;
    RangeError.checkValidRange(start, end, length);
    if (start < end) {
      if (start != 0 || end != length) {
        source = source.sublist(start, end);
      }
      add(source);
    }
    if (isLast) close();
  }
}
