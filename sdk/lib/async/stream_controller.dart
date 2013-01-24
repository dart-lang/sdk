// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.async;

// -------------------------------------------------------------------
// Controller for creating and adding events to a stream.
// -------------------------------------------------------------------

/**
 * A controller with the stream it controls.
 *
 * This controller allows sending data, error and done events on
 * its [stream].
 * This class can be used to create a simple stream that others
 * can listen on, and to push events to that stream.
 *
 * It's possible to check whether the stream is paused or not, and whether
 * it has subscribers or not, as well as getting a callback when either of
 * these change.
 */
class StreamController<T> implements StreamSink<T> {
  final _StreamImpl<T> stream;

  /**
   * A controller with a broadcast [stream]..
   *
   * The [onPauseStateChange] function is called when the stream becomes
   * paused or resumes after being paused. The current pause state can
   * be read from [isPaused]. Ignored if [:null:].
   *
   * The [onSubscriptionStateChange] function is called when the stream
   * receives its first listener or loses its last. The current subscription
   * state can be read from [hasSubscribers]. Ignored if [:null:].
   */
  StreamController.broadcast({void onPauseStateChange(),
                              void onSubscriptionStateChange()})
      : stream = new _MultiControllerStream<T>(onSubscriptionStateChange,
                                               onPauseStateChange);

  /**
   * A controller with a [stream] that supports only one single subscriber.
   *
   * The controller will buffer all incoming events until the subscriber is
   * registered.
   *
   * The [onPauseStateChange] function is called when the stream becomes
   * paused or resumes after being paused. The current pause state can
   * be read from [isPaused]. Ignored if [:null:].
   *
   * The [onSubscriptionStateChange] function is called when the stream
   * receives its first listener or loses its last. The current subscription
   * state can be read from [hasSubscribers]. Ignored if [:null:].
   */
  StreamController({void onPauseStateChange(),
                    void onSubscriptionStateChange()})
      : stream = new _SingleControllerStream<T>(onSubscriptionStateChange,
                                                onPauseStateChange);

  /**
   * Returns a view of this object that only exposes the [StreamSink] interface.
   */
  StreamSink<T> get sink => new StreamSinkView<T>(this);

  /** Whether one or more active subscribers have requested a pause. */
  bool get isPaused => stream._isPaused;

  /** Whether there are currently any subscribers on this [Stream]. */
  bool get hasSubscribers => stream._hasSubscribers;

  /**
   * Send or queue a data event.
   */
  void add(T value) => stream._add(value);

  /**
   * Send or enqueue an error event.
   *
   * If [error] is not an [AsyncError], [error] and an optional [stackTrace]
   * is combined into an [AsyncError] and sent this stream's listeners.
   *
   * Otherwise, if [error] is an [AsyncError], it is used directly as the
   * error object reported to listeners, and the [stackTrace] is ignored.
   *
   * If a subscription has requested to be unsubscribed on errors,
   * it will be unsubscribed after receiving this event.
   */
  void signalError(Object error, [Object stackTrace]) {
    AsyncError asyncError;
    if (error is AsyncError) {
      asyncError = error;
    } else {
      asyncError = new AsyncError(error, stackTrace);
    }
    stream._signalError(asyncError);
  }

  /**
   * Send or enqueue a "done" message.
   *
   * The "done" message should be sent at most once by a stream, and it
   * should be the last message sent.
   */
  void close() { stream._close(); }
}

typedef void _NotificationHandler();

class _MultiControllerStream<T> extends _MultiStreamImpl<T> {
  _NotificationHandler _subscriptionHandler;
  _NotificationHandler _pauseHandler;

  _MultiControllerStream(this._subscriptionHandler, this._pauseHandler);

  void _onSubscriptionStateChange() {
    if (_subscriptionHandler != null) _subscriptionHandler();
  }

  void _onPauseStateChange() {
    if (_pauseHandler != null) _pauseHandler();
  }
}

class _SingleControllerStream<T> extends _SingleStreamImpl<T> {
  _NotificationHandler _subscriptionHandler;
  _NotificationHandler _pauseHandler;

  _SingleControllerStream(this._subscriptionHandler, this._pauseHandler);

  void _onSubscriptionStateChange() {
    if (_subscriptionHandler != null) _subscriptionHandler();
  }

  void _onPauseStateChange() {
    if (_pauseHandler != null) _pauseHandler();
  }
}
