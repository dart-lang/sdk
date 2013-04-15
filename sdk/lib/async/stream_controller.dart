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
 *
 * If the stream starts or stops having listeners (first listener subscribing,
 * last listener unsubscribing), the `onSubscriptionStateChange` callback
 * is notified as soon as possible. If the subscription stat changes during
 * an event firing or a callback being executed, the change will not be reported
 * until the current event or callback has finished.
 * If the pause state has also changed during an event or callback, only the
 * subscription state callback is notified.
 *
 * If the subscriber state has not changed, but the pause state has, the
 * `onPauseStateChange` callback is notified as soon as possible, after firing
 * a current event or completing another callback. This happens if the stream
 * is not paused, and a listener pauses it, or if the stream has been resumed
 * from pause and has no pending events. If the listeners resume a paused stream
 * while it still has queued events, the controller will still consider the
 * stream paused until all queued events have been dispatched.
 *
 * Whether to invoke a callback depends only on the state before and after
 * a stream action, for example firing an event. If the state changes multiple
 * times during the action, and then ends up in the same state as before, no
 * callback is performed.
 *
 * If listeners are added after the stream has completed (sent a "done" event),
 * the listeners will be sent a "done" event eventually, but they won't affect
 * the stream at all, and won't trigger callbacks. From the controller's point
 * of view, the stream is completely inert when has completed.
 */
class StreamController<T> extends EventSink<T> {
  final _StreamImpl<T> stream;

  /**
   *
   * If the stream is canceled before the controller needs new data the
   * [onResume] call might not be executed.
      : stream = new _MultiControllerStream<T>(
            onListen, onPause, onResume, onCancel);
   * A controller with a [stream] that supports only one single subscriber.
   *
   * The controller will buffer all incoming events until the subscriber is
   * registered.
   *
   * The [onPause] function is called when the stream becomes
   * paused. [onResume] is called when the stream resumed.
   *
   * The [onListen] callback is called when the stream
   * receives its listener. [onCancel] when the listener cancels
   * its subscription.
   *
   * If the stream is canceled before the controller needs new data the
   * [onResume] call might not be executed.
   */
  StreamController({void onListen(),
                    void onPause(),
                    void onResume(),
                    void onCancel()})
      : stream = new _SingleControllerStream<T>(
            onListen, onPause, onResume, onCancel);

  /**
   * Returns a view of this object that only exposes the [EventSink] interface.
   */
  EventSink<T> get sink => new _EventSinkView<T>(this);

  /**
   * Whether the stream is closed for adding more events.
   *
   * If true, the "done" event might not have fired yet, but it has been
   * scheduled, and it is too late to add more events.
   */
  bool get isClosed => stream._isClosed;

  /** Whether one or more active subscribers have requested a pause. */
  bool get isPaused => stream._isInputPaused;

  /** Whether there are currently any subscribers on this [Stream]. */
  bool get hasListener => stream._hasListener;

  /**
   * Send or queue a data event.
   */
  void add(T value) => stream._add(value);

  /**
   * Send or enqueue an error event.
   *
   * If a subscription has requested to be unsubscribed on errors,
   * it will be unsubscribed after receiving this event.
   */
  void addError(Object error, [Object stackTrace]) {
    if (stackTrace != null) {
      // Force stack trace overwrite. Even if the error already contained
      // a stack trace.
      _attachStackTrace(error, stackTrace);
    }
    stream._addError(error);
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

class _SingleControllerStream<T> extends _SingleStreamImpl<T> {
  _NotificationHandler _onListen;
  _NotificationHandler _onPause;
  _NotificationHandler _onResume;
  _NotificationHandler _onCancel;

  // TODO(floitsch): share this code with _MultiControllerStream.
  _runGuarded(_NotificationHandler notificationHandler) {
    if (notificationHandler == null) return;
    try {
      notificationHandler();
    } catch (e, s) {
      _throwDelayed(e, s);
    }
  }

  _SingleControllerStream(this._onListen,
                          this._onPause,
                          this._onResume,
                          this._onCancel);

  void _onSubscriptionStateChange() {
    _runGuarded(_hasListener ? _onListen : _onCancel);
  }

  void _onPauseStateChange() {
    _runGuarded(_isPaused ? _onPause : _onResume);
  }
}
