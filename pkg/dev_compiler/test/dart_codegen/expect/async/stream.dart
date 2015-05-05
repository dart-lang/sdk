part of dart.async;
 abstract class Stream<T> {Stream();
 factory Stream.fromFuture(Future<T> future) {
  _StreamController<T> controller = ((__x19) => DEVC$RT.cast(__x19, DEVC$RT.type((StreamController<T> _) {
    }
  ), DEVC$RT.type((_StreamController<T> _) {
    }
  ), "CastUser", """line 88, column 9 of dart:async/stream.dart: """, __x19 is _StreamController<T>, false))(new StreamController<T>(sync: true));
   future.then((value) {
    controller._add(DEVC$RT.cast(value, dynamic, T, "CompositeCast", """line 90, column 25 of dart:async/stream.dart: """, value is T, false));
     controller._closeUnchecked();
    }
  , onError: (error, stackTrace) {
    controller._addError(error, DEVC$RT.cast(stackTrace, dynamic, StackTrace, "DynamicCast", """line 94, column 37 of dart:async/stream.dart: """, stackTrace is StackTrace, true));
     controller._closeUnchecked();
    }
  );
   return controller.stream;
  }
 factory Stream.fromIterable(Iterable<T> data) {
  return new _GeneratedStreamImpl<T>(() => new _IterablePendingEvents<T>(data));
  }
 factory Stream.periodic(Duration period, [T computation(int computationCount)]) {
  if (computation == null) computation = ((i) => null);
   Timer timer;
   int computationCount = 0;
   StreamController<T> controller;
   Stopwatch watch = new Stopwatch();
   void sendEvent() {
    watch.reset();
     T data = computation(computationCount++);
     controller.add(data);
    }
   void startPeriodicTimer() {
    assert (timer == null); timer = new Timer.periodic(period, (Timer timer) {
      sendEvent();
      }
    );
    }
   controller = new StreamController<T>(sync: true, onListen: () {
    watch.start();
     startPeriodicTimer();
    }
  , onPause: () {
    timer.cancel();
     timer = null;
     watch.stop();
    }
  , onResume: () {
    assert (timer == null); Duration elapsed = watch.elapsed;
     watch.start();
     timer = new Timer(period - elapsed, () {
      timer = null;
       startPeriodicTimer();
       sendEvent();
      }
    );
    }
  , onCancel: () {
    if (timer != null) timer.cancel();
     timer = null;
    }
  );
   return controller.stream;
  }
 factory Stream.eventTransformed(Stream source, EventSink mapSink(EventSink<T> sink)) {
  return new _BoundSinkStream<dynamic, T>(source, DEVC$RT.cast(mapSink, DEVC$RT.type((__CastType20<T> _) {
    }
  ), DEVC$RT.type((_SinkMapper<dynamic, dynamic> _) {
    }
  ), "CompositeCast", """line 217, column 41 of dart:async/stream.dart: """, mapSink is _SinkMapper<dynamic, dynamic>, false));
  }
 bool get isBroadcast => false;
 Stream<T> asBroadcastStream({
  void onListen(StreamSubscription<T> subscription), void onCancel(StreamSubscription<T> subscription)}
) {
  return new _AsBroadcastStream<T>(this, DEVC$RT.cast(onListen, DEVC$RT.type((__CastType24<T> _) {
    }
  ), __CastType22, "CompositeCast", """line 249, column 44 of dart:async/stream.dart: """, onListen is __CastType22, false), DEVC$RT.cast(onCancel, DEVC$RT.type((__CastType24<T> _) {
    }
  ), __CastType22, "CompositeCast", """line 249, column 54 of dart:async/stream.dart: """, onCancel is __CastType22, false));
  }
 StreamSubscription<T> listen(void onData(T event), {
  Function onError, void onDone(), bool cancelOnError}
);
 Stream<T> where(bool test(T event)) {
  return new _WhereStream<T>(this, test);
  }
 Stream map(convert(T event)) {
  return new _MapStream<T, dynamic>(this, convert);
  }
 Stream asyncMap(convert(T event)) {
  StreamController controller;
   StreamSubscription subscription;
   void onListen() {
    final add = controller.add;
     assert (controller is _StreamController || controller is _BroadcastStreamController); final eventSink = controller;
     final addError = eventSink._addError;
     subscription = this.listen((T event) {
      var newValue;
       try {
        newValue = convert(event);
        }
       catch (e, s) {
        controller.addError(e, s);
         return;}
       if (newValue is Future) {
        subscription.pause();
         newValue.then(add, onError: addError).whenComplete(subscription.resume);
        }
       else {
        controller.add(newValue);
        }
      }
    , onError: DEVC$RT.cast(addError, dynamic, Function, "DynamicCast", """line 339, column 20 of dart:async/stream.dart: """, addError is Function, true), onDone: controller.close);
    }
   if (this.isBroadcast) {
    controller = new StreamController.broadcast(onListen: onListen, onCancel: () {
      subscription.cancel();
      }
    , sync: true);
    }
   else {
    controller = new StreamController(onListen: onListen, onPause: () {
      subscription.pause();
      }
    , onResume: () {
      subscription.resume();
      }
    , onCancel: () {
      subscription.cancel();
      }
    , sync: true);
    }
   return controller.stream;
  }
 Stream asyncExpand(Stream convert(T event)) {
  StreamController controller;
   StreamSubscription subscription;
   void onListen() {
    assert (controller is _StreamController || controller is _BroadcastStreamController); final eventSink = controller;
     subscription = this.listen((T event) {
      Stream newStream;
       try {
        newStream = convert(event);
        }
       catch (e, s) {
        controller.addError(e, s);
         return;}
       if (newStream != null) {
        subscription.pause();
         controller.addStream(newStream).whenComplete(subscription.resume);
        }
      }
    , onError: DEVC$RT.cast(eventSink._addError, dynamic, Function, "DynamicCast", """line 396, column 20 of dart:async/stream.dart: """, eventSink._addError is Function, true), onDone: controller.close);
    }
   if (this.isBroadcast) {
    controller = new StreamController.broadcast(onListen: onListen, onCancel: () {
      subscription.cancel();
      }
    , sync: true);
    }
   else {
    controller = new StreamController(onListen: onListen, onPause: () {
      subscription.pause();
      }
    , onResume: () {
      subscription.resume();
      }
    , onCancel: () {
      subscription.cancel();
      }
    , sync: true);
    }
   return controller.stream;
  }
 Stream<T> handleError(Function onError, {
  bool test(error)}
) {
  return new _HandleErrorStream<T>(this, onError, test);
  }
 Stream expand(Iterable convert(T value)) {
  return new _ExpandStream<T, dynamic>(this, convert);
  }
 Future pipe(StreamConsumer<T> streamConsumer) {
  return streamConsumer.addStream(this).then((_) => streamConsumer.close());
  }
 Stream transform(StreamTransformer<T, dynamic> streamTransformer) {
  return streamTransformer.bind(this);
  }
 Future<T> reduce(T combine(T previous, T element)) {
  _Future<T> result = new _Future<T>();
   bool seenFirst = false;
   T value;
   StreamSubscription subscription;
   subscription = this.listen((T element) {
    if (seenFirst) {
      _runUserCode(() => combine(value, element), (T newValue) {
        value = newValue;
        }
      , ((__x29) => DEVC$RT.cast(__x29, dynamic, __CastType26, "CompositeCast", """line 502, column 24 of dart:async/stream.dart: """, __x29 is __CastType26, false))(_cancelAndErrorClosure(subscription, result)));
      }
     else {
      value = element;
       seenFirst = true;
      }
    }
  , onError: result._completeError, onDone: () {
    if (!seenFirst) {
      try {
        throw IterableElementError.noElement();
        }
       catch (e, s) {
        _completeWithErrorCallback(result, e, s);
        }
      }
     else {
      result._complete(value);
      }
    }
  , cancelOnError: true);
   return result;
  }
 Future fold(var initialValue, combine(var previous, T element)) {
  _Future result = new _Future();
   var value = initialValue;
   StreamSubscription subscription;
   subscription = this.listen((T element) {
    _runUserCode(() => combine(value, element), (newValue) {
      value = newValue;
      }
    , ((__x30) => DEVC$RT.cast(__x30, dynamic, __CastType26, "CompositeCast", """line 535, column 11 of dart:async/stream.dart: """, __x30 is __CastType26, false))(_cancelAndErrorClosure(subscription, result)));
    }
  , onError: (e, st) {
    result._completeError(e, DEVC$RT.cast(st, dynamic, StackTrace, "DynamicCast", """line 539, column 34 of dart:async/stream.dart: """, st is StackTrace, true));
    }
  , onDone: () {
    result._complete(value);
    }
  , cancelOnError: true);
   return result;
  }
 Future<String> join([String separator = ""]) {
  _Future<String> result = new _Future<String>();
   StringBuffer buffer = new StringBuffer();
   StreamSubscription subscription;
   bool first = true;
   subscription = this.listen((T element) {
    if (!first) {
      buffer.write(separator);
      }
     first = false;
     try {
      buffer.write(element);
      }
     catch (e, s) {
      _cancelAndErrorWithReplacement(subscription, result, e, s);
      }
    }
  , onError: (e) {
    result._completeError(e);
    }
  , onDone: () {
    result._complete(buffer.toString());
    }
  , cancelOnError: true);
   return result;
  }
 Future<bool> contains(Object needle) {
  _Future<bool> future = new _Future<bool>();
   StreamSubscription subscription;
   subscription = this.listen((T element) {
    _runUserCode(() => (element == needle), (bool isMatch) {
      if (isMatch) {
        _cancelAndValue(subscription, future, true);
        }
      }
    , ((__x31) => DEVC$RT.cast(__x31, dynamic, __CastType26, "CompositeCast", """line 603, column 13 of dart:async/stream.dart: """, __x31 is __CastType26, false))(_cancelAndErrorClosure(subscription, future)));
    }
  , onError: future._completeError, onDone: () {
    future._complete(false);
    }
  , cancelOnError: true);
   return future;
  }
 Future forEach(void action(T element)) {
  _Future future = new _Future();
   StreamSubscription subscription;
   subscription = this.listen((T element) {
    _runUserCode(() => action(element), (_) {
      }
    , ((__x32) => DEVC$RT.cast(__x32, dynamic, __CastType26, "CompositeCast", """line 629, column 13 of dart:async/stream.dart: """, __x32 is __CastType26, false))(_cancelAndErrorClosure(subscription, future)));
    }
  , onError: future._completeError, onDone: () {
    future._complete(null);
    }
  , cancelOnError: true);
   return future;
  }
 Future<bool> every(bool test(T element)) {
  _Future<bool> future = new _Future<bool>();
   StreamSubscription subscription;
   subscription = this.listen((T element) {
    _runUserCode(() => test(element), (bool isMatch) {
      if (!isMatch) {
        _cancelAndValue(subscription, future, false);
        }
      }
    , ((__x33) => DEVC$RT.cast(__x33, dynamic, __CastType26, "CompositeCast", """line 658, column 13 of dart:async/stream.dart: """, __x33 is __CastType26, false))(_cancelAndErrorClosure(subscription, future)));
    }
  , onError: future._completeError, onDone: () {
    future._complete(true);
    }
  , cancelOnError: true);
   return future;
  }
 Future<bool> any(bool test(T element)) {
  _Future<bool> future = new _Future<bool>();
   StreamSubscription subscription;
   subscription = this.listen((T element) {
    _runUserCode(() => test(element), (bool isMatch) {
      if (isMatch) {
        _cancelAndValue(subscription, future, true);
        }
      }
    , ((__x34) => DEVC$RT.cast(__x34, dynamic, __CastType26, "CompositeCast", """line 695, column 13 of dart:async/stream.dart: """, __x34 is __CastType26, false))(_cancelAndErrorClosure(subscription, future)));
    }
  , onError: future._completeError, onDone: () {
    future._complete(false);
    }
  , cancelOnError: true);
   return future;
  }
 Future<int> get length {
  _Future<int> future = new _Future<int>();
   int count = 0;
   this.listen((_) {
    count++;
    }
  , onError: future._completeError, onDone: () {
    future._complete(count);
    }
  , cancelOnError: true);
   return future;
  }
 Future<bool> get isEmpty {
  _Future<bool> future = new _Future<bool>();
   StreamSubscription subscription;
   subscription = this.listen((_) {
    _cancelAndValue(subscription, future, false);
    }
  , onError: future._completeError, onDone: () {
    future._complete(true);
    }
  , cancelOnError: true);
   return future;
  }
 Future<List<T>> toList() {
  List<T> result = <T> [];
   _Future<List<T>> future = new _Future<List<T>>();
   this.listen((T data) {
    result.add(data);
    }
  , onError: future._completeError, onDone: () {
    future._complete(result);
    }
  , cancelOnError: true);
   return future;
  }
 Future<Set<T>> toSet() {
  Set<T> result = new Set<T>();
   _Future<Set<T>> future = new _Future<Set<T>>();
   this.listen((T data) {
    result.add(data);
    }
  , onError: future._completeError, onDone: () {
    future._complete(result);
    }
  , cancelOnError: true);
   return future;
  }
 Future drain([var futureValue]) => listen(null, cancelOnError: true).asFuture(futureValue);
 Stream<T> take(int count) {
  return new _TakeStream<T>(this, count);
  }
 Stream<T> takeWhile(bool test(T element)) {
  return new _TakeWhileStream<T>(this, test);
  }
 Stream<T> skip(int count) {
  return new _SkipStream<T>(this, count);
  }
 Stream<T> skipWhile(bool test(T element)) {
  return new _SkipWhileStream<T>(this, test);
  }
 Stream<T> distinct([bool equals(T previous, T next)]) {
  return new _DistinctStream<T>(this, equals);
  }
 Future<T> get first {
  _Future<T> future = new _Future<T>();
   StreamSubscription subscription;
   subscription = this.listen((T value) {
    _cancelAndValue(subscription, future, value);
    }
  , onError: future._completeError, onDone: () {
    try {
      throw IterableElementError.noElement();
      }
     catch (e, s) {
      _completeWithErrorCallback(future, e, s);
      }
    }
  , cancelOnError: true);
   return future;
  }
 Future<T> get last {
  _Future<T> future = new _Future<T>();
   T result = null;
   bool foundResult = false;
   StreamSubscription subscription;
   subscription = this.listen((T value) {
    foundResult = true;
     result = value;
    }
  , onError: future._completeError, onDone: () {
    if (foundResult) {
      future._complete(result);
       return;}
     try {
      throw IterableElementError.noElement();
      }
     catch (e, s) {
      _completeWithErrorCallback(future, e, s);
      }
    }
  , cancelOnError: true);
   return future;
  }
 Future<T> get single {
  _Future<T> future = new _Future<T>();
   T result = null;
   bool foundResult = false;
   StreamSubscription subscription;
   subscription = this.listen((T value) {
    if (foundResult) {
      try {
        throw IterableElementError.tooMany();
        }
       catch (e, s) {
        _cancelAndErrorWithReplacement(subscription, future, e, s);
        }
       return;}
     foundResult = true;
     result = value;
    }
  , onError: future._completeError, onDone: () {
    if (foundResult) {
      future._complete(result);
       return;}
     try {
      throw IterableElementError.noElement();
      }
     catch (e, s) {
      _completeWithErrorCallback(future, e, s);
      }
    }
  , cancelOnError: true);
   return future;
  }
 Future<dynamic> firstWhere(bool test(T element), {
  Object defaultValue()}
) {
  _Future<dynamic> future = new _Future();
   StreamSubscription subscription;
   subscription = this.listen((T value) {
    _runUserCode(() => test(value), (bool isMatch) {
      if (isMatch) {
        _cancelAndValue(subscription, future, value);
        }
      }
    , ((__x35) => DEVC$RT.cast(__x35, dynamic, __CastType26, "CompositeCast", """line 1037, column 11 of dart:async/stream.dart: """, __x35 is __CastType26, false))(_cancelAndErrorClosure(subscription, future)));
    }
  , onError: future._completeError, onDone: () {
    if (defaultValue != null) {
      _runUserCode(defaultValue, future._complete, future._completeError);
       return;}
     try {
      throw IterableElementError.noElement();
      }
     catch (e, s) {
      _completeWithErrorCallback(future, e, s);
      }
    }
  , cancelOnError: true);
   return future;
  }
 Future<dynamic> lastWhere(bool test(T element), {
  Object defaultValue()}
) {
  _Future<dynamic> future = new _Future();
   T result = null;
   bool foundResult = false;
   StreamSubscription subscription;
   subscription = this.listen((T value) {
    _runUserCode(() => true == test(value), (bool isMatch) {
      if (isMatch) {
        foundResult = true;
         result = value;
        }
      }
    , ((__x36) => DEVC$RT.cast(__x36, dynamic, __CastType26, "CompositeCast", """line 1078, column 11 of dart:async/stream.dart: """, __x36 is __CastType26, false))(_cancelAndErrorClosure(subscription, future)));
    }
  , onError: future._completeError, onDone: () {
    if (foundResult) {
      future._complete(result);
       return;}
     if (defaultValue != null) {
      _runUserCode(defaultValue, future._complete, future._completeError);
       return;}
     try {
      throw IterableElementError.noElement();
      }
     catch (e, s) {
      _completeWithErrorCallback(future, e, s);
      }
    }
  , cancelOnError: true);
   return future;
  }
 Future<T> singleWhere(bool test(T element)) {
  _Future<T> future = new _Future<T>();
   T result = null;
   bool foundResult = false;
   StreamSubscription subscription;
   subscription = this.listen((T value) {
    _runUserCode(() => true == test(value), (bool isMatch) {
      if (isMatch) {
        if (foundResult) {
          try {
            throw IterableElementError.tooMany();
            }
           catch (e, s) {
            _cancelAndErrorWithReplacement(subscription, future, e, s);
            }
           return;}
         foundResult = true;
         result = value;
        }
      }
    , ((__x37) => DEVC$RT.cast(__x37, dynamic, __CastType26, "CompositeCast", """line 1130, column 11 of dart:async/stream.dart: """, __x37 is __CastType26, false))(_cancelAndErrorClosure(subscription, future)));
    }
  , onError: future._completeError, onDone: () {
    if (foundResult) {
      future._complete(result);
       return;}
     try {
      throw IterableElementError.noElement();
      }
     catch (e, s) {
      _completeWithErrorCallback(future, e, s);
      }
    }
  , cancelOnError: true);
   return future;
  }
 Future<T> elementAt(int index) {
  if (index is! int || index < 0) throw new ArgumentError(index);
   _Future<T> future = new _Future<T>();
   StreamSubscription subscription;
   int elementIndex = 0;
   subscription = this.listen((T value) {
    if (index == elementIndex) {
      _cancelAndValue(subscription, future, value);
       return;}
     elementIndex += 1;
    }
  , onError: future._completeError, onDone: () {
    future._completeError(new RangeError.index(index, this, "index", null, elementIndex));
    }
  , cancelOnError: true);
   return future;
  }
 Stream timeout(Duration timeLimit, {
  void onTimeout(EventSink sink)}
) {
  StreamController controller;
   StreamSubscription<T> subscription;
   Timer timer;
   Zone zone;
   Function timeout;
   void onData(T event) {
    timer.cancel();
     controller.add(event);
     timer = zone.createTimer(timeLimit, DEVC$RT.cast(timeout, Function, __CastType38, "CompositeCast", """line 1220, column 43 of dart:async/stream.dart: """, timeout is __CastType38, false));
    }
   void onError(error, StackTrace stackTrace) {
    timer.cancel();
     assert (controller is _StreamController || controller is _BroadcastStreamController); var eventSink = controller;
     eventSink._addError(error, stackTrace);
     timer = zone.createTimer(timeLimit, DEVC$RT.cast(timeout, Function, __CastType38, "CompositeCast", """line 1228, column 43 of dart:async/stream.dart: """, timeout is __CastType38, false));
    }
   void onDone() {
    timer.cancel();
     controller.close();
    }
   void onListen() {
    zone = Zone.current;
     if (onTimeout == null) {
      timeout = () {
        controller.addError(new TimeoutException("No stream event", timeLimit), null);
        }
      ;
      }
     else {
      onTimeout = ((__x41) => DEVC$RT.cast(__x41, ZoneUnaryCallback, __CastType39, "CompositeCast", """line 1246, column 21 of dart:async/stream.dart: """, __x41 is __CastType39, false))(zone.registerUnaryCallback(onTimeout));
       _ControllerEventSinkWrapper wrapper = new _ControllerEventSinkWrapper(null);
       timeout = () {
        wrapper._sink = controller;
         zone.runUnaryGuarded(onTimeout, wrapper);
         wrapper._sink = null;
        }
      ;
      }
     subscription = this.listen(onData, onError: onError, onDone: onDone);
     timer = zone.createTimer(timeLimit, DEVC$RT.cast(timeout, Function, __CastType38, "CompositeCast", """line 1257, column 43 of dart:async/stream.dart: """, timeout is __CastType38, false));
    }
   Future onCancel() {
    timer.cancel();
     Future result = subscription.cancel();
     subscription = null;
     return result;
    }
   controller = isBroadcast ? new _SyncBroadcastStreamController(onListen, onCancel) : new _SyncStreamController(onListen, () {
    timer.cancel();
     subscription.pause();
    }
  , () {
    subscription.resume();
     timer = zone.createTimer(timeLimit, DEVC$RT.cast(timeout, Function, __CastType38, "CompositeCast", """line 1276, column 53 of dart:async/stream.dart: """, timeout is __CastType38, false));
    }
  , onCancel);
   return controller.stream;
  }
}
 abstract class StreamSubscription<T> {Future cancel();
 void onData(void handleData(T data));
 void onError(Function handleError);
 void onDone(void handleDone());
 void pause([Future resumeSignal]);
 void resume();
 bool get isPaused;
 Future asFuture([var futureValue]);
}
 abstract class EventSink<T> implements Sink<T> {void add(T event);
 void addError(errorEvent, [StackTrace stackTrace]);
 void close();
}
 class StreamView<T> extends Stream<T> {Stream<T> _stream;
 StreamView(this._stream);
 bool get isBroadcast => _stream.isBroadcast;
 Stream<T> asBroadcastStream({
void onListen(StreamSubscription<T> subscription), void onCancel(StreamSubscription<T> subscription)}
) => _stream.asBroadcastStream(onListen: onListen, onCancel: onCancel);
 StreamSubscription<T> listen(void onData(T value), {
Function onError, void onDone(), bool cancelOnError}
) {
return _stream.listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
}
}
 abstract class StreamConsumer<S> {Future addStream(Stream<S> stream);
 Future close();
}
 abstract class StreamSink<S> implements StreamConsumer<S>, EventSink<S> {Future close();
 Future get done;
}
 abstract class StreamTransformer<S, T> {const factory StreamTransformer(StreamSubscription<T> transformer(Stream<S> stream, bool cancelOnError)) = _StreamSubscriptionTransformer;
 factory StreamTransformer.fromHandlers({
void handleData(S data, EventSink<T> sink), void handleError(Object error, StackTrace stackTrace, EventSink<T> sink), void handleDone(EventSink<T> sink)}
) = _StreamHandlerTransformer;
 Stream<T> bind(Stream<S> stream);
}
 abstract class StreamIterator<T> {factory StreamIterator(Stream<T> stream) => new _StreamIteratorImpl<T>(stream);
 Future<bool> moveNext();
 T get current;
 Future cancel();
}
 class _ControllerEventSinkWrapper<T> implements EventSink<T> {EventSink _sink;
 _ControllerEventSinkWrapper(this._sink);
 void add(T data) {
_sink.add(data);
}
 void addError(error, [StackTrace stackTrace]) {
_sink.addError(error, stackTrace);
}
 void close() {
_sink.close();
}
}
 typedef EventSink<dynamic> __CastType20<T>(EventSink<T> __u21);
 typedef void __CastType22(StreamSubscription<dynamic> __u23);
 typedef void __CastType24<T>(StreamSubscription<T> __u25);
 typedef dynamic __CastType26(dynamic __u27, StackTrace __u28);
 typedef void __CastType38();
 typedef void __CastType39(EventSink<dynamic> __u40);
