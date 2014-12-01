// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.async;

/**
 * An object representing a delayed computation.
 *
 * A [Future] is used to represent a potential value, or error,
 * that will be available at some time in the future.
 * Receivers of a [Future] can register callbacks
 * that handle the value or error once it is available.
 * For example:
 *
 *     Future<int> future = getFuture();
 *     future.then((value) => handleValue(value))
 *           .catchError((error) => handleError(error));
 *
 * A [Future] can complete in two ways:
 * with a value ("the future succeeds")
 * or with an error ("the future fails").
 * Users can install callbacks for each case.
 * The result of registering a pair of callbacks is a new Future (the
 * "successor") which in turn is completed with the result of invoking the
 * corresponding callback.
 * The successor is completed with an error if the invoked callback throws.
 * For example:
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
 * If a future does not have a successor when it completes with an error,
 * it forwards the error message to the global error-handler.
 * This behavior makes sure that no error is silently dropped.
 * However, it also means that error handlers should be installed early,
 * so that they are present as soon as a future is completed with an error.
 * The following example demonstrates this potential bug:
 *
 *     var future = getFuture();
 *     new Timer(new Duration(milliseconds: 5), () {
 *       // The error-handler is not attached until 5 ms after the future has
 *       // been received. If the future fails before that, the error is
 *       // forwarded to the global error-handler, even though there is code
 *       // (just below) to eventually handle the error.
 *       future.then((value) { useValue(value); },
 *                   onError: (e) { handleError(e); });
 *     });
 *
 * When registering callbacks, it's often more readable to register the two
 * callbacks separately, by first using [then] with one argument
 * (the value handler) and using a second [catchError] for handling errors.
 * Each of these will forward the result that they don't handle
 * to their successors, and together they handle both value and error result.
 * It also has the additional benefit of the [catchError] handling errors in the
 * [then] value callback too.
 * Using sequential handlers instead of parallel ones often leads to code that
 * is easier to reason about.
 * It also makes asynchronous code very similar to synchronous code:
 *
 *     // Synchronous code.
 *     try {
 *       int value = foo();
 *       return bar(value);
 *     } catch (e) {
 *       return 499;
 *     }
 *
 * Equivalent asynchronous code, based on futures:
 *
 *     Future<int> future = new Future(foo);  // Result of foo() as a future.
 *     future.then((int value) => bar(value))
 *           .catchError((e) => 499);
 *
 * Similar to the synchronous code, the error handler (registered with
 * [catchError]) is handling any errors thrown by either `foo` or `bar`.
 * If the error-handler had been registered as the `onError` parameter of
 * the `then` call, it would not catch errors from the `bar` call.
 *
 * Futures can have more than one callback-pair registered. Each successor is
 * treated independently and is handled as if it was the only successor.
 *
 * A future may also fail to ever complete. In that case, no callbacks are
 * called.
 */
abstract class Future<T> {
  // The `_nullFuture` is a completed Future with the value `null`.
  static final _Future _nullFuture = new Future.value(null);

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
   * If a non-future value is returned, the returned future is completed
   * with that value.
   */
  factory Future(computation()) {
    _Future result = new _Future<T>();
    Timer.run(() {
      try {
        result._complete(computation());
      } catch (e, s) {
        _completeWithErrorCallback(result, e, s);
      }
    });
    return result;
  }

  /**
   * Creates a future containing the result of calling [computation]
   * asynchronously with [scheduleMicrotask].
   *
   * If executing [computation] throws,
   * the returned future is completed with the thrown error.
   *
   * If calling [computation] returns a [Future], completion of
   * the created future will wait until the returned future completes,
   * and will then complete with the same result.
   *
   * If calling [computation] returns a non-future value,
   * the returned future is completed with that value.
   */
  factory Future.microtask(computation()) {
    _Future result = new _Future<T>();
    scheduleMicrotask(() {
      try {
        result._complete(computation());
      } catch (e, s) {
        _completeWithErrorCallback(result, e, s);
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
   * If calling [computation] returns a [Future], completion of
   * the created future will wait until the returned future completes,
   * and will then complete with the same result.
   *
   * If calling [computation] returns a non-future value,
   * the returned future is completed with that value.
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
   * Use [Completer] to create a Future and complete it later.
   */
  factory Future.value([value]) {
    return new _Future<T>.immediate(value);
  }

  /**
   * A future that completes with an error in the next event-loop iteration.
   *
   * If [error] is `null`, it is replaced by a [NullThrownError].
   *
   * Use [Completer] to create a future and complete it later.
   */
  factory Future.error(Object error, [StackTrace stackTrace]) {
    error = _nonNullError(error);
    if (!identical(Zone.current, _ROOT_ZONE)) {
      AsyncError replacement = Zone.current.errorCallback(error, stackTrace);
      if (replacement != null) {
        error = _nonNullError(replacement.error);
        stackTrace = replacement.stackTrace;
      }
    }
    return new _Future<T>.immediateError(error, stackTrace);
  }

  /**
   * Creates a future that runs its computation after a delay.
   *
   * The [computation] will be executed after the given [duration] has passed,
   * and the future is completed with the result.
   * If the duration is 0 or less,
   * it completes no sooner than in the next event-loop iteration.
   *
   * If [computation] is omitted,
   * it will be treated as if [computation] was set to `() => null`,
   * and the future will eventually complete with the `null` value.
   *
   * If calling [computation] throws, the created future will complete with the
   * error.
   *
   * See also [Completer] for a way to create and complete a future at a
   * later time that isn't necessarily after a known fixed duration.
   */
  factory Future.delayed(Duration duration, [T computation()]) {
    _Future result = new _Future<T>();
    new Timer(duration, () {
      try {
        result._complete(computation == null ? null : computation());
      } catch (e, s) {
        _completeWithErrorCallback(result, e, s);
      }
    });
    return result;
  }

  /**
   * Wait for all the given futures to complete and collect their values.
   *
   * Returns a future which will complete once all the futures in a list are
   * complete. If any of the futures in the list completes with an error,
   * the resulting future also completes with an error. Otherwise the value
   * of the returned future will be a list of all the values that were produced.
   *
   * If `eagerError` is true, the future completes with an error immediately on
   * the first error from one of the futures. Otherwise all futures must
   * complete before the returned future is completed (still with the first
   * error to occur, the remaining errors are silently dropped).
   */
  static Future<List> wait(Iterable<Future> futures, {bool eagerError: false}) {
    final _Future<List> result = new _Future<List>();
    List values;  // Collects the values. Set to null on error.
    int remaining = 0;  // How many futures are we waiting for.
    var error;   // The first error from a future.
    StackTrace stackTrace;  // The stackTrace that came with the error.

    // Handle an error from any of the futures.
    handleError(theError, theStackTrace) {
      final bool isFirstError = (values != null);
      values = null;
      remaining--;
      if (isFirstError) {
        if (remaining == 0 || eagerError) {
          result._completeError(theError, theStackTrace);
        } else {
          error = theError;
          stackTrace = theStackTrace;
        }
      } else if (remaining == 0 && !eagerError) {
        result._completeError(error, stackTrace);
      }
    }

    // As each future completes, put its value into the corresponding
    // position in the list of values.
    for (Future future in futures) {
      int pos = remaining++;
      future.then((Object value) {
        remaining--;
        if (values != null) {
          values[pos] = value;
          if (remaining == 0) {
            result._completeWithValue(values);
          }
        } else if (remaining == 0 && !eagerError) {
          result._completeError(error, stackTrace);
        }
      }, onError: handleError);
    }
    if (remaining == 0) {
      return new Future.value(const []);
    }
    values = new List(remaining);
    return result;
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
   *
   * If [f] returns a non-[Future], iteration continues immediately. Otherwise
   * it waits for the returned [Future] to complete.
   */
  static Future forEach(Iterable input, f(element)) {
    Iterator iterator = input.iterator;
    return doWhile(() {
      if (!iterator.moveNext()) return false;
      return new Future.sync(() => f(iterator.current)).then((_) => true);
    });
  }

  /**
   * Perform an async operation repeatedly until it returns `false`.
   *
   * Runs [f] repeatedly, starting the next iteration only when the [Future]
   * returned by [f] completes to `true`. Returns a [Future] that completes once
   * [f] returns `false`.
   *
   * The return values of all [Future]s are discarded. Any errors will cause the
   * iteration to stop and will be piped through the returned [Future].
   *
   * The function [f] may return either a [bool] or a [Future] that completes to
   * a [bool]. If it returns a non-[Future], iteration continues immediately.
   * Otherwise it waits for the returned [Future] to complete.
   */
  static Future doWhile(f()) {
    _Future doneSignal = new _Future();
    var nextIteration;
    // Bind this callback explicitly so that each iteration isn't bound in the
    // context of all the previous iterations' callbacks.
    nextIteration = Zone.current.bindUnaryCallback((bool keepGoing) {
      if (keepGoing) {
        new Future.sync(f).then(nextIteration,
                                onError: doneSignal._completeError);
      } else {
        doneSignal._complete(null);
      }
    }, runGuarded: true);
    nextIteration(true);
    return doneSignal;
  }

  /**
   * Register callbacks to be called when this future completes.
   *
   * When this future completes with a value,
   * the [onValue] callback will be called with that value.
   * If this future is already completed, the callback will not be called
   * immediately, but will be scheduled in a later microtask.
   *
   * If [onError] is provided, and this future completes with an error,
   * the `onError` callback is called with that error and its stack trace.
   * The `onError` callback must accept either one argument or two arguments.
   * If `onError` accepts two arguments,
   * it is called with both the error and the stack trace,
   * otherwise it is called with just the error object.
   *
   * Returns a new [Future]
   * which is completed with the result of the call to `onValue`
   * (if this future completes with a value)
   * or to `onError` (if this future completes with an error).
   *
   * If the invoked callback throws,
   * the returned future is completed with the thrown error
   * and a stack trace for the error.
   * In the case of `onError`,
   * if the exception thrown is `identical` to the error argument to `onError`,
   * the throw is considered a rethrow,
   * and the original stack trace is used instead.
   *
   * If the callback returns a [Future],
   * the future returned by `then` will be completed with
   * the same result as the future returned by the callback.
   *
   * If [onError] is not given, and this future completes with an error,
   * the error is forwarded directly to the returned future.
   *
   * In most cases, it is more readable to use [catchError] separately, possibly
   * with a `test` parameter, instead of handling both value and error in a
   * single [then] call.
   */
  Future then(onValue(T value), { Function onError });

  /**
   * Handles errors emitted by this [Future].
   *
   * This is the asynchronous equivalent of a "catch" block.
   *
   * Returns a new [Future] that will be completed with either the result of
   * this future or the result of calling the `onError` callback.
   *
   * If this future completes with a value,
   * the returned future completes with the same value.
   *
   * If this future completes with an error,
   * then [test] is first called with the error value.
   *
   * If `test` returns false, the exception is not handled by this `catchError`,
   * and the returned future completes with the same error and stack trace
   * as this future.
   *
   * If `test` returns `true`,
   * [onError] is called with the error and possibly stack trace,
   * and the returned future is completed with the result of this call
   * in exactly the same way as for [then]'s `onError`.
   *
   * If `test` is omitted, it defaults to a function that always returns true.
   * The `test` function should not throw, but if it does, it is handled as
   * if the the `onError` function had thrown.
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
   *       return this.then((v) {
   *         var f2 = action();
   *         if (f2 is Future) return f2.then((_) => v);
   *         return v
   *       }, onError: (e) {
   *         var f2 = action();
   *         if (f2 is Future) return f2.then((_) { throw e; });
   *         throw e;
   *       });
   *     }
   */
  Future<T> whenComplete(action());

  /**
   * Creates a [Stream] containing the result of this future.
   *
   * The stream will produce single data or error event containing the
   * completion result of this future, and then it will close with a
   * done event.
   *
   * If the future never completes, the stream will not produce any events.
   */
  Stream<T> asStream();

  /**
   * Time-out the future computation after [timeLimit] has passed.
   *
   * Returns a new future that completes with the same value as this future,
   * if this future completes in time.
   *
   * If this future does not complete before `timeLimit` has passed,
   * the [onTimeout] action is executed instead, and its result (whether it
   * returns or throws) is used as the result of the returned future.
   *
   * If `onTimeout` is omitted, a timeout will cause the returned future to
   * complete with a [TimeoutException].
   */
  Future timeout(Duration timeLimit, {onTimeout()});
}

/**
 * Thrown when a scheduled timeout happens while waiting for an async result.
 */
class TimeoutException implements Exception {
  /** Description of the cause of the timeout. */
  final String message;
  /** The duration that was exceeded. */
  final Duration duration;

  TimeoutException(this.message, [this.duration]);

  String toString() {
    String result = "TimeoutException";
    if (duration != null) result = "TimeoutException after $duration";
    if (message != null) result = "$result: $message";
    return result;
  }
}

/**
 * A way to produce Future objects and to complete them later
 * with a value or error.
 *
 * Most of the time, the simplest way to create a future is to just use
 * one of the [Future] constructors to capture the result of a single
 * asynchronous computation:
 *
 *     new Future(() { doSomething(); return result; });
 *
 * or, if the future represents the result of a sequence of asynchronous
 * computations, they can be chained using [Future.then] or similar functions
 * on [Future]:
 *
 *     Future doStuff(){
 *       return someAsyncOperation().then((result) {
 *         return someOtherAsyncOperation(result);
 *       });
 *     }
 *
 * If you do need to create a Future from scratch — for example,
 * when you're converting a callback-based API into a Future-based
 * one — you can use a Completer as follows:
 *
 *     class AsyncOperation {
 *       Completer _completer = new Completer();
 *
 *       Future<T> doOperation() {
 *         _startOperation();
 *         return _completer.future; // Send future object back to client.
 *       }
 *
 *       // Something calls this when the value is ready.
 *       void _finishOperation(T result) {
 *         _completer.complete(result);
 *       }
 *
 *       // If something goes wrong, call this.
 *       void _errorHappened(error) {
 *         _completer.completeError(error);
 *       }
 *     }
 */
abstract class Completer<T> {

  /**
   * Creates a new completer.
   *
   * The general workflow for creating a new future is to 1) create a
   * new completer, 2) hand out its future, and, at a later point, 3) invoke
   * either [complete] or [completeError].
   *
   * The completer completes the future asynchronously. That means that
   * callbacks registered on the future, are not called immediately when
   * [complete] or [completeError] is called. Instead the callbacks are
   * delayed until a later microtask.
   *
   * Example:
   *
   *     var completer = new Completer();
   *     handOut(completer.future);
   *     later: {
   *       completer.complete('completion value');
   *     }
   */
  factory Completer() => new _AsyncCompleter<T>();

  /**
   * Completes the future synchronously.
   *
   * This constructor should be avoided unless the completion of the future is
   * known to be the final result of another asynchronous operation. If in doubt
   * use the default [Completer] constructor.
   *
   * Using an normal, asynchronous, completer will never give the wrong
   * behavior, but using a synchronous completer incorrectly can cause
   * otherwise correct programs to break.
   *
   * An asynchronous completer is only intended for optimizing event
   * propagation when one asynchronous event immediately triggers another.
   * It should not be used unless the calls to [complete] and [completeError]
   * are guaranteed to occur in places where it won't break `Future` invariants.
   *
   * Completing synchronously means that the completer's future will be
   * completed immediately when calling the [complete] or [completeError]
   * method on a synchronous completer, which also calls any callbacks
   * registered on that future.
   *
   * Completing synchronously must not break the rule that when you add a
   * callback on a future, that callback must not be called until the code
   * that added the callback has completed.
   * For that reason, a synchronous completion must only occur at the very end
   * (in "tail position") of another synchronous event,
   * because at that point, completing the future immediately is be equivalent
   * to returning to the event loop and completing the future in the next
   * microtask.
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
  Future<T> get future;

  /**
   * Completes [future] with the supplied values.
   *
   * The value must be either a value of type [T]
   * or a future of type `Future<T>`.
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
   * If [error] is `null`, it is replaced by a [NullThrownError].
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

// Helper function completing a _Future with error, but checking the zone
// for error replacement first.
void _completeWithErrorCallback(_Future result, error, stackTrace) {
  AsyncError replacement = Zone.current.errorCallback(error, stackTrace);
  if (replacement != null) {
    error = _nonNullError(replacement.error);
    stackTrace = replacement.stackTrace;
  }
  result._completeError(error, stackTrace);
}

/** Helper function that converts `null` to a [NullThrownError]. */
Object _nonNullError(Object error) =>
  (error != null) ? error : new NullThrownError();
