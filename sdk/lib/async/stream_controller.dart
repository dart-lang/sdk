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
abstract class StreamController<T> implements EventSink<T> {
  /** The stream that this controller is controlling. */
  Stream<T> get stream;

  /**
   * A controller with a [stream] that supports only one single subscriber.
   *
   * The controller will buffer all incoming events until the subscriber is
   * registered.
   *
   * The [onPause] function is called when the stream becomes
   * paused. [onResume] is called when the stream resumed.
   *
   * The [onListen] callback is called when the stream
   * receives its listener and [onCancel] when the listener ends
   * its subscription.
   *
   * If the stream is canceled before the controller needs new data the
   * [onResume] call might not be executed.
   */
  factory StreamController({void onListen(),
                            void onPause(),
                            void onResume(),
                            void onCancel()})
      => new _StreamControllerImpl<T>(onListen, onPause, onResume, onCancel);

  /**
   * A controller where [stream] creates new stream each time it is read.
   *
   * The controller distributes any events to all currently subscribed streams.
   *
   * The [onListen] callback is called when the first listener is subscribed,
   * and the [onCancel] is called when there is no longer any active listeners.
   * If a listener is added again later, after the [onCancel] was called,
   * the [onListen] will be called again.
   */
  factory StreamController.multiplex({void onListen(), void onCancel()}) {
    return new _MultiplexStreamController<T>(onListen, onCancel);
  }

  /**
   * Returns a view of this object that only exposes the [EventSink] interface.
   */
  EventSink<T> get sink;

  /**
   * Whether the stream is closed for adding more events.
   *
   * If true, the "done" event might not have fired yet, but it has been
   * scheduled, and it is too late to add more events.
   */
  bool get isClosed;

  /** Whether the subscription is active and paused. */
  bool get isPaused;

  /** Whether there is a subscriber on the [Stream]. */
  bool get hasListener;

  /**
   * Send or enqueue an error event.
   *
   * Also allows an objection stack trace object, on top of what [EventSink]
   * allows.
   */
  void addError(Object error, [Object stackTrace]);
}


abstract class _StreamControllerLifecycle<T> {
  void _recordListen(StreamSubscription<T> subscription) {}
  void _recordPause(StreamSubscription<T> subscription) {}
  void _recordResume(StreamSubscription<T> subscription) {}
  void _recordCancel(StreamSubscription<T> subscription) {}
}

/**
 * Default implementation of [StreamController].
 *
 * Controls a stream that only supports a single controller.
 */
class _StreamControllerImpl<T> implements StreamController<T>,
                                          _StreamControllerLifecycle<T> {
  static const int _STATE_OPEN = 0;
  static const int _STATE_CANCELLED = 1;
  static const int _STATE_CLOSED = 2;

  final _NotificationHandler _onListen;
  final _NotificationHandler _onPause;
  final _NotificationHandler _onResume;
  final _NotificationHandler _onCancel;
  _StreamImpl<T> _stream;

  // An active subscription on the stream, or null if no subscripton is active.
  _ControllerSubscription<T> _subscription;

  // Whether we have sent a "done" event.
  int _state = _STATE_OPEN;

  // Events added to the stream before it has an active subscription.
  _PendingEvents _pendingEvents = null;

  _StreamControllerImpl(this._onListen,
                        this._onPause,
                        this._onResume,
                        this._onCancel) {
    _stream = new _ControllerStream<T>(this);
  }

  Stream<T> get stream => _stream;

  /**
   * Returns a view of this object that only exposes the [EventSink] interface.
   */
  EventSink<T> get sink => new _EventSinkView<T>(this);

  /**
   * Whether a listener has existed and been cancelled.
   *
   * After this, adding more events will be ignored.
   */
  bool get _isCancelled => (_state & _STATE_CANCELLED) != 0;

  bool get isClosed => (_state & _STATE_CLOSED) != 0;

  bool get isPaused => _subscription != null && _subscription._isInputPaused;

  bool get hasListener => _subscription != null;

  /**
   * Send or queue a data event.
   */
  void add(T value) {
    if (isClosed) throw new StateError("Adding event after close");
    if (_subscription != null) {
      _subscription._add(value);
    } else if (!_isCancelled) {
      _addPendingEvent(new _DelayedData<T>(value));
    }
  }

  /**
   * Send or enqueue an error event.
   */
  void addError(Object error, [Object stackTrace]) {
    if (isClosed) throw new StateError("Adding event after close");
    if (stackTrace != null) {
      // Force stack trace overwrite. Even if the error already contained
      // a stack trace.
      _attachStackTrace(error, stackTrace);
    }
    if (_subscription != null) {
      _subscription._addError(error);
    } else if (!_isCancelled) {
      _addPendingEvent(new _DelayedError(error));
    }
  }

  /**
   * Closes this controller.
   *
   * After closing, no further events may be added using [add] or [addError].
   *
   * You are allowed to close the controller more than once, but only the first
   * call has any effect.
   *
   * The first time a controller is closed, a "done" event is sent to its
   * stream.
   */
  void close() {
    if (isClosed) return;
    _state |= _STATE_CLOSED;
    if (_subscription != null) {
      _subscription._close();
    } else if (!_isCancelled) {
      _addPendingEvent(const _DelayedDone());
    }
  }

  void _addPendingEvent(_DelayedEvent event) {
    if (_isCancelled) return;
    _StreamImplEvents events = _pendingEvents;
    if (events == null) {
      events = _pendingEvents = new _StreamImplEvents();
    }
    events.add(event);
  }

  void _recordListen(_BufferingStreamSubscription<T> subscription) {
    assert(_subscription == null);
    _subscription = subscription;
    subscription._setPendingEvents(_pendingEvents);
    _pendingEvents = null;
    subscription._guardCallback(() {
      _runGuarded(_onListen);
    });
  }

  void _recordCancel(StreamSubscription<T> subscription) {
    assert(identical(_subscription, subscription));
    _subscription = null;
    _state |= _STATE_CANCELLED;
    _runGuarded(_onCancel);
  }

  void _recordPause(StreamSubscription<T> subscription) {
    _runGuarded(_onPause);
  }

  void _recordResume(StreamSubscription<T> subscription) {
    _runGuarded(_onResume);
  }
}

typedef void _NotificationHandler();

void _runGuarded(_NotificationHandler notificationHandler) {
  if (notificationHandler == null) return;
  try {
    notificationHandler();
  } catch (e, s) {
    _throwDelayed(e, s);
  }
}

class _ControllerStream<T> extends _StreamImpl<T> {
  _StreamControllerLifecycle<T> _controller;
  bool _hasListener = false;

  _ControllerStream(this._controller);

  StreamSubscription<T> _createSubscription(
      void onData(T data),
      void onError(Object error),
      void onDone(),
      bool cancelOnError) {
    if (_hasListener) {
      throw new StateError("The stream has already been listened to.");
    }
    _hasListener = true;
    return new _ControllerSubscription<T>(
        _controller, onData, onError, onDone, cancelOnError);
  }

  void _onListen(_BufferingStreamSubscription subscription) {
    _controller._recordListen(subscription);
  }
}

class _ControllerSubscription<T> extends _BufferingStreamSubscription<T> {
  final _StreamControllerLifecycle<T> _controller;

  _ControllerSubscription(this._controller,
                          void onData(T data),
                          void onError(Object error),
                          void onDone(),
                          bool cancelOnError)
      : super(onData, onError, onDone, cancelOnError);

  void _onCancel() {
    _controller._recordCancel(this);
  }

  void _onPause() {
    _controller._recordPause(this);
  }

  void _onResume() {
    _controller._recordResume(this);
  }
}

class _MultiplexStreamController<T> implements StreamController<T>,
                                               _StreamControllerLifecycle<T> {
  final _NotificationHandler _onListen;
  final _NotificationHandler _onCancel;
  /** Set when the [close] method is called. */
  bool _isClosed = false;

  // TODO(lrn): Make a more efficient implementation of these subscriptions,
  // e.g., the traditional double-linked list with concurrent add and remove
  // while firing.
  Set<_BufferingStreamSubscription<T>> _streams;

  _MultiplexStreamController(this._onListen, this._onCancel)
      : _streams = new Set<_BufferingStreamSubscription<T>>();

  // StreamController interface.

  Stream<T> get stream => new _ControllerStream<T>(this);

  EventSink<T> get sink => new _EventSinkView<T>(this);

  bool get isClosed => _isClosed;

  /**
   * A multiplex controller is never paused.
   *
   * Each receiving stream may be paused individually, and they handle their
   * own buffering.
   */
  bool get isPaused => false;

  /** Whether there are currently a subscriber on the [Stream]. */
  bool get hasListener => !_streams.isEmpty;

  // _StreamControllerLifecycle interface.

  void _recordListen(_BufferingStreamSubscription<T> subscription) {
    bool isFirst = _streams.isEmpty;
    _streams.add(subscription);
    if (isFirst) {
      _runGuarded(_onListen);
    }
  }

  void _recordCancel(_BufferingStreamSubscription<T> subscription) {
    _streams.remove(subscription);
    if (_streams.isEmpty) {
      _runGuarded(_onCancel);
    }
  }

  void _recordPause(StreamSubscription<T> subscription) {}
  void _recordResume(StreamSubscription<T> subscription) {}

  // EventSink interface.

  void add(T data) {
    if (_streams.isEmpty) return;
    _forEachListener((_BufferingStreamSubscription<T> subscription) {
      subscription._add(data);
    });
  }

  void addError(Object error, [Object stackTrace]) {
    if (_streams.isEmpty) return;
    _forEachListener((_BufferingStreamSubscription<T> subscription) {
      subscription._addError(error);
    });
  }

  void close() {
    _isClosed = true;
    if (_streams.isEmpty) return;
    _forEachListener((_BufferingStreamSubscription<T> subscription) {
      _streams.remove(subscription);
      subscription._close();
    });
  }

  void _forEachListener(
      void action(_BufferingStreamSubscription<T> subscription)) {
    List<_BufferingStreamSubscription<T>> subscriptions = _streams.toList();
    for (_BufferingStreamSubscription<T> subscription in subscriptions) {
      if (_streams.contains(subscription)) {
        action(subscription);
      }
    }
  }
}

