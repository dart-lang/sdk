// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.convert;

/**
 * A [Converter] converts data from one representation into another.
 *
 * It is recommended that implementations of `Converter` extend this class,
 * to inherit any further methods that may be added to the class.
 */
abstract class Converter<S, T> implements StreamTransformer {
  const Converter();

  /**
   * Converts [input] and returns the result of the conversion.
   */
  T convert(S input);

  /**
   * Fuses `this` with [other].
   *
   * Encoding with the resulting converter is equivalent to converting with
   * `this` before converting with `other`.
   */
  Converter<S, dynamic> fuse(Converter<T, dynamic> other) {
    return new _FusedConverter<S, T, dynamic>(this, other);
  }

  /**
   * Starts a chunked conversion.
   */
  ChunkedConversionSink startChunkedConversion(Sink sink) {
    throw new UnsupportedError(
        "This converter does not support chunked conversions: $this");
  }

  // Subclasses are encouraged to provide better types.
  Stream bind(Stream source) {
    return new Stream.eventTransformed(
        source,
        (EventSink sink) => new _ConverterStreamEventSink(this, sink));
  }
}

/**
 * Fuses two converters.
 *
 * For a non-chunked conversion converts the input in sequence.
 */
class _FusedConverter<S, M, T> extends Converter<S, T> {
  final Converter _first;
  final Converter _second;

  _FusedConverter(this._first, this._second);

  T convert(S input) => _second.convert(_first.convert(input));

  ChunkedConversionSink startChunkedConversion(Sink sink) {
    return _first.startChunkedConversion(_second.startChunkedConversion(sink));
  }
}
