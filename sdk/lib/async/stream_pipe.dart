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
 * A [StreamTransformer] that forwards events and subscriptions.
 *
 * By default this transformer subscribes to [_source] and forwards all events
 * to [_stream]. It does not subscribe to [_source] until there is a subscriber,
 * on [_stream] and unsubscribes again when there are no subscribers left.
 *
 * The events are passed through the [_handleData], [_handleError] and
 * [_handleDone] methods. Subclasses are supposed to add handling of some of
 * the events by overriding these methods.
 *
 * Handles backwards propagation of subscription and pause.
 *
 * This class is intended for internal use only.
 */
class _ForwardingStreamTransformer<S, T> implements StreamTransformer<S, T> {
  Stream<T> _stream;
  Stream<S> _source;
  StreamSubscription<S> _subscription;

  Stream<T> _createOutputStream() {
    if (_source.isSingleSubscription) {
      return new _ForwardingSingleStream<T>(this);
    }
    return new _ForwardingMultiStream<T>(this);
  }

  Stream<T> bind(Stream<S> source) {
    if (_source != null) {
      throw new StateError("Transformer source already bound");
    }
    _source = source;
    _stream = _createOutputStream();
    return _stream;
  }

  void _onPauseStateChange(bool isPaused) {
    if (isPaused) {
      if (_subscription != null) {
        _subscription.pause();
      }
    } else {
      if (_subscription != null) {
        _subscription.resume();
      }
    }
  }

  /**
    * Subscribe or unsubscribe on [_source] depending on whether
    * [_stream] has subscribers.
    */
  void _onSubscriptionStateChange(bool hasSubscribers) {
    if (hasSubscribers) {
      assert(_subscription == null);
      _subscription = _source.listen(this._handleData,
                                     onError: this._handleError,
                                     onDone: this._handleDone);
    } else {
      // TODO(lrn): Check why this can happen.
      if (_subscription == null) return;
      _subscription.cancel();
      _subscription = null;
    }
  }

  void _handleData(S inputEvent) {
    var outputEvent = inputEvent;
    _stream._add(outputEvent);
  }

  void _handleError(AsyncError error) {
    _stream._signalError(error);
  }

  void _handleDone() {
    _stream._close();
  }
}

class _ForwardingMultiStream<T> extends _MultiStreamImpl<T> {
  _ForwardingStreamTransformer _transformer;
  _ForwardingMultiStream(this._transformer);

  _onSubscriptionStateChange() {
    _transformer._onSubscriptionStateChange(_hasSubscribers);
  }

  _onPauseStateChange() {
    _transformer._onPauseStateChange(_isPaused);
  }
}

class _ForwardingSingleStream<T> extends _SingleStreamImpl<T> {
  _ForwardingStreamTransformer _transformer;
  _ForwardingSingleStream(this._transformer);

  _onSubscriptionStateChange() {
    _transformer._onSubscriptionStateChange(_hasSubscribers);
  }

  _onPauseStateChange() {
    _transformer._onPauseStateChange(_isPaused);
  }
}


// -------------------------------------------------------------------
// Stream transformers used by the default Stream implementation.
// -------------------------------------------------------------------

typedef bool _Predicate<T>(T value);

class WhereTransformer<T> extends _ForwardingStreamTransformer<T, T> {
  final _Predicate<T> _test;

  WhereTransformer(bool test(T value))
      : this._test = test;

  void _handleData(T inputEvent) {
    bool satisfies;
    try {
      satisfies = _test(inputEvent);
    } catch (e, s) {
      _stream._signalError(_asyncError(e, s));
      return;
    }
    if (satisfies) {
      _stream._add(inputEvent);
    }
  }
}


typedef T _Transformation<S, T>(S value);

/**
 * A stream pipe that converts data events before passing them on.
 */
class MapTransformer<S, T> extends _ForwardingStreamTransformer<S, T> {
  final _Transformation _transform;

  MapTransformer(T transform(S event))
      : this._transform = transform;

  void _handleData(S inputEvent) {
    T outputEvent;
    try {
      outputEvent = _transform(inputEvent);
    } catch (e, s) {
      _stream._signalError(_asyncError(e, s));
      return;
    }
    _stream._add(outputEvent);
  }
}

/**
 * A stream pipe that converts data events before passing them on.
 */
class ExpandTransformer<S, T> extends _ForwardingStreamTransformer<S, T> {
  final _Transformation<S, Iterable<T>> _expand;

  ExpandTransformer(Iterable<T> expand(S event))
      : this._expand = expand;

  void _handleData(S inputEvent) {
    try {
      for (T value in _expand(inputEvent)) {
        _stream._add(value);
      }
    } catch (e, s) {
      // If either _expand or iterating the generated iterator throws,
      // we abort the iteration.
      _stream._signalError(_asyncError(e, s));
    }
  }
}


typedef void _ErrorTransformation(AsyncError error);
typedef bool _ErrorTest(error);

/**
 * A stream pipe that converts or disposes error events
 * before passing them on.
 */
class HandleErrorTransformer<T> extends _ForwardingStreamTransformer<T, T> {
  final _ErrorTransformation _transform;
  final _ErrorTest _test;

  HandleErrorTransformer(void transform(AsyncError event), bool test(error))
      : this._transform = transform, this._test = test;

  void _handleError(AsyncError error) {
    bool matches = true;
    if (_test != null) {
      try {
        matches = _test(error.error);
      } catch (e, s) {
        _stream._signalError(_asyncError(e, s, error));
        return;
      }
    }
    if (matches) {
      try {
        _transform(error);
      } catch (e, s) {
        _stream._signalError(_asyncError(e, s, error));
        return;
      }
    } else {
      _stream._signalError(error);
    }
  }
}


typedef void _TransformDataHandler<S, T>(S data, StreamSink<T> sink);
typedef void _TransformErrorHandler<T>(AsyncError data, StreamSink<T> sink);
typedef void _TransformDoneHandler<T>(StreamSink<T> sink);

/**
 * A stream transfomer that intercepts all events and can generate any event as
 * output.
 *
 * Each incoming event on the source stream is passed to the corresponding
 * provided event handler, along with a [StreamSink] linked to the output
 * Stream.
 * The handler can then decide exactly which events to send to the output.
 */
class _StreamTransformerImpl<S, T> extends _ForwardingStreamTransformer<S, T> {
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
    Stream<T> stream = super.bind(source);
    // Cache a Sink object to avoid creating a new one for each event.
    _sink = new _StreamImplSink(stream);
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


class TakeTransformer<T> extends _ForwardingStreamTransformer<T, T> {
  int _remaining;

  TakeTransformer(int count)
      : this._remaining = count {
    // This test is done early to avoid handling an async error
    // in the _handleData method.
    if (count is! int) throw new ArgumentError(count);
  }

  void _handleData(T inputEvent) {
    if (_remaining > 0) {
      _stream._add(inputEvent);
      _remaining -= 1;
      if (_remaining == 0) {
        // Closing also unsubscribes all subscribers, which unsubscribes
        // this from source.
        _stream._close();
      }
    }
  }
}


class TakeWhileTransformer<T> extends _ForwardingStreamTransformer<T, T> {
  final _Predicate<T> _test;

  TakeWhileTransformer(bool test(T value))
      : this._test = test;

  void _handleData(T inputEvent) {
    bool satisfies;
    try {
      satisfies = _test(inputEvent);
    } catch (e, s) {
      _stream._signalError(_asyncError(e, s));
      // The test didn't say true. Didn't say false either, but we stop anyway.
      _stream._close();
      return;
    }
    if (satisfies) {
      _stream._add(inputEvent);
    } else {
      _stream._close();
    }
  }
}

class SkipTransformer<T> extends _ForwardingStreamTransformer<T, T> {
  int _remaining;

  SkipTransformer(int count)
      : this._remaining = count{
    // This test is done early to avoid handling an async error
    // in the _handleData method.
    if (count is! int || count < 0) throw new ArgumentError(count);
  }

  void _handleData(T inputEvent) {
    if (_remaining > 0) {
      _remaining--;
      return;
    }
    return _stream._add(inputEvent);
  }
}

class SkipWhileTransformer<T> extends _ForwardingStreamTransformer<T, T> {
  final _Predicate<T> _test;
  bool _hasFailed = false;

  SkipWhileTransformer(bool test(T value))
      : this._test = test;

  void _handleData(T inputEvent) {
    if (_hasFailed) {
      _stream._add(inputEvent);
    }
    bool satisfies;
    try {
      satisfies = _test(inputEvent);
    } catch (e, s) {
      _stream._signalError(_asyncError(e, s));
      // A failure to return a boolean is considered "not matching".
      _hasFailed = true;
      return;
    }
    if (!satisfies) {
      _hasFailed = true;
      _stream._add(inputEvent);
    }
  }
}

typedef bool _Equality<T>(T a, T b);

class DistinctTransformer<T> extends _ForwardingStreamTransformer<T, T> {
  static var _SENTINEL = new Object();

  _Equality<T> _equals;
  var _previous = _SENTINEL;

  DistinctTransformer(bool equals(T a, T b))
      : _equals = equals;

  void _handleData(T inputEvent) {
    if (identical(_previous, _SENTINEL)) {
      _previous = inputEvent;
      return _stream._add(inputEvent);
    } else {
      bool isEqual;
      try {
        if (_equals == null) {
          isEqual = (_previous == inputEvent);
        } else {
          isEqual = _equals(_previous, inputEvent);
        }
      } catch (e, s) {
        _stream._signalError(_asyncError(e, s));
        return null;
      }
      if (!isEqual) {
        _stream._add(inputEvent);
        _previous = inputEvent;
      }
    }
  }
}
