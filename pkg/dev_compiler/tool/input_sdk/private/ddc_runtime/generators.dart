// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library adapts ES6 generators to implement Dart's async/await.
/// It's designed to interact with Dart's Future/Stream and follow Dart
/// async/await semantics.
/// See https://github.com/dart-lang/sdk/issues/27315 for ideas on
/// reconciling Dart's Future and ES6 Promise.
/// Inspired by `co`: https://github.com/tj/co/blob/master/index.js, which is a
/// stepping stone for proposed ES7 async/await, and uses ES6 Promises.
part of dart._runtime;

final _jsIterator = JS('', 'Symbol("_jsIterator")');
final _current = JS('', 'Symbol("_current")');

syncStar(gen, E, @rest args) =>
    JS('', 'new (${getGenericClass(SyncIterable)}($E).new)($gen, $args)');

@JSExportName('async')
async_(gen, T, @rest args) => JS(
    '',
    '''(() => {
  let iter;
  const FutureT = ${getGenericClass(Future)}($T);
  let _FutureType;
  // Return the raw class type or null if not a class object.
  // This is streamlined to test for native futures.
  function _getRawClassType(obj) {
    if (!obj) return null;
    let constructor = obj.constructor;
    if (!constructor == null) return null;
    return $getGenericClass(constructor);
  }
  function onValue(res) {
    if (res === void 0) res = null;
    return next(iter.next(res));
  }
  function onError(err) {
    // If the awaited Future throws, we want to convert this to an exception
    // thrown from the `yield` point, as if it was thrown there.
    //
    // If the exception is not caught inside `gen`, it will emerge here, which
    // will send it to anyone listening on this async function's Future<T>.
    //
    // In essence, we are giving the code inside the generator a chance to
    // use try-catch-finally.
    return next(iter.throw(err));
  }
  function next(ret) {
    let future = ret.value;
    if (ret.done) {
      return ret.value;
    }
    // Wraps if future is not a native Future.
    if (_getRawClassType(future) !== _FutureType) {
      future = $Future.value(future);
    }
    // Chain the Future so `await` receives the Future's value.
    return future.then($dynamic)(onValue, {onError: onError});
  }
  let result = FutureT.microtask(function() {
    iter = $gen.apply(null, $args)[Symbol.iterator]();
    var result = onValue();
    if ($isSubtype($getReifiedType(result), FutureT) == null) {
      // Chain the Future<dynamic> to a Future<T> to produce the correct
      // final type.
      return result.then($T)((x) => x, {onError: onError});
    } else {
      return result;
    }
  });
  // TODO(jmesserly): optimize this further.
  _FutureType = _getRawClassType(result);
  return result;  
})()''');

/// Implementation inspired by _AsyncStarStreamController in
/// dart-lang/sdk's runtime/lib/core_patch.dart
///
/// Given input like:
///
///     foo() async* {
///       yield 1;
///       yield* bar();
///       print(await baz());
///     }
///
/// This generates as:
///
///     function foo() {
///       return dart.asyncStar(function*(stream) {
///         if (stream.add(1)) return;
///         yield;
///         if (stream.addStream(bar()) return;
///         yield;
///         print(yield baz());
///      });
///     }
///
// TODO(jmesserly): port back to Dart, based on VM's equivalent class.
final _AsyncStarStreamController = JS(
    '',
    '''
  class _AsyncStarStreamController {
    constructor(generator, T, args) {
      this.isAdding = false;
      this.isWaiting = false;
      this.isScheduled = false;
      this.isSuspendedAtYield = false;
      this.canceler = null;
      this.iterator = generator(this, ...args)[Symbol.iterator]();
      this.controller = ${getGenericClass(StreamController)}(T).new({
        onListen: () => this.scheduleGenerator(),
        onResume: () => this.onResume(),
        onCancel: () => this.onCancel()
      });
    }

    onResume() {
      if (this.isSuspendedAtYield) {
        this.scheduleGenerator();
      }
    }

    onCancel() {
      if (this.controller.isClosed) {
        return null;
      }
      if (this.canceler == null) {
        this.canceler = $Completer.new();
        this.scheduleGenerator();
      }
      return this.canceler.future;
    }

    close() {
      if (this.canceler != null && !this.canceler.isCompleted) {
        // If the stream has been cancelled, complete the cancellation future
        // with the error.
        this.canceler.complete();
      }
      this.controller.close();
    }

    scheduleGenerator() {
      // TODO(jmesserly): is this paused check in the right place? Assuming the
      // async* Stream yields, then is paused (by other code), the body will
      // already be scheduled. This will cause at least one more iteration to
      // run (adding another data item to the Stream) before actually pausing.
      // It could be fixed by moving the `isPaused` check inside `runBody`.
      if (this.isScheduled || this.controller.isPaused ||
          this.isAdding || this.isWaiting) {
        return;
      }
      this.isScheduled = true;
      $scheduleMicrotask(() => this.runBody());
    }

    runBody(opt_awaitValue) {
      this.isScheduled = false;
      this.isSuspendedAtYield = false;
      this.isWaiting = false;
      let iter;
      try {
        iter = this.iterator.next(opt_awaitValue);
      } catch (e) {
        this.addError(e, $stackTrace(e));
        this.close();
        return;
      }
      if (iter.done) {
        this.close();
        return;
      }

      // If we're suspended at a yield/yield*, we're done for now.
      if (this.isSuspendedAtYield || this.isAdding) return;

      // Handle `await`: if we get a value passed to `yield` it means we are
      // waiting on this Future. Make sure to prevent scheduling, and pass the
      // value back as the result of the `yield`.
      //
      // TODO(jmesserly): is the timing here correct? The assumption here is
      // that we should schedule `await` in `async*` the same as in `async`.
      this.isWaiting = true;
      let future = iter.value;
      if (!$instanceOf(future, ${getGenericClass(Future)})) {
        future = $Future.value(future);
      }
      return future.then($dynamic)((x) => this.runBody(x),
          { onError: (e, s) => this.throwError(e, s) });
    }

    // Adds element to stream, returns true if the caller should terminate
    // execution of the generator.
    add(event) {
      // If stream is cancelled, tell caller to exit the async generator.
      if (!this.controller.hasListener) return true;
      this.controller.add(event);
      this.scheduleGenerator();
      this.isSuspendedAtYield = true;
      return false;
    }

    // Adds the elements of stream into this controller's stream.
    // The generator will be scheduled again when all of the
    // elements of the added stream have been consumed.
    // Returns true if the caller should terminate
    // execution of the generator.
    addStream(stream) {
      // If stream is cancelled, tell caller to exit the async generator.
      if (!this.controller.hasListener) return true;

      this.isAdding = true;
      this.controller.addStream(stream, {cancelOnError: false}).then($dynamic)(
          () => {
        this.isAdding = false;
        this.scheduleGenerator();
      }, { onError: (e, s) => this.throwError(e, s) });
    }

    throwError(error, stackTrace) {
      try {
        this.iterator.throw(error);
      } catch (e) {
        this.addError(e, stackTrace);
      }
    }

    addError(error, stackTrace) {
      if ((this.canceler != null) && !this.canceler.isCompleted) {
        // If the stream has been cancelled, complete the cancellation future
        // with the error.
        this.canceler.completeError(error, stackTrace);
        return;
      }
      if (!this.controller.hasListener) return;
      this.controller.addError(error, stackTrace);
    }
  }
''');

/// Returns a Stream of T implemented by an async* function.
asyncStar(gen, T, @rest args) => JS('', 'new #(#, #, #).controller.stream',
    _AsyncStarStreamController, gen, T, args);
