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
abstract class StreamController<T> implements StreamSink<T> {
  /** The stream that this controller is controlling. */
  Stream<T> get stream;

  /**
   * A controller with a [stream] that supports only one single subscriber.
   *
   * If [sync] is true, events may be passed directly to the stream's listener
   * during an [add], [addError] or [close] call. If [sync] is false, the event
   * will be passed to the listener at a later time, after the code creating
   * the event has returned.
   *
   * The controller will buffer all incoming events until the subscriber is
   * registered.
   *
   * The [onPause] function is called when the stream becomes
   * paused. [onResume] is called when the stream resumed.
   *
   * The [onListen] callback is called when the stream
   * receives its listener and [onCancel] when the listener ends
   * its subscription. If [onCancel] needs to perform an asynchronous operation,
   * [onCancel] should return a future that completes when the cancel operation
   * is done.
   *
   * If the stream is canceled before the controller needs new data the
   * [onResume] call might not be executed.
   */
  factory StreamController({void onListen(),
                            void onPause(),
                            void onResume(),
                            onCancel(),
                            bool sync: false}) {
    if (onListen == null && onPause == null &&
        onResume == null && onCancel == null) {
      return sync
          ? new _NoCallbackSyncStreamController/*<T>*/()
          : new _NoCallbackAsyncStreamController/*<T>*/();
    }
    return sync
         ? new _SyncStreamController<T>(onListen, onPause, onResume, onCancel)
         : new _AsyncStreamController<T>(onListen, onPause, onResume, onCancel);
  }

  /**
   * A controller where [stream] can be listened to more than once.
   *
   * The [Stream] returned by [stream] is a broadcast stream.
   * It can be listened to more than once.
   *
   * The controller distributes any events to all currently subscribed
   * listeners at the time when [add], [addError] or [close] is called.
   * It is not allowed to call `add`, `addError`, or `close` before a previous
   * call has returned. The controller does not have any internal queue of
   * events, and if there are no listeners at the time the event is added,
   * it will just be dropped, or, if it is an error, be reported as uncaught.
   *
   * Each listener subscription is handled independently,
   * and if one pauses, only the pausing listener is affected.
   * A paused listener will buffer events internally until unpaused or canceled.
   *
   * If [sync] is true, events may be fired directly by the stream's
   * subscriptions during an [add], [addError] or [close] call.
   * If [sync] is false, the event will be fired at a later time,
   * after the code adding the event has completed.
   *
   * When [sync] is false, no guarantees are given with regard to when
   * multiple listeners get the events, except that each listener will get
   * all events in the correct order. Each subscription handles the events
   * individually.
   * If two events are sent on an async controller with two listeners,
   * one of the listeners may get both events
   * before the other listener gets any.
   * A listener must be subscribed both when the event is initiated
   * (that is, when [add] is called)
   * and when the event is later delivered,
   * in order to receive the event.
   *
   * The [onListen] callback is called when the first listener is subscribed,
   * and the [onCancel] is called when there are no longer any active listeners.
   * If a listener is added again later, after the [onCancel] was called,
   * the [onListen] will be called again.
   */
  factory StreamController.broadcast({void onListen(),
                                      void onCancel(),
                                      bool sync: false}) {
    return sync
        ? new _SyncBroadcastStreamController<T>(onListen, onCancel)
        : new _AsyncBroadcastStreamController<T>(onListen, onCancel);
  }

  /**
   * Returns a view of this object that only exposes the [StreamSink] interface.
   */
  StreamSink<T> get sink;

  /**
   * Whether the stream is closed for adding more events.
   *
   * If true, the "done" event might not have fired yet, but it has been
   * scheduled, and it is too late to add more events.
   */
  bool get isClosed;

  /**
   * Whether the subscription would need to buffer events.
   *
   * This is the case if the controller's stream has a listener and it is
   * paused, or if it has not received a listener yet. In that case, the
   * controller is considered paused as well.
   *
   * A broadcast stream controller is never considered paused. It always
   * forwards its events to all uncanceled listeners, if any, and let them
   * handle their own pausing.
   */
  bool get isPaused;

  /** Whether there is a subscriber on the [Stream]. */
  bool get hasListener;

  /**
   * Send or enqueue an error event.
   *
   * Also allows an objection stack trace object, on top of what [EventSink]
   * allows.
   */
  void addError(Object error, [StackTrace stackTrace]);

  /**
   * Receives events from [source] and puts them into this controller's stream.
   *
   * Returns a future which completes when the source stream is done.
   *
   * Events must not be added directly to this controller using [add],
   * [addError], [close] or [addStream], until the returned future
   * is complete.
   *
   * Data and error events are forwarded to this controller's stream. A done
   * event on the source will end the `addStream` operation and complete the
   * returned future.
   *
   * If [cancelOnError] is true, only the first error on [source] is
   * forwarded to the controller's stream, and the `addStream` ends
   * after this. If [cancelOnError] is false, all errors are forwarded
   * and only a done event will end the `addStream`.
   */
  Future addStream(Stream<T> source, {bool cancelOnError: true});
}


abstract class _StreamControllerLifecycle<T> {
  StreamSubscription<T> _subscribe(
      void onData(T data),
      Function onError,
      void onDone(),
      bool cancelOnError);
  void _recordPause(StreamSubscription<T> subscription) {}
  void _recordResume(StreamSubscription<T> subscription) {}
  Future _recordCancel(StreamSubscription<T> subscription) => null;
}

/**
 * Default implementation of [StreamController].
 *
 * Controls a stream that only supports a single controller.
 */
abstract class _StreamController<T> implements StreamController<T>,
                                               _StreamControllerLifecycle<T>,
                                               _EventSink<T>,
                                               _EventDispatch<T> {
  // The states are bit-flags. More than one can be set at a time.
  //
  // The "subscription state" goes through the states:
  //   initial -> subscribed -> canceled.
  // These are mutually exclusive.
  // The "closed" state records whether the [close] method has been called
  // on the controller. This can be done at any time. If done before
  // subscription, the done event is queued. If done after cancel, the done
  // event is ignored (just as any other event after a cancel).

  /** The controller is in its initial state with no subscription. */
  static const int _STATE_INITIAL = 0;
  /** The controller has a subscription, but hasn't been closed or canceled. */
  static const int _STATE_SUBSCRIBED = 1;
  /** The subscription is canceled. */
  static const int _STATE_CANCELED = 2;
  /** Mask for the subscription state. */
  static const int _STATE_SUBSCRIPTION_MASK = 3;

  // The following state relate to the controller, not the subscription.
  // If closed, adding more events is not allowed.
  // If executing an [addStream], new events are not allowed either, but will
  // be added by the stream.

  /**
   * The controller is closed due to calling [close].
   *
   * When the stream is closed, you can neither add new events nor add new
   * listeners.
   */
  static const int _STATE_CLOSED = 4;
  /**
   * The controller is in the middle of an [addStream] operation.
   *
   * While adding events from a stream, no new events can be added directly
   * on the controller.
   */
  static const int _STATE_ADDSTREAM = 8;

  /**
   * Field containing different data depending on the current subscription
   * state.
   *
   * If [_state] is [_STATE_INITIAL], the field may contain a [_PendingEvents]
   * for events added to the controller before a subscription.
   *
   * While [_state] is [_STATE_SUBSCRIBED], the field contains the subscription.
   *
   * When [_state] is [_STATE_CANCELED] the field is currently not used.
   */
  var _varData;

  /** Current state of the controller. */
  int _state = _STATE_INITIAL;

  /**
   * Future completed when the stream sends its last event.
   *
   * This is also the future returned by [close].
   */
  // TODO(lrn): Could this be stored in the varData field too, if it's not
  // accessed until the call to "close"? Then we need to special case if it's
  // accessed earlier, or if close is called before subscribing.
  _Future _doneFuture;

  _StreamController();

  _NotificationHandler get _onListen;
  _NotificationHandler get _onPause;
  _NotificationHandler get _onResume;
  _NotificationHandler get _onCancel;

  // Return a new stream every time. The streams are equal, but not identical.
  Stream<T> get stream => new _ControllerStream(this);

  /**
   * Returns a view of this object that only exposes the [StreamSink] interface.
   */
  StreamSink<T> get sink => new _StreamSinkWrapper<T>(this);

  /**
   * Whether a listener has existed and been canceled.
   *
   * After this, adding more events will be ignored.
   */
  bool get _isCanceled => (_state & _STATE_CANCELED) != 0;

  /** Whether there is an active listener. */
  bool get hasListener => (_state & _STATE_SUBSCRIBED) != 0;

  /** Whether there has not been a listener yet. */
  bool get _isInitialState =>
      (_state & _STATE_SUBSCRIPTION_MASK) == _STATE_INITIAL;

  bool get isClosed => (_state & _STATE_CLOSED) != 0;

  bool get isPaused => hasListener ? _subscription._isInputPaused
                                   : !_isCanceled;

  bool get _isAddingStream => (_state & _STATE_ADDSTREAM) != 0;

  /** New events may not be added after close, or during addStream. */
  bool get _mayAddEvent => (_state < _STATE_CLOSED);

  // Returns the pending events.
  // Pending events are events added before a subscription exists.
  // They are added to the subscription when it is created.
  // Pending events, if any, are kept in the _varData field until the
  // stream is listened to.
  // While adding a stream, pending events are moved into the
  // state object to allow the state object to use the _varData field.
  _PendingEvents get _pendingEvents {
    assert(_isInitialState);
    if (!_isAddingStream) {
      return _varData;
    }
    _StreamControllerAddStreamState state = _varData;
    return state.varData;
  }

  // Returns the pending events, and creates the object if necessary.
  _StreamImplEvents _ensurePendingEvents() {
    assert(_isInitialState);
    if (!_isAddingStream) {
      if (_varData == null) _varData = new _StreamImplEvents();
      return _varData;
    }
    _StreamControllerAddStreamState state = _varData;
    if (state.varData == null) state.varData = new _StreamImplEvents();
    return state.varData;
  }

  // Get the current subscription.
  // If we are adding a stream, the subscription is moved into the state
  // object to allow the state object to use the _varData field.
  _ControllerSubscription get _subscription {
    assert(hasListener);
    if (_isAddingStream) {
      _StreamControllerAddStreamState addState = _varData;
      return addState.varData;
    }
    return _varData;
  }

  /**
   * Creates an error describing why an event cannot be added.
   *
   * The reason, and therefore the error message, depends on the current state.
   */
  Error _badEventState() {
    if (isClosed) {
      return new StateError("Cannot add event after closing");
    }
    assert(_isAddingStream);
    return new StateError("Cannot add event while adding a stream");
  }

  // StreamSink interface.
  Future addStream(Stream<T> source, {bool cancelOnError: true}) {
    if (!_mayAddEvent) throw _badEventState();
    if (_isCanceled) return new _Future.immediate(null);
    _StreamControllerAddStreamState addState =
        new _StreamControllerAddStreamState(this,
                                            _varData,
                                            source,
                                            cancelOnError);
    _varData = addState;
    _state |= _STATE_ADDSTREAM;
    return addState.addStreamFuture;
  }

  /**
   * Returns a future that is completed when the stream is done
   * processing events.
   *
   * This happens either when the done event has been sent, or if the
   * subscriber of a single-subscription stream is cancelled.
   */
  Future get done => _ensureDoneFuture();

  Future _ensureDoneFuture() {
    if (_doneFuture == null) {
      _doneFuture = _isCanceled ? Future._nullFuture : new _Future();
    }
    return _doneFuture;
  }

  /**
   * Send or enqueue a data event.
   */
  void add(T value) {
    if (!_mayAddEvent) throw _badEventState();
    _add(value);
  }

  /**
   * Send or enqueue an error event.
   */
  void addError(Object error, [StackTrace stackTrace]) {
    if (!_mayAddEvent) throw _badEventState();
    AsyncError replacement = Zone.current.errorCallback(error, stackTrace);
    if (replacement != null) {
      error = replacement.error;
      stackTrace = replacement.stackTrace;
    }
    _addError(error, stackTrace);
  }

  /**
   * Closes this controller and sends a done event on the stream.
   *
   * The first time a controller is closed, a "done" event is added to its
   * stream.
   *
   * You are allowed to close the controller more than once, but only the first
   * call has any effect.
   *
   * After closing, no further events may be added using [add] or [addError].
   *
   * The returned future is completed when the done event has been delivered.
   */
  Future close() {
    if (isClosed) {
      return _ensureDoneFuture();
    }
    if (!_mayAddEvent) throw _badEventState();
    _closeUnchecked();
    return _ensureDoneFuture();
  }

  void _closeUnchecked() {
    _state |= _STATE_CLOSED;
    if (hasListener) {
      _sendDone();
    } else if (_isInitialState) {
      _ensurePendingEvents().add(const _DelayedDone());
    }
  }

  // EventSink interface. Used by the [addStream] events.

  // Add data event, used both by the [addStream] events and by [add].
  void _add(T value) {
    if (hasListener) {
      _sendData(value);
    } else if (_isInitialState) {
      _ensurePendingEvents().add(new _DelayedData<T>(value));
    }
  }

  void _addError(Object error, StackTrace stackTrace) {
    if (hasListener) {
      _sendError(error, stackTrace);
    } else if (_isInitialState) {
      _ensurePendingEvents().add(new _DelayedError(error, stackTrace));
    }
  }

  void _close() {
    // End of addStream stream.
    assert(_isAddingStream);
    _StreamControllerAddStreamState addState = _varData;
    _varData = addState.varData;
    _state &= ~_STATE_ADDSTREAM;
    addState.complete();
  }

  // _StreamControllerLifeCycle interface

  StreamSubscription<T> _subscribe(
      void onData(T data),
      Function onError,
      void onDone(),
      bool cancelOnError) {
    if (!_isInitialState) {
      throw new StateError("Stream has already been listened to.");
    }
    _ControllerSubscription subscription =
        new _ControllerSubscription(this, onData, onError, onDone,
                                    cancelOnError);

    _PendingEvents pendingEvents = _pendingEvents;
    _state |= _STATE_SUBSCRIBED;
    if (_isAddingStream) {
      _StreamControllerAddStreamState addState = _varData;
      addState.varData = subscription;
      addState.resume();
    } else {
      _varData = subscription;
    }
    subscription._setPendingEvents(pendingEvents);
    subscription._guardCallback(() {
      _runGuarded(_onListen);
    });

    return subscription;
  }

  Future _recordCancel(StreamSubscription<T> subscription) {
    // When we cancel, we first cancel any stream being added,
    // Then we call _onCancel, and finally the _doneFuture is completed.
    // If either of addStream's cancel or _onCancel returns a future,
    // we wait for it before continuing.
    // Any error during this process ends up in the returned future.
    // If more errors happen, we act as if it happens inside nested try/finallys
    // or whenComplete calls, and only the last error ends up in the
    // returned future.
    Future result;
    if (_isAddingStream) {
      _StreamControllerAddStreamState addState = _varData;
      result = addState.cancel();
    }
    _varData = null;
    _state =
        (_state & ~(_STATE_SUBSCRIBED | _STATE_ADDSTREAM)) | _STATE_CANCELED;

    if (_onCancel != null) {
      if (result == null) {
        // Only introduce a future if one is needed.
        // If _onCancel returns null, no future is needed.
        try {
          result = _onCancel();
        } catch (e, s) {
          // Return the error in the returned future.
          // Complete it asynchronously, so there is time for a listener
          // to handle the error.
          result = new _Future().._asyncCompleteError(e, s);
        }
      } else {
        // Simpler case when we already know that we will return a future.
        result = result.whenComplete(_onCancel);
      }
    }

    void complete() {
      if (_doneFuture != null && _doneFuture._mayComplete) {
        _doneFuture._asyncComplete(null);
      }
    }

    if (result != null) {
      result = result.whenComplete(complete);
    } else {
      complete();
    }

    return result;
  }

  void _recordPause(StreamSubscription<T> subscription) {
    if (_isAddingStream) {
      _StreamControllerAddStreamState addState = _varData;
      addState.pause();
    }
    _runGuarded(_onPause);
  }

  void _recordResume(StreamSubscription<T> subscription) {
    if (_isAddingStream) {
      _StreamControllerAddStreamState addState = _varData;
      addState.resume();
    }
    _runGuarded(_onResume);
  }
}

abstract class _SyncStreamControllerDispatch<T>
    implements _StreamController<T> {
  void _sendData(T data) {
    _subscription._add(data);
  }

  void _sendError(Object error, StackTrace stackTrace) {
    _subscription._addError(error, stackTrace);
  }

  void _sendDone() {
    _subscription._close();
  }
}

abstract class _AsyncStreamControllerDispatch<T>
    implements _StreamController<T> {
  void _sendData(T data) {
    _subscription._addPending(new _DelayedData(data));
  }

  void _sendError(Object error, StackTrace stackTrace) {
    _subscription._addPending(new _DelayedError(error, stackTrace));
  }

  void _sendDone() {
    _subscription._addPending(const _DelayedDone());
  }
}

// TODO(lrn): Use common superclass for callback-controllers when VM supports
// constructors in mixin superclasses.

class _AsyncStreamController<T> extends _StreamController<T>
                                   with _AsyncStreamControllerDispatch<T> {
  final _NotificationHandler _onListen;
  final _NotificationHandler _onPause;
  final _NotificationHandler _onResume;
  final _NotificationHandler _onCancel;

  _AsyncStreamController(void this._onListen(),
                         void this._onPause(),
                         void this._onResume(),
                         this._onCancel());
}

class _SyncStreamController<T> extends _StreamController<T>
                                  with _SyncStreamControllerDispatch<T> {
  final _NotificationHandler _onListen;
  final _NotificationHandler _onPause;
  final _NotificationHandler _onResume;
  final _NotificationHandler _onCancel;

  _SyncStreamController(void this._onListen(),
                        void this._onPause(),
                        void this._onResume(),
                        this._onCancel());
}

abstract class _NoCallbacks {
  _NotificationHandler get _onListen => null;
  _NotificationHandler get _onPause => null;
  _NotificationHandler get _onResume => null;
  _NotificationHandler get _onCancel => null;
}

class _NoCallbackAsyncStreamController/*<T>*/ = _StreamController/*<T>*/
       with _AsyncStreamControllerDispatch/*<T>*/, _NoCallbacks;

class _NoCallbackSyncStreamController/*<T>*/ = _StreamController/*<T>*/
       with _SyncStreamControllerDispatch/*<T>*/, _NoCallbacks;

typedef _NotificationHandler();

Future _runGuarded(_NotificationHandler notificationHandler) {
  if (notificationHandler == null) return null;
  try {
    var result = notificationHandler();
    if (result is Future) return result;
    return null;
  } catch (e, s) {
    Zone.current.handleUncaughtError(e, s);
  }
}

class _ControllerStream<T> extends _StreamImpl<T> {
  _StreamControllerLifecycle<T> _controller;

  _ControllerStream(this._controller);

  StreamSubscription<T> _createSubscription(
      void onData(T data),
      Function onError,
      void onDone(),
      bool cancelOnError) =>
    _controller._subscribe(onData, onError, onDone, cancelOnError);

  // Override == and hashCode so that new streams returned by the same
  // controller are considered equal. The controller returns a new stream
  // each time it's queried, but doesn't have to cache the result.

  int get hashCode => _controller.hashCode ^ 0x35323532;

  bool operator==(Object other) {
    if (identical(this, other)) return true;
    if (other is! _ControllerStream) return false;
    _ControllerStream otherStream = other;
    return identical(otherStream._controller, this._controller);
  }
}

class _ControllerSubscription<T> extends _BufferingStreamSubscription<T> {
  final _StreamControllerLifecycle<T> _controller;

  _ControllerSubscription(this._controller, void onData(T data),
                          Function onError, void onDone(), bool cancelOnError)
      : super(onData, onError, onDone, cancelOnError);

  Future _onCancel() {
    return _controller._recordCancel(this);
  }

  void _onPause() {
    _controller._recordPause(this);
  }

  void _onResume() {
    _controller._recordResume(this);
  }
}


/** A class that exposes only the [StreamSink] interface of an object. */
class _StreamSinkWrapper<T> implements StreamSink<T> {
  final StreamController _target;
  _StreamSinkWrapper(this._target);
  void add(T data) { _target.add(data); }
  void addError(Object error, [StackTrace stackTrace]) {
    _target.addError(error, stackTrace);
  }
  Future close() => _target.close();
  Future addStream(Stream<T> source, {bool cancelOnError: true}) =>
      _target.addStream(source, cancelOnError: cancelOnError);
  Future get done => _target.done;
}

/**
 * Object containing the state used to handle [StreamController.addStream].
 */
class _AddStreamState<T> {
  // [_Future] returned by call to addStream.
  final _Future addStreamFuture;

  // Subscription on stream argument to addStream.
  final StreamSubscription addSubscription;

  _AddStreamState(_EventSink<T> controller, Stream source, bool cancelOnError)
      : addStreamFuture = new _Future(),
        addSubscription = source.listen(controller._add,
                                        onError: cancelOnError
                                             ? makeErrorHandler(controller)
                                             : controller._addError,
                                        onDone: controller._close,
                                        cancelOnError: cancelOnError);

  static makeErrorHandler(_EventSink controller) =>
      (e, StackTrace s) {
        controller._addError(e, s);
        controller._close();
      };

  void pause() {
    addSubscription.pause();
  }

  void resume() {
    addSubscription.resume();
  }

  /**
   * Stop adding the stream.
   *
   * Complete the future returned by `StreamController.addStream` when
   * the cancel is complete.
   *
   * Return a future if the cancel takes time, otherwise return `null`.
   */
  Future cancel() {
    var cancel = addSubscription.cancel();
    if (cancel == null) {
      addStreamFuture._asyncComplete(null);
      return null;
    }
    return cancel.whenComplete(() { addStreamFuture._asyncComplete(null); });
  }

  void complete() {
    addStreamFuture._asyncComplete(null);
  }
}

class _StreamControllerAddStreamState<T> extends _AddStreamState<T> {
  // The subscription or pending data of a _StreamController.
  // Stored here because we reuse the `_varData` field  in the _StreamController
  // to store this state object.
  var varData;

  _StreamControllerAddStreamState(_StreamController controller,
                                  this.varData,
                                  Stream source,
                                  bool cancelOnError)
      : super(controller, source, cancelOnError) {
    if (controller.isPaused) {
      addSubscription.pause();
    }
  }
}
