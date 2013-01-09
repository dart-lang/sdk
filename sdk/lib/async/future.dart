// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.async;

/**
 * A [Future] is used to obtain a value sometime in the future.  Receivers of a
 * [Future] can obtain the value by passing a callback to [then]. For example:
 *
 *     Future<int> future = getFutureFromSomewhere();
 *     future.then((value) {
 *       print("I received the number $value");
 *     });
 *
 * A future may complete by *succeeding* (producing a value) or *failing*
 * (producing an error, which may be handled with [catchError]).
 *
 * When a future completes, the following actions happen in order:
 *
 *   1. if the future suceeded, handlers registered with [then] are called.
 *   2. if the future failed, handlers registered with [catchError] are
 *      tested in sequence. Each test returning true is, have its handler
 *      called.
 *   4. if the future failed, and no handler registered with [catchError] it
 *      is accepting the error, an error is sent to the global error handler.
 *
 * [Future]s are usually not created directly, but with [Completer]s.
 */
abstract class Future<T> {
  /** A future whose value is immediately available. */
  factory Future.immediate(T value) => new _FutureImpl<T>.immediate(value);

  /** A future that completes with an error. */
  factory Future.immediateError(var error, [Object stackTrace]) {
    return new _FutureImpl<T>.immediateError(error, stackTrace);
  }

  // TODO(floitsch): I don't think the typing is right here.
  // Otherwise new Future<int>.wait(...) would be a Future<List<int>>. Sounds
  // wrong.
  factory Future.wait(List<Future> futures)
    => new _FutureImpl<List<T>>.wait(futures);

  factory Future.delayed(int milliseconds, dynamic value()) {
    var completer = new Completer<T>();
    new Timer(milliseconds, (_) => completer.complete(null));
    return completer.future.then((_) => value());
  }

  /**
   * When this future completes with a value, then [onValue] is called with this
   * value. If [this] future is already completed then the invocation of
   * [onValue] is delayed until the next event-loop iteration.
   *
   * Returns a new [Future] [:f:].
   *
   * If [this] is completed with an error then [:f:] is completed with the same
   * error. If [this] is completed with a value, then [:f:]'s completion value
   * depends on the result of invoking [onValue] with [this]' completion value.
   *
   * If [onValue] returns a [Future] [:f2:] then [:f:] and [:f2:] are chained.
   * That is, [:f:] is completed with the completion value of [:f2:].
   *
   * Otherwise [:f:] is completed with the return value of [onValue].
   *
   * If [onValue] throws an exception, the returned future will receive the
   * exception.
   *
   * If [onError] is provided, it is called if this future completes with an
   * error, and its return value/throw behavior is handled the same way as
   * for [onValue].
   *
   * In most cases, it is more readable to use [catchError] separately, possibly
   * with a [:test:] parameter, instead of handling both value and error in a
   * single [then] call.
   */
  Future then(onValue(T value), { onError(AsyncError asyncError) });

  /**
   * If this future is complete with an error, [test] is called with the error.
   * If [test] returns [true], [onError] is called with the error
   * wrapped in an [AsyncError]. The result of [onError] is handled exactly as
   * [then]'s [onValue]. If [test] returns false, the exception is not handled
   * by [onError]. If [test] is omitted, it defaults to a function that always
   * returns true.
   *
   * Example:
   * foo
   *   .catchError(..., test: (e) => e is ArgumentError)
   *   .catchError(..., test: (e) => e is NoSuchMethodError)
   *   .then((v) { ... });
   */
  Future catchError(onError(AsyncError asyncError),
                    {bool test(Object error)});

  /**
   * Register a function to be called when this future completes.
   *
   * The [action] function is called when this future completes, whether it
   * does so with a value or with an error.
   *
   * This is the asynchronous equivalent of a "finally" block.
   *
   * If the call to [action] does not throw, the returned future is completed
   * with the same result as this future.
   *
   * If the call to [action] throws, the returned future is completed with the
   * thrown error.
   */
  Future<T> whenComplete(void action());

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
   * The argument [exception] should not be [:null:]. A [stackTrace]
   * object can be provided as well, to give the user information about where
   * the error occurred. If omitted, it will be [:null:].
   */
  void completeError(Object exception, [Object stackTrace]);
}

class Futures {
  /**
   * Returns a future which will complete once all the futures in a list are
   * complete. If any of the futures in the list completes with an exception,
   * the resulting future also completes with an exception. (The value of the
   * returned future will be a list of all the values that were produced.)
   */
  static Future<List> wait(Iterable<Future> futures) {
    return new _FutureImpl<List>.wait(futures);
  }

  /**
   * Runs [f] for each element in [input] in order, moving to the next element
   * only when the [Future] returned by [f] completes. Returns a [Future] that
   * completes when all elements have been processed.
   *
   * The return values of all [Future]s are discarded. Any errors will cause the
   * iteration to stop and will be piped through the returned [Future].
   */
  static Future forEach(Iterable input, Future f(element)) {
    var iterator = input.iterator;
    Future nextElement(_) {
      if (!iterator.moveNext()) return new Future.immediate(null);
      return f(iterator.current).then(nextElement);
    }
    return nextElement(null);
  }
}
