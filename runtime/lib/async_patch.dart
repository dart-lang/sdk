// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Note: the VM concatenates all patch files into a single patch file. This
/// file is the first patch in "dart:async" which contains all the imports used
/// by patches of that library. We plan to change this when we have a shared
/// front end and simply use parts.

import "dart:_internal" show VMLibraryHooks, patch;

/// These are the additional parts of this patch library:
// part "deferred_load_patch.dart";
// part "schedule_microtask_patch.dart";
// part "timer_patch.dart";

// Equivalent of calling FATAL from C++ code.
_fatal(msg) native "DartAsync_fatal";

// We need to pass the value as first argument and leave the second and third
// arguments empty (used for error handling).
// See vm/ast_transformer.cc for usage.
Function _asyncThenWrapperHelper(continuation) {
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
  if (Zone.current == Zone.root) return continuation;
  return Zone.current.registerUnaryCallback((x) => continuation(x, null, null));
}

// We need to pass the exception and stack trace objects as second and third
// parameter to the continuation.  See vm/ast_transformer.cc for usage.
Function _asyncErrorWrapperHelper(continuation) {
  // See comments of `_asyncThenWrapperHelper`.
  var errorCallback = (e, s) => continuation(null, e, s);
  if (Zone.current == Zone.root) return errorCallback;
  return Zone.current.registerBinaryCallback(errorCallback);
}

/// Registers the [thenCallback] and [errorCallback] on the given [object].
///
/// If [object] is not a future, then it is wrapped into one.
///
/// Returns the result of registering with `.then`.
Future _awaitHelper(
    var object, Function thenCallback, Function errorCallback, var awaiter) {
  if (object is! Future) {
    object = new _Future().._setValue(object);
  } else if (object is! _Future) {
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
  object._awaiter = awaiter;
  return object._thenNoZoneRegistration(thenCallback, errorCallback);
}

// Called as part of the 'await for (...)' construct. Registers the
// awaiter on the stream.
void _asyncStarListenHelper(var object, var awaiter) {
  if (object is! _StreamImpl) {
    return;
  }
  // `object` is a `_StreamImpl`.
  object._awaiter = awaiter;
}

void _asyncStarMoveNextHelper(var stream) {
  if (stream is! _StreamImpl) {
    return;
  }
  // stream is a _StreamImpl.
  if (stream._generator == null) {
    // No generator registered, this isn't an async* Stream.
    return;
  }
  _moveNextDebuggerStepCheck(stream._generator);
}

// _AsyncStarStreamController is used by the compiler to implement
// async* generator functions.
class _AsyncStarStreamController<T> {
  StreamController<T> controller;
  Function asyncStarBody;
  bool isAdding = false;
  bool onListenReceived = false;
  bool isScheduled = false;
  bool isSuspendedAtYield = false;
  Completer cancellationCompleter = null;

  Stream<T> get stream {
    final Stream<T> local = controller.stream;
    if (local is _StreamImpl<T>) {
      local._generator = asyncStarBody;
    }
    return local;
  }

  void runBody() {
    isScheduled = false;
    isSuspendedAtYield = false;
    asyncStarBody();
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

  // Adds the elements of stream into this controller's stream.
  // The generator will be scheduled again when all of the
  // elements of the added stream have been consumed.
  // Returns true if the caller should terminate
  // execution of the generator.
  bool addStream(Stream<T> stream) {
    if (!onListenReceived) _fatal("yield before stream is listened to");
    // If stream is cancelled, tell caller to exit the async generator.
    if (!controller.hasListener) return true;
    isAdding = true;
    var whenDoneAdding =
        controller.addStream(stream as Stream<T>, cancelOnError: false);
    whenDoneAdding.then((_) {
      isAdding = false;
      scheduleGenerator();
      if (!isScheduled) isSuspendedAtYield = true;
    });
    return false;
  }

  void addError(Object error, StackTrace stackTrace) {
    if ((cancellationCompleter != null) && !cancellationCompleter.isCompleted) {
      // If the stream has been cancelled, complete the cancellation future
      // with the error.
      cancellationCompleter.completeError(error, stackTrace);
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
    if ((cancellationCompleter != null) && !cancellationCompleter.isCompleted) {
      // If the stream has been cancelled, complete the cancellation future
      // with the error.
      cancellationCompleter.complete();
    }
    controller.close();
  }

  _AsyncStarStreamController(this.asyncStarBody) {
    controller = new StreamController(
        onListen: this.onListen,
        onResume: this.onResume,
        onCancel: this.onCancel);
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
      cancellationCompleter = new Completer();
      // Only resume the generator if it is suspended at a yield.
      // Cancellation does not affect an async generator that is
      // suspended at an await.
      if (isSuspendedAtYield) {
        scheduleGenerator();
      }
    }
    return cancellationCompleter.future;
  }
}

@patch
void _rethrow(Object error, StackTrace stackTrace) native "Async_rethrow";

@patch
class _Future<T> {
  /// The closure implementing the async[*]-body that is `await`ing this future.
  Function _awaiter;
}

@patch
class _StreamImpl<T> {
  /// The closure implementing the async[*]-body that is `await`ing this future.
  Function _awaiter;

  /// The closure implementing the async-generator body that is creating events
  /// for this stream.
  Function _generator;
}

void _completeOnAsyncReturn(Completer completer, Object value) {
  completer.complete(value);
}

/// Returns a [StackTrace] object containing the synchronous prefix for this
/// asynchronous method.
Object _asyncStackTraceHelper(Function async_op)
    native "StackTrace_asyncStackTraceHelper";

void _clearAsyncThreadStackTrace()
    native "StackTrace_clearAsyncThreadStackTrace";

void _setAsyncThreadStackTrace(StackTrace stackTrace)
    native "StackTrace_setAsyncThreadStackTrace";

void _moveNextDebuggerStepCheck(Function async_op)
    native "AsyncStarMoveNext_debuggerStepCheck";
