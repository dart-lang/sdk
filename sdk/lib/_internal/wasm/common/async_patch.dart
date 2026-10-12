import 'dart:_internal' show patch;

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
    if (_hasSuspended) {
      _future._completeError(error, stackTrace);
    } else {
      _future._asyncCompleteError(error, stackTrace);
    }
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
  operand.then(
    (value) {
      suspendState._resume.call(suspendState, value, null, null);
    },
    onError: (exception, stackTrace) {
      suspendState._resume.call(suspendState, null, exception, stackTrace);
    },
  );
  suspendState._hasSuspended = true;
}

@pragma("wasm:entry-point")
void _awaitHelperWithTypeCheck<T>(
  _AsyncSuspendState suspendState,
  Object? operand,
) {
  if (operand is! Future<T>) {
    scheduleMicrotask(
      () => suspendState._resume.call(suspendState, operand, null, null),
    );
  } else {
    operand.then(
      (Object? value) {
        suspendState._resume.call(suspendState, value, null, null);
      },
      onError: (exception, stackTrace) {
        suspendState._resume.call(suspendState, null, exception, stackTrace);
      },
    );
  }
  suspendState._hasSuspended = true;
}
