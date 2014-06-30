// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.async;

class _BroadcastStream<T> extends _ControllerStream<T> {
  _BroadcastStream(_StreamControllerLifecycle controller) : super(controller);

  bool get isBroadcast => true;
}

abstract class _BroadcastSubscriptionLink {
  _BroadcastSubscriptionLink _next;
  _BroadcastSubscriptionLink _previous;
}

class _BroadcastSubscription<T> extends _ControllerSubscription<T>
                                implements _BroadcastSubscriptionLink {
  static const int _STATE_EVENT_ID = 1;
  static const int _STATE_FIRING = 2;
  static const int _STATE_REMOVE_AFTER_FIRING = 4;
  // TODO(lrn): Use the _state field on _ControllerSubscription to
  // also store this state. Requires that the subscription implementation
  // does not assume that it's use of the state integer is the only use.
  int _eventState;

  _BroadcastSubscriptionLink _next;
  _BroadcastSubscriptionLink _previous;

  _BroadcastSubscription(_StreamControllerLifecycle controller,
                         bool cancelOnError)
      : super(controller, cancelOnError) {
    _next = _previous = this;
  }

  _BroadcastStreamController get _controller => super._controller;

  bool _expectsEvent(int eventId) =>
      (_eventState & _STATE_EVENT_ID) == eventId;

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
  void _onPause() { }

  // The controller._recordResume doesn't do anything for a broadcast
  // controller, so we don't bother calling it.
  void _onResume() { }

  // _onCancel is inherited.
}


abstract class _BroadcastStreamController<T>
    implements StreamController<T>,
               _StreamControllerLifecycle<T>,
               _BroadcastSubscriptionLink,
               _EventSink<T>,
               _EventDispatch<T> {
  static const int _STATE_INITIAL = 0;
  static const int _STATE_EVENT_ID = 1;
  static const int _STATE_FIRING = 2;
  static const int _STATE_CLOSED = 4;
  static const int _STATE_ADDSTREAM = 8;

  final _NotificationHandler _onListen;
  final _NotificationHandler _onCancel;

  // State of the controller.
  int _state;

  // Double-linked list of active listeners.
  _BroadcastSubscriptionLink _next;
  _BroadcastSubscriptionLink _previous;

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

  _BroadcastStreamController(this._onListen, this._onCancel)
      : _state = _STATE_INITIAL {
    _next = _previous = this;
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
    return identical(_next._next, this);
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

  bool get _isEmpty => identical(_next, this);

  /** Adds subscription to linked list of active listeners. */
  void _addListener(_BroadcastSubscription<T> subscription) {
    assert(identical(subscription._next, subscription));
    // Insert in linked list just before `this`.
    subscription._previous = _previous;
    subscription._next = this;
    this._previous._next = subscription;
    this._previous = subscription;
    subscription._eventState = (_state & _STATE_EVENT_ID);
  }

  void _removeListener(_BroadcastSubscription<T> subscription) {
    assert(identical(subscription._controller, this));
    assert(!identical(subscription._next, subscription));
    _BroadcastSubscriptionLink previous = subscription._previous;
    _BroadcastSubscriptionLink next = subscription._next;
    previous._next = next;
    next._previous = previous;
    subscription._next = subscription._previous = subscription;
  }

  // _StreamControllerLifecycle interface.

  StreamSubscription<T> _subscribe(bool cancelOnError) {
    if (isClosed) {
      return new _DoneStreamSubscription<T>(_nullDoneHandler);
    }
    StreamSubscription subscription =
        new _BroadcastSubscription<T>(this, cancelOnError);
    _addListener(subscription);
    if (identical(_next, _previous)) {
      // Only one listener, so it must be the first listener.
      _runGuarded(_onListen);
    }
    return subscription;
  }

  Future _recordCancel(_BroadcastSubscription<T> subscription) {
    // If already removed by the stream, don't remove it again.
    if (identical(subscription._next, subscription)) return null;
    assert(!identical(subscription._next, subscription));
    if (subscription._isFiring) {
      subscription._setRemoveAfterFiring();
    } else {
      assert(!identical(subscription._next, subscription));
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
    if (!_mayAddEvent) throw _addEventError();
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
    assert(_isAddingStream);
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
    // Start firing (set the _STATE_FIRING bit). We don't do [_onCancel]
    // callbacks while firing, and we prevent reentrancy of this function.
    //
    // Set [_state]'s event id to the next event's id.
    // Any listeners added while firing this event will expect the next event,
    // not this one, and won't get notified.
    _state ^= _STATE_EVENT_ID | _STATE_FIRING;
    _BroadcastSubscriptionLink link = _next;
    while (!identical(link, this)) {
      _BroadcastSubscription<T> subscription = link;
      if (subscription._expectsEvent(id)) {
        subscription._eventState |= _BroadcastSubscription._STATE_FIRING;
        action(subscription);
        subscription._toggleEventId();
        link = subscription._next;
        if (subscription._removeAfterFiring) {
          _removeListener(subscription);
        }
        subscription._eventState &= ~_BroadcastSubscription._STATE_FIRING;
      } else {
        link = subscription._next;
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
    _runGuarded(_onCancel);
  }
}

class _SyncBroadcastStreamController<T> extends _BroadcastStreamController<T> {
  _SyncBroadcastStreamController(void onListen(), void onCancel())
      : super(onListen, onCancel);

  // EventDispatch interface.

  void _sendData(T data) {
    if (_isEmpty) return;
    if (_hasOneListener) {
      _state |= _BroadcastStreamController._STATE_FIRING;
      _BroadcastSubscription subscription = _next;
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
      _forEachListener((_BroadcastSubscription<T> subscription) {
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
    for (_BroadcastSubscriptionLink link = _next;
         !identical(link, this);
         link = link._next) {
      _BroadcastSubscription<T> subscription = link;
      subscription._addPending(new _DelayedData(data));
    }
  }

  void _sendError(Object error, StackTrace stackTrace) {
    for (_BroadcastSubscriptionLink link = _next;
         !identical(link, this);
         link = link._next) {
      _BroadcastSubscription<T> subscription = link;
      subscription._addPending(new _DelayedError(error, stackTrace));
    }
  }

  void _sendDone() {
    if (!_isEmpty) {
      for (_BroadcastSubscriptionLink link = _next;
           !identical(link, this);
           link = link._next) {
        _BroadcastSubscription<T> subscription = link;
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
class _AsBroadcastStreamController<T>
    extends _SyncBroadcastStreamController<T>
    implements _EventDispatch<T> {
  _StreamImplEvents _pending;

  _AsBroadcastStreamController(void onListen(), void onCancel())
      : super(onListen, onCancel);

  bool get _hasPending => _pending != null && ! _pending.isEmpty;

  void _addPendingEvent(_DelayedEvent event) {
    if (_pending == null) {
      _pending = new _StreamImplEvents();
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
    super.addError(error, stackTrace);
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

// A subscription that never receives any events.
// It can simulate pauses, but otherwise does nothing.
class _DoneSubscription<T> implements StreamSubscription<T> {
  int _pauseCount = 0;
  void onData(void handleData(T data)) {}
  void onError(Function handleError) {}
  void onDone(void handleDone()) {}
  void pause([Future resumeSignal]) {
    if (resumeSignal != null) resumeSignal.then(_resume);
    _pauseCount++;
  }
  void resume() { _resume(null); }
  void _resume(_) {
    if (_pauseCount > 0) _pauseCount--;
  }
  Future cancel() { return new _Future.immediate(null); }
  bool get isPaused => _pauseCount > 0;
  Future asFuture([Object value]) => new _Future();
}
