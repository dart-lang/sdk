// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.convert;

typedef void _ChunkedConversionCallback<T>(T accumulated);

/**
 * A [ChunkedConversionSink] is used to transmit data more efficiently between
 * two converters during chunked conversions.
 */
abstract class ChunkedConversionSink<T> {
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
