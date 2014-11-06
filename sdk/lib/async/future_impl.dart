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

const bool _GUARDED = true;
const bool _UNGUARDED = false;

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

class _FutureListener {
  static const int MASK_VALUE = 1;
  static const int MASK_ERROR = 2;
  static const int MASK_TEST_ERROR = 4;
  static const int MASK_WHENCOMPLETE = 8;
  static const int STATE_CHAIN = 0;
  static const int STATE_THEN = MASK_VALUE;
  static const int STATE_THEN_ONERROR = MASK_VALUE | MASK_ERROR;
  static const int STATE_CATCHERROR = MASK_ERROR;
  static const int STATE_CATCHERROR_TEST = MASK_ERROR | MASK_TEST_ERROR;
  static const int STATE_WHENCOMPLETE = MASK_WHENCOMPLETE;
  // Listeners on the same future are linked through this link.
  _FutureListener _nextListener = null;
  // The future to complete when this listener is activated.
  final _Future result;
  // Which fields means what.
  final int state;
  // Used for then/whenDone callback and error test
  final Function callback;
  // Used for error callbacks.
  final Function errorCallback;

  _FutureListener.then(this.result,
                       _FutureOnValue onValue, Function errorCallback)
      : callback = onValue,
        errorCallback = errorCallback,
        state = (errorCallback == null) ? STATE_THEN : STATE_THEN_ONERROR;

  _FutureListener.catchError(this.result,
                             this.errorCallback, _FutureErrorTest test)
      : callback = test,
        state = (test == null) ? STATE_CATCHERROR : STATE_CATCHERROR_TEST;

  _FutureListener.whenComplete(this.result, _FutureAction onComplete)
      : callback = onComplete,
        errorCallback = null,
        state = STATE_WHENCOMPLETE;

  _FutureListener.chain(this.result)
      : callback = null,
        errorCallback = null,
        state = STATE_CHAIN;

  Zone get _zone => result._zone;

  bool get handlesValue => (state & MASK_VALUE != 0);
  bool get handlesError => (state & MASK_ERROR != 0);
  bool get hasErrorTest => (state == STATE_CATCHERROR_TEST);
  bool get handlesComplete => (state == STATE_WHENCOMPLETE);

  _FutureOnValue get _onValue {
    assert(handlesValue);
    return callback;
  }
  Function get _onError => errorCallback;
  _FutureErrorTest get _errorTest {
    assert(hasErrorTest);
    return callback;
  }
  _FutureAction get _whenCompleteAction {
    assert(handlesComplete);
    return callback;
  }
}

class _Future<T> implements Future<T> {
  /// Initial state, waiting for a result. In this state, the
  /// [resultOrListeners] field holds a single-linked list of
  /// [_FutureListener] listeners.
  static const int _INCOMPLETE = 0;
  /// Pending completion. Set when completed using [_asyncComplete] or
  /// [_asyncCompleteError]. It is an error to try to complete it again.
  /// [resultOrListeners] holds listeners.
  static const int _PENDING_COMPLETE = 1;
  /// The future has been chained to another future. The result of that
  /// other future becomes the result of this future as well.
  // TODO(floitsch): we don't really need a special "_CHAINED" state. We could
  // just use the PENDING_COMPLETE state instead.
  static const int _CHAINED = 2;
  /// The future has been completed with a value result.
  static const int _VALUE = 4;
  /// The future has been completed with an error result.
  static const int _ERROR = 8;

  /** Whether the future is complete, and as what. */
  int _state = _INCOMPLETE;

  /**
   * Zone that the future was completed from.
   * This is the zone that an error result belongs to.
   *
   * Until the future is completed, the field may hold the zone that
   * listener callbacks used to create this future should be run in.
   */
  final Zone _zone = Zone.current;

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
   * The cases are disjoint - incomplete and unchained ([_INCOMPLETE]),
   * incomplete and chained ([_CHAINED]), or completed with value or error
   * ([_VALUE] or [_ERROR]) - so the field only needs to hold
   * one value at a time.
   */
  var _resultOrListeners;

  _Future();

  /// Valid types for value: `T` or `Future<T>`.
  _Future.immediate(value) {
    _asyncComplete(value);
  }

  _Future.immediateError(var error, [StackTrace stackTrace]) {
    _asyncCompleteError(error, stackTrace);
  }

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

  Future then(f(T value), { Function onError }) {
    _Future result = new _Future();
    if (!identical(result._zone, _ROOT_ZONE)) {
      f = result._zone.registerUnaryCallback(f);
      if (onError != null) {
        onError = _registerErrorHandler(onError, result._zone);
      }
    }
    _addListener(new _FutureListener.then(result, f, onError));
    return result;
  }

  Future catchError(Function onError, { bool test(error) }) {
    _Future result = new _Future();
    if (!identical(result._zone, _ROOT_ZONE)) {
      onError = _registerErrorHandler(onError, result._zone);
      if (test != null) test = result._zone.registerUnaryCallback(test);
    }
    _addListener(new _FutureListener.catchError(result, onError, test));
    return result;
  }

  Future<T> whenComplete(action()) {
    _Future result = new _Future<T>();
    if (!identical(result._zone, _ROOT_ZONE)) {
      action = result._zone.registerCallback(action);
    }
    _addListener(new _FutureListener.whenComplete(result, action));
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

  void _setErrorObject(AsyncError error) {
    assert(!_isComplete);  // But may have a completion pending.
    _state = _ERROR;
    _resultOrListeners = error;
  }

  void _setError(Object error, StackTrace stackTrace) {
    _setErrorObject(new AsyncError(error, stackTrace));
  }

  void _addListener(_FutureListener listener) {
    assert(listener._nextListener == null);
    if (_isComplete) {
      // Handle late listeners asynchronously.
      _zone.scheduleMicrotask(() {
        _propagateToFutures(this, listener, _UNGUARDED);
      });
    } else {
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
    _FutureListener listener = new _FutureListener.chain(target);
    if (source._isComplete) {
      _propagateToFutures(source, listener, _GUARDED);
    } else {
      source._addListener(listener);
    }
  }

  void _complete(value) {
    assert(!_isComplete);
    if (value is Future) {
      if (value is _Future) {
        _chainCoreFuture(value, this);
      } else {
        _chainForeignFuture(value, this);
      }
    } else {
      _FutureListener listeners = _removeListeners();
      _setValue(value);
      _propagateToFutures(this, listeners, _GUARDED);
    }
  }

  void _completeWithValue(value) {
    assert(!_isComplete);
    assert(value is! Future);

    _FutureListener listeners = _removeListeners();
    _setValue(value);
    _propagateToFutures(this, listeners, _GUARDED);
  }

  void _completeError(error, [StackTrace stackTrace]) {
    assert(!_isComplete);

    _FutureListener listeners = _removeListeners();
    _setError(error, stackTrace);
    _propagateToFutures(this, listeners, _GUARDED);
  }

  void _asyncComplete(value) {
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

    _markPendingCompletion();
    _zone.scheduleMicrotask(() {
      _completeError(error, stackTrace);
    });
  }

  /**
   * Stack implemented by linked list of [_PendingFutureListeners].
   *
   * Each `_PendingFutureListeners` have on source future and one or more
   * listeners on that future (linked internally through
   * [_FutureListener._nextListener]).
   *
   * While propagating future results to listeners, pending listeners are
   * stored on this stack.
   */
  static _PendingFutureListeners _pendingFutureListeners = null;

  /**
   * Handle an uncaught async error.
   *
   * If the [guarded] flag is `true`, or the future's zone has an error
   * handler, the uncaught error is passed to the zone's error handler.
   * Otherwise, the uncaught error is thrown immediately, and is expected
   * to propagate to the event loop. (If it can't propagate to the event
   * loop, `guarded` should be true).
   */
  static void _throwUncaughtError(_Future source, bool guarded) {
    assert(source._hasError);
    AsyncError asyncError = source._error;
    Zone zone = source._zone;
    if (guarded || !identical(zone.errorZone, _ROOT_ZONE)) {
      zone.handleUncaughtError(asyncError.error, asyncError.stackTrace);
      if (_pendingFutureListeners != null) {
        _schedulePriorityAsyncCallback(_propagateToFutures);
      }
      return;
    }
    if (_pendingFutureListeners != null) {
      _schedulePriorityAsyncCallback(_propagateToFutures);
    }
    throw new _UncaughtAsyncError(asyncError.error, asyncError.stackTrace);
  }

  /**
   * Propagates the value/error of [source] to its [listeners], executing the
   * listeners' callbacks.
   *
   * The [guarded] flag should be set when the function isn't being called in
   * tail position of an event, or if simply throwing an uncaught error is
   * otherwise not acceptable.
   *
   * Parameters are optional to allow using [_propagateToFutures] directly
   * as a scheduled function. In that case, it takes its sources from
   * [_pendingFutureListeners].
   */
  static void _propagateToFutures([_Future source,
                                   _FutureListener listeners,
                                   bool guarded = _UNGUARDED]) {
    while (true) {
      if (source == null) {
        // Pop source and listeners from _pendingFutureListeners.
        // This always sets `listeners` to be a single listener.
        if (_pendingFutureListeners == null) return;
        _PendingFutureListeners pending = _pendingFutureListeners;
        // Read top-most source and listener.
        source = pending.source;
        listeners = pending.listeners;
        // Remove the top-most listener. If it's the last listener for
        // source, go to the next _PendingFutureListeners block.
        if (listeners != null && listeners._nextListener != null) {
          pending.listeners = listeners._nextListener;
          listeners._nextListener = null;
        } else {
          _pendingFutureListeners = pending.next;
        }
      } else {
        // Check if there are zero listeners, or more than one listener.
        assert(source._isComplete);
        if (listeners == null) {
          // If zero listeners, and source has an error, consider the error
          // uncaught.
          if (source._hasError) {
            _throwUncaughtError(source, guarded);
            return;
          }
          if (_pendingFutureListeners == null) return;
          source = null;
          continue;
        } else if (listeners._nextListener != null) {
          // Usually futures only have one listener.
          // If they have several, we put the rest on the pending listener
          // stack and handle them later.
          _pendingFutureListeners =
              new _PendingFutureListeners(source, listeners._nextListener,
                                          _pendingFutureListeners);
          listeners._nextListener = null;
        }
      }
      assert(source != null);
      assert(listeners != null);
      assert(listeners._nextListener == null);
      _FutureListener listener = listeners;

      bool hasError = source._hasError;
      // Do the actual propagation.
      // Set initial state of listenerHasError and listenerValueOrError. These
      // variables are updated, with the outcome of potential callbacks.
      bool listenerHasError = hasError;
      final sourceValue = hasError ? source._error : source._value;
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
      if (hasError || (listener.handlesValue || listener.handlesComplete)) {
        Zone zone = listener._zone;

        void handleError() {
          assert(listener.handlesError);
          AsyncError asyncError = source._error;
          bool matchesTest = true;
          if (listener.hasErrorTest) {
            _FutureErrorTest test = listener._errorTest;
            try {
              matchesTest = zone.runUnary(test, asyncError.error);
            } catch (e, s) {
              listenerValueOrError = identical(asyncError.error, e) ?
                  asyncError : new AsyncError(e, s);
              listenerHasError = true;
              return;
            }
          }
          if (matchesTest) {
            Function errorCallback = listener._onError;
            assert(errorCallback != null);
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
              listenerHasError = true;
              return;
            }
            listenerHasError = false;
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
            listenerHasError = true;
            return;
          }
          if (completeResult is Future) {
            _Future result = listener.result;
            result._isChained = true;
            isPropagationAborted = true;
            final _Future originalSource = source;
            completeResult.then((ignored) {
              _propagateToFutures(originalSource,
                                  new _FutureListener.chain(result),
                                  _UNGUARDED);
            }, onError: (error, [stackTrace]) {
              // When there is an error, we have to make the error the new
              // result of the current listener.
              if (completeResult is! _Future) {
                // This should be a rare case.
                completeResult = new _Future();
                completeResult._setError(error, stackTrace);
              }
              _propagateToFutures(completeResult,
                                  new _FutureListener.chain(result),
                                  _UNGUARDED);
            });
          }
        }

        Zone oldZone = Zone._enter(zone);

        if (!hasError) {
          if (listener.handlesValue) {
            // Run try/catch in separate function to help compilers.
            () {
              try {
                listenerValueOrError = zone.runUnary(listener._onValue,
                                                     sourceValue);
                listenerHasError = false;
              } catch (e, s) {
                listenerValueOrError = new AsyncError(e, s);
                listenerHasError = true;
              }
            }();
            assert(!listener.handlesComplete);
          } else if (listener.handlesComplete) {
            // Complete-listeners are distinct from value/error handlers,
            // so no need to check for a complete handler if it is an error
            // handler.
            handleWhenCompleteCallback();
          }
        } else {
          if (!source._zone.inSameErrorZone(zone)) {
            // Don't cross zone boundaries with errors.
            zone = Zone._leave(oldZone);
            _throwUncaughtError(source, guarded);
            return;
          }
          if (listener.handlesError) {
            handleError();
            assert(!listener.handlesComplete);
          } else if (listener.handlesComplete) {
            handleWhenCompleteCallback();
          }
        }

        Zone._leave(oldZone);

        if (isPropagationAborted) {
          // Don't use the value in listenerValueOrError - the whenComplete
          // handler is handling that result.
          if (_pendingFutureListeners == null) return;
          source = null;
          continue;
        }
        // If the listener's value is a future we need to chain it. Note that
        // this can only happen if there is a callback. Since 'is' checks
        // can be expensive, we're trying to avoid it.
        if (!listenerHasError &&
            !identical(sourceValue, listenerValueOrError) &&
            listenerValueOrError is Future) {
          Future chainSource = listenerValueOrError;
          // Shortcut if the chain-source is already completed. Just continue
          // the loop.
          _Future result = listener.result;
          if (chainSource is _Future) {
            if (chainSource._isComplete) {
              // Propagate the value (simulating a tail call).
              result._isChained = true;
              source = chainSource;
              listeners = new _FutureListener.chain(result);
              continue;
            } else {
              _chainCoreFuture(chainSource, result);
            }
          } else {
            _chainForeignFuture(chainSource, result);
          }
          if (_pendingFutureListeners == null) return;
          source = null;
          continue;
        }
      }
      // Complete the future waiting for the result.
      _Future result = listener.result;
      _FutureListener resultListeners = result._removeListeners();
      if (!listenerHasError) {
        result._setValue(listenerValueOrError);
      } else {
        AsyncError asyncError = listenerValueOrError;
        result._setErrorObject(asyncError);
      }
      // Prepare for next round.
      source = result;
      listeners = resultListeners;
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

class _PendingFutureListeners {
  final _Future source;
  final _PendingFutureListeners next;
  _FutureListener listeners;
  _PendingFutureListeners(this.source, this.listeners, this.next);
}
