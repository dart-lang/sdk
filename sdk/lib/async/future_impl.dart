// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.async;

deprecatedFutureValue(_FutureImpl future) =>
  future._isComplete ? future._resultOrListeners : null;

abstract class _Completer<T> implements Completer<T> {
  final Future<T> future;
  bool _isComplete = false;

  _Completer() : future = new _FutureImpl<T>() {
    _FutureImpl futureImpl = future;
    futureImpl._zone.expectCallback();
  }

  void _setFutureValue(T value);
  void _setFutureError(error);

  void complete([T value]) {
    if (_isComplete) throw new StateError("Future already completed");
    _isComplete = true;
    _FutureImpl futureImpl = future;
    futureImpl._zone.unexpectCallback();
    _setFutureValue(value);
  }

  void completeError(Object error, [Object stackTrace = null]) {
    if (_isComplete) throw new StateError("Future already completed");
    _isComplete = true;
    if (stackTrace != null) {
      // Force the stack trace onto the error, even if it already had one.
      _attachStackTrace(error, stackTrace);
    }
    _FutureImpl futureImpl = future;
    if (futureImpl._inSameErrorZone(_Zone.current)) {
      futureImpl._zone.unexpectCallback();
      _setFutureError(error);
    } else {
      _Zone.current.handleUncaughtError(error);
    }
  }

  bool get isCompleted => _isComplete;
}

class _AsyncCompleter<T> extends _Completer<T> {
  void _setFutureValue(T value) {
    _FutureImpl future = this.future;
    runAsync(() { future._setValue(value); });
  }

  void _setFutureError(error) {
    _FutureImpl future = this.future;
    runAsync(() { future._setError(error); });
  }
}

class _SyncCompleter<T> extends _Completer<T> {
  void _setFutureValue(T value) {
    _FutureImpl future = this.future;
    future._setValue(value);
  }

  void _setFutureError(error) {
    _FutureImpl future = this.future;
    future._setError(error);
  }
}

/**
 * A listener on a future.
 *
 * When the future completes, the [_sendValue] or [_sendError] method
 * is invoked with the result.
 *
 * Listeners are kept in a linked list.
 */
abstract class _FutureListener<T> {
  _FutureListener _nextListener;
  factory _FutureListener.wrap(_FutureImpl future) {
    return new _FutureListenerWrapper(future);
  }
  void _sendValue(T value);
  void _sendError(error);

  bool _inSameErrorZone(_Zone otherZone);
}

/** Adapter for a [_FutureImpl] to be a future result listener. */
class _FutureListenerWrapper<T> implements _FutureListener<T> {
  _FutureImpl future;
  _FutureListener _nextListener;
  _FutureListenerWrapper(this.future);
  _sendValue(T value) { future._setValue(value); }
  _sendError(error) { future._setError(error); }
  bool _inSameErrorZone(_Zone otherZone) => future._inSameErrorZone(otherZone);
}

/**
 * This listener is installed at error-zone boundaries. It signals an
 * uncaught error in the zone of origin when an error is sent from one error
 * zone to another.
 *
 * When a Future is listening to another Future and they have not been
 * instantiated in the same error-zone then Futures put an instance of this
 * class between them (see [_FutureImpl._addListener]).
 *
 * For example:
 *
 *     var completer = new Completer();
 *     var future = completer.future.then((x) => x);
 *     catchErrors(() {
 *       var future2 = future.catchError(print);
 *     });
 *     completer.completeError(499);
 *
 * In this example `future` and `future2` are in different error-zones. The
 * error (499) that originates outside `catchErrors` must not reach the
 * `catchError` future (`future2`) inside `catchErrors`.
 *
 * When invoking `catchError` on `future` the Future installs an
 * [_ErrorZoneBoundaryListener] between itself and the result, `future2`.
 *
 * Conceptually _ErrorZoneBoundaryListeners could be implemented as
 * `catchError`s on the origin future as well.
 */
class _ErrorZoneBoundaryListener implements _FutureListener {
  _FutureListener _nextListener;
  final _FutureListener _listener;

  _ErrorZoneBoundaryListener(this._listener);

  bool _inSameErrorZone(_Zone otherZone) {
    // Should never be called. We use [_inSameErrorZone] to know if we have
    // to insert an instance of [_ErrorZoneBoundaryListener] (and in the
    // controller). Once we have inserted one we should never need to use it
    // anymore.
    // It would be valid to `return true` instead.
    throw new UnsupportedError(
        "A Zone boundary doesn't support the inSameErrorZone test.");
  }

  void _sendValue(value) {
    _listener._sendValue(value);
  }

  void _sendError(error) {
    // We are not allowed to send an error from one error-zone to another.
    // This is the whole purpose of this class.
    _Zone.current.handleUncaughtError(error);
  }
}

class _FutureImpl<T> implements Future<T> {
  // State of the future. The state determines the interpretation of the
  // [resultOrListeners] field.
  // TODO(lrn): rename field since it can also contain a chained future.

  /// Initial state, waiting for a result. In this state, the
  /// [resultOrListeners] field holds a single-linked list of
  /// [FutureListener] listeners.
  static const int _INCOMPLETE = 0;
  /// The future has been chained to another future. The result of that
  /// other future becomes the result of this future as well.
  /// In this state, the [resultOrListeners] field holds the future that
  /// will give the result to this future. Both existing and new listeners are
  /// forwarded directly to the other future.
  static const int _CHAINED = 1;
  /// The future has been chained to another future, but there hasn't been
  /// any listeners added to this future yet. If it is completed with an
  /// error, the error will be considered unhandled.
  static const int _CHAINED_UNLISTENED = 3;
  /// The future has been completed with a value result.
  static const int _VALUE = 4;
  /// The future has been completed with an error result.
  static const int _ERROR = 6;
  /// Extra bit set when the future has been completed with an error result.
  /// but no listener has been scheduled to receive the error.
  /// If the bit is still set when a [runAsync] call triggers, the error will
  /// be reported to the top-level handler.
  /// Assigning a listener before that time will clear the bit.
  static const int _UNHANDLED_ERROR = 8;

  /** Whether the future is complete, and as what. */
  int _state = _INCOMPLETE;

  final _Zone _zone = _Zone.current.fork();

  bool get _isChained => (_state & _CHAINED) != 0;
  bool get _hasChainedListener => _state == _CHAINED;
  bool get _isComplete => _state >= _VALUE;
  bool get _hasValue => _state == _VALUE;
  bool get _hasError => _state >= _ERROR;
  bool get _hasUnhandledError => _state >= _UNHANDLED_ERROR;

  void _clearUnhandledError() {
    _state &= ~_UNHANDLED_ERROR;
  }

  /**
   * Either the result, a list of listeners or another future.
   *
   * The result of the future is either a value or an error.
   * A result is only stored when the future has completed.
   *
   * The listeners is an internally linked list of [_FutureListener]s.
   * Listeners are only remembered while the future is not yet complete,
   * and it is not chained to another future.
   *
   * The future is another future that his future is chained to. This future
   * is waiting for the other future to complete, and when it does, this future
   * will complete with the same result.
   * All listeners are forwarded to the other future.
   *
   * The cases are disjoint (incomplete and unchained, incomplete and
   * chained, or completed with value or error), so the field only needs to hold
   * one value at a time.
   */
  var _resultOrListeners;

  _FutureImpl();

  _FutureImpl.immediate(T value) {
    _state = _VALUE;
    _resultOrListeners = value;
  }

  _FutureImpl.immediateError(var error, [Object stackTrace]) {
    if (stackTrace != null) {
      // Force stack trace onto error, even if it had already one.
      _attachStackTrace(error, stackTrace);
    }
    _setError(error);
  }

  factory _FutureImpl.wait(Iterable<Future> futures) {
    Completer completer;
    // List collecting values from the futures.
    // Set to null if an error occurs.
    List values;
    void handleError(error) {
      if (values != null) {
        values = null;
        completer.completeError(error);
      }
    }
    // As each future completes, put its value into the corresponding
    // position in the list of values.
    int remaining = 0;
    for (Future future in futures) {
      int pos = remaining++;
      future.catchError(handleError).then((Object value) {
        if (values == null) return null;
        values[pos] = value;
        remaining--;
        if (remaining == 0) {
          completer.complete(values);
        }
      });
    }
    if (remaining == 0) {
      return new Future.value(const []);
    }
    values = new List(remaining);
    completer = new Completer<List>();
    return completer.future;
  }

  Future then(f(T value), { onError(error) }) {
    if (onError == null) {
      return new _ThenFuture(f).._subscribeTo(this);
    }
    return new _SubscribeFuture(f, onError).._subscribeTo(this);
  }

  Future catchError(f(error), { bool test(error) }) {
    return new _CatchErrorFuture(f, test).._subscribeTo(this);
  }

  Future<T> whenComplete(action()) {
    return new _WhenFuture<T>(action).._subscribeTo(this);
  }

  Stream<T> asStream() => new Stream.fromFuture(this);

  bool _inSameErrorZone(_Zone otherZone) {
    return _zone.inSameErrorZone(otherZone);
  }

  void _setValue(T value) {
    if (_isComplete) throw new StateError("Future already completed");
    _FutureListener listeners = _isChained ? null : _removeListeners();
    _state = _VALUE;
    _resultOrListeners = value;
    while (listeners != null) {
      _FutureListener listener = listeners;
      listeners = listener._nextListener;
      listener._nextListener = null;
      listener._sendValue(value);
    }
  }

  void _setError(error) {
    if (_isComplete) throw new StateError("Future already completed");

    _FutureListener listeners;
    bool hasListeners;
    if (_isChained) {
      listeners = null;
      hasListeners = (_state == _CHAINED);  // and not _CHAINED_UNLISTENED.
    } else {
      listeners = _removeListeners();
      hasListeners = (listeners != null);
    }

    _state = _ERROR;
    _resultOrListeners = error;

    if (!hasListeners) {
      _scheduleUnhandledError();
      return;
    }
    while (listeners != null) {
      _FutureListener listener = listeners;
      listeners = listener._nextListener;
      listener._nextListener = null;
      listener._sendError(error);
    }
  }

  void _scheduleUnhandledError() {
    assert(_state == _ERROR);
    _state = _ERROR | _UNHANDLED_ERROR;
    // Wait for the rest of the current event's duration to see
    // if a subscriber is added to handle the error.
    runAsync(() {
      if (_hasUnhandledError) {
        // No error handler has been added since the error was set.
        _clearUnhandledError();
        // TODO(floitsch): Hook this into unhandled error handling.
        var error = _resultOrListeners;
        _zone.handleUncaughtError(error);
      }
    });
  }

  void _addListener(_FutureListener listener) {
    assert(listener._nextListener == null);
    if (!listener._inSameErrorZone(_zone)) {
      listener = new _ErrorZoneBoundaryListener(listener);
    }
    if (_isChained) {
      _state = _CHAINED;  // In case it was _CHAINED_UNLISTENED.
      _FutureImpl resultSource = _chainSource;
      resultSource._addListener(listener);
      return;
    }
    if (_isComplete) {
      _clearUnhandledError();
      // Handle late listeners asynchronously.
      runAsync(() {
        if (_hasValue) {
          T value = _resultOrListeners;
          listener._sendValue(value);
        } else {
          assert(_hasError);
          listener._sendError(_resultOrListeners);
        }
      });
    } else {
      assert(!_isComplete);
      listener._nextListener = _resultOrListeners;
      _resultOrListeners = listener;
    }
  }

  _FutureListener _removeListeners() {
    // Reverse listeners before returning them, so the resulting list is in
    // subscription order.
    assert(!_isComplete);
    _FutureListener current = _resultOrListeners;
    _resultOrListeners = null;
    _FutureListener prev = null;
    while (current != null) {
      _FutureListener next = current._nextListener;
      current._nextListener = prev;
      prev = current;
      current = next;
    }
    return prev;
  }

  /**
   * Make another [_FutureImpl] receive the result of this one.
   *
   * If this future is already complete, the [future] is notified
   * immediately. This function is only called during event resolution
   * where it's acceptable to send an event.
   */
  void _chain(_FutureImpl future) {
    if (!_isComplete) {
      future._chainFromFuture(this);
    } else if (_hasValue) {
      future._setValue(_resultOrListeners);
    } else {
      assert(_hasError);
      _clearUnhandledError();
      future._setError(_resultOrListeners);
    }
  }

  /**
   * Returns the future that this future is chained to.
   *
   * If that future is itself chained to something else,
   * get the [_chainSource] of that future instead, and make this
   * future chain directly to the earliest source.
   */
  _FutureImpl get _chainSource {
    assert(_isChained);
    _FutureImpl future = _resultOrListeners;
    if (future._isChained) {
      future = _resultOrListeners = future._chainSource;
    }
    return future;
  }

  /**
   * Make this incomplete future end up with the same result as [resultSource].
   *
   * This is done by moving all listeners to [resultSource] and forwarding all
   * future [_addListener] calls to [resultSource] directly.
   */
  void _chainFromFuture(_FutureImpl resultSource) {
    assert(!_isComplete);
    assert(!_isChained);
    if (resultSource._isChained) {
      resultSource = resultSource._chainSource;
    }
    assert(!resultSource._isChained);
    if (identical(this, resultSource)) {
      // The only unchained future in a future dependency tree (as defined
      // by the chain-relations) is the "root" that every other future depends
      // on. The future we are adding is unchained, so if it is already in the
      // tree, it must be the root, so that's the only one we need to check
      // against to detect a cycle.
      _setError(new StateError("Cyclic future dependency."));
      return;
    }
    _FutureListener cursor = _removeListeners();
    bool hadListeners = cursor != null;
    while (cursor != null) {
      _FutureListener listener = cursor;
      cursor = cursor._nextListener;
      listener._nextListener = null;
      resultSource._addListener(listener);
    }
    // Listen with this future as well, so that when the other future completes,
    // this future will be completed as well.
    resultSource._addListener(this._asListener());
    _resultOrListeners = resultSource;
    _state = hadListeners ? _CHAINED : _CHAINED_UNLISTENED;
  }

  /**
   * Helper function to handle the result of transforming an incoming event.
   *
   * If the result is itself a [Future], this future is linked to that
   * future's output. If not, this future is completed with the result.
   */
  void _setOrChainValue(var result) {
    assert(!_isChained);
    assert(!_isComplete);
    if (result is Future) {
      // Result should be a Future<T>.
      if (result is _FutureImpl) {
        _FutureImpl chainFuture = result;
        chainFuture._chain(this);
        return;
      } else {
        Future future = result;
        future.then(_setValue,
                    onError: _setError);
        return;
      }
    } else {
      // Result must be of type T.
      _setValue(result);
    }
  }

  _FutureListener _asListener() => new _FutureListener.wrap(this);
}

/**
 * Transforming future base class.
 *
 * A transforming future is itself a future and a future listener.
 * Subclasses override [_sendValue]/[_sendError] to intercept
 * the results of a previous future.
 */
abstract class _TransformFuture<S, T> extends _FutureImpl<T>
                                      implements _FutureListener<S> {
  // _FutureListener implementation.
  _FutureListener _nextListener;

  _TransformFuture() {
    _zone.expectCallback();
  }

  void _sendValue(S value) {
    _zone.executeCallback(() => _zonedSendValue(value));
  }

  void _sendError(error) {
    _zone.executeCallback(() => _zonedSendError(error));
  }

  void _subscribeTo(_FutureImpl future) {
    future._addListener(this);
  }

  void _zonedSendValue(S value);
  void _zonedSendError(error);
}

/** The onValue and onError handlers return either a value or a future */
typedef dynamic _FutureOnValue<T>(T value);
typedef dynamic _FutureOnError(error);
/** Test used by [Future.catchError] to handle skip some errors. */
typedef bool _FutureErrorTest(var error);
/** Used by [WhenFuture]. */
typedef _FutureAction();

/** Future returned by [Future.then] with no [:onError:] parameter. */
class _ThenFuture<S, T> extends _TransformFuture<S, T> {
  // TODO(ahe): Restore type when feature is implemented in dart2js
  // checked mode.
  final /* _FutureOnValue<S> */ _onValue;

  _ThenFuture(this._onValue);

  _zonedSendValue(S value) {
    assert(_onValue != null);
    var result;
    try {
      result = _onValue(value);
    } catch (e, s) {
      _setError(_asyncError(e, s));
      return;
    }
    _setOrChainValue(result);
  }

  void _zonedSendError(error) {
    _setError(error);
  }
}

/** Future returned by [Future.catchError]. */
class _CatchErrorFuture<T> extends _TransformFuture<T,T> {
  final _FutureErrorTest _test;
  final _FutureOnError _onError;

  _CatchErrorFuture(this._onError, this._test);

  _zonedSendValue(T value) {
    _setValue(value);
  }

  _zonedSendError(error) {
    assert(_onError != null);
    // if _test is supplied, check if it returns true, otherwise just
    // forward the error unmodified.
    if (_test != null) {
      bool matchesTest;
      try {
        matchesTest = _test(error);
      } catch (e, s) {
        _setError(_asyncError(e, s));
        return;
      }
      if (!matchesTest) {
        _setError(error);
        return;
      }
    }
    // Act on the error, and use the result as this future's result.
    var result;
    try {
      result = _onError(error);
    } catch (e, s) {
      _setError(_asyncError(e, s));
      return;
    }
    _setOrChainValue(result);
  }
}

/** Future returned by [Future.then] with an [:onError:] parameter. */
class _SubscribeFuture<S, T> extends _ThenFuture<S, T> {
  final _FutureOnError _onError;

  _SubscribeFuture(onValue(S value), this._onError) : super(onValue);

  // The _sendValue method is inherited from ThenFuture.

  void _zonedSendError(error) {
    assert(_onError != null);
    var result;
    try {
      result = _onError(error);
    } catch (e, s) {
      _setError(_asyncError(e, s));
      return;
    }
    _setOrChainValue(result);
  }
}

/** Future returned by [Future.whenComplete]. */
class _WhenFuture<T> extends _TransformFuture<T, T> {
  final _FutureAction _action;

  _WhenFuture(this._action);

  void _zonedSendValue(T value) {
    try {
      var result = _action();
      if (result is Future) {
        Future resultFuture = result;
        resultFuture.then((_) {
          _setValue(value);
        }, onError: _setError);
        return;
      }
    } catch (e, s) {
      _setError(_asyncError(e, s));
      return;
    }
    _setValue(value);
  }

  void _zonedSendError(error) {
    try {
      var result = _action();
      if (result is Future) {
        Future resultFuture = result;
        // TODO(lrn): Find a way to combine [error] into [e].
        resultFuture.then((_) {
          _setError(error);
        }, onError: _setError);
        return;
      }
    } catch (e, s) {
      error = _asyncError(e, s);
    }
    _setError(error);
  }
}
