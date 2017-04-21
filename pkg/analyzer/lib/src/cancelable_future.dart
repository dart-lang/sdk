// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.cancelable_future;

import 'dart:async';

/**
 * Type of callback called when the future returned by a CancelableCompleter
 * is canceled.
 */
typedef void CancelHandler();

/**
 * A way to produce [CancelableFuture] objects and to complete them later with
 * a value or error.
 *
 * This class behaves like the standard library [Completer] class, except that
 * its [future] getter returns a [CancelableFuture].
 *
 * If the future is canceled before being completed, the [CancelHandler] which
 * was passed to the constructor is invoked, and any further attempt to
 * complete the future has no effect.  For example, in the following code:
 *
 *     main() {
 *       var cc = new CancelableCompleter(() {
 *         print('cancelled'); // (2)
 *       });
 *       cc.future.then((value) {
 *         print('completed with value $value');
 *       }, onError: (error) {
 *         print('completed with error $error'); // (3)
 *       });
 *       cc.future.cancel(); // (1)
 *     }
 *
 * The call at (1) causes (2) to be invoked immediately.  (3) will be invoked
 * later (on a microtask), with an error that is an instance of
 * [FutureCanceledError].
 *
 * Note that since the closure passed to then() is executed on a microtask,
 * there is a short window of time between the call to [complete] and the
 * client being informed that the future has completed.  During this window,
 * any attempt to cancel the future will have no effect.  For example, in the
 * following code:
 *
 *     main() {
 *       var cc = new CancelableCompleter(() {
 *         print('cancelled'); // (3)
 *       });
 *       cc.future.then((value) {
 *         print('completed with value $value'); // (4)
 *       }, onError: (error) {
 *         print('completed with error $error');
 *       });
 *       cc.complete(100); // (1)
 *       cc.future.cancel(); // (2)
 *     }
 *
 * The call at (1) will place the completer in the "completed" state, so the
 * call at (2) will have no effect (in particular, (3) won't ever execute).
 * Later, (4) will be invoked on a microtask.
 */
class CancelableCompleter<T> implements Completer<T> {
  /**
   * The completer which holds the state of the computation.  If the
   * computation is canceled, this completer will remain in the non-completed
   * state.
   */
  final Completer<T> _innerCompleter = new Completer<T>.sync();

  /**
   * The completer which holds the future that is exposed to the client
   * through [future].  If the computation is canceled, this completer will
   * be completed with a FutureCanceledError.
   */
  final Completer<T> _outerCompleter = new Completer<T>();

  /**
   * The callback to invoke if the 'cancel' method is called on the future
   * returned by [future].  This callback will only be invoked if the future
   * is canceled before being completed.
   */
  final CancelHandler _onCancel;

  _CancelableCompleterFuture<T> _future;

  /**
   * Create a CancelableCompleter that will invoke the given callback
   * synchronously if its future is canceled.  The callback will not be
   * invoked if the future is completed before being canceled.
   */
  CancelableCompleter(this._onCancel) {
    _future = new _CancelableCompleterFuture<T>(this);

    // When the client completes the inner completer, we need to check whether
    // the outer completer has been completed.  If it has, then the operation
    // was canceled before it finished, and it's too late to un-cancel it, so
    // we just ignore the result from the inner completer.  If it hasn't, then
    // we simply pass along the result from the inner completer to the outer
    // completer.
    //
    // Note that the reason it is safe for the inner completer to be
    // synchronous is that we don't expose its future to client code, and we
    // only use it to complete the outer completer (which is asynchronous).
    _innerCompleter.future.then((T value) {
      if (!_outerCompleter.isCompleted) {
        _outerCompleter.complete(value);
      }
    }, onError: (Object error, StackTrace stackTrace) {
      if (!_outerCompleter.isCompleted) {
        _outerCompleter.completeError(error, stackTrace);
      }
    });
  }

  /**
   * The [CancelableFuture] that will contain the result provided to this
   * completer.
   */
  @override
  CancelableFuture<T> get future => _future;

  /**
   * Whether the future has been completed.  This is independent of whether
   * the future has been canceled.
   */
  @override
  bool get isCompleted => _innerCompleter.isCompleted;

  /**
   * Complete [future] with the supplied value.  If the future has previously
   * been canceled, this will have no effect on [future], however it will
   * still set [isCompleted] to true.
   */
  @override
  void complete([value]) {
    _innerCompleter.complete(value);
  }

  /**
   * Complete [future] with an error.  If the future has previously been
   * canceled, this will have no effect on [future], however it will still set
   * [isCompleted] to true.
   */
  @override
  void completeError(Object error, [StackTrace stackTrace]) {
    _innerCompleter.completeError(error, stackTrace);
  }

  void _cancel() {
    if (!_outerCompleter.isCompleted) {
      _outerCompleter.completeError(new FutureCanceledError());
      _onCancel();
    }
  }
}

/**
 * An object representing a delayed computation that can be canceled.
 */
abstract class CancelableFuture<T> implements Future<T> {
  /**
   * A CancelableFuture containing the result of calling [computation]
   * asynchronously.  Since the computation is started without delay, calling
   * the future's cancel method will have no effect.
   */
  factory CancelableFuture(computation()) =>
      new _WrappedFuture<T>(new Future<T>(computation));

  /**
   * A CancelableFuture containing the result of calling [computation] after
   * [duration] has passed.
   *
   * TODO(paulberry): if the future is canceled before the duration has
   * elapsed, the computation should not be performed.
   */
  factory CancelableFuture.delayed(Duration duration, [computation()]) =>
      new _WrappedFuture<T>(new Future<T>.delayed(duration, computation));

  /**
   * A CancelableFuture that completes with error.  Since the future is
   * completed without delay, calling the future's cancel method will have no
   * effect.
   */
  factory CancelableFuture.error(Object error, [StackTrace stackTrace]) =>
      new _WrappedFuture<T>(new Future<T>.error(error, stackTrace));

  /**
   * A CancelableFuture containing the result of calling [computation]
   * asynchronously with scheduleMicrotask.  Since the computation is started
   * without delay, calling the future's cancel method will have no effect.
   */
  factory CancelableFuture.microtask(computation()) =>
      new _WrappedFuture<T>(new Future<T>.microtask(computation));

  /**
   * A CancelableFuture containing the result of immediately calling
   * [computation].  Since the computation is started without delay, calling
   * the future's cancel method will have no effect.
   */
  factory CancelableFuture.sync(computation()) =>
      new _WrappedFuture<T>(new Future<T>.sync(computation));

  /**
   * A CancelableFuture whose value is available in the next event-loop
   * iteration.  Since the value is available without delay, calling the
   * future's cancel method will have no effect.
   */
  factory CancelableFuture.value([value]) =>
      new _WrappedFuture<T>(new Future<T>.value(value));

  /**
   * If the delayed computation has not yet completed, attempt to cancel it.
   * Note that the cancellation is not always possible.  If the computation
   * could be canceled, the future is completed with a FutureCanceledError.
   * Otherwise it will behave as though cancel() was not called.
   *
   * Note that attempting to cancel a future that has already completed will
   * never succeed--futures that have already completed retain their final
   * state forever.
   */
  void cancel();
}

/**
 * Error which is used to complete any [CancelableFuture] which has been
 * successfully canceled by calling its 'cancel' method.
 */
class FutureCanceledError {}

class _CancelableCompleterFuture<T> implements CancelableFuture<T> {
  final CancelableCompleter<T> _completer;

  _CancelableCompleterFuture(this._completer);

  @override
  Stream<T> asStream() {
    // TODO(paulberry): Implement this in such a way that
    // StreamSubscription.cancel() cancels the future.
    return _completer._outerCompleter.future.asStream();
  }

  @override
  void cancel() {
    _completer._cancel();
  }

  @override
  Future<T> catchError(Function onError, {bool test(Object error)}) =>
      _completer._outerCompleter.future.catchError(onError, test: test);

  @override
  Future/*<S>*/ then/*<S>*/(FutureOr/*<S>*/ onValue(T value),
          {Function onError}) =>
      _completer._outerCompleter.future.then(onValue, onError: onError);

  @override
  Future<T> timeout(Duration timeLimit, {onTimeout()}) {
    // TODO(paulberry): Implement this in such a way that a timeout cancels
    // the future.
    return _completer._outerCompleter.future
        .timeout(timeLimit, onTimeout: onTimeout);
  }

  @override
  Future<T> whenComplete(action()) =>
      _completer._outerCompleter.future.whenComplete(action);
}

/**
 * A CancelableFuture that wraps an ordinary Future.  Attempting to cancel a
 * _WrappedFuture has no effect.
 */
class _WrappedFuture<T> implements CancelableFuture<T> {
  final Future<T> _future;

  _WrappedFuture(this._future);

  @override
  Stream<T> asStream() => _future.asStream();

  @override
  void cancel() {}

  @override
  Future<T> catchError(Function onError, {bool test(Object error)}) =>
      _future.catchError(onError, test: test);

  @override
  Future/*<S>*/ then/*<S>*/(FutureOr/*<S>*/ onValue(T value),
          {Function onError}) =>
      _future.then(onValue, onError: onError);

  @override
  Future<T> timeout(Duration timeLimit, {onTimeout()}) =>
      _future.timeout(timeLimit, onTimeout: onTimeout);

  @override
  Future<T> whenComplete(action()) => _future.whenComplete(action);
}
