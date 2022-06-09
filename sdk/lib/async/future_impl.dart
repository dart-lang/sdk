// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.async;

/// Implementation of [Completer] based on a [_Future].
///
/// The [_Future] class implements the functionality internally as
/// private methods, that this completer can call into.
///
/// The completer is either synchronous or asynchronous. In the latter
/// case, it asks the `_Future` to delay completion.
abstract class _Completer<T> implements Completer<T> {
  /// The future completed by this completer.
  ///
  /// Only ever completed through calling [complete] or [completeError].
  /// which can only be done once.
  final _Future<T> future = new _Future<T>();

  void complete([FutureOr<T>? value]);

  void completeError(Object error, [StackTrace? stackTrace]) {
    // TODO(40614): Remove once non-nullability is sound.
    checkNotNullable(error, "error");
    if (!future._mayComplete) throw new StateError("Future already completed");
    _completeError(_interceptSyncError(Zone.current, error, stackTrace));
  }

  void _completeError(AsyncError error);

  /// Whether calling [complete] or [completeError] is disallowed.
  ///
  /// The [_Future._mayComplete] differs from [_Future._isComplete].
  /// The former means calling [_Future._complete] is allowed.
  /// The latter means it has a value or an error.
  /// If the [_Future] has been "completed" with another future,
  /// or asynchronously completed with an error,
  /// the two differs while waiting for that the final result to be set.
  bool get isCompleted => !future._mayComplete;
}

class _AsyncCompleter<T> extends _Completer<T> {
  void complete([FutureOr<T>? value]) {
    if (!future._mayComplete) throw new StateError("Future already completed");
    // Ensure that value is a `FutureOr<T>`, which means it can only be
    // null (or omitted) if [T] is nullable.
    FutureOr<T> checkedValue = value as dynamic;
    future._asyncCompleteUnchecked(checkedValue);
  }

  void _completeError(AsyncError error) {
    future._asyncCompleteErrorObject(error);
  }
}

class _SyncCompleter<T> extends _Completer<T> {
  void complete([FutureOr<T>? value]) {
    if (!future._mayComplete) throw new StateError("Future already completed");
    // Ensure that value is a `FutureOr<T>`, which means it can only be
    // null (or omitted) if [T] is nullable.
    FutureOr<T> checkedValue = value as dynamic;
    future._completeUnchecked(checkedValue);
  }

  void _completeError(AsyncError error) {
    future._completeErrorObject(error);
  }
}

/// A listener on a `Future<S>` which creates a `Future<T>`.
///
/// The listener knows the type of both the [source] and [result] futures,
/// and is the class which calls user code and enforces types around it,
/// where `_Future` itself is mostly untyped.
///
/// If the listener is not handling values (not related to a `.then` call),
/// the [S] and [T] types are always the same.
///
/// When the [source] future is completed, the listener's
/// [propagate] function will be called at some later point
/// (but often very soon).
/// The [propagate] function takes the result of [source] and
/// calls the appropriate user callbacks, then completes [result]
/// with the result of that call, and returns the listeners of
/// the newly completed [result] future, so they too can be
/// processed.
class _FutureListener<S, T> {
  // Keep in sync with sdk/runtime/vm/stack_trace.cc.
  static const int maskValue = 1;
  static const int maskError = 2;
  static const int maskTestError = 4;
  static const int maskWhenComplete = 8;
  static const int stateChain = 0;
  // Handles values, passes errors on.
  static const int stateThen = maskValue;
  // Handles values and errors.
  static const int stateThenOnerror = maskValue | maskError;
  // Handles errors, has errorCallback.
  static const int stateCatchError = maskError;
  // Ignores both values and errors. Has no callback or errorCallback.
  // The [result] future is ignored, its always the same as the source.
  static const int stateCatchErrorTest = maskError | maskTestError;
  static const int stateWhenComplete = maskWhenComplete;
  static const int maskType =
      maskValue | maskError | maskTestError | maskWhenComplete;

  // Listeners on the same future as single-liked list.
  //
  // New listeners are "pushed" at the head of the list, so the
  // list is in reverse listening order. The list is reveresed
  // before being used, so we preserve listening order in the callbacks.
  //
  // Type parameters are both top types because:
  // - The first, source, type is contravariant. When listeners
  //   are added to a chained future, they may accept a supertype
  //   of what the source provides (`super S`).
  // - The second, target, type differes between listeners on the same
  //   future, so the types are unrelated.
  _FutureListener<Object?, Object?>? _nextListener;

  // The future that this listener gets its result from.
  //
  // Can be changed if the listener is moved to a different future.
  // Has the type `Future<S>`, which allows `S` to be a supertype
  // of the actual future's type.
  _Future<S> source;

  /// The future to complete when this listener is activated.
  ///
  /// The [result] future of a future listener is *only ever* completed
  /// through the listener's [propagate] method. After calling that,
  /// the [result] is either completed, chained to a native future,
  /// or pending the result of a non-native future.
  /// Before calling [propagate], the future is always incomplete
  /// ([_stateIncomplete], possibly [_stateIgnoreError]).
  @pragma("vm:entry-point")
  final _Future<T> result;

  /// Which fields means what.
  ///
  /// Always satisfies precisely one of
  /// * [_mayAddListener] ([_stateIncomplete],
  ///    possibly including [_statePendingComplete] and [_stateIgnoreError]).
  /// * [_isChained] ([_stateChained]).
  /// * [_isComplete] ([_stateValue] or [_stateError]).
  ///
  /// Transitions by calling [_setError], [_setValue], [_chainCoreFuture].
  @pragma("vm:entry-point")
  final int state;

  // Used for then/whenDone callback and error test
  @pragma("vm:entry-point")
  final Function? callback;

  // Used for error callbacks.
  final Function? errorCallback;

  _FutureListener.then(this.source, this.result,
      FutureOr<T> Function(S) onValue, Function? errorCallback)
      : callback = onValue,
        errorCallback = errorCallback,
        state = (errorCallback == null) ? stateThen : stateThenOnerror;

  _FutureListener.thenAwait(this.source, this.result,
      FutureOr<T> Function(S) onValue, Function errorCallback)
      : callback = onValue,
        errorCallback = errorCallback,
        state = stateThenOnerror;

  _FutureListener.catchError(
      this.source, this.result, this.errorCallback, this.callback)
      : assert(S == T),
        state = (callback == null) ? stateCatchError : stateCatchErrorTest;

  _FutureListener.whenComplete(this.source, this.result, this.callback)
      : assert(S == T),
        errorCallback = null,
        state = stateWhenComplete;

  _Zone get _zone => result._zone;

  @pragma("vm:prefer-inline")
  @pragma("dart2js:tryInline")
  bool get handlesValue => (state & maskValue != 0);

  @pragma("vm:prefer-inline")
  @pragma("dart2js:tryInline")
  bool get handlesError => (state & maskError != 0);

  @pragma("vm:prefer-inline")
  @pragma("dart2js:tryInline")
  bool get hasErrorTest => (state & maskType == stateCatchErrorTest);

  @pragma("vm:prefer-inline")
  @pragma("dart2js:tryInline")
  bool get handlesComplete => (state & maskType == stateWhenComplete);

  FutureOr<T> Function(S) get _onValue {
    assert(handlesValue);
    return unsafeCast<FutureOr<T> Function(S)>(callback);
  }

  bool Function(Object) get _errorTest {
    assert(hasErrorTest);
    return unsafeCast<bool Function(Object)>(callback);
  }

  dynamic Function() get _whenCompleteAction {
    assert(handlesComplete);
    return unsafeCast<dynamic Function()>(callback);
  }

  void setSourceUnchecked(_Future source) {
    assert(source is Future<S>);
    source = unsafeCast<_Future<S>>(source);
  }

  /// Whether this listener has an error callback.
  ///
  /// This function must only be called if the listener [handlesError].
  bool get hasErrorCallback {
    assert(handlesError);
    return errorCallback != null;
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
    dynamic result;
    if (errorCallback is dynamic Function(Object, StackTrace)) {
      result = _zone.runBinary<dynamic, Object, StackTrace>(
          errorCallback, asyncError.error, asyncError.stackTrace);
    } else {
      result = _zone.runUnary<dynamic, Object>(
          errorCallback as dynamic, asyncError.error);
    }
    // Give better error messages if the result is not a valid
    // FutureOr<T>.
    try {
      return result;
    } on TypeError {
      if (handlesValue) {
        // This is a `.then` callback with an `onError`.
        throw ArgumentError(
            "The error handler of Future.then"
                " must return a value of the returned future's type",
            "onError");
      }
      // This is a `catchError` callback.
      throw ArgumentError(
          "The error handler of "
              "Future.catchError must return a value of the future's type",
          "onError");
    }
  }

  dynamic handleWhenComplete() {
    assert(!handlesError);
    return _zone.run(_whenCompleteAction);
  }

  // Whether the [value] future should be awaited and the [future] completed
  // with its result, rather than just completing the [future] directly
  // with the [value].
  bool shouldChain(Future<dynamic> value) => value is Future<T> || value is! T;

  /// Processes all listeners in this listener linked list.
  ///
  /// Processing a listener means taking the result of [source],
  /// which must be [_Future._isComplete] or [_Future._isChained]
  /// (to a completed future, and which will then be completed as the first
  /// step of [_FutureListener.propagate]), passing the result through the
  /// callbacks of the listener, and then completing [target] if possible.
  ///
  /// If [target] is completed, continue processing *its* listeners as well.
  /// The new listeners are handled before other already completed listeners
  /// (mainly for backwards compatability with the previous implementation).
  ///
  /// Runs in a loop until there are no further listeners with a completed
  /// [source] future.
  void propagateResults() {
    _FutureListener listeners = this;
    if (listeners._nextListener == null) {
      // Single listener, just call it directly.
      var newListeners = listeners.propagate();
      if (newListeners == null) return;
      listeners = newListeners;
    }
    // Maintain linked list of pending listeners.
    listeners = _reverseListeners(listeners, null);
    while (true) {
      // Propagate to first pending listener.
      var newListeners = listeners.propagate();
      // Remember next pending listener.
      var nextListener = listeners._nextListener;
      if (newListeners != null) {
        // Prepend the reversed newListeners.
        // Special case a single listener, because it is the majority
        // of cases in practice.
        var nextNewListener = newListeners._nextListener;
        listeners = (nextNewListener == null)
            ? newListeners
            : _reverseListeners(nextNewListener, newListeners);
        newListeners._nextListener = nextListener;
      } else if (nextListener != null) {
        listeners = nextListener;
      } else {
        return;
      }
    }
  }

  /// Reverses [listeners], and returns new first element.
  ///
  /// Set the new last element (original [listeners]) to point to [next].
  static _FutureListener _reverseListeners(
      _FutureListener listeners, _FutureListener? next) {
    var cursor = listeners;
    while (true) {
      var prev = cursor._nextListener;
      cursor._nextListener = next;
      if (prev != null) {
        next = cursor;
        cursor = prev;
      } else {
        return cursor;
      }
    }
  }

  /// Calls listener callbacks with [source] result and completes [result].
  ///
  /// If the callback throws synchronously, we pass that error into
  /// [_zone.errorCallback] before completing [result] with resulting error.
  /// (For error handlers, if they throw the original error object, we
  /// treat it as a rethrow.)
  ///
  /// Returns the listeners of [result] if it is completed, so that
  /// those listeners can also have their result propagated.
  @pragma("vm:recognized", "other")
  @pragma("vm:never-inline")
  _FutureListener? propagate() {
    _Future<T> target = this.result;
    _Future<S> source = this.source;
    if (source._isChained) {
      // Find chained source, which must be complete, and copy result.
      _Future originalSource = source;
      do {
        originalSource = unsafeCast<_Future>(originalSource._resultOrListeners);
      } while (originalSource._isChained);
      assert(originalSource._isComplete);
      // Clone result of source.
      source._setState(
          originalSource._state, originalSource._resultOrListeners);
    }
    assert(source._isComplete);
    assert(target._mayAddListener);

    if (source._hasError && !source._zone.inSameErrorZone(target._zone)) {
      // Target future will never complete. We can't help it, for now we
      // mark it as pending complete.
      // TODO(lrn): Stop doing this.
      return null;
    }

    // Four different modes:
    // * whenComplete
    // * has value and handles value
    // * has error and handles error (potentially tests error)
    // * passes result through unchanged.
    if (!handlesComplete) {
      if (!source._hasError) {
        // Propagate a value result.
        if (handlesValue) {
          S value = unsafeCast<S>(source._resultOrListeners);
          FutureOr<T> result;
          try {
            result = _zone.runUnary<FutureOr<T>, S>(_onValue, value);
          } catch (e, s) {
            var errorObject = _interceptSyncError(target._zone, e, s);
            return target._setError(errorObject);
          }
          return target._completeWithFutureOr(result);
        }
        // If future doesn't handle values, its `S` and `T` types
        // are the same.
        assert(checkUnsoundType<T>(source._resultOrListeners));
        return target._setValue(source._resultOrListeners);
      } else if (handlesError) {
        AsyncError errorObject =
            unsafeCast<AsyncError>(source._resultOrListeners);
        try {
          if (matchesErrorTest(errorObject)) {
            var result = handleError(errorObject);
            return target._completeWithFutureOr(result);
          }
        } catch (e, s) {
          AsyncError newErrorObject = errorObject;
          if (!identical(e, errorObject.error)) {
            newErrorObject = _interceptSyncError(target._zone, e, s);
          }
          return target._setError(newErrorObject);
        }
        return target._setError(errorObject);
      }
    } else {
      // Handles whenComplete.
      FutureOr<void> result;
      try {
        result = target._zone.run(_whenCompleteAction);
      } catch (e, s) {
        // Callback throws synchronously.
        var errorObject = _interceptSyncError(target._zone, e, s);
        return target._setError(errorObject);
      }
      if (result is Future<void>) {
        // Wait for result of whenComplete callback.
        // If it throws, complete with that,
        // otherwise complete with same result as source.
        result.then((_) {
          target._setNativeFutureResult(source)?.propagateResults();
        }, onError: (e, s) {
          target._completeErrorObject(AsyncError(e, s));
        });
        return null;
      }
    }
    return target._setNativeFutureResult(source);
  }

  /// Filters list of listeners to only include results in same error zone.
  ///
  /// Works on a list of listeners (this one and the ones linked through
  /// [_nextListener]), and filters that list to only include listeners
  /// with [result] futures with the same error zone as [sourceZone].
  _FutureListener? filterByErrorZone(Zone sourceZone) {
    // Optimize for simple case of one listener.
    if (_nextListener == null) {
      if (sourceZone.inSameErrorZone(result._zone)) return this;
      return null;
    }
    // Find first listener to retain.
    _FutureListener cursor = this;
    while (!sourceZone.inSameErrorZone(cursor.result._zone)) {
      var next = cursor._nextListener;
      if (next == null) return null;
      cursor = next;
    }
    // Cursor is first element to retain.
    var first = cursor;
    var last = cursor;
    // Link other listeners to retain to first.
    while (true) {
      var next = cursor._nextListener;
      if (next == null) {
        last._nextListener = null;
        return first;
      }
      if (sourceZone.inSameErrorZone(next.result._zone)) {
        last._nextListener = next;
        last = next;
      }
      cursor = next;
    }
  }
}

/// An implementation of [Future] with callbacks.
///
/// The future is in one of a number of states.
/// * Incomplete
/// * Pending complete (being asynchronously completed, either by a microtask
///   or waiting for another non-native future).
/// * Chained (completed with a native future)
/// * Completed
///     * With a value
///     * With an error
///
/// The state determines the value of the [_resultOrListeners] variable.
/// That variable is in one of three modes:
/// * [_mayAddListener] (incomplet or pending complete)
///     - The variable can contain a chain of [_FutureListener]s.
///     - All these have [_FutureListener.source] pointing to this future.
/// * [_isChained] (chained)
///     - The variable contains another [_Future], which is always a
///       [_Future<T>].
/// * [_isComplete] (completed)
///     - the variable contains either the value (of type [T]) or
///       and [AsyncError] object, determined by [_hasError].
///
/// The [_zone] is the zone used by this future for everything zone
/// related. When completed with an error, the error belongs to the
/// "errorzone" of [_zone]. When a microtask needs to be scheduled,
/// it uses [_zone.scheduleMicrotask].
///
/// Most internal operations are *untyped* (as far as possible).
///
/// A number of operations are marked as for external use in this library
/// (but outside this file and `future.dart`).
/// Those check types on entry.
/// The types are mainly used inside [_FutureListener], where a
/// `_FutureListener<S, T>` handles all the conversion from [S] to [T].
class _Future<T> implements Future<T> {
  /// Initial state, waiting for a result. In this state, the
  /// [_resultOrListeners] field holds a single-linked list of
  /// [_FutureListener] listeners.
  static const int _stateIncomplete = 0;

  /// Flag set when an error need not be handled.
  ///
  /// Set by the [FutureExtensions.ignore] method to avoid
  /// having to introduce an unnecessary listener.
  /// Only relevant until the future is completed.
  static const int _stateIgnoreError = 1;

  /// Pending completion.
  ///
  /// Set when completed using [_asyncComplete] or
  /// [_asyncCompleteError] or similar asynchronous completions.
  /// Used by [_Completer] to see if you can call [Completer.complete].
  /// It is an error to try to complete it again.
  /// [_resultOrListeners] still hold listeners.
  static const int _statePendingComplete = 2;

  /// The future has been chained to another "source" [_Future].
  ///
  /// The result of that other future becomes the result of this future
  /// as well, when the other future completes.
  /// This future cannot be completed again.
  /// [_resultOrListeners] contains the source future.
  /// Listeners have been moved to the chained future.
  ///
  /// The [_stateIgnoreError] bit may be set, but [_statePendingComplete]
  /// is not.
  static const int _stateChained = 4;

  /// The future has been completed with a value result.
  ///
  /// [_resultOrListeners] contains the value.
  static const int _stateValue = 8;

  /// The future has been completed with an error result.
  ///
  /// [_resultOrListeners] contains an [AsyncError]
  /// holding the error and stack trace.
  static const int _stateError = 16;

  /// Mask for the states above except [_stateIgnoreError].
  static const int _completionStateMask = 30;

  /// Whether the future is complete, and as what.
  int _state = _stateIncomplete;

  /// Either the result, a list of listeners or another future.
  ///
  /// The result of the future is either a value or an error.
  /// A result is only stored when the future has completed.
  ///
  /// The listeners is an internally linked list of [_FutureListener]s.
  /// Listeners are only remembered while the future is not yet complete,
  /// and it is not chained to another future.
  ///
  /// The future is another future that this future is chained to. This future
  /// is waiting for the other future to complete, and when it does,
  /// this future will complete with the same result.
  /// All listeners are forwarded to the other future.
  @pragma("vm:entry-point")
  Object? _resultOrListeners;

  @pragma("vm:prefer-inline")
  @pragma("dart2js:tryInline")
  void _setState(int state, Object? stateValue) {
    assert(state & _stateError == 0 || stateValue is AsyncError);
    assert(state & _stateValue == 0 || checkUnsoundType<T>(stateValue));
    assert(state & _stateChained == 0 || stateValue is _Future);
    assert(state & (_stateError | _stateValue | _stateChained) != 0 ||
        stateValue is _FutureListener?);
    _state = state;
    _resultOrListeners = stateValue;
  }

  /// Zone that the future was completed from.
  /// This is the zone that an error result belongs to.
  ///
  /// Until the future is completed, the field may hold the zone that
  /// listener callbacks used to create this future should be run in.
  final _Zone _zone;

  // This constructor is used by async/await.
  _Future() : _zone = Zone._current;

  /// Creates fresh future in a specific zone.
  _Future.zone(this._zone);

  _Future.immediate(FutureOr<T> result) : _zone = Zone._current {
    _asyncCompleteUnchecked(result);
  }

  /// Creates a future with the value and the specified zone.
  _Future.zoneValue(T value, this._zone) {
    _setState(_stateValue, value);
  }

  /// Creates a future with an asynchronously completed error.
  _Future.immediateError(var error, StackTrace stackTrace)
      : _zone = Zone._current {
    // Completes asynchronously.
    _asyncCompleteErrorObject(AsyncError(error, stackTrace));
  }

  /// Creates a future that is already completed with the value.
  _Future.value(T value) : this.zoneValue(value, Zone._current);

  // PUBLIC API, called by classes in `dart:async` other than
  // `Future` and `_Completer`.
  //
  // Should not be called from inside the implementation.
  // Use implementation-specific functions instead.

  /// Completes this future synchronously with the future or value.
  ///
  /// Even if the value is an already completed `_Future` with an error
  /// result, the completion happens immediately.
  void _complete(FutureOr<T> value) {
    _completeUnchecked(value);
  }

  /// Completes this future synchronously with the future or value.
  ///
  /// Even if the value is an already completed `_Future` with an error
  /// result, the completion happens immediately.
  ///
  /// Argument must be assignable to `FutureOr<T>`.
  void _completeUnchecked(/* FutureOr<T> */ Object? value) {
    assert(checkUnsoundType<FutureOr<T>>(value));
    assert(_mayComplete);
    // Linked list of listeners whose source has been completed, if any.
    _FutureListener? completedListeners;
    if (value is Future<T>) {
      Object nativeFuture = value as Object;
      if (nativeFuture is _Future) {
        completedListeners = _chainCoreFuture(nativeFuture);
      } else {
        _chainForeignFuture(value);
        return;
      }
    } else {
      completedListeners = _setValue(value);
    }
    if (completedListeners != null) completedListeners.propagateResults();
  }

  /// Completes this future synchronously with an error and stack trace.
  void _completeError(Object error, StackTrace stackTrace) {
    _completeErrorObject(AsyncError(error, stackTrace));
  }

  /// Completes this future synchronously with an asynchronous error.
  void _completeErrorObject(AsyncError error) {
    assert(_mayComplete);
    _setError(error)?.propagateResults();
  }

  /// Asynchronously completes this future with the value or future.
  ///
  /// Ensures completion won't happen until a later microtask.
  /// Tries to not introduce extra delays if [value] is already an
  /// incomplete future.
  void _asyncComplete(FutureOr<T> value) {
    _asyncCompleteUnchecked(value);
  }

  /// Internal helper function used by the implementation of `async` functions.
  ///
  /// Like [_asyncComplete], but avoids type checks that are guaranteed to
  /// succeed by the way the function is called.
  /// Should be used judiciously.
  void _asyncCompleteUnchecked(/*FutureOr<T>*/ dynamic value) {
    assert(_mayComplete);

    // Ensure [value] is FutureOr<T>, do so using an `as` check so it works
    // also correctly in non-sound null-safety mode.
    assert(checkUnsoundType<FutureOr<T>>(value));

    // Two corner cases if the value is a future:
    //   1. the future is already completed and is an error.
    //   2. the future is not yet completed but might become an error.
    // The first case means that we must not immediately complete the Future,
    // as our code would immediately start propagating the error without
    // giving the time to install error-handlers.
    // However the second case requires us to deal with the value immediately.
    // Otherwise the value could complete with an error and report an
    // unhandled error, even though we know we are already going to listen to
    // it.

    if (value is Future<T>) {
      var nativeFuture = value as Object;
      if (nativeFuture is _Future) {
        _asyncCompleteWithNativeFuture(nativeFuture);
        return;
      }
      // Always asynchronous, based on calling `.then`.
      _chainForeignFuture(value);
      return;
    }
    assert(checkUnsoundType<T>(value));
    _asyncCompleteWithValueUnchecked(value);
  }

  /// Completes asynchronously with an error and stack trace.
  ///
  /// Completes with an error in a later microtask step.
  /// Sets [_isPendingComplete] to true while waiting.
  void _asyncCompleteError(Object error, StackTrace stackTrace) {
    _asyncCompleteErrorObject(AsyncError(error, stackTrace));
  }

  /// Completes asynchronously with an asynchronous error.
  ///
  /// Completes with an error in a later microtask step.
  /// Sets [_isPendingComplete] to true while waiting.
  void _asyncCompleteErrorObject(AsyncError error) {
    assert(_mayComplete); // _mayAddListener && !_isPendingComplete
    if (_resultOrListeners == null && _ignoreError) {
      _setState(_stateError, error);
      return;
    }
    _state |= _statePendingComplete;
    _zone.scheduleMicrotask(() {
      _setError(error)?.propagateResults();
    });
  }

  /// Registers a system-created result and error continuation.
  ///
  /// Used by the implementation of `await` to listen to a future.
  /// The system created listeners are pre-registered in the zone,
  /// to avoid registering the same listener more than once.
  Future<E> _thenAwait<E>(FutureOr<E> f(T value), Function onError) {
    _Future<E> result = _Future<E>();
    _addListener(_FutureListener<T, E>.thenAwait(this, result, f, onError));
    return result;
  }

  // ---------------------------------------------------------------------
  // INTERNAL API. DO NOT USE WITHOUT PERMISSION. SUBJECT TO CHANGE.

  /// Used by [_Completer] for [Completer.isComplete].
  ///
  /// Should not be used internally.
  bool get _mayComplete => (_state & _completionStateMask) == _stateIncomplete;

  /// Used by [_Completer] for [Completer.isComplete].
  ///
  /// It's a state where the completer may not complete, but the
  /// [_Future] does not contain a result ([_isComplete]) yet.
  ///
  /// Set when completing with a non-native future (waiting for a
  /// `.then` callback) or while waiting for a microtask to asyncronously
  /// complete the future.
  /// (Or if you ever complete a future with itself.)
  bool get _isPendingComplete => (_state & _statePendingComplete) != 0;

  /// The [_resultOrListeners] contains listeners.
  ///
  /// True until the future is either completed with a value,
  /// or it's chained to another native future (at which point
  /// the listeners are stored onthat other future instead).
  /// Mutually exclusive with [_isComplete] and [_isChained].
  bool get _mayAddListener =>
      _state <= (_statePendingComplete | _stateIgnoreError);

  /// The [resultOrListeners] contains another native future.
  ///
  /// This future will complete with the exact same result as
  /// the other future
  /// Mutually exclusive with [_mayAddListener] and [_isComplete].
  bool get _isChained => ((_state & _stateChained) != 0);

  /// The [resultOrListeners] contains the final result.
  ///
  /// That's either a value of type [T] or an [AsyncError].
  /// Whether it's an error can be seen from [_hasError].
  /// Mutually exclusive with [_mayAddListener] and [_isChained].
  bool get _isComplete => (_state & (_stateValue | _stateError)) != 0;
  bool get _hasError => (_state & _stateError) != 0;
  bool get _ignoreError => (_state & _stateIgnoreError) != 0;

  /// Is complete with error, and does not ignore error.
  bool get _needsHandlingError => _state == _stateError;

  Future<R> then<R>(FutureOr<R> f(T value), {Function? onError}) {
    _Future<R> result = new _Future<R>();
    Zone currentZone = result._zone;
    if (identical(currentZone, _rootZone)) {
      if (onError != null &&
          onError is! Function(Object, StackTrace) &&
          onError is! Function(Object)) {
        throw ArgumentError.value(
            onError,
            "onError",
            "Error handler must accept one Object or one Object and a StackTrace"
                " as arguments, and return a value of the returned future's type");
      }
    } else {
      f = currentZone.registerUnaryCallback<FutureOr<R>, T>(f);
      if (onError != null) {
        // This call also checks that onError is assignable to one of:
        //   dynamic Function(Object)
        //   dynamic Function(Object, StackTrace)
        onError = _registerErrorHandler(onError, currentZone);
      }
    }
    _addListener(_FutureListener<T, R>.then(this, result, f, onError));
    return result;
  }

  void _ignore() {
    // If already chained or completed, we don't check for listeners
    // locally any more.
    if (_mayAddListener) _state |= _stateIgnoreError;
  }

  Future<T> catchError(Function onError, {bool test(Object error)?}) {
    _Future<T> result = new _Future<T>();
    if (!identical(result._zone, _rootZone)) {
      onError = _registerErrorHandler(onError, result._zone);
      if (test != null) test = result._zone.registerUnaryCallback(test);
    } else {
      _checkErrorHandler(onError);
    }
    _addListener(_FutureListener<T, T>.catchError(this, result, onError, test));
    return result;
  }

  Future<T> whenComplete(dynamic action()) {
    _Future<T> result = new _Future<T>();
    var currentZone = result._zone;
    if (!identical(currentZone, _rootZone)) {
      action = currentZone.registerCallback<dynamic>(action);
    }
    _addListener(_FutureListener<T, T>.whenComplete(this, result, action));
    return result;
  }

  Stream<T> asStream() => new Stream<T>.fromFuture(this);

  /// Adds a new listener to this future.
  ///
  /// The listener was created by a call to [Future.then],
  /// [Future.catchError] or [Future.whenComplete] on this future.
  /// It contains the callbacks from that call,
  /// this future as [_FutureListener.source], and the future
  /// returned by the call as [_FutureListener.result].
  ///
  /// If this future is chained to another future, then the
  /// listener is instead added to the source future of the chain.
  /// If this future is already complete, a microtask on [_zone]
  /// is scheduled to have the result delivered.
  /// Otherwise the listener is linked into the linked list of listeners
  /// on this future.
  void _addListener(_FutureListener listener) {
    assert(identical(listener.source, this));
    assert(listener._nextListener == null);
    _Future source = this;
    if (source._isChained) {
      do {
        source = unsafeCast<_Future>(source._resultOrListeners);
        assert(source is _Future<T>);
      } while (source._isChained);
      if (source._isComplete) {
        _setState(source._state, source._resultOrListeners);
        source = this;
      }
    }
    if (source._mayAddListener) {
      source._prependListeners(listener);
      return;
    }
    assert(source._isComplete);
    assert(identical(listener.source, source));
    if (_hasError && !_zone.inSameErrorZone(listener.result._zone)) {
      // If completed with an error, and the listener is in another
      // error zone, we can discard the listener immediately.
      return;
    }
    // The chained source has completed, so copy the result here
    // instead of forwarding new listeners to the source future.
    // Handle late listeners asynchronously.
    _zone.scheduleMicrotask(listener.propagateResults);
  }

  /// Wait for a non-native future to complete and use its result.
  ///
  /// Always called with a `Future<T>`.
  ///
  /// Waits for [source] to complete, by calling `.then` on it.
  /// (If that fails, which it never should,
  /// asynchronously complete with that error instead,
  /// that way this function is always asynchronous.)
  ///
  /// Completes this future with the same result.
  ///
  /// Only intended for non-native futures.
  /// Use [_chainCoreFuture] for a [_Future].
  void _chainForeignFuture(Future<T> source) {
    assert(_mayAddListener);
    assert(!_isPendingComplete);
    assert(source is! _Future);

    // Mark the target as chained (and as such half-completed).
    _state |= _statePendingComplete;
    try {
      source.then((T value) {
        assert(_isPendingComplete);
        try {
          _setValue(value)?.propagateResults();
        } catch (error, stackTrace) {
          _setError(AsyncError(error, stackTrace))?.propagateResults();
        }
      }, onError: (Object error, StackTrace stackTrace) {
        assert(_isPendingComplete);
        _setError(AsyncError(error, stackTrace))?.propagateResults();
      });
    } catch (error, stackTrace) {
      // This only happens if the `then` call threw synchronously when given
      // valid arguments.
      // That requires a non-conforming implementation of the Future interface,
      // which should, hopefully, never happen.

      // Foreign futures are assume asynchronous, so delay the completion.
      scheduleMicrotask(() {
        _setError(AsyncError(error, stackTrace))?.propagateResults();
      });
    }
  }

  /// Take the value (when completed) of source and complete this future
  /// with that result (value or error).
  ///
  /// If the [source] is already completed,
  /// so is [this] future, and its listeners are returned.
  ///
  /// If chaining a future to itself, we now complete the future with
  /// an error, and return its listeners.
  _FutureListener? _chainCoreFuture(_Future source) {
    assert(_mayAddListener); // Not completed, not already chained.
    while (source._isChained) {
      source = unsafeCast<_Future>(source._resultOrListeners);
    }
    assert(source is _Future<T>);
    if (identical(this, source)) {
      // Completing a future with itself.
      // The future will never complete with a result.
      // We make it complete with an error instead.
      return _setError(
          AsyncError(_FutureCyclicDependencyError(this), StackTrace.empty));
    }
    if (source._isComplete) {
      return _setNativeFutureResult(source);
    }
    assert(source._mayAddListener);
    var listeners = unsafeCast<_FutureListener?>(_resultOrListeners);
    _setState(_stateChained, source);
    if (listeners != null) {
      source._prependListeners(listeners);
    }
    return null;
  }

  /// Moves a chain of [listeners] to this [_Future].
  ///
  /// The listeners are prepended to the current listeners (meaning they
  /// will be called later than existing listeners).
  ///
  /// User to chain a native future to the native future source of its result,
  /// by [chainCoreFuture] and similar code in other places.
  void _prependListeners(_FutureListener listeners) {
    assert(_mayAddListener);
    var existingListeners = unsafeCast<_FutureListener?>(_resultOrListeners);
    _FutureListener cursor = listeners;
    while (true) {
      cursor.setSourceUnchecked(this);
      var next = cursor._nextListener;
      if (next == null) {
        cursor._nextListener = existingListeners;
        break;
      }
      cursor = next;
    }
    _resultOrListeners = listeners;
  }

  /// Completes this future synchronously with a value.
  void _completeWithValue(T value) {
    assert(!_isComplete);
    _setValue(value)?.propagateResults();
  }

  /// Completes this future synchronously with a value.
  ///
  /// The value must be a [T].
  void _completeWithValueUnchecked(Object? value) {
    assert(checkUnsoundType<T>(value));
    assert(!_isComplete);
    _setValue(value)?.propagateResults();
  }

  /// Asynchronously completes this future with a native future.
  ///
  /// If the native future is already complete, a microtask is scheduled
  /// to set the result.
  /// If not, this future is chained to the other future
  /// (moving all listeners to the source, and forwarding all new
  /// listeners to the source as well, until the source completes).
  ///
  /// Helper function for [_asyncComplete]/[_asyncCompleteUnchecked].
  /// Not used internally.
  void _asyncCompleteWithNativeFuture(_Future source) {
    assert(_mayComplete); // Not completed, chained or pending.
    while (source._isChained) {
      source = unsafeCast<_Future>(source._resultOrListeners);
      assert(source is _Future<T>);
    }
    if (source._isComplete) {
      if (_resultOrListeners == null && (!source._hasError || _ignoreError)) {
        // No listeners, no need to report errors,
        // just copy the result eagerly.
        _setNativeFutureResult(source);
        return;
      }
    } else if (!identical(this, source)) {
      // Source is not complete, and not identical to this,
      // so chain directly to it.
      var listeners = unsafeCast<_FutureListener?>(_resultOrListeners);
      _setState(_stateChained, source);
      if (listeners != null) {
        source._prependListeners(listeners);
      }
      return;
    }
    // No fast path, complete later.
    _state |= _statePendingComplete;
    _zone.scheduleMicrotask(() {
      _chainCoreFuture(source)?.propagateResults();
    });
  }

  /// Asynchronously complete with a value.
  ///
  /// The value is untyped, but must be assignable to [T].
  ///
  /// Also used to implement `async` functions.
  ///
  /// Like [_asyncCompleteUnchecked], but avoids an `is Future<T>` check
  /// due to having a static guarantee on the callsite that
  /// the [value] cannot be a [Future].
  /// Should be used judiciously.
  void _asyncCompleteWithValueUnchecked(/*T*/ Object? value) {
    assert(checkUnsoundType<T>(value));
    assert(_mayAddListener);
    var listeners = _setValue(value);
    if (listeners != null) {
      _zone.scheduleMicrotask(listeners.propagateResults);
    }
  }

  /// Completes with an [AsyncError] object without downcasting.
  ///
  /// The [AsyncError] object is usually taken from another [_Future]
  /// which is completed with an error. It's known to be an [AsyncError],
  /// but is stored in a field of type `dynamic`.
  void _completeErrorUnchecked(AsyncError error) {
    assert(_mayComplete, "SetError($_state)");
    _setError(error)?.propagateResults();
  }

  /// Completes this future with a value.
  ///
  /// Returns the listeners of this future, in reverse order.
  // This method is used by async/await. (Where?)
  _FutureListener? _setValue(Object? value) {
    assert(checkUnsoundType<T>(value));
    assert(!_isComplete);
    var listeners = unsafeCast<_FutureListener?>(_resultOrListeners);

    _setState(_stateValue, value);

    return listeners;
  }

  /// Completes this future with an error.
  ///
  /// Returns the listeners of this future (in reverse order).
  /// If there are no listeners, and this future doesn't ignore errors,
  /// the error is reported as uncaught to [_zone].
  _FutureListener? _setError(AsyncError error) {
    assert(_mayAddListener); // If chained, don't call this method.

    int oldState = _state;
    var listeners = unsafeCast<_FutureListener?>(_resultOrListeners);

    _setState(_stateError, error);

    return listeners?.filterByErrorZone(_zone) ?? _onUnhandledError(oldState);
  }

  /// Reports unhandled error if the future doens't ignore unhandled errors.
  ///
  /// The [oldState] must be the [_Future._state] from before completing
  /// the future with an error.
  /// It contains the flag which says to ignore unhandled errors.
  ///
  /// Called after completing with error,
  /// and finding no listeners in the same error zone.
  ///
  /// Returns `Null` to allow it to be used after a `??` guard,
  /// since it's only called when the list of (error-zone filtered)
  /// listeners is `null`.
  Null _onUnhandledError(int oldState) {
    assert(_hasError);
    if (oldState & _stateIgnoreError == 0) {
      var error = unsafeCast<AsyncError>(_resultOrListeners);
      _zone.handleUncaughtError(error.error, error.stackTrace);
    }
    return null;
  }

  /// Completes this future with the result of the completed [source].
  ///
  /// Use [_setValue] or [_setError] instead if the type of value
  /// is known, since they can skip some checks when they know whether
  /// it's an error result or not,
  /// and use this method if completing with another completed future,
  /// without already knowing or caring whether it's an error or value.
  ///
  /// Returns the listeners of this future (in reverse order).
  /// If there are no listeners, [source] was completed with an error,
  /// and this future doesn't ignore errors,
  /// the error is reported as uncaught to [_zone].
  _FutureListener? _setNativeFutureResult(_Future source) {
    assert(_mayAddListener); // Not complete or chained.
    assert(source is _Future<T> || source._hasError);
    assert(source._isComplete);

    int oldState = _state;
    var listeners = unsafeCast<_FutureListener?>(_resultOrListeners);
    _setState(source._state, source._resultOrListeners);

    if (!_hasError) return listeners;
    return listeners?.filterByErrorZone(_zone) ?? _onUnhandledError(oldState);
  }

  /// Completes (entirely or partially) this future with [source].
  ///
  /// If [source] is a non-native future, this future is marked partially
  /// completed ([_isPendingComplete])
  /// while we wait for a result from [source].
  ///
  /// If [source] is a native [_Future], then we either copy its
  /// result (if it's completed) or chains to it (if not).
  /// Otherwise [source] must be a [T] object, and we complete
  /// this future with it as a value.
  ///
  /// Returns the listeners of this future if we complete it.
  /// (If we chaing to a native future, the listeners are moved to
  /// that future. If we have a partial/pending completion,
  /// the listeners stay on the future until we have a result.
  /// In either case, no listeners are returned.)
  ///
  /// Only used by [_FutureListener.propagate] for the results returned by the
  /// [Future.then]/[Future.catchError] callbacks.
  /// As async callback results, this future can always complete
  /// immeditely with the result.
  _FutureListener? _completeWithFutureOr(/* FutureOr<T> */ Object? source) {
    assert(checkUnsoundType<FutureOr<T>>(source));
    if (source is Future<T>) {
      var nativeSource =
          source as Object; // Demote so we can promote to _Future.
      if (nativeSource is _Future) {
        _Future nativeFuture = nativeSource; // Prevent demotion by assignment.
        while (nativeFuture._isChained) {
          nativeFuture = unsafeCast<_Future>(nativeFuture._resultOrListeners);
        }
        assert(nativeFuture is _Future<T>);
        if (nativeFuture._isComplete) {
          return _setNativeFutureResult(nativeFuture);
        }
        assert(nativeFuture._mayAddListener);
        return _chainCoreFuture(nativeFuture);
      }
      _chainForeignFuture(source);
      return null;
    }
    assert(checkUnsoundType<T>(source));
    return _setValue(source);
  }

  @pragma("vm:recognized", "other")
  @pragma("vm:entry-point")
  Future<T> timeout(Duration timeLimit, {FutureOr<T> onTimeout()?}) {
    // Use .immediate
    if (_isComplete) return new _Future<T>().._asyncComplete(this);
    // This is a VM recognised method, and the _future variable is deliberately
    // allocated in a specific slot in the closure context for stack unwinding.
    _Future<T> _future = new _Future<T>();
    Timer timer;
    if (onTimeout == null) {
      timer = new Timer(timeLimit, () {
        _future._completeError(
            TimeoutException("Future not completed", timeLimit),
            StackTrace.empty);
      });
    } else {
      Zone zone = Zone.current;
      FutureOr<T> Function() onTimeoutHandler =
          zone.registerCallback(onTimeout);

      timer = Timer(timeLimit, () {
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

/// Registers [errorHandler] in [_zone] if it has the correct type.
///
/// Checks that the function accepts either an [Object] and a [StackTrace]
/// or just one [Object]. Does not check the return type.
///
/// The actually returned value must be `FutureOr<R>` where `R` is the
/// value type of the future that the call will complete (either returned
/// by [Future.then] or [Future.catchError]). We check the returned value
/// dynamically because the functions are passed as arguments in positions
/// without inference, so a function expression won't infer the return type.
///
/// Throws if the signature or parameter types are not valid.
Function _registerErrorHandler(Function errorHandler, Zone zone) {
  if (errorHandler is dynamic Function(Object, StackTrace)) {
    return zone
        .registerBinaryCallback<dynamic, Object, StackTrace>(errorHandler);
  }
  if (errorHandler is dynamic Function(Object)) {
    return zone.registerUnaryCallback<dynamic, Object>(errorHandler);
  }
  throw ArgumentError.value(
      errorHandler,
      "onError",
      "Error handler must accept one Object or one Object and a StackTrace"
          " as arguments, and return a value of the returned future's type");
}

/// Checks the type of an error handler.
///
/// Checks that the function accepts either an [Object] and a [StackTrace]
/// or just one [Object]. Does not check the return type.
///
/// The actually returned value must be `FutureOr<R>` where `R` is the
/// value type of the future that the call will complete (either returned
/// by [Future.then] or [Future.catchError]). We check the returned value
/// dynamically because the functions are passed as arguments in positions
/// without inference, so a function expression won't infer the return type.
///
/// Throws if the signature or parameter types are not valid.
void _checkErrorHandler(Function errorHandler) {
  if (errorHandler is! dynamic Function(Object, StackTrace) &&
      errorHandler is! dynamic Function(Object)) {
    throw ArgumentError.value(
        errorHandler,
        "onError",
        "Error handler must accept one Object or one Object and a StackTrace"
            " as arguments, and return a value of the returned future's type");
  }
}

/// Runs the [zone.errorCallback] on the [error] and [stackTrace].
///
/// Returns an [AsyncError] containing either the returned error,
/// or if [Zone.errorCallback] returned `null`,
/// then an object containing the original error and stacktrace,
/// or a default stack trace if [stackTrace] is `null`.
AsyncError _interceptSyncError(
        Zone zone, Object error, StackTrace? stackTrace) =>
    zone.errorCallback(error, stackTrace) ?? AsyncError(error, stackTrace);

/// Thrown when a [_Future] is completed with itself, leading to a deadlock.
class _FutureCyclicDependencyError extends UnsupportedError {
  final Future future;
  _FutureCyclicDependencyError(this.future)
      : super("Future completed with itself");
}
