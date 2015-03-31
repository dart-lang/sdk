part of dart.async;
 typedef dynamic _FutureOnValue<T>(T value);
 typedef bool _FutureErrorTest(var error);
 typedef _FutureAction();
 abstract class _Completer<T> implements Completer<T> {final _Future<T> future = new _Future<T>();
 void complete([value]);
 void completeError(Object error, [StackTrace stackTrace]) {
  error = _nonNullError(error);
   if (!future._mayComplete) throw new StateError("Future already completed");
   AsyncError replacement = Zone.current.errorCallback(error, stackTrace);
   if (replacement != null) {
    error = _nonNullError(replacement.error);
     stackTrace = replacement.stackTrace;
    }
   _completeError(error, stackTrace);
  }
 void _completeError(Object error, StackTrace stackTrace);
 bool get isCompleted => !future._mayComplete;
}
 class _AsyncCompleter<T> extends _Completer<T> {void complete([value]) {
if (!future._mayComplete) throw new StateError("Future already completed");
 future._asyncComplete(value);
}
 void _completeError(Object error, StackTrace stackTrace) {
future._asyncCompleteError(error, stackTrace);
}
}
 class _SyncCompleter<T> extends _Completer<T> {void complete([value]) {
if (!future._mayComplete) throw new StateError("Future already completed");
 future._complete(value);
}
 void _completeError(Object error, StackTrace stackTrace) {
future._completeError(error, stackTrace);
}
}
 class _FutureListener {static const int MASK_VALUE = 1;
 static const int MASK_ERROR = 2;
 static const int MASK_TEST_ERROR = 4;
 static const int MASK_WHENCOMPLETE = 8;
 static const int STATE_CHAIN = 0;
 static const int STATE_THEN = MASK_VALUE;
 static const int STATE_THEN_ONERROR = MASK_VALUE | MASK_ERROR;
 static const int STATE_CATCHERROR = MASK_ERROR;
 static const int STATE_CATCHERROR_TEST = MASK_ERROR | MASK_TEST_ERROR;
 static const int STATE_WHENCOMPLETE = MASK_WHENCOMPLETE;
 _FutureListener _nextListener = null;
 final _Future result;
 final int state;
 final Function callback;
 final Function errorCallback;
 _FutureListener.then(this.result, _FutureOnValue onValue, Function errorCallback) : callback = onValue, errorCallback = errorCallback, state = (errorCallback == null) ? STATE_THEN : STATE_THEN_ONERROR;
 _FutureListener.catchError(this.result, this.errorCallback, _FutureErrorTest test) : callback = test, state = (test == null) ? STATE_CATCHERROR : STATE_CATCHERROR_TEST;
 _FutureListener.whenComplete(this.result, _FutureAction onComplete) : callback = onComplete, errorCallback = null, state = STATE_WHENCOMPLETE;
 _FutureListener.chain(this.result) : callback = null, errorCallback = null, state = STATE_CHAIN;
 Zone get _zone => result._zone;
 bool get handlesValue => (state & MASK_VALUE != 0);
 bool get handlesError => (state & MASK_ERROR != 0);
 bool get hasErrorTest => (state == STATE_CATCHERROR_TEST);
 bool get handlesComplete => (state == STATE_WHENCOMPLETE);
 _FutureOnValue get _onValue {
assert (handlesValue); return DEVC$RT.cast(callback, Function, __t11, "ImplicitCast", """line 112, column 12 of dart:async/future_impl.dart: """, callback is __t11, true);
}
 Function get _onError => errorCallback;
 _FutureErrorTest get _errorTest {
assert (hasErrorTest); return DEVC$RT.cast(callback, Function, __t13, "CompositeCast", """line 117, column 12 of dart:async/future_impl.dart: """, callback is __t13, false);
}
 _FutureAction get _whenCompleteAction {
assert (handlesComplete); return DEVC$RT.cast(callback, Function, __t15, "ImplicitCast", """line 121, column 12 of dart:async/future_impl.dart: """, callback is __t15, true);
}
}
 class _Future<T> implements Future<T> {static const int _INCOMPLETE = 0;
 static const int _PENDING_COMPLETE = 1;
 static const int _CHAINED = 2;
 static const int _VALUE = 4;
 static const int _ERROR = 8;
 int _state = _INCOMPLETE;
 final Zone _zone = Zone.current;
 var _resultOrListeners;
 _Future();
 _Future.immediate(value) {
_asyncComplete(value);
}
 _Future.immediateError(var error, [StackTrace stackTrace]) {
_asyncCompleteError(error, stackTrace);
}
 bool get _mayComplete => _state == _INCOMPLETE;
 bool get _isChained => _state == _CHAINED;
 bool get _isComplete => _state >= _VALUE;
 bool get _hasValue => _state == _VALUE;
 bool get _hasError => _state == _ERROR;
 set _isChained(bool value) {
if (value) {
assert (!_isComplete); _state = _CHAINED;
}
 else {
assert (_isChained); _state = _INCOMPLETE;
}
}
 Future then(f(T value), {
Function onError}
) {
_Future result = new _Future();
 if (!identical(result._zone, _ROOT_ZONE)) {
f = ((__x19) => DEVC$RT.wrap((dynamic f(dynamic __u16)) {
dynamic c(dynamic x0) => f(x0);
 return f == null ? null : c;
}
, __x19, __t11, DEVC$RT.type((__t17<T> _) {
}
), "Wrap", """line 208, column 11 of dart:async/future_impl.dart: """, __x19 is __t17<T>))(result._zone.registerUnaryCallback(f));
 if (onError != null) {
onError = _registerErrorHandler(onError, result._zone);
}
}
 _addListener(new _FutureListener.then(result, f, onError));
 return result;
}
 Future catchError(Function onError, {
bool test(error)}
) {
_Future result = new _Future();
 if (!identical(result._zone, _ROOT_ZONE)) {
onError = _registerErrorHandler(onError, result._zone);
 if (test != null) test = ((__x22) => DEVC$RT.wrap((dynamic f(dynamic __u21)) {
dynamic c(dynamic x0) => ((__x20) => DEVC$RT.cast(__x20, dynamic, bool, "CastResult", """line 221, column 32 of dart:async/future_impl.dart: """, __x20 is bool, true))(f(x0));
 return f == null ? null : c;
}
, __x22, __t11, __t13, "Wrap", """line 221, column 32 of dart:async/future_impl.dart: """, __x22 is __t13))(result._zone.registerUnaryCallback(test));
}
 _addListener(new _FutureListener.catchError(result, onError, test));
 return result;
}
 Future<T> whenComplete(action()) {
_Future result = new _Future<T>();
 if (!identical(result._zone, _ROOT_ZONE)) {
action = result._zone.registerCallback(action);
}
 _addListener(new _FutureListener.whenComplete(result, action));
 return DEVC$RT.cast(result, DEVC$RT.type((_Future<dynamic> _) {
}
), DEVC$RT.type((Future<T> _) {
}
), "CompositeCast", """line 233, column 12 of dart:async/future_impl.dart: """, result is Future<T>, false);
}
 Stream<T> asStream() => new Stream<T>.fromFuture(this);
 void _markPendingCompletion() {
if (!_mayComplete) throw new StateError("Future already completed");
 _state = _PENDING_COMPLETE;
}
 T get _value {
assert (_isComplete && _hasValue); return DEVC$RT.cast(_resultOrListeners, dynamic, T, "CompositeCast", """line 245, column 12 of dart:async/future_impl.dart: """, _resultOrListeners is T, false);
}
 AsyncError get _error {
assert (_isComplete && _hasError); return DEVC$RT.cast(_resultOrListeners, dynamic, AsyncError, "DynamicCast", """line 250, column 12 of dart:async/future_impl.dart: """, _resultOrListeners is AsyncError, true);
}
 void _setValue(T value) {
assert (!_isComplete); _state = _VALUE;
 _resultOrListeners = value;
}
 void _setErrorObject(AsyncError error) {
assert (!_isComplete); _state = _ERROR;
 _resultOrListeners = error;
}
 void _setError(Object error, StackTrace stackTrace) {
_setErrorObject(new AsyncError(error, stackTrace));
}
 void _addListener(_FutureListener listener) {
assert (listener._nextListener == null); if (_isComplete) {
_zone.scheduleMicrotask(() {
_propagateToListeners(this, listener);
}
);
}
 else {
listener._nextListener = DEVC$RT.cast(_resultOrListeners, dynamic, _FutureListener, "DynamicCast", """line 277, column 32 of dart:async/future_impl.dart: """, _resultOrListeners is _FutureListener, true);
 _resultOrListeners = listener;
}
}
 _FutureListener _removeListeners() {
assert (!_isComplete); _FutureListener current = DEVC$RT.cast(_resultOrListeners, dynamic, _FutureListener, "DynamicCast", """line 286, column 31 of dart:async/future_impl.dart: """, _resultOrListeners is _FutureListener, true);
 _resultOrListeners = null;
 _FutureListener prev = null;
 while (current != null) {
_FutureListener next = current._nextListener;
 current._nextListener = prev;
 prev = current;
 current = next;
}
 return prev;
}
 static void _chainForeignFuture(Future source, _Future target) {
assert (!target._isComplete); assert (source is! _Future); target._isChained = true;
 source.then((value) {
assert (target._isChained); target._completeWithValue(value);
}
, onError: (error, [stackTrace]) {
assert (target._isChained); target._completeError(error, DEVC$RT.cast(stackTrace, dynamic, StackTrace, "DynamicCast", """line 317, column 38 of dart:async/future_impl.dart: """, stackTrace is StackTrace, true));
}
);
}
 static void _chainCoreFuture(_Future source, _Future target) {
assert (!target._isComplete); assert (source is _Future); target._isChained = true;
 _FutureListener listener = new _FutureListener.chain(target);
 if (source._isComplete) {
_propagateToListeners(source, listener);
}
 else {
source._addListener(listener);
}
}
 void _complete(value) {
assert (!_isComplete); if (value is Future) {
if (value is _Future) {
_chainCoreFuture(DEVC$RT.cast(value, dynamic, DEVC$RT.type((_Future<dynamic> _) {
}
), "DynamicCast", """line 341, column 26 of dart:async/future_impl.dart: """, value is _Future<dynamic>, true), this);
}
 else {
_chainForeignFuture(DEVC$RT.cast(value, dynamic, DEVC$RT.type((Future<dynamic> _) {
}
), "DynamicCast", """line 343, column 29 of dart:async/future_impl.dart: """, value is Future<dynamic>, true), this);
}
}
 else {
_FutureListener listeners = _removeListeners();
 _setValue(DEVC$RT.cast(value, dynamic, T, "CompositeCast", """line 347, column 17 of dart:async/future_impl.dart: """, value is T, false));
 _propagateToListeners(this, listeners);
}
}
 void _completeWithValue(value) {
assert (!_isComplete); assert (value is! Future); _FutureListener listeners = _removeListeners();
 _setValue(DEVC$RT.cast(value, dynamic, T, "CompositeCast", """line 357, column 15 of dart:async/future_impl.dart: """, value is T, false));
 _propagateToListeners(this, listeners);
}
 void _completeError(error, [StackTrace stackTrace]) {
assert (!_isComplete); _FutureListener listeners = _removeListeners();
 _setError(error, stackTrace);
 _propagateToListeners(this, listeners);
}
 void _asyncComplete(value) {
assert (!_isComplete); if (value == null) {
}
 else if (value is Future) {
Future<T> typedFuture = DEVC$RT.cast(value, dynamic, DEVC$RT.type((Future<T> _) {
}
), "CompositeCast", """line 386, column 31 of dart:async/future_impl.dart: """, value is Future<T>, false);
 if (typedFuture is _Future) {
_Future<T> coreFuture = DEVC$RT.cast(typedFuture, DEVC$RT.type((Future<T> _) {
}
), DEVC$RT.type((_Future<T> _) {
}
), "CompositeCast", """line 388, column 33 of dart:async/future_impl.dart: """, typedFuture is _Future<T>, false);
 if (coreFuture._isComplete && coreFuture._hasError) {
_markPendingCompletion();
 _zone.scheduleMicrotask(() {
  _chainCoreFuture(coreFuture, this);
  }
);
}
 else {
_chainCoreFuture(coreFuture, this);
}
}
 else {
_chainForeignFuture(typedFuture, this);
}
 return;}
 else {
T typedValue = DEVC$RT.cast(value, dynamic, T, "CompositeCast", """line 407, column 22 of dart:async/future_impl.dart: """, value is T, false);
}
 _markPendingCompletion();
 _zone.scheduleMicrotask(() {
_completeWithValue(value);
}
);
}
 void _asyncCompleteError(error, StackTrace stackTrace) {
assert (!_isComplete); _markPendingCompletion();
 _zone.scheduleMicrotask(() {
_completeError(error, stackTrace);
}
);
}
 static void _propagateToListeners(_Future source, _FutureListener listeners) {
while (true) {
assert (source._isComplete); bool hasError = source._hasError;
 if (listeners == null) {
if (hasError) {
AsyncError asyncError = source._error;
 source._zone.handleUncaughtError(asyncError.error, asyncError.stackTrace);
}
 return;}
 while (listeners._nextListener != null) {
_FutureListener listener = listeners;
 listeners = listener._nextListener;
 listener._nextListener = null;
 _propagateToListeners(source, listener);
}
 _FutureListener listener = listeners;
 bool listenerHasValue = true;
 final sourceValue = hasError ? null : source._value;
 var listenerValueOrError = sourceValue;
 bool isPropagationAborted = false;
 if (hasError || (listener.handlesValue || listener.handlesComplete)) {
Zone zone = listener._zone;
 if (hasError && !source._zone.inSameErrorZone(zone)) {
AsyncError asyncError = source._error;
 source._zone.handleUncaughtError(asyncError.error, asyncError.stackTrace);
 return;}
 Zone oldZone;
 if (!identical(Zone.current, zone)) {
oldZone = Zone._enter(zone);
}
 bool handleValueCallback() {
try {
  listenerValueOrError = zone.runUnary(listener._onValue, sourceValue);
   return true;
  }
 catch (e, s) {
  listenerValueOrError = new AsyncError(e, s);
   return false;
  }
}
 void handleError() {
AsyncError asyncError = source._error;
 bool matchesTest = true;
 if (listener.hasErrorTest) {
  _FutureErrorTest test = listener._errorTest;
   try {
    matchesTest = ((__x23) => DEVC$RT.cast(__x23, dynamic, bool, "DynamicCast", """line 499, column 29 of dart:async/future_impl.dart: """, __x23 is bool, true))(zone.runUnary(test, asyncError.error));
    }
   catch (e, s) {
    listenerValueOrError = identical(asyncError.error, e) ? asyncError : new AsyncError(e, s);
     listenerHasValue = false;
     return;}
  }
 Function errorCallback = listener._onError;
 if (matchesTest && errorCallback != null) {
  try {
    if (errorCallback is ZoneBinaryCallback) {
      listenerValueOrError = zone.runBinary(errorCallback, asyncError.error, asyncError.stackTrace);
      }
     else {
      listenerValueOrError = zone.runUnary(DEVC$RT.cast(errorCallback, Function, __t11, "ImplicitCast", """line 515, column 54 of dart:async/future_impl.dart: """, errorCallback is __t11, true), asyncError.error);
      }
    }
   catch (e, s) {
    listenerValueOrError = identical(asyncError.error, e) ? asyncError : new AsyncError(e, s);
     listenerHasValue = false;
     return;}
   listenerHasValue = true;
  }
 else {
  listenerValueOrError = asyncError;
   listenerHasValue = false;
  }
}
 void handleWhenCompleteCallback() {
var completeResult;
 try {
  completeResult = zone.run(listener._whenCompleteAction);
  }
 catch (e, s) {
  if (hasError && identical(source._error.error, e)) {
    listenerValueOrError = source._error;
    }
   else {
    listenerValueOrError = new AsyncError(e, s);
    }
   listenerHasValue = false;
   return;}
 if (completeResult is Future) {
  _Future result = listener.result;
   result._isChained = true;
   isPropagationAborted = true;
   completeResult.then((ignored) {
    _propagateToListeners(source, new _FutureListener.chain(result));
    }
  , onError: (error, [stackTrace]) {
    if (completeResult is! _Future) {
      completeResult = new _Future();
       completeResult._setError(error, stackTrace);
      }
     _propagateToListeners(DEVC$RT.cast(completeResult, dynamic, DEVC$RT.type((_Future<dynamic> _) {
      }
    ), "DynamicCast", """line 559, column 37 of dart:async/future_impl.dart: """, completeResult is _Future<dynamic>, true), new _FutureListener.chain(result));
    }
  );
  }
}
 if (!hasError) {
if (listener.handlesValue) {
  listenerHasValue = handleValueCallback();
  }
}
 else {
handleError();
}
 if (listener.handlesComplete) {
handleWhenCompleteCallback();
}
 if (oldZone != null) Zone._leave(oldZone);
 if (isPropagationAborted) return; if (listenerHasValue && !identical(sourceValue, listenerValueOrError) && listenerValueOrError is Future) {
Future chainSource = DEVC$RT.cast(listenerValueOrError, dynamic, DEVC$RT.type((Future<dynamic> _) {
  }
), "DynamicCast", """line 585, column 32 of dart:async/future_impl.dart: """, listenerValueOrError is Future<dynamic>, true);
 _Future result = listener.result;
 if (chainSource is _Future) {
  if (chainSource._isComplete) {
    result._isChained = true;
     source = chainSource;
     listeners = new _FutureListener.chain(result);
     continue;
    }
   else {
    _chainCoreFuture(chainSource, result);
    }
  }
 else {
  _chainForeignFuture(chainSource, result);
  }
 return;}
}
 _Future result = listener.result;
 listeners = result._removeListeners();
 if (listenerHasValue) {
result._setValue(listenerValueOrError);
}
 else {
AsyncError asyncError = DEVC$RT.cast(listenerValueOrError, dynamic, AsyncError, "DynamicCast", """line 610, column 33 of dart:async/future_impl.dart: """, listenerValueOrError is AsyncError, true);
 result._setErrorObject(asyncError);
}
 source = result;
}
}
 Future timeout(Duration timeLimit, {
onTimeout()}
) {
if (_isComplete) return new _Future.immediate(this);
 _Future result = new _Future();
 Timer timer;
 if (onTimeout == null) {
timer = new Timer(timeLimit, () {
result._completeError(new TimeoutException("Future not completed", timeLimit));
}
);
}
 else {
Zone zone = Zone.current;
 onTimeout = zone.registerCallback(onTimeout);
 timer = new Timer(timeLimit, () {
try {
result._complete(zone.run(onTimeout));
}
 catch (e, s) {
result._completeError(e, s);
}
}
);
}
 this.then((T v) {
if (timer.isActive) {
timer.cancel();
 result._completeWithValue(v);
}
}
, onError: (e, s) {
if (timer.isActive) {
timer.cancel();
 result._completeError(e, DEVC$RT.cast(s, dynamic, StackTrace, "DynamicCast", """line 646, column 34 of dart:async/future_impl.dart: """, s is StackTrace, true));
}
}
);
 return result;
}
}
 typedef dynamic __t11(dynamic __u12);
 typedef bool __t13(dynamic __u14);
 typedef dynamic __t15();
 typedef dynamic __t17<T>(T __u18);
