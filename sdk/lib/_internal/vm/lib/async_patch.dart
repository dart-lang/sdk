// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Note: the VM concatenates all patch files into a single patch file. This
/// file is the first patch in "dart:async" which contains all the imports used
/// by patches of that library. We plan to change this when we have a shared
/// front end and simply use parts.

import "dart:_internal" show VMLibraryHooks, patch, unsafeCast;

/// These are the additional parts of this patch library:
// part "deferred_load_patch.dart";
// part "schedule_microtask_patch.dart";
// part "timer_patch.dart";

// Equivalent of calling FATAL from C++ code.
@pragma("vm:external-name", "DartAsync_fatal")
external _fatal(msg);

// We need to pass the value as first argument and leave the second and third
// arguments empty (used for error handling).
@pragma("vm:recognized", "other")
dynamic Function(dynamic) _asyncThenWrapperHelper(
    dynamic Function(dynamic, dynamic) continuation) {
  @pragma("vm:invisible")
  dynamic thenWrapper(dynamic arg) => continuation(arg, /*stack_trace=*/ null);

  // Any function that is used as an asynchronous callback must be registered
  // in the current Zone. Normally, this is done by the future when a
  // callback is registered (for example with `.then` or `.catchError`). In our
  // case we want to reuse the same callback multiple times and therefore avoid
  // the multiple registrations. For our internal futures (`_Future`) we can
  // use the shortcut-version of `.then`, and skip the registration. However,
  // that means that the continuation must be registered by us.
  //
  // Furthermore, we know that the root-zone doesn't actually do anything and
  // we can therefore skip the registration call for it.
  //
  // Note, that the continuation accepts up to three arguments. If the current
  // zone is the root zone, we don't wrap the continuation, and a bad
  // `Future` implementation could potentially invoke the callback with the
  // wrong number of arguments.
  final currentZone = Zone._current;
  if (identical(currentZone, _rootZone) ||
      identical(currentZone._registerUnaryCallback,
          _rootZone._registerUnaryCallback)) {
    return thenWrapper;
  }
  return currentZone.registerUnaryCallback<dynamic, dynamic>(thenWrapper);
}

// We need to pass the exception and stack trace objects as second and third
// parameter to the continuation.
dynamic Function(Object, StackTrace) _asyncErrorWrapperHelper(
    dynamic Function(dynamic, StackTrace) errorCallback) {
  final currentZone = Zone._current;
  if (identical(currentZone, _rootZone) ||
      identical(currentZone._registerBinaryCallback,
          _rootZone._registerBinaryCallback)) {
    return errorCallback;
  }
  return currentZone
      .registerBinaryCallback<dynamic, Object, StackTrace>(errorCallback);
}

/// Registers the [thenCallback] and [errorCallback] on the given [object].
///
/// If [object] is not a future, then it is wrapped into one.
///
/// Returns the result of registering with `.then`.
Future _awaitHelper(var object, dynamic Function(dynamic) thenCallback,
    dynamic Function(Object, StackTrace) errorCallback) {
  _Future future;
  if (object is _Future) {
    future = object;
  } else if (object is! Future) {
    future = new _Future().._setValue(object);
  } else {
    return object.then(thenCallback, onError: errorCallback);
  }
  // `object` is a `_Future`.
  //
  // Since the callbacks have been registered in the current zone (see
  // [_asyncThenWrapperHelper] and [_asyncErrorWrapperHelper]), we can avoid
  // another registration and directly invoke the no-zone-registration `.then`.
  //
  // We can only do this for our internal futures (the default implementation of
  // all futures that are constructed by the `dart:async` library).
  return future._thenAwait<dynamic>(thenCallback, errorCallback);
}

@pragma("vm:entry-point", "call")
void _asyncStarMoveNextHelper(var stream) {
  if (stream is! _StreamImpl) {
    return;
  }
  // stream is a _StreamImpl.
  final generator = stream._generator;
  if (generator == null) {
    // No generator registered, this isn't an async* Stream.
    return;
  }
  _moveNextDebuggerStepCheck(generator);
}

// _AsyncStarStreamController is used by the compiler to implement
// async* generator functions.
@pragma("vm:entry-point")
class _AsyncStarStreamController<T> {
  @pragma("vm:entry-point")
  StreamController<T> controller;
  @pragma("vm:entry-point")
  Function? asyncStarBody;
  bool isAdding = false;
  bool onListenReceived = false;
  bool isScheduled = false;
  bool isSuspendedAtYield = false;
  _Future? cancellationFuture = null;

  /// Argument passed to the generator when it is resumed after an addStream.
  ///
  /// `true` if the generator should exit after `yield*` resumes.
  /// `false` if the generator should continue after `yield*` resumes.
  /// `null` otherwies.
  bool? continuationArgument = null;

  Stream<T> get stream {
    final Stream<T> local = controller.stream;
    if (local is _StreamImpl<T>) {
      local._generator = asyncStarBody!;
    }
    return local;
  }

  void runBody() {
    isScheduled = false;
    isSuspendedAtYield = false;
    final bool? argument = continuationArgument;
    continuationArgument = null;
    asyncStarBody!(argument, null);
  }

  void scheduleGenerator() {
    if (isScheduled || controller.isPaused || isAdding) {
      return;
    }
    isScheduled = true;
    scheduleMicrotask(runBody);
  }

  // Adds element to stream, returns true if the caller should terminate
  // execution of the generator.
  //
  // TODO(hausner): Per spec, the generator should be suspended before
  // exiting when the stream is closed. We could add a getter like this:
  // get isCancelled => controller.hasListener;
  // The generator would translate a 'yield e' statement to
  // controller.add(e);
  // suspend;
  // if (controller.isCancelled) return;
  @pragma("vm:entry-point", "call")
  bool add(T event) {
    if (!onListenReceived) _fatal("yield before stream is listened to");
    if (isSuspendedAtYield) _fatal("unexpected yield");
    controller.add(event);
    if (!controller.hasListener) {
      return true;
    }

    scheduleGenerator();
    isSuspendedAtYield = true;
    return false;
  }

  // Adds the elements of stream into this controller's stream.
  // The generator will be scheduled again when all of the
  // elements of the added stream have been consumed.
  @pragma("vm:entry-point", "call")
  void addStream(Stream<T> stream) {
    if (!onListenReceived) _fatal("yield before stream is listened to");

    if (exitAfterYieldStarIfCancelled()) return;

    isAdding = true;
    final whenDoneAdding = controller.addStream(stream, cancelOnError: false);
    whenDoneAdding.then((_) {
      isAdding = false;
      if (exitAfterYieldStarIfCancelled()) return;
      resumeNormallyAfterYieldStar();
    });
  }

  /// Schedules the generator to exit after `yield*` if stream was cancelled.
  ///
  /// Returns `true` if generator is told to exit and `false` otherwise.
  bool exitAfterYieldStarIfCancelled() {
    // If consumer cancelled subscription we should tell async* generator to
    // finish (i.e. run finally clauses and return).
    if (!controller.hasListener) {
      continuationArgument = true;
      scheduleGenerator();
      return true;
    }
    return false;
  }

  /// Schedules the generator to resume normally after `yield*`.
  void resumeNormallyAfterYieldStar() {
    continuationArgument = false;
    scheduleGenerator();
    if (!isScheduled) isSuspendedAtYield = true;
  }

  void addError(Object error, StackTrace stackTrace) {
    // TODO(40614): Remove once non-nullability is sound.
    ArgumentError.checkNotNull(error, "error");
    final future = cancellationFuture;
    if ((future != null) && future._mayComplete) {
      // If the stream has been cancelled, complete the cancellation future
      // with the error.
      future._completeError(error, stackTrace);
      return;
    }
    // If stream is cancelled, tell caller to exit the async generator.
    if (!controller.hasListener) return;
    controller.addError(error, stackTrace);
    // No need to schedule the generator body here. This code is only
    // called from the catch clause of the implicit try-catch-finally
    // around the generator body. That is, we are on the error path out
    // of the generator and do not need to run the generator again.
  }

  close() {
    final future = cancellationFuture;
    if ((future != null) && future._mayComplete) {
      // If the stream has been cancelled, complete the cancellation future
      // with the error.
      future._completeWithValue(null);
    }
    controller.close();
  }

  _AsyncStarStreamController(this.asyncStarBody)
      : controller = new StreamController(sync: true) {
    controller.onListen = this.onListen;
    controller.onResume = this.onResume;
    controller.onCancel = this.onCancel;
  }

  onListen() {
    assert(!onListenReceived);
    onListenReceived = true;
    scheduleGenerator();
  }

  onResume() {
    if (isSuspendedAtYield) {
      scheduleGenerator();
    }
  }

  onCancel() {
    if (controller.isClosed) {
      return null;
    }
    if (cancellationFuture == null) {
      cancellationFuture = new _Future();
      // Only resume the generator if it is suspended at a yield.
      // Cancellation does not affect an async generator that is
      // suspended at an await.
      if (isSuspendedAtYield) {
        scheduleGenerator();
      }
    }
    return cancellationFuture;
  }
}

@patch
class _StreamImpl<T> {
  /// The closure implementing the async-generator body that is creating events
  /// for this stream.
  Function? _generator;
}

@pragma("vm:entry-point", "call")
void _completeOnAsyncReturn(_Future _future, Object? value, bool is_sync) {
  // The first awaited expression is invoked sync. so complete is async. to
  // allow then and error handlers to be attached.
  // async_jump_var=0 is prior to first await, =1 is first await.
  if (!is_sync || value is Future) {
    _future._asyncCompleteUnchecked(value);
  } else {
    _future._completeWithValue(value);
  }
}

@pragma("vm:entry-point", "call")
void _completeWithNoFutureOnAsyncReturn(
    _Future _future, Object? value, bool is_sync) {
  // The first awaited expression is invoked sync. so complete is async. to
  // allow then and error handlers to be attached.
  // async_jump_var=0 is prior to first await, =1 is first await.
  if (!is_sync) {
    _future._asyncCompleteUncheckedNoFuture(value);
  } else {
    _future._completeWithValue(value);
  }
}

@pragma("vm:entry-point", "call")
void _completeOnAsyncError(
    _Future _future, Object e, StackTrace st, bool is_sync) {
  if (!is_sync) {
    _future._asyncCompleteError(e, st);
  } else {
    _future._completeError(e, st);
  }
}

@pragma("vm:external-name", "AsyncStarMoveNext_debuggerStepCheck")
external void _moveNextDebuggerStepCheck(Function async_op);

@pragma("vm:entry-point")
class _SuspendState {
  static const bool _trace = false;

  @pragma("vm:entry-point", "call")
  @pragma("vm:invisible")
  static Object? _initAsync<T>() {
    if (_trace) print('_initAsync<$T>');
    return _Future<T>();
  }

  @pragma("vm:invisible")
  @pragma("vm:recognized", "other")
  void _createAsyncCallbacks() {
    if (_trace) print('_createAsyncCallbacks');

    @pragma("vm:invisible")
    thenCallback(value) {
      if (_trace) print('thenCallback (this=$this, value=$value)');
      _resume(value, null, null);
    }

    @pragma("vm:invisible")
    errorCallback(exception, stackTrace) {
      if (_trace) {
        print('errorCallback (this=$this, '
            'exception=$exception, stackTrace=$stackTrace)');
      }
      _resume(null, exception, stackTrace);
    }

    final currentZone = Zone._current;
    if (identical(currentZone, _rootZone) ||
        identical(currentZone._registerUnaryCallback,
            _rootZone._registerUnaryCallback)) {
      _thenCallback = thenCallback;
    } else {
      _thenCallback =
          currentZone.registerUnaryCallback<dynamic, dynamic>(thenCallback);
    }
    if (identical(currentZone, _rootZone) ||
        identical(currentZone._registerBinaryCallback,
            _rootZone._registerBinaryCallback)) {
      _errorCallback = errorCallback;
    } else {
      _errorCallback = currentZone
          .registerBinaryCallback<dynamic, Object, StackTrace>(errorCallback);
    }
  }

  @pragma("vm:entry-point", "call")
  @pragma("vm:invisible")
  Object? _await(Object? object) {
    if (_trace) print('_awaitAsync (object=$object)');
    if (_thenCallback == null) {
      _createAsyncCallbacks();
    }
    _awaitHelper(object, unsafeCast<dynamic Function(dynamic)>(_thenCallback),
        unsafeCast<dynamic Function(Object, StackTrace)>(_errorCallback));
    return _functionData;
  }

  @pragma("vm:entry-point", "call")
  @pragma("vm:invisible")
  static Future _returnAsync(Object suspendState, Object? returnValue) {
    if (_trace) {
      print('_returnAsync (suspendState=$suspendState, '
          'returnValue=$returnValue)');
    }
    _Future future;
    bool isSync = true;
    if (suspendState is _SuspendState) {
      future = unsafeCast<_Future>(suspendState._functionData);
    } else {
      future = unsafeCast<_Future>(suspendState);
      isSync = false;
    }
    _completeOnAsyncReturn(future, returnValue, isSync);
    return future;
  }

  @pragma("vm:entry-point", "call")
  @pragma("vm:invisible")
  static Future _returnAsyncNotFuture(
      Object suspendState, Object? returnValue) {
    if (_trace) {
      print('_returnAsyncNotFuture (suspendState=$suspendState, '
          'returnValue=$returnValue)');
    }
    _Future future;
    bool isSync = true;
    if (suspendState is _SuspendState) {
      future = unsafeCast<_Future>(suspendState._functionData);
    } else {
      future = unsafeCast<_Future>(suspendState);
      isSync = false;
    }
    _completeWithNoFutureOnAsyncReturn(future, returnValue, isSync);
    return future;
  }

  @pragma("vm:entry-point", "call")
  @pragma("vm:invisible")
  static Object? _initAsyncStar<T>() {
    if (_trace) print('_initAsyncStar<$T>');
    return _AsyncStarStreamController<T>(null);
  }

  @pragma("vm:invisible")
  @pragma("vm:recognized", "other")
  _createAsyncStarCallback(_AsyncStarStreamController controller) {
    controller.asyncStarBody = (value, _) {
      if (_trace) print('asyncStarBody callback (value=$value)');
      _resume(value, null, null);
    };
  }

  @pragma("vm:entry-point", "call")
  @pragma("vm:invisible")
  Object? _yieldAsyncStar(Object? object) {
    final controller = unsafeCast<_AsyncStarStreamController>(_functionData);
    if (controller.asyncStarBody == null) {
      _createAsyncStarCallback(controller);
      return controller.stream;
    }
    return null;
  }

  @pragma("vm:entry-point", "call")
  @pragma("vm:invisible")
  static void _returnAsyncStar(Object suspendState, Object? returnValue) {
    if (_trace) {
      print('_returnAsyncStar (suspendState=$suspendState, '
          'returnValue=$returnValue)');
    }
    final controller = unsafeCast<_AsyncStarStreamController>(
        unsafeCast<_SuspendState>(suspendState)._functionData);
    controller.close();
  }

  @pragma("vm:entry-point", "call")
  @pragma("vm:invisible")
  static Object? _handleException(
      Object suspendState, Object exception, StackTrace stackTrace) {
    if (_trace) {
      print('_handleException (suspendState=$suspendState, '
          'exception=$exception, stackTrace=$stackTrace)');
    }
    Object? functionData;
    bool isSync = true;
    if (suspendState is _SuspendState) {
      functionData = suspendState._functionData;
    } else {
      functionData = suspendState;
      isSync = false;
    }
    if (functionData is _Future) {
      // async function.
      _completeOnAsyncError(functionData, exception, stackTrace, isSync);
    } else if (functionData is _AsyncStarStreamController) {
      // async* function.
      functionData.addError(exception, stackTrace);
      functionData.close();
    } else {
      throw 'Unexpected function data ${functionData.runtimeType} $functionData';
    }
    return functionData;
  }

  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  external set _functionData(Object value);

  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  external Object get _functionData;

  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  external set _thenCallback(Function? value);

  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  external Function? get _thenCallback;

  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  external set _errorCallback(Function value);

  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  external Function get _errorCallback;

  @pragma("vm:recognized", "other")
  @pragma("vm:never-inline")
  external void _resume(
      Object? value, Object? exception, StackTrace? stackTrace);
}
