// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

/// The current system encoding.
const SystemEncoding SYSTEM_ENCODING = const SystemEncoding();

/**
 * The system encoding is the current code page on Windows and UTF-8 on
 * Linux and Mac.
 */
class SystemEncoding extends Encoding {
  const SystemEncoding();

  String get name => 'system';

  List<int> encode(String input) => encoder.convert(input);
  String decode(List<int> encoded) => decoder.convert(encoded);

  Converter<String, List<int>> get encoder {
    if (Platform.operatingSystem == "windows") {
      return const _WindowsCodePageEncoder();
    } else {
      return const Utf8Encoder();
    }
  }

  Converter<List<int>, String> get decoder {
    if (Platform.operatingSystem == "windows") {
      return const _WindowsCodePageDecoder();
    } else {
      return const Utf8Decoder();
    }
  }
}

class _WindowsCodePageEncoder extends Converter<String, List<int>> {

  const _WindowsCodePageEncoder();

  List<int> convert(String input) {
    List<int> encoded = _encodeString(input);
    if (encoded == null) {
      throw new FormatException("Invalid character for encoding");
    }
    return encoded;
  }

  /**
   * Starts a chunked conversion.
   */
  StringConversionSink startChunkedConversion(Sink<List<int>> sink) {
    return new _WindowsCodePageEncoderSink(sink);
  }

  // Override the base-class' bind, to provide a better type.
  Stream<List<int>> bind(Stream<String> stream) => super.bind(stream);

  external static List<int> _encodeString(String string);
}

class _WindowsCodePageEncoderSink extends StringConversionSinkBase {
  // TODO(floitsch): provide more efficient conversions when the input is
  // not a String.

  final Sink<List<int>> _sink;

  _WindowsCodePageEncoderSink(this._sink);

  void close() {
    _sink.close();
  }

  void add(String string) {
    List<int> encoded = _WindowsCodePageEncoder._encodeString(string);
    if (encoded == null) {
      throw new FormatException("Invalid character for encoding");
    }
    _sink.add(encoded);
  }

  void addSlice(String source, int start, int end, bool isLast) {
    if (start != 0 || end != source.length) {
      source = source.substring(start, end);
    }
    add(source);
    if (isLast) close();
  }
}


class _WindowsCodePageDecoder extends Converter<List<int>, String> {

  const _WindowsCodePageDecoder();

  String convert(List<int> input) {
    return _decodeBytes(input);
  }

  /**
   * Starts a chunked conversion.
   */
  ByteConversionSink startChunkedConversion(Sink<String> sink) {
    return new _WindowsCodePageDecoderSink(sink);
  }

  // Override the base-class' bind, to provide a better type.
  Stream<String> bind(Stream<List<int>> stream) => super.bind(stream);

  external static String _decodeBytes(List<int> bytes);
}

class _WindowsCodePageDecoderSink extends ByteConversionSinkBase {
  // TODO(floitsch): provide more efficient conversions when the input is
  // a slice.

  final Sink<String> _sink;

  _WindowsCodePageDecoderSink(this._sink);

  void close() {
    _sink.close();
  }

  void add(List<int> bytes) {
    _sink.add(_WindowsCodePageDecoder._decodeBytes(bytes));
  }
}
