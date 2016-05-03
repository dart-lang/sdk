// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.convert;

typedef void _ChunkedConversionCallback<T>(T accumulated);

/**
 * A converter that supports chunked conversions.
 *
 * In addition to immediate conversions from [S] to [T], a chunked converter
 * also supports longer-running conversions from [S2] to [T2].
 *
 * Frequently, the source and target types are the same, but this is not a
 * requirement. In particular, converters that work with lists in the
 * immediate conversion, could flatten the type for the chunked conversion.
 *
 * For example, the [LineSplitter] class returns a `List<String>` for the
 * immediate conversion, but returns individual `String`s in the chunked
 * conversion.
 */
abstract class ChunkedConverter<S, T, S2, T2> extends Converter<S, T> {

  const ChunkedConverter();

  /**
   * Starts a chunked conversion.
   *
   * The returned sink serves as input for the long-running conversion. The
   * given [sink] serves as output.
   */
  ChunkedConversionSink<S2> startChunkedConversion(Sink<T2> sink) {
    throw new UnsupportedError(
        "This converter does not support chunked conversions: $this");
  }

  Stream<T2> bind(Stream<S2> stream) {
    return new Stream<T2>.eventTransformed(
        stream,
        (EventSink<T2> sink) =>
            new _ConverterStreamEventSink<S2, T2>(this, sink));
  }

  /**
   * Fuses this instance with the given [other] converter.
   *
   * If [other] is a ChunkedConverter (with matching generic types), returns a
   * [ChunkedConverter].
   */
  Converter<S, dynamic> fuse(Converter<T, dynamic> other) {
    if (other is ChunkedConverter<T, dynamic, T2, dynamic>) {
      return new _FusedChunkedConverter<S, T, dynamic, S2, T2, dynamic>(
          this, other);
    }
    return super.fuse(other);
  }
}

/**
 * A [ChunkedConversionSink] is used to transmit data more efficiently between
 * two converters during chunked conversions.
 *
 * The basic `ChunkedConversionSink` is just a [Sink], and converters should
 * work with a plain `Sink`, but may work more efficiently with certain
 * specialized types of `ChunkedConversionSink`.
 *
 * It is recommended that implementations of `ChunkedConversionSink` extends
 * this class, to inherit any further methods that may be added to the class.
 */
abstract class ChunkedConversionSink<T> implements Sink<T> {
  ChunkedConversionSink();
  factory ChunkedConversionSink.withCallback(
      void callback(List<T> accumulated)) = _SimpleCallbackSink;

  /**
   * Adds chunked data to this sink.
   *
   * This method is also used when converters are used as [StreamTransformer]s.
   */
  void add(T chunk);

  /**
   * Closes the sink.
   *
   * This signals the end of the chunked conversion. This method is called
   * when converters are used as [StreamTransformer]'s.
   */
  void close();
}

/**
 * This class accumulates all chunks and invokes a callback with a list of
 * the chunks when the sink is closed.
 *
 * This class can be used to terminate a chunked conversion.
 */
class _SimpleCallbackSink<T> extends ChunkedConversionSink<T> {
  final _ChunkedConversionCallback<List<T>> _callback;
  final List<T> _accumulated = <T>[];

  _SimpleCallbackSink(this._callback);

  void add(T chunk) { _accumulated.add(chunk); }
  void close() { _callback(_accumulated); }
}

/**
 * This class implements the logic for a chunked conversion as a
 * stream transformer.
 *
 * It is used as strategy in the [EventTransformStream].
 *
 * It also implements the [ChunkedConversionSink] interface so that it
 * can be used as output sink in a chunked conversion.
 */
class _ConverterStreamEventSink<S, T> implements EventSink<S> {
  /** The output sink for the converter. */
  final EventSink<T> _eventSink;

  /**
   * The input sink for new data. All data that is received with
   * [handleData] is added into this sink.
   */
  final ChunkedConversionSink<S> _chunkedSink;

  _ConverterStreamEventSink(
      Converter/*=ChunkedConverter<dynamic, dynamic, S, T>*/ converter,
      EventSink<T> sink)
      : this._eventSink = sink,
        _chunkedSink = converter.startChunkedConversion(sink);

  void add(S o) { _chunkedSink.add(o); }
  void addError(Object error, [StackTrace stackTrace]) {
    _eventSink.addError(error, stackTrace);
  }
  void close() { _chunkedSink.close(); }
}

/**
 * Fuses two chunked converters.
 */
class _FusedChunkedConverter<S, M, T, S2, M2, T2> extends
    ChunkedConverter<S, T, S2, T2> {
  final ChunkedConverter<S, M, S2, M2> _first;
  final ChunkedConverter<M, T, M2, T2> _second;

  _FusedChunkedConverter(this._first, this._second);

  T convert(S input) => _second.convert(_first.convert(input));

  ChunkedConversionSink<S2> startChunkedConversion(Sink<T2> sink) {
    return _first.startChunkedConversion(_second.startChunkedConversion(sink));
  }
}
