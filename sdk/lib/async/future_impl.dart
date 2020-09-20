// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.async;

/** The onValue and onError handlers return either a value or a future */
typedef FutureOr<T> _FutureOnValue<S, T>(S value);
/** Test used by [Future.catchError] to handle skip some errors. */
typedef bool _FutureErrorTest(Object error);
/** Used by [WhenFuture]. */
typedef dynamic _FutureAction();

abstract class _Completer<T> implements Completer<T> {
  final _Future<T> future = new _Future<T>();

  void complete([FutureOr<T>? value]);

  void completeError(Object error, [StackTrace? stackTrace]) {
    // TODO(40614): Remove once non-nullability is sound.
    ArgumentError.checkNotNull(error, "error");
    if (!future._mayComplete) throw new StateError("Future already completed");
    AsyncError? replacement = Zone.current.errorCallback(error, stackTrace);
    if (replacement != null) {
      error = replacement.error;
      stackTrace = replacement.stackTrace;
    } else {
      stackTrace ??= AsyncError.defaultStackTrace(error);
    }
    if (stackTrace == null) throw "unreachable"; // TODO(40088)
    _completeError(error, stackTrace);
  }

  void _completeError(Object error, StackTrace stackTrace);

  // The future's _isComplete doesn't take into account pending completions.
  // We therefore use _mayComplete.
  bool get isCompleted => !future._mayComplete;
}

class _AsyncCompleter<T> extends _Completer<T> {
  void complete([FutureOr<T>? value]) {
    if (!future._mayComplete) throw new StateError("Future already completed");
    future._asyncComplete(value == null ? value as dynamic : value);
  }

  void _completeError(Object error, StackTrace stackTrace) {
    future._asyncCompleteError(error, stackTrace);
  }
}

class _SyncCompleter<T> extends _Completer<T> {
  void complete([FutureOr<T>? value]) {
    if (!future._mayComplete) throw new StateError("Future already completed");
    future._complete(value == null ? value as dynamic : value);
  }

  void _completeError(Object error, StackTrace stackTrace) {
    future._completeError(error, stackTrace);
  }
}

class _FutureListener<S, T> {
  static const int maskValue = 1;
  static const int maskError = 2;
  static const int maskTestError = 4;
  static const int maskWhencomplete = 8;
  static const int stateChain = 0;
  static const int stateThen = maskValue;
  static const int stateThenOnerror = maskValue | maskError;
  static const int stateCatcherror = maskError;
  static const int stateCatcherrorTest = maskError | maskTestError;
  static const int stateWhencomplete = maskWhencomplete;
  static const int maskType =
      maskValue | maskError | maskTestError | maskWhencomplete;
  static const int stateIsAwait = 16;
  // Listeners on the same future are linked through this link.
  _FutureListener? _nextListener;
  // The future to complete when this listener is activated.
  final _Future<T> result;
  // Which fields means what.
  final int state;
  // Used for then/whenDone callback and error test
  @pragma("vm:entry-point")
  final Function? callback;
  // Used for error callbacks.
  final Function? errorCallback;

  _FutureListener.then(
      this.result, FutureOr<T> Function(S) onValue, Function? errorCallback)
      : callback = onValue,
        errorCallback = errorCallback,
        state = (errorCallback == null) ? stateThen : stateThenOnerror;

  _FutureListener.thenAwait(
      this.result, _FutureOnValue<S, T> onValue, Function errorCallback)
      : callback = onValue,
        errorCallback = errorCallback,
        state = ((errorCallback == null) ? stateThen : stateThenOnerror) |
            stateIsAwait;

  _FutureListener.catchError(this.result, this.errorCallback, this.callback)
      : state = (callback == null) ? stateCatcherror : stateCatcherrorTest;

  _FutureListener.whenComplete(this.result, this.callback)
      : errorCallback = null,
        state = stateWhencomplete;

  _Zone get _zone => result._zone;

  bool get handlesValue => (state & maskValue != 0);
  bool get handlesError => (state & maskError != 0);
  bool get hasErrorTest => (state & maskType == stateCatcherrorTest);
  bool get handlesComplete => (state & maskType == stateWhencomplete);
  bool get isAwait => (state & stateIsAwait != 0);

  FutureOr<T> Function(S) get _onValue {
    assert(handlesValue);
    return callback as dynamic;
  }

  Function? get _onError => errorCallback;

  _FutureErrorTest get _errorTest {
    assert(hasErrorTest);
    return callback as dynamic;
  }

  _FutureAction get _whenCompleteAction {
    assert(handlesComplete);
    return callback as dynamic;
  }

  /// Whether this listener has an error callback.
  ///
  /// This function must only be called if the listener [handlesError].
  bool get hasErrorCallback {
    assert(handlesError);
    return _onError != null;
  }

  FutureOr<T> handleValue(S sourceResult) {
    return _zone.runUnary<FutureOr<T>, S>(_onValue, sourceResult);
  }

  bool matchesErrorTest(AsyncError asyncError) {
    if (!hasErrorTest) return true;
    return _zone.runUnary<bool, Object>(_errorTest, asyncError.error);
  }

  FutureOr<T> handleError(AsyncError asyncError) {
    assert(handlesError && hasErrorCallback);
    var errorCallback = this.errorCallback; // To enable promotion.
    // If the errorCallback returns something which is not a FutureOr<T>,
    // this return statement throws, and the caller handles the error.
    if (errorCallback is dynamic Function(Object, StackTrace)) {
      return _zone.runBinary<dynamic, Object, StackTrace>(
          errorCallback, asyncError.error, asyncError.stackTrace);
    } else {
      return _zone.runUnary<dynamic, Object>(
          errorCallback as dynamic, asyncError.error);
    }
  }

  dynamic handleWhenComplete() {
    assert(!handlesError);
    return _zone.run(_whenCompleteAction);
  }
}

class _Future<T> implements Future<T> {
  /// Initial state, waiting for a result. In this state, the
  /// [resultOrListeners] field holds a single-linked list of
  /// [_FutureListener] listeners.
  static const int _stateIncomplete = 0;

  /// Pending completion. Set when completed using [_asyncComplete] or
  /// [_asyncCompleteError]. It is an error to try to complete it again.
  /// [resultOrListeners] holds listeners.
  static const int _statePendingComplete = 1;

  /// The future has been chained to another future. The result of that
  /// other future becomes the result of this future as well.
  /// [resultOrListeners] contains the source future.
  static const int _stateChained = 2;

  /// The future has been completed with a value result.
  static const int _stateValue = 4;

  /// The future has been completed with an error result.
  static const int _stateError = 8;

  /** Whether the future is complete, and as what. */
  int _state = _stateIncomplete;

  /**
   * Zone that the future was completed from.
   * This is the zone that an error result belongs to.
   *
   * Until the future is completed, the field may hold the zone that
   * listener callbacks used to create this future should be run in.
   */
  final _Zone _zone;

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
   */
  @pragma("vm:entry-point")
  var _resultOrListeners;

  // This constructor is used by async/await.
  _Future() : _zone = Zone._current;

  _Future.immediate(FutureOr<T> result) : _zone = Zone._current {
    _asyncComplete(result);
  }

  /** Creates a future with the value and the specified zone. */
  _Future.zoneValue(T value, this._zone) {
    _setValue(value);
  }

  _Future.immediateError(var error, StackTrace stackTrace)
      : _zone = Zone._current {
    _asyncCompleteError(error, stackTrace);
  }

  /** Creates a future that is already completed with the value. */
  _Future.value(T value) : this.zoneValue(value, Zone._current);

  bool get _mayComplete => _state == _stateIncomplete;
  bool get _isPendingComplete => _state == _statePendingComplete;
  bool get _mayAddListener => _state <= _statePendingComplete;
  bool get _isChained => _state == _stateChained;
  bool get _isComplete => _state >= _stateValue;
  bool get _hasError => _state == _stateError;

  static List<Function>? _continuationFunctions(_Future<Object> future) {
    List<Function>? result = null;
    while (true) {
      if (future._mayAddListener) return result;
      assert(!future._isComplete);
      assert(!future._isChained);
      // So _resultOrListeners contains listeners.
      _FutureListener<Object, Object>? listener = future._resultOrListeners;
      if (listener != null &&
          listener._nextListener == null &&
          listener.isAwait) {
        (result ??= <Function>[]).add(listener.handleValue);
        future = listener.result;
        assert(!future._isComplete);
      } else {
        break;
      }
    }
    return result;
  }

  void _setChained(_Future source) {
    assert(_mayAddListener);
    _state = _stateChained;
    _resultOrListeners = source;
  }

  Future<R> then<R>(FutureOr<R> f(T value), {Function? onError}) {
    Zone currentZone = Zone.current;
    if (!identical(currentZone, _rootZone)) {
      f = currentZone.registerUnaryCallback<FutureOr<R>, T>(f);
      if (onError != null) {
        // In checked mode, this checks that onError is assignable to one of:
        //   dynamic Function(Object)
        //   dynamic Function(Object, StackTrace)
        onError = _registerErrorHandler(onError, currentZone);
      }
    }
    _Future<R> result = new _Future<R>();
    _addListener(new _FutureListener<T, R>.then(result, f, onError));
    return result;
  }

  /// Registers a system created result and error continuation.
  ///
  /// Used by the implementation of `await` to listen to a future.
  /// The system created liseners are not registered in the zone,
  /// and the listener is marked as being from an `await`.
  /// This marker is used in [_continuationFunctions].
  Future<E> _thenAwait<E>(FutureOr<E> f(T value), Function onError) {
    _Future<E> result = new _Future<E>();
    _addListener(new _FutureListener<T, E>.thenAwait(result, f, onError));
    return result;
  }

  Future<T> catchError(Function onError, {bool test(Object error)?}) {
    _Future<T> result = new _Future<T>();
    if (!identical(result._zone, _rootZone)) {
      onError = _registerErrorHandler(onError, result._zone);
      if (test != null) test = result._zone.registerUnaryCallback(test);
    }
    _addListener(new _FutureListener<T, T>.catchError(result, onError, test));
    return result;
  }

  Future<T> whenComplete(dynamic action()) {
    _Future<T> result = new _Future<T>();
    if (!identical(result._zone, _rootZone)) {
      action = result._zone.registerCallback<dynamic>(action);
    }
    _addListener(new _FutureListener<T, T>.whenComplete(result, action));
    return result;
  }

  Stream<T> asStream() => new Stream<T>.fromFuture(this);

  void _setPendingComplete() {
    assert(_mayComplete);
    _state = _statePendingComplete;
  }

  void _clearPendingComplete() {
    assert(_isPendingComplete);
    _state = _stateIncomplete;
  }

  AsyncError get _error {
    assert(_hasError);
    return _resultOrListeners;
  }

  _Future get _chainSource {
    assert(_isChained);
    return _resultOrListeners;
  }

  // This method is used by async/await.
  void _setValue(T value) {
    assert(!_isComplete); // But may have a completion pending.
    _state = _stateValue;
    _resultOrListeners = value;
  }

  void _setErrorObject(AsyncError error) {
    assert(!_isComplete); // But may have a completion pending.
    _state = _stateError;
    _resultOrListeners = error;
  }

  void _setError(Object error, StackTrace stackTrace) {
    _setErrorObject(new AsyncError(error, stackTrace));
  }

  /// Copy the completion result of [source] into this future.
  ///
  /// Used when a chained future notices that its source is completed.
  void _cloneResult(_Future source) {
    assert(!_isComplete);
    assert(source._isComplete);
    _state = source._state;
    _resultOrListeners = source._resultOrListeners;
  }

  void _addListener(_FutureListener listener) {
    assert(listener._nextListener == null);
    if (_mayAddListener) {
      listener._nextListener = _resultOrListeners;
      _resultOrListeners = listener;
    } else {
      if (_isChained) {
        // Delegate listeners to chained source future.
        // If the source is complete, instead copy its values and
        // drop the chaining.
        _Future source = _chainSource;
        if (!source._isComplete) {
          source._addListener(listener);
          return;
        }
        _cloneResult(source);
      }
      assert(_isComplete);
      // Handle late listeners asynchronously.
      _zone.scheduleMicrotask(() {
        _propagateToListeners(this, listener);
      });
    }
  }

  void _prependListeners(_FutureListener? listeners) {
    if (listeners == null) return;
    if (_mayAddListener) {
      _FutureListener? existingListeners = _resultOrListeners;
      _resultOrListeners = listeners;
      if (existingListeners != null) {
        _FutureListener cursor = listeners;
        _FutureListener? next = cursor._nextListener;
        while (next != null) {
          cursor = next;
          next = cursor._nextListener;
        }
        cursor._nextListener = existingListeners;
      }
    } else {
      if (_isChained) {
        // Delegate listeners to chained source future.
        // If the source is complete, instead copy its values and
        // drop the chaining.
        _Future source = _chainSource;
        if (!source._isComplete) {
          source._prependListeners(listeners);
          return;
        }
        _cloneResult(source);
      }
      assert(_isComplete);
      listeners = _reverseListeners(listeners);
      _zone.scheduleMicrotask(() {
        _propagateToListeners(this, listeners);
      });
    }
  }

  _FutureListener? _removeListeners() {
    // Reverse listeners before returning them, so the resulting list is in
    // subscription order.
    assert(!_isComplete);
    _FutureListener? current = _resultOrListeners;
    _resultOrListeners = null;
    return _reverseListeners(current);
  }

  _FutureListener? _reverseListeners(_FutureListener? listeners) {
    _FutureListener? prev = null;
    _FutureListener? current = listeners;
    while (current != null) {
      _FutureListener? next = current._nextListener;
      current._nextListener = prev;
      prev = current;
      current = next;
    }
    return prev;
  }

  // Take the value (when completed) of source and complete target with that
  // value (or error). This function could chain all Futures, but is slower
  // for _Future than _chainCoreFuture, so you must use _chainCoreFuture
  // in that case.
  static void _chainForeignFuture(Future source, _Future target) {
    assert(!target._isComplete);
    assert(source is! _Future);

    // Mark the target as chained (and as such half-completed).
    target._setPendingComplete();
    try {
      source.then((value) {
        assert(target._isPendingComplete);
        // The "value" may be another future if the foreign future
        // implementation is mis-behaving,
        // so use _complete instead of _completeWithValue.
        target._clearPendingComplete(); // Clear this first, it's set again.
        target._complete(value);
      }, onError: (Object error, StackTrace stackTrace) {
        assert(target._isPendingComplete);
        target._completeError(error, stackTrace);
      });
    } catch (e, s) {
      // This only happens if the `then` call threw synchronously when given
      // valid arguments.
      // That requires a non-conforming implementation of the Future interface,
      // which should, hopefully, never happen.
      scheduleMicrotask(() {
        target._completeError(e, s);
      });
    }
  }

  // Take the value (when completed) of source and complete target with that
  // value (or error). This function expects that source is a _Future.
  static void _chainCoreFuture(_Future source, _Future target) {
    assert(target._mayAddListener); // Not completed, not already chained.
    while (source._isChained) {
      source = source._chainSource;
    }
    if (source._isComplete) {
      _FutureListener? listeners = target._removeListeners();
      target._cloneResult(source);
      _propagateToListeners(target, listeners);
    } else {
      _FutureListener? listeners = target._resultOrListeners;
      target._setChained(source);
      source._prependListeners(listeners);
    }
  }

  void _complete(FutureOr<T> value) {
    assert(!_isComplete);
    if (value is Future<T>) {
      if (value is _Future<T>) {
        _chainCoreFuture(value, this);
      } else {
        _chainForeignFuture(value, this);
      }
    } else {
      _FutureListener? listeners = _removeListeners();
      // TODO(40014): Remove cast when type promotion works.
      // This would normally be `as T` but we use `as dynamic` to make the
      // unneeded check be implict to match dart2js unsound optimizations in the
      // user code.
      _setValue(value as dynamic); // Value promoted to T.
      _propagateToListeners(this, listeners);
    }
  }

  void _completeWithValue(T value) {
    assert(!_isComplete);
    assert(value is! Future<T>);

    _FutureListener? listeners = _removeListeners();
    _setValue(value);
    _propagateToListeners(this, listeners);
  }

  void _completeError(Object error, StackTrace stackTrace) {
    assert(!_isComplete);

    _FutureListener? listeners = _removeListeners();
    _setError(error, stackTrace);
    _propagateToListeners(this, listeners);
  }

  void _asyncComplete(FutureOr<T> value) {
    assert(!_isComplete);
    // Two corner cases if the value is a future:
    //   1. the future is already completed and an error.
    //   2. the future is not yet completed but might become an error.
    // The first case means that we must not immediately complete the Future,
    // as our code would immediately start propagating the error without
    // giving the time to install error-handlers.
    // However the second case requires us to deal with the value immediately.
    // Otherwise the value could complete with an error and report an
    // unhandled error, even though we know we are already going to listen to
    // it.

    if (value is Future<T>) {
      _chainFuture(value);
      return;
    }
    // TODO(40014): Remove cast when type promotion works.
    // This would normally be `as T` but we use `as dynamic` to make the
    // unneeded check be implict to match dart2js unsound optimizations in the
    // user code.
    _asyncCompleteWithValue(value as dynamic); // Value promoted to T.
  }

  void _asyncCompleteWithValue(T value) {
    _setPendingComplete();
    _zone.scheduleMicrotask(() {
      _completeWithValue(value);
    });
  }

  void _chainFuture(Future<T> value) {
    if (value is _Future<T>) {
      if (value._hasError) {
        // Delay completion to allow the user to register callbacks.
        _setPendingComplete();
        _zone.scheduleMicrotask(() {
          _chainCoreFuture(value, this);
        });
      } else {
        _chainCoreFuture(value, this);
      }
      return;
    }
    // Just listen on the foreign future. This guarantees an async delay.
    _chainForeignFuture(value, this);
  }

  void _asyncCompleteError(Object error, StackTrace stackTrace) {
    assert(!_isComplete);

    _setPendingComplete();
    _zone.scheduleMicrotask(() {
      _completeError(error, stackTrace);
    });
  }

  /**
   * Propagates the value/error of [source] to its [listeners], executing the
   * listeners' callbacks.
   */
  static void _propagateToListeners(
      _Future source, _FutureListener? listeners) {
    while (true) {
      assert(source._isComplete);
      bool hasError = source._hasError;
      if (listeners == null) {
        if (hasError) {
          AsyncError asyncError = source._error;
          source._zone
              .handleUncaughtError(asyncError.error, asyncError.stackTrace);
        }
        return;
      }
      // Usually futures only have one listener. If they have several, we
      // call handle them separately in recursive calls, continuing
      // here only when there is only one listener left.
      _FutureListener listener = listeners;
      _FutureListener? nextListener = listener._nextListener;
      while (nextListener != null) {
        listener._nextListener = null;
        _propagateToListeners(source, listener);
        listener = nextListener;
        nextListener = listener._nextListener;
      }

      final sourceResult = source._resultOrListeners;
      // Do the actual propagation.
      // Set initial state of listenerHasError and listenerValueOrError. These
      // variables are updated with the outcome of potential callbacks.
      // Non-error results, including futures, are stored in
      // listenerValueOrError and listenerHasError is set to false. Errors
      // are stored in listenerValueOrError as an [AsyncError] and
      // listenerHasError is set to true.
      bool listenerHasError = hasError;
      var listenerValueOrError = sourceResult;

      // Only if we either have an error or callbacks, go into this, somewhat
      // expensive, branch. Here we'll enter/leave the zone. Many futures
      // don't have callbacks, so this is a significant optimization.
      if (hasError || listener.handlesValue || listener.handlesComplete) {
        _Zone zone = listener._zone;
        if (hasError && !source._zone.inSameErrorZone(zone)) {
          // Don't cross zone boundaries with errors.
          AsyncError asyncError = source._error;
          source._zone
              .handleUncaughtError(asyncError.error, asyncError.stackTrace);
          return;
        }

        _Zone? oldZone;
        if (!identical(Zone._current, zone)) {
          // Change zone if it's not current.
          oldZone = Zone._enter(zone);
        }

        // These callbacks are abstracted to isolate the try/catch blocks
        // from the rest of the code to work around a V8 glass jaw.
        void handleWhenCompleteCallback() {
          // The whenComplete-handler is not combined with normal value/error
          // handling. This means at most one handleX method is called per
          // listener.
          assert(!listener.handlesValue);
          assert(!listener.handlesError);
          var completeResult;
          try {
            completeResult = listener.handleWhenComplete();
          } catch (e, s) {
            if (hasError && identical(source._error.error, e)) {
              listenerValueOrError = source._error;
            } else {
              listenerValueOrError = new AsyncError(e, s);
            }
            listenerHasError = true;
            return;
          }
          if (completeResult is _Future && completeResult._isComplete) {
            if (completeResult._hasError) {
              listenerValueOrError = completeResult._error;
              listenerHasError = true;
            }
            // Otherwise use the existing result of source.
            return;
          }
          if (completeResult is Future) {
            // We have to wait for the completeResult future to complete
            // before knowing if it's an error or we should use the result
            // of source.
            var originalSource = source;
            listenerValueOrError = completeResult.then((_) => originalSource);
            listenerHasError = false;
          }
        }

        void handleValueCallback() {
          try {
            listenerValueOrError = listener.handleValue(sourceResult);
          } catch (e, s) {
            listenerValueOrError = new AsyncError(e, s);
            listenerHasError = true;
          }
        }

        void handleError() {
          try {
            AsyncError asyncError = source._error;
            if (listener.matchesErrorTest(asyncError) &&
                listener.hasErrorCallback) {
              listenerValueOrError = listener.handleError(asyncError);
              listenerHasError = false;
            }
          } catch (e, s) {
            if (identical(source._error.error, e)) {
              listenerValueOrError = source._error;
            } else {
              listenerValueOrError = new AsyncError(e, s);
            }
            listenerHasError = true;
          }
        }

        if (listener.handlesComplete) {
          handleWhenCompleteCallback();
        } else if (!hasError) {
          if (listener.handlesValue) {
            handleValueCallback();
          }
        } else {
          if (listener.handlesError) {
            handleError();
          }
        }

        // If we changed zone, oldZone will not be null.
        if (oldZone != null) Zone._leave(oldZone);

        // If the listener's value is a future we need to chain it. Note that
        // this can only happen if there is a callback.
        if (listenerValueOrError is Future) {
          Future chainSource = listenerValueOrError;
          // Shortcut if the chain-source is already completed. Just continue
          // the loop.
          _Future result = listener.result;
          if (chainSource is _Future) {
            if (chainSource._isComplete) {
              listeners = result._removeListeners();
              result._cloneResult(chainSource);
              source = chainSource;
              continue;
            } else {
              _chainCoreFuture(chainSource, result);
            }
          } else {
            _chainForeignFuture(chainSource, result);
          }
          return;
        }
      }
      _Future result = listener.result;
      listeners = result._removeListeners();
      if (!listenerHasError) {
        result._setValue(listenerValueOrError);
      } else {
        AsyncError asyncError = listenerValueOrError;
        result._setErrorObject(asyncError);
      }
      // Prepare for next round.
      source = result;
    }
  }

  @pragma("vm:entry-point")
  Future<T> timeout(Duration timeLimit, {FutureOr<T> onTimeout()?}) {
    if (_isComplete) return new _Future.immediate(this);
    // This is a VM recognised method, and the _future variable is deliberately
    // allocated in a specific slot in the closure context for stack unwinding.
    _Future<T> _future = new _Future<T>();
    Timer timer;
    if (onTimeout == null) {
      timer = new Timer(timeLimit, () {
        _future._completeError(
            new TimeoutException("Future not completed", timeLimit),
            StackTrace.empty);
      });
    } else {
      Zone zone = Zone.current;
      FutureOr<T> Function() onTimeoutHandler =
          zone.registerCallback(onTimeout);

      timer = new Timer(timeLimit, () {
        try {
          _future._complete(zone.run(onTimeoutHandler));
        } catch (e, s) {
          _future._completeError(e, s);
        }
      });
    }
    this.then((T v) {
      if (timer.isActive) {
        timer.cancel();
        _future._completeWithValue(v);
      }
    }, onError: (Object e, StackTrace s) {
      if (timer.isActive) {
        timer.cancel();
        _future._completeError(e, s);
      }
    });
    return _future;
  }
}

/// Registers errorHandler in zone if it has the correct type.
///
/// Checks that the function accepts either an [Object] and a [StackTrace]
/// or just one [Object]. Does not check the return type.
/// The actually returned value must be `FutureOr<R>` where `R` is the
/// value type of the future that the call will complete (either returned
/// by [Future.then] or [Future.catchError]). We check the returned value
/// dynamically because the functions are passed as arguments in positions
/// without inference, so a function expression won't infer the return type.
///
/// Throws if the type is not valid.
Function _registerErrorHandler(Function errorHandler, Zone zone) {
  if (errorHandler is dynamic Function(Object, StackTrace)) {
    return zone
        .registerBinaryCallback<dynamic, Object, StackTrace>(errorHandler);
  }
  if (errorHandler is dynamic Function(Object)) {
    return zone.registerUnaryCallback<dynamic, Object>(errorHandler);
  }
  throw new ArgumentError.value(
      errorHandler,
      "onError",
      "Error handler must accept one Object or one Object and a StackTrace"
          " as arguments, and return a a valid result");
}
