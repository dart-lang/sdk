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

/**
 * This class wraps a [Converter] for use as a [StreamTransformer].
 */
class _ConverterTransformStream<S, T> extends EventTransformStream<S, T> {
  final _ConverterStreamEventTransformer<S, T> _eventTransformer;

  _ConverterTransformStream(Stream<S> source, Converter converter)
      : this._withEventTransformer(
          source,
          new _ConverterStreamEventTransformer<S, T>(converter));

  _ConverterTransformStream._withEventTransformer(
      Stream<S> source,
      _ConverterStreamEventTransformer<S, T> eventTransformer)
      : _eventTransformer = eventTransformer,
        super(source, eventTransformer);

  /**
   * Starts listening to `this`.
   *
   * This starts the chunked conversion.
   */
  StreamSubscription<T> listen(void onData(T data),
                               { Function onError,
                                 void onDone(),
                                 bool cancelOnError }) {
    _eventTransformer._startChunkedConversion();
    return super.listen(onData, onError: onError, onDone: onDone,
                        cancelOnError: cancelOnError);
  }
}

/**
 * This class converts implements the logic for a chunked conversion as a
 * stream transformer.
 *
 * It is used as strategy in the [EventTransformStream].
 *
 * It also implements the [ChunkedConversionSink] interface so that it
 * can be used as output sink in a chunked conversion.
 */
class _ConverterStreamEventTransformer<S, T>
    implements ChunkedConversionSink<T>, StreamEventTransformer<S, T> {
  final Converter _converter;

  /** At every [handleData] this field is updated with the new event sink. */
  EventSink<T> _eventSink;

  /**
   * The input sink for new data. All data that is received with
   * [handleData] is added into this sink.
   */
  ChunkedConversionSink _chunkedSink;

  _ConverterStreamEventTransformer(this._converter);

  /**
   * Starts the chunked conversion.
   */
  void _startChunkedConversion() {
    _chunkedSink = _converter.startChunkedConversion(this);
  }

  /**
   * Not supported.
   */
  Stream bind(Stream otherStream) {
    throw new UnsupportedError("Converter streams must not call bind");
  }

  void add(T o) => _eventSink.add(o);
  void close() => _eventSink.close();

  void handleData(S event, EventSink<T> eventSink) {
    _eventSink = eventSink;
    try {
      _chunkedSink.add(event);
    } catch(e) {
      // TODO(floitsch): capture stack trace.
      eventSink.addError(e);
    } finally {
      _eventSink = null;
    }
  }

  void handleDone(EventSink<T> eventSink) {
    _eventSink = eventSink;
    try {
      _chunkedSink.close();
    } catch(e) {
      // TODO(floitsch): capture stack trace.
      eventSink.addError(e);
    } finally {
      _eventSink = null;
    }
  }

  void handleError(var errorEvent, EventSink<T> eventSink) {
    // TODO(floitsch): capture stack trace.
    eventSink.addError(errorEvent);
  }
}
