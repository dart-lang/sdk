part of dart.async;
 class _BroadcastStream<T> extends _ControllerStream<T> {_BroadcastStream(_StreamControllerLifecycle controller) : super(DEVC$RT.cast(controller, DEVC$RT.type((_StreamControllerLifecycle<dynamic> _) {
  }
), DEVC$RT.type((_StreamControllerLifecycle<T> _) {
  }
), "CompositeCast", """line 8, column 67 of dart:async/broadcast_stream_controller.dart: """, controller is _StreamControllerLifecycle<T>, false));
 bool get isBroadcast => true;
}
 abstract class _BroadcastSubscriptionLink {_BroadcastSubscriptionLink _next;
 _BroadcastSubscriptionLink _previous;
}
 class _BroadcastSubscription<T> extends _ControllerSubscription<T> implements _BroadcastSubscriptionLink {static const int _STATE_EVENT_ID = 1;
 static const int _STATE_FIRING = 2;
 static const int _STATE_REMOVE_AFTER_FIRING = 4;
 int _eventState;
 _BroadcastSubscriptionLink _next;
 _BroadcastSubscriptionLink _previous;
 _BroadcastSubscription(_StreamControllerLifecycle controller, void onData(T data), Function onError, void onDone(), bool cancelOnError) : super(DEVC$RT.cast(controller, DEVC$RT.type((_StreamControllerLifecycle<dynamic> _) {
}
), DEVC$RT.type((_StreamControllerLifecycle<T> _) {
}
), "CompositeCast", """line 36, column 15 of dart:async/broadcast_stream_controller.dart: """, controller is _StreamControllerLifecycle<T>, false), onData, onError, onDone, cancelOnError) {
_next = _previous = this;
}
 _BroadcastStreamController<T> get _controller => ((__x2) => DEVC$RT.cast(__x2, DEVC$RT.type((_StreamControllerLifecycle<T> _) {
}
), DEVC$RT.type((_BroadcastStreamController<T> _) {
}
), "CompositeCast", """line 40, column 52 of dart:async/broadcast_stream_controller.dart: """, __x2 is _BroadcastStreamController<T>, false))(super._controller);
 bool _expectsEvent(int eventId) => (_eventState & _STATE_EVENT_ID) == eventId;
 void _toggleEventId() {
_eventState ^= _STATE_EVENT_ID;
}
 bool get _isFiring => (_eventState & _STATE_FIRING) != 0;
 void _setRemoveAfterFiring() {
assert (_isFiring); _eventState |= _STATE_REMOVE_AFTER_FIRING;
}
 bool get _removeAfterFiring => (_eventState & _STATE_REMOVE_AFTER_FIRING) != 0;
 void _onPause() {
}
 void _onResume() {
}
}
 abstract class _BroadcastStreamController<T> implements StreamController<T>, _StreamControllerLifecycle<T>, _BroadcastSubscriptionLink, _EventSink<T>, _EventDispatch<T> {static const int _STATE_INITIAL = 0;
 static const int _STATE_EVENT_ID = 1;
 static const int _STATE_FIRING = 2;
 static const int _STATE_CLOSED = 4;
 static const int _STATE_ADDSTREAM = 8;
 final _NotificationHandler _onListen;
 final _NotificationHandler _onCancel;
 int _state;
 _BroadcastSubscriptionLink _next;
 _BroadcastSubscriptionLink _previous;
 _AddStreamState<T> _addStreamState;
 _Future _doneFuture;
 _BroadcastStreamController(this._onListen, this._onCancel) : _state = _STATE_INITIAL {
_next = _previous = this;
}
 Stream<T> get stream => new _BroadcastStream<T>(this);
 StreamSink<T> get sink => new _StreamSinkWrapper<T>(this);
 bool get isClosed => (_state & _STATE_CLOSED) != 0;
 bool get isPaused => false;
 bool get hasListener => !_isEmpty;
 bool get _hasOneListener {
assert (!_isEmpty); return identical(_next._next, this);
}
 bool get _isFiring => (_state & _STATE_FIRING) != 0;
 bool get _isAddingStream => (_state & _STATE_ADDSTREAM) != 0;
 bool get _mayAddEvent => (_state < _STATE_CLOSED);
 _Future _ensureDoneFuture() {
if (_doneFuture != null) return _doneFuture;
 return _doneFuture = new _Future();
}
 bool get _isEmpty => identical(_next, this);
 void _addListener(_BroadcastSubscription<T> subscription) {
assert (identical(subscription._next, subscription)); subscription._previous = _previous;
 subscription._next = this;
 this._previous._next = subscription;
 this._previous = subscription;
 subscription._eventState = (_state & _STATE_EVENT_ID);
}
 void _removeListener(_BroadcastSubscription<T> subscription) {
assert (identical(subscription._controller, this)); assert (!identical(subscription._next, subscription)); _BroadcastSubscriptionLink previous = subscription._previous;
 _BroadcastSubscriptionLink next = subscription._next;
 previous._next = next;
 next._previous = previous;
 subscription._next = subscription._previous = subscription;
}
 StreamSubscription<T> _subscribe(void onData(T data), Function onError, void onDone(), bool cancelOnError) {
if (isClosed) {
if (onDone == null) onDone = _nullDoneHandler;
 return new _DoneStreamSubscription<T>(onDone);
}
 StreamSubscription subscription = new _BroadcastSubscription<T>(this, onData, onError, onDone, cancelOnError);
 _addListener(DEVC$RT.cast(subscription, DEVC$RT.type((StreamSubscription<dynamic> _) {
}
), DEVC$RT.type((_BroadcastSubscription<T> _) {
}
), "CompositeCast", """line 196, column 18 of dart:async/broadcast_stream_controller.dart: """, subscription is _BroadcastSubscription<T>, false));
 if (identical(_next, _previous)) {
_runGuarded(_onListen);
}
 return DEVC$RT.cast(subscription, DEVC$RT.type((StreamSubscription<dynamic> _) {
}
), DEVC$RT.type((StreamSubscription<T> _) {
}
), "CompositeCast", """line 201, column 12 of dart:async/broadcast_stream_controller.dart: """, subscription is StreamSubscription<T>, false);
}
 Future _recordCancel(StreamSubscription<T> subscription) {
if (identical(subscription._next, subscription)) return null;
 assert (!identical(subscription._next, subscription)); if (subscription._isFiring) {
subscription._setRemoveAfterFiring();
}
 else {
assert (!identical(subscription._next, subscription)); _removeListener(DEVC$RT.cast(subscription, DEVC$RT.type((StreamSubscription<T> _) {
}
), DEVC$RT.type((_BroadcastSubscription<T> _) {
}
), "CompositeCast", """line 212, column 23 of dart:async/broadcast_stream_controller.dart: """, subscription is _BroadcastSubscription<T>, false));
 if (!_isFiring && _isEmpty) {
_callOnCancel();
}
}
 return null;
}
 void _recordPause(StreamSubscription<T> subscription) {
}
 void _recordResume(StreamSubscription<T> subscription) {
}
 Error _addEventError() {
if (isClosed) {
return new StateError("Cannot add new events after calling close");
}
 assert (_isAddingStream); return new StateError("Cannot add new events while doing an addStream");
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
assert (_doneFuture != null); return _doneFuture;
}
 if (!_mayAddEvent) throw _addEventError();
 _state |= _STATE_CLOSED;
 Future doneFuture = _ensureDoneFuture();
 _sendDone();
 return doneFuture;
}
 Future get done => _ensureDoneFuture();
 Future addStream(Stream<T> stream, {
bool cancelOnError : true}
) {
if (!_mayAddEvent) throw _addEventError();
 _state |= _STATE_ADDSTREAM;
 _addStreamState = new _AddStreamState<T>(this, stream, cancelOnError);
 return _addStreamState.addStreamFuture;
}
 void _add(T data) {
_sendData(data);
}
 void _addError(Object error, StackTrace stackTrace) {
_sendError(error, stackTrace);
}
 void _close() {
assert (_isAddingStream); _AddStreamState addState = _addStreamState;
 _addStreamState = null;
 _state &= ~_STATE_ADDSTREAM;
 addState.complete();
}
 void _forEachListener(void action(_BufferingStreamSubscription<T> subscription)) {
if (_isFiring) {
throw new StateError("Cannot fire new event. Controller is already firing an event");
}
 if (_isEmpty) return; int id = (_state & _STATE_EVENT_ID);
 _state ^= _STATE_EVENT_ID | _STATE_FIRING;
 _BroadcastSubscriptionLink link = _next;
 while (!identical(link, this)) {
_BroadcastSubscription<T> subscription = DEVC$RT.cast(link, _BroadcastSubscriptionLink, DEVC$RT.type((_BroadcastSubscription<T> _) {
}
), "CompositeCast", """line 309, column 48 of dart:async/broadcast_stream_controller.dart: """, link is _BroadcastSubscription<T>, false);
 if (subscription._expectsEvent(id)) {
subscription._eventState |= _BroadcastSubscription._STATE_FIRING;
 action(subscription);
 subscription._toggleEventId();
 link = subscription._next;
 if (subscription._removeAfterFiring) {
  _removeListener(subscription);
  }
 subscription._eventState &= ~_BroadcastSubscription._STATE_FIRING;
}
 else {
link = subscription._next;
}
}
 _state &= ~_STATE_FIRING;
 if (_isEmpty) {
_callOnCancel();
}
}
 void _callOnCancel() {
assert (_isEmpty); if (isClosed && _doneFuture._mayComplete) {
_doneFuture._asyncComplete(null);
}
 _runGuarded(_onCancel);
}
}
 class _SyncBroadcastStreamController<T> extends _BroadcastStreamController<T> {_SyncBroadcastStreamController(void onListen(), void onCancel()) : super(onListen, onCancel);
 void _sendData(T data) {
if (_isEmpty) return; if (_hasOneListener) {
_state |= _BroadcastStreamController._STATE_FIRING;
 _BroadcastSubscription subscription = DEVC$RT.cast(_next, _BroadcastSubscriptionLink, DEVC$RT.type((_BroadcastSubscription<dynamic> _) {
}
), "AssignmentCast", """line 350, column 45 of dart:async/broadcast_stream_controller.dart: """, _next is _BroadcastSubscription<dynamic>, true);
 subscription._add(data);
 _state &= ~_BroadcastStreamController._STATE_FIRING;
 if (_isEmpty) {
_callOnCancel();
}
 return;}
 _forEachListener((_BufferingStreamSubscription<T> subscription) {
subscription._add(data);
}
);
}
 void _sendError(Object error, StackTrace stackTrace) {
if (_isEmpty) return; _forEachListener((_BufferingStreamSubscription<T> subscription) {
subscription._addError(error, stackTrace);
}
);
}
 void _sendDone() {
if (!_isEmpty) {
_forEachListener(((__x7) => DEVC$RT.cast(__x7, DEVC$RT.type((__CastType5<T> _) {
}
), DEVC$RT.type((__CastType3<T> _) {
}
), "InferableClosure", """line 372, column 24 of dart:async/broadcast_stream_controller.dart: """, __x7 is __CastType3<T>, false))((_BroadcastSubscription<T> subscription) {
subscription._close();
}
));
}
 else {
assert (_doneFuture != null); assert (_doneFuture._mayComplete); _doneFuture._asyncComplete(null);
}
}
}
 class _AsyncBroadcastStreamController<T> extends _BroadcastStreamController<T> {_AsyncBroadcastStreamController(void onListen(), void onCancel()) : super(onListen, onCancel);
 void _sendData(T data) {
for (_BroadcastSubscriptionLink link = _next; !identical(link, this); link = link._next) {
_BroadcastSubscription<T> subscription = DEVC$RT.cast(link, _BroadcastSubscriptionLink, DEVC$RT.type((_BroadcastSubscription<T> _) {
}
), "CompositeCast", """line 393, column 48 of dart:async/broadcast_stream_controller.dart: """, link is _BroadcastSubscription<T>, false);
 subscription._addPending(new _DelayedData(data));
}
}
 void _sendError(Object error, StackTrace stackTrace) {
for (_BroadcastSubscriptionLink link = _next; !identical(link, this); link = link._next) {
_BroadcastSubscription<T> subscription = DEVC$RT.cast(link, _BroadcastSubscriptionLink, DEVC$RT.type((_BroadcastSubscription<T> _) {
}
), "CompositeCast", """line 402, column 48 of dart:async/broadcast_stream_controller.dart: """, link is _BroadcastSubscription<T>, false);
 subscription._addPending(new _DelayedError(error, stackTrace));
}
}
 void _sendDone() {
if (!_isEmpty) {
for (_BroadcastSubscriptionLink link = _next; !identical(link, this); link = link._next) {
_BroadcastSubscription<T> subscription = DEVC$RT.cast(link, _BroadcastSubscriptionLink, DEVC$RT.type((_BroadcastSubscription<T> _) {
}
), "CompositeCast", """line 412, column 50 of dart:async/broadcast_stream_controller.dart: """, link is _BroadcastSubscription<T>, false);
 subscription._addPending(const _DelayedDone());
}
}
 else {
assert (_doneFuture != null); assert (_doneFuture._mayComplete); _doneFuture._asyncComplete(null);
}
}
}
 class _AsBroadcastStreamController<T> extends _SyncBroadcastStreamController<T> implements _EventDispatch<T> {_StreamImplEvents _pending;
 _AsBroadcastStreamController(void onListen(), void onCancel()) : super(onListen, onCancel);
 bool get _hasPending => _pending != null && !_pending.isEmpty;
 void _addPendingEvent(_DelayedEvent event) {
if (_pending == null) {
_pending = new _StreamImplEvents();
}
 _pending.add(event);
}
 void add(T data) {
if (!isClosed && _isFiring) {
_addPendingEvent(new _DelayedData<T>(data));
 return;}
 super.add(data);
 while (_hasPending) {
_pending.handleNext(this);
}
}
 void addError(Object error, [StackTrace stackTrace]) {
if (!isClosed && _isFiring) {
_addPendingEvent(new _DelayedError(error, stackTrace));
 return;}
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
 assert (!_hasPending); return result;
}
 void _callOnCancel() {
if (_hasPending) {
_pending.clear();
 _pending = null;
}
 super._callOnCancel();
}
}
 class _DoneSubscription<T> implements StreamSubscription<T> {int _pauseCount = 0;
 void onData(void handleData(T data)) {
}
 void onError(Function handleError) {
}
 void onDone(void handleDone()) {
}
 void pause([Future resumeSignal]) {
if (resumeSignal != null) resumeSignal.then(_resume);
 _pauseCount++;
}
 void resume() {
_resume(null);
}
 void _resume(_) {
if (_pauseCount > 0) _pauseCount--;
}
 Future cancel() {
return new _Future.immediate(null);
}
 bool get isPaused => _pauseCount > 0;
 Future asFuture([Object value]) => new _Future();
}
 typedef void __CastType3<T>(_BufferingStreamSubscription<T> __u4);
 typedef dynamic __CastType5<T>(_BroadcastSubscription<T> __u6);
