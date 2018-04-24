// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Patch file for the dart:async library.

import 'dart:_js_helper'
    show
        patch,
        ExceptionAndStackTrace,
        Primitives,
        convertDartClosureToJS,
        getTraceFromException,
        requiresPreamble,
        wrapException,
        unwrapException;
import 'dart:_isolate_helper'
    show IsolateNatives, TimerImpl, leaveJsAsync, enterJsAsync, isWorker;

import 'dart:_foreign_helper' show JS, JS_GET_FLAG;

import 'dart:_async_await_error_codes' as async_error_codes;

import "dart:collection" show IterableBase;

@patch
class _AsyncRun {
  @patch
  static void _scheduleImmediate(void callback()) {
    _scheduleImmediateClosure(callback);
  }

  // Lazily initialized.
  static final Function _scheduleImmediateClosure =
      _initializeScheduleImmediate();

  static Function _initializeScheduleImmediate() {
    requiresPreamble();
    if (JS('', 'self.scheduleImmediate') != null) {
      return _scheduleImmediateJsOverride;
    }
    if (JS('', 'self.MutationObserver') != null &&
        JS('', 'self.document') != null) {
      // Use mutationObservers.
      var div = JS('', 'self.document.createElement("div")');
      var span = JS('', 'self.document.createElement("span")');
      var storedCallback;

      internalCallback(_) {
        leaveJsAsync();
        var f = storedCallback;
        storedCallback = null;
        f();
      }

      var observer = JS('', 'new self.MutationObserver(#)',
          convertDartClosureToJS(internalCallback, 1));
      JS('', '#.observe(#, { childList: true })', observer, div);

      return (void callback()) {
        assert(storedCallback == null);
        enterJsAsync();
        storedCallback = callback;
        // Because of a broken shadow-dom polyfill we have to change the
        // children instead a cheap property.
        // See https://github.com/Polymer/ShadowDOM/issues/468
        JS('', '#.firstChild ? #.removeChild(#): #.appendChild(#)', div, div,
            span, div, span);
      };
    } else if (JS('', 'self.setImmediate') != null) {
      return _scheduleImmediateWithSetImmediate;
    }
    // TODO(20055): We should use DOM promises when available.
    return _scheduleImmediateWithTimer;
  }

  static void _scheduleImmediateJsOverride(void callback()) {
    internalCallback() {
      leaveJsAsync();
      callback();
    }

    ;
    enterJsAsync();
    JS('void', 'self.scheduleImmediate(#)',
        convertDartClosureToJS(internalCallback, 0));
  }

  static void _scheduleImmediateWithSetImmediate(void callback()) {
    internalCallback() {
      leaveJsAsync();
      callback();
    }

    ;
    enterJsAsync();
    JS('void', 'self.setImmediate(#)',
        convertDartClosureToJS(internalCallback, 0));
  }

  static void _scheduleImmediateWithTimer(void callback()) {
    Timer._createTimer(Duration.zero, callback);
  }
}

@patch
class DeferredLibrary {
  @patch
  Future<Null> load() {
    throw 'DeferredLibrary not supported. '
        'please use the `import "lib.dart" deferred as lib` syntax.';
  }
}

@patch
class Timer {
  @patch
  static Timer _createTimer(Duration duration, void callback()) {
    int milliseconds = duration.inMilliseconds;
    if (milliseconds < 0) milliseconds = 0;
    return new TimerImpl(milliseconds, callback);
  }

  @patch
  static Timer _createPeriodicTimer(
      Duration duration, void callback(Timer timer)) {
    int milliseconds = duration.inMilliseconds;
    if (milliseconds < 0) milliseconds = 0;
    return new TimerImpl.periodic(milliseconds, callback);
  }
}

class _AsyncAwaitCompleter<T> implements Completer<T> {
  final _completer = new Completer<T>.sync();
  bool isSync;

  _AsyncAwaitCompleter() : isSync = false;

  void complete([FutureOr<T> value]) {
    if (isSync) {
      _completer.complete(value);
    } else if (value is Future<T>) {
      value.then(_completer.complete, onError: _completer.completeError);
    } else {
      scheduleMicrotask(() {
        _completer.complete(value);
      });
    }
  }

  void completeError(e, [st]) {
    if (isSync) {
      _completer.completeError(e, st);
    } else {
      scheduleMicrotask(() {
        _completer.completeError(e, st);
      });
    }
  }

  Future<T> get future => _completer.future;
  bool get isCompleted => _completer.isCompleted;
}

/// Initiates the computation of an `async` function and starts the body
/// synchronously.
///
/// Used as part of the runtime support for the async/await transformation.
///
/// This function sets up the first call into the transformed [bodyFunction].
/// Independently, it takes the [completer] and returns the future of the
/// completer for convenience of the transformed code.
dynamic _asyncStartSync(
    _WrappedAsyncBody bodyFunction, _AsyncAwaitCompleter completer) {
  bodyFunction(async_error_codes.SUCCESS, null);
  completer.isSync = true;
  return completer.future;
}

/// Initiates the computation of an `async` function.
///
/// Used as part of the runtime support for the async/await transformation.
///
/// This function sets up the first call into the transformed [bodyFunction].
/// Independently, it takes the [completer] and returns the future of the
/// completer for convenience of the transformed code.
dynamic _asyncStart(_WrappedAsyncBody bodyFunction, Completer completer) {
  // TODO(sra): Specialize this implementation of `await null`.
  _awaitOnObject(null, bodyFunction);
  return completer.future;
}

/// Performs the `await` operation of an `async` function.
///
/// Used as part of the runtime support for the async/await transformation.
///
/// Arranges for [bodyFunction] to be called when the future or value [object]
/// is completed with a code [async_error_codes.SUCCESS] or
/// [async_error_codes.ERROR] depending on the success of the future.
dynamic _asyncAwait(dynamic object, _WrappedAsyncBody bodyFunction) {
  _awaitOnObject(object, bodyFunction);
}

/// Completes the future of an `async` function.
///
/// Used as part of the runtime support for the async/await transformation.
///
/// This function is used when the `async` function returns (explicitly or
/// implicitly).
dynamic _asyncReturn(dynamic object, Completer completer) {
  completer.complete(object);
}

/// Completes the future of an `async` function with an error.
///
/// Used as part of the runtime support for the async/await transformation.
///
/// This function is used when the `async` function re-throws an exception.
dynamic _asyncRethrow(dynamic object, Completer completer) {
  // The error is a js-error.
  completer.completeError(
      unwrapException(object), getTraceFromException(object));
}

/// Awaits on the given [object].
///
/// If the [object] is a Future, registers on it, otherwise wraps it into a
/// future first.
///
/// The [bodyFunction] argument is the continuation that should be invoked
/// when the future completes.
void _awaitOnObject(object, _WrappedAsyncBody bodyFunction) {
  Function thenCallback =
      (result) => bodyFunction(async_error_codes.SUCCESS, result);

  Function errorCallback = (dynamic error, StackTrace stackTrace) {
    ExceptionAndStackTrace wrappedException =
        new ExceptionAndStackTrace(error, stackTrace);
    bodyFunction(async_error_codes.ERROR, wrappedException);
  };

  if (object is _Future) {
    // We can skip the zone registration, since the bodyFunction is already
    // registered (see [_wrapJsFunctionForAsync]).
    object._thenNoZoneRegistration(thenCallback, errorCallback);
  } else if (object is Future) {
    object.then(thenCallback, onError: errorCallback);
  } else {
    _Future future = new _Future();
    future._setValue(object);
    // We can skip the zone registration, since the bodyFunction is already
    // registered (see [_wrapJsFunctionForAsync]).
    future._thenNoZoneRegistration(thenCallback, null);
  }
}

typedef void _WrappedAsyncBody(int errorCode, dynamic result);

_WrappedAsyncBody _wrapJsFunctionForAsync(dynamic /* js function */ function) {
  var protected = JS(
      '',
      """
        (function (fn, ERROR) {
          // Invokes [function] with [errorCode] and [result].
          //
          // If (and as long as) the invocation throws, calls [function] again,
          // with an error-code.
          return function(errorCode, result) {
            while (true) {
              try {
                fn(errorCode, result);
                break;
              } catch (error) {
                result = error;
                errorCode = ERROR;
              }
            }
          }
        })(#, #)""",
      function,
      async_error_codes.ERROR);

  return Zone.current.registerBinaryCallback((int errorCode, dynamic result) {
    JS('', '#(#, #)', protected, errorCode, result);
  });
}

/// Implements the runtime support for async* functions.
///
/// Called by the transformed function for each original return, await, yield,
/// yield* and before starting the function.
///
/// When the async* function wants to return it calls this function with
/// [asyncBody] == [async_error_codes.SUCCESS], the asyncStarHelper takes this
/// as signal to close the stream.
///
/// When the async* function wants to signal that an uncaught error was thrown,
/// it calls this function with [asyncBody] == [async_error_codes.ERROR],
/// the streamHelper takes this as signal to addError [object] to the
/// [controller] and close it.
///
/// If the async* function wants to do a yield or yield*, it calls this function
/// with [object] being an [IterationMarker].
///
/// In the case of a yield or yield*, if the stream subscription has been
/// canceled, schedules [asyncBody] to be called with
/// [async_error_codes.STREAM_WAS_CANCELED].
///
/// If [object] is a single-yield [IterationMarker], adds the value of the
/// [IterationMarker] to the stream. If the stream subscription has been
/// paused, return early. Otherwise schedule the helper function to be
/// executed again.
///
/// If [object] is a yield-star [IterationMarker], starts listening to the
/// yielded stream, and adds all events and errors to our own controller (taking
/// care if the subscription has been paused or canceled) - when the sub-stream
/// is done, schedules [asyncBody] again.
///
/// If the async* function wants to do an await it calls this function with
/// [object] not an [IterationMarker].
///
/// If [object] is not a [Future], it is wrapped in a `Future.value`.
/// The [asyncBody] is called on completion of the future (see [asyncHelper].
void _asyncStarHelper(
    dynamic object,
    dynamic /* int | _WrappedAsyncBody */ bodyFunctionOrErrorCode,
    _AsyncStarStreamController controller) {
  if (identical(bodyFunctionOrErrorCode, async_error_codes.SUCCESS)) {
    // This happens on return from the async* function.
    if (controller.isCanceled) {
      controller.cancelationCompleter.complete();
    } else {
      controller.close();
    }
    return;
  } else if (identical(bodyFunctionOrErrorCode, async_error_codes.ERROR)) {
    // The error is a js-error.
    if (controller.isCanceled) {
      controller.cancelationCompleter.completeError(
          unwrapException(object), getTraceFromException(object));
    } else {
      controller.addError(
          unwrapException(object), getTraceFromException(object));
      controller.close();
    }
    return;
  }

  if (object is _IterationMarker) {
    if (controller.isCanceled) {
      bodyFunctionOrErrorCode(async_error_codes.STREAM_WAS_CANCELED, null);
      return;
    }
    if (object.state == _IterationMarker.YIELD_SINGLE) {
      controller.add(object.value);

      scheduleMicrotask(() {
        if (controller.isPaused) {
          // We only suspend the thread inside the microtask in order to allow
          // listeners on the output stream to pause in response to the just
          // output value, and have the stream immediately stop producing.
          controller.isSuspended = true;
          return;
        }
        bodyFunctionOrErrorCode(null, async_error_codes.SUCCESS);
      });
      return;
    } else if (object.state == _IterationMarker.YIELD_STAR) {
      Stream stream = object.value;
      // Errors of [stream] are passed though to the main stream. (see
      // [AsyncStreamController.addStream]).
      // TODO(sigurdm): The spec is not very clear here. Clarify with Gilad.
      controller.addStream(stream).then((_) {
        // No check for isPaused here because the spec 17.16.2 only
        // demands checks *before* each element in [stream] not after the last
        // one. On the other hand we check for isCanceled, as that check happens
        // after insertion of each element.
        int errorCode = controller.isCanceled
            ? async_error_codes.STREAM_WAS_CANCELED
            : async_error_codes.SUCCESS;
        bodyFunctionOrErrorCode(errorCode, null);
      });
      return;
    }
  }

  _awaitOnObject(object, bodyFunctionOrErrorCode);
}

Stream _streamOfController(_AsyncStarStreamController controller) {
  return controller.stream;
}

/// A wrapper around a [StreamController] that keeps track of the state of
/// the execution of an async* function.
/// It can be in 1 of 3 states:
///
/// - running/scheduled
/// - suspended
/// - canceled
///
/// If yielding while the subscription is paused it will become suspended. And
/// only resume after the subscription is resumed or canceled.
class _AsyncStarStreamController<T> {
  StreamController<T> controller;
  Stream get stream => controller.stream;

  /// True when the async* function has yielded while being paused.
  /// When true execution will only resume after a `onResume` or `onCancel`
  /// event.
  bool isSuspended = false;

  bool get isPaused => controller.isPaused;

  Completer cancelationCompleter = null;

  /// True after the StreamSubscription has been cancelled.
  /// When this is true, errors thrown from the async* body should go to the
  /// [cancelationCompleter] instead of adding them to [controller], and
  /// returning from the async function should complete [cancelationCompleter].
  bool get isCanceled => cancelationCompleter != null;

  add(event) => controller.add(event);

  addStream(Stream<T> stream) {
    return controller.addStream(stream, cancelOnError: false);
  }

  addError(error, stackTrace) => controller.addError(error, stackTrace);

  close() => controller.close();

  _AsyncStarStreamController(_WrappedAsyncBody body) {
    _resumeBody() {
      scheduleMicrotask(() {
        body(async_error_codes.SUCCESS, null);
      });
    }

    controller = new StreamController<T>(onListen: () {
      _resumeBody();
    }, onResume: () {
      // Only schedule again if the async* function actually is suspended.
      // Resume directly instead of scheduling, so that the sequence
      // `pause-resume-pause` will result in one extra event produced.
      if (isSuspended) {
        isSuspended = false;
        _resumeBody();
      }
    }, onCancel: () {
      // If the async* is finished we ignore cancel events.
      if (!controller.isClosed) {
        cancelationCompleter = new Completer();
        if (isSuspended) {
          // Resume the suspended async* function to run finalizers.
          isSuspended = false;
          scheduleMicrotask(() {
            body(async_error_codes.STREAM_WAS_CANCELED, null);
          });
        }
        return cancelationCompleter.future;
      }
    });
  }
}

//_makeAsyncStarController(body) {
//  return new _AsyncStarStreamController(body);
//}

class _IterationMarker {
  static const YIELD_SINGLE = 0;
  static const YIELD_STAR = 1;
  static const ITERATION_ENDED = 2;
  static const UNCAUGHT_ERROR = 3;

  final value;
  final int state;

  const _IterationMarker._(this.state, this.value);

  static yieldStar(dynamic /* Iterable or Stream */ values) {
    return new _IterationMarker._(YIELD_STAR, values);
  }

  static endOfIteration() {
    return const _IterationMarker._(ITERATION_ENDED, null);
  }

  static yieldSingle(dynamic value) {
    return new _IterationMarker._(YIELD_SINGLE, value);
  }

  static uncaughtError(dynamic error) {
    return new _IterationMarker._(UNCAUGHT_ERROR, error);
  }

  toString() => "IterationMarker($state, $value)";
}

class _SyncStarIterator<T> implements Iterator<T> {
  // _SyncStarIterator handles stepping a sync* generator body state machine.
  //
  // It also handles the stepping over 'nested' iterators to flatten yield*
  // statements. For non-sync* iterators, [_nestedIterator] contains the
  // iterator. We delegate to [_nestedIterator] when it is not `null`.
  //
  // For nested sync* iterators, [this] iterator acts on behalf of the innermost
  // nested sync* iterator. The current state machine is suspended on a stack
  // until the inner state machine ends.

  // The state machine for the innermost _SyncStarIterator.
  dynamic _body;

  // The current value, unless iterating a non-sync* nested iterator.
  T _current = null;

  // This is the nested iterator when iterating a yield* of a non-sync iterator.
  // TODO(32956): In strong-mode, yield* takes an Iterable<T> (possibly checked
  // with an implicit downcast), so change type to Iterator<T>.
  Iterator _nestedIterator = null;

  // Stack of suspended state machines when iterating a yield* of a sync*
  // iterator.
  List _suspendedBodies = null;

  _SyncStarIterator(this._body);

  T get current {
    if (_nestedIterator == null) return _current;
    return _nestedIterator.current;
  }

  _runBody() {
    // TODO(sra): Find a way to hard-wire SUCCESS and ERROR codes.
    return JS(
        '',
        '''
        // Invokes [body] with [errorCode] and [result].
        //
        // If (and as long as) the invocation throws, calls [function] again,
        // with an error-code.
        (function(body, SUCCESS, ERROR) {
          var errorValue, errorCode = SUCCESS;
          while (true) {
            try {
              return body(errorCode, errorValue);
            } catch (error) {
              errorValue = error;
              errorCode = ERROR;
            }
          }
        })(#, #, #)''',
        _body,
        async_error_codes.SUCCESS,
        async_error_codes.ERROR);
  }

  bool moveNext() {
    while (true) {
      if (_nestedIterator != null) {
        if (_nestedIterator.moveNext()) {
          return true;
        } else {
          _nestedIterator = null;
        }
      }
      var value = _runBody();
      if (value is _IterationMarker) {
        int state = value.state;
        if (state == _IterationMarker.ITERATION_ENDED) {
          if (_suspendedBodies == null || _suspendedBodies.isEmpty) {
            _current = null;
            // Rely on [_body] to repeatedly return `ITERATION_ENDED`.
            return false;
          }
          // Resume the innermost suspended iterator.
          _body = _suspendedBodies.removeLast();
          continue;
        } else if (state == _IterationMarker.UNCAUGHT_ERROR) {
          // Rely on [_body] to repeatedly return `UNCAUGHT_ERROR`.
          // This is a wrapped exception, so we use JavaScript throw to throw
          // it.
          JS('', 'throw #', value.value);
        } else {
          assert(state == _IterationMarker.YIELD_STAR);
          Iterator inner = value.value.iterator;
          if (inner is _SyncStarIterator) {
            // Suspend the current state machine and start acting on behalf of
            // the nested state machine.
            //
            // TODO(sra): Recognize "tail yield*" statements and avoid
            // suspending the current body when all it will do is step without
            // effect to ITERATION_ENDED.
            (_suspendedBodies ??= []).add(_body);
            _body = inner._body;
            continue;
          } else {
            _nestedIterator = inner;
            // TODO(32956): Change to the following when strong-mode is the only
            // option:
            //
            //     _nestedIterator = JS<Iterator<T>>('','#', inner);
            continue;
          }
        }
      } else {
        // TODO(32956): Remove this test.
        if (JS_GET_FLAG('STRONG_MODE')) {
          _current = JS<T>('', '#', value);
        } else {
          _current = value;
        }
        return true;
      }
    }
    return false; // TODO(sra): Fix type inference so that this is not needed.
  }
}

/// An Iterable corresponding to a sync* method.
///
/// Each invocation of a sync* method will return a new instance of this class.
class _SyncStarIterable<T> extends IterableBase<T> {
  // This is a function that will return a helper function that does the
  // iteration of the sync*.
  //
  // Each invocation should give a body with fresh state.
  final dynamic /* js function */ _outerHelper;

  _SyncStarIterable(this._outerHelper);

  Iterator<T> get iterator =>
      new _SyncStarIterator<T>(JS('', '#()', _outerHelper));
}

@patch
void _rethrow(Object error, StackTrace stackTrace) {
  error = wrapException(error);
  JS('void', '#.stack = #', error, stackTrace.toString());
  JS('void', 'throw #', error);
}
