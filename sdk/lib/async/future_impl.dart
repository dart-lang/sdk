// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.async;

/** The onValue and onError handlers return either a value or a future */
typedef dynamic _FutureOnValue<T>(T value);
/** Test used by [Future.catchError] to handle skip some errors. */
typedef bool _FutureErrorTest(var error);
/** Used by [WhenFuture]. */
typedef _FutureAction();

abstract class _Completer<T> implements Completer<T> {
  final _Future<T> future = new _Future<T>();

  void complete([value]);

  void completeError(Object error, [StackTrace stackTrace]) {
    error = _nonNullError(error);
    if (!future._mayComplete) throw new StateError("Future already completed");
    AsyncError replacement = Zone.current.errorCallback(error, stackTrace);
    if (replacement != null) {
      error = _nonNullError(replacement.error);
      stackTrace = replacement.stackTrace;
    }
    _completeError(error, stackTrace);
  }

  void _completeError(Object error, StackTrace stackTrace);

  // The future's _isComplete doesn't take into account pending completions.
  // We therefore use _mayComplete.
  bool get isCompleted => !future._mayComplete;
}

class _AsyncCompleter<T> extends _Completer<T> {

  void complete([value]) {
    if (!future._mayComplete) throw new StateError("Future already completed");
    future._asyncComplete(value);
  }

  void _completeError(Object error, StackTrace stackTrace) {
    future._asyncCompleteError(error, stackTrace);
  }
}

class _SyncCompleter<T> extends _Completer<T> {
  void complete([value]) {
    if (!future._mayComplete) throw new StateError("Future already completed");
    future._complete(value);
  }

  void _completeError(Object error, StackTrace stackTrace) {
    future._completeError(error, stackTrace);
  }
}

class _Future<T> implements Future<T> {
  // State of the future. The state determines the interpretation of the
  // [resultOrListeners] field.
  // TODO(lrn): rename field since it can also contain a chained future.

  /// Initial state, waiting for a result. In this state, the
  /// [resultOrListeners] field holds a single-linked list of
  /// [FutureListener] listeners.
  static const int _INCOMPLETE = 0;
  /// Pending completion. Set when completed using [_asyncComplete] or
  /// [_asyncCompleteError]. It is an error to try to complete it again.
  static const int _PENDING_COMPLETE = 1;
  /// The future has been chained to another future. The result of that
  /// other future becomes the result of this future as well.
  /// In this state, no callback should be executed anymore.
  // TODO(floitsch): we don't really need a special "_CHAINED" state. We could
  // just use the PENDING_COMPLETE state instead.
  static const int _CHAINED = 2;
  /// The future has been completed with a value result.
  static const int _VALUE = 4;
  /// The future has been completed with an error result.
  static const int _ERROR = 8;

  /** Whether the future is complete, and as what. */
  int _state = _INCOMPLETE;

  final Zone _zone;

  bool get _mayComplete => _state == _INCOMPLETE;
  bool get _isChained => _state == _CHAINED;
  bool get _isComplete => _state >= _VALUE;
  bool get _hasValue => _state == _VALUE;
  bool get _hasError => _state == _ERROR;

  set _isChained(bool value) {
    if (value) {
      assert(!_isComplete);
      _state = _CHAINED;
    } else {
      assert(_isChained);
      _state = _INCOMPLETE;
    }
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

  /**
   * A [_Future] implements a linked list. If a future has more than one
   * listener the [_nextListener] field of the first listener points to the
   * remaining listeners.
   */
  // TODO(floitsch): since single listeners are the common case we should
  // use a bit to indicate that the _resultOrListeners contains a container.
  _Future _nextListener;

  // TODO(floitsch): we only need two closure fields to store the callbacks.
  // If we store the type of a closure in the state field (where there are
  // still bits left), we can just store two closures instead of using 4
  // fields of which 2 are always null.
  _FutureOnValue _onValueCallback;
  _FutureErrorTest _errorTestCallback;
  Function _onErrorCallback;
  _FutureAction _whenCompleteActionCallback;

  _FutureOnValue get _onValue => _isChained ? null : _onValueCallback;
  _FutureErrorTest get _errorTest => _isChained ? null : _errorTestCallback;
  Function get _onError => _isChained ? null : _onErrorCallback;
  _FutureAction get _whenCompleteAction
      => _isChained ? null : _whenCompleteActionCallback;

  _Future()
      : _zone = Zone.current,
        _onValueCallback = null, _errorTestCallback = null,
        _onErrorCallback = null, _whenCompleteActionCallback = null;

  /// Valid types for value: `T` or `Future<T>`.
  _Future.immediate(value)
        : _zone = Zone.current,
          _onValueCallback = null, _errorTestCallback = null,
          _onErrorCallback = null, _whenCompleteActionCallback = null {
    _asyncComplete(value);
  }

  _Future.immediateError(var error, [StackTrace stackTrace])
      : _zone = Zone.current,
        _onValueCallback = null, _errorTestCallback = null,
        _onErrorCallback = null, _whenCompleteActionCallback = null {
    _asyncCompleteError(error, stackTrace);
  }

  _Future._then(onValueCallback(value), Function onErrorCallback)
      : _zone = Zone.current,
        _onValueCallback = Zone.current.registerUnaryCallback(onValueCallback),
        _onErrorCallback = _registerErrorHandler(onErrorCallback, Zone.current),
        _errorTestCallback = null,
        _whenCompleteActionCallback = null;

  _Future._catchError(Function onErrorCallback, bool errorTestCallback(e))
    : _zone = Zone.current,
      _onErrorCallback = _registerErrorHandler(onErrorCallback, Zone.current),
      _errorTestCallback =
          Zone.current.registerUnaryCallback(errorTestCallback),
      _onValueCallback = null,
      _whenCompleteActionCallback = null;

  _Future._whenComplete(whenCompleteActionCallback())
      : _zone = Zone.current,
        _whenCompleteActionCallback =
            Zone.current.registerCallback(whenCompleteActionCallback),
        _onValueCallback = null,
        _errorTestCallback = null,
        _onErrorCallback = null;

  Future then(f(T value), { Function onError }) {
    _Future result;
    result = new _Future._then(f, onError);
    _addListener(result);
    return result;
  }

  Future catchError(Function onError, { bool test(error) }) {
    _Future result = new _Future._catchError(onError, test);
    _addListener(result);
    return result;
  }

  Future<T> whenComplete(action()) {
    _Future result = new _Future<T>._whenComplete(action);
    _addListener(result);
    return result;
  }

  Stream<T> asStream() => new Stream.fromFuture(this);

  void _markPendingCompletion() {
    if (!_mayComplete) throw new StateError("Future already completed");
    _state = _PENDING_COMPLETE;
  }

  T get _value {
    assert(_isComplete && _hasValue);
    return _resultOrListeners;
  }

  AsyncError get _error {
    assert(_isComplete && _hasError);
    return _resultOrListeners;
  }

  void _setValue(T value) {
    assert(!_isComplete);  // But may have a completion pending.
    _state = _VALUE;
    _resultOrListeners = value;
  }

  void _setError(Object error, StackTrace stackTrace) {
    assert(!_isComplete);  // But may have a completion pending.
    _state = _ERROR;
    _resultOrListeners = new AsyncError(error, stackTrace);
  }

  void _addListener(_Future listener) {
    assert(listener._nextListener == null);
    if (_isComplete) {
      // Handle late listeners asynchronously.
      _zone.scheduleMicrotask(() {
        _propagateToListeners(this, listener);
      });
    } else {
      listener._nextListener = _resultOrListeners;
      _resultOrListeners = listener;
    }
  }

  _Future _removeListeners() {
    // Reverse listeners before returning them, so the resulting list is in
    // subscription order.
    assert(!_isComplete);
    _Future current = _resultOrListeners;
    _resultOrListeners = null;
    _Future prev = null;
    while (current != null) {
      _Future next = current._nextListener;
      current._nextListener = prev;
      prev = current;
      current = next;
    }
    return prev;
  }

  // Take the value (when completed) of source and complete target with that
  // value (or error). This function can chain all Futures, but is slower
  // for _Future than _chainCoreFuture - Use _chainCoreFuture in that case.
  static void _chainForeignFuture(Future source, _Future target) {
    assert(!target._isComplete);
    assert(source is! _Future);

    // Mark the target as chained (and as such half-completed).
    target._isChained = true;
    source.then((value) {
        assert(target._isChained);
        target._completeWithValue(value);
      },
      // TODO(floitsch): eventually we would like to make this non-optional
      // and dependent on the listeners of the target future. If none of
      // the target future's listeners want to have the stack trace we don't
      // need a trace.
      onError: (error, [stackTrace]) {
        assert(target._isChained);
        target._completeError(error, stackTrace);
      });
  }

  // Take the value (when completed) of source and complete target with that
  // value (or error). This function expects that source is a _Future.
  static void _chainCoreFuture(_Future source, _Future target) {
    assert(!target._isComplete);
    assert(source is _Future);

    // Mark the target as chained (and as such half-completed).
    target._isChained = true;
    _Future internalFuture = source;
    if (internalFuture._isComplete) {
      _propagateToListeners(internalFuture, target);
    } else {
      internalFuture._addListener(target);
    }
  }

  void _complete(value) {
    assert(!_isComplete);
    assert(_onValue == null);
    assert(_onError == null);
    assert(_whenCompleteAction == null);
    assert(_errorTest == null);

    if (value is Future) {
      if (value is _Future) {
        _chainCoreFuture(value, this);
      } else {
        _chainForeignFuture(value, this);
      }
    } else {
      _Future listeners = _removeListeners();
      _setValue(value);
      _propagateToListeners(this, listeners);
    }
  }

  void _completeWithValue(value) {
    assert(!_isComplete);
    assert(_onValue == null);
    assert(_onError == null);
    assert(_whenCompleteAction == null);
    assert(_errorTest == null);
    assert(value is! Future);

    _Future listeners = _removeListeners();
    _setValue(value);
    _propagateToListeners(this, listeners);
  }

  void _completeError(error, [StackTrace stackTrace]) {
    assert(!_isComplete);
    assert(_onValue == null);
    assert(_onError == null);
    assert(_whenCompleteAction == null);
    assert(_errorTest == null);

    _Future listeners = _removeListeners();
    _setError(error, stackTrace);
    _propagateToListeners(this, listeners);
  }

  void _asyncComplete(value) {
    assert(!_isComplete);
    assert(_onValue == null);
    assert(_onError == null);
    assert(_whenCompleteAction == null);
    assert(_errorTest == null);
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

    if (value == null) {
      // No checks for `null`.
    } else if (value is Future) {
      // Assign to typed variables so we get earlier checks in checked mode.
      Future<T> typedFuture = value;
      if (typedFuture is _Future) {
        _Future<T> coreFuture = typedFuture;
        if (coreFuture._isComplete && coreFuture._hasError) {
          // Case 1 from above. Delay completion to enable the user to register
          // callbacks.
          _markPendingCompletion();
          _zone.scheduleMicrotask(() {
            _chainCoreFuture(coreFuture, this);
          });
        } else {
          _chainCoreFuture(coreFuture, this);
        }
      } else {
        // Case 2 from above. Chain the future immidiately.
        // Note that we are still completing asynchronously (through
        // _chainForeignFuture)..
        _chainForeignFuture(typedFuture, this);
      }
      return;
    } else {
      T typedValue = value;
    }

    _markPendingCompletion();
    _zone.scheduleMicrotask(() {
      _completeWithValue(value);
    });
  }

  void _asyncCompleteError(error, StackTrace stackTrace) {
    assert(!_isComplete);
    assert(_onValue == null);
    assert(_onError == null);
    assert(_whenCompleteAction == null);
    assert(_errorTest == null);

    _markPendingCompletion();
    _zone.scheduleMicrotask(() {
      _completeError(error, stackTrace);
    });
  }

  /**
   * Propagates the value/error of [source] to its [listeners].
   *
   * Unlinks all listeners and propagates the source to each listener
   * separately.
   */
  static void _propagateMultipleListeners(_Future source, _Future listeners) {
    assert(listeners != null);
    assert(listeners._nextListener != null);
    do {
      _Future listener = listeners;
      listeners = listener._nextListener;
      listener._nextListener = null;
      _propagateToListeners(source, listener);
    } while (listeners != null);
  }

  /**
   * Propagates the value/error of [source] to its [listeners], executing the
   * listeners' callbacks.
   *
   * If [runCallback] is true (which should be the default) it executes
   * the registered action of listeners. If it is `false` then the callback is
   * skipped. This is used to complete futures with chained futures.
   */
  static void _propagateToListeners(_Future source, _Future listeners) {
    while (true) {
      if (!source._isComplete) return;  // Chained future.
      bool hasError = source._hasError;
      if (hasError && listeners == null) {
        AsyncError asyncError = source._error;
        source._zone.handleUncaughtError(
            asyncError.error, asyncError.stackTrace);
        return;
      }
      if (listeners == null) return;
      _Future listener = listeners;
      if (listener._nextListener != null) {
        // Usually futures only have one listener. If they have several, we
        // handle them specially.
        _propagateMultipleListeners(source, listeners);
        return;
      }
      // Do the actual propagation.
      // Set initial state of listenerHasValue and listenerValueOrError. These
      // variables are updated, with the outcome of potential callbacks.
      bool listenerHasValue = true;
      final sourceValue = source._hasValue ? source._value : null;
      var listenerValueOrError = sourceValue;
      // Set to true if a whenComplete needs to wait for a future.
      // The whenComplete action will resume the propagation by itself.
      bool isPropagationAborted = false;
      // TODO(floitsch): mark the listener as pending completion. Currently
      // we can't do this, since the markPendingCompletion verifies that
      // the future is not already marked (or chained).
      // Only if we either have an error or callbacks, go into this, somewhat
      // expensive, branch. Here we'll enter/leave the zone. Many futures
      // doesn't have callbacks, so this is a significant optimization.
      if (hasError ||
          listener._onValue != null ||
          listener._whenCompleteAction != null) {
        Zone zone = listener._zone;
        if (hasError && !source._zone.inSameErrorZone(zone)) {
          // Don't cross zone boundaries with errors.
          AsyncError asyncError = source._error;
          source._zone.handleUncaughtError(
              asyncError.error, asyncError.stackTrace);
          return;
        }

        Zone oldZone;
        if (!identical(Zone.current, zone)) {
          // Change zone if it's not current.
          oldZone = Zone._enter(zone);
        }

        bool handleValueCallback() {
          try {
            listenerValueOrError = zone.runUnary(listener._onValue,
                                                 sourceValue);
            return true;
          } catch (e, s) {
            listenerValueOrError = new AsyncError(e, s);
            return false;
          }
        }

        void handleError() {
          AsyncError asyncError = source._error;
          _FutureErrorTest test = listener._errorTest;
          bool matchesTest = true;
          if (test != null) {
            try {
              matchesTest = zone.runUnary(test, asyncError.error);
            } catch (e, s) {
              // TODO(ajohnsen): Should we suport rethrow for test throws?
              listenerValueOrError = identical(asyncError.error, e) ?
                  asyncError : new AsyncError(e, s);
              listenerHasValue = false;
              return;
            }
          }
          Function errorCallback = listener._onError;
          if (matchesTest && errorCallback != null) {
            try {
              if (errorCallback is ZoneBinaryCallback) {
                listenerValueOrError = zone.runBinary(errorCallback,
                                                      asyncError.error,
                                                      asyncError.stackTrace);
              } else {
                listenerValueOrError = zone.runUnary(errorCallback,
                                                     asyncError.error);
              }
            } catch (e, s) {
              listenerValueOrError = identical(asyncError.error, e) ?
                  asyncError : new AsyncError(e, s);
              listenerHasValue = false;
              return;
            }
            listenerHasValue = true;
          } else {
            // Copy over the error from the source.
            listenerValueOrError = asyncError;
            listenerHasValue = false;
          }
        }

        void handleWhenCompleteCallback() {
          var completeResult;
          try {
            completeResult = zone.run(listener._whenCompleteAction);
          } catch (e, s) {
            if (hasError && identical(source._error.error, e)) {
              listenerValueOrError = source._error;
            } else {
              listenerValueOrError = new AsyncError(e, s);
            }
            listenerHasValue = false;
          }
          if (completeResult is Future) {
            listener._isChained = true;
            isPropagationAborted = true;
            completeResult.then((ignored) {
              // Try again. Since the future is marked as chained it won't run
              // the whenComplete again.
              _propagateToListeners(source, listener);
            }, onError: (error, [stackTrace]) {
              // When there is an error, we have to make the error the new
              // result of the current listener.
              if (completeResult is! _Future) {
                // This should be a rare case.
                completeResult = new _Future();
                completeResult._setError(error, stackTrace);
              }
              _propagateToListeners(completeResult, listener);
            });
          }
        }

        if (!hasError) {
          if (listener._onValue != null) {
            listenerHasValue = handleValueCallback();
          }
        } else {
          handleError();
        }
        if (listener._whenCompleteAction != null) {
          handleWhenCompleteCallback();
        }
        // If we changed zone, oldZone will not be null.
        if (oldZone != null) Zone._leave(oldZone);
        listener._onValueCallback = null;
        listener._errorTestCallback = null;
        listener._onErrorCallback = null;
        listener._whenCompleteActionCallback = null;

        if (isPropagationAborted) return;
        // If the listener's value is a future we need to chain it. Note that
        // this can only happen if there is a callback. Since 'is' checks
        // can be expensive, we're trying to avoid it.
        if (listenerHasValue &&
            !identical(sourceValue, listenerValueOrError) &&
            listenerValueOrError is Future) {
          Future chainSource = listenerValueOrError;
          // Shortcut if the chain-source is already completed. Just continue
          // the loop.
          if (chainSource is _Future) {
            if (chainSource._isComplete) {
              // propagate the value (simulating a tail call).
              listener._isChained = true;
              source = chainSource;
              listeners = listener;
              continue;
            } else {
              _chainCoreFuture(chainSource, listener);
            }
          } else {
            _chainForeignFuture(chainSource, listener);
          }
          return;
        }
      }
      if (listenerHasValue) {
        listeners = listener._removeListeners();
        listener._setValue(listenerValueOrError);
      } else {
        listeners = listener._removeListeners();
        AsyncError asyncError = listenerValueOrError;
        listener._setError(asyncError.error, asyncError.stackTrace);
      }
      // Prepare for next round.
      source = listener;
    }
  }

  Future timeout(Duration timeLimit, {onTimeout()}) {
    if (_isComplete) return new _Future.immediate(this);
    _Future result = new _Future();
    Timer timer;
    if (onTimeout == null) {
      timer = new Timer(timeLimit, () {
        result._completeError(new TimeoutException("Future not completed",
                                                   timeLimit));
      });
    } else {
      Zone zone = Zone.current;
      onTimeout = zone.registerCallback(onTimeout);
      timer = new Timer(timeLimit, () {
        try {
          result._complete(zone.run(onTimeout));
        } catch (e, s) {
          result._completeError(e, s);
        }
      });
    }
    this.then((T v) {
      if (timer.isActive) {
        timer.cancel();
        result._completeWithValue(v);
      }
    }, onError: (e, s) {
      if (timer.isActive) {
        timer.cancel();
        result._completeError(e, s);
      }
    });
    return result;
  }
}
