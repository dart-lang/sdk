// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.async;

/** The onValue and onError handlers return either a value or a future */
typedef dynamic _FutureOnValue<T>(T value);
typedef dynamic _FutureOnError(error);
/** Test used by [Future.catchError] to handle skip some errors. */
typedef bool _FutureErrorTest(var error);
/** Used by [WhenFuture]. */
typedef _FutureAction();

abstract class _Completer<T> implements Completer<T> {
  final _Future<T> future = new _Future<T>();

  void complete([T value]);

  void completeError(Object error, [Object stackTrace = null]);

  // The future's _isComplete doesn't take into account pending completions.
  // We therefore use _mayComplete.
  bool get isCompleted => !future._mayComplete;
}

class _AsyncCompleter<T> extends _Completer<T> {

  void complete([T value]) {
    future._asyncComplete(value);
  }

  void completeError(Object error, [Object stackTrace = null]) {
    future._asyncCompleteError(error, stackTrace);
  }
}

class _SyncCompleter<T> extends _Completer<T> {

  void complete([T value]) {
    future._complete(value);
  }

  void completeError(Object error, [Object stackTrace = null]) {
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

  final _Zone _zone = _Zone.current.fork();

  bool get _mayComplete => _state == _INCOMPLETE;
  bool get _isChained => _state == _CHAINED;
  bool get _isComplete => _state >= _VALUE;
  bool get _hasValue => _state == _VALUE;
  bool get _hasError => _state == _ERROR;

  set _isChained(bool value) {
    if (value) {
      assert(_mayComplete);
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
  final _FutureOnValue _onValueCallback;
  final _FutureErrorTest _errorTestCallback;
  final _FutureOnError _onErrorCallback;
  final _FutureAction _whenCompleteActionCallback;

  _FutureOnValue get _onValue => _isChained ? null : _onValueCallback;
  _FutureErrorTest get _errorTest => _isChained ? null : _errorTestCallback;
  _FutureOnError get _onError => _isChained ? null : _onErrorCallback;
  _FutureAction get _whenCompleteAction
      => _isChained ? null : _whenCompleteActionCallback;

  _Future()
      : _onValueCallback = null, _errorTestCallback = null,
        _onErrorCallback = null, _whenCompleteActionCallback = null;

  _Future.immediate(T value)
        : _onValueCallback = null, _errorTestCallback = null,
          _onErrorCallback = null, _whenCompleteActionCallback = null {
    _asyncComplete(value);
  }

  _Future.immediateError(var error, [Object stackTrace])
      : _onValueCallback = null, _errorTestCallback = null,
        _onErrorCallback = null, _whenCompleteActionCallback = null {
    _asyncCompleteError(error, stackTrace);
  }

  _Future._then(this._onValueCallback, this._onErrorCallback)
      : _errorTestCallback = null, _whenCompleteActionCallback = null {
    _zone.expectCallback();
  }

  _Future._catchError(this._onErrorCallback, this._errorTestCallback)
    : _onValueCallback = null, _whenCompleteActionCallback = null {
    _zone.expectCallback();
  }

  _Future._whenComplete(this._whenCompleteActionCallback)
      : _onValueCallback = null, _errorTestCallback = null,
        _onErrorCallback = null {
    _zone.expectCallback();
  }

  Future then(f(T value), { onError(error) }) {
    _Future result;
    result = new _Future._then(f, onError);
    _addListener(result);
    return result;
  }

  Future catchError(f(error), { bool test(error) }) {
    _Future result = new _Future._catchError(f, test);
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

  void _clearPendingCompletion() {
    assert(_state == _PENDING_COMPLETE);
    _state = _INCOMPLETE;
  }

  T get _value {
    assert(_isComplete && _hasValue);
    return _resultOrListeners;
  }

  Object get _error {
    assert(_isComplete && _hasError);
    return _resultOrListeners;
  }

  void _setValue(T value) {
    assert(!_isComplete);  // But may have a completion pending.
    _state = _VALUE;
    _resultOrListeners = value;
  }

  void _setError(Object error) {
    assert(!_isComplete);  // But may have a completion pending.
    _state = _ERROR;
    _resultOrListeners = error;
  }

  void _addListener(_Future listener) {
    assert(listener._nextListener == null);
    if (_isComplete) {
      // Handle late listeners asynchronously.
      runAsync(() {
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

  static void _chainFutures(Future source, _Future target) {
    assert(!target._isComplete);

    // Mark the target as chained (and as such half-completed).
    target._isChained = true;
    if (source is _Future) {
      _Future internalFuture = source;
      if (internalFuture._isComplete) {
        _propagateToListeners(internalFuture, target);
      } else {
        internalFuture._addListener(target);
      }
    } else {
      source.then((value) {
          // Clear the is-chained bit, so that we can use the standard
          // _complete method.
          target._isChained = false;
          target._complete(value);
        },
        onError: (error) {
          // Clear the is-chained bit, so that we can use the standard
          // _completeError method.
          target._isChained = false;
          target._completeError(error);
        });
    }
  }

  void _complete(value) {
    assert(_onValueCallback == null &&
           _onErrorCallback == null &&
           _whenCompleteActionCallback == null &&
           _errorTestCallback == null);
    if (!_mayComplete) throw new StateError("Future already completed");
    if (value is Future) {
      _chainFutures(value, this);
      return;
    }
    _Future listeners = _removeListeners();
    _setValue(value);
    _propagateToListeners(this, listeners);
  }

  void _completeError(error, [StackTrace stackTrace]) {
    assert(_onValueCallback == null);
    assert(_onErrorCallback == null);
    assert(_whenCompleteActionCallback == null);
    assert(_errorTestCallback == null);
    // _isComplete does not trigger for pending completions.
    if (!_mayComplete) throw new StateError("Future already completed");
    if (stackTrace != null) {
      // Force the stack trace onto the error, even if it already had one.
      _attachStackTrace(error, stackTrace);
    }

    _Future listeners = _isChained ? null : _removeListeners();
    _setError(error);
    _propagateToListeners(this, listeners);
  }

  void _asyncComplete(value) {
    assert(_onValueCallback == null);
    assert(_onErrorCallback == null);
    assert(_whenCompleteActionCallback == null);
    assert(_errorTestCallback == null);
    if (!_mayComplete) throw new StateError("Future already completed");
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
    if (value is Future &&
        (value is! _Future || !(value as _Future)._isComplete)) {
      // Case 2 from above. We need to register.
      // Note that we are still completing asynchronously: either we register
      // through .then (in which case the completing is asynchronous), or we
      // have a _Future which isn't complete yet.
      _complete(value);
      return;
    }

    _markPendingCompletion();
    runAsync(() {
      _clearPendingCompletion();
      _complete(value);
    });
  }

  void _asyncCompleteError(error, [StackTrace stackTrace]) {
    assert(_onValueCallback == null);
    assert(_onErrorCallback == null);
    assert(_whenCompleteActionCallback == null);
    assert(_errorTestCallback == null);
    if (!_mayComplete) throw new StateError("Future already completed");
    _markPendingCompletion();
    runAsync(() {
      _clearPendingCompletion();
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
        source._zone.handleUncaughtError(source._error);
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
      if (hasError && !source._zone.inSameErrorZone(listener._zone)) {
        // Don't cross zone boundaries with errors.
        source._zone.handleUncaughtError(source._error);
        return;
      }
      if (!identical(_Zone.current, listener._zone)) {
        // Run the propagation in the listener's zone to avoid
        // zone transitions. The idea is that many chained futures will
        // be in the same zone.
        listener._zone.executePeriodicCallback(() {
          _propagateToListeners(source, listener);
        });
        return;
      }

      // Do the actual propagation.
      // TODO(floitsch): Do we need to go through the zone even if we
      // don't have a callback to execute?
      bool listenerHasValue;
      var listenerValueOrError;
      // Set to true if a whenComplete needs to wait for a future.
      // The whenComplete action will resume the propagation by itself.
      bool isPropagationAborted = false;
      // Even though we are already in the right zone (due to the optimization
      // above), we still need to go through the zone. The overhead of
      // executeCallback is however smaller when it is already in the correct
      // zone.
      // TODO(floitsch): only run callbacks in the zone, not the whole
      // handling code.
      listener._zone.executeCallback(() {
        // TODO(floitsch): mark the listener as pending completion. Currently
        // we can't do this, since the markPendingCompletion verifies that
        // the future is not already marked (or chained).
        try {
          if (!hasError) {
            var value = source._value;
            if (listener._onValue != null) {
              listenerValueOrError = listener._onValue(value);
              listenerHasValue = true;
            } else {
              // Copy over the value from the source.
              listenerValueOrError = value;
              listenerHasValue = true;
            }
          } else {
            Object error = source._error;
            _FutureErrorTest test = listener._errorTest;
            bool matchesTest = true;
            if (test != null) {
              matchesTest = test(error);
            }
            if (matchesTest && listener._onError != null) {
              listenerValueOrError = listener._onError(error);
              listenerHasValue = true;
            } else {
              // Copy over the error from the source.
              listenerValueOrError = error;
              listenerHasValue = false;
            }
          }

          if (listener._whenCompleteAction != null) {
            var completeResult = listener._whenCompleteAction();
            if (completeResult is Future) {
              listener._isChained = true;
              completeResult.then((ignored) {
                // Try again, but this time don't run the whenComplete callback.
                _propagateToListeners(source, listener);
              }, onError: (error) {
                // When there is an error, we have to make the error the new
                // result of the current listener.
                if (completeResult is! _Future) {
                  // This should be a rare case.
                  completeResult = new _Future();
                  completeResult._setError(error);
                }
                _propagateToListeners(completeResult, listener);
              });
              isPropagationAborted = true;
              // We will reenter the listener's zone.
              listener._zone.expectCallback();
            }
          }
        } catch (e, s) {
          // Set the exception as error.
          listenerValueOrError = _asyncError(e, s);
          listenerHasValue = false;
        }
        if (listenerHasValue && listenerValueOrError is Future) {
          // We are going to reenter the zone to finish what we started.
          listener._zone.expectCallback();
        }
      });
      if (isPropagationAborted) return;
      // If the listener's value is a future we need to chain it.
      if (listenerHasValue && listenerValueOrError is Future) {
        Future chainSource = listenerValueOrError;
        // Shortcut if the chain-source is already completed. Just continue the
        // loop.
        if (chainSource is _Future && (chainSource as _Future)._isComplete) {
          // propagate the value (simulating a tail call).
          listener._isChained = true;
          source = chainSource;
          listeners = listener;
          continue;
        }
        _chainFutures(chainSource, listener);
        return;
      }

      if (listenerHasValue) {
        listeners = listener._removeListeners();
        listener._setValue(listenerValueOrError);
      } else {
        listeners = listener._removeListeners();
        listener._setError(listenerValueOrError);
      }
      // Prepare for next round.
      source = listener;
    }
  }
}
