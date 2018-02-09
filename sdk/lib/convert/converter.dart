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
abstract class Converter<S, T> extends StreamTransformerBase<S, T> {
  const Converter();

  /**
   * Adapts [source] to be a `Converter<TS, TT>`.
   *
   * This allows [source] to be used at the new type, but at run-time it
   * must satisfy the requirements of both the new type and its original type.
   *
   * Conversion input must be both [SS] and [TS] and the output created by
   * [source] for those input must be both [ST] and [TT].
   */
  static Converter<TS, TT> castFrom<SS, ST, TS, TT>(Converter<SS, ST> source) =>
      new CastConverter<SS, ST, TS, TT>(source);

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
  Converter<S, TT> fuse<TT>(Converter<T, TT> other) {
    return new _FusedConverter<S, T, TT>(this, other);
  }

  /**
   * Starts a chunked conversion.
   *
   * The returned sink serves as input for the long-running conversion. The
   * given [sink] serves as output.
   */
  Sink<S> startChunkedConversion(Sink<T> sink) {
    throw new UnsupportedError(
        "This converter does not support chunked conversions: $this");
  }

  Stream<T> bind(Stream<S> stream) {
    return new Stream<T>.eventTransformed(
        stream, (EventSink sink) => new _ConverterStreamEventSink(this, sink));
  }

  /**
   * Provides a `Converter<RS, RT>` view of this stream transformer.
   *
   * If this transformer already has the desired type, or a subtype,
   * it is returned directly,
   * otherwise returns the result of `retype<RS, RT>()`.
   */
  Converter<RS, RT> cast<RS, RT>() {
    Converter<Object, Object> self = this;
    return self is Converter<RS, RT> ? self : retype<RS, RT>();
  }

  /**
   * Provides a `Converter<RS, RT>` view of this stream transformer.
   *
   * The resulting transformer will check at run-time that all conversion
   * inputs are actually instances of [S],
   * and it will check that all conversion output produced by this converter
   * are acually instances of [RT].
   */
  Converter<RS, RT> retype<RS, RT>() => Converter.castFrom<S, T, RS, RT>(this);
}

/**
 * Fuses two converters.
 *
 * For a non-chunked conversion converts the input in sequence.
 */
class _FusedConverter<S, M, T> extends Converter<S, T> {
  final Converter<S, M> _first;
  final Converter<M, T> _second;

  _FusedConverter(this._first, this._second);

  T convert(S input) => _second.convert(_first.convert(input));

  Sink<S> startChunkedConversion(Sink<T> sink) {
    return _first.startChunkedConversion(_second.startChunkedConversion(sink));
  }
}
