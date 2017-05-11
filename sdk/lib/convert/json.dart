// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.convert;

/**
 * Error thrown by JSON serialization if an object cannot be serialized.
 *
 * The [unsupportedObject] field holds that object that failed to be serialized.
 *
 * If an object isn't directly serializable, the serializer calls the `toJson`
 * method on the object. If that call fails, the error will be stored in the
 * [cause] field. If the call returns an object that isn't directly
 * serializable, the [cause] is null.
 */
class JsonUnsupportedObjectError extends Error {
  /** The object that could not be serialized. */
  final unsupportedObject;
  /** The exception thrown when trying to convert the object. */
  final cause;

  JsonUnsupportedObjectError(this.unsupportedObject, {this.cause});

  String toString() {
    if (cause != null) {
      return "Converting object to an encodable object failed.";
    } else {
      return "Converting object did not return an encodable object.";
    }
  }
}

/**
 * Reports that an object could not be stringified due to cyclic references.
 *
 * An object that references itself cannot be serialized by
 * [JsonCodec.encode]/[JsonEncoder.convert].
 * When the cycle is detected, a [JsonCyclicError] is thrown.
 */
class JsonCyclicError extends JsonUnsupportedObjectError {
  /** The first object that was detected as part of a cycle. */
  JsonCyclicError(Object object) : super(object);
  String toString() => "Cyclic error in JSON stringify";
}

/**
 * An instance of the default implementation of the [JsonCodec].
 *
 * This instance provides a convenient access to the most common JSON
 * use cases.
 *
 * Examples:
 *
 *     var encoded = JSON.encode([1, 2, { "a": null }]);
 *     var decoded = JSON.decode('["foo", { "bar": 499 }]');
 */
const JsonCodec JSON = const JsonCodec();

typedef _Reviver(var key, var value);
typedef _ToEncodable(var o);

/**
 * A [JsonCodec] encodes JSON objects to strings and decodes strings to
 * JSON objects.
 *
 * Examples:
 *
 *     var encoded = JSON.encode([1, 2, { "a": null }]);
 *     var decoded = JSON.decode('["foo", { "bar": 499 }]');
 */
class JsonCodec extends Codec<Object, String> {
  final _Reviver _reviver;
  final _ToEncodable _toEncodable;

  /**
   * Creates a `JsonCodec` with the given reviver and encoding function.
   *
   * The [reviver] function is called during decoding. It is invoked once for
   * each object or list property that has been parsed.
   * The `key` argument is either the integer list index for a list property,
   * the string map key for object properties, or `null` for the final result.
   *
   * If [reviver] is omitted, it defaults to returning the value argument.
   *
   * The [toEncodable] function is used during encoding. It is invoked for
   * values that are not directly encodable to a string (a value that is not a
   * number, boolean, string, null, list or a map with string keys). The
   * function must return an object that is directly encodable. The elements of
   * a returned list and values of a returned map do not need to be directly
   * encodable, and if they aren't, `toEncodable` will be used on them as well.
   * Please notice that it is possible to cause an infinite recursive regress
   * in this way, by effectively creating an infinite data structure through
   * repeated call to `toEncodable`.
   *
   * If [toEncodable] is omitted, it defaults to a function that returns the
   * result of calling `.toJson()` on the unencodable object.
   */
  const JsonCodec({reviver(var key, var value), toEncodable(var object)})
      : _reviver = reviver,
        _toEncodable = toEncodable;

  /**
   * Creates a `JsonCodec` with the given reviver.
   *
   * The [reviver] function is called once for each object or list property
   * that has been parsed during decoding. The `key` argument is either the
   * integer list index for a list property, the string map key for object
   * properties, or `null` for the final result.
   */
  JsonCodec.withReviver(reviver(var key, var value)) : this(reviver: reviver);

  /**
   * Parses the string and returns the resulting Json object.
   *
   * The optional [reviver] function is called once for each object or list
   * property that has been parsed during decoding. The `key` argument is either
   * the integer list index for a list property, the string map key for object
   * properties, or `null` for the final result.
   *
   * The default [reviver] (when not provided) is the identity function.
   */
  dynamic decode(String source, {reviver(var key, var value)}) {
    if (reviver == null) reviver = _reviver;
    if (reviver == null) return decoder.convert(source);
    return new JsonDecoder(reviver).convert(source);
  }

  /**
   * Converts [value] to a JSON string.
   *
   * If value contains objects that are not directly encodable to a JSON
   * string (a value that is not a number, boolean, string, null, list or a map
   * with string keys), the [toEncodable] function is used to convert it to an
   * object that must be directly encodable.
   *
   * If [toEncodable] is omitted, it defaults to a function that returns the
   * result of calling `.toJson()` on the unencodable object.
   */
  String encode(Object value, {toEncodable(object)}) {
    if (toEncodable == null) toEncodable = _toEncodable;
    if (toEncodable == null) return encoder.convert(value);
    return new JsonEncoder(toEncodable).convert(value);
  }

  JsonEncoder get encoder {
    if (_toEncodable == null) return const JsonEncoder();
    return new JsonEncoder(_toEncodable);
  }

  JsonDecoder get decoder {
    if (_reviver == null) return const JsonDecoder();
    return new JsonDecoder(_reviver);
  }
}

/**
 * This class converts JSON objects to strings.
 */
class JsonEncoder extends Converter<Object, String> {
  /**
   * The string used for indention.
   *
   * When generating multi-line output, this string is inserted once at the
   * beginning of each indented line for each level of indentation.
   *
   * If `null`, the output is encoded as a single line.
   */
  final String indent;

  /**
   * Function called on non-encodable objects to return a replacement
   * encodable object that will be encoded in the orignal's place.
   */
  final _ToEncodable _toEncodable;

  /**
   * Creates a JSON encoder.
   *
   * The JSON encoder handles numbers, strings, booleans, null, lists and
   * maps with string keys directly.
   *
   * Any other object is attempted converted by [toEncodable] to an
   * object that is of one of the convertible types.
   *
   * If [toEncodable] is omitted, it defaults to calling `.toJson()` on
   * the object.
   */
  const JsonEncoder([toEncodable(object)])
      : this.indent = null,
        this._toEncodable = toEncodable;

  /**
   * Creates a JSON encoder that creates multi-line JSON.
   *
   * The encoding of elements of lists and maps are indented and put on separate
   * lines. The [indent] string is prepended to these elements, once for each
   * level of indentation.
   *
   * If [indent] is `null`, the output is encoded as a single line.
   *
   * The JSON encoder handles numbers, strings, booleans, null, lists and
   * maps with string keys directly.
   *
   * Any other object is attempted converted by [toEncodable] to an
   * object that is of one of the convertible types.
   *
   * If [toEncodable] is omitted, it defaults to calling `.toJson()` on
   * the object.
   */
  const JsonEncoder.withIndent(this.indent, [toEncodable(object)])
      : this._toEncodable = toEncodable;

  /**
   * Converts [object] to a JSON [String].
   *
   * Directly serializable values are [num], [String], [bool], and [Null], as
   * well as some [List] and [Map] values. For [List], the elements must all be
   * serializable. For [Map], the keys must be [String] and the values must be
   * serializable.
   *
   * If a value of any other type is attempted to be serialized, the
   * `toEncodable` function provided in the constructor is called with the value
   * as argument. The result, which must be a directly serializable value, is
   * serialized instead of the original value.
   *
   * If the conversion throws, or returns a value that is not directly
   * serializable, a [JsonUnsupportedObjectError] exception is thrown.
   * If the call throws, the error is caught and stored in the
   * [JsonUnsupportedObjectError]'s [:cause:] field.
   *
   * If a [List] or [Map] contains a reference to itself, directly or through
   * other lists or maps, it cannot be serialized and a [JsonCyclicError] is
   * thrown.
   *
   * [object] should not change during serialization.
   *
   * If an object is serialized more than once, [convert] may cache the text
   * for it. In other words, if the content of an object changes after it is
   * first serialized, the new values may not be reflected in the result.
   */
  String convert(Object object) =>
      _JsonStringStringifier.stringify(object, _toEncodable, indent);

  /**
   * Starts a chunked conversion.
   *
   * The converter works more efficiently if the given [sink] is a
   * [StringConversionSink].
   *
   * Returns a chunked-conversion sink that accepts at most one object. It is
   * an error to invoke `add` more than once on the returned sink.
   */
  ChunkedConversionSink<Object> startChunkedConversion(Sink<String> sink) {
    if (sink is! StringConversionSink) {
      sink = new StringConversionSink.from(sink);
    } else if (sink is _Utf8EncoderSink) {
      return new _JsonUtf8EncoderSink(
          sink._sink,
          _toEncodable,
          JsonUtf8Encoder._utf8Encode(indent),
          JsonUtf8Encoder.DEFAULT_BUFFER_SIZE);
    }
    return new _JsonEncoderSink(sink, _toEncodable, indent);
  }

  // Override the base class's bind, to provide a better type.
  Stream<String> bind(Stream<Object> stream) => super.bind(stream);

  Converter<Object, T> fuse<T>(Converter<String, T> other) {
    if (other is Utf8Encoder) {
      return new JsonUtf8Encoder(indent, _toEncodable)
          as dynamic/*=Converter<Object, T>*/;
    }
    return super.fuse<T>(other);
  }
}

/**
 * Encoder that encodes a single object as a UTF-8 encoded JSON string.
 *
 * This encoder works equivalently to first converting the object to
 * a JSON string, and then UTF-8 encoding the string, but without
 * creating an intermediate string.
 */
class JsonUtf8Encoder extends Converter<Object, List<int>> {
  /** Default buffer size used by the JSON-to-UTF-8 encoder. */
  static const int DEFAULT_BUFFER_SIZE = 256;
  /** Indentation used in pretty-print mode, `null` if not pretty. */
  final List<int> _indent;
  /** Function called with each un-encodable object encountered. */
  final _ToEncodable _toEncodable;
  /** UTF-8 buffer size. */
  final int _bufferSize;

  /**
   * Create converter.
   *
   * If [indent] is non-`null`, the converter attempts to "pretty-print" the
   * JSON, and uses `indent` as the indentation. Otherwise the result has no
   * whitespace outside of string literals.
   * If `indent` contains characters that are not valid JSON whitespace
   * characters, the result will not be valid JSON. JSON whitespace characters
   * are space (U+0020), tab (U+0009), line feed (U+000a) and carriage return
   * (U+000d) ([ECMA
   * 404](http://www.ecma-international.org/publications/standards/Ecma-404.htm)).
   *
   * The [bufferSize] is the size of the internal buffers used to collect
   * UTF-8 code units.
   * If using [startChunkedConversion], it will be the size of the chunks.
   *
   * The JSON encoder handles numbers, strings, booleans, null, lists and maps
   * directly.
   *
   * Any other object is attempted converted by [toEncodable] to an object that
   * is of one of the convertible types.
   *
   * If [toEncodable] is omitted, it defaults to calling `.toJson()` on the
   * object.
   */
  JsonUtf8Encoder(
      [String indent,
      toEncodable(object),
      int bufferSize = DEFAULT_BUFFER_SIZE])
      : _indent = _utf8Encode(indent),
        _toEncodable = toEncodable,
        _bufferSize = bufferSize;

  static List<int> _utf8Encode(String string) {
    if (string == null) return null;
    if (string.isEmpty) return new Uint8List(0);
    checkAscii:
    {
      for (int i = 0; i < string.length; i++) {
        if (string.codeUnitAt(i) >= 0x80) break checkAscii;
      }
      return string.codeUnits;
    }
    return UTF8.encode(string);
  }

  /** Convert [object] into UTF-8 encoded JSON. */
  List<int> convert(Object object) {
    List<List<int>> bytes = [];
    // The `stringify` function always converts into chunks.
    // Collect the chunks into the `bytes` list, then combine them afterwards.
    void addChunk(Uint8List chunk, int start, int end) {
      if (start > 0 || end < chunk.length) {
        int length = end - start;
        chunk = new Uint8List.view(
            chunk.buffer, chunk.offsetInBytes + start, length);
      }
      bytes.add(chunk);
    }

    _JsonUtf8Stringifier.stringify(
        object, _indent, _toEncodable, _bufferSize, addChunk);
    if (bytes.length == 1) return bytes[0];
    int length = 0;
    for (int i = 0; i < bytes.length; i++) {
      length += bytes[i].length;
    }
    Uint8List result = new Uint8List(length);
    for (int i = 0, offset = 0; i < bytes.length; i++) {
      var byteList = bytes[i];
      int end = offset + byteList.length;
      result.setRange(offset, end, byteList);
      offset = end;
    }
    return result;
  }

  /**
   * Start a chunked conversion.
   *
   * Only one object can be passed into the returned sink.
   *
   * The argument [sink] will receive byte lists in sizes depending on the
   * `bufferSize` passed to the constructor when creating this encoder.
   */
  ChunkedConversionSink<Object> startChunkedConversion(Sink<List<int>> sink) {
    ByteConversionSink byteSink;
    if (sink is ByteConversionSink) {
      byteSink = sink;
    } else {
      byteSink = new ByteConversionSink.from(sink);
    }
    return new _JsonUtf8EncoderSink(
        byteSink, _toEncodable, _indent, _bufferSize);
  }

  // Override the base class's bind, to provide a better type.
  Stream<List<int>> bind(Stream<Object> stream) {
    return super.bind(stream);
  }
}

/**
 * Implements the chunked conversion from object to its JSON representation.
 *
 * The sink only accepts one value, but will produce output in a chunked way.
 */
class _JsonEncoderSink extends ChunkedConversionSink<Object> {
  final String _indent;
  final _ToEncodable _toEncodable;
  final StringConversionSink _sink;
  bool _isDone = false;

  _JsonEncoderSink(this._sink, this._toEncodable, this._indent);

  /**
   * Encodes the given object [o].
   *
   * It is an error to invoke this method more than once on any instance. While
   * this makes the input effectly non-chunked the output will be generated in
   * a chunked way.
   */
  void add(Object o) {
    if (_isDone) {
      throw new StateError("Only one call to add allowed");
    }
    _isDone = true;
    ClosableStringSink stringSink = _sink.asStringSink();
    _JsonStringStringifier.printOn(o, stringSink, _toEncodable, _indent);
    stringSink.close();
  }

  void close() {/* do nothing */}
}

/**
 * Sink returned when starting a chunked conversion from object to bytes.
 */
class _JsonUtf8EncoderSink extends ChunkedConversionSink<Object> {
  /** The byte sink receiveing the encoded chunks. */
  final ByteConversionSink _sink;
  final List<int> _indent;
  final _ToEncodable _toEncodable;
  final int _bufferSize;
  bool _isDone = false;
  _JsonUtf8EncoderSink(
      this._sink, this._toEncodable, this._indent, this._bufferSize);

  /** Callback called for each slice of result bytes. */
  void _addChunk(Uint8List chunk, int start, int end) {
    _sink.addSlice(chunk, start, end, false);
  }

  void add(Object object) {
    if (_isDone) {
      throw new StateError("Only one call to add allowed");
    }
    _isDone = true;
    _JsonUtf8Stringifier.stringify(
        object, _indent, _toEncodable, _bufferSize, _addChunk);
    _sink.close();
  }

  void close() {
    if (!_isDone) {
      _isDone = true;
      _sink.close();
    }
  }
}

/**
 * This class parses JSON strings and builds the corresponding objects.
 */
class JsonDecoder extends Converter<String, Object> {
  final _Reviver _reviver;
  /**
   * Constructs a new JsonDecoder.
   *
   * The [reviver] may be `null`.
   */
  const JsonDecoder([reviver(var key, var value)]) : this._reviver = reviver;

  /**
   * Converts the given JSON-string [input] to its corresponding object.
   *
   * Parsed JSON values are of the types [num], [String], [bool], [Null],
   * [List]s of parsed JSON values or [Map]s from [String] to parsed JSON
   * values.
   *
   * If `this` was initialized with a reviver, then the parsing operation
   * invokes the reviver on every object or list property that has been parsed.
   * The arguments are the property name ([String]) or list index ([int]), and
   * the value is the parsed value. The return value of the reviver is used as
   * the value of that property instead the parsed value.
   *
   * Throws [FormatException] if the input is not valid JSON text.
   */
  dynamic convert(String input) => _parseJson(input, _reviver);

  /**
   * Starts a conversion from a chunked JSON string to its corresponding object.
   *
   * The output [sink] receives exactly one decoded element through `add`.
   */
  external StringConversionSink startChunkedConversion(Sink<Object> sink);

  // Override the base class's bind, to provide a better type.
  Stream<Object> bind(Stream<String> stream) => super.bind(stream);
}

// Internal optimized JSON parsing implementation.
external _parseJson(String source, reviver(key, value));

// Implementation of encoder/stringifier.

dynamic _defaultToEncodable(dynamic object) => object.toJson();

/**
 * JSON encoder that traverses an object structure and writes JSON source.
 *
 * This is an abstract implementation that doesn't decide on the output
 * format, but writes the JSON through abstract methods like [writeString].
 */
abstract class _JsonStringifier {
  // Character code constants.
  static const int BACKSPACE = 0x08;
  static const int TAB = 0x09;
  static const int NEWLINE = 0x0a;
  static const int CARRIAGE_RETURN = 0x0d;
  static const int FORM_FEED = 0x0c;
  static const int QUOTE = 0x22;
  static const int CHAR_0 = 0x30;
  static const int BACKSLASH = 0x5c;
  static const int CHAR_b = 0x62;
  static const int CHAR_f = 0x66;
  static const int CHAR_n = 0x6e;
  static const int CHAR_r = 0x72;
  static const int CHAR_t = 0x74;
  static const int CHAR_u = 0x75;

  /** List of objects currently being traversed. Used to detect cycles. */
  final List _seen = new List();
  /** Function called for each un-encodable object encountered. */
  final _ToEncodable _toEncodable;

  _JsonStringifier(toEncodable(o))
      : _toEncodable = toEncodable ?? _defaultToEncodable;

  /** Append a string to the JSON output. */
  void writeString(String characters);
  /** Append part of a string to the JSON output. */
  void writeStringSlice(String characters, int start, int end);
  /** Append a single character, given by its code point, to the JSON output. */
  void writeCharCode(int charCode);
  /** Write a number to the JSON output. */
  void writeNumber(num number);

  // ('0' + x) or ('a' + x - 10)
  static int hexDigit(int x) => x < 10 ? 48 + x : 87 + x;

  /**
   * Write, and suitably escape, a string's content as a JSON string literal.
   */
  void writeStringContent(String s) {
    int offset = 0;
    final int length = s.length;
    for (int i = 0; i < length; i++) {
      int charCode = s.codeUnitAt(i);
      if (charCode > BACKSLASH) continue;
      if (charCode < 32) {
        if (i > offset) writeStringSlice(s, offset, i);
        offset = i + 1;
        writeCharCode(BACKSLASH);
        switch (charCode) {
          case BACKSPACE:
            writeCharCode(CHAR_b);
            break;
          case TAB:
            writeCharCode(CHAR_t);
            break;
          case NEWLINE:
            writeCharCode(CHAR_n);
            break;
          case FORM_FEED:
            writeCharCode(CHAR_f);
            break;
          case CARRIAGE_RETURN:
            writeCharCode(CHAR_r);
            break;
          default:
            writeCharCode(CHAR_u);
            writeCharCode(CHAR_0);
            writeCharCode(CHAR_0);
            writeCharCode(hexDigit((charCode >> 4) & 0xf));
            writeCharCode(hexDigit(charCode & 0xf));
            break;
        }
      } else if (charCode == QUOTE || charCode == BACKSLASH) {
        if (i > offset) writeStringSlice(s, offset, i);
        offset = i + 1;
        writeCharCode(BACKSLASH);
        writeCharCode(charCode);
      }
    }
    if (offset == 0) {
      writeString(s);
    } else if (offset < length) {
      writeStringSlice(s, offset, length);
    }
  }

  /**
   * Check if an encountered object is already being traversed.
   *
   * Records the object if it isn't already seen. Should have a matching call to
   * [_removeSeen] when the object is no longer being traversed.
   */
  void _checkCycle(object) {
    for (int i = 0; i < _seen.length; i++) {
      if (identical(object, _seen[i])) {
        throw new JsonCyclicError(object);
      }
    }
    _seen.add(object);
  }

  /**
   * Remove [object] from the list of currently traversed objects.
   *
   * Should be called in the opposite order of the matching [_checkCycle]
   * calls.
   */
  void _removeSeen(object) {
    assert(!_seen.isEmpty);
    assert(identical(_seen.last, object));
    _seen.removeLast();
  }

  /**
   * Write an object.
   *
   * If [object] isn't directly encodable, the [_toEncodable] function gets one
   * chance to return a replacement which is encodable.
   */
  void writeObject(object) {
    // Tries stringifying object directly. If it's not a simple value, List or
    // Map, call toJson() to get a custom representation and try serializing
    // that.
    if (writeJsonValue(object)) return;
    _checkCycle(object);
    try {
      var customJson = _toEncodable(object);
      if (!writeJsonValue(customJson)) {
        throw new JsonUnsupportedObjectError(object);
      }
      _removeSeen(object);
    } catch (e) {
      throw new JsonUnsupportedObjectError(object, cause: e);
    }
  }

  /**
   * Serialize a [num], [String], [bool], [Null], [List] or [Map] value.
   *
   * Returns true if the value is one of these types, and false if not.
   * If a value is both a [List] and a [Map], it's serialized as a [List].
   */
  bool writeJsonValue(object) {
    if (object is num) {
      if (!object.isFinite) return false;
      writeNumber(object);
      return true;
    } else if (identical(object, true)) {
      writeString('true');
      return true;
    } else if (identical(object, false)) {
      writeString('false');
      return true;
    } else if (object == null) {
      writeString('null');
      return true;
    } else if (object is String) {
      writeString('"');
      writeStringContent(object);
      writeString('"');
      return true;
    } else if (object is List) {
      _checkCycle(object);
      writeList(object);
      _removeSeen(object);
      return true;
    } else if (object is Map) {
      _checkCycle(object);
      // writeMap can fail if keys are not all strings.
      var success = writeMap(object);
      _removeSeen(object);
      return success;
    } else {
      return false;
    }
  }

  /** Serialize a [List]. */
  void writeList(List list) {
    writeString('[');
    if (list.length > 0) {
      writeObject(list[0]);
      for (int i = 1; i < list.length; i++) {
        writeString(',');
        writeObject(list[i]);
      }
    }
    writeString(']');
  }

  /** Serialize a [Map]. */
  bool writeMap(Map map) {
    if (map.isEmpty) {
      writeString("{}");
      return true;
    }
    List keyValueList = new List(map.length * 2);
    int i = 0;
    bool allStringKeys = true;
    map.forEach((key, value) {
      if (key is! String) {
        allStringKeys = false;
      }
      keyValueList[i++] = key;
      keyValueList[i++] = value;
    });
    if (!allStringKeys) return false;
    writeString('{');
    String separator = '"';
    for (int i = 0; i < keyValueList.length; i += 2) {
      writeString(separator);
      separator = ',"';
      writeStringContent(keyValueList[i]);
      writeString('":');
      writeObject(keyValueList[i + 1]);
    }
    writeString('}');
    return true;
  }
}

/**
 * A modification of [_JsonStringifier] which indents the contents of [List] and
 * [Map] objects using the specified indent value.
 *
 * Subclasses should implement [writeIndentation].
 */
abstract class _JsonPrettyPrintMixin implements _JsonStringifier {
  int _indentLevel = 0;

  /**
   * Add [indentLevel] indentations to the JSON output.
   */
  void writeIndentation(int indentLevel);

  void writeList(List list) {
    if (list.isEmpty) {
      writeString('[]');
    } else {
      writeString('[\n');
      _indentLevel++;
      writeIndentation(_indentLevel);
      writeObject(list[0]);
      for (int i = 1; i < list.length; i++) {
        writeString(',\n');
        writeIndentation(_indentLevel);
        writeObject(list[i]);
      }
      writeString('\n');
      _indentLevel--;
      writeIndentation(_indentLevel);
      writeString(']');
    }
  }

  bool writeMap(Map map) {
    if (map.isEmpty) {
      writeString("{}");
      return true;
    }
    List keyValueList = new List(map.length * 2);
    int i = 0;
    bool allStringKeys = true;
    map.forEach((key, value) {
      if (key is! String) {
        allStringKeys = false;
      }
      keyValueList[i++] = key;
      keyValueList[i++] = value;
    });
    if (!allStringKeys) return false;
    writeString('{\n');
    _indentLevel++;
    String separator = "";
    for (int i = 0; i < keyValueList.length; i += 2) {
      writeString(separator);
      separator = ",\n";
      writeIndentation(_indentLevel);
      writeString('"');
      writeStringContent(keyValueList[i]);
      writeString('": ');
      writeObject(keyValueList[i + 1]);
    }
    writeString('\n');
    _indentLevel--;
    writeIndentation(_indentLevel);
    writeString('}');
    return true;
  }
}

/**
 * A specialziation of [_JsonStringifier] that writes its JSON to a string.
 */
class _JsonStringStringifier extends _JsonStringifier {
  final StringSink _sink;

  _JsonStringStringifier(this._sink, _toEncodable) : super(_toEncodable);

  /**
   * Convert object to a string.
   *
   * The [toEncodable] function is used to convert non-encodable objects
   * to encodable ones.
   *
   * If [indent] is not `null`, the resulting JSON will be "pretty-printed"
   * with newlines and indentation. The `indent` string is added as indentation
   * for each indentation level. It should only contain valid JSON whitespace
   * characters (space, tab, carriage return or line feed).
   */
  static String stringify(object, toEncodable(o), String indent) {
    StringBuffer output = new StringBuffer();
    printOn(object, output, toEncodable, indent);
    return output.toString();
  }

  /**
   * Convert object to a string, and write the result to the [output] sink.
   *
   * The result is written piecemally to the sink.
   */
  static void printOn(
      object, StringSink output, toEncodable(o), String indent) {
    var stringifier;
    if (indent == null) {
      stringifier = new _JsonStringStringifier(output, toEncodable);
    } else {
      stringifier =
          new _JsonStringStringifierPretty(output, toEncodable, indent);
    }
    stringifier.writeObject(object);
  }

  void writeNumber(num number) {
    _sink.write(number.toString());
  }

  void writeString(String string) {
    _sink.write(string);
  }

  void writeStringSlice(String string, int start, int end) {
    _sink.write(string.substring(start, end));
  }

  void writeCharCode(int charCode) {
    _sink.writeCharCode(charCode);
  }
}

class _JsonStringStringifierPretty extends _JsonStringStringifier
    with _JsonPrettyPrintMixin {
  final String _indent;

  _JsonStringStringifierPretty(StringSink sink, toEncodable(o), this._indent)
      : super(sink, toEncodable);

  void writeIndentation(int count) {
    for (int i = 0; i < count; i++) writeString(_indent);
  }
}

typedef void _AddChunk(Uint8List list, int start, int end);

/**
 * Specialization of [_JsonStringifier] that writes the JSON as UTF-8.
 *
 * The JSON text is UTF-8 encoded and written to [Uint8List] buffers.
 * The buffers are then passed back to a user provided callback method.
 */
class _JsonUtf8Stringifier extends _JsonStringifier {
  final int bufferSize;
  final _AddChunk addChunk;
  Uint8List buffer;
  int index = 0;

  _JsonUtf8Stringifier(toEncodable(o), int bufferSize, this.addChunk)
      : this.bufferSize = bufferSize,
        buffer = new Uint8List(bufferSize),
        super(toEncodable);

  /**
   * Convert [object] to UTF-8 encoded JSON.
   *
   * Calls [addChunk] with slices of UTF-8 code units.
   * These will typically have size [bufferSize], but may be shorter.
   * The buffers are not reused, so the [addChunk] call may keep and reuse the
   * chunks.
   *
   * If [indent] is non-`null`, the result will be "pretty-printed" with extra
   * newlines and indentation, using [indent] as the indentation.
   */
  static void stringify(Object object, List<int> indent, toEncodable(o),
      int bufferSize, void addChunk(Uint8List chunk, int start, int end)) {
    _JsonUtf8Stringifier stringifier;
    if (indent != null) {
      stringifier = new _JsonUtf8StringifierPretty(
          toEncodable, indent, bufferSize, addChunk);
    } else {
      stringifier = new _JsonUtf8Stringifier(toEncodable, bufferSize, addChunk);
    }
    stringifier.writeObject(object);
    stringifier.flush();
  }

  /**
   * Must be called at the end to push the last chunk to the [addChunk]
   * callback.
   */
  void flush() {
    if (index > 0) {
      addChunk(buffer, 0, index);
    }
    buffer = null;
    index = 0;
  }

  void writeNumber(num number) {
    writeAsciiString(number.toString());
  }

  /** Write a string that is known to not have non-ASCII characters. */
  void writeAsciiString(String string) {
    // TODO(lrn): Optimize by copying directly into buffer instead of going
    // through writeCharCode;
    for (int i = 0; i < string.length; i++) {
      int char = string.codeUnitAt(i);
      assert(char <= 0x7f);
      writeByte(char);
    }
  }

  void writeString(String string) {
    writeStringSlice(string, 0, string.length);
  }

  void writeStringSlice(String string, int start, int end) {
    // TODO(lrn): Optimize by copying directly into buffer instead of going
    // through writeCharCode/writeByte. Assumption is the most characters
    // in starings are plain ASCII.
    for (int i = start; i < end; i++) {
      int char = string.codeUnitAt(i);
      if (char <= 0x7f) {
        writeByte(char);
      } else {
        if ((char & 0xFC00) == 0xD800 && i + 1 < end) {
          // Lead surrogate.
          int nextChar = string.codeUnitAt(i + 1);
          if ((nextChar & 0xFC00) == 0xDC00) {
            // Tail surrogate.
            char = 0x10000 + ((char & 0x3ff) << 10) + (nextChar & 0x3ff);
            writeFourByteCharCode(char);
            i++;
            continue;
          }
        }
        writeMultiByteCharCode(char);
      }
    }
  }

  void writeCharCode(int charCode) {
    if (charCode <= 0x7f) {
      writeByte(charCode);
      return;
    }
    writeMultiByteCharCode(charCode);
  }

  void writeMultiByteCharCode(int charCode) {
    if (charCode <= 0x7ff) {
      writeByte(0xC0 | (charCode >> 6));
      writeByte(0x80 | (charCode & 0x3f));
      return;
    }
    if (charCode <= 0xffff) {
      writeByte(0xE0 | (charCode >> 12));
      writeByte(0x80 | ((charCode >> 6) & 0x3f));
      writeByte(0x80 | (charCode & 0x3f));
      return;
    }
    writeFourByteCharCode(charCode);
  }

  void writeFourByteCharCode(int charCode) {
    assert(charCode <= 0x10ffff);
    writeByte(0xF0 | (charCode >> 18));
    writeByte(0x80 | ((charCode >> 12) & 0x3f));
    writeByte(0x80 | ((charCode >> 6) & 0x3f));
    writeByte(0x80 | (charCode & 0x3f));
  }

  void writeByte(int byte) {
    assert(byte <= 0xff);
    if (index == buffer.length) {
      addChunk(buffer, 0, index);
      buffer = new Uint8List(bufferSize);
      index = 0;
    }
    buffer[index++] = byte;
  }
}

/**
 * Pretty-printing version of [_JsonUtf8Stringifier].
 */
class _JsonUtf8StringifierPretty extends _JsonUtf8Stringifier
    with _JsonPrettyPrintMixin {
  final List<int> indent;
  _JsonUtf8StringifierPretty(toEncodable(o), this.indent, bufferSize,
      void addChunk(Uint8List buffer, int start, int end))
      : super(toEncodable, bufferSize, addChunk);

  void writeIndentation(int count) {
    List<int> indent = this.indent;
    int indentLength = indent.length;
    if (indentLength == 1) {
      int char = indent[0];
      while (count > 0) {
        writeByte(char);
        count -= 1;
      }
      return;
    }
    while (count > 0) {
      count--;
      int end = index + indentLength;
      if (end <= buffer.length) {
        buffer.setRange(index, end, indent);
        index = end;
      } else {
        for (int i = 0; i < indentLength; i++) {
          writeByte(indent[i]);
        }
      }
    }
  }
}
