// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.async;

/**
 * An object representing a delayed computation.
 *
 * A [Future] is used to obtain a not yet
 * available value, or error, sometime in the future.  Receivers of a
 * [Future] can register callbacks that handle the value or error once it is
 * available. For example:
 *
 *     Future<int> future = getFuture();
 *     future.then((value) => handleValue(value))
 *           .catchError((error) => handleError(error));
 *
 * A [Future] can be completed in two ways: with a value ("the future succeeds")
 * or with an error ("the future fails"). Users can install callbacks for each
 * case. The result of registering a pair of callbacks is a new Future (the
 * "successor") which in turn is completed with the result of invoking the
 * corresponding callback. The successor is completed with an error if the
 * invoked callback throws. For example:
 *
 *     Future<int> successor = future.then((int value) {
 *         // Invoked when the future is completed with a value.
 *         return 42;  // The successor is completed with the value 42.
 *       },
 *       onError: (e) {
 *         // Invoked when the future is completed with an error.
 *         if (canHandle(e)) {
 *           return 499;  // The successor is completed with the value 499.
 *         } else {
 *           throw e;  // The successor is completed with the error e.
 *         }
 *       });
 *
 * If a future does not have a successor but is completed with an error, it
 * forwards the error message to the global error-handler. This special casing
 * makes sure that no error is silently dropped. However, it also means that
 * error handlers should be installed early, so that they are present as soon
 * as a future is completed with an error. The following example demonstrates
 * this potential bug:
 *
 *     var future = getFuture();
 *     new Timer(new Duration(milliseconds: 5), () {
 *       // The error-handler is only attached 5ms after the future has been
 *       // received. If the future fails in the mean-time it will forward the
 *       // error to the global error-handler, even though there is code (just
 *       // below) to handle the error.
 *       future.then((value) { useValue(value); },
 *                   onError: (e) { handleError(e); });
 *     });
 *
 * In general we discourage registering the two callbacks at the same time, but
 * prefer to use [then] with one argument (the value handler), and to use
 * [catchError] for handling errors. The missing callbacks (the error-handler
 * for [then], and the value-handler for [catchError]), are automatically
 * configured to "forward" the value/error. Separating value and error-handling
 * into separate registration calls usually leads to code that is easier to
 * reason about. In fact it makes asynchronous code very similar to synchronous
 * code:
 *
 *     // Synchronous code.
 *     try {
 *       int value = foo();
 *       return bar(value);
 *     } catch (e) {
 *       return 499;
 *     }
 *
 *  Equivalent asynchronous code, based on futures:
 *
 *     Future<int> future = foo();  // foo now returns a future.
 *     future.then((int value) => bar(value))
 *           .catchError((e) => 499);
 *
 * Similar to the synchronous code, the error handler (registered with
 * [catchError]) is handling the errors for exceptions coming from calls to
 * 'foo', as well as 'bar'. This would not be the case if the error-handler was
 * registered at the same time as the value-handler.
 *
 * Futures can have more than one callback-pairs registered. Each successor is
 * treated independently and is handled as if it was the only successor.
 */
// TODO(floitsch): document chaining.
abstract class Future<T> {

  /**
   * Creates a future containing the result of calling [computation]
   * asynchronously with [Timer.run].
   *
   * If the result of executing [computation] throws, the returned future is
   * completed with the error.
   *
   * If the returned value is itself a [Future], completion of
   * the created future will wait until the returned future completes,
   * and will then complete with the same result.
   *
   * If a value is returned, it becomes the result of the created future.
   */
  factory Future(computation()) {
    _Future result = new _Future<T>();
    Timer.run(() {
      try {
        result._complete(computation());
      } catch (e, s) {
        result._completeError(e, s);
      }
    });
    return result;
  }

  /**
   * Creates a future containing the result of calling [computation]
   * asynchronously with [scheduleMicrotask].
   *
   * If the result of executing [computation] throws, the returned future is
   * completed with the error.
   *
   * If the returned value is itself a [Future], completion of
   * the created future will wait until the returned future completes,
   * and will then complete with the same result.
   *
   * If a value is returned, it becomes the result of the created future.
   */
  factory Future.microtask(computation()) {
    _Future result = new _Future<T>();
    scheduleMicrotask(() {
      try {
        result._complete(computation());
      } catch (e, s) {
        result._completeError(e, s);
      }
    });
    return result;
  }

  /**
   * Creates a future containing the result of immediately calling
   * [computation].
   *
   * If calling [computation] throws, the returned future is completed with the
   * error.
   *
   * If the returned value is itself a [Future], completion of
   * the created future will wait until the returned future completes,
   * and will then complete with the same result.
   */
  factory Future.sync(computation()) {
    try {
      var result = computation();
      return new Future<T>.value(result);
    } catch (error, stackTrace) {
      return new Future<T>.error(error, stackTrace);
    }
  }

  /**
   * A future whose value is available in the next event-loop iteration.
   *
   * If [value] is not a [Future], using this constructor is equivalent
   * to [:new Future<T>.sync(() => value):].
   *
   * See [Completer] to create a Future and complete it later.
   */
  factory Future.value([value]) {
    return new _Future<T>.immediate(value);
  }

  /**
   * A future that completes with an error in the next event-loop iteration.
   *
   * See [Completer] to create a Future and complete it later.
   */
  factory Future.error(Object error, [StackTrace stackTrace]) {
    return new _Future<T>.immediateError(error, stackTrace);
  }

  /**
   * Creates a future that completes after a delay.
   *
   * The future will be completed after the given [duration] has passed with
   * the result of calling [computation]. If the duration is 0 or less, it
   * completes no sooner than in the next event-loop iteration.
   *
   * If [computation] is not given or [:null:] then it will behave as if
   * [computation] was set to [:() => null:]. That is, it will complete with
   * [:null:].
   *
   * If calling [computation] throws, the created future will complete with the
   * error.
   *
   * See [Completer]s, for futures with values that are computed asynchronously.
   */
  factory Future.delayed(Duration duration, [T computation()]) {
    Completer completer = new Completer.sync();
    Future result = completer.future;
    if (computation != null) {
      result = result.then((ignored) => computation());
    }
    new Timer(duration, () { completer.complete(null); });
    return result;
  }

  /**
   * Wait for all the given futures to complete and collect their values.
   *
   * Returns a future which will complete once all the futures in a list are
   * complete. If any of the futures in the list completes with an error,
   * the resulting future also completes with an error. Otherwise the value
   * of the returned future will be a list of all the values that were produced.
   */
  static Future<List> wait(Iterable<Future> futures) {
    Completer completer;
    // List collecting values from the futures.
    // Set to null if an error occurs.
    List values;

    dynamic handleError(error) {
      if (values != null) {
        values = null;
        completer.completeError(error);
      }
      return null;
    }

    // As each future completes, put its value into the corresponding
    // position in the list of values.
    int remaining = 0;
    for (Future future in futures) {
      int pos = remaining++;
      future.catchError(handleError).then((Object value) {
        if (values == null) return null;
        values[pos] = value;
        remaining--;
        if (remaining == 0) {
          completer.complete(values);
        }
      });
    }
    if (remaining == 0) {
      return new Future.value(const []);
    }
    values = new List(remaining);
    completer = new Completer<List>();
    return completer.future;
  }

  /**
   * Perform an async operation for each element of the iterable, in turn.
   *
   * Runs [f] for each element in [input] in order, moving to the next element
   * only when the [Future] returned by [f] completes. Returns a [Future] that
   * completes when all elements have been processed.
   *
   * The return values of all [Future]s are discarded. Any errors will cause the
   * iteration to stop and will be piped through the returned [Future].
   */
  static Future forEach(Iterable input, Future f(element)) {
    _Future doneSignal = new _Future();
    Iterator iterator = input.iterator;
    void nextElement(_) {
      if (iterator.moveNext()) {
        new Future.sync(() => f(iterator.current))
            .then(nextElement, onError: doneSignal._completeError);
      } else {
        doneSignal._complete(null);
      }
    }
    nextElement(null);
    return doneSignal;
  }

  /**
   * When this future completes with a value, then [onValue] is called with this
   * value. If [this] future is already completed then the invocation of
   * [onValue] is delayed until the next event-loop iteration.
   *
   * Returns a new [Future] `f` which is completed with the result of
   * invoking [onValue] (if [this] completes with a value) or [onError] (if
   * [this] completes with an error).
   *
   * If the invoked callback throws an exception, the returned future `f` is
   * completed with the error.
   *
   * If the invoked callback returns a [Future] `f2` then `f` and `f2` are
   * chained. That is, `f` is completed with the completion value of `f2`.
   *
   * The [onError] callback must be of type `void onError(error)` or
   * `void onError(error, StackTrace stackTrace)`. If [onError] accepts
   * two arguments it is called with the stack trace (which could be `null` if
   * the stream itself received an error without stack trace).
   * Otherwise it is called with just the error object.
   *
   * If [onError] is not given it forwards the error to `f`.
   *
   * In most cases, it is more readable to use [catchError] separately, possibly
   * with a `test` parameter, instead of handling both value and error in a
   * single [then] call.
   */
  Future then(onValue(T value), { Function onError });

  /**
   * Handles errors emitted by this [Future].
   *
   * Returns a new [Future] `f`.
   *
   * When [this] completes with a value, the value is forwarded to `f`
   * unmodified. That is, `f` completes with the same value.
   *
   * When [this] completes with an error, [test] is called with the
   * error's value. If the invocation returns [true], [onError] is called with
   * the error. The result of [onError] is handled exactly the same as for
   * [then]'s [onError].
   *
   * If [test] returns false, the exception is not handled by [onError], but is
   * thrown unmodified, thus forwarding it to `f`.
   *
   * If [test] is omitted, it defaults to a function that always returns true.
   *
   * Example:
   *
   *     foo
   *       .catchError(..., test: (e) => e is ArgumentError)
   *       .catchError(..., test: (e) => e is NoSuchMethodError)
   *       .then((v) { ... });
   *
   * This method is equivalent to:
   *
   *     Future catchError(onError(error),
   *                       {bool test(error)}) {
   *       this.then((v) => v,  // Forward the value.
   *                 // But handle errors, if the [test] succeeds.
   *                 onError: (e, stackTrace) {
   *                   if (test == null || test(e)) {
   *                     if (onError is ZoneBinaryCallback) {
   *                       return onError(e, stackTrace);
   *                     }
   *                     return onError(e);
   *                   }
   *                   throw e;
   *                 });
   *     }
   *
   */
  Future catchError(Function onError,
                    {bool test(Object error)});

  /**
   * Register a function to be called when this future completes.
   *
   * The [action] function is called when this future completes, whether it
   * does so with a value or with an error.
   *
   * This is the asynchronous equivalent of a "finally" block.
   *
   * The future returned by this call, `f`, will complete the same way
   * as this future unless an error occurs in the [action] call, or in
   * a [Future] returned by the [action] call. If the call to [action]
   * does not return a future, its return value is ignored.
   *
   * If the call to [action] throws, then `f` is completed with the
   * thrown error.
   *
   * If the call to [action] returns a [Future], `f2`, then completion of
   * `f` is delayed until `f2` completes. If `f2` completes with
   * an error, that will be the result of `f` too. The value of `f2` is always
   * ignored.
   *
   * This method is equivalent to:
   *
   *     Future<T> whenComplete(action()) {
   *       this.then((v) {
   *                   var f2 = action();
   *                   if (f2 is Future) return f2.then((_) => v);
   *                   return v
   *                 },
   *                 onError: (e) {
   *                   var f2 = action();
   *                   if (f2 is Future) return f2.then((_) { throw e; });
   *                   throw e;
   *                 });
   *     }
   */
  Future<T> whenComplete(action());

  /**
   * Creates a [Stream] that sends [this]' completion value, data or error, to
   * its subscribers. The stream closes after the completion value.
   */
  Stream<T> asStream();
}

/**
 * A way to produce Future objects and to complete them later
 * with a value or error.
 *
 * If you already have a Future, you probably don't need a Completer.
 * Instead, you can usually use [Future.then], which returns a Future:
 *
 *     Future doStuff(){
 *       return someAsyncOperation().then((result) {
 *         // Do something.
 *       });
 *     }
 *
 * If you do need to create a Future from scratch—for example,
 * when you're converting a callback-based API into a Future-based
 * one—you can use a Completer as follows:
 *
 *     Class AsyncOperation {
 *       Completer _completer = new Completer();
 *
 *       Future<T> doOperation() {
 *         _startOperation();
 *         return _completer.future; // Send future object back to client.
 *       }
 *
 *       // Something calls this when the value is ready.
 *       _finishOperation(T result) {
 *         _completer.complete(result);
 *       }
 *
 *       // If something goes wrong, call this.
 *       _errorHappened(error) {
 *         _completer.completeError(error);
 *       }
 *     }
 */
abstract class Completer<T> {

  /**
   * Creates a completer whose future is completed asynchronously, sometime
   * after [complete] is called on it. This allows a call to [complete] to
   * be in the middle of other code, without running an unknown amount of
   * future completion and [then] callbacks synchronously at the point that
   * [complete] is called.
   *
   * Example:
   *
   *     var completer = new Completer.sync();
   *     completer.future.then((_) { bar(); });
   *     // The completion is the result of the asynchronous onDone event.
   *     // However, there is code executed after the call to complete,
   *     // but before completer.future runs its completion callback.
   *     stream.listen(print, onDone: () {
   *       completer.complete("done");
   *       foo();  // In this case, foo() runs before bar().
   *     });
   */
  factory Completer() => new _AsyncCompleter<T>();

  /**
   * Completes the future synchronously.
   *
   * This constructor should be avoided unless the completion of the future is
   * known to be the final result of another asynchronous operation. If in doubt
   * use the default [Completer] constructor.
   *
   * Example:
   *
   *     var completer = new Completer.sync();
   *     // The completion is the result of the asynchronous onDone event.
   *     // No other operation is performed after the completion. It is safe
   *     // to use the Completer.sync constructor.
   *     stream.listen(print, onDone: () { completer.complete("done"); });
   *
   * Bad example. Do not use this code. Only for illustrative purposes:
   *
   *     var completer = new Completer.sync();
   *     completer.future.then((_) { bar(); });
   *     // The completion is the result of the asynchronous onDone event.
   *     // However, there is still code executed after the completion. This
   *     // operation is *not* safe.
   *     stream.listen(print, onDone: () {
   *       completer.complete("done");
   *       foo();  // In this case, foo() runs after bar().
   *     });
   */
  factory Completer.sync() => new _SyncCompleter<T>();

  /** The future that will contain the result provided to this completer. */
  Future get future;

  /**
   * Completes [future] with the supplied values.
   *
   * If the value is itself a future, the completer will wait for that future
   * to complete, and complete with the same result, whether it is a success
   * or an error.
   *
   * Calling `complete` or [completeError] must not be done more than once.
   *
   * All listeners on the future are informed about the value.
   */
  void complete([value]);

  /**
   * Complete [future] with an error.
   *
   * Calling [complete] or `completeError` must not be done more than once.
   *
   * Completing a future with an error indicates that an exception was thrown
   * while trying to produce a value.
   *
   * The argument [error] must not be `null`.
   *
   * If `error` is a `Future`, the future itself is used as the error value.
   * If you want to complete with the result of the future, you can use:
   *
   *     thisCompleter.complete(theFuture)
   *
   * or if you only want to handle an error from the future:
   *
   *     theFuture.catchError(thisCompleter.completeError);
   *
   */
  void completeError(Object error, [StackTrace stackTrace]);

  /**
   * Whether the future has been completed.
   */
  bool get isCompleted;
}
