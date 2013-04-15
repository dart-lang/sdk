// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.async;

/**
 * A [Future] represents a delayed computation. It is used to obtain a not-yet
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
   * asynchronously with [runAsync].
   *
   * if the result of executing [computation] throws, the returned future is
   * completed with the error. If a thrown value is an [AsyncError], it is used
   * directly, instead of wrapping this error again in another [AsyncError].
   *
   * If the returned value is itself a [Future], completion of
   * the created future will wait until the returned future completes,
   * and will then complete with the same result.
   *
   * If a value is returned, it becomes the result of the created future.
   */
  factory Future(computation()) {
    _ThenFuture<dynamic, T> future =
        new _ThenFuture<dynamic, T>((_) => computation());
    runAsync(() => future._sendValue(null));
    return future;
  }

  /**
   * Creates a future containing the result of immediately calling
   * [computation].
   *
   * if the result of executing [computation] throws, the returned future is
   * completed with the error. If a thrown value is an [AsyncError], it is used
   * directly, instead of wrapping this error again in another [AsyncError].
   *
   * If the returned value is itself a [Future], completion of
   * the created future will wait until the returned future completes,
   * and will then complete with the same result.
   */
  factory Future.sync(computation()) {
    try {
      var result = computation();
      return new _FutureImpl<T>().._setOrChainValue(result);
    } catch (error, stackTrace) {
      return new _FutureImpl<T>.immediateError(error, stackTrace);
    }
  }

  /**
   * A future whose value is available in the next event-loop iteration.
   *
   * If [value] is not a [Future], using this constructor is equivalent
   * to [:new Future.sync(() => value):].
   *
   * See [Completer] to create a Future and complete it later.
   */
  factory Future.value([T value]) => new _FutureImpl<T>.immediate(value);

  /**
   * A future that completes with an error in the next event-loop iteration.
   *
   * See [Completer] to create a Future and complete it later.
   */
  factory Future.error(var error, [Object stackTrace]) {
    return new _FutureImpl<T>.immediateError(error, stackTrace);
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
    // TODO(floitsch): no need to allocate a ThenFuture when the computation is
    // null.
    if (computation == null) computation = (() => null);
    _ThenFuture<dynamic, T> future =
        new _ThenFuture<dynamic, T>((_) => computation());
    new Timer(duration, () => future._sendValue(null));
    return future;
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
    return new _FutureImpl<List>.wait(futures);
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
    _FutureImpl doneSignal = new _FutureImpl();
    Iterator iterator = input.iterator;
    void nextElement(_) {
      if (iterator.moveNext()) {
        new Future.sync(() => f(iterator.current))
            .then(nextElement, onError: doneSignal._setError);
      } else {
        doneSignal._setValue(null);
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
   * If [onError] is not given, it is equivalent to `(e) { throw e; }`. That
   * is, it forwards the error to `f`.
   *
   * In most cases, it is more readable to use [catchError] separately, possibly
   * with a `test` parameter, instead of handling both value and error in a
   * single [then] call.
   */
  Future then(onValue(T value), { onError(Object error) });

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
   *                 onError: (e) {
   *                   if (test == null || test(e)) {
   *                     return onError(e);
   *                   }
   *                   throw e;
   *                 });
   *     }
   *
   */
  Future catchError(onError(Object error),
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
 * A [Completer] is used to produce [Future]s and supply their value when it
 * becomes available.
 *
 * A service that provides values to callers, and wants to return [Future]s can
 * use a [Completer] as follows:
 *
 *     Completer completer = new Completer();
 *     // send future object back to client...
 *     return completer.future;
 *     ...
 *
 *     // later when value is available, call:
 *     completer.complete(value);
 *
 *     // alternatively, if the service cannot produce the value, it
 *     // can provide an error:
 *     completer.completeError(error);
 *
 */
abstract class Completer<T> {

  factory Completer() => new _CompleterImpl<T>();

  /** The future that will contain the result provided to this completer. */
  Future get future;

  /**
   * Completes [future] with the supplied values.
   *
   * All listeners on the future will be immediately informed about the value.
   */
  void complete([T value]);

  /**
   * Complete [future] with an error.
   *
   * Completing a future with an error indicates that an exception was thrown
   * while trying to produce a value.
   *
   * The argument [exception] should not be `null`.
   */
  void completeError(Object exception, [Object stackTrace]);

  /**
   * Whether the future has been completed.
   */
  bool get isCompleted;
}
