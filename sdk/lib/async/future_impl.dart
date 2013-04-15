// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.async;

deprecatedFutureValue(_FutureImpl future) =>
  future._isComplete ? future._resultOrListeners : null;

class _CompleterImpl<T> implements Completer<T> {
  final Future<T> future;
  bool _isComplete = false;

  _CompleterImpl() : future = new _FutureImpl<T>();

  void complete([T value]) {
    if (_isComplete) throw new StateError("Future already completed");
    _isComplete = true;
    _FutureImpl future = this.future;
    future._setValue(value);
  }

  void completeError(Object error, [Object stackTrace = null]) {
    if (_isComplete) throw new StateError("Future already completed");
    _isComplete = true;
    if (stackTrace != null) {
      // Force the stack trace onto the error, even if it already had one.
      _attachStackTrace(error, stackTrace);
    }
    _FutureImpl future = this.future;
    future._setError(error);
  }

  bool get isCompleted => _isComplete;
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
}

/** Adapter for a [_FutureImpl] to be a future result listener. */
class _FutureListenerWrapper<T> implements _FutureListener<T> {
  _FutureImpl future;
  _FutureListener _nextListener;
  _FutureListenerWrapper(this.future);
  _sendValue(T value) { future._setValue(value); }
  _sendError(error) { future._setError(error); }
}

class _FutureImpl<T> implements Future<T> {
  static const int _INCOMPLETE = 0;
  static const int _VALUE = 1;
  static const int _ERROR = 2;
  static const int _UNHANDLED_ERROR = 4;

  /** Whether the future is complete, and as what. */
  int _state = _INCOMPLETE;

  bool get _isComplete => _state != _INCOMPLETE;
  bool get _hasValue => _state == _VALUE;
  bool get _hasError => (_state & _ERROR) != 0;
  bool get _hasUnhandledError => (_state & _UNHANDLED_ERROR) != 0;

  void _clearUnhandledError() {
    // Works because _UNHANDLED_ERROR is highest bit in use.
    _state &= ~_UNHANDLED_ERROR;
  }

  /**
   * Either the result, or a list of listeners until the future completes.
   *
   * The result of the future is either a value or an error.
   * A result is only stored when the future has completed.
   *
   * The listeners is an internally linked list of [_FutureListener]s.
   * Listeners are only remembered while the future is not yet complete.
   *
   * Since the result and the listeners cannot occur at the same time,
   * we can use the same field for both.
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
    if (!_isComplete) {
      if (onError == null) {
        return new _ThenFuture(f).._subscribeTo(this);
      }
      return new _SubscribeFuture(f, onError).._subscribeTo(this);
    }
    if (_hasError) {
      if (onError != null) {
        return _handleError(onError, null);
      }
      // The "f" funtion will never be called, so just return
      // a future that delegates to this. We don't want to return
      // this itself to give a signal that the future is complete.
      return new _FutureWrapper(this);
    } else {
      assert(_hasValue);
      return _handleValue(f);
    }
  }

  Future catchError(f(error), { bool test(error) }) {
    if (_hasValue) {
      return new _FutureWrapper(this);
    }
    if (!_isComplete) {
      return new _CatchErrorFuture(f, test).._subscribeTo(this);
    } else {
      return _handleError(f, test);
    }
  }

  Future<T> whenComplete(action()) {
    _WhenFuture<T> whenFuture = new _WhenFuture<T>(action);
    if (!_isComplete) {
      _addListener(whenFuture);
    } else if (_hasValue) {
      T value = _resultOrListeners;
      Timer.run(() {
        whenFuture._sendValue(value);
      });
    } else {
      assert(_hasError);
      _clearUnhandledError();
      var error = _resultOrListeners;
      Timer.run(() {
        whenFuture._sendError(error);
      });
    }
    return whenFuture;
  }

  /** Handle a late listener on a completed future with a value. */
  Future _handleValue(onValue(var value)) {
    assert(_hasValue);
    _ThenFuture thenFuture = new _ThenFuture(onValue);
    T value = _resultOrListeners;
    Timer.run(() { thenFuture._sendValue(value); });
    return thenFuture;
  }

  /** Handle a late listener on a completed future with an error. */
  Future _handleError(onError(error), bool test(error)) {
    assert(_hasError);
    _clearUnhandledError();
    var error = _resultOrListeners;
    _CatchErrorFuture errorFuture = new _CatchErrorFuture(onError, test);
    Timer.run(() { errorFuture._sendError(error); });
    return errorFuture;
  }

  Stream<T> asStream() => new Stream.fromFuture(this);

  void _setValue(T value) {
    if (_isComplete) throw new StateError("Future already completed");
    _FutureListener listeners = _removeListeners();
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
    _FutureListener listeners = _removeListeners();
    _state = _ERROR;
    _resultOrListeners = error;
    if (listeners == null) {
      _scheduleUnhandledError();
      return;
    }
    do {
      _FutureListener listener = listeners;
      listeners = listener._nextListener;
      listener._nextListener = null;
      listener._sendError(error);
    } while (listeners != null);
  }

  void _scheduleUnhandledError() {
    _state |= _UNHANDLED_ERROR;
    // Wait for the rest of the current event's duration to see
    // if a subscriber is added to handle the error.
    Timer.run(() {
      if (_hasUnhandledError) {
        // No error handler has been added since the error was set.
        _clearUnhandledError();
        var error = _resultOrListeners;
        print("Uncaught Error: ${error}");
        var trace = getAttachedStackTrace(error);
        if (trace != null) {
          print("Stack Trace:\n$trace\n");
        }
        throw error;
      }
    });
  }

  void _addListener(_FutureListener listener) {
    assert(!_isComplete);
    assert(listener._nextListener == null);
    listener._nextListener = _resultOrListeners;
    _resultOrListeners = listener;
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
      _addListener(future._asListener());
    } else if (_hasValue) {
      future._setValue(_resultOrListeners);
    } else {
      assert(_hasError);
      _clearUnhandledError();
      future._setError(_resultOrListeners);
    }
  }

  /**
   * Helper function to handle the result of transforming an incoming event.
   *
   * If the result is itself a [Future], this future is linked to that
   * future's output. If not, this future is completed with the result.
   */
  void _setOrChainValue(var result) {
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

  void _sendValue(S value);

  void _sendError(error);

  void _subscribeTo(_FutureImpl future) {
    future._addListener(this);
  }
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

  _sendValue(S value) {
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

  void _sendError(error) {
    _setError(error);
  }
}

/** Future returned by [Future.catchError]. */
class _CatchErrorFuture<T> extends _TransformFuture<T,T> {
  final _FutureErrorTest _test;
  final _FutureOnError _onError;

  _CatchErrorFuture(this._onError, this._test);

  _sendValue(T value) {
    _setValue(value);
  }

  _sendError(error) {
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

  void _sendError(error) {
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

  void _sendValue(T value) {
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

  void _sendError(error) {
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

/**
 * Thin wrapper around a [Future].
 *
 * This is used to return a "new" [Future] that effectively work just
 * as an existing [Future], without making this discoverable by comparing
 * identities.
 */
class _FutureWrapper<T> implements Future<T> {
  final Future<T> _future;

  _FutureWrapper(this._future);

  Future then(function(T value), { onError(error) }) {
    return _future.then(function, onError: onError);
  }

  Future catchError(function(error), {bool test(var error)}) {
    return _future.catchError(function, test: test);
  }

  Future<T> whenComplete(action()) {
    return _future.whenComplete(action);
  }

  Stream<T> asStream() => new Stream.fromFuture(_future);
}
