// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

/**
 * String encodings.
 */
class Encoding {
  static const Encoding UTF_8 = const Encoding._internal("utf-8");
  static const Encoding ISO_8859_1 = const Encoding._internal("iso-8859-1");
  static const Encoding ASCII = const Encoding._internal("us-ascii");

  /**
   * SYSTEM encoding is the current code page on Windows and UTF-8 on
   * Linux and Mac.
   */
  static const Encoding SYSTEM = const Encoding._internal("system");

  // All aliasses (in lowercase) of supported encoding from
  // http://www.iana.org/assignments/character-sets/character-sets.xml.
  static Map<String, Encoding> _nameToEncoding = <String, Encoding> {
    // ISO_8859-1:1987.
    "iso_8859-1:1987": ISO_8859_1,
    "iso-ir-100": ISO_8859_1,
    "iso_8859-1": ISO_8859_1,
    "iso-8859-1": ISO_8859_1,
    "latin1": ISO_8859_1,
    "l1": ISO_8859_1,
    "ibm819": ISO_8859_1,
    "cp819": ISO_8859_1,
    "csisolatin1": ISO_8859_1,

    // US-ASCII.
    "iso-ir-6": ASCII,
    "ansi_x3.4-1968": ASCII,
    "ansi_x3.4-1986": ASCII,
    "iso_646.irv:1991": ASCII,
    "iso646-us": ASCII,
    "us-ascii": ASCII,
    "us": ASCII,
    "ibm367": ASCII,
    "cp367": ASCII,
    "csascii": ASCII,
    "ascii": ASCII,  // This is not in the IANA official names.

    // UTF-8.
    "csutf8": UTF_8,
    "utf-8": UTF_8
  };

  /**
   * Gets an [Encoding] object from the name of the character set
   * name. The names used are the IANA official names for the
   * character set (see
   * http://www.iana.org/assignments/character-sets/character-sets.xml).
   *
   * The [name] passed is case insensitive.
   *
   * If character set is not supported [:null:] is returned.
   */
  static Encoding fromName(String name) {
    if (name == null) return null;
    name = name.toLowerCase();
    return _nameToEncoding[name];
  }

  /**
   * Name of the encoding. This will be the lower-case version of one of the
   * IANA official names for the character set (see
   * http://www.iana.org/assignments/character-sets/character-sets.xml)
   */
  final String name;

  const Encoding._internal(String this.name);
}

const UTF_8 = Encoding.UTF_8;
const ISO_8859_1 = Encoding.ISO_8859_1;
const ASCII = Encoding.ASCII;

/**
 * Stream transformer that can decode a stream of bytes into a stream of
 * strings using [encoding].
 *
 * Invalid or forbidden byte-sequences will not produce errors, but will instead
 * insert [replacementChar] in the decoded strings.
 */
class StringDecoder implements StreamTransformer<List<int>, String> {
  var _decoder;

  /**
   * Decodes a stream of bytes into a `String` with an optional
   * [encoding] and [replacementChar].
   *
   * The default value for [encoding] is [Encoding.UTF_8].
   *
   * The default value for [replacementChar] is code point U+FFFD.
   *
   * Completes with the decoded `String` when the stream is done.
   */
  static Future<String> decode(
      Stream<List<int>> stream,
      [Encoding encoding = Encoding.UTF_8,
       int replacementChar = UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]) {
    return stream
        .transform(new StringDecoder(encoding, replacementChar))
        .fold(
            new StringBuffer(),
            (prev, data) => prev..write(data))
        .then((sb) => sb.toString());
  }

  /**
   * Create a new [StringDecoder] with an optional [encoding] and
   * [replacementChar].
   *
   * The default value for [encoding] is [Encoding.UTF_8].
   *
   * The default value for [replacementChar] is code point U+FFFD.
   */
  StringDecoder([Encoding encoding = Encoding.UTF_8, int replacementChar]) {
    switch (encoding) {
      case Encoding.UTF_8:
        if (replacementChar == null) {
          replacementChar = UNICODE_REPLACEMENT_CHARACTER_CODEPOINT;
        }
        _decoder = new Utf8DecoderTransformer(replacementChar);
        break;
      case Encoding.ASCII:
        if (replacementChar == null) {
          replacementChar = '?'.codeUnitAt(0);
        } else if (replacementChar > 127) {
          throw new ArgumentError("Invalid replacement character for ASCII");
        }
        _decoder = new _AsciiDecoder(replacementChar);
        break;
      case Encoding.ISO_8859_1:
        if (replacementChar == null) {
          replacementChar = '?'.codeUnitAt(0);
        } else if (replacementChar > 255) {
          throw new ArgumentError(
              "Invalid replacement character for ISO_8859_1");
        }
        _decoder = new _Latin1Decoder(replacementChar);
        break;
      case Encoding.SYSTEM:
        if (Platform.operatingSystem == "windows") {
          _decoder = new _WindowsCodePageDecoder();
        } else {
          if (replacementChar != null) {
            // TODO(ajohnsen): Handle replacement character.
            throw new UnsupportedError(
                "Replacement character is not supported for SYSTEM encoding");
          }
          _decoder = new Utf8DecoderTransformer();
        }
        break;
      default:
        throw new ArgumentError("Unsupported encoding '$encoding'");
    }
  }

  Stream<String> bind(Stream<List<int>> stream) => _decoder.bind(stream);
}


/**
 * Stream transformer that can encode a stream of strings info a stream of
 * bytes using [encoding].
 *
 * Strings that cannot be represented in the given encoding will result in an
 * error and a close event on the stream.
 */
class StringEncoder implements StreamTransformer<String, List<int>> {
  var _encoder;

  /**
   * Create a new [StringDecoder] with an optional [encoding] and
   * [replacementChar].
   */
  StringEncoder([Encoding encoding = Encoding.UTF_8]) {
    switch (encoding) {
      case Encoding.UTF_8:
        _encoder = new Utf8EncoderTransformer();
        break;
      case Encoding.ASCII:
        _encoder = new _AsciiEncoder();
        break;
      case Encoding.ISO_8859_1:
        _encoder = new _Latin1Encoder();
        break;
      case Encoding.SYSTEM:
        if (Platform.operatingSystem == "windows") {
          _encoder = new _WindowsCodePageEncoder();
        } else {
          _encoder = new Utf8EncoderTransformer();
        }
        break;
      default:
        throw new ArgumentError("Unsupported encoding '$encoding'");
    }
  }

  Stream<List<int>> bind(Stream<String> stream) => _encoder.bind(stream);
}


// Utility function to synchronously decode a list of bytes.
String _decodeString(List<int> bytes, [Encoding encoding = Encoding.UTF_8]) {
  if (bytes.length == 0) return "";
  var string;
  var error;
  var controller = new StreamController(sync: true);
  controller.stream
    .transform(new StringDecoder(encoding))
    .listen((data) => string = data,
            onError: (e) => error = e);
  controller.add(bytes);
  controller.close();
  if (error != null) throw error;
  assert(string != null);
  return string;
}


// Utility function to synchronously decode a utf8-encoded list of bytes,
// throwing on error.
String _decodeUtf8Strict(List<int> bytes) {
  if (bytes.length == 0) return "";
  var string;
  var error;
  var controller = new StreamController(sync: true);
  controller.stream
    .transform(new Utf8DecoderTransformer(null))
    .listen((data) => string = data,
            onError: (e) => error = e);
  controller.add(bytes);
  controller.close();
  if (error != null) throw error;
  assert(string != null);
  return string;
}


// Utility function to synchronously encode a String.
// Will throw an exception if the encoding is invalid.
List<int> _encodeString(String string, [Encoding encoding = Encoding.UTF_8]) {
  if (string.length == 0) return [];
  var bytes;
  var controller = new StreamController(sync: true);
  controller.stream
    .transform(new StringEncoder(encoding))
    .listen((data) => bytes = data);
  controller.add(string);
  controller.close();
  assert(bytes != null);
  return bytes;
}


abstract class _SingleByteDecoder
    extends StreamEventTransformer<List<int>, String> {
  final int _replacementChar;

  _SingleByteDecoder(this._replacementChar);

  void handleData(List<int> data, EventSink<String> sink) {
    var buffer = new List<int>(data.length);
    for (int i = 0; i < data.length; i++) {
      int char = _decodeByte(data[i]);
      if (char < 0) char = _replacementChar;
      buffer[i] = char;
    }
    sink.add(new String.fromCharCodes(buffer));
  }

  int _decodeByte(int byte);
}


// Utility class for decoding ascii data delivered as a stream of
// bytes.
class _AsciiDecoder extends _SingleByteDecoder {
  _AsciiDecoder(int replacementChar) : super(replacementChar);

  int _decodeByte(int byte) => ((byte & 0x7f) == byte) ? byte : -1;
}


// Utility class for decoding Latin-1 data delivered as a stream of
// bytes.
class _Latin1Decoder extends _SingleByteDecoder {
  _Latin1Decoder(int replacementChar) : super(replacementChar);

  int _decodeByte(int byte) => ((byte & 0xFF) == byte) ? byte : -1;
}


abstract class _SingleByteEncoder
    extends StreamEventTransformer<String, List<int>> {
  void handleData(String data, EventSink<List<int>> sink) {
    var bytes = _encode(data);
    if (bytes == null) {
      sink.addError(new FormatException("Invalid character for encoding"));
      sink.close();
    } else {
      sink.add(bytes);
    }
  }

  List<int> _encode(String string);
}


// Utility class for encoding a string into an ASCII byte stream.
class _AsciiEncoder extends _SingleByteEncoder {
  List<int> _encode(String string) {
    var bytes = string.codeUnits;
    for (var byte in bytes) {
      if (byte > 127) return null;
    }
    return bytes;
  }
}


// Utility class for encoding a string into a Latin1 byte stream.
class _Latin1Encoder extends _SingleByteEncoder {
  List<int> _encode(String string) {
    var bytes = string.codeUnits;
    for (var byte in bytes) {
      if (byte > 255) return null;
    }
    return bytes;
  }
}


// Utility class for encoding a string into a current windows
// code page byte list.
// Implemented on top of a _SingleByteEncoder, even though it's not really a
// single byte encoder, to avoid copying boilerplate.
class _WindowsCodePageEncoder extends _SingleByteEncoder {
  List<int> _encode(String string) => _encodeString(string);

  external static List<int> _encodeString(String string);
}


// Utility class for decoding Windows current code page data delivered
// as a stream of bytes.
class _WindowsCodePageDecoder extends StreamEventTransformer<List<int>, String> {
  void handleData(List<int> data, EventSink<String> sink) {
    sink.add(_decodeBytes(data));
  }

  external static String _decodeBytes(List<int> bytes);
}
