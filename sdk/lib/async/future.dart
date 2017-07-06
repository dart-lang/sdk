// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "async.dart";

/// A type representing values that are either `Future<T>` or `T`.
///
/// This class declaration is a public stand-in for an internal
/// future-or-value generic type. References to this class are resolved to the
/// internal type.
///
/// It is a compile-time error for any class to extend, mix in or implement
/// `FutureOr`.
///
/// Note: the `FutureOr<T>` type is interpreted as `dynamic` in non strong-mode.
///
/// # Examples
/// ``` dart
/// // The `Future<T>.then` function takes a callback [f] that returns either
/// // an `S` or a `Future<S>`.
/// Future<S> then<S>(FutureOr<S> f(T x), ...);
///
/// // `Completer<T>.complete` takes either a `T` or `Future<T>`.
/// void complete(FutureOr<T> value);
/// ```
///
/// # Advanced
/// The `FutureOr<int>` type is actually the "type union" of the types `int` and
/// `Future<int>`. This type union is defined in such a way that
/// `FutureOr<Object>` is both a super- and sub-type of `Object` (sub-type
/// because `Object` is one of the types of the union, super-type because
/// `Object` is a super-type of both of the types of the union). Together it
/// means that `FutureOr<Object>` is equivalent to `Object`.
///
/// As a corollary, `FutureOr<Object>` is equivalent to
/// `FutureOr<FutureOr<Object>>`, `FutureOr<Future<Object>> is equivalent to
/// `Future<Object>`.
abstract class FutureOr<T> {
  // Private generative constructor, so that it is not subclassable, mixable, or
  // instantiable.
  FutureOr._() {
    throw new UnsupportedError("FutureOr can't be instantiated");
  }
}

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
 * A [Future] can be completed in two ways:
 * with a value ("the future succeeds")
 * or with an error ("the future fails").
 * Users can install callbacks for each case.
 *
 * In some cases we say that a future is completed with another future.
 * This is a short way of stating that the future is completed in the same way,
 * with the same value or error,
 * as the other future once that completes.
 * Whenever a function in the core library may complete a future
 * (for example [Completer.complete] or [new Future.value]),
 * then it also accepts another future and does this work for the developer.
 *
 * The result of registering a pair of callbacks is a new Future (the
 * "successor") which in turn is completed with the result of invoking the
 * corresponding callback.
 * The successor is completed with an error if the invoked callback throws.
 * For example:
 * ```
 * Future<int> successor = future.then((int value) {
 *     // Invoked when the future is completed with a value.
 *     return 42;  // The successor is completed with the value 42.
 *   },
 *   onError: (e) {
 *     // Invoked when the future is completed with an error.
 *     if (canHandle(e)) {
 *       return 499;  // The successor is completed with the value 499.
 *     } else {
 *       throw e;  // The successor is completed with the error e.
 *     }
 *   });
 * ```
 *
 * If a future does not have a successor when it completes with an error,
 * it forwards the error message to the global error-handler.
 * This behavior makes sure that no error is silently dropped.
 * However, it also means that error handlers should be installed early,
 * so that they are present as soon as a future is completed with an error.
 * The following example demonstrates this potential bug:
 * ```
 * var future = getFuture();
 * new Timer(new Duration(milliseconds: 5), () {
 *   // The error-handler is not attached until 5 ms after the future has
 *   // been received. If the future fails before that, the error is
 *   // forwarded to the global error-handler, even though there is code
 *   // (just below) to eventually handle the error.
 *   future.then((value) { useValue(value); },
 *               onError: (e) { handleError(e); });
 * });
 * ```
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
 * ```
 * // Synchronous code.
 * try {
 *   int value = foo();
 *   return bar(value);
 * } catch (e) {
 *   return 499;
 * }
 * ```
 *
 * Equivalent asynchronous code, based on futures:
 * ```
 * Future<int> future = new Future(foo);  // Result of foo() as a future.
 * future.then((int value) => bar(value))
 *       .catchError((e) => 499);
 * ```
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
  /// A `Future<Null>` completed with `null`.
  static final _Future<Null> _nullFuture = new _Future<Null>.value(null);

  /// A `Future<bool>` completed with `false`.
  static final _Future<bool> _falseFuture = new _Future<bool>.value(false);

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
  factory Future(FutureOr<T> computation()) {
    _Future<T> result = new _Future<T>();
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
  factory Future.microtask(FutureOr<T> computation()) {
    _Future<T> result = new _Future<T>();
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
   * Returns a future containing the result of immediately calling
   * [computation].
   *
   * If calling [computation] throws, the returned future is completed with the
   * error.
   *
   * If calling [computation] returns a `Future<T>`, that future is returned.
   *
   * If calling [computation] returns a non-future value,
   * a future is returned which has been completed with that value.
   */
  factory Future.sync(FutureOr<T> computation()) {
    try {
      var result = computation();
      if (result is Future<T>) {
        return result;
      } else if (result is Future) {
        // TODO(lrn): Remove this case for Dart 2.0.
        return new _Future<T>.immediate(result);
      } else {
        return new _Future<T>.value(result);
      }
    } catch (error, stackTrace) {
      var future = new _Future<T>();
      AsyncError replacement = Zone.current.errorCallback(error, stackTrace);
      if (replacement != null) {
        future._asyncCompleteError(
            _nonNullError(replacement.error), replacement.stackTrace);
      } else {
        future._asyncCompleteError(error, stackTrace);
      }
      return future;
    }
  }

  /**
   * Creates a future completed with [value].
   *
   * If [value] is a future, the created future waits for the
   * [value] future to complete, and then completes with the same result.
   * Since a [value] future can complete with an error, so can the future
   * created by [Future.value], even if the name suggests otherwise.
   *
   * If [value] is not a [Future], the created future is completed
   * with the [value] value,
   * equivalently to `new Future<T>.sync(() => value)`.
   *
   * Use [Completer] to create a future and complete it later.
   */
  factory Future.value([FutureOr<T> value]) {
    return new _Future<T>.immediate(value);
  }

  /**
   * Creates a future that completes with an error.
   *
   * The created future will be completed with an error in a future microtask.
   * This allows enough time for someone to add an error handler on the future.
   * If an error handler isn't added before the future completes, the error
   * will be considered unhandled.
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
   * and the future is completed with the result of the computation,
   *
   * If the duration is 0 or less,
   * it completes no sooner than in the next event-loop iteration,
   * after all microtasks have run.
   *
   * If [computation] is omitted,
   * it will be treated as if [computation] was `() => null`,
   * and the future will eventually complete with the `null` value.
   *
   * If calling [computation] throws, the created future will complete with the
   * error.
   *
   * See also [Completer] for a way to create and complete a future at a
   * later time that isn't necessarily after a known fixed duration.
   */
  factory Future.delayed(Duration duration, [FutureOr<T> computation()]) {
    _Future<T> result = new _Future<T>();
    new Timer(duration, () {
      try {
        result._complete(computation?.call());
      } catch (e, s) {
        _completeWithErrorCallback(result, e, s);
      }
    });
    return result;
  }

  /**
   * Waits for multiple futures to complete and collects their results.
   *
   * Returns a future which will complete once all the provided futures
   * have completed, either with their results, or with an error if either
   * of the provided futures fail.
   *
   * The value of the returned future will be a list of all the values that
   * were produced.
   *
   * If any future completes with an error,
   * then the returned future completes with that error.
   * If further futures also complete with errors, those errors are discarded.
   *
   * If `eagerError` is true, the returned future completes with an error
   * immediately on the first error from one of the futures. Otherwise all
   * futures must complete before the returned future is completed (still with
   * the first error; the remaining errors are silently dropped).
   *
   * In the case of an error, [cleanUp] (if provided), is invoked on any
   * non-null result of successful futures.
   * This makes it possible to `cleanUp` resources that would otherwise be
   * lost (since the returned future does not provide access to these values).
   * The [cleanUp] function is unused if there is no error.
   *
   * The call to [cleanUp] should not throw. If it does, the error will be an
   * uncaught asynchronous error.
   */
  static Future<List<T>> wait<T>(Iterable<Future<T>> futures,
      {bool eagerError: false, void cleanUp(T successValue)}) {
    final _Future<List<T>> result = new _Future<List<T>>();
    List<T> values; // Collects the values. Set to null on error.
    int remaining = 0; // How many futures are we waiting for.
    var error; // The first error from a future.
    StackTrace stackTrace; // The stackTrace that came with the error.

    // Handle an error from any of the futures.
    // TODO(jmesserly): use `void` return type once it can be inferred for the
    // `then` call below.
    handleError(theError, theStackTrace) {
      remaining--;
      if (values != null) {
        if (cleanUp != null) {
          for (var value in values) {
            if (value != null) {
              // Ensure errors from cleanUp are uncaught.
              new Future.sync(() {
                cleanUp(value);
              });
            }
          }
        }
        values = null;
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

    try {
      // As each future completes, put its value into the corresponding
      // position in the list of values.
      for (Future future in futures) {
        int pos = remaining;
        future.then((T value) {
          remaining--;
          if (values != null) {
            values[pos] = value;
            if (remaining == 0) {
              result._completeWithValue(values);
            }
          } else {
            if (cleanUp != null && value != null) {
              // Ensure errors from cleanUp are uncaught.
              new Future.sync(() {
                cleanUp(value);
              });
            }
            if (remaining == 0 && !eagerError) {
              result._completeError(error, stackTrace);
            }
          }
        }, onError: handleError);
        // Increment the 'remaining' after the call to 'then'.
        // If that call throws, we don't expect any future callback from
        // the future, and we also don't increment remaining.
        remaining++;
      }
      if (remaining == 0) {
        return new Future.value(const []);
      }
      values = new List<T>(remaining);
    } catch (e, st) {
      // The error must have been thrown while iterating over the futures
      // list, or while installing a callback handler on the future.
      if (remaining == 0 || eagerError) {
        // Throw a new Future.error.
        // Don't just call `result._completeError` since that would propagate
        // the error too eagerly, not giving the callers time to install
        // error handlers.
        // Also, don't use `_asyncCompleteError` since that one doesn't give
        // zones the chance to intercept the error.
        return new Future.error(e, st);
      } else {
        // Don't allocate a list for values, thus indicating that there was an
        // error.
        // Set error to the caught exception.
        error = e;
        stackTrace = st;
      }
    }
    return result;
  }

  /**
   * Returns the result of the first future in [futures] to complete.
   *
   * The returned future is completed with the result of the first
   * future in [futures] to report that it is complete,
   * whether it's with a value or an error.
   * The results of all the other futures are discarded.
   *
   * If [futures] is empty, or if none of its futures complete,
   * the returned future never completes.
   */
  static Future<T> any<T>(Iterable<Future<T>> futures) {
    var completer = new Completer<T>.sync();
    var onValue = (T value) {
      if (!completer.isCompleted) completer.complete(value);
    };
    var onError = (error, stack) {
      if (!completer.isCompleted) completer.completeError(error, stack);
    };
    for (var future in futures) {
      future.then(onValue, onError: onError);
    }
    return completer.future;
  }

  /**
   * Performs an action for each element of the iterable, in turn.
   *
   * The [action] may be either synchronous or asynchronous.
   *
   * Calls [action] with each element in [elements] in order.
   * If the call to [action] returns a `Future<T>`, the iteration waits
   * until the future is completed before continuing with the next element.
   *
   * Returns a [Future] that completes with `null` when all elements have been
   * processed.
   *
   * Non-[Future] return values, and completion-values of returned [Future]s,
   * are discarded.
   *
   * Any error from [action], synchronous or asynchronous,
   * will stop the iteration and be reported in the returned [Future].
   */
  static Future forEach<T>(Iterable<T> elements, FutureOr action(T element)) {
    var iterator = elements.iterator;
    return doWhile(() {
      if (!iterator.moveNext()) return false;
      var result = action(iterator.current);
      if (result is Future) return result.then(_kTrue);
      return true;
    });
  }

  // Constant `true` function, used as callback by [forEach].
  static bool _kTrue(_) => true;

  /**
   * Performs an operation repeatedly until it returns `false`.
   *
   * The operation, [action], may be either synchronous or asynchronous.
   *
   * The operation is called repeatedly as long as it returns either the [bool]
   * value `true` or a `Future<bool>` which completes with the value `true`.
   *
   * If a call to [action] returns `false` or a [Future] that completes to
   * `false`, iteration ends and the future returned by [doWhile] is completed
   * with a `null` value.
   *
   * If a call to [action] throws or a future returned by [action] completes
   * with an error, iteration ends and the future returned by [doWhile]
   * completes with the same error.
   *
   * Calls to [action] may happen at any time,
   * including immediately after calling `doWhile`.
   * The only restriction is a new call to [action] won't happen before
   * the previous call has returned, and if it returned a `Future<bool>`, not
   * until that future has completed.
   */
  static Future doWhile(FutureOr<bool> action()) {
    _Future doneSignal = new _Future();
    var nextIteration;
    // Bind this callback explicitly so that each iteration isn't bound in the
    // context of all the previous iterations' callbacks.
    // This avoids, e.g., deeply nested stack traces from the stack trace
    // package.
    nextIteration = Zone.current.bindUnaryCallback((bool keepGoing) {
      while (keepGoing) {
        FutureOr<bool> result;
        try {
          result = action();
        } catch (error, stackTrace) {
          // Cannot use _completeWithErrorCallback because it completes
          // the future synchronously.
          _asyncCompleteWithErrorCallback(doneSignal, error, stackTrace);
          return;
        }
        if (result is Future<bool>) {
          result.then(nextIteration, onError: doneSignal._completeError);
          return;
        }
        keepGoing = result;
      }
      doneSignal._complete(null);
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
   *
   * Note that futures don't delay reporting of errors until listeners are
   * added. If the first `then` or `catchError` call happens after this future
   * has completed with an error then the error is reported as unhandled error.
   * See the description on [Future].
   */
  Future<S> then<S>(FutureOr<S> onValue(T value), {Function onError});

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
   * if the `onError` function had thrown.
   *
   * Note that futures don't delay reporting of errors until listeners are
   * added. If the first `catchError` (or `then`) call happens after this future
   * has completed with an error then the error is reported as unhandled error.
   * See the description on [Future].
   */
  // The `Function` below stands for one of two types:
  // - (dynamic) -> FutureOr<T>
  // - (dynamic, StackTrace) -> FutureOr<T>
  // Given that there is a `test` function that is usually used to do an
  // `isCheck` we should also expect functions that take a specific argument.
  // Note: making `catchError` return a `Future<T>` in non-strong mode could be
  // a breaking change.
  Future<T> catchError(Function onError, {bool test(Object error)});

  /**
   * Registers a function to be called when this future completes.
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
  Future<T> whenComplete(FutureOr action());

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
   * The [onTimeout] function must return a [T] or a `Future<T>`.
   *
   * If `onTimeout` is omitted, a timeout will cause the returned future to
   * complete with a [TimeoutException].
   */
  Future<T> timeout(Duration timeLimit, {FutureOr<T> onTimeout()});
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
 * ```
 * new Future(() { doSomething(); return result; });
 * ```
 * or, if the future represents the result of a sequence of asynchronous
 * computations, they can be chained using [Future.then] or similar functions
 * on [Future]:
 * ```
 * Future doStuff(){
 *   return someAsyncOperation().then((result) {
 *     return someOtherAsyncOperation(result);
 *   });
 * }
 * ```
 * If you do need to create a Future from scratch — for example,
 * when you're converting a callback-based API into a Future-based
 * one — you can use a Completer as follows:
 * ```
 * class AsyncOperation {
 *   Completer _completer = new Completer();
 *
 *   Future<T> doOperation() {
 *     _startOperation();
 *     return _completer.future; // Send future object back to client.
 *   }
 *
 *   // Something calls this when the value is ready.
 *   void _finishOperation(T result) {
 *     _completer.complete(result);
 *   }
 *
 *   // If something goes wrong, call this.
 *   void _errorHappened(error) {
 *     _completer.completeError(error);
 *   }
 * }
 * ```
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
   * callbacks registered on the future are not called immediately when
   * [complete] or [completeError] is called. Instead the callbacks are
   * delayed until a later microtask.
   *
   * Example:
   * ```
   * var completer = new Completer();
   * handOut(completer.future);
   * later: {
   *   completer.complete('completion value');
   * }
   * ```
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
   * A synchronous completer is only intended for optimizing event
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

  /**
   * The future that is completed by this completer.
   *
   * The future that is completed when [complete] or [completeError] is called.
   */
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
   * Calling [complete] or [completeError] must be done at most once.
   *
   * All listeners on the future are informed about the value.
   */
  void complete([FutureOr<T> value]);

  /**
   * Complete [future] with an error.
   *
   * Calling [complete] or [completeError] must be done at most once.
   *
   * Completing a future with an error indicates that an exception was thrown
   * while trying to produce a value.
   *
   * If [error] is `null`, it is replaced by a [NullThrownError].
   *
   * If `error` is a `Future`, the future itself is used as the error value.
   * If you want to complete with the result of the future, you can use:
   * ```
   * thisCompleter.complete(theFuture)
   * ```
   * or if you only want to handle an error from the future:
   * ```
   * theFuture.catchError(thisCompleter.completeError);
   * ```
   */
  void completeError(Object error, [StackTrace stackTrace]);

  /**
   * Whether the [future] has been completed.
   *
   * Reflects whether [complete] or [completeError] has been called.
   * A `true` value doesn't necessarily mean that listeners of this future
   * have been invoked yet, either because the completer usually waits until
   * a later microtask to propagate the result, or because [complete]
   * was called with a future that hasn't completed yet.
   *
   * When this value is `true`, [complete] and [completeError] must not be
   * called again.
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

// Like [_completeWithErrorCallback] but completes asynchronously.
void _asyncCompleteWithErrorCallback(_Future result, error, stackTrace) {
  AsyncError replacement = Zone.current.errorCallback(error, stackTrace);
  if (replacement != null) {
    error = _nonNullError(replacement.error);
    stackTrace = replacement.stackTrace;
  }
  result._asyncCompleteError(error, stackTrace);
}

/** Helper function that converts `null` to a [NullThrownError]. */
Object _nonNullError(Object error) => error ?? new NullThrownError();
