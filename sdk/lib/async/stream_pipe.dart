// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.async;

/** Utility function to create an [AsyncError] if [error] isn't one already. */
AsyncError _asyncError(Object error, Object stackTrace, [AsyncError cause]) {
  if (error is AsyncError) return error;
  if (cause == null) return new AsyncError(error, stackTrace);
  return new AsyncError.withCause(error, stackTrace, cause);
}

/** Runs user code and takes actions depending on success or failure. */
_runUserCode(userCode(), onSuccess(value), onError(AsyncError error),
             { AsyncError cause }) {
  var result;
  try {
    result = userCode();
  } on AsyncError catch (e) {
    return onError(e);
  } catch (e, s) {
    if (cause == null) {
      onError(new AsyncError(e, s));
    } else {
      onError(new AsyncError.withCause(e, s, cause));
    }
  }
  onSuccess(result);
}

/** Helper function to make an onError argument to [_runUserCode]. */
_cancelAndError(StreamSubscription subscription, _FutureImpl future) =>
  (AsyncError error) {
    subscription.cancel();
    future._setError(error);
  };


/**
 * A [Stream] that forwards subscriptions to another stream.
 *
 * This stream implements [Stream], but forwards all subscriptions
 * to an underlying stream, and wraps the returned subscription to
 * modify the events on the way.
 *
 * This class is intended for internal use only.
 */
abstract class _ForwardingStream<S, T> extends Stream<T> {
  final Stream<S> _source;

  _ForwardingStream(this._source);

  bool get isBroadcast => _source.isBroadcast;

  bool asBroadcastStream() => _source.asBroadcastStream;

  StreamSubscription listen(void onData(T value),
                            { void onError(AsyncError error),
                              void onDone(),
                              bool unsubscribeOnError }) {
    if (onData == null) onData = _nullDataHandler;
    if (onError == null) onError = _nullErrorHandler;
    if (onDone == null) onDone = _nullDoneHandler;
    unsubscribeOnError = identical(true, unsubscribeOnError);
    StreamSubscription subscription =
        new _ForwardingStreamSubscription<S, T>(
            this, onData, onError, onDone, unsubscribeOnError);
    return subscription;
  }

  // Override the following methods in subclasses to change the behavior.

  void _handleData(S data, _StreamOutputSink<T> sink) {
    var outputData = data;
    sink._sendData(outputData);
  }

  void _handleError(AsyncError error, _StreamOutputSink<T> sink) {
    sink._sendError(error);
  }

  void _handleDone(_StreamOutputSink<T> sink) {
    sink._sendDone();
  }
}

/**
 * Abstract superclass for subscriptions that forward to other subscriptions.
 */
class _ForwardingStreamSubscription<S, T>
    implements StreamSubscription<T>, _StreamOutputSink<T> {
  final _ForwardingStream<S, T> _stream;
  // TODO(ahe): Restore type when feature is implemented in dart2js
  // checked mode. http://dartbug.com/7733
  var /* _DataHandler<T> */ _onData;
  _ErrorHandler _onError;
  _DoneHandler _onDone;

  StreamSubscription<S> _subscription;

  _ForwardingStreamSubscription(this._stream,
                                this._onData,
                                this._onError,
                                this._onDone,
                                bool unsubscribeOnError) {
    _subscription =
        _stream._source.listen(_handleData,
                               onError: _handleError,
                               onDone: _handleDone,
                               unsubscribeOnError: unsubscribeOnError);
  }

  // StreamSubscription interface.

  void onData(void handleData(T event)) {
    if (handleData == null) handleData = _nullDataHandler;
    _onData = handleData;
  }

  void onError(void handleError(AsyncError error)) {
    if (handleError == null) handleError = _nullErrorHandler;
    _onError = handleError;
  }

  void onDone(void handleDone()) {
    if (handleDone == null) handleDone = _nullDoneHandler;
    _onDone = handleDone;
  }

  void pause([Future resumeSignal]) {
    if (_subscription == null) {
      throw new StateError("Subscription has been unsubscribed");
    }
    _subscription.pause(resumeSignal);
  }

  void resume() {
    if (_subscription == null) {
      throw new StateError("Subscription has been unsubscribed");
    }
    _subscription.resume();
  }

  void cancel() {
    if (_subscription == null) {
      throw new StateError("Subscription has been unsubscribed");
    }
    _subscription.cancel();
    _subscription = null;
  }

  // _StreamOutputSink interface. Sends data to this subscription.

  void _sendData(T data) {
    _onData(data);
  }

  void _sendError(AsyncError error) {
    _onError(error);
  }

  void _sendDone() {
    // If the transformation sends a done signal, we stop the subscription.
    if (_subscription != null) {
      _subscription.cancel();
      _subscription = null;
    }
    _onDone();
  }

  // Methods used as listener on source subscription.

  // TODO(ahe): Restore type when feature is implemented in dart2js
  // checked mode. http://dartbug.com/7733
  void _handleData(/*S*/ data) {
    _stream._handleData(data, this);
  }

  void _handleError(AsyncError error) {
    _stream._handleError(error, this);
  }

  void _handleDone() {
    _stream._handleDone(this);
  }
}

// -------------------------------------------------------------------
// Stream transformers used by the default Stream implementation.
// -------------------------------------------------------------------

typedef bool _Predicate<T>(T value);

class _WhereStream<T> extends _ForwardingStream<T, T> {
  final _Predicate<T> _test;

  _WhereStream(Stream<T> source, bool test(T value))
      : _test = test, super(source);

  void _handleData(T inputEvent, _StreamOutputSink<T> sink) {
    bool satisfies;
    try {
      satisfies = _test(inputEvent);
    } catch (e, s) {
      sink._sendError(_asyncError(e, s));
      return;
    }
    if (satisfies) {
      sink._sendData(inputEvent);
    }
  }
}


typedef T _Transformation<S, T>(S value);

/**
 * A stream pipe that converts data events before passing them on.
 */
class _MapStream<S, T> extends _ForwardingStream<S, T> {
  final _Transformation _transform;

  _MapStream(Stream<S> source, T transform(S event))
      : this._transform = transform, super(source);

  void _handleData(S inputEvent, _StreamOutputSink<T> sink) {
    T outputEvent;
    try {
      outputEvent = _transform(inputEvent);
    } catch (e, s) {
      sink._sendError(_asyncError(e, s));
      return;
    }
    sink._sendData(outputEvent);
  }
}

/**
 * A stream pipe that converts data events before passing them on.
 */
class _ExpandStream<S, T> extends _ForwardingStream<S, T> {
  final _Transformation<S, Iterable<T>> _expand;

  _ExpandStream(Stream<S> source, Iterable<T> expand(S event))
      : this._expand = expand, super(source);

  void _handleData(S inputEvent, _StreamOutputSink<T> sink) {
    try {
      for (T value in _expand(inputEvent)) {
        sink._sendData(value);
      }
    } catch (e, s) {
      // If either _expand or iterating the generated iterator throws,
      // we abort the iteration.
      sink._sendError(_asyncError(e, s));
    }
  }
}


typedef void _ErrorTransformation(AsyncError error);
typedef bool _ErrorTest(error);

/**
 * A stream pipe that converts or disposes error events
 * before passing them on.
 */
class _HandleErrorStream<T> extends _ForwardingStream<T, T> {
  final _ErrorTransformation _transform;
  final _ErrorTest _test;

  _HandleErrorStream(Stream<T> source,
                    void transform(AsyncError event),
                    bool test(error))
      : this._transform = transform, this._test = test, super(source);

  void _handleError(AsyncError error, _StreamOutputSink<T> sink) {
    bool matches = true;
    if (_test != null) {
      try {
        matches = _test(error.error);
      } catch (e, s) {
        sink._sendError(_asyncError(e, s, error));
        return;
      }
    }
    if (matches) {
      try {
        _transform(error);
      } catch (e, s) {
        sink._sendError(_asyncError(e, s, error));
        return;
      }
    } else {
      sink._sendError(error);
    }
  }
}


class _TakeStream<T> extends _ForwardingStream<T, T> {
  int _remaining;

  _TakeStream(Stream<T> source, int count)
      : this._remaining = count, super(source) {
    // This test is done early to avoid handling an async error
    // in the _handleData method.
    if (count is! int) throw new ArgumentError(count);
  }

  void _handleData(T inputEvent, _StreamOutputSink<T> sink) {
    if (_remaining > 0) {
      sink._sendData(inputEvent);
      _remaining -= 1;
      if (_remaining == 0) {
        // Closing also unsubscribes all subscribers, which unsubscribes
        // this from source.
        sink._sendDone();
      }
    }
  }
}


class _TakeWhileStream<T> extends _ForwardingStream<T, T> {
  final _Predicate<T> _test;

  _TakeWhileStream(Stream<T> source, bool test(T value))
      : this._test = test, super(source);

  void _handleData(T inputEvent, _StreamOutputSink<T> sink) {
    bool satisfies;
    try {
      satisfies = _test(inputEvent);
    } catch (e, s) {
      sink._sendError(_asyncError(e, s));
      // The test didn't say true. Didn't say false either, but we stop anyway.
      sink._sendDone();
      return;
    }
    if (satisfies) {
      sink._sendData(inputEvent);
    } else {
      sink._sendDone();
    }
  }
}

class _SkipStream<T> extends _ForwardingStream<T, T> {
  int _remaining;

  _SkipStream(Stream<T> source, int count)
      : this._remaining = count, super(source) {
    // This test is done early to avoid handling an async error
    // in the _handleData method.
    if (count is! int || count < 0) throw new ArgumentError(count);
  }

  void _handleData(T inputEvent, _StreamOutputSink<T> sink) {
    if (_remaining > 0) {
      _remaining--;
      return;
    }
    return sink._sendData(inputEvent);
  }
}

class _SkipWhileStream<T> extends _ForwardingStream<T, T> {
  final _Predicate<T> _test;
  bool _hasFailed = false;

  _SkipWhileStream(Stream<T> source, bool test(T value))
      : this._test = test, super(source);

  void _handleData(T inputEvent, _StreamOutputSink<T> sink) {
    if (_hasFailed) {
      sink._sendData(inputEvent);
    }
    bool satisfies;
    try {
      satisfies = _test(inputEvent);
    } catch (e, s) {
      sink._sendError(_asyncError(e, s));
      // A failure to return a boolean is considered "not matching".
      _hasFailed = true;
      return;
    }
    if (!satisfies) {
      _hasFailed = true;
      sink._sendData(inputEvent);
    }
  }
}

typedef bool _Equality<T>(T a, T b);

class _DistinctStream<T> extends _ForwardingStream<T, T> {
  static var _SENTINEL = new Object();

  _Equality<T> _equals;
  var _previous = _SENTINEL;

  _DistinctStream(Stream<T> source, bool equals(T a, T b))
      : _equals = equals, super(source);

  void _handleData(T inputEvent, _StreamOutputSink<T> sink) {
    if (identical(_previous, _SENTINEL)) {
      _previous = inputEvent;
      return sink._sendData(inputEvent);
    } else {
      bool isEqual;
      try {
        if (_equals == null) {
          isEqual = (_previous == inputEvent);
        } else {
          isEqual = _equals(_previous, inputEvent);
        }
      } catch (e, s) {
        sink._sendError(_asyncError(e, s));
        return null;
      }
      if (!isEqual) {
        sink._sendData(inputEvent);
        _previous = inputEvent;
      }
    }
  }
}


typedef void _TransformDataHandler<S, T>(S data, StreamSink<T> sink);
typedef void _TransformErrorHandler<T>(AsyncError data, StreamSink<T> sink);
typedef void _TransformDoneHandler<T>(StreamSink<T> sink);

/**
 * A stream transformer that intercepts all events and can generate any event as
 * output.
 *
 * Each incoming event on the source stream is passed to the corresponding
 * provided event handler, along with a [StreamSink] linked to the output
 * Stream.
 * The handler can then decide exactly which events to send to the output.
 */
class _StreamTransformerImpl<S, T> implements StreamTransformer<S, T> {
  final _TransformDataHandler<S, T> _onData;
  final _TransformErrorHandler<T> _onError;
  final _TransformDoneHandler<T> _onDone;
  StreamSink<T> _sink;

  _StreamTransformerImpl(void onData(S data, StreamSink<T> sink),
                         void onError(AsyncError data, StreamSink<T> sink),
                         void onDone(StreamSink<T> sink))
      : this._onData = (onData == null ? _defaultHandleData : onData),
        this._onError = (onError == null ? _defaultHandleError : onError),
        this._onDone = (onDone == null ? _defaultHandleDone : onDone);

  Stream<T> bind(Stream<S> source) {
    Stream<T> stream = new _SingleStreamImpl<T>();
    // Cache a Sink object to avoid creating a new one for each event.
    _sink = new _StreamImplSink(stream);
    source.listen(_handleData, onError: _handleError, onDone: _handleDone);
    return stream;
  }

  void _handleData(S data) {
    try {
      _onData(data, _sink);
    } catch (e, s) {
      _stream._signalError(_asyncError(e, s));
    }
  }

  void _handleError(AsyncError error) {
    try {
      _onError(error, _sink);
    } catch (e, s) {
      _stream._signalError(_asyncError(e, s, error));
    }
  }

  void _handleDone() {
    try {
      _onDone(_sink);
    } catch (e, s) {
      _stream._signalError(_asyncError(e, s));
    }
  }

  /** Default data handler forwards all data. */
  static void _defaultHandleData(var data, StreamSink sink) {
    sink.add(data);
  }
  /** Default error handler forwards all errors. */
  static void _defaultHandleError(AsyncError error, StreamSink sink) {
    sink.signalError(error);
  }
  /** Default done handler forwards done. */
  static void _defaultHandleDone(StreamSink sink) {
    sink.close();
  }
}

/** Creates a [StreamSink] from a [_StreamImpl]'s input methods. */
class _StreamImplSink<T> implements StreamSink<T> {
  _StreamImpl<T> _target;
  _StreamImplSink(this._target);
  void add(T data) { _target._add(data); }
  void signalError(AsyncError error) { _target._signalError(error); }
  void close() { _target._close(); }
}
