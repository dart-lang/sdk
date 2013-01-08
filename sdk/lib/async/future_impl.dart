// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// part of dart.async;

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
    new Timer(0, (_) {
      // Never complete an error in the same cycle. Otherwise users might
      // not have a chance to register their error-handlers.
      _FutureImpl future = this.future;
      future._setError(new AsyncError(error, stackTrace));
    });
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
  void _sendError(AsyncError error);
}

/** Adapter for a [_FutureImpl] to be a future result listener. */
class _FutureListenerWrapper<T> implements _FutureListener<T> {
  _FutureImpl future;
  _FutureListener _nextListener;
  _FutureListenerWrapper(this.future);
  _sendValue(T value) { future._setValue(value); }
  _sendError(AsyncError error) { future._setError(error); }
}

class _FutureImpl<T> implements Future<T> {
  static const int _INCOMPLETE = 0;
  static const int _VALUE = 1;
  static const int _ERROR = 2;

  /** Whether the future is complete, and as what. */
  int _state = _INCOMPLETE;

  bool get _isComplete => _state != _INCOMPLETE;
  bool get _hasValue => _state == _VALUE;
  bool get _hasError => _state == _ERROR;

  /**
   * Either the result, or a list of listeners until the future completes.
   *
   * The result of the future is either a value or an [AsyncError].
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
    new Timer(0, (_) { _setError(new AsyncError(error, stackTrace)); });
  }

  factory _FutureImpl.wait(Iterable<Future> futures) {
    // TODO(ajohnsen): can we do better wrt the generic type T?
    if (futures.isEmpty) {
      return new Future<List>.immediate(const []);
    }

    Completer completer = new Completer<List>();
    int remaining = futures.length;
    List values = new List.fixedLength(futures.length);

    // As each future completes, put its value into the corresponding
    // position in the list of values.
    int i = 0;
    for (Future future in futures) {
      int pos = i++;
      future.then((Object value) {
        values[pos] = value;
        if (--remaining == 0) {
          completer.complete(values);
        }
      });
      future.catchError((error) {
        completer.completeError(error.error, error.stackTrace);
      });
    }

    return completer.future;
  }

  Future then(f(T value), { onError(AsyncError error) }) {
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

  Future catchError(f(AsyncError asyncError), { bool test(error) }) {
    if (_hasValue) {
      return new _FutureWrapper(this);
    }
    if (!_isComplete) {
      return new _CatchErrorFuture(f, test).._subscribeTo(this);
    } else {
      return _handleError(f, test);
    }
  }

  Future<T> whenComplete(void action()) {
    _WhenFuture<T> whenFuture = new _WhenFuture<T>(action);
    if (!_isComplete) {
      _addListener(whenFuture);
    } else if (_hasValue) {
      new Timer(0, (_) {
        T value = _resultOrListeners;
        whenFuture._sendValue(value);
      });
    } else {
      assert(_hasError);
      new Timer(0, (_) {
        AsyncError error = _resultOrListeners;
        whenFuture._sendError(error);
      });
    }
    return whenFuture;
  }

  Future _handleValue(onValue(var value)) {
    assert(_hasValue);
    _ThenFuture thenFuture = new _ThenFuture(onValue);
    T value = _resultOrListeners;
    new Timer(0, (_) { thenFuture._sendValue(value); });
    return thenFuture;
  }

  Future _handleError(onError(AsyncError error), bool test(error)) {
    assert(_hasError);
    AsyncError error = _resultOrListeners;
    _CatchErrorFuture errorFuture = new _CatchErrorFuture(onError, test);
    new Timer(0, (_) { errorFuture._sendError(error); });
    return errorFuture;
  }

  Stream<T> asStream() => new Stream.fromFuture(this);

  void _setValue(T value) {
    if (_state != _INCOMPLETE) throw new StateError("Future already completed");
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

  void _setError(AsyncError error) {
    if (_isComplete) throw new StateError("Future already completed");
    _FutureListener listeners = _removeListeners();
    _state = _ERROR;
    _resultOrListeners = error;
    if (listeners == null) {
      error.throwDelayed();
      return;
    }
    while (listeners != null) {
      _FutureListener listener = listeners;
      listeners = listener._nextListener;
      listener._nextListener = null;
      listener._sendError(error);
    }
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
      future._setError(_resultOrListeners);
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

  void _sendError(AsyncError error);

  void _subscribeTo(_FutureImpl future) {
    future._addListener(this);
  }

  /**
   * Helper function to hand the result of transforming an incoming event.
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
}

/** The onValue and onError handlers return either a value or a future */
typedef dynamic _FutureOnValue<T>(T value);
typedef dynamic _FutureOnError(AsyncError error);
/** Test used by [Future.catchError] to handle skip some errors. */
typedef bool _FutureErrorTest(var error);
/** Used by [WhenFuture]. */
typedef void _FutureAction();

/** Future returned by [Future.then] with no [:onError:] parameter. */
class _ThenFuture<S, T> extends _TransformFuture<S, T> {
  final _FutureOnValue<S> _onValue;

  _ThenFuture(this._onValue);

  _sendValue(S value) {
    assert(_onValue != null);
    var result;
    try {
      result = _onValue(value);
    } catch (e, s) {
      _setError(new AsyncError(e, s));
      return;
    }
    _setOrChainValue(result);
  }

  void _sendError(AsyncError error) {
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

  _sendError(AsyncError error) {
    assert(_onError != null);
    // if _test is supplied, check if it returns true, otherwise just
    // forward the error unmodified.
    if (_test != null) {
      bool matchesTest;
      try {
        matchesTest = _test(error.error);
      } catch (e, s) {
        _setError(new AsyncError.withCause(e, s, error));
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
      _setError(new AsyncError.withCause(e, s, error));
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

  void _sendError(AsyncError error) {
    assert(_onError != null);
    var result;
    try {
      result = _onError(error);
    } catch (e, s) {
      _setError(new AsyncError.withCause(e, s, error));
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
      _action();
    } catch (e, s) {
      _setError(new AsyncError(e, s));
      return;
    }
    _setValue(value);
  }

  void _sendError(AsyncError error) {
    try {
      _action();
    } catch (e, s) {
      error = new AsyncError.withCause(e, s, error);
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

  Future then(function(T value), { onError(AsyncError error) }) {
    return _future.then(function, onError: onError);
  }

  Future catchError(function(AsyncError error), {bool test(var error)}) {
    return _future.catchError(function, test: test);
  }

  Future whenComplete(void action()) {
    return _future.whenComplete(action);
  }

  Stream<T> asStream() => new Stream.fromFuture(this);
}
