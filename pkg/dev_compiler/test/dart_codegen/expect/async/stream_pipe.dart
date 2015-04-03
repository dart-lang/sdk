part of dart.async;
 _runUserCode(userCode(), onSuccess(value), onError(error, StackTrace stackTrace)) {
  try {
    onSuccess(userCode());
    }
   catch (e, s) {
    AsyncError replacement = Zone.current.errorCallback(e, s);
     if (replacement == null) {
      onError(e, s);
      }
     else {
      var error = _nonNullError(replacement.error);
       var stackTrace = replacement.stackTrace;
       onError(error, stackTrace);
      }
    }
  }
 void _cancelAndError(StreamSubscription subscription, _Future future, error, StackTrace stackTrace) {
  var cancelFuture = subscription.cancel();
   if (cancelFuture is Future) {
    cancelFuture.whenComplete(() => future._completeError(error, stackTrace));
    }
   else {
    future._completeError(error, stackTrace);
    }
  }
 void _cancelAndErrorWithReplacement(StreamSubscription subscription, _Future future, error, StackTrace stackTrace) {
  AsyncError replacement = Zone.current.errorCallback(error, stackTrace);
   if (replacement != null) {
    error = _nonNullError(replacement.error);
     stackTrace = replacement.stackTrace;
    }
   _cancelAndError(subscription, future, error, stackTrace);
  }
 _cancelAndErrorClosure(StreamSubscription subscription, _Future future) => ((error, StackTrace stackTrace) => _cancelAndError(subscription, future, error, stackTrace));
 void _cancelAndValue(StreamSubscription subscription, _Future future, value) {
  var cancelFuture = subscription.cancel();
   if (cancelFuture is Future) {
    cancelFuture.whenComplete(() => future._complete(value));
    }
   else {
    future._complete(value);
    }
  }
 abstract class _ForwardingStream<S, T> extends Stream<T> {final Stream<S> _source;
 _ForwardingStream(this._source);
 bool get isBroadcast => _source.isBroadcast;
 StreamSubscription<T> listen(void onData(T value), {
  Function onError, void onDone(), bool cancelOnError}
) {
  cancelOnError = identical(true, cancelOnError);
   return _createSubscription(onData, onError, onDone, cancelOnError);
  }
 StreamSubscription<T> _createSubscription(void onData(T data), Function onError, void onDone(), bool cancelOnError) {
  return new _ForwardingStreamSubscription<S, T>(this, onData, onError, onDone, cancelOnError);
  }
 void _handleData(S data, _EventSink<T> sink) {
  var outputData = data;
   sink._add(outputData);
  }
 void _handleError(error, StackTrace stackTrace, _EventSink<T> sink) {
  sink._addError(error, stackTrace);
  }
 void _handleDone(_EventSink<T> sink) {
  sink._close();
  }
}
 class _ForwardingStreamSubscription<S, T> extends _BufferingStreamSubscription<T> {final _ForwardingStream<S, T> _stream;
 StreamSubscription<S> _subscription;
 _ForwardingStreamSubscription(this._stream, void onData(T data), Function onError, void onDone(), bool cancelOnError) : super(onData, onError, onDone, cancelOnError) {
_subscription = _stream._source.listen(_handleData, onError: _handleError, onDone: _handleDone);
}
 void _add(T data) {
if (_isClosed) return; super._add(data);
}
 void _addError(Object error, StackTrace stackTrace) {
if (_isClosed) return; super._addError(error, stackTrace);
}
 void _onPause() {
if (_subscription == null) return; _subscription.pause();
}
 void _onResume() {
if (_subscription == null) return; _subscription.resume();
}
 Future _onCancel() {
if (_subscription != null) {
  StreamSubscription subscription = _subscription;
   _subscription = null;
   subscription.cancel();
  }
 return null;
}
 void _handleData(S data) {
_stream._handleData(data, this);
}
 void _handleError(error, StackTrace stackTrace) {
_stream._handleError(error, stackTrace, this);
}
 void _handleDone() {
_stream._handleDone(this);
}
}
 typedef bool _Predicate<T>(T value);
 void _addErrorWithReplacement(_EventSink sink, error, stackTrace) {
AsyncError replacement = Zone.current.errorCallback(error, DEVC$RT.cast(stackTrace, dynamic, StackTrace, "DynamicCast", """line 191, column 62 of dart:async/stream_pipe.dart: """, stackTrace is StackTrace, true));
 if (replacement != null) {
error = _nonNullError(replacement.error);
 stackTrace = replacement.stackTrace;
}
 sink._addError(error, DEVC$RT.cast(stackTrace, dynamic, StackTrace, "DynamicCast", """line 196, column 25 of dart:async/stream_pipe.dart: """, stackTrace is StackTrace, true));
}
 class _WhereStream<T> extends _ForwardingStream<T, T> {final _Predicate<T> _test;
 _WhereStream(Stream<T> source, bool test(T value)) : _test = test, super(source);
 void _handleData(T inputEvent, _EventSink<T> sink) {
bool satisfies;
 try {
satisfies = _test(inputEvent);
}
 catch (e, s) {
_addErrorWithReplacement(sink, e, s);
 return;}
 if (satisfies) {
sink._add(inputEvent);
}
}
}
 typedef T _Transformation<S, T>(S value);
 class _MapStream<S, T> extends _ForwardingStream<S, T> {final _Transformation _transform;
 _MapStream(Stream<S> source, T transform(S event)) : this._transform = transform, super(source);
 void _handleData(S inputEvent, _EventSink<T> sink) {
T outputEvent;
 try {
outputEvent = ((__x69) => DEVC$RT.cast(__x69, dynamic, T, "CompositeCast", """line 235, column 21 of dart:async/stream_pipe.dart: """, __x69 is T, false))(_transform(inputEvent));
}
 catch (e, s) {
_addErrorWithReplacement(sink, e, s);
 return;}
 sink._add(outputEvent);
}
}
 class _ExpandStream<S, T> extends _ForwardingStream<S, T> {final _Transformation<S, Iterable<T>> _expand;
 _ExpandStream(Stream<S> source, Iterable<T> expand(S event)) : this._expand = expand, super(source);
 void _handleData(S inputEvent, _EventSink<T> sink) {
try {
for (T value in _expand(inputEvent)) {
sink._add(value);
}
}
 catch (e, s) {
_addErrorWithReplacement(sink, e, s);
}
}
}
 typedef bool _ErrorTest(error);
 class _HandleErrorStream<T> extends _ForwardingStream<T, T> {final Function _transform;
 final _ErrorTest _test;
 _HandleErrorStream(Stream<T> source, Function onError, bool test(error)) : this._transform = onError, this._test = test, super(source);
 void _handleError(Object error, StackTrace stackTrace, _EventSink<T> sink) {
bool matches = true;
 if (_test != null) {
try {
matches = _test(error);
}
 catch (e, s) {
_addErrorWithReplacement(sink, e, s);
 return;}
}
 if (matches) {
try {
_invokeErrorHandler(_transform, error, stackTrace);
}
 catch (e, s) {
if (identical(e, error)) {
sink._addError(error, stackTrace);
}
 else {
_addErrorWithReplacement(sink, e, s);
}
 return;}
}
 else {
sink._addError(error, stackTrace);
}
}
}
 class _TakeStream<T> extends _ForwardingStream<T, T> {int _remaining;
 _TakeStream(Stream<T> source, int count) : this._remaining = count, super(source) {
if (count is! int) throw new ArgumentError(count);
}
 void _handleData(T inputEvent, _EventSink<T> sink) {
if (_remaining > 0) {
sink._add(inputEvent);
 _remaining -= 1;
 if (_remaining == 0) {
sink._close();
}
}
}
}
 class _TakeWhileStream<T> extends _ForwardingStream<T, T> {final _Predicate<T> _test;
 _TakeWhileStream(Stream<T> source, bool test(T value)) : this._test = test, super(source);
 void _handleData(T inputEvent, _EventSink<T> sink) {
bool satisfies;
 try {
satisfies = _test(inputEvent);
}
 catch (e, s) {
_addErrorWithReplacement(sink, e, s);
 sink._close();
 return;}
 if (satisfies) {
sink._add(inputEvent);
}
 else {
sink._close();
}
}
}
 class _SkipStream<T> extends _ForwardingStream<T, T> {int _remaining;
 _SkipStream(Stream<T> source, int count) : this._remaining = count, super(source) {
if (count is! int || count < 0) throw new ArgumentError(count);
}
 void _handleData(T inputEvent, _EventSink<T> sink) {
if (_remaining > 0) {
_remaining--;
 return;}
 sink._add(inputEvent);
}
}
 class _SkipWhileStream<T> extends _ForwardingStream<T, T> {final _Predicate<T> _test;
 bool _hasFailed = false;
 _SkipWhileStream(Stream<T> source, bool test(T value)) : this._test = test, super(source);
 void _handleData(T inputEvent, _EventSink<T> sink) {
if (_hasFailed) {
sink._add(inputEvent);
 return;}
 bool satisfies;
 try {
satisfies = _test(inputEvent);
}
 catch (e, s) {
_addErrorWithReplacement(sink, e, s);
 _hasFailed = true;
 return;}
 if (!satisfies) {
_hasFailed = true;
 sink._add(inputEvent);
}
}
}
 typedef bool _Equality<T>(T a, T b);
 class _DistinctStream<T> extends _ForwardingStream<T, T> {static var _SENTINEL = new Object();
 _Equality<T> _equals;
 var _previous = _SENTINEL;
 _DistinctStream(Stream<T> source, bool equals(T a, T b)) : _equals = equals, super(source);
 void _handleData(T inputEvent, _EventSink<T> sink) {
if (identical(_previous, _SENTINEL)) {
_previous = inputEvent;
 return sink._add(inputEvent);
}
 else {
bool isEqual;
 try {
if (_equals == null) {
isEqual = (_previous == inputEvent);
}
 else {
isEqual = _equals(DEVC$RT.cast(_previous, Object, T, "CompositeCast", """line 426, column 29 of dart:async/stream_pipe.dart: """, _previous is T, false), inputEvent);
}
}
 catch (e, s) {
_addErrorWithReplacement(sink, e, s);
 return null;
}
 if (!isEqual) {
sink._add(inputEvent);
 _previous = inputEvent;
}
}
}
}
