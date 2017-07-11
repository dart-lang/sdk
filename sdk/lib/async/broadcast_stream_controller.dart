// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.async;

class _BroadcastStream<T> extends _ControllerStream<T> {
  _BroadcastStream(_StreamControllerLifecycle<T> controller)
      : super(controller);

  bool get isBroadcast => true;
}

class _BroadcastSubscription<T> extends _ControllerSubscription<T> {
  static const int _STATE_EVENT_ID = 1;
  static const int _STATE_FIRING = 2;
  static const int _STATE_REMOVE_AFTER_FIRING = 4;
  // TODO(lrn): Use the _state field on _ControllerSubscription to
  // also store this state. Requires that the subscription implementation
  // does not assume that it's use of the state integer is the only use.
  int _eventState = 0; // Initialized to help dart2js type inference.

  _BroadcastSubscription<T> _next;
  _BroadcastSubscription<T> _previous;

  _BroadcastSubscription(_StreamControllerLifecycle<T> controller,
      void onData(T data), Function onError, void onDone(), bool cancelOnError)
      : super(controller, onData, onError, onDone, cancelOnError) {
    _next = _previous = this;
  }

  bool _expectsEvent(int eventId) => (_eventState & _STATE_EVENT_ID) == eventId;

  void _toggleEventId() {
    _eventState ^= _STATE_EVENT_ID;
  }

  bool get _isFiring => (_eventState & _STATE_FIRING) != 0;

  void _setRemoveAfterFiring() {
    assert(_isFiring);
    _eventState |= _STATE_REMOVE_AFTER_FIRING;
  }

  bool get _removeAfterFiring =>
      (_eventState & _STATE_REMOVE_AFTER_FIRING) != 0;

  // The controller._recordPause doesn't do anything for a broadcast controller,
  // so we don't bother calling it.
  void _onPause() {}

  // The controller._recordResume doesn't do anything for a broadcast
  // controller, so we don't bother calling it.
  void _onResume() {}

  // _onCancel is inherited.
}

abstract class _BroadcastStreamController<T>
    implements
        StreamController<T>,
        _StreamControllerLifecycle<T>,
        _EventSink<T>,
        _EventDispatch<T> {
  static const int _STATE_INITIAL = 0;
  static const int _STATE_EVENT_ID = 1;
  static const int _STATE_FIRING = 2;
  static const int _STATE_CLOSED = 4;
  static const int _STATE_ADDSTREAM = 8;

  ControllerCallback onListen;
  ControllerCancelCallback onCancel;

  // State of the controller.
  int _state;

  // Double-linked list of active listeners.
  _BroadcastSubscription<T> _firstSubscription;
  _BroadcastSubscription<T> _lastSubscription;

  // Extra state used during an [addStream] call.
  _AddStreamState<T> _addStreamState;

  /**
   * Future returned by [close] and [done].
   *
   * The future is completed whenever the done event has been sent to all
   * relevant listeners.
   * The relevant listeners are the ones that were listening when [close] was
   * called. When all of these have been canceled (sending the done event makes
   * them cancel, but they can also be canceled before sending the event),
   * this future completes.
   *
   * Any attempt to listen after calling [close] will throw, so there won't
   * be any further listeners.
   */
  _Future _doneFuture;

  _BroadcastStreamController(this.onListen, this.onCancel)
      : _state = _STATE_INITIAL;

  ControllerCallback get onPause {
    throw new UnsupportedError(
        "Broadcast stream controllers do not support pause callbacks");
  }

  void set onPause(void onPauseHandler()) {
    throw new UnsupportedError(
        "Broadcast stream controllers do not support pause callbacks");
  }

  ControllerCallback get onResume {
    throw new UnsupportedError(
        "Broadcast stream controllers do not support pause callbacks");
  }

  void set onResume(void onResumeHandler()) {
    throw new UnsupportedError(
        "Broadcast stream controllers do not support pause callbacks");
  }

  // StreamController interface.

  Stream<T> get stream => new _BroadcastStream<T>(this);

  StreamSink<T> get sink => new _StreamSinkWrapper<T>(this);

  bool get isClosed => (_state & _STATE_CLOSED) != 0;

  /**
   * A broadcast controller is never paused.
   *
   * Each receiving stream may be paused individually, and they handle their
   * own buffering.
   */
  bool get isPaused => false;

  /** Whether there are currently one or more subscribers. */
  bool get hasListener => !_isEmpty;

  /**
   * Test whether the stream has exactly one listener.
   *
   * Assumes that the stream has a listener (not [_isEmpty]).
   */
  bool get _hasOneListener {
    assert(!_isEmpty);
    return identical(_firstSubscription, _lastSubscription);
  }

  /** Whether an event is being fired (sent to some, but not all, listeners). */
  bool get _isFiring => (_state & _STATE_FIRING) != 0;

  bool get _isAddingStream => (_state & _STATE_ADDSTREAM) != 0;

  bool get _mayAddEvent => (_state < _STATE_CLOSED);

  _Future _ensureDoneFuture() {
    if (_doneFuture != null) return _doneFuture;
    return _doneFuture = new _Future();
  }

  // Linked list helpers

  bool get _isEmpty => _firstSubscription == null;

  /** Adds subscription to linked list of active listeners. */
  void _addListener(_BroadcastSubscription<T> subscription) {
    assert(identical(subscription._next, subscription));
    subscription._eventState = (_state & _STATE_EVENT_ID);
    // Insert in linked list as last subscription.
    _BroadcastSubscription<T> oldLast = _lastSubscription;
    _lastSubscription = subscription;
    subscription._next = null;
    subscription._previous = oldLast;
    if (oldLast == null) {
      _firstSubscription = subscription;
    } else {
      oldLast._next = subscription;
    }
  }

  void _removeListener(_BroadcastSubscription<T> subscription) {
    assert(identical(subscription._controller, this));
    assert(!identical(subscription._next, subscription));
    _BroadcastSubscription<T> previous = subscription._previous;
    _BroadcastSubscription<T> next = subscription._next;
    if (previous == null) {
      // This was the first subscription.
      _firstSubscription = next;
    } else {
      previous._next = next;
    }
    if (next == null) {
      // This was the last subscription.
      _lastSubscription = previous;
    } else {
      next._previous = previous;
    }

    subscription._next = subscription._previous = subscription;
  }

  // _StreamControllerLifecycle interface.

  StreamSubscription<T> _subscribe(void onData(T data), Function onError,
      void onDone(), bool cancelOnError) {
    if (isClosed) {
      if (onDone == null) onDone = _nullDoneHandler;
      return new _DoneStreamSubscription<T>(onDone);
    }
    StreamSubscription<T> subscription = new _BroadcastSubscription<T>(
        this, onData, onError, onDone, cancelOnError);
    _addListener(subscription);
    if (identical(_firstSubscription, _lastSubscription)) {
      // Only one listener, so it must be the first listener.
      _runGuarded(onListen);
    }
    return subscription;
  }

  Future _recordCancel(StreamSubscription<T> sub) {
    _BroadcastSubscription<T> subscription = sub;
    // If already removed by the stream, don't remove it again.
    if (identical(subscription._next, subscription)) return null;
    if (subscription._isFiring) {
      subscription._setRemoveAfterFiring();
    } else {
      _removeListener(subscription);
      // If we are currently firing an event, the empty-check is performed at
      // the end of the listener loop instead of here.
      if (!_isFiring && _isEmpty) {
        _callOnCancel();
      }
    }
    return null;
  }

  void _recordPause(StreamSubscription<T> subscription) {}
  void _recordResume(StreamSubscription<T> subscription) {}

  // EventSink interface.

  Error _addEventError() {
    if (isClosed) {
      return new StateError("Cannot add new events after calling close");
    }
    assert(_isAddingStream);
    return new StateError("Cannot add new events while doing an addStream");
  }

  void add(T data) {
    if (!_mayAddEvent) throw _addEventError();
    _sendData(data);
  }

  void addError(Object error, [StackTrace stackTrace]) {
    error = _nonNullError(error);
    if (!_mayAddEvent) throw _addEventError();
    AsyncError replacement = Zone.current.errorCallback(error, stackTrace);
    if (replacement != null) {
      error = _nonNullError(replacement.error);
      stackTrace = replacement.stackTrace;
    }
    _sendError(error, stackTrace);
  }

  Future close() {
    if (isClosed) {
      assert(_doneFuture != null);
      return _doneFuture;
    }
    if (!_mayAddEvent) throw _addEventError();
    _state |= _STATE_CLOSED;
    Future doneFuture = _ensureDoneFuture();
    _sendDone();
    return doneFuture;
  }

  Future get done => _ensureDoneFuture();

  Future addStream(Stream<T> stream, {bool cancelOnError: true}) {
    if (!_mayAddEvent) throw _addEventError();
    _state |= _STATE_ADDSTREAM;
    _addStreamState = new _AddStreamState(this, stream, cancelOnError);
    return _addStreamState.addStreamFuture;
  }

  // _EventSink interface, called from AddStreamState.
  void _add(T data) {
    _sendData(data);
  }

  void _addError(Object error, StackTrace stackTrace) {
    _sendError(error, stackTrace);
  }

  void _close() {
    assert(_isAddingStream);
    _AddStreamState addState = _addStreamState;
    _addStreamState = null;
    _state &= ~_STATE_ADDSTREAM;
    addState.complete();
  }

  // Event handling.
  void _forEachListener(
      void action(_BufferingStreamSubscription<T> subscription)) {
    if (_isFiring) {
      throw new StateError(
          "Cannot fire new event. Controller is already firing an event");
    }
    if (_isEmpty) return;

    // Get event id of this event.
    int id = (_state & _STATE_EVENT_ID);
    // Start firing (set the _STATE_FIRING bit). We don't do [onCancel]
    // callbacks while firing, and we prevent reentrancy of this function.
    //
    // Set [_state]'s event id to the next event's id.
    // Any listeners added while firing this event will expect the next event,
    // not this one, and won't get notified.
    _state ^= _STATE_EVENT_ID | _STATE_FIRING;
    _BroadcastSubscription<T> subscription = _firstSubscription;
    while (subscription != null) {
      if (subscription._expectsEvent(id)) {
        subscription._eventState |= _BroadcastSubscription._STATE_FIRING;
        action(subscription);
        subscription._toggleEventId();
        _BroadcastSubscription<T> next = subscription._next;
        if (subscription._removeAfterFiring) {
          _removeListener(subscription);
        }
        subscription._eventState &= ~_BroadcastSubscription._STATE_FIRING;
        subscription = next;
      } else {
        subscription = subscription._next;
      }
    }
    _state &= ~_STATE_FIRING;

    if (_isEmpty) {
      _callOnCancel();
    }
  }

  void _callOnCancel() {
    assert(_isEmpty);
    if (isClosed && _doneFuture._mayComplete) {
      // When closed, _doneFuture is not null.
      _doneFuture._asyncComplete(null);
    }
    _runGuarded(onCancel);
  }
}

class _SyncBroadcastStreamController<T> extends _BroadcastStreamController<T>
    implements SynchronousStreamController<T> {
  _SyncBroadcastStreamController(void onListen(), void onCancel())
      : super(onListen, onCancel);

  // EventDispatch interface.

  bool get _mayAddEvent => super._mayAddEvent && !_isFiring;

  _addEventError() {
    if (_isFiring) {
      return new StateError(
          "Cannot fire new event. Controller is already firing an event");
    }
    return super._addEventError();
  }

  void _sendData(T data) {
    if (_isEmpty) return;
    if (_hasOneListener) {
      _state |= _BroadcastStreamController._STATE_FIRING;
      _BroadcastSubscription<T> subscription = _firstSubscription;
      subscription._add(data);
      _state &= ~_BroadcastStreamController._STATE_FIRING;
      if (_isEmpty) {
        _callOnCancel();
      }
      return;
    }
    _forEachListener((_BufferingStreamSubscription<T> subscription) {
      subscription._add(data);
    });
  }

  void _sendError(Object error, StackTrace stackTrace) {
    if (_isEmpty) return;
    _forEachListener((_BufferingStreamSubscription<T> subscription) {
      subscription._addError(error, stackTrace);
    });
  }

  void _sendDone() {
    if (!_isEmpty) {
      _forEachListener((_BufferingStreamSubscription<T> subscription) {
        subscription._close();
      });
    } else {
      assert(_doneFuture != null);
      assert(_doneFuture._mayComplete);
      _doneFuture._asyncComplete(null);
    }
  }
}

class _AsyncBroadcastStreamController<T> extends _BroadcastStreamController<T> {
  _AsyncBroadcastStreamController(void onListen(), void onCancel())
      : super(onListen, onCancel);

  // EventDispatch interface.

  void _sendData(T data) {
    for (_BroadcastSubscription<T> subscription = _firstSubscription;
        subscription != null;
        subscription = subscription._next) {
      subscription._addPending(new _DelayedData<T>(data));
    }
  }

  void _sendError(Object error, StackTrace stackTrace) {
    for (_BroadcastSubscription<T> subscription = _firstSubscription;
        subscription != null;
        subscription = subscription._next) {
      subscription._addPending(new _DelayedError(error, stackTrace));
    }
  }

  void _sendDone() {
    if (!_isEmpty) {
      for (_BroadcastSubscription<T> subscription = _firstSubscription;
          subscription != null;
          subscription = subscription._next) {
        subscription._addPending(const _DelayedDone());
      }
    } else {
      assert(_doneFuture != null);
      assert(_doneFuture._mayComplete);
      _doneFuture._asyncComplete(null);
    }
  }
}

/**
 * Stream controller that is used by [Stream.asBroadcastStream].
 *
 * This stream controller allows incoming events while it is firing
 * other events. This is handled by delaying the events until the
 * current event is done firing, and then fire the pending events.
 *
 * This class extends [_SyncBroadcastStreamController]. Events of
 * an "asBroadcastStream" stream are always initiated by events
 * on another stream, and it is fine to forward them synchronously.
 */
class _AsBroadcastStreamController<T> extends _SyncBroadcastStreamController<T>
    implements _EventDispatch<T> {
  _StreamImplEvents<T> _pending;

  _AsBroadcastStreamController(void onListen(), void onCancel())
      : super(onListen, onCancel);

  bool get _hasPending => _pending != null && !_pending.isEmpty;

  void _addPendingEvent(_DelayedEvent event) {
    if (_pending == null) {
      _pending = new _StreamImplEvents<T>();
    }
    _pending.add(event);
  }

  void add(T data) {
    if (!isClosed && _isFiring) {
      _addPendingEvent(new _DelayedData<T>(data));
      return;
    }
    super.add(data);
    while (_hasPending) {
      _pending.handleNext(this);
    }
  }

  void addError(Object error, [StackTrace stackTrace]) {
    if (!isClosed && _isFiring) {
      _addPendingEvent(new _DelayedError(error, stackTrace));
      return;
    }
    if (!_mayAddEvent) throw _addEventError();
    _sendError(error, stackTrace);
    while (_hasPending) {
      _pending.handleNext(this);
    }
  }

  Future close() {
    if (!isClosed && _isFiring) {
      _addPendingEvent(const _DelayedDone());
      _state |= _BroadcastStreamController._STATE_CLOSED;
      return super.done;
    }
    Future result = super.close();
    assert(!_hasPending);
    return result;
  }

  void _callOnCancel() {
    if (_hasPending) {
      _pending.clear();
      _pending = null;
    }
    super._callOnCancel();
  }
}
