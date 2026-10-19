import 'dart:_internal' show patch, unsafeCast;

import 'dart:_wasm';

// Modular kernel transformer will make calls to this method be re-directed to
// call dart:core:Error._trySetStackTrace instead.
@patch
external void _trySetStackTrace(Object error, StackTrace stackTrace);

typedef _AsyncResumeFun =
    WasmFunction<
      void Function(
        _AsyncSuspendState,
        // Value of the last `await`
        Object?,
        // If the last `await` threw an error, the error value
        Object?,
        // If the last `await` threw an error, the stack trace
        StackTrace?,
      )
    >;

@pragma("wasm:entry-point")
class _AsyncSuspendState {
  // The inner function.
  //
  // Note: this function never throws. Any uncaught exceptions are passed to
  // `_completeError`.
  @pragma("wasm:entry-point")
  final _AsyncResumeFun _resume;

  // Context containing the local variables of the function.
  @pragma("wasm:entry-point")
  WasmStructRef? _context;

  // CFG target index for the next resumption.
  @pragma("wasm:entry-point")
  WasmI32 _targetIndex;

  // The future that will be completed.
  @pragma("wasm:entry-point")
  final _Future _future;

  // When a called function throws this stores the thrown exception. Used when
  // performing type tests in catch blocks.
  @pragma("wasm:entry-point")
  Object? _currentException;

  // When a called function throws this stores the stack trace.
  @pragma("wasm:entry-point")
  StackTrace? _currentExceptionStackTrace;

  // When running finalizers and the continuation is "return", the value to
  // return after the last finalizer.
  //
  // Used in finalizer blocks.
  @pragma("wasm:entry-point")
  Object? _currentReturnValue;

  bool _hasSuspended = false;

  void Function(Object?)? _thenCallback;

  void Function(Object, StackTrace)? _errorCallback;

  @pragma("wasm:entry-point")
  _AsyncSuspendState(this._resume, this._context, this._future)
    : _targetIndex = WasmI32.fromInt(0),
      _currentException = null,
      _currentExceptionStackTrace = null,
      _currentReturnValue = null;

  @pragma("wasm:entry-point")
  void _complete(Object? value) {
    // NOTE: We don't check `_hasSuspended`:
    //   * if the body completes synchronously, the very next thing we'll
    //     synchronously do is return the future from the call before running
    //     any microtasks (so there are no listeners yet). `_chainFuture` will
    //     not complete with an error synchronously, and completing with a value
    //     synchronously is safe.
    //   * if the body completes after a suspend point, we will already be in a
    //     microtask queue and can run any listener callbacks immediately.
    if (value is Future) {
      _future._chainFutureOrCompleteWithValue(value);
    } else {
      _future._completeWithValue(value);
    }
  }

  @pragma("wasm:entry-point")
  void _completeError(Object error, StackTrace stackTrace) {
    // If throwing synchronously, delay error completion to a microtask so the
    // caller can attach an error handler before the error is reported as
    // uncaught.
    final asyncError = _interceptCaughtError(error, stackTrace);
    if (_hasSuspended) {
      _future._completeErrorObject(asyncError);
    } else {
      _future._asyncCompleteErrorObject(asyncError);
    }
  }

  @pragma("wasm:prefer-inline")
  ZoneUnaryCallback<void, Object?> _ensureAsyncCallbacks() =>
      _thenCallback ?? _createAsyncCallbacks();

  ZoneUnaryCallback<void, Object?> _createAsyncCallbacks() {
    // Only register (not bind) the callbacks; `Future.then` / `_thenAwait`
    // is responsible for invoking them in the right zone via `zone.run*`.
    final currentZone = Zone._current;
    final thenCallback = currentZone.registerUnaryCallback<void, Object?>((
      value,
    ) {
      _resume.call(this, value, null, null);
    });
    _thenCallback = thenCallback;
    _errorCallback = currentZone
        .registerBinaryCallback<void, Object, StackTrace>((
          exception,
          stackTrace,
        ) {
          _resume.call(this, null, exception, stackTrace);
        });
    return thenCallback;
  }
}

@pragma("wasm:entry-point")
_AsyncSuspendState _newAsyncSuspendState(
  _AsyncResumeFun resume,
  WasmStructRef? context,
  _Future future,
) => _AsyncSuspendState(resume, context, future);

@pragma("wasm:entry-point")
_Future<T> _makeFuture<T>() => _Future<T>();

@pragma("wasm:entry-point")
void _awaitHelper(_AsyncSuspendState suspendState, Future operand) {
  final thenCallback = suspendState._ensureAsyncCallbacks();
  if (operand is _Future) {
    if (operand._isComplete && !operand._hasError) {
      _scheduleValueMicrotask(
        operand._zone,
        thenCallback,
        operand._resultOrListeners,
      );
    } else {
      operand._thenAwait<void>(
        thenCallback,
        unsafeCast<ZoneBinaryCallback<void, Object, StackTrace>>(
          suspendState._errorCallback,
        ),
      );
    }
  } else {
    operand.then<void>(thenCallback, onError: suspendState._errorCallback);
  }
  suspendState._hasSuspended = true;
}

@pragma("wasm:entry-point")
void _awaitHelperWithTypeCheck<T>(
  _AsyncSuspendState suspendState,
  Object? operand,
) {
  if (operand is Future<T>) {
    return _awaitHelper(suspendState, operand);
  }
  final thenCallback = suspendState._ensureAsyncCallbacks();
  _scheduleValueMicrotask(Zone._current, thenCallback, operand);
  suspendState._hasSuspended = true;
}

void _scheduleValueMicrotask(
  Zone scheduleZone,
  ZoneUnaryCallback<void, Object?> thenCallback,
  Object? value,
) {
  final zone = Zone._current;
  scheduleZone.scheduleMicrotask(() {
    zone.runUnary(thenCallback, value);
  });
}
