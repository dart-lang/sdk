// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Patch file for the dart:async library.

import 'dart:_js_helper' show notNull, patch, ReifyFunctionTypes;
import 'dart:_isolate_helper'
    show TimerImpl, global, leaveJsAsync, enterJsAsync;
import 'dart:_foreign_helper' show JS, JSExportName;
import 'dart:_runtime' as dart;

typedef void _Callback();
typedef void _TakeCallback(_Callback callback);

/// This function adapts ES6 generators to implement Dart's async/await.
///
/// It's designed to interact with Dart's Future and follow Dart async/await
/// semantics.
///
/// See https://github.com/dart-lang/sdk/issues/27315 for ideas on reconciling
/// Dart's Future and ES6 Promise. At that point we should use native JS
/// async/await.
///
/// Inspired by `co`: https://github.com/tj/co/blob/master/index.js, which is a
/// stepping stone for ES async/await.
@JSExportName('async')
@ReifyFunctionTypes(false)
_async<T>(Function() initGenerator) {
  var iter;
  Object Function(Object) onValue;
  Object Function(Object, StackTrace) onError;

  onAwait(Object value) {
    _Future f;
    if (value is _Future) {
      f = value;
    } else if (value is Future) {
      f = _Future();
      _Future._chainForeignFuture(value, f);
    } else {
      f = _Future.value(value);
    }
    f = JS('', '#', f._thenNoZoneRegistration(onValue, onError));
    return f;
  }

  onValue = (value) {
    var iteratorResult = JS('', '#.next(#)', iter, value);
    value = JS('', '#.value', iteratorResult);
    return JS('bool', '#.done', iteratorResult) ? value : onAwait(value);
  };

  // If the awaited Future throws, we want to convert this to an exception
  // thrown from the `yield` point, as if it was thrown there.
  //
  // If the exception is not caught inside `gen`, it will emerge here, which
  // will send it to anyone listening on this async function's Future<T>.
  //
  // In essence, we are giving the code inside the generator a chance to
  // use try-catch-finally.
  onError = (value, stackTrace) {
    var iteratorResult = JS(
        '', '#.throw(#)', iter, dart.createErrorWithStack(value, stackTrace));
    value = JS('', '#.value', iteratorResult);
    return JS('bool', '#.done', iteratorResult) ? value : onAwait(value);
  };

  var zone = Zone.current;
  if (!identical(zone, _rootZone)) {
    onValue = zone.registerUnaryCallback(onValue);
    onError = zone.registerBinaryCallback(onError);
  }

  var asyncFuture = _Future<T>();

  // This will be set to true once we've yielded to the event loop.
  //
  // Before we've done that, we need to complete the future asynchronously to
  // match dart2js/VM. See https://github.com/dart-lang/sdk/issues/33330
  //
  // Once we've yielded to the event loop we can complete synchronously.
  // Other implementations call this `isSync` to indicate that.
  bool isRunningAsEvent = false;
  runBody() {
    try {
      iter = JS('', '#[Symbol.iterator]()', initGenerator());
      var iteratorValue = JS('', '#.next(null)', iter);
      var value = JS('', '#.value', iteratorValue);
      if (JS('bool', '#.done', iteratorValue)) {
        // TODO(jmesserly): this is a workaround for ignored cast failures.
        // Remove it once we've fixed those. We should be able to call:
        //
        //     if (isRunningAsEvent) {
        //       asyncFuture._complete(value);
        //     } else {
        //       asyncFuture._asyncComplete(value);
        //     }
        //
        // But if the user code returns `Future<dynamic>` instead of
        // `Future<T>`, that function won't recognize it as a future and will
        // instead treat it as a completed value.
        if (value is Future) {
          if (value is _Future) {
            _Future._chainCoreFuture(value, asyncFuture);
          } else {
            _Future._chainForeignFuture(value, asyncFuture);
          }
        } else if (isRunningAsEvent) {
          asyncFuture._completeWithValue(JS('', '#', value));
        } else {
          asyncFuture._asyncComplete(JS('', '#', value));
        }
      } else {
        _Future._chainCoreFuture(onAwait(value), asyncFuture);
      }
    } catch (e, s) {
      if (isRunningAsEvent) {
        _completeWithErrorCallback(asyncFuture, e, s);
      } else {
        _asyncCompleteWithErrorCallback(asyncFuture, e, s);
      }
    }
  }

  if (dart.startAsyncSynchronously) {
    runBody();
    isRunningAsEvent = true;
  } else {
    isRunningAsEvent = true;
    scheduleMicrotask(runBody);
  }
  return asyncFuture;
}

@patch
class _AsyncRun {
  @patch
  static void _scheduleImmediate(void callback()) {
    _scheduleImmediateClosure(callback);
  }

  // Lazily initialized.
  static final _TakeCallback _scheduleImmediateClosure =
      _initializeScheduleImmediate();

  static _TakeCallback _initializeScheduleImmediate() {
    // TODO(rnystrom): Not needed by dev_compiler.
    // requiresPreamble();
    if (JS('', '#.scheduleImmediate', global) != null) {
      return _scheduleImmediateJsOverride;
    }
    if (JS('', '#.MutationObserver', global) != null &&
        JS('', '#.document', global) != null) {
      // Use mutationObservers.
      var div = JS('', '#.document.createElement("div")', global);
      var span = JS('', '#.document.createElement("span")', global);
      _Callback storedCallback;

      internalCallback(_) {
        leaveJsAsync();
        var f = storedCallback;
        storedCallback = null;
        f();
      }

      ;

      var observer =
          JS('', 'new #.MutationObserver(#)', global, internalCallback);
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
    } else if (JS('', '#.setImmediate', global) != null) {
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
    JS('void', '#.scheduleImmediate(#)', global, internalCallback);
  }

  static void _scheduleImmediateWithSetImmediate(void callback()) {
    internalCallback() {
      leaveJsAsync();
      callback();
    }

    ;
    enterJsAsync();
    JS('void', '#.setImmediate(#)', global, internalCallback);
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
    return TimerImpl(milliseconds, callback);
  }

  @patch
  static Timer _createPeriodicTimer(
      Duration duration, void callback(Timer timer)) {
    int milliseconds = duration.inMilliseconds;
    if (milliseconds < 0) milliseconds = 0;
    return TimerImpl.periodic(milliseconds, callback);
  }
}

@patch
void _rethrow(Object error, StackTrace stackTrace) {
  JS('', 'throw #', dart.createErrorWithStack(error, stackTrace));
}

/// Used by the compiler to implement `async*` functions.
///
/// This is inspired by _AsyncStarStreamController in dart-lang/sdk's
/// runtime/lib/core_patch.dart
///
/// Given input like:
///
///     foo() async* {
///       yield 1;
///       yield* bar();
///       print(await baz());
///     }
///
/// This compiles to:
///
///     function foo() {
///       return new (AsyncStarImplOfT()).new(function*(stream) {
///         if (stream.add(1)) return;
///         yield;
///         if (stream.addStream(bar()) return;
///         yield;
///         print(yield baz());
///      });
///     }
///
class _AsyncStarImpl<T> {
  StreamController<T> controller;
  Object Function(_AsyncStarImpl<T>) initGenerator;
  @notNull
  bool isSuspendedAtYieldStar = false;
  @notNull
  bool onListenReceived = false;
  @notNull
  bool isScheduled = false;
  @notNull
  bool isSuspendedAtYield = false;

  /// Whether we're suspended at an `await`.
  @notNull
  bool isSuspendedAtAwait = false;

  Completer cancellationCompleter;
  Object jsIterator;

  Null Function(Object, StackTrace) _handleErrorCallback;
  void Function([Object]) _runBodyCallback;

  _AsyncStarImpl(this.initGenerator) {
    controller = StreamController(
        onListen: JS('!', 'this.onListen.bind(this)'),
        onResume: JS('!', 'this.onResume.bind(this)'),
        onCancel: JS('!', 'this.onCancel.bind(this)'));
    jsIterator = JS('!', '#[Symbol.iterator]()', initGenerator(this));
  }

  /// The stream produced by this `async*` function.
  Stream<T> get stream => controller.stream;

  /// Returns the callback used for error handling.
  ///
  /// This callback throws the error back into the user code, at the appropriate
  /// location (e.g. `await` `yield` or `yield*`). This gives user code a chance
  /// to handle it try-catch. If they do not handle, the error gets routed to
  /// the [stream] as an error via [addError].
  ///
  /// As a performance optimization, this callback is only bound once to the
  /// current [Zone]. This works because a single subscription stream should
  /// always be running in its original zone. An `async*` method will always
  /// save/restore the zone that was active when `listen()` was first called,
  /// similar to a stream. This follows from section 16.14 of the Dart 4th
  /// edition spec:
  ///
  /// > If `f` is marked `async*` (9), then a fresh instance `s` implementing
  /// > the built-in class `Stream` is associated with the invocation and
  /// > immediately returned. When `s` is listened to, execution of the body of
  /// > `f` will begin.
  ///
  Null Function(Object, StackTrace) get handleError {
    if (_handleErrorCallback == null) {
      _handleErrorCallback = (error, StackTrace stackTrace) {
        try {
          JS('', '#.throw(#)', jsIterator,
              dart.createErrorWithStack(error, stackTrace));
        } catch (e, newStack) {
          // The generator didn't catch the error, or it threw a new one.
          // Make sure to propagate the new error.
          addError(e, newStack);
        }
      };
      var zone = Zone.current;
      if (!identical(zone, Zone.root)) {
        _handleErrorCallback = zone.bindBinaryCallback(_handleErrorCallback);
      }
    }
    return _handleErrorCallback;
  }

  void scheduleGenerator() {
    // TODO(jmesserly): is this isPaused check in the right place? Assuming the
    // async* Stream yields, then is paused (by other code), the body will
    // already be scheduled. This will cause at least one more iteration to
    // run (adding another data item to the Stream) before actually pausing.
    // It could be fixed by moving the `isPaused` check inside `runBody`.
    if (isScheduled ||
        controller.isPaused ||
        isSuspendedAtYieldStar ||
        isSuspendedAtAwait) {
      return;
    }
    isScheduled = true;
    // Capture the current zone. See comment on [handleError] for more
    // information about this optimization.
    var zone = Zone.current;
    if (_runBodyCallback == null) {
      _runBodyCallback = JS('!', '#.bind(this)', runBody);
      if (!identical(zone, Zone.root)) {
        var registered = zone.registerUnaryCallback(_runBodyCallback);
        _runBodyCallback = ([arg]) => zone.runUnaryGuarded(registered, arg);
      }
    }
    zone.scheduleMicrotask(_runBodyCallback);
  }

  void runBody(awaitValue) {
    isScheduled = false;
    isSuspendedAtYield = false;
    isSuspendedAtAwait = false;

    Object iterResult;
    try {
      iterResult = JS('', '#.next(#)', jsIterator, awaitValue);
    } catch (e, s) {
      addError(e, s);
      return null;
    }

    if (JS('!', '#.done', iterResult)) {
      close();
      return null;
    }

    // If we're suspended at a yield/yield*, we're done for now.
    if (isSuspendedAtYield || isSuspendedAtYieldStar) return null;

    // Handle `await`: if we get a value passed to `yield` it means we are
    // waiting on this Future. Make sure to prevent scheduling, and pass the
    // value back as the result of the `yield`.
    //
    // TODO(jmesserly): is the timing here correct? The assumption here is
    // that we should schedule `await` in `async*` the same as in `async`.
    isSuspendedAtAwait = true;
    FutureOr<Object> value = JS('', '#.value', iterResult);

    // TODO(jmesserly): this logic was copied from `async` function impl.
    _Future f;
    if (value is _Future) {
      f = value;
    } else if (value is Future) {
      f = _Future();
      _Future._chainForeignFuture(value, f);
    } else {
      f = _Future.value(value);
    }
    f._thenNoZoneRegistration(_runBodyCallback, handleError);
  }

  /// Adds element to [stream] and returns true if the caller should terminate
  /// execution of the generator.
  ///
  /// This is called from generated code like this:
  ///
  ///     if (controller.add(1)) return;
  ///     yield;
  //
  // TODO(hausner): Per spec, the generator should be suspended before exiting
  // when the stream is closed. We could add a getter like this:
  //
  //     get isCancelled => controller.hasListener;
  //
  // The generator would translate a 'yield e' statement to
  //
  //     controller.add(1);
  //     suspend; // this is `yield` in JS.
  //     if (controller.isCancelled) return;
  bool add(T event) {
    if (!onListenReceived) _fatal("yield before stream is listened to");
    if (isSuspendedAtYield) _fatal("unexpected yield");
    // If stream is cancelled, tell caller to exit the async generator.
    if (!controller.hasListener) {
      return true;
    }
    controller.add(event);
    scheduleGenerator();
    isSuspendedAtYield = true;
    return false;
  }

  /// Adds the elements of [stream] into this [controller]'s stream, and returns
  /// true if the caller should terminate execution of the generator.
  ///
  /// The generator will be scheduled again when all of the elements of the
  /// added stream have been consumed.
  bool addStream(Stream<T> stream) {
    if (!onListenReceived) _fatal("yield* before stream is listened to");
    // If stream is cancelled, tell caller to exit the async generator.
    if (!controller.hasListener) return true;
    isSuspendedAtYieldStar = true;
    var whenDoneAdding = controller.addStream(stream, cancelOnError: false);
    whenDoneAdding.then((_) {
      isSuspendedAtYieldStar = false;
      scheduleGenerator();
      if (!isScheduled) isSuspendedAtYield = true;
    }, onError: handleError);
    return false;
  }

  void addError(Object error, StackTrace stackTrace) {
    if (cancellationCompleter != null && !cancellationCompleter.isCompleted) {
      // If the stream has been cancelled, complete the cancellation future
      // with the error.
      cancellationCompleter.completeError(error, stackTrace);
    } else if (controller.hasListener) {
      controller.addError(error, stackTrace);
    }
    // No need to schedule the generator body here. This code is only
    // called from the catch clause of the implicit try-catch-finally
    // around the generator body. That is, we are on the error path out
    // of the generator and do not need to run the generator again.
    close();
  }

  void close() {
    if (cancellationCompleter != null && !cancellationCompleter.isCompleted) {
      // If the stream has been cancelled, complete the cancellation future
      // with the error.
      cancellationCompleter.complete();
    }
    controller.close();
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
    if (cancellationCompleter == null) {
      cancellationCompleter = Completer();
      // Only resume the generator if it is suspended at a yield.
      // Cancellation does not affect an async generator that is
      // suspended at an await.
      if (isSuspendedAtYield) {
        scheduleGenerator();
      }
    }
    return cancellationCompleter.future;
  }

  _fatal(String message) => throw StateError(message);
}
