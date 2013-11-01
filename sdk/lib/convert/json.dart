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

/**
 * A [JsonCodec] encodes JSON objects to strings and decodes strings to
 * JSON objects.
 */
class JsonCodec extends Codec<Object, String> {
  const JsonCodec();

  /**
   * Creates a `JsonCodec` with the given reviver.
   *
   * The [reviver] function is called once for each object or list property
   * that has been parsed during decoding. The `key` argument is either the
   * integer list index for a list property, the map string for object
   * properties, or `null` for the final result.
   */
  factory JsonCodec.withReviver(reviver(var key, var value)) =
      _ReviverJsonCodec;

  /**
   * Parses the string and returns the resulting Json object.
   *
   * The optional [reviver] function is called once for each object or list
   * property that has been parsed during decoding. The `key` argument is either
   * the integer list index for a list property, the map string for object
   * properties, or `null` for the final result.
   *
   * The default [reviver] (when not provided) is the identity function.
   */
  dynamic decode(String source, {reviver(var key, var value)}) {
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
   * If [toEncodable] is omitted, it defaults to calling `.toJson()` on the
   * unencodable object.
   */
  String encode(Object value, {toEncodable(var object)}) {
    if (toEncodable == null) return encoder.convert(value);
    return new JsonEncoder(toEncodable).convert(value);
  }

  JsonEncoder get encoder => const JsonEncoder();
  JsonDecoder get decoder => const JsonDecoder(null);
}

typedef _Reviver(var key, var value);

class _ReviverJsonCodec extends JsonCodec {
  final _Reviver _reviver;
  _ReviverJsonCodec(this._reviver);

  dynamic decode(String source, {reviver(var key, var value)}) {
    if (reviver == null) reviver = _reviver;
    return new JsonDecoder(reviver).convert(source);
  }

  JsonDecoder get decoder => new JsonDecoder(_reviver);
}

/**
 * This class converts JSON objects to strings.
 */
class JsonEncoder extends Converter<Object, String> {
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
      : this._toEncodableFunction = toEncodable;

  /**
   * Converts the given object [o] to its JSON representation.
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
   * Json Objects should not change during serialization.
   * If an object is serialized more than once, [stringify] is allowed to cache
   * the JSON text for it. I.e., if an object changes after it is first
   * serialized, the new values may or may not be reflected in the result.
   */
  String convert(Object o) =>
      _JsonStringifier.stringify(o, _toEncodableFunction);

  /**
   * Starts a chunked conversion.
   *
   * The converter works more efficiently if the given [sink] is a
   * [StringConversionSink].
   *
   * Returns a chunked-conversion sink that accepts at most one object. It is
   * an error to invoke `add` more than once on the returned sink.
   */
  ChunkedConversionSink<Object> startChunkedConversion(
      ChunkedConversionSink<String> sink) {
    if (sink is! StringConversionSink) {
      sink = new StringConversionSink.from(sink);
    }
    return new _JsonEncoderSink(sink, _toEncodableFunction);
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
  final Function _toEncodableFunction;
  final StringConversionSink _sink;
  bool _isDone = false;

  _JsonEncoderSink(this._sink, this._toEncodableFunction);

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
    _JsonStringifier.printOn(o, stringSink, _toEncodableFunction);
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
  const JsonDecoder(reviver(var key, var value)) : this._reviver = reviver;

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
  StringConversionSink startChunkedConversion(
      ChunkedConversionSink<Object> sink) {
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
  final ChunkedConversionSink<Object> _chunkedSink;

  _JsonDecoderSink(this._reviver, this._chunkedSink)
      : super(new StringBuffer());

  void close() {
    super.close();
    StringBuffer buffer = _stringSink;
    String accumulated = buffer.toString();
    buffer.clear();
    Object decoded = _parseJson(accumulated, _reviver);
    _chunkedSink.add(decoded);
    _chunkedSink.close();
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
  static const int BACKSLASH       = 0x5c;
  static const int CHAR_b          = 0x62;
  static const int CHAR_f          = 0x66;
  static const int CHAR_n          = 0x6e;
  static const int CHAR_r          = 0x72;
  static const int CHAR_t          = 0x74;
  static const int CHAR_u          = 0x75;

  final Function toEncodable;
  final StringSink sink;
  final Set<Object> seen;

  _JsonStringifier(this.sink, this.toEncodable)
      : this.seen = new HashSet.identity();

  static String stringify(final object, toEncodable(object)) {
    if (toEncodable == null) toEncodable = _defaultToEncodable;
    StringBuffer output = new StringBuffer();
    _JsonStringifier stringifier = new _JsonStringifier(output, toEncodable);
    stringifier.stringifyValue(object);
    return output.toString();
  }

  static void printOn(final object, StringSink output, toEncodable(object)) {
    _JsonStringifier stringifier = new _JsonStringifier(output, toEncodable);
    stringifier.stringifyValue(object);
  }

  static String numberToString(num x) {
    return x.toString();
  }

  // ('0' + x) or ('a' + x - 10)
  static int hexDigit(int x) => x < 10 ? 48 + x : 87 + x;

  static void escape(StringSink sb, String s) {
    final int length = s.length;
    bool needsEscape = false;
    final charCodes = new List<int>();
    for (int i = 0; i < length; i++) {
      int charCode = s.codeUnitAt(i);
      if (charCode < 32) {
        needsEscape = true;
        charCodes.add(BACKSLASH);
        switch (charCode) {
        case BACKSPACE:
          charCodes.add(CHAR_b);
          break;
        case TAB:
          charCodes.add(CHAR_t);
          break;
        case NEWLINE:
          charCodes.add(CHAR_n);
          break;
        case FORM_FEED:
          charCodes.add(CHAR_f);
          break;
        case CARRIAGE_RETURN:
          charCodes.add(CHAR_r);
          break;
        default:
          charCodes.add(CHAR_u);
          charCodes.add(hexDigit((charCode >> 12) & 0xf));
          charCodes.add(hexDigit((charCode >> 8) & 0xf));
          charCodes.add(hexDigit((charCode >> 4) & 0xf));
          charCodes.add(hexDigit(charCode & 0xf));
          break;
        }
      } else if (charCode == QUOTE || charCode == BACKSLASH) {
        needsEscape = true;
        charCodes.add(BACKSLASH);
        charCodes.add(charCode);
      } else {
        charCodes.add(charCode);
      }
    }
    sb.write(needsEscape ? new String.fromCharCodes(charCodes) : s);
  }

  void checkCycle(final object) {
    if (seen.contains(object)) {
      throw new JsonCyclicError(object);
    }
    seen.add(object);
  }

  void stringifyValue(final object) {
    // Tries stringifying object directly. If it's not a simple value, List or
    // Map, call toJson() to get a custom representation and try serializing
    // that.
    if (!stringifyJsonValue(object)) {
      checkCycle(object);
      try {
        var customJson = toEncodable(object);
        if (!stringifyJsonValue(customJson)) {
          throw new JsonUnsupportedObjectError(object);
        }
        seen.remove(object);
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
  bool stringifyJsonValue(final object) {
    if (object is num) {
      // TODO: use writeOn.
      sink.write(numberToString(object));
      return true;
    } else if (identical(object, true)) {
      sink.write('true');
      return true;
    } else if (identical(object, false)) {
      sink.write('false');
       return true;
    } else if (object == null) {
      sink.write('null');
      return true;
    } else if (object is String) {
      sink.write('"');
      escape(sink, object);
      sink.write('"');
      return true;
    } else if (object is List) {
      checkCycle(object);
      List a = object;
      sink.write('[');
      if (a.length > 0) {
        stringifyValue(a[0]);
        // TODO: switch to Iterables.
        for (int i = 1; i < a.length; i++) {
          sink.write(',');
          stringifyValue(a[i]);
        }
      }
      sink.write(']');
      seen.remove(object);
      return true;
    } else if (object is Map) {
      checkCycle(object);
      Map<String, Object> m = object;
      sink.write('{');
      bool first = true;
      m.forEach((String key, Object value) {
        if (!first) {
          sink.write(',"');
        } else {
          sink.write('"');
        }
        escape(sink, key);
        sink.write('":');
        stringifyValue(value);
        first = false;
      });
      sink.write('}');
      seen.remove(object);
      return true;
    } else {
      return false;
    }
  }
}
