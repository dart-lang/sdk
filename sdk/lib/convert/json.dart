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
  /** The exception thrown by object's [:toJson:] method, if any. */
  final cause;

  JsonUnsupportedObjectError(this.unsupportedObject, { this.cause });

  String toString() {
    if (cause != null) {
      return "Calling toJson method on object failed.";
    } else {
      return "Object toJson method returns non-serializable value.";
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
const JSON = const JsonCodec();

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
  Object decode(String str, {reviver(var key, var value)}) {
    return new JsonDecoder(reviver).convert(str);
  }

  JsonEncoder get encoder => new JsonEncoder();
  JsonDecoder get decoder => new JsonDecoder(null);
}

typedef _Reviver(var key, var value);

class _ReviverJsonCodec extends JsonCodec {
  final _Reviver _reviver;
  _ReviverJsonCodec(this._reviver);

  Object decode(String str, {reviver(var key, var value)}) {
    if (reviver == null) reviver = _reviver;
    return new JsonDecoder(reviver).convert(str);
  }

  JsonDecoder get decoder => new JsonDecoder(_reviver);
}

/**
 * This class converts JSON objects to strings.
 */
class JsonEncoder extends Converter<Object, String> {
  JsonEncoder();

  /**
   * Converts the given object [o] to its JSON representation.
   *
   * Directly serializable values are [num], [String], [bool], and [Null], as
   * well as some [List] and [Map] values.
   * For [List], the elements must all be serializable.
   * For [Map], the keys must be [String] and the values must be serializable.
   *
   * If a value is any other type is attempted serialized, a "toJson()" method
   * is invoked on the object and the result, which must be a directly
   * serializable value, is serialized instead of the original value.
   *
   * If the object does not support this method, throws, or returns a
   * value that is not directly serializable, a [JsonUnsupportedObjectError]
   * exception is thrown. If the call throws (including the case where there
   * is no nullary "toJson" method, the error is caught and stored in the
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
  String convert(Object o) => OLD_JSON_LIB.stringify(o);

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
    return new _JsonEncoderSink(sink);
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
  final StringConversionSink _sink;
  bool _isDone = false;

  _JsonEncoderSink(this._sink);

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
    OLD_JSON_LIB.printOn(o, stringSink);
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
  JsonDecoder(reviver(var key, var value)) : this._reviver = reviver;

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
  Object convert(String input) => _parseJson(input, _reviver);

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
