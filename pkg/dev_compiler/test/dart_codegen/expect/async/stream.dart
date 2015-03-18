part of dart.async;
 abstract class Stream<T> {Stream();
 factory Stream.fromFuture(Future<T> future) {
  _StreamController<T> controller = ((__x29) => DEVC$RT.cast(__x29, DEVC$RT.type((StreamController<T> _) {
    }
  ), DEVC$RT.type((_StreamController<T> _) {
    }
  ), "CastExact", """line 87, column 39 of dart:async/stream.dart: """, __x29 is _StreamController<T>, false))(new StreamController<T>(sync: true));
   future.then(((__x35) => DEVC$RT.wrap((dynamic f(dynamic __u30)) {
    dynamic c(dynamic x0) => f(x0);
     return f == null ? null : c;
    }
  , __x35, __t33, DEVC$RT.type((__t31<T> _) {
    }
  ), "WrapLiteral", """line 88, column 17 of dart:async/stream.dart: """, __x35 is __t31<T>))((value) {
    controller._add(DEVC$RT.cast(value, dynamic, T, "CastGeneral", """line 89, column 25 of dart:async/stream.dart: """, value is T, false));
     controller._closeUnchecked();
    }
  ), onError: (error, stackTrace) {
    controller._addError(error, DEVC$RT.cast(stackTrace, dynamic, StackTrace, "CastGeneral", """line 93, column 37 of dart:async/stream.dart: """, stackTrace is StackTrace, true));
     controller._closeUnchecked();
    }
  );
   return controller.stream;
  }
 factory Stream.fromIterable(Iterable<T> data) {
  return new _GeneratedStreamImpl<T>(() => new _IterablePendingEvents<T>(data));
  }
 factory Stream.periodic(Duration period, [T computation(int computationCount)]) {
  if (computation == null) computation = ((__x41) => DEVC$RT.wrap((dynamic f(dynamic __u36)) {
    dynamic c(dynamic x0) => f(x0);
     return f == null ? null : c;
    }
  , __x41, __t39, DEVC$RT.type((__t37<T> _) {
    }
  ), "Wrap", """line 126, column 44 of dart:async/stream.dart: """, __x41 is __t37<T>))(((i) => null));
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
  return ((__x42) => DEVC$RT.cast(__x42, DEVC$RT.type((_BoundSinkStream<dynamic, dynamic> _) {
    }
  ), DEVC$RT.type((Stream<T> _) {
    }
  ), "CastExact", """line 216, column 12 of dart:async/stream.dart: """, __x42 is Stream<T>, false))(new _BoundSinkStream(source, DEVC$RT.wrap((EventSink<dynamic> f(EventSink<T> __u43)) {
    EventSink<dynamic> c(EventSink<T> x0) => f(DEVC$RT.cast(x0, DEVC$RT.type((EventSink<dynamic> _) {
      }
    ), DEVC$RT.type((EventSink<T> _) {
      }
    ), "CastParam", """line 216, column 41 of dart:async/stream.dart: """, x0 is EventSink<T>, false));
     return f == null ? null : c;
    }
  , mapSink, DEVC$RT.type((__t46<T> _) {
    }
  ), __t44, "Wrap", """line 216, column 41 of dart:async/stream.dart: """, mapSink is __t44)));
  }
 bool get isBroadcast => false;
 Stream<T> asBroadcastStream({
  void onListen(StreamSubscription<T> subscription), void onCancel(StreamSubscription<T> subscription)}
) {
  return new _AsBroadcastStream<T>(this, DEVC$RT.wrap((void f(StreamSubscription<T> __u48)) {
    void c(StreamSubscription<T> x0) => f(DEVC$RT.cast(x0, DEVC$RT.type((StreamSubscription<dynamic> _) {
      }
    ), DEVC$RT.type((StreamSubscription<T> _) {
      }
    ), "CastParam", """line 248, column 44 of dart:async/stream.dart: """, x0 is StreamSubscription<T>, false));
     return f == null ? null : c;
    }
  , onListen, DEVC$RT.type((__t51<T> _) {
    }
  ), __t49, "Wrap", """line 248, column 44 of dart:async/stream.dart: """, onListen is __t49), DEVC$RT.wrap((void f(StreamSubscription<T> __u53)) {
    void c(StreamSubscription<T> x0) => f(DEVC$RT.cast(x0, DEVC$RT.type((StreamSubscription<dynamic> _) {
      }
    ), DEVC$RT.type((StreamSubscription<T> _) {
      }
    ), "CastParam", """line 248, column 54 of dart:async/stream.dart: """, x0 is StreamSubscription<T>, false));
     return f == null ? null : c;
    }
  , onCancel, DEVC$RT.type((__t51<T> _) {
    }
  ), __t49, "Wrap", """line 248, column 54 of dart:async/stream.dart: """, onCancel is __t49));
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
    , onError: DEVC$RT.cast(addError, dynamic, Function, "CastGeneral", """line 338, column 20 of dart:async/stream.dart: """, addError is Function, true), onDone: controller.close);
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
    , onError: DEVC$RT.cast(eventSink._addError, dynamic, Function, "CastGeneral", """line 395, column 20 of dart:async/stream.dart: """, eventSink._addError is Function, true), onDone: controller.close);
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
      , ((__x57) => DEVC$RT.cast(__x57, dynamic, __t54, "CastGeneral", """line 501, column 24 of dart:async/stream.dart: """, __x57 is __t54, false))(_cancelAndErrorClosure(subscription, result)));
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
    , ((__x58) => DEVC$RT.cast(__x58, dynamic, __t54, "CastGeneral", """line 534, column 11 of dart:async/stream.dart: """, __x58 is __t54, false))(_cancelAndErrorClosure(subscription, result)));
    }
  , onError: (e, st) {
    result._completeError(e, DEVC$RT.cast(st, dynamic, StackTrace, "CastGeneral", """line 538, column 34 of dart:async/stream.dart: """, st is StackTrace, true));
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
    , ((__x59) => DEVC$RT.cast(__x59, dynamic, __t54, "CastGeneral", """line 602, column 13 of dart:async/stream.dart: """, __x59 is __t54, false))(_cancelAndErrorClosure(subscription, future)));
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
    , ((__x60) => DEVC$RT.cast(__x60, dynamic, __t54, "CastGeneral", """line 628, column 13 of dart:async/stream.dart: """, __x60 is __t54, false))(_cancelAndErrorClosure(subscription, future)));
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
    , ((__x61) => DEVC$RT.cast(__x61, dynamic, __t54, "CastGeneral", """line 657, column 13 of dart:async/stream.dart: """, __x61 is __t54, false))(_cancelAndErrorClosure(subscription, future)));
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
    , ((__x62) => DEVC$RT.cast(__x62, dynamic, __t54, "CastGeneral", """line 694, column 13 of dart:async/stream.dart: """, __x62 is __t54, false))(_cancelAndErrorClosure(subscription, future)));
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
   this.listen(((__x66) => DEVC$RT.wrap((dynamic f(dynamic __u63)) {
    dynamic c(dynamic x0) => f(x0);
     return f == null ? null : c;
    }
  , __x66, __t33, DEVC$RT.type((__t64<T> _) {
    }
  ), "WrapLiteral", """line 711, column 7 of dart:async/stream.dart: """, __x66 is __t64<T>))((_) {
    count++;
    }
  ), onError: future._completeError, onDone: () {
    future._complete(count);
    }
  , cancelOnError: true);
   return future;
  }
 Future<bool> get isEmpty {
  _Future<bool> future = new _Future<bool>();
   StreamSubscription subscription;
   subscription = this.listen(((__x68) => DEVC$RT.wrap((dynamic f(dynamic __u67)) {
    dynamic c(dynamic x0) => f(x0);
     return f == null ? null : c;
    }
  , __x68, __t33, DEVC$RT.type((__t64<T> _) {
    }
  ), "WrapLiteral", """line 733, column 7 of dart:async/stream.dart: """, __x68 is __t64<T>))((_) {
    _cancelAndValue(subscription, future, false);
    }
  ), onError: future._completeError, onDone: () {
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
  return ((__x69) => DEVC$RT.cast(__x69, DEVC$RT.type((_TakeStream<dynamic> _) {
    }
  ), DEVC$RT.type((Stream<T> _) {
    }
  ), "CastExact", """line 819, column 12 of dart:async/stream.dart: """, __x69 is Stream<T>, false))(new _TakeStream(this, count));
  }
 Stream<T> takeWhile(bool test(T element)) {
  return ((__x70) => DEVC$RT.cast(__x70, DEVC$RT.type((_TakeWhileStream<dynamic> _) {
    }
  ), DEVC$RT.type((Stream<T> _) {
    }
  ), "CastExact", """line 841, column 12 of dart:async/stream.dart: """, __x70 is Stream<T>, false))(new _TakeWhileStream(this, test));
  }
 Stream<T> skip(int count) {
  return ((__x71) => DEVC$RT.cast(__x71, DEVC$RT.type((_SkipStream<dynamic> _) {
    }
  ), DEVC$RT.type((Stream<T> _) {
    }
  ), "CastExact", """line 852, column 12 of dart:async/stream.dart: """, __x71 is Stream<T>, false))(new _SkipStream(this, count));
  }
 Stream<T> skipWhile(bool test(T element)) {
  return ((__x72) => DEVC$RT.cast(__x72, DEVC$RT.type((_SkipWhileStream<dynamic> _) {
    }
  ), DEVC$RT.type((Stream<T> _) {
    }
  ), "CastExact", """line 868, column 12 of dart:async/stream.dart: """, __x72 is Stream<T>, false))(new _SkipWhileStream(this, test));
  }
 Stream<T> distinct([bool equals(T previous, T next)]) {
  return ((__x73) => DEVC$RT.cast(__x73, DEVC$RT.type((_DistinctStream<dynamic> _) {
    }
  ), DEVC$RT.type((Stream<T> _) {
    }
  ), "CastExact", """line 885, column 12 of dart:async/stream.dart: """, __x73 is Stream<T>, false))(new _DistinctStream(this, equals));
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
    , ((__x74) => DEVC$RT.cast(__x74, dynamic, __t54, "CastGeneral", """line 1036, column 11 of dart:async/stream.dart: """, __x74 is __t54, false))(_cancelAndErrorClosure(subscription, future)));
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
    , ((__x75) => DEVC$RT.cast(__x75, dynamic, __t54, "CastGeneral", """line 1077, column 11 of dart:async/stream.dart: """, __x75 is __t54, false))(_cancelAndErrorClosure(subscription, future)));
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
    , ((__x76) => DEVC$RT.cast(__x76, dynamic, __t54, "CastGeneral", """line 1129, column 11 of dart:async/stream.dart: """, __x76 is __t54, false))(_cancelAndErrorClosure(subscription, future)));
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
     timer = zone.createTimer(timeLimit, DEVC$RT.cast(timeout, Function, __t77, "CastGeneral", """line 1219, column 43 of dart:async/stream.dart: """, timeout is __t77, false));
    }
   void onError(error, StackTrace stackTrace) {
    timer.cancel();
     assert (controller is _StreamController || controller is _BroadcastStreamController); var eventSink = controller;
     eventSink._addError(error, stackTrace);
     timer = zone.createTimer(timeLimit, DEVC$RT.cast(timeout, Function, __t77, "CastGeneral", """line 1227, column 43 of dart:async/stream.dart: """, timeout is __t77, false));
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
      onTimeout = ((__x81) => DEVC$RT.wrap((dynamic f(dynamic __u78)) {
        dynamic c(dynamic x0) => f(x0);
         return f == null ? null : c;
        }
      , __x81, __t33, __t79, "Wrap", """line 1245, column 21 of dart:async/stream.dart: """, __x81 is __t79))(zone.registerUnaryCallback(onTimeout));
       _ControllerEventSinkWrapper wrapper = new _ControllerEventSinkWrapper(null);
       timeout = () {
        wrapper._sink = controller;
         zone.runUnaryGuarded(onTimeout, wrapper);
         wrapper._sink = null;
        }
      ;
      }
     subscription = this.listen(onData, onError: onError, onDone: onDone);
     timer = zone.createTimer(timeLimit, DEVC$RT.cast(timeout, Function, __t77, "CastGeneral", """line 1256, column 43 of dart:async/stream.dart: """, timeout is __t77, false));
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
     timer = zone.createTimer(timeLimit, DEVC$RT.cast(timeout, Function, __t77, "CastGeneral", """line 1275, column 53 of dart:async/stream.dart: """, timeout is __t77, false));
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
void onListen(StreamSubscription subscription), void onCancel(StreamSubscription subscription)}
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
 typedef dynamic __t31<T>(T __u32);
 typedef dynamic __t33(dynamic __u34);
 typedef T __t37<T>(int __u38);
 typedef dynamic __t39(dynamic __u40);
 typedef EventSink<dynamic> __t44(EventSink<dynamic> __u45);
 typedef EventSink<dynamic> __t46<T>(EventSink<T> __u47);
 typedef void __t49(StreamSubscription<dynamic> __u50);
 typedef void __t51<T>(StreamSubscription<T> __u52);
 typedef dynamic __t54(dynamic __u55, StackTrace __u56);
 typedef void __t64<T>(T __u65);
 typedef void __t77();
 typedef void __t79(EventSink<dynamic> __u80);
