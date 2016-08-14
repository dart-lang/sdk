// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.async;

/** The onValue and onError handlers return either a value or a future */
typedef dynamic/*T|Future<T>*/ _FutureOnValue<S, T>(S value);
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

class _FutureListener<S, T> {
  static const int MASK_VALUE = 1;
  static const int MASK_ERROR = 2;
  static const int MASK_TEST_ERROR = 4;
  static const int MASK_WHENCOMPLETE = 8;
  static const int STATE_CHAIN = 0;
  static const int STATE_THEN = MASK_VALUE;
  // TODO(johnmccutchan): Remove the hard coded value. See #26030.
  static const int STATE_THEN_ONERROR = 3;  // MASK_VALUE | MASK_ERROR.
  static const int STATE_CATCHERROR = MASK_ERROR;
  // TODO(johnmccutchan): Remove the hard coded value. See #26030.
  static const int STATE_CATCHERROR_TEST = 6;  // MASK_ERROR | MASK_TEST_ERROR.
  static const int STATE_WHENCOMPLETE = MASK_WHENCOMPLETE;
  // Listeners on the same future are linked through this link.
  _FutureListener _nextListener = null;
  // The future to complete when this listener is activated.
  final _Future<T> result;
  // Which fields means what.
  final int state;
  // Used for then/whenDone callback and error test
  final Function callback;
  // Used for error callbacks.
  final Function errorCallback;

  _FutureListener.then(this.result,
                       _FutureOnValue<S, T> onValue, Function errorCallback)
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

  Zone get _zone => result._zone;

  bool get handlesValue => (state & MASK_VALUE != 0);
  bool get handlesError => (state & MASK_ERROR != 0);
  bool get hasErrorTest => (state == STATE_CATCHERROR_TEST);
  bool get handlesComplete => (state == STATE_WHENCOMPLETE);


  _FutureOnValue<S, T> get _onValue {
    assert(handlesValue);
    return callback as Object /*=_FutureOnValue<S, T>*/;
  }
  Function get _onError => errorCallback;
  _FutureErrorTest get _errorTest {
    assert(hasErrorTest);
    return callback as Object /*=_FutureErrorTest*/;
  }
  _FutureAction get _whenCompleteAction {
    assert(handlesComplete);
    return callback as Object /*=_FutureAction*/;
  }

  /// Whether this listener has an error callback.
  ///
  /// This function must only be called if the listener [handlesError].
  bool get hasErrorCallback {
    assert(handlesError);
    return _onError != null;
  }

  dynamic/*T|Future<T>*/ handleValue(S sourceResult) {
    return _zone.runUnary/*<dynamic/*T|Future<T>*/, S>*/(
        _onValue, sourceResult);
  }

  bool matchesErrorTest(AsyncError asyncError) {
    if (!hasErrorTest) return true;
    _FutureErrorTest test = _errorTest;
    return _zone.runUnary/*<bool, dynamic>*/(_errorTest, asyncError.error);
  }

  dynamic/*T|Future<T>*/ handleError(AsyncError asyncError) {
    assert(handlesError && hasErrorCallback);
    if (errorCallback is ZoneBinaryCallback) {
      var typedErrorCallback = errorCallback as Object
          /*=ZoneBinaryCallback<Object/*T|Future<T>*/, Object, StackTrace>*/;
      return _zone.runBinary(typedErrorCallback,
          asyncError.error,
          asyncError.stackTrace);
    } else {
      return _zone.runUnary/*<dynamic/*T|Future<T>*/, dynamic>*/(
          errorCallback, asyncError.error);
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
  static const int _INCOMPLETE = 0;
  /// Pending completion. Set when completed using [_asyncComplete] or
  /// [_asyncCompleteError]. It is an error to try to complete it again.
  /// [resultOrListeners] holds listeners.
  static const int _PENDING_COMPLETE = 1;
  /// The future has been chained to another future. The result of that
  /// other future becomes the result of this future as well.
  /// [resultOrListeners] contains the source future.
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
   */
  var _resultOrListeners;

  // This constructor is used by async/await.
  _Future();

  /// Valid types for value: `T` or `Future<T>`.
  _Future.immediate(value) {
    _asyncComplete(value);
  }

  _Future.immediateError(var error, [StackTrace stackTrace]) {
    _asyncCompleteError(error, stackTrace);
  }

  bool get _mayComplete       => _state == _INCOMPLETE;
  bool get _isPendingComplete => _state == _PENDING_COMPLETE;
  bool get _mayAddListener    => _state <= _PENDING_COMPLETE;
  bool get _isChained         => _state == _CHAINED;
  bool get _isComplete        => _state >= _VALUE;
  bool get _hasError          => _state == _ERROR;

  void _setChained(_Future source) {
    assert(_mayAddListener);
    _state = _CHAINED;
    _resultOrListeners = source;
  }

  Future/*<E>*/ then/*<E>*/(
      /*=dynamic/*E|Future<E>*/*/ f(T value), { Function onError }) {
    Zone currentZone = Zone.current;
    ZoneUnaryCallback registered;
    if (!identical(currentZone, _ROOT_ZONE)) {
      f = currentZone.registerUnaryCallback/*<dynamic, T>*/(f);
      if (onError != null) {
        onError = _registerErrorHandler/*<T>*/(onError, currentZone);
      }
    }
    return _thenNoZoneRegistration/*<E>*/(f, onError);
  }

  // This method is used by async/await.
  Future/*<E>*/ _thenNoZoneRegistration/*<E>*/(f(T value), Function onError) {
    _Future/*<E>*/ result = new _Future/*<E>*/();
    _addListener(new _FutureListener/*<T, E>*/.then(result, f, onError));
    return result;
  }

  Future/*<T>*/ catchError(Function onError, { bool test(error) }) {
    _Future/*<T>*/ result = new _Future/*<T>*/();
    if (!identical(result._zone, _ROOT_ZONE)) {
      onError = _registerErrorHandler/*<T>*/(onError, result._zone);
      if (test != null) test = result._zone.registerUnaryCallback(test);
    }
    _addListener(new _FutureListener/*<T, T>*/.catchError(
        result, onError, test));
    return result;
  }

  Future<T> whenComplete(action()) {
    _Future<T> result = new _Future<T>();
    if (!identical(result._zone, _ROOT_ZONE)) {
      action = result._zone.registerCallback/*<dynamic>*/(action);
    }
    _addListener(new _FutureListener/*<T, T>*/.whenComplete(result, action));
    return result;
  }

  Stream<T> asStream() => new Stream<T>.fromFuture(this);

  void _setPendingComplete() {
    assert(_mayComplete);
    _state = _PENDING_COMPLETE;
  }

  void _clearPendingComplete() {
    assert(_isPendingComplete);
    _state = _INCOMPLETE;
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

  void _prependListeners(_FutureListener listeners) {
    if (listeners == null) return;
    if (_mayAddListener) {
      _FutureListener existingListeners = _resultOrListeners;
      _resultOrListeners = listeners;
      if (existingListeners != null) {
        _FutureListener cursor = listeners;
        while (cursor._nextListener != null) {
          cursor = cursor._nextListener;
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

  _FutureListener _removeListeners() {
    // Reverse listeners before returning them, so the resulting list is in
    // subscription order.
    assert(!_isComplete);
    _FutureListener current = _resultOrListeners;
    _resultOrListeners = null;
    return _reverseListeners(current);
  }

  _FutureListener _reverseListeners(_FutureListener listeners) {
    _FutureListener prev = null;
    _FutureListener current = listeners;
    while (current != null) {
      _FutureListener next = current._nextListener;
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
          target._clearPendingComplete();  // Clear this first, it's set again.
          target._complete(value);
        },
        // TODO(floitsch): eventually we would like to make this non-optional
        // and dependent on the listeners of the target future. If none of
        // the target future's listeners want to have the stack trace we don't
        // need a trace.
        onError: (error, [stackTrace]) {
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
    assert(target._mayAddListener);  // Not completed, not already chained.
    while (source._isChained) {
      source = source._chainSource;
    }
    if (source._isComplete) {
      _FutureListener listeners = target._removeListeners();
      target._cloneResult(source);
      _propagateToListeners(target, listeners);
    } else {
      _FutureListener listeners = target._resultOrListeners;
      target._setChained(source);
      source._prependListeners(listeners);
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
      _setValue(value as Object /*=T*/);
      _propagateToListeners(this, listeners);
    }
  }

  void _completeWithValue(T value) {
    assert(!_isComplete);
    assert(value is! Future);

    _FutureListener listeners = _removeListeners();
    _setValue(value);
    _propagateToListeners(this, listeners);
  }

  void _completeError(error, [StackTrace stackTrace]) {
    assert(!_isComplete);

    _FutureListener listeners = _removeListeners();
    _setError(error, stackTrace);
    _propagateToListeners(this, listeners);
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

    if (value is Future) {
      // Assign to typed variables so we get earlier checks in checked mode.
      Future<T> typedFuture = value as Object /*=Future<T>*/;
      if (typedFuture is _Future) {
        _Future<T> coreFuture = typedFuture;
        if (coreFuture._hasError) {
          // Case 1 from above. Delay completion to enable the user to register
          // callbacks.
          _setPendingComplete();
          _zone.scheduleMicrotask(() {
            _chainCoreFuture(coreFuture, this);
          });
        } else {
          _chainCoreFuture(coreFuture, this);
        }
      } else {
        // Case 2 from above. Chain the future immediately.
        // Note that we are still completing asynchronously (through
        // _chainForeignFuture).
        _chainForeignFuture(typedFuture, this);
      }
      return;
    }
    T typedValue = value as Object /*=T*/;

    _setPendingComplete();
    _zone.scheduleMicrotask(() {
      _completeWithValue(typedValue);
    });
  }

  void _asyncCompleteError(error, StackTrace stackTrace) {
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
  static void _propagateToListeners(_Future source, _FutureListener listeners) {
    while (true) {
      assert(source._isComplete);
      bool hasError = source._hasError;
      if (listeners == null) {
        if (hasError) {
          AsyncError asyncError = source._error;
          source._zone.handleUncaughtError(
              asyncError.error, asyncError.stackTrace);
        }
        return;
      }
      // Usually futures only have one listener. If they have several, we
      // call handle them separately in recursive calls, continuing
      // here only when there is only one listener left.
      while (listeners._nextListener != null) {
        _FutureListener listener = listeners;
        listeners = listener._nextListener;
        listener._nextListener = null;
        _propagateToListeners(source, listener);
      }
      _FutureListener listener = listeners;
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
          if (completeResult is Future) {
            if (completeResult is _Future && completeResult._isComplete) {
              if (completeResult._hasError) {
                listenerValueOrError = completeResult._error;
                listenerHasError = true;
              }
              // Otherwise use the existing result of source.
              return;
            }
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

  Future<T> timeout(Duration timeLimit, {onTimeout()}) {
    if (_isComplete) return new _Future.immediate(this);
    _Future<T> result = new _Future<T>();
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
