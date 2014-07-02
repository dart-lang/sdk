// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.convert;

/**
 * Error thrown by JSON serialization if an object cannot be serialized.
 *
 * The [unsupportedObject] field holds that object that failed to be serialized.
 *
 * If an object isn't directly serializable, the serializer calls the 'toJson'
 * method on the object. If that call fails, the error will be stored in the
 * [cause] field. If the call returns an object that isn't directly
 * serializable, the [cause] is be null.
 */
class JsonUnsupportedObjectError extends Error {
  /** The object that could not be serialized. */
  final unsupportedObject;
  /** The exception thrown when trying to convert the object. */
  final cause;

  JsonUnsupportedObjectError(this.unsupportedObject, { this.cause });

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
 * An object that references itself cannot be serialized by [stringify].
 * When the cycle is detected, a [JsonCyclicError] is thrown.
 */
class JsonCyclicError extends JsonUnsupportedObjectError {
  /** The first object that was detected as part of a cycle. */
  JsonCyclicError(Object object): super(object);
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
 */
class JsonCodec extends Codec<Object, String> {
  final _Reviver _reviver;
  final _ToEncodable _toEncodable;

  /**
   * Creates a `JsonCodec` with the given reviver and encoding function.
   *
   * The [reviver] function is called during decoding. It is invoked
   * once for each object or list property that has been parsed.
   * The `key` argument is either the
   * integer list index for a list property, the string map key for object
   * properties, or `null` for the final result.
   *
   * If [reviver] is omitted, it defaults to returning the value argument.
   *
   * The [toEncodable] function is used during encoding. It is invoked for
   * values that are not directly encodable to a JSON1toE
   * string (a value that is not a number, boolean, string, null, list or a map
   * with string keys). The function must return an object that is directly
   * encodable. The elements of a returned list and values of a returned map
   * do not need be directly encodable, and if they aren't, `toEncodable` will
   * be used on them as well.
   * Please notice that it is possible to cause an infinite recursive
   * regress in this way, by effectively creating an infinite data structure
   * through repeated call to `toEncodable`.
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
  String encode(Object value, {toEncodable(var object)}) {
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

  final _toEncodableFunction;

  /**
   * Creates a JSON encoder.
   *
   * The JSON encoder handles numbers, strings, booleans, null, lists and
   * maps directly.
   *
   * Any other object is attempted converted by [toEncodable] to an
   * object that is of one of the convertible types.
   *
   * If [toEncodable] is omitted, it defaults to calling `.toJson()` on
   * the object.
   */
  const JsonEncoder([Object toEncodable(Object nonSerializable)])
      : this.indent = null,
        this._toEncodableFunction = toEncodable;

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
   * maps directly.
   *
   * Any other object is attempted converted by [toEncodable] to an
   * object that is of one of the convertible types.
   *
   * If [toEncodable] is omitted, it defaults to calling `.toJson()` on
   * the object.
   */
  const JsonEncoder.withIndent(this.indent,
      [Object toEncodable(Object nonSerializable)])
      : this._toEncodableFunction = toEncodable;

  /**
   * Converts [object] to a JSON [String].
   *
   * Directly serializable values are [num], [String], [bool], and [Null], as
   * well as some [List] and [Map] values.
   * For [List], the elements must all be serializable.
   * For [Map], the keys must be [String] and the values must be serializable.
   *
   * If a value is any other type is attempted serialized, the conversion
   * function provided in the constructor is invoked with the object as argument
   * and the result, which must be a directly serializable value,
   * is serialized instead of the original value.
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
      _JsonStringifier.stringify(object, _toEncodableFunction, indent);

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
    }
    return new _JsonEncoderSink(sink, _toEncodableFunction, indent);
  }

  // Override the base-classes bind, to provide a better type.
  Stream<String> bind(Stream<Object> stream) => super.bind(stream);
}

/**
 * Implements the chunked conversion from object to its JSON representation.
 *
 * The sink only accepts one value, but will produce output in a chunked way.
 */
class _JsonEncoderSink extends ChunkedConversionSink<Object> {
  final String _indent;
  final Function _toEncodableFunction;
  final StringConversionSink _sink;
  bool _isDone = false;

  _JsonEncoderSink(this._sink, this._toEncodableFunction, this._indent);

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
    _JsonStringifier.printOn(o, stringSink, _toEncodableFunction, _indent);
    stringSink.close();
  }

  void close() { /* do nothing */ }
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
   * [List]s of parsed JSON values or [Map]s from [String] to parsed
   * JSON values.
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
   * Starts a conversion from a chunked JSON string to its corresponding
   * object.
   *
   * The output [sink] receives exactly one decoded element through `add`.
   */
  StringConversionSink startChunkedConversion(Sink<Object> sink) {
    return new _JsonDecoderSink(_reviver, sink);
  }

  // Override the base-classes bind, to provide a better type.
  Stream<Object> bind(Stream<String> stream) => super.bind(stream);
}

/**
 * Implements the chunked conversion from a JSON string to its corresponding
 * object.
 *
 * The sink only creates one object, but its input can be chunked.
 */
// TODO(floitsch): don't accumulate everything before starting to decode.
class _JsonDecoderSink extends _StringSinkConversionSink {
  final _Reviver _reviver;
  final Sink<Object> _sink;

  _JsonDecoderSink(this._reviver, this._sink)
      : super(new StringBuffer());

  void close() {
    super.close();
    StringBuffer buffer = _stringSink;
    String accumulated = buffer.toString();
    buffer.clear();
    Object decoded = _parseJson(accumulated, _reviver);
    _sink.add(decoded);
    _sink.close();
  }
}

// Internal optimized JSON parsing implementation.
external _parseJson(String source, reviver(key, value));


// Implementation of encoder/stringifier.

Object _defaultToEncodable(object) => object.toJson();

class _JsonStringifier {
  // Character code constants.
  static const int BACKSPACE       = 0x08;
  static const int TAB             = 0x09;
  static const int NEWLINE         = 0x0a;
  static const int CARRIAGE_RETURN = 0x0d;
  static const int FORM_FEED       = 0x0c;
  static const int QUOTE           = 0x22;
  static const int CHAR_0          = 0x30;
  static const int BACKSLASH       = 0x5c;
  static const int CHAR_b          = 0x62;
  static const int CHAR_f          = 0x66;
  static const int CHAR_n          = 0x6e;
  static const int CHAR_r          = 0x72;
  static const int CHAR_t          = 0x74;
  static const int CHAR_u          = 0x75;

  final Function _toEncodable;
  final StringSink _sink;
  final List _seen;

  factory _JsonStringifier(StringSink sink, Function toEncodable,
      String indent) {
    if (indent == null) return new _JsonStringifier._(sink, toEncodable);
    return new _JsonStringifierPretty(sink, toEncodable, indent);
  }

  _JsonStringifier._(this._sink, this._toEncodable)
      : this._seen = new List();

  static String stringify(object, toEncodable(object), String indent) {
    if (toEncodable == null) toEncodable = _defaultToEncodable;
    StringBuffer output = new StringBuffer();
    printOn(object, output, toEncodable, indent);
    return output.toString();
  }

  static void printOn(object, StringSink output, toEncodable(object),
      String indent) {
    new _JsonStringifier(output, toEncodable, indent).stringifyValue(object);
  }

  static String numberToString(num x) {
    return x.toString();
  }

  // ('0' + x) or ('a' + x - 10)
  static int hexDigit(int x) => x < 10 ? 48 + x : 87 + x;

  void escape(String s) {
    int offset = 0;
    final int length = s.length;
    for (int i = 0; i < length; i++) {
      int charCode = s.codeUnitAt(i);
      if (charCode > BACKSLASH) continue;
      if (charCode < 32) {
        if (i > offset) _sink.write(s.substring(offset, i));
        offset = i + 1;
        _sink.writeCharCode(BACKSLASH);
        switch (charCode) {
        case BACKSPACE:
          _sink.writeCharCode(CHAR_b);
          break;
        case TAB:
          _sink.writeCharCode(CHAR_t);
          break;
        case NEWLINE:
          _sink.writeCharCode(CHAR_n);
          break;
        case FORM_FEED:
          _sink.writeCharCode(CHAR_f);
          break;
        case CARRIAGE_RETURN:
          _sink.writeCharCode(CHAR_r);
          break;
        default:
          _sink.writeCharCode(CHAR_u);
          _sink.writeCharCode(CHAR_0);
          _sink.writeCharCode(CHAR_0);
          _sink.writeCharCode(hexDigit((charCode >> 4) & 0xf));
          _sink.writeCharCode(hexDigit(charCode & 0xf));
          break;
        }
      } else if (charCode == QUOTE || charCode == BACKSLASH) {
        if (i > offset) _sink.write(s.substring(offset, i));
        offset = i + 1;
        _sink.writeCharCode(BACKSLASH);
        _sink.writeCharCode(charCode);
      }
    }
    if (offset == 0) {
      _sink.write(s);
    } else if (offset < length) {
      _sink.write(s.substring(offset, length));
    }
  }

  void checkCycle(object) {
    for (int i = 0; i < _seen.length; i++) {
      if (identical(object, _seen[i])) {
        throw new JsonCyclicError(object);
      }
    }
    _seen.add(object);
  }

  void stringifyValue(object) {
    // Tries stringifying object directly. If it's not a simple value, List or
    // Map, call toJson() to get a custom representation and try serializing
    // that.
    if (!stringifyJsonValue(object)) {
      checkCycle(object);
      try {
        var customJson = _toEncodable(object);
        if (!stringifyJsonValue(customJson)) {
          throw new JsonUnsupportedObjectError(object);
        }
        _removeSeen(object);
      } catch (e) {
        throw new JsonUnsupportedObjectError(object, cause: e);
      }
    }
  }

  /**
   * Serializes a [num], [String], [bool], [Null], [List] or [Map] value.
   *
   * Returns true if the value is one of these types, and false if not.
   * If a value is both a [List] and a [Map], it's serialized as a [List].
   */
  bool stringifyJsonValue(object) {
    if (object is num) {
      if (!object.isFinite) return false;
      _sink.write(numberToString(object));
      return true;
    } else if (identical(object, true)) {
      _sink.write('true');
      return true;
    } else if (identical(object, false)) {
      _sink.write('false');
       return true;
    } else if (object == null) {
      _sink.write('null');
      return true;
    } else if (object is String) {
      _sink.write('"');
      escape(object);
      _sink.write('"');
      return true;
    } else if (object is List) {
      checkCycle(object);
      List a = object;
      _sink.write('[');
      if (a.length > 0) {
        stringifyValue(a[0]);
        for (int i = 1; i < a.length; i++) {
          _sink.write(',');
          stringifyValue(a[i]);
        }
      }
      _sink.write(']');
      _removeSeen(object);
      return true;
    } else if (object is Map) {
      checkCycle(object);
      Map<String, Object> m = object;
      _sink.write('{');
      String separator = '"';
      m.forEach((String key, value) {
        _sink.write(separator);
        separator = ',"';
        escape(key);
        _sink.write('":');
        stringifyValue(value);
      });
      _sink.write('}');
      _removeSeen(object);
      return true;
    } else {
      return false;
    }
  }

  void _removeSeen(object) {
    assert(!_seen.isEmpty);
    assert(identical(_seen.last, object));
    _seen.removeLast();
  }
}

/**
 * A subclass of [_JsonStringifier] which indents the contents of [List] and
 * [Map] objects using the specified indent value.
 */
class _JsonStringifierPretty extends _JsonStringifier {
  final String _indent;

  int _indentLevel = 0;

  _JsonStringifierPretty(_sink, _toEncodable, this._indent)
      : super._(_sink, _toEncodable);

  void _write([String value = '']) {
    _sink.write(_indent * _indentLevel);
    _sink.write(value);
  }

  /**
   * Serializes a [num], [String], [bool], [Null], [List] or [Map] value.
   *
   * Returns true if the value is one of these types, and false if not.
   * If a value is both a [List] and a [Map], it's serialized as a [List].
   */
  bool stringifyJsonValue(final object) {
    if (object is List) {
      checkCycle(object);
      List a = object;
      if (a.isEmpty) {
        _sink.write('[]');
      } else {
        _sink.writeln('[');
        _indentLevel++;
        _write();
        stringifyValue(a[0]);
        for (int i = 1; i < a.length; i++) {
          _sink.writeln(',');
          _write();
          stringifyValue(a[i]);
        }
        _sink.writeln();
        _indentLevel--;
        _write(']');
      }
      _seen.remove(object);
      return true;
    } else if (object is Map) {
      checkCycle(object);
      Map<String, Object> m = object;
      if (m.isEmpty) {
        _sink.write('{}');
      } else {
        _sink.write('{');
        _sink.writeln();
        _indentLevel++;
        bool first = true;
        m.forEach((String key, Object value) {
          if (!first) {
            _sink.writeln(',');
          }
          _write('"');
          escape(key);
          _sink.write('": ');
          stringifyValue(value);
          first = false;
        });
        _sink.writeln();
        _indentLevel--;
        _write('}');
      }
      _seen.remove(object);
      return true;
    }
    return super.stringifyJsonValue(object);
  }
}
