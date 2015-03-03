part of dart.async;
 abstract class _EventSink<T> {void _add(T data);
 void _addError(Object error, StackTrace stackTrace);
 void _close();
}
 abstract class _EventDispatch<T> {void _sendData(T data);
 void _sendError(Object error, StackTrace stackTrace);
 void _sendDone();
}
 class _BufferingStreamSubscription<T> implements StreamSubscription<T>, _EventSink<T>, _EventDispatch<T> {static const int _STATE_CANCEL_ON_ERROR = 1;
 static const int _STATE_CLOSED = 2;
 static const int _STATE_INPUT_PAUSED = 4;
 static const int _STATE_CANCELED = 8;
 static const int _STATE_WAIT_FOR_CANCEL = 16;
 static const int _STATE_IN_CALLBACK = 32;
 static const int _STATE_HAS_PENDING = 64;
 static const int _STATE_PAUSE_COUNT = 128;
 static const int _STATE_PAUSE_COUNT_SHIFT = 7;
 _DataHandler<T> _onData;
 Function _onError;
 _DoneHandler _onDone;
 final Zone _zone = Zone.current;
 int _state;
 Future _cancelFuture;
 _PendingEvents _pending;
 _BufferingStreamSubscription(void onData(T data), Function onError, void onDone(), bool cancelOnError) : _state = (cancelOnError ? _STATE_CANCEL_ON_ERROR : 0) {
this.onData(onData);
 this.onError(onError);
 this.onDone(onDone);
}
 void _setPendingEvents(_PendingEvents pendingEvents) {
assert (_pending == null); if (pendingEvents == null) return; _pending = pendingEvents;
 if (!pendingEvents.isEmpty) {
_state |= _STATE_HAS_PENDING;
 _pending.schedule(this);
}
}
 _PendingEvents _extractPending() {
assert (_isCanceled); _PendingEvents events = _pending;
 _pending = null;
 return events;
}
 void onData(void handleData(T event)) {
if (handleData == null) handleData = _nullDataHandler;
 _onData = _zone.registerUnaryCallback(DDC$RT.wrap((void f(T __u118)) {
void c(T x0) => f(DDC$RT.cast(x0, dynamic, T, "CastParam", """line 154, column 43 of dart:async/stream_impl.dart: """, x0 is T, false));
 return f == null ? null : c;
}
, handleData, DDC$RT.type((__t121<T> _) {
}
), __t119, "Wrap", """line 154, column 43 of dart:async/stream_impl.dart: """, handleData is __t119));
}
 void onError(Function handleError) {
if (handleError == null) handleError = _nullErrorHandler;
 _onError = _registerErrorHandler(handleError, _zone);
}
 void onDone(void handleDone()) {
if (handleDone == null) handleDone = _nullDoneHandler;
 _onDone = _zone.registerCallback(handleDone);
}
 void pause([Future resumeSignal]) {
if (_isCanceled) return; bool wasPaused = _isPaused;
 bool wasInputPaused = _isInputPaused;
 _state = (_state + _STATE_PAUSE_COUNT) | _STATE_INPUT_PAUSED;
 if (resumeSignal != null) resumeSignal.whenComplete(resume);
 if (!wasPaused && _pending != null) _pending.cancelSchedule();
 if (!wasInputPaused && !_inCallback) _guardCallback(_onPause);
}
 void resume() {
if (_isCanceled) return; if (_isPaused) {
_decrementPauseCount();
 if (!_isPaused) {
  if (_hasPending && !_pending.isEmpty) {
    _pending.schedule(this);
    }
   else {
    assert (_mayResumeInput); _state &= ~_STATE_INPUT_PAUSED;
     if (!_inCallback) _guardCallback(_onResume);
    }
  }
}
}
 Future cancel() {
_state &= ~_STATE_WAIT_FOR_CANCEL;
 if (_isCanceled) return _cancelFuture;
 _cancel();
 return _cancelFuture;
}
 Future asFuture([var futureValue]) {
_Future<T> result = new _Future<T>();
 _onDone = () {
result._complete(futureValue);
}
;
 _onError = (error, stackTrace) {
cancel();
 result._completeError(error, DDC$RT.cast(stackTrace, dynamic, StackTrace, "CastGeneral", """line 212, column 36 of dart:async/stream_impl.dart: """, stackTrace is StackTrace, true));
}
;
 return result;
}
 bool get _isInputPaused => (_state & _STATE_INPUT_PAUSED) != 0;
 bool get _isClosed => (_state & _STATE_CLOSED) != 0;
 bool get _isCanceled => (_state & _STATE_CANCELED) != 0;
 bool get _waitsForCancel => (_state & _STATE_WAIT_FOR_CANCEL) != 0;
 bool get _inCallback => (_state & _STATE_IN_CALLBACK) != 0;
 bool get _hasPending => (_state & _STATE_HAS_PENDING) != 0;
 bool get _isPaused => _state >= _STATE_PAUSE_COUNT;
 bool get _canFire => _state < _STATE_IN_CALLBACK;
 bool get _mayResumeInput => !_isPaused && (_pending == null || _pending.isEmpty);
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
 void _incrementPauseCount() {
_state = (_state + _STATE_PAUSE_COUNT) | _STATE_INPUT_PAUSED;
}
 void _decrementPauseCount() {
assert (_isPaused); _state -= _STATE_PAUSE_COUNT;
}
 void _add(T data) {
assert (!_isClosed); if (_isCanceled) return; if (_canFire) {
_sendData(data);
}
 else {
_addPending(new _DelayedData(data));
}
}
 void _addError(Object error, StackTrace stackTrace) {
if (_isCanceled) return; if (_canFire) {
_sendError(error, stackTrace);
}
 else {
_addPending(new _DelayedError(error, stackTrace));
}
}
 void _close() {
assert (!_isClosed); if (_isCanceled) return; _state |= _STATE_CLOSED;
 if (_canFire) {
_sendDone();
}
 else {
_addPending(const _DelayedDone());
}
}
 void _onPause() {
assert (_isInputPaused);}
 void _onResume() {
assert (!_isInputPaused);}
 Future _onCancel() {
assert (_isCanceled); return null;
}
 void _addPending(_DelayedEvent event) {
_StreamImplEvents pending = DDC$RT.cast(_pending, _PendingEvents, _StreamImplEvents, "CastGeneral", """line 322, column 33 of dart:async/stream_impl.dart: """, _pending is _StreamImplEvents, true);
 if (_pending == null) pending = _pending = new _StreamImplEvents();
 pending.add(event);
 if (!_hasPending) {
_state |= _STATE_HAS_PENDING;
 if (!_isPaused) {
  _pending.schedule(this);
  }
}
}
 void _sendData(T data) {
assert (!_isCanceled); assert (!_isPaused); assert (!_inCallback); bool wasInputPaused = _isInputPaused;
 _state |= _STATE_IN_CALLBACK;
 _zone.runUnaryGuarded(DDC$RT.wrap((void f(T __u123)) {
void c(T x0) => f(DDC$RT.cast(x0, dynamic, T, "CastParam", """line 341, column 27 of dart:async/stream_impl.dart: """, x0 is T, false));
 return f == null ? null : c;
}
, _onData, DDC$RT.type((__t121<T> _) {
}
), __t119, "Wrap", """line 341, column 27 of dart:async/stream_impl.dart: """, _onData is __t119), data);
 _state &= ~_STATE_IN_CALLBACK;
 _checkState(wasInputPaused);
}
 void _sendError(var error, StackTrace stackTrace) {
assert (!_isCanceled); assert (!_isPaused); assert (!_inCallback); bool wasInputPaused = _isInputPaused;
 void sendError() {
if (_isCanceled && !_waitsForCancel) return; _state |= _STATE_IN_CALLBACK;
 if (_onError is ZoneBinaryCallback) {
  _zone.runBinaryGuarded(DDC$RT.cast(_onError, Function, __t124, "CastGeneral", """line 358, column 32 of dart:async/stream_impl.dart: """, _onError is __t124, false), error, stackTrace);
  }
 else {
  _zone.runUnaryGuarded(DDC$RT.cast(_onError, Function, __t119, "CastGeneral", """line 360, column 31 of dart:async/stream_impl.dart: """, _onError is __t119, false), error);
  }
 _state &= ~_STATE_IN_CALLBACK;
}
 if (_cancelOnError) {
_state |= _STATE_WAIT_FOR_CANCEL;
 _cancel();
 if (_cancelFuture is Future) {
  _cancelFuture.whenComplete(sendError);
  }
 else {
  sendError();
  }
}
 else {
sendError();
 _checkState(wasInputPaused);
}
}
 void _sendDone() {
assert (!_isCanceled); assert (!_isPaused); assert (!_inCallback); void sendDone() {
if (!_waitsForCancel) return; _state |= (_STATE_CANCELED | _STATE_CLOSED | _STATE_IN_CALLBACK);
 _zone.runGuarded(_onDone);
 _state &= ~_STATE_IN_CALLBACK;
}
 _cancel();
 _state |= _STATE_WAIT_FOR_CANCEL;
 if (_cancelFuture is Future) {
_cancelFuture.whenComplete(sendDone);
}
 else {
sendDone();
}
}
 void _guardCallback(callback) {
assert (!_inCallback); bool wasInputPaused = _isInputPaused;
 _state |= _STATE_IN_CALLBACK;
 callback();
 _state &= ~_STATE_IN_CALLBACK;
 _checkState(wasInputPaused);
}
 void _checkState(bool wasInputPaused) {
assert (!_inCallback); if (_hasPending && _pending.isEmpty) {
_state &= ~_STATE_HAS_PENDING;
 if (_isInputPaused && _mayResumeInput) {
  _state &= ~_STATE_INPUT_PAUSED;
  }
}
 while (true) {
if (_isCanceled) {
  _pending = null;
   return;}
 bool isInputPaused = _isInputPaused;
 if (wasInputPaused == isInputPaused) break;
 _state ^= _STATE_IN_CALLBACK;
 if (isInputPaused) {
  _onPause();
  }
 else {
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
 abstract class _StreamImpl<T> extends Stream<T> {StreamSubscription<T> listen(void onData(T data), {
Function onError, void onDone(), bool cancelOnError}
) {
cancelOnError = identical(true, cancelOnError);
 StreamSubscription subscription = _createSubscription(onData, onError, onDone, cancelOnError);
 _onListen(subscription);
 return DDC$RT.cast(subscription, DDC$RT.type((StreamSubscription<dynamic> _) {
}
), DDC$RT.type((StreamSubscription<T> _) {
}
), "CastDynamic", """line 476, column 12 of dart:async/stream_impl.dart: """, subscription is StreamSubscription<T>, false);
}
 _BufferingStreamSubscription<T> _createSubscription(void onData(T data), Function onError, void onDone(), bool cancelOnError) {
return new _BufferingStreamSubscription<T>(onData, onError, onDone, cancelOnError);
}
 void _onListen(StreamSubscription subscription) {
}
}
 typedef _PendingEvents _EventGenerator();
 class _GeneratedStreamImpl<T> extends _StreamImpl<T> {final _EventGenerator _pending;
 bool _isUsed = false;
 _GeneratedStreamImpl(this._pending);
 StreamSubscription _createSubscription(void onData(T data), Function onError, void onDone(), bool cancelOnError) {
if (_isUsed) throw new StateError("Stream has already been listened to.");
 _isUsed = true;
 return new _BufferingStreamSubscription(DDC$RT.wrap((void f(T __u127)) {
void c(T x0) => f(DDC$RT.cast(x0, dynamic, T, "CastParam", """line 516, column 9 of dart:async/stream_impl.dart: """, x0 is T, false));
 return f == null ? null : c;
}
, onData, DDC$RT.type((__t130<T> _) {
}
), __t128, "Wrap", """line 516, column 9 of dart:async/stream_impl.dart: """, onData is __t128), onError, onDone, cancelOnError).._setPendingEvents(_pending());
}
}
 class _IterablePendingEvents<T> extends _PendingEvents {Iterator<T> _iterator;
 _IterablePendingEvents(Iterable<T> data) : _iterator = data.iterator;
 bool get isEmpty => _iterator == null;
 void handleNext(_EventDispatch dispatch) {
if (_iterator == null) {
throw new StateError("No events pending.");
}
 bool isDone;
 try {
isDone = !_iterator.moveNext();
}
 catch (e, s) {
_iterator = null;
 dispatch._sendError(e, s);
 return;}
 if (!isDone) {
dispatch._sendData(_iterator.current);
}
 else {
_iterator = null;
 dispatch._sendDone();
}
}
 void clear() {
if (isScheduled) cancelSchedule();
 _iterator = null;
}
}
 typedef void _DataHandler<T>(T value);
 typedef void _DoneHandler();
 void _nullDataHandler(var value) {
}
 void _nullErrorHandler(error, [StackTrace stackTrace]) {
Zone.current.handleUncaughtError(error, stackTrace);
}
 void _nullDoneHandler() {
}
 abstract class _DelayedEvent {_DelayedEvent next;
 void perform(_EventDispatch dispatch);
}
 class _DelayedData<T> extends _DelayedEvent {final T value;
 _DelayedData(this.value);
 void perform(_EventDispatch<T> dispatch) {
dispatch._sendData(value);
}
}
 class _DelayedError extends _DelayedEvent {final error;
 final StackTrace stackTrace;
 _DelayedError(this.error, this.stackTrace);
 void perform(_EventDispatch dispatch) {
dispatch._sendError(error, stackTrace);
}
}
 class _DelayedDone implements _DelayedEvent {const _DelayedDone();
 void perform(_EventDispatch dispatch) {
dispatch._sendDone();
}
 _DelayedEvent get next => null;
 void set next(_DelayedEvent _) {
throw new StateError("No events after a done.");
}
}
 abstract class _PendingEvents {static const int _STATE_UNSCHEDULED = 0;
 static const int _STATE_SCHEDULED = 1;
 static const int _STATE_CANCELED = 3;
 int _state = _STATE_UNSCHEDULED;
 bool get isEmpty;
 bool get isScheduled => _state == _STATE_SCHEDULED;
 bool get _eventScheduled => _state >= _STATE_SCHEDULED;
 void schedule(_EventDispatch dispatch) {
if (isScheduled) return; assert (!isEmpty); if (_eventScheduled) {
assert (_state == _STATE_CANCELED); _state = _STATE_SCHEDULED;
 return;}
 scheduleMicrotask(() {
int oldState = _state;
 _state = _STATE_UNSCHEDULED;
 if (oldState == _STATE_CANCELED) return; handleNext(dispatch);
}
);
 _state = _STATE_SCHEDULED;
}
 void cancelSchedule() {
if (isScheduled) _state = _STATE_CANCELED;
}
 void handleNext(_EventDispatch dispatch);
 void clear();
}
 class _StreamImplEvents extends _PendingEvents {_DelayedEvent firstPendingEvent = null;
 _DelayedEvent lastPendingEvent = null;
 bool get isEmpty => lastPendingEvent == null;
 void add(_DelayedEvent event) {
if (lastPendingEvent == null) {
firstPendingEvent = lastPendingEvent = event;
}
 else {
lastPendingEvent = lastPendingEvent.next = event;
}
}
 void handleNext(_EventDispatch dispatch) {
assert (!isScheduled); _DelayedEvent event = firstPendingEvent;
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
 class _BroadcastLinkedList {_BroadcastLinkedList _next;
 _BroadcastLinkedList _previous;
 void _unlink() {
_previous._next = _next;
 _next._previous = _previous;
 _next = _previous = this;
}
 void _insertBefore(_BroadcastLinkedList newNext) {
_BroadcastLinkedList newPrevious = newNext._previous;
 newPrevious._next = this;
 newNext._previous = _previous;
 _previous._next = newNext;
 _previous = newPrevious;
}
}
 typedef void _broadcastCallback(StreamSubscription subscription);
 class _DoneStreamSubscription<T> implements StreamSubscription<T> {static const int _DONE_SENT = 1;
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
if (_isScheduled) return; _zone.scheduleMicrotask(_sendDone);
 _state |= _SCHEDULED;
}
 void onData(void handleData(T data)) {
}
 void onError(Function handleError) {
}
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
 Future cancel() => null;
 Future asFuture([futureValue]) {
_Future result = new _Future();
 _onDone = () {
result._completeWithValue(null);
}
;
 return result;
}
 void _sendDone() {
_state &= ~_SCHEDULED;
 if (isPaused) return; _state |= _DONE_SENT;
 if (_onDone != null) _zone.runGuarded(_onDone);
}
}
 class _AsBroadcastStream<T> extends Stream<T> {final Stream<T> _source;
 final _broadcastCallback _onListenHandler;
 final _broadcastCallback _onCancelHandler;
 final Zone _zone;
 _AsBroadcastStreamController<T> _controller;
 StreamSubscription<T> _subscription;
 _AsBroadcastStream(this._source, void onListenHandler(StreamSubscription subscription), void onCancelHandler(StreamSubscription subscription)) : _onListenHandler = Zone.current.registerUnaryCallback(DDC$RT.wrap((void f(StreamSubscription<dynamic> __u132)) {
void c(StreamSubscription<dynamic> x0) => f(DDC$RT.cast(x0, dynamic, DDC$RT.type((StreamSubscription<dynamic> _) {
}
), "CastParam", """line 813, column 63 of dart:async/stream_impl.dart: """, x0 is StreamSubscription<dynamic>, true));
 return f == null ? null : c;
}
, onListenHandler, __t133, __t119, "Wrap", """line 813, column 63 of dart:async/stream_impl.dart: """, onListenHandler is __t119)), _onCancelHandler = Zone.current.registerUnaryCallback(DDC$RT.wrap((void f(StreamSubscription<dynamic> __u135)) {
void c(StreamSubscription<dynamic> x0) => f(DDC$RT.cast(x0, dynamic, DDC$RT.type((StreamSubscription<dynamic> _) {
}
), "CastParam", """line 814, column 63 of dart:async/stream_impl.dart: """, x0 is StreamSubscription<dynamic>, true));
 return f == null ? null : c;
}
, onCancelHandler, __t133, __t119, "Wrap", """line 814, column 63 of dart:async/stream_impl.dart: """, onCancelHandler is __t119)), _zone = Zone.current {
_controller = new _AsBroadcastStreamController<T>(_onListen, _onCancel);
}
 bool get isBroadcast => true;
 StreamSubscription<T> listen(void onData(T data), {
Function onError, void onDone(), bool cancelOnError}
) {
if (_controller == null || _controller.isClosed) {
return new _DoneStreamSubscription<T>(onDone);
}
 if (_subscription == null) {
_subscription = _source.listen(_controller.add, onError: _controller.addError, onDone: _controller.close);
}
 cancelOnError = identical(true, cancelOnError);
 return _controller._subscribe(onData, onError, onDone, cancelOnError);
}
 void _onCancel() {
bool shutdown = (_controller == null) || _controller.isClosed;
 if (_onCancelHandler != null) {
_zone.runUnary(DDC$RT.wrap((void f(StreamSubscription<dynamic> __u136)) {
void c(StreamSubscription<dynamic> x0) => f(DDC$RT.cast(x0, dynamic, DDC$RT.type((StreamSubscription<dynamic> _) {
}
), "CastParam", """line 842, column 22 of dart:async/stream_impl.dart: """, x0 is StreamSubscription<dynamic>, true));
 return f == null ? null : c;
}
, _onCancelHandler, __t133, __t119, "Wrap", """line 842, column 22 of dart:async/stream_impl.dart: """, _onCancelHandler is __t119), new _BroadcastSubscriptionWrapper(this));
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
_zone.runUnary(DDC$RT.wrap((void f(StreamSubscription<dynamic> __u137)) {
void c(StreamSubscription<dynamic> x0) => f(DDC$RT.cast(x0, dynamic, DDC$RT.type((StreamSubscription<dynamic> _) {
}
), "CastParam", """line 854, column 22 of dart:async/stream_impl.dart: """, x0 is StreamSubscription<dynamic>, true));
 return f == null ? null : c;
}
, _onListenHandler, __t133, __t119, "Wrap", """line 854, column 22 of dart:async/stream_impl.dart: """, _onListenHandler is __t119), new _BroadcastSubscriptionWrapper(this));
}
}
 void _cancelSubscription() {
if (_subscription == null) return; StreamSubscription subscription = _subscription;
 _subscription = null;
 _controller = null;
 subscription.cancel();
}
 void _pauseSubscription(Future resumeSignal) {
if (_subscription == null) return; _subscription.pause(resumeSignal);
}
 void _resumeSubscription() {
if (_subscription == null) return; _subscription.resume();
}
 bool get _isSubscriptionPaused {
if (_subscription == null) return false;
 return _subscription.isPaused;
}
}
 class _BroadcastSubscriptionWrapper<T> implements StreamSubscription<T> {final _AsBroadcastStream _stream;
 _BroadcastSubscriptionWrapper(this._stream);
 void onData(void handleData(T data)) {
throw new UnsupportedError("Cannot change handlers of asBroadcastStream source subscription.");
}
 void onError(void handleError(Object data)) {
throw new UnsupportedError("Cannot change handlers of asBroadcastStream source subscription.");
}
 void onDone(void handleDone()) {
throw new UnsupportedError("Cannot change handlers of asBroadcastStream source subscription.");
}
 void pause([Future resumeSignal]) {
_stream._pauseSubscription(resumeSignal);
}
 void resume() {
_stream._resumeSubscription();
}
 Future cancel() {
_stream._cancelSubscription();
 return null;
}
 bool get isPaused {
return _stream._isSubscriptionPaused;
}
 Future asFuture([var futureValue]) {
throw new UnsupportedError("Cannot change handlers of asBroadcastStream source subscription.");
}
}
 class _StreamIteratorImpl<T> implements StreamIterator<T> {static const int _STATE_FOUND = 0;
 static const int _STATE_DONE = 1;
 static const int _STATE_MOVING = 2;
 static const int _STATE_EXTRA_DATA = 3;
 static const int _STATE_EXTRA_ERROR = 4;
 static const int _STATE_EXTRA_DONE = 5;
 StreamSubscription _subscription;
 T _current = null;
 var _futureOrPrefetch = null;
 int _state = _STATE_FOUND;
 _StreamIteratorImpl(final Stream<T> stream) {
_subscription = stream.listen(_onData, onError: _onError, onDone: _onDone, cancelOnError: true);
}
 T get current => _current;
 Future<bool> moveNext() {
if (_state == _STATE_DONE) {
return new _Future<bool>.immediate(false);
}
 if (_state == _STATE_MOVING) {
throw new StateError("Already waiting for next.");
}
 if (_state == _STATE_FOUND) {
_state = _STATE_MOVING;
 _current = null;
 _futureOrPrefetch = new _Future<bool>();
 return DDC$RT.cast(_futureOrPrefetch, dynamic, DDC$RT.type((Future<bool> _) {
}
), "CastGeneral", """line 1000, column 14 of dart:async/stream_impl.dart: """, _futureOrPrefetch is Future<bool>, false);
}
 else {
assert (_state >= _STATE_EXTRA_DATA); switch (_state) {case _STATE_EXTRA_DATA: _state = _STATE_FOUND;
 _current = DDC$RT.cast(_futureOrPrefetch, dynamic, T, "CastGeneral", """line 1006, column 22 of dart:async/stream_impl.dart: """, _futureOrPrefetch is T, false);
 _futureOrPrefetch = null;
 _subscription.resume();
 return new _Future<bool>.immediate(true);
 case _STATE_EXTRA_ERROR: AsyncError prefetch = DDC$RT.cast(_futureOrPrefetch, dynamic, AsyncError, "CastGeneral", """line 1011, column 33 of dart:async/stream_impl.dart: """, _futureOrPrefetch is AsyncError, true);
 _clear();
 return new _Future<bool>.immediateError(prefetch.error, prefetch.stackTrace);
 case _STATE_EXTRA_DONE: _clear();
 return new _Future<bool>.immediate(false);
}
}
}
 void _clear() {
_subscription = null;
 _futureOrPrefetch = null;
 _current = null;
 _state = _STATE_DONE;
}
 Future cancel() {
StreamSubscription subscription = _subscription;
 if (_state == _STATE_MOVING) {
_Future<bool> hasNext = DDC$RT.cast(_futureOrPrefetch, dynamic, DDC$RT.type((_Future<bool> _) {
}
), "CastGeneral", """line 1033, column 31 of dart:async/stream_impl.dart: """, _futureOrPrefetch is _Future<bool>, false);
 _clear();
 hasNext._complete(false);
}
 else {
_clear();
}
 return subscription.cancel();
}
 void _onData(T data) {
if (_state == _STATE_MOVING) {
_current = data;
 _Future<bool> hasNext = DDC$RT.cast(_futureOrPrefetch, dynamic, DDC$RT.type((_Future<bool> _) {
}
), "CastGeneral", """line 1045, column 31 of dart:async/stream_impl.dart: """, _futureOrPrefetch is _Future<bool>, false);
 _futureOrPrefetch = null;
 _state = _STATE_FOUND;
 hasNext._complete(true);
 return;}
 _subscription.pause();
 assert (_futureOrPrefetch == null); _futureOrPrefetch = data;
 _state = _STATE_EXTRA_DATA;
}
 void _onError(Object error, [StackTrace stackTrace]) {
if (_state == _STATE_MOVING) {
_Future<bool> hasNext = DDC$RT.cast(_futureOrPrefetch, dynamic, DDC$RT.type((_Future<bool> _) {
}
), "CastGeneral", """line 1059, column 31 of dart:async/stream_impl.dart: """, _futureOrPrefetch is _Future<bool>, false);
 _clear();
 hasNext._completeError(error, stackTrace);
 return;}
 _subscription.pause();
 assert (_futureOrPrefetch == null); _futureOrPrefetch = new AsyncError(error, stackTrace);
 _state = _STATE_EXTRA_ERROR;
}
 void _onDone() {
if (_state == _STATE_MOVING) {
_Future<bool> hasNext = DDC$RT.cast(_futureOrPrefetch, dynamic, DDC$RT.type((_Future<bool> _) {
}
), "CastGeneral", """line 1073, column 31 of dart:async/stream_impl.dart: """, _futureOrPrefetch is _Future<bool>, false);
 _clear();
 hasNext._complete(false);
 return;}
 _subscription.pause();
 _futureOrPrefetch = null;
 _state = _STATE_EXTRA_DONE;
}
}
 typedef dynamic __t119(dynamic __u120);
 typedef void __t121<T>(T __u122);
 typedef dynamic __t124(dynamic __u125, dynamic __u126);
 typedef void __t128(dynamic __u129);
 typedef void __t130<T>(T __u131);
 typedef void __t133(StreamSubscription<dynamic> __u134);
