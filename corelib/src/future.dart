// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart core library.


/**
 * A Future is used to obtain a value sometime in the
 * future.
 *
 * Receivers of a Future obtain the value by passing
 * a callback to the 'then' method of Future.
 *
 * For example:
 *
 *   Future<int> future = getFutureFromSomewhere();
 *   future.then((value) {
 *     print("I received the number " + value);
 *   });
 *
 */
interface Future<T> factory FutureImpl<T> {

  /**
   * The value this future provided.  (If called when hasValue
   * is false, then throws an exception.)
   */
  T get value();

  /**
   * Exception that occurred (null if no exception occured).  (If called
   * before [isComplete] is true, then this exception property itself
   * throws a FutureNotCompleteException.)
   */
  Object get exception();

  /**
   * Whether the future is complete (either the value is available or there
   * was an exception).
   */
  bool get isComplete();

  /**
   * Whether the value is available (meaning isComplete is true, and there
   * was no exception).
   */
  bool get hasValue();

  /**
   * When this future is complete and has a value, then call
   * the onComplete callback function with the value.
   */
  void then(void onComplete(T value));

  /**
   * If this future gets an exception, then call onException.
   *
   * If onException returns true, then the exception is considered
   * handled.
   *
   * If onException does not return true (or handleException was never called),
   * then the exception is not considered handled.  In that case, if there were
   * any calls to [then] (meaning that there are onComplete callbacks waiting
   * for the value), then the exception will be thrown when it is set.
   *
   * (In most cases it should not be necessary to call handleException,
   * because the exception associated with this Future will propagate naturally
   * if the future's value is being consumed.  Only call handleException if you
   * need to do some special local exception handling related to this
   * particular Future's value.)
   */
  void handleException(bool onException(Object exception));
}


/**
 * A Completer is used to produce Future objects, and supply
 * a value to the Future object when the value becomes available.
 *
 * A service that provides values to callers, and wants to return Future objects
 * rather than returning the values immediately, can use a Completer as follows:
 *
 *   Completer completer = new Completer();
 *   Future future = completer.future;
 *
 *   // send [future] object back to client...
 *
 *   // later when value is available, call:
 *   completer.complete(value);
 *
 *   // alternatively, if the service cannot produce the value, it
 *   // can provide an exception:
 *   completer.completeException(exception);
 *
 */
interface Completer<T> factory CompleterImpl<T> {

  /** Create a completer */
  Completer();

  Future get future();

  /**
   * Called when value is available.
   */
  void complete(T value);

  /**
   * Called if an exception occured while trying to produce value.
   */
  void completeException(Object exception);
}
