// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.async;

/** Abstract and private interface for a place to put events. */
abstract class _EventSink<T> {
  void _add(T data);
  void _addError(Object error, StackTrace stackTrace);
  void _close();
}

/**
 * Abstract and private interface for a place to send events.
 *
 * Used by event buffering to finally dispatch the pending event, where
 * [_EventSink] is where the event first enters the stream subscription,
 * and may yet be buffered.
 */
abstract class _EventDispatch<T> {
  void _sendData(T data);
  void _sendError(Object error, StackTrace stackTrace);
  void _sendDone();
}

/**
 * Default implementation of stream subscription of buffering events.
 *
 * The only public methods are those of [StreamSubscription], so instances of
 * [_BufferingStreamSubscription] can be returned directly as a
 * [StreamSubscription] without exposing internal functionality.
 *
 * The [StreamController] is a public facing version of [Stream] and this class,
 * with some methods made public.
 *
 * The user interface of [_BufferingStreamSubscription] are the following
 * methods:
 *
 * * [_add]: Add a data event to the stream.
 * * [_addError]: Add an error event to the stream.
 * * [_close]: Request to close the stream.
 * * [_onCancel]: Called when the subscription will provide no more events,
 *     either due to being actively canceled, or after sending a done event.
 * * [_onPause]: Called when the subscription wants the event source to pause.
 * * [_onResume]: Called when allowing new events after a pause.
 *
 * The user should not add new events when the subscription requests a paused,
 * but if it happens anyway, the subscription will enqueue the events just as
 * when new events arrive while still firing an old event.
 */
class _BufferingStreamSubscription<T>
    implements StreamSubscription<T>, _EventSink<T>, _EventDispatch<T> {
  /** The `cancelOnError` flag from the `listen` call. */
  static const int _STATE_CANCEL_ON_ERROR = 1;
  /**
   * Whether the "done" event has been received.
   * No further events are accepted after this.
   */
  static const int _STATE_CLOSED = 2;
  /**
   * Set if the input has been asked not to send events.
   *
   * This is not the same as being paused, since the input will remain paused
   * after a call to [resume] if there are pending events.
   */
  static const int _STATE_INPUT_PAUSED = 4;
  /**
   * Whether the subscription has been canceled.
   *
   * Set by calling [cancel], or by handling a "done" event, or an "error" event
   * when `cancelOnError` is true.
   */
  static const int _STATE_CANCELED = 8;
  /**
   * Set when either:
   *
   *   * an error is sent, and [cancelOnError] is true, or
   *   * a done event is sent.
   *
   * If the subscription is canceled while _STATE_WAIT_FOR_CANCEL is set, the
   * state is unset, and no further events must be delivered.
   */
  static const int _STATE_WAIT_FOR_CANCEL = 16;
  static const int _STATE_IN_CALLBACK = 32;
  static const int _STATE_HAS_PENDING = 64;
  static const int _STATE_PAUSE_COUNT = 128;

  /* Event handlers provided in constructor. */
  _DataHandler<T> _onData;
  Function _onError;
  _DoneHandler _onDone;
  final Zone _zone = Zone.current;

  /** Bit vector based on state-constants above. */
  int _state;

  // TODO(floitsch): reuse another field
  /** The future [_onCancel] may return. */
  Future _cancelFuture;

  /**
   * Queue of pending events.
   *
   * Is created when necessary, or set in constructor for preconfigured events.
   */
  _PendingEvents<T> _pending;

  _BufferingStreamSubscription(
      void onData(T data), Function onError, void onDone(), bool cancelOnError)
      : _state = (cancelOnError ? _STATE_CANCEL_ON_ERROR : 0) {
    this.onData(onData);
    this.onError(onError);
    this.onDone(onDone);
  }

  /**
   * Sets the subscription's pending events object.
   *
   * This can only be done once. The pending events object is used for the
   * rest of the subscription's life cycle.
   */
  void _setPendingEvents(_PendingEvents<T> pendingEvents) {
    assert(_pending == null);
    if (pendingEvents == null) return;
    _pending = pendingEvents;
    if (!pendingEvents.isEmpty) {
      _state |= _STATE_HAS_PENDING;
      _pending.schedule(this);
    }
  }

  // StreamSubscription interface.

  void onData(void handleData(T event)) {
    if (handleData == null) handleData = _nullDataHandler;
    // TODO(floitsch): the return type should be 'void', and the type
    // should be inferred.
    _onData = _zone.registerUnaryCallback<dynamic, T>(handleData);
  }

  void onError(Function handleError) {
    if (handleError == null) handleError = _nullErrorHandler;
    // We are not allowed to use 'void' as type argument for the generic type,
    // so we use 'dynamic' instead.
    _onError = _registerErrorHandler<dynamic>(handleError, _zone);
  }

  void onDone(void handleDone()) {
    if (handleDone == null) handleDone = _nullDoneHandler;
    _onDone = _zone.registerCallback(handleDone);
  }

  void pause([Future resumeSignal]) {
    if (_isCanceled) return;
    bool wasPaused = _isPaused;
    bool wasInputPaused = _isInputPaused;
    // Increment pause count and mark input paused (if it isn't already).
    _state = (_state + _STATE_PAUSE_COUNT) | _STATE_INPUT_PAUSED;
    if (resumeSignal != null) resumeSignal.whenComplete(resume);
    if (!wasPaused && _pending != null) _pending.cancelSchedule();
    if (!wasInputPaused && !_inCallback) _guardCallback(_onPause);
  }

  void resume() {
    if (_isCanceled) return;
    if (_isPaused) {
      _decrementPauseCount();
      if (!_isPaused) {
        if (_hasPending && !_pending.isEmpty) {
          // Input is still paused.
          _pending.schedule(this);
        } else {
          assert(_mayResumeInput);
          _state &= ~_STATE_INPUT_PAUSED;
          if (!_inCallback) _guardCallback(_onResume);
        }
      }
    }
  }

  Future cancel() {
    // The user doesn't want to receive any further events. If there is an
    // error or done event pending (waiting for the cancel to be done) discard
    // that event.
    _state &= ~_STATE_WAIT_FOR_CANCEL;
    if (!_isCanceled) {
      _cancel();
    }
    return _cancelFuture ?? Future._nullFuture;
  }

  Future<E> asFuture<E>([E futureValue]) {
    _Future<E> result = new _Future<E>();

    // Overwrite the onDone and onError handlers.
    _onDone = () {
      result._complete(futureValue);
    };
    _onError = (error, stackTrace) {
      Future cancelFuture = cancel();
      if (!identical(cancelFuture, Future._nullFuture)) {
        cancelFuture.whenComplete(() {
          result._completeError(error, stackTrace);
        });
      } else {
        result._completeError(error, stackTrace);
      }
    };

    return result;
  }

  // State management.

  bool get _isInputPaused => (_state & _STATE_INPUT_PAUSED) != 0;
  bool get _isClosed => (_state & _STATE_CLOSED) != 0;
  bool get _isCanceled => (_state & _STATE_CANCELED) != 0;
  bool get _waitsForCancel => (_state & _STATE_WAIT_FOR_CANCEL) != 0;
  bool get _inCallback => (_state & _STATE_IN_CALLBACK) != 0;
  bool get _hasPending => (_state & _STATE_HAS_PENDING) != 0;
  bool get _isPaused => _state >= _STATE_PAUSE_COUNT;
  bool get _canFire => _state < _STATE_IN_CALLBACK;
  bool get _mayResumeInput =>
      !_isPaused && (_pending == null || _pending.isEmpty);
  bool get _cancelOnError => (_state & _STATE_CANCEL_ON_ERROR) != 0;

  bool get isPaused => _isPaused;

  void _cancel() {
    _state |= _STATE_CANCELED;
    if (_hasPending) {
      _pending.cancelSchedule();
    }
    if (!_inCallback) _pending = null;
    _cancelFuture = _onCancel();
  }

  /**
   * Decrements the pause count.
   *
   * Does not automatically unpause the input (call [_onResume]) when
   * the pause count reaches zero. This is handled elsewhere, and only
   * if there are no pending events buffered.
   */
  void _decrementPauseCount() {
    assert(_isPaused);
    _state -= _STATE_PAUSE_COUNT;
  }

  // _EventSink interface.

  void _add(T data) {
    assert(!_isClosed);
    if (_isCanceled) return;
    if (_canFire) {
      _sendData(data);
    } else {
      _addPending(new _DelayedData<T>(data));
    }
  }

  void _addError(Object error, StackTrace stackTrace) {
    if (_isCanceled) return;
    if (_canFire) {
      _sendError(error, stackTrace); // Reports cancel after sending.
    } else {
      _addPending(new _DelayedError(error, stackTrace));
    }
  }

  void _close() {
    assert(!_isClosed);
    if (_isCanceled) return;
    _state |= _STATE_CLOSED;
    if (_canFire) {
      _sendDone();
    } else {
      _addPending(const _DelayedDone());
    }
  }

  // Hooks called when the input is paused, unpaused or canceled.
  // These must not throw. If overwritten to call user code, include suitable
  // try/catch wrapping and send any errors to
  // [_Zone.current.handleUncaughtError].
  void _onPause() {
    assert(_isInputPaused);
  }

  void _onResume() {
    assert(!_isInputPaused);
  }

  Future _onCancel() {
    assert(_isCanceled);
    return null;
  }

  // Handle pending events.

  /**
   * Add a pending event.
   *
   * If the subscription is not paused, this also schedules a firing
   * of pending events later (if necessary).
   */
  void _addPending(_DelayedEvent event) {
    _StreamImplEvents<T> pending = _pending;
    if (_pending == null) {
      pending = _pending = new _StreamImplEvents<T>();
    }
    pending.add(event);
    if (!_hasPending) {
      _state |= _STATE_HAS_PENDING;
      if (!_isPaused) {
        _pending.schedule(this);
      }
    }
  }

  /* _EventDispatch interface. */

  void _sendData(T data) {
    assert(!_isCanceled);
    assert(!_isPaused);
    assert(!_inCallback);
    bool wasInputPaused = _isInputPaused;
    _state |= _STATE_IN_CALLBACK;
    _zone.runUnaryGuarded(_onData, data);
    _state &= ~_STATE_IN_CALLBACK;
    _checkState(wasInputPaused);
  }

  void _sendError(Object error, StackTrace stackTrace) {
    assert(!_isCanceled);
    assert(!_isPaused);
    assert(!_inCallback);
    bool wasInputPaused = _isInputPaused;

    void sendError() {
      // If the subscription has been canceled while waiting for the cancel
      // future to finish we must not report the error.
      if (_isCanceled && !_waitsForCancel) return;
      _state |= _STATE_IN_CALLBACK;
      // TODO(floitsch): this dynamic should be 'void'.
      if (_onError is ZoneBinaryCallback<dynamic, Object, StackTrace>) {
        ZoneBinaryCallback<dynamic, Object, StackTrace> errorCallback =
            _onError;
        _zone.runBinaryGuarded(errorCallback, error, stackTrace);
      } else {
        _zone.runUnaryGuarded<Object>(_onError, error);
      }
      _state &= ~_STATE_IN_CALLBACK;
    }

    if (_cancelOnError) {
      _state |= _STATE_WAIT_FOR_CANCEL;
      _cancel();
      if (_cancelFuture is Future &&
          !identical(_cancelFuture, Future._nullFuture)) {
        _cancelFuture.whenComplete(sendError);
      } else {
        sendError();
      }
    } else {
      sendError();
      // Only check state if not cancelOnError.
      _checkState(wasInputPaused);
    }
  }

  void _sendDone() {
    assert(!_isCanceled);
    assert(!_isPaused);
    assert(!_inCallback);

    void sendDone() {
      // If the subscription has been canceled while waiting for the cancel
      // future to finish we must not report the done event.
      if (!_waitsForCancel) return;
      _state |= (_STATE_CANCELED | _STATE_CLOSED | _STATE_IN_CALLBACK);
      _zone.runGuarded(_onDone);
      _state &= ~_STATE_IN_CALLBACK;
    }

    _cancel();
    _state |= _STATE_WAIT_FOR_CANCEL;
    if (_cancelFuture is Future &&
        !identical(_cancelFuture, Future._nullFuture)) {
      _cancelFuture.whenComplete(sendDone);
    } else {
      sendDone();
    }
  }

  /**
   * Call a hook function.
   *
   * The call is properly wrapped in code to avoid other callbacks
   * during the call, and it checks for state changes after the call
   * that should cause further callbacks.
   */
  void _guardCallback(void callback()) {
    assert(!_inCallback);
    bool wasInputPaused = _isInputPaused;
    _state |= _STATE_IN_CALLBACK;
    callback();
    _state &= ~_STATE_IN_CALLBACK;
    _checkState(wasInputPaused);
  }

  /**
   * Check if the input needs to be informed of state changes.
   *
   * State changes are pausing, resuming and canceling.
   *
   * After canceling, no further callbacks will happen.
   *
   * The cancel callback is called after a user cancel, or after
   * the final done event is sent.
   */
  void _checkState(bool wasInputPaused) {
    assert(!_inCallback);
    if (_hasPending && _pending.isEmpty) {
      _state &= ~_STATE_HAS_PENDING;
      if (_isInputPaused && _mayResumeInput) {
        _state &= ~_STATE_INPUT_PAUSED;
      }
    }
    // If the state changes during a callback, we immediately
    // make a new state-change callback. Loop until the state didn't change.
    while (true) {
      if (_isCanceled) {
        _pending = null;
        return;
      }
      bool isInputPaused = _isInputPaused;
      if (wasInputPaused == isInputPaused) break;
      _state ^= _STATE_IN_CALLBACK;
      if (isInputPaused) {
        _onPause();
      } else {
        _onResume();
      }
      _state &= ~_STATE_IN_CALLBACK;
      wasInputPaused = isInputPaused;
    }
    if (_hasPending && !_isPaused) {
      _pending.schedule(this);
    }
  }
}

// -------------------------------------------------------------------
// Common base class for single and multi-subscription streams.
// -------------------------------------------------------------------
abstract class _StreamImpl<T> extends Stream<T> {
  // ------------------------------------------------------------------
  // Stream interface.

  StreamSubscription<T> listen(void onData(T data),
      {Function onError, void onDone(), bool cancelOnError}) {
    cancelOnError = identical(true, cancelOnError);
    StreamSubscription<T> subscription =
        _createSubscription(onData, onError, onDone, cancelOnError);
    _onListen(subscription);
    return subscription;
  }

  // -------------------------------------------------------------------
  /** Create a subscription object. Called by [subcribe]. */
  StreamSubscription<T> _createSubscription(void onData(T data),
      Function onError, void onDone(), bool cancelOnError) {
    return new _BufferingStreamSubscription<T>(
        onData, onError, onDone, cancelOnError);
  }

  /** Hook called when the subscription has been created. */
  void _onListen(StreamSubscription subscription) {}
}

typedef _PendingEvents<T> _EventGenerator<T>();

/** Stream that generates its own events. */
class _GeneratedStreamImpl<T> extends _StreamImpl<T> {
  final _EventGenerator<T> _pending;
  bool _isUsed = false;
  /**
   * Initializes the stream to have only the events provided by a
   * [_PendingEvents].
   *
   * A new [_PendingEvents] must be generated for each listen.
   */
  _GeneratedStreamImpl(this._pending);

  StreamSubscription<T> _createSubscription(void onData(T data),
      Function onError, void onDone(), bool cancelOnError) {
    if (_isUsed) throw new StateError("Stream has already been listened to.");
    _isUsed = true;
    return new _BufferingStreamSubscription<T>(
        onData, onError, onDone, cancelOnError)
      .._setPendingEvents(_pending());
  }
}

/** Pending events object that gets its events from an [Iterable]. */
class _IterablePendingEvents<T> extends _PendingEvents<T> {
  // The iterator providing data for data events.
  // Set to null when iteration has completed.
  Iterator<T> _iterator;

  _IterablePendingEvents(Iterable<T> data) : _iterator = data.iterator;

  bool get isEmpty => _iterator == null;

  void handleNext(_EventDispatch<T> dispatch) {
    if (_iterator == null) {
      throw new StateError("No events pending.");
    }
    // Send one event per call to moveNext.
    // If moveNext returns true, send the current element as data.
    // If moveNext returns false, send a done event and clear the _iterator.
    // If moveNext throws an error, send an error and clear the _iterator.
    // After an error, no further events will be sent.
    bool isDone;
    try {
      isDone = !_iterator.moveNext();
    } catch (e, s) {
      _iterator = null;
      dispatch._sendError(e, s);
      return;
    }
    if (!isDone) {
      dispatch._sendData(_iterator.current);
    } else {
      _iterator = null;
      dispatch._sendDone();
    }
  }

  void clear() {
    if (isScheduled) cancelSchedule();
    _iterator = null;
  }
}

// Internal helpers.

// Types of the different handlers on a stream. Types used to type fields.
typedef void _DataHandler<T>(T value);
typedef void _DoneHandler();

/** Default data handler, does nothing. */
void _nullDataHandler(Object value) {}

/** Default error handler, reports the error to the current zone's handler. */
void _nullErrorHandler(Object error, [StackTrace stackTrace]) {
  Zone.current.handleUncaughtError(error, stackTrace);
}

/** Default done handler, does nothing. */
void _nullDoneHandler() {}

/** A delayed event on a buffering stream subscription. */
abstract class _DelayedEvent<T> {
  /** Added as a linked list on the [StreamController]. */
  _DelayedEvent next;
  /** Execute the delayed event on the [StreamController]. */
  void perform(_EventDispatch<T> dispatch);
}

/** A delayed data event. */
class _DelayedData<T> extends _DelayedEvent<T> {
  final T value;
  _DelayedData(this.value);
  void perform(_EventDispatch<T> dispatch) {
    dispatch._sendData(value);
  }
}

/** A delayed error event. */
class _DelayedError extends _DelayedEvent {
  final error;
  final StackTrace stackTrace;

  _DelayedError(this.error, this.stackTrace);
  void perform(_EventDispatch dispatch) {
    dispatch._sendError(error, stackTrace);
  }
}

/** A delayed done event. */
class _DelayedDone implements _DelayedEvent {
  const _DelayedDone();
  void perform(_EventDispatch dispatch) {
    dispatch._sendDone();
  }

  _DelayedEvent get next => null;

  void set next(_DelayedEvent _) {
    throw new StateError("No events after a done.");
  }
}

/** Superclass for provider of pending events. */
abstract class _PendingEvents<T> {
  // No async event has been scheduled.
  static const int _STATE_UNSCHEDULED = 0;
  // An async event has been scheduled to run a function.
  static const int _STATE_SCHEDULED = 1;
  // An async event has been scheduled, but it will do nothing when it runs.
  // Async events can't be preempted.
  static const int _STATE_CANCELED = 3;

  /**
   * State of being scheduled.
   *
   * Set to [_STATE_SCHEDULED] when pending events are scheduled for
   * async dispatch. Since we can't cancel a [scheduleMicrotask] call, if
   * scheduling is "canceled", the _state is simply set to [_STATE_CANCELED]
   * which will make the async code do nothing except resetting [_state].
   *
   * If events are scheduled while the state is [_STATE_CANCELED], it is
   * merely switched back to [_STATE_SCHEDULED], but no new call to
   * [scheduleMicrotask] is performed.
   */
  int _state = _STATE_UNSCHEDULED;

  bool get isEmpty;

  bool get isScheduled => _state == _STATE_SCHEDULED;
  bool get _eventScheduled => _state >= _STATE_SCHEDULED;

  /**
   * Schedule an event to run later.
   *
   * If called more than once, it should be called with the same dispatch as
   * argument each time. It may reuse an earlier argument in some cases.
   */
  void schedule(_EventDispatch<T> dispatch) {
    if (isScheduled) return;
    assert(!isEmpty);
    if (_eventScheduled) {
      assert(_state == _STATE_CANCELED);
      _state = _STATE_SCHEDULED;
      return;
    }
    scheduleMicrotask(() {
      int oldState = _state;
      _state = _STATE_UNSCHEDULED;
      if (oldState == _STATE_CANCELED) return;
      handleNext(dispatch);
    });
    _state = _STATE_SCHEDULED;
  }

  void cancelSchedule() {
    if (isScheduled) _state = _STATE_CANCELED;
  }

  void handleNext(_EventDispatch<T> dispatch);

  /** Throw away any pending events and cancel scheduled events. */
  void clear();
}

/** Class holding pending events for a [_StreamImpl]. */
class _StreamImplEvents<T> extends _PendingEvents<T> {
  /// Single linked list of [_DelayedEvent] objects.
  _DelayedEvent firstPendingEvent = null;

  /// Last element in the list of pending events. New events are added after it.
  _DelayedEvent lastPendingEvent = null;

  bool get isEmpty => lastPendingEvent == null;

  void add(_DelayedEvent event) {
    if (lastPendingEvent == null) {
      firstPendingEvent = lastPendingEvent = event;
    } else {
      lastPendingEvent = lastPendingEvent.next = event;
    }
  }

  void handleNext(_EventDispatch<T> dispatch) {
    assert(!isScheduled);
    _DelayedEvent event = firstPendingEvent;
    firstPendingEvent = event.next;
    if (firstPendingEvent == null) {
      lastPendingEvent = null;
    }
    event.perform(dispatch);
  }

  void clear() {
    if (isScheduled) cancelSchedule();
    firstPendingEvent = lastPendingEvent = null;
  }
}

typedef void _BroadcastCallback<T>(StreamSubscription<T> subscription);

/**
 * Done subscription that will send one done event as soon as possible.
 */
class _DoneStreamSubscription<T> implements StreamSubscription<T> {
  static const int _DONE_SENT = 1;
  static const int _SCHEDULED = 2;
  static const int _PAUSED = 4;

  final Zone _zone;
  int _state = 0;
  _DoneHandler _onDone;

  _DoneStreamSubscription(this._onDone) : _zone = Zone.current {
    _schedule();
  }

  bool get _isSent => (_state & _DONE_SENT) != 0;
  bool get _isScheduled => (_state & _SCHEDULED) != 0;
  bool get isPaused => _state >= _PAUSED;

  void _schedule() {
    if (_isScheduled) return;
    _zone.scheduleMicrotask(_sendDone);
    _state |= _SCHEDULED;
  }

  void onData(void handleData(T data)) {}
  void onError(Function handleError) {}
  void onDone(void handleDone()) {
    _onDone = handleDone;
  }

  void pause([Future resumeSignal]) {
    _state += _PAUSED;
    if (resumeSignal != null) resumeSignal.whenComplete(resume);
  }

  void resume() {
    if (isPaused) {
      _state -= _PAUSED;
      if (!isPaused && !_isSent) {
        _schedule();
      }
    }
  }

  Future cancel() => Future._nullFuture;

  Future<E> asFuture<E>([E futureValue]) {
    _Future<E> result = new _Future<E>();
    _onDone = () {
      result._completeWithValue(null);
    };
    return result;
  }

  void _sendDone() {
    _state &= ~_SCHEDULED;
    if (isPaused) return;
    _state |= _DONE_SENT;
    if (_onDone != null) _zone.runGuarded(_onDone);
  }
}

class _AsBroadcastStream<T> extends Stream<T> {
  final Stream<T> _source;
  final _BroadcastCallback<T> _onListenHandler;
  final _BroadcastCallback<T> _onCancelHandler;
  final Zone _zone;

  _AsBroadcastStreamController<T> _controller;
  StreamSubscription<T> _subscription;

  _AsBroadcastStream(
      this._source,
      void onListenHandler(StreamSubscription<T> subscription),
      void onCancelHandler(StreamSubscription<T> subscription))
      // TODO(floitsch): the return type should be void and should be
      // inferred.
      : _onListenHandler = Zone.current
            .registerUnaryCallback<dynamic, StreamSubscription<T>>(
                onListenHandler),
        _onCancelHandler = Zone.current
            .registerUnaryCallback<dynamic, StreamSubscription<T>>(
                onCancelHandler),
        _zone = Zone.current {
    _controller = new _AsBroadcastStreamController<T>(_onListen, _onCancel);
  }

  bool get isBroadcast => true;

  StreamSubscription<T> listen(void onData(T data),
      {Function onError, void onDone(), bool cancelOnError}) {
    if (_controller == null || _controller.isClosed) {
      // Return a dummy subscription backed by nothing, since
      // it will only ever send one done event.
      return new _DoneStreamSubscription<T>(onDone);
    }
    if (_subscription == null) {
      _subscription = _source.listen(_controller.add,
          onError: _controller.addError, onDone: _controller.close);
    }
    cancelOnError = identical(true, cancelOnError);
    return _controller._subscribe(onData, onError, onDone, cancelOnError);
  }

  void _onCancel() {
    bool shutdown = (_controller == null) || _controller.isClosed;
    if (_onCancelHandler != null) {
      _zone.runUnary(
          _onCancelHandler, new _BroadcastSubscriptionWrapper<T>(this));
    }
    if (shutdown) {
      if (_subscription != null) {
        _subscription.cancel();
        _subscription = null;
      }
    }
  }

  void _onListen() {
    if (_onListenHandler != null) {
      _zone.runUnary(
          _onListenHandler, new _BroadcastSubscriptionWrapper<T>(this));
    }
  }

  // Methods called from _BroadcastSubscriptionWrapper.
  void _cancelSubscription() {
    if (_subscription == null) return;
    // Called by [_controller] when it has no subscribers left.
    StreamSubscription subscription = _subscription;
    _subscription = null;
    _controller = null; // Marks the stream as no longer listenable.
    subscription.cancel();
  }

  void _pauseSubscription(Future resumeSignal) {
    if (_subscription == null) return;
    _subscription.pause(resumeSignal);
  }

  void _resumeSubscription() {
    if (_subscription == null) return;
    _subscription.resume();
  }

  bool get _isSubscriptionPaused {
    if (_subscription == null) return false;
    return _subscription.isPaused;
  }
}

/**
 * Wrapper for subscription that disallows changing handlers.
 */
class _BroadcastSubscriptionWrapper<T> implements StreamSubscription<T> {
  final _AsBroadcastStream _stream;

  _BroadcastSubscriptionWrapper(this._stream);

  void onData(void handleData(T data)) {
    throw new UnsupportedError(
        "Cannot change handlers of asBroadcastStream source subscription.");
  }

  void onError(Function handleError) {
    throw new UnsupportedError(
        "Cannot change handlers of asBroadcastStream source subscription.");
  }

  void onDone(void handleDone()) {
    throw new UnsupportedError(
        "Cannot change handlers of asBroadcastStream source subscription.");
  }

  void pause([Future resumeSignal]) {
    _stream._pauseSubscription(resumeSignal);
  }

  void resume() {
    _stream._resumeSubscription();
  }

  Future cancel() {
    _stream._cancelSubscription();
    return Future._nullFuture;
  }

  bool get isPaused {
    return _stream._isSubscriptionPaused;
  }

  Future<E> asFuture<E>([E futureValue]) {
    throw new UnsupportedError(
        "Cannot change handlers of asBroadcastStream source subscription.");
  }
}

/**
 * Simple implementation of [StreamIterator].
 *
 * Pauses the stream between calls to [moveNext].
 */
class _StreamIterator<T> implements StreamIterator<T> {
  // The stream iterator is always in one of four states.
  // The value of the [_stateData] field depends on the state.
  //
  // When `_subscription == null` and `_stateData != null`:
  // The stream iterator has been created, but [moveNext] has not been called
  // yet. The [_stateData] field contains the stream to listen to on the first
  // call to [moveNext] and [current] returns `null`.
  //
  // When `_subscription != null` and `!_isPaused`:
  // The user has called [moveNext] and the iterator is waiting for the next
  // event. The [_stateData] field contains the [_Future] returned by the
  // [_moveNext] call and [current] returns `null.`
  //
  // When `_subscription != null` and `_isPaused`:
  // The most recent call to [moveNext] has completed with a `true` value
  // and [current] provides the value of the data event.
  // The [_stateData] field contains the [current] value.
  //
  // When `_subscription == null` and `_stateData == null`:
  // The stream has completed or been canceled using [cancel].
  // The stream completes on either a done event or an error event.
  // The last call to [moveNext] has completed with `false` and [current]
  // returns `null`.

  /// Subscription being listened to.
  ///
  /// Set to `null` when the stream subscription is done or canceled.
  StreamSubscription _subscription;

  /// Data value depending on the current state.
  ///
  /// Before first call to [moveNext]: The stream to listen to.
  ///
  /// After calling [moveNext] but before the returned future completes:
  /// The returned future.
  ///
  /// After calling [moveNext] and the returned future has completed
  /// with `true`: The value of [current].
  ///
  /// After calling [moveNext] and the returned future has completed
  /// with `false`, or after calling [cancel]: `null`.
  Object _stateData;

  /// Whether the iterator is between calls to `moveNext`.
  /// This will usually cause the [_subscription] to be paused, but as an
  /// optimization, we only pause after the [moveNext] future has been
  /// completed.
  bool _isPaused = false;

  _StreamIterator(final Stream<T> stream) : _stateData = stream;

  T get current {
    if (_subscription != null && _isPaused) {
      return _stateData as Object/*=T*/;
    }
    return null;
  }

  Future<bool> moveNext() {
    if (_subscription != null) {
      if (_isPaused) {
        var future = new _Future<bool>();
        _stateData = future;
        _isPaused = false;
        _subscription.resume();
        return future;
      }
      throw new StateError("Already waiting for next.");
    }
    return _initializeOrDone();
  }

  /// Called if there is no active subscription when [moveNext] is called.
  ///
  /// Either starts listening on the stream if this is the first call to
  /// [moveNext], or returns a `false` future because the stream has already
  /// ended.
  Future<bool> _initializeOrDone() {
    assert(_subscription == null);
    var stateData = _stateData;
    if (stateData != null) {
      Stream<T> stream = stateData as Object/*=Stream<T>*/;
      _subscription = stream.listen(_onData,
          onError: _onError, onDone: _onDone, cancelOnError: true);
      var future = new _Future<bool>();
      _stateData = future;
      return future;
    }
    return Future._falseFuture;
  }

  Future cancel() {
    StreamSubscription<T> subscription = _subscription;
    Object stateData = _stateData;
    _stateData = null;
    if (subscription != null) {
      _subscription = null;
      if (!_isPaused) {
        _Future<bool> future = stateData as Object/*=_Future<bool>*/;
        future._asyncComplete(false);
      }
      return subscription.cancel();
    }
    return Future._nullFuture;
  }

  void _onData(T data) {
    assert(_subscription != null && !_isPaused);
    _Future<bool> moveNextFuture = _stateData as Object/*=_Future<bool>*/;
    _stateData = data;
    _isPaused = true;
    moveNextFuture._complete(true);
    if (_subscription != null && _isPaused) _subscription.pause();
  }

  void _onError(Object error, [StackTrace stackTrace]) {
    assert(_subscription != null && !_isPaused);
    _Future<bool> moveNextFuture = _stateData as Object/*=_Future<bool>*/;
    _subscription = null;
    _stateData = null;
    moveNextFuture._completeError(error, stackTrace);
  }

  void _onDone() {
    assert(_subscription != null && !_isPaused);
    _Future<bool> moveNextFuture = _stateData as Object/*=_Future<bool>*/;
    _subscription = null;
    _stateData = null;
    moveNextFuture._complete(false);
  }
}

/** An empty broadcast stream, sending a done event as soon as possible. */
class _EmptyStream<T> extends Stream<T> {
  const _EmptyStream() : super._internal();
  bool get isBroadcast => true;
  StreamSubscription<T> listen(void onData(T data),
      {Function onError, void onDone(), bool cancelOnError}) {
    return new _DoneStreamSubscription<T>(onDone);
  }
}
