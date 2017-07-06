// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "dart:async";

/**
 * Wraps an [_EventSink] so it exposes only the [EventSink] interface.
 */
class _EventSinkWrapper<T> implements EventSink<T> {
  _EventSink _sink;
  _EventSinkWrapper(this._sink);

  void add(T data) {
    _sink._add(data);
  }

  void addError(error, [StackTrace stackTrace]) {
    _sink._addError(error, stackTrace);
  }

  void close() {
    _sink._close();
  }
}

/**
 * A StreamSubscription that pipes data through a sink.
 *
 * The constructor of this class takes a [_SinkMapper] which maps from
 * [EventSink] to [EventSink]. The input to the mapper is the output of
 * the transformation. The returned sink is the transformation's input.
 */
class _SinkTransformerStreamSubscription<S, T>
    extends _BufferingStreamSubscription<T> {
  /// The transformer's input sink.
  EventSink<S> _transformerSink;

  /// The subscription to the input stream.
  StreamSubscription<S> _subscription;

  _SinkTransformerStreamSubscription(Stream<S> source, _SinkMapper<S, T> mapper,
      void onData(T data), Function onError, void onDone(), bool cancelOnError)
      // We set the adapter's target only when the user is allowed to send data.
      : super(onData, onError, onDone, cancelOnError) {
    _EventSinkWrapper<T> eventSink = new _EventSinkWrapper<T>(this);
    _transformerSink = mapper(eventSink);
    _subscription =
        source.listen(_handleData, onError: _handleError, onDone: _handleDone);
  }

  /** Whether this subscription is still subscribed to its source. */
  bool get _isSubscribed => _subscription != null;

  // _EventSink interface.

  /**
   * Adds an event to this subscriptions.
   *
   * Contrary to normal [_BufferingStreamSubscription]s we may receive
   * events when the stream is already closed. Report them as state
   * error.
   */
  void _add(T data) {
    if (_isClosed) {
      throw new StateError("Stream is already closed");
    }
    super._add(data);
  }

  /**
   * Adds an error event to this subscriptions.
   *
   * Contrary to normal [_BufferingStreamSubscription]s we may receive
   * events when the stream is already closed. Report them as state
   * error.
   */
  void _addError(Object error, StackTrace stackTrace) {
    if (_isClosed) {
      throw new StateError("Stream is already closed");
    }
    super._addError(error, stackTrace);
  }

  /**
   * Adds a close event to this subscriptions.
   *
   * Contrary to normal [_BufferingStreamSubscription]s we may receive
   * events when the stream is already closed. Report them as state
   * error.
   */
  void _close() {
    if (_isClosed) {
      throw new StateError("Stream is already closed");
    }
    super._close();
  }

  // _BufferingStreamSubscription hooks.

  void _onPause() {
    if (_isSubscribed) _subscription.pause();
  }

  void _onResume() {
    if (_isSubscribed) _subscription.resume();
  }

  Future _onCancel() {
    if (_isSubscribed) {
      StreamSubscription subscription = _subscription;
      _subscription = null;
      return subscription.cancel();
    }
    return null;
  }

  void _handleData(S data) {
    try {
      _transformerSink.add(data);
    } catch (e, s) {
      _addError(e, s);
    }
  }

  void _handleError(error, [stackTrace]) {
    try {
      _transformerSink.addError(error, stackTrace);
    } catch (e, s) {
      if (identical(e, error)) {
        _addError(error, stackTrace);
      } else {
        _addError(e, s);
      }
    }
  }

  void _handleDone() {
    try {
      _subscription = null;
      _transformerSink.close();
    } catch (e, s) {
      _addError(e, s);
    }
  }
}

typedef EventSink<S> _SinkMapper<S, T>(EventSink<T> output);

/**
 * A StreamTransformer for Sink-mappers.
 *
 * A Sink-mapper takes an [EventSink] (its output) and returns another
 * EventSink (its input).
 *
 * Note that this class can be `const`.
 */
class _StreamSinkTransformer<S, T> implements StreamTransformer<S, T> {
  final _SinkMapper<S, T> _sinkMapper;
  const _StreamSinkTransformer(this._sinkMapper);

  Stream<T> bind(Stream<S> stream) =>
      new _BoundSinkStream<S, T>(stream, _sinkMapper);
}

/**
 * The result of binding a StreamTransformer for Sink-mappers.
 *
 * It contains the bound Stream and the sink-mapper. Only when the user starts
 * listening to this stream is the sink-mapper invoked. The result is used
 * to create a StreamSubscription that transforms events.
 */
class _BoundSinkStream<S, T> extends Stream<T> {
  final _SinkMapper<S, T> _sinkMapper;
  final Stream<S> _stream;

  bool get isBroadcast => _stream.isBroadcast;

  _BoundSinkStream(this._stream, this._sinkMapper);

  StreamSubscription<T> listen(void onData(T event),
      {Function onError, void onDone(), bool cancelOnError}) {
    cancelOnError = identical(true, cancelOnError);
    StreamSubscription<T> subscription =
        new _SinkTransformerStreamSubscription<S, T>(
            _stream, _sinkMapper, onData, onError, onDone, cancelOnError);
    return subscription;
  }
}

/// Data-handler coming from [StreamTransformer.fromHandlers].
typedef void _TransformDataHandler<S, T>(S data, EventSink<T> sink);

/// Error-handler coming from [StreamTransformer.fromHandlers].
typedef void _TransformErrorHandler<T>(
    Object error, StackTrace stackTrace, EventSink<T> sink);

/// Done-handler coming from [StreamTransformer.fromHandlers].
typedef void _TransformDoneHandler<T>(EventSink<T> sink);

/**
 * Wraps handlers (from [StreamTransformer.fromHandlers]) into an `EventSink`.
 *
 * This way we can reuse the code from [_StreamSinkTransformer].
 */
class _HandlerEventSink<S, T> implements EventSink<S> {
  final _TransformDataHandler<S, T> _handleData;
  final _TransformErrorHandler<T> _handleError;
  final _TransformDoneHandler<T> _handleDone;

  /// The output sink where the handlers should send their data into.
  EventSink<T> _sink;

  _HandlerEventSink(
      this._handleData, this._handleError, this._handleDone, this._sink) {
    if (_sink == null) {
      throw new ArgumentError("The provided sink must not be null.");
    }
  }

  bool get _isClosed => _sink == null;

  _reportClosedSink() {
    // TODO(29554): throw a StateError, and don't just report the problem.
    Zone.ROOT
      ..print("Sink is closed and adding to it is an error.")
      ..print("  See http://dartbug.com/29554.")
      ..print(StackTrace.current.toString());
  }

  void add(S data) {
    if (_isClosed) {
      _reportClosedSink();
    }
    if (_handleData != null) {
      _handleData(data, _sink);
    } else {
      _sink.add(data as T);
    }
  }

  void addError(Object error, [StackTrace stackTrace]) {
    if (_isClosed) {
      _reportClosedSink();
    }
    if (_handleError != null) {
      _handleError(error, stackTrace, _sink);
    } else {
      _sink.addError(error, stackTrace);
    }
  }

  void close() {
    if (_isClosed) return;
    var sink = _sink;
    _sink = null;
    if (_handleDone != null) {
      _handleDone(sink);
    } else {
      sink.close();
    }
  }
}

/**
 * A StreamTransformer that transformers events with the given handlers.
 *
 * Note that this transformer can only be used once.
 */
class _StreamHandlerTransformer<S, T> extends _StreamSinkTransformer<S, T> {
  _StreamHandlerTransformer(
      {void handleData(S data, EventSink<T> sink),
      void handleError(Object error, StackTrace stackTrace, EventSink<T> sink),
      void handleDone(EventSink<T> sink)})
      : super((EventSink<T> outputSink) {
          return new _HandlerEventSink<S, T>(
              handleData, handleError, handleDone, outputSink);
        });

  Stream<T> bind(Stream<S> stream) {
    return super.bind(stream);
  }
}

/// A closure mapping a stream and cancelOnError to a StreamSubscription.
typedef StreamSubscription<T> _SubscriptionTransformer<S, T>(
    Stream<S> stream, bool cancelOnError);

/**
 * A [StreamTransformer] that minimizes the number of additional classes.
 *
 * Instead of implementing three classes: a [StreamTransformer], a [Stream]
 * (as the result of a `bind` call) and a [StreamSubscription] (which does the
 * actual work), this class only requires a function that is invoked when the
 * last bit (the subscription) of the transformer-workflow is needed.
 *
 * The given transformer function maps from Stream and cancelOnError to a
 * `StreamSubscription`. As such it can also act on `cancel` events, making it
 * fully general.
 */
class _StreamSubscriptionTransformer<S, T> implements StreamTransformer<S, T> {
  final _SubscriptionTransformer<S, T> _onListen;

  const _StreamSubscriptionTransformer(this._onListen);

  Stream<T> bind(Stream<S> stream) =>
      new _BoundSubscriptionStream<S, T>(stream, _onListen);
}

/**
 * A stream transformed by a [_StreamSubscriptionTransformer].
 *
 * When this stream is listened to it invokes the [_onListen] function with
 * the stored [_stream]. Usually the transformer starts listening at this
 * moment.
 */
class _BoundSubscriptionStream<S, T> extends Stream<T> {
  final _SubscriptionTransformer<S, T> _onListen;
  final Stream<S> _stream;

  _BoundSubscriptionStream(this._stream, this._onListen);

  StreamSubscription<T> listen(void onData(T event),
      {Function onError, void onDone(), bool cancelOnError}) {
    cancelOnError = identical(true, cancelOnError);
    StreamSubscription<T> result = _onListen(_stream, cancelOnError);
    result.onData(onData);
    result.onError(onError);
    result.onDone(onDone);
    return result;
  }
}
