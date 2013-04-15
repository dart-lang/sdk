// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.async;

/**
 * Utility function to attach a stack trace to an [error]  if it doesn't have
 * one already.
 */
_asyncError(Object error, Object stackTrace) {
  if (stackTrace == null) return error;
  if (getAttachedStackTrace(error) != null) return error;
  _attachStackTrace(error, stackTrace);
  return error;
}

/** Runs user code and takes actions depending on success or failure. */
_runUserCode(userCode(), onSuccess(value), onError(error)) {
  try {
    onSuccess(userCode());
  } catch (e, s) {
    onError(_asyncError(e, s));
  }
}

/** Helper function to make an onError argument to [_runUserCode]. */
_cancelAndError(StreamSubscription subscription, _FutureImpl future) =>
  (error) {
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

  StreamSubscription<T> listen(void onData(T value),
                              { void onError(error),
                                void onDone(),
                                bool cancelOnError }) {
    if (onData == null) onData = _nullDataHandler;
    if (onError == null) onError = _nullErrorHandler;
    if (onDone == null) onDone = _nullDoneHandler;
    cancelOnError = identical(true, cancelOnError);
    return _createSubscription(onData, onError, onDone, cancelOnError);
  }

  StreamSubscription<T> _createSubscription(void onData(T value),
                                            void onError(error),
                                            void onDone(),
                                            bool cancelOnError) {
    return new _ForwardingStreamSubscription<S, T>(
        this, onData, onError, onDone, cancelOnError);
  }

  // Override the following methods in subclasses to change the behavior.

  void _handleData(S data, _EventOutputSink<T> sink) {
    var outputData = data;
    sink._sendData(outputData);
  }

  void _handleError(error, _EventOutputSink<T> sink) {
    sink._sendError(error);
  }

  void _handleDone(_EventOutputSink<T> sink) {
    sink._sendDone();
  }
}

/**
 * Common behavior of [StreamSubscription] classes.
 *
 * Stores and allows updating of the event handlers of a [StreamSubscription].
 */
abstract class _BaseStreamSubscription<T> implements StreamSubscription<T> {
  // TODO(ahe): Restore type when feature is implemented in dart2js
  // checked mode. http://dartbug.com/7733
  var /* _DataHandler<T> */ _onData;
  _ErrorHandler _onError;
  _DoneHandler _onDone;

  _BaseStreamSubscription(this._onData,
                          this._onError,
                          this._onDone) {
    if (_onData == null) _onData = _nullDataHandler;
    if (_onError == null) _onError = _nullErrorHandler;
    if (_onDone == null) _onDone = _nullDoneHandler;
  }

  // StreamSubscription interface.
  void onData(void handleData(T event)) {
    if (handleData == null) handleData = _nullDataHandler;
    _onData = handleData;
  }

  void onError(void handleError(error)) {
    if (handleError == null) handleError = _nullErrorHandler;
    _onError = handleError;
  }

  void onDone(void handleDone()) {
    if (handleDone == null) handleDone = _nullDoneHandler;
    _onDone = handleDone;
  }

  void pause([Future resumeSignal]);

  void resume();

  void cancel();

  Future asFuture([var futureValue]) {
    _FutureImpl<T> result = new _FutureImpl<T>();

    // Overwrite the onDone and onError handlers.
    onDone(() { result._setValue(futureValue); });
    onError((error) {
      cancel();
      result._setError(error);
    });

    return result;
  }
}


/**
 * Abstract superclass for subscriptions that forward to other subscriptions.
 */
class _ForwardingStreamSubscription<S, T>
    extends _BaseStreamSubscription<T> implements _EventOutputSink<T> {
  final _ForwardingStream<S, T> _stream;
  final bool _cancelOnError;

  StreamSubscription<S> _subscription;

  _ForwardingStreamSubscription(this._stream,
                                void onData(T data),
                                void onError(error),
                                void onDone(),
                                this._cancelOnError)
      : super(onData, onError, onDone) {
    // Don't unsubscribe on incoming error, only if we send an error forwards.
    _subscription =
        _stream._source.listen(_handleData,
                               onError: _handleError,
                               onDone: _handleDone);
  }

  // StreamSubscription interface.

  void pause([Future resumeSignal]) {
    if (_subscription == null) return;
    _subscription.pause(resumeSignal);
  }

  void resume() {
    if (_subscription == null) return;
    _subscription.resume();
  }

  void cancel() {
    if (_subscription != null) {
      _subscription.cancel();
      _subscription = null;
    }
  }

  // _EventOutputSink interface. Sends data to this subscription.

  void _sendData(T data) {
    _onData(data);
  }

  void _sendError(error) {
    _onError(error);
    if (_cancelOnError) {
      _subscription.cancel();
      _subscription = null;
    }
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

  void _handleError(error) {
    _stream._handleError(error, this);
  }

  void _handleDone() {
    // On a done-event, we have already been unsubscribed.
    _subscription = null;
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

  void _handleData(T inputEvent, _EventOutputSink<T> sink) {
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

  void _handleData(S inputEvent, _EventOutputSink<T> sink) {
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

  void _handleData(S inputEvent, _EventOutputSink<T> sink) {
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


typedef void _ErrorTransformation(error);
typedef bool _ErrorTest(error);

/**
 * A stream pipe that converts or disposes error events
 * before passing them on.
 */
class _HandleErrorStream<T> extends _ForwardingStream<T, T> {
  final _ErrorTransformation _transform;
  final _ErrorTest _test;

  _HandleErrorStream(Stream<T> source,
                    void transform(event),
                    bool test(error))
      : this._transform = transform, this._test = test, super(source);

  void _handleError(Object error, _EventOutputSink<T> sink) {
    bool matches = true;
    if (_test != null) {
      try {
        matches = _test(error);
      } catch (e, s) {
        sink._sendError(_asyncError(e, s));
        return;
      }
    }
    if (matches) {
      try {
        _transform(error);
      } catch (e, s) {
        sink._sendError(_asyncError(e, s));
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

  void _handleData(T inputEvent, _EventOutputSink<T> sink) {
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

  void _handleData(T inputEvent, _EventOutputSink<T> sink) {
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

  void _handleData(T inputEvent, _EventOutputSink<T> sink) {
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

  void _handleData(T inputEvent, _EventOutputSink<T> sink) {
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

  void _handleData(T inputEvent, _EventOutputSink<T> sink) {
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

// Stream transformations and event transformations.

typedef void _TransformDataHandler<S, T>(S data, EventSink<T> sink);
typedef void _TransformErrorHandler<T>(data, EventSink<T> sink);
typedef void _TransformDoneHandler<T>(EventSink<T> sink);

/** Default data handler forwards all data. */
void _defaultHandleData(var data, EventSink sink) {
  sink.add(data);
}

/** Default error handler forwards all errors. */
void _defaultHandleError(error, EventSink sink) {
  sink.addError(error);
}

/** Default done handler forwards done. */
void _defaultHandleDone(EventSink sink) {
  sink.close();
}


/**
 * A [StreamTransformer] that modifies stream events.
 *
 * This class is used by [StreamTransformer]'s factory constructor.
 * It is actually an [StreamEventTransformer] where the functions used to
 * modify the events are passed as constructor arguments.
 *
 * If an argument is omitted, it acts as the default method from
 * [StreamEventTransformer].
 */
class _StreamTransformerImpl<S, T> extends StreamEventTransformer<S, T> {
  // TODO(ahe): Restore type when feature is implemented in dart2js
  // checked mode. http://dartbug.com/7733
  final Function /*_TransformDataHandler<S, T>*/ _handleData;
  final _TransformErrorHandler<T> _handleError;
  final _TransformDoneHandler<T> _handleDone;

  _StreamTransformerImpl(void handleData(S data, EventSink<T> sink),
                         void handleError(data, EventSink<T> sink),
                         void handleDone(EventSink<T> sink))
      : this._handleData  = (handleData == null  ? _defaultHandleData
                                                 : handleData),
        this._handleError = (handleError == null ? _defaultHandleError
                                                 : handleError),
        this._handleDone  = (handleDone == null  ? _defaultHandleDone
                                                 : handleDone);

  void handleData(S data, EventSink<T> sink) {
    _handleData(data, sink);
  }

  void handleError(error, EventSink<T> sink) {
    _handleError(error, sink);
  }

  void handleDone(EventSink<T> sink) {
    _handleDone(sink);
  }
}

