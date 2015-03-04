part of dart.async;
 abstract class Stream<T> {Stream();
 factory Stream.fromFuture(Future<T> future) {
  _StreamController<T> controller = ((__x37) => DEVC$RT.cast(__x37, DEVC$RT.type((StreamController<T> _) {
    }
  ), DEVC$RT.type((_StreamController<T> _) {
    }
  ), "CastExact", """line 87, column 39 of dart:async/stream.dart: """, __x37 is _StreamController<T>, false))(new StreamController<T>(sync: true));
   future.then((value) {
    controller._add(DEVC$RT.cast(value, dynamic, T, "CastGeneral", """line 89, column 25 of dart:async/stream.dart: """, value is T, false));
     controller._closeUnchecked();
    }
  , onError: (error, stackTrace) {
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
  return ((__x38) => DEVC$RT.cast(__x38, DEVC$RT.type((_BoundSinkStream<dynamic, dynamic> _) {
    }
  ), DEVC$RT.type((Stream<T> _) {
    }
  ), "CastExact", """line 216, column 12 of dart:async/stream.dart: """, __x38 is Stream<T>, false))(new _BoundSinkStream(source, DEVC$RT.wrap((EventSink<dynamic> f(EventSink<T> __u39)) {
    EventSink<dynamic> c(EventSink<T> x0) => f(DEVC$RT.cast(x0, DEVC$RT.type((EventSink<dynamic> _) {
      }
    ), DEVC$RT.type((EventSink<T> _) {
      }
    ), "CastParam", """line 216, column 41 of dart:async/stream.dart: """, x0 is EventSink<T>, false));
     return f == null ? null : c;
    }
  , mapSink, DEVC$RT.type((__t42<T> _) {
    }
  ), __t40, "Wrap", """line 216, column 41 of dart:async/stream.dart: """, mapSink is __t40)));
  }
 bool get isBroadcast => false;
 Stream<T> asBroadcastStream({
  void onListen(StreamSubscription<T> subscription), void onCancel(StreamSubscription<T> subscription)}
) {
  return new _AsBroadcastStream<T>(this, DEVC$RT.wrap((void f(StreamSubscription<T> __u44)) {
    void c(StreamSubscription<T> x0) => f(DEVC$RT.cast(x0, DEVC$RT.type((StreamSubscription<dynamic> _) {
      }
    ), DEVC$RT.type((StreamSubscription<T> _) {
      }
    ), "CastParam", """line 248, column 44 of dart:async/stream.dart: """, x0 is StreamSubscription<T>, false));
     return f == null ? null : c;
    }
  , onListen, DEVC$RT.type((__t47<T> _) {
    }
  ), __t45, "Wrap", """line 248, column 44 of dart:async/stream.dart: """, onListen is __t45), DEVC$RT.wrap((void f(StreamSubscription<T> __u49)) {
    void c(StreamSubscription<T> x0) => f(DEVC$RT.cast(x0, DEVC$RT.type((StreamSubscription<dynamic> _) {
      }
    ), DEVC$RT.type((StreamSubscription<T> _) {
      }
    ), "CastParam", """line 248, column 54 of dart:async/stream.dart: """, x0 is StreamSubscription<T>, false));
     return f == null ? null : c;
    }
  , onCancel, DEVC$RT.type((__t47<T> _) {
    }
  ), __t45, "Wrap", """line 248, column 54 of dart:async/stream.dart: """, onCancel is __t45));
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
      _runUserCode(() => combine(value, element), ((__x55) => DEVC$RT.wrap((dynamic f(T __u50)) {
        dynamic c(T x0) => f(DEVC$RT.cast(x0, dynamic, T, "CastParam", """line 500, column 24 of dart:async/stream.dart: """, x0 is T, false));
         return f == null ? null : c;
        }
      , __x55, DEVC$RT.type((__t53<T> _) {
        }
      ), __t51, "WrapLiteral", """line 500, column 24 of dart:async/stream.dart: """, __x55 is __t51))((T newValue) {
        value = newValue;
        }
      ), ((__x59) => DEVC$RT.cast(__x59, dynamic, __t56, "CastGeneral", """line 501, column 24 of dart:async/stream.dart: """, __x59 is __t56, false))(_cancelAndErrorClosure(subscription, result)));
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
    , ((__x60) => DEVC$RT.cast(__x60, dynamic, __t56, "CastGeneral", """line 534, column 11 of dart:async/stream.dart: """, __x60 is __t56, false))(_cancelAndErrorClosure(subscription, result)));
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
    _runUserCode(() => (element == needle), ((__x64) => DEVC$RT.wrap((dynamic f(bool __u61)) {
      dynamic c(bool x0) => f(DEVC$RT.cast(x0, dynamic, bool, "CastParam", """line 597, column 13 of dart:async/stream.dart: """, x0 is bool, true));
       return f == null ? null : c;
      }
    , __x64, __t62, __t51, "WrapLiteral", """line 597, column 13 of dart:async/stream.dart: """, __x64 is __t51))((bool isMatch) {
      if (isMatch) {
        _cancelAndValue(subscription, future, true);
        }
      }
    ), ((__x65) => DEVC$RT.cast(__x65, dynamic, __t56, "CastGeneral", """line 602, column 13 of dart:async/stream.dart: """, __x65 is __t56, false))(_cancelAndErrorClosure(subscription, future)));
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
    , ((__x66) => DEVC$RT.cast(__x66, dynamic, __t56, "CastGeneral", """line 628, column 13 of dart:async/stream.dart: """, __x66 is __t56, false))(_cancelAndErrorClosure(subscription, future)));
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
    _runUserCode(() => test(element), ((__x68) => DEVC$RT.wrap((dynamic f(bool __u67)) {
      dynamic c(bool x0) => f(DEVC$RT.cast(x0, dynamic, bool, "CastParam", """line 652, column 13 of dart:async/stream.dart: """, x0 is bool, true));
       return f == null ? null : c;
      }
    , __x68, __t62, __t51, "WrapLiteral", """line 652, column 13 of dart:async/stream.dart: """, __x68 is __t51))((bool isMatch) {
      if (!isMatch) {
        _cancelAndValue(subscription, future, false);
        }
      }
    ), ((__x69) => DEVC$RT.cast(__x69, dynamic, __t56, "CastGeneral", """line 657, column 13 of dart:async/stream.dart: """, __x69 is __t56, false))(_cancelAndErrorClosure(subscription, future)));
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
    _runUserCode(() => test(element), ((__x71) => DEVC$RT.wrap((dynamic f(bool __u70)) {
      dynamic c(bool x0) => f(DEVC$RT.cast(x0, dynamic, bool, "CastParam", """line 689, column 13 of dart:async/stream.dart: """, x0 is bool, true));
       return f == null ? null : c;
      }
    , __x71, __t62, __t51, "WrapLiteral", """line 689, column 13 of dart:async/stream.dart: """, __x71 is __t51))((bool isMatch) {
      if (isMatch) {
        _cancelAndValue(subscription, future, true);
        }
      }
    ), ((__x72) => DEVC$RT.cast(__x72, dynamic, __t56, "CastGeneral", """line 694, column 13 of dart:async/stream.dart: """, __x72 is __t56, false))(_cancelAndErrorClosure(subscription, future)));
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
  return ((__x73) => DEVC$RT.cast(__x73, DEVC$RT.type((_TakeStream<dynamic> _) {
    }
  ), DEVC$RT.type((Stream<T> _) {
    }
  ), "CastExact", """line 819, column 12 of dart:async/stream.dart: """, __x73 is Stream<T>, false))(new _TakeStream(this, count));
  }
 Stream<T> takeWhile(bool test(T element)) {
  return ((__x74) => DEVC$RT.cast(__x74, DEVC$RT.type((_TakeWhileStream<dynamic> _) {
    }
  ), DEVC$RT.type((Stream<T> _) {
    }
  ), "CastExact", """line 841, column 12 of dart:async/stream.dart: """, __x74 is Stream<T>, false))(new _TakeWhileStream(this, DEVC$RT.wrap((bool f(T __u75)) {
    bool c(T x0) => f(DEVC$RT.cast(x0, dynamic, T, "CastParam", """line 841, column 39 of dart:async/stream.dart: """, x0 is T, false));
     return f == null ? null : c;
    }
  , test, DEVC$RT.type((__t78<T> _) {
    }
  ), __t76, "Wrap", """line 841, column 39 of dart:async/stream.dart: """, test is __t76)));
  }
 Stream<T> skip(int count) {
  return ((__x80) => DEVC$RT.cast(__x80, DEVC$RT.type((_SkipStream<dynamic> _) {
    }
  ), DEVC$RT.type((Stream<T> _) {
    }
  ), "CastExact", """line 852, column 12 of dart:async/stream.dart: """, __x80 is Stream<T>, false))(new _SkipStream(this, count));
  }
 Stream<T> skipWhile(bool test(T element)) {
  return ((__x81) => DEVC$RT.cast(__x81, DEVC$RT.type((_SkipWhileStream<dynamic> _) {
    }
  ), DEVC$RT.type((Stream<T> _) {
    }
  ), "CastExact", """line 868, column 12 of dart:async/stream.dart: """, __x81 is Stream<T>, false))(new _SkipWhileStream(this, DEVC$RT.wrap((bool f(T __u82)) {
    bool c(T x0) => f(DEVC$RT.cast(x0, dynamic, T, "CastParam", """line 868, column 39 of dart:async/stream.dart: """, x0 is T, false));
     return f == null ? null : c;
    }
  , test, DEVC$RT.type((__t78<T> _) {
    }
  ), __t76, "Wrap", """line 868, column 39 of dart:async/stream.dart: """, test is __t76)));
  }
 Stream<T> distinct([bool equals(T previous, T next)]) {
  return ((__x83) => DEVC$RT.cast(__x83, DEVC$RT.type((_DistinctStream<dynamic> _) {
    }
  ), DEVC$RT.type((Stream<T> _) {
    }
  ), "CastExact", """line 885, column 12 of dart:async/stream.dart: """, __x83 is Stream<T>, false))(new _DistinctStream(this, DEVC$RT.wrap((bool f(T __u84, T __u85)) {
    bool c(T x0, T x1) => f(DEVC$RT.cast(x0, dynamic, T, "CastParam", """line 885, column 38 of dart:async/stream.dart: """, x0 is T, false), DEVC$RT.cast(x1, dynamic, T, "CastParam", """line 885, column 38 of dart:async/stream.dart: """, x1 is T, false));
     return f == null ? null : c;
    }
  , equals, DEVC$RT.type((__t89<T> _) {
    }
  ), __t86, "Wrap", """line 885, column 38 of dart:async/stream.dart: """, equals is __t86)));
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
    _runUserCode(() => test(value), ((__x93) => DEVC$RT.wrap((dynamic f(bool __u92)) {
      dynamic c(bool x0) => f(DEVC$RT.cast(x0, dynamic, bool, "CastParam", """line 1031, column 11 of dart:async/stream.dart: """, x0 is bool, true));
       return f == null ? null : c;
      }
    , __x93, __t62, __t51, "WrapLiteral", """line 1031, column 11 of dart:async/stream.dart: """, __x93 is __t51))((bool isMatch) {
      if (isMatch) {
        _cancelAndValue(subscription, future, value);
        }
      }
    ), ((__x94) => DEVC$RT.cast(__x94, dynamic, __t56, "CastGeneral", """line 1036, column 11 of dart:async/stream.dart: """, __x94 is __t56, false))(_cancelAndErrorClosure(subscription, future)));
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
    _runUserCode(() => true == test(value), ((__x96) => DEVC$RT.wrap((dynamic f(bool __u95)) {
      dynamic c(bool x0) => f(DEVC$RT.cast(x0, dynamic, bool, "CastParam", """line 1071, column 11 of dart:async/stream.dart: """, x0 is bool, true));
       return f == null ? null : c;
      }
    , __x96, __t62, __t51, "WrapLiteral", """line 1071, column 11 of dart:async/stream.dart: """, __x96 is __t51))((bool isMatch) {
      if (isMatch) {
        foundResult = true;
         result = value;
        }
      }
    ), ((__x97) => DEVC$RT.cast(__x97, dynamic, __t56, "CastGeneral", """line 1077, column 11 of dart:async/stream.dart: """, __x97 is __t56, false))(_cancelAndErrorClosure(subscription, future)));
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
    _runUserCode(() => true == test(value), ((__x99) => DEVC$RT.wrap((dynamic f(bool __u98)) {
      dynamic c(bool x0) => f(DEVC$RT.cast(x0, dynamic, bool, "CastParam", """line 1115, column 11 of dart:async/stream.dart: """, x0 is bool, true));
       return f == null ? null : c;
      }
    , __x99, __t62, __t51, "WrapLiteral", """line 1115, column 11 of dart:async/stream.dart: """, __x99 is __t51))((bool isMatch) {
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
    ), ((__x100) => DEVC$RT.cast(__x100, dynamic, __t56, "CastGeneral", """line 1129, column 11 of dart:async/stream.dart: """, __x100 is __t56, false))(_cancelAndErrorClosure(subscription, future)));
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
     timer = zone.createTimer(timeLimit, DEVC$RT.cast(timeout, Function, __t101, "CastGeneral", """line 1219, column 43 of dart:async/stream.dart: """, timeout is __t101, false));
    }
   void onError(error, StackTrace stackTrace) {
    timer.cancel();
     assert (controller is _StreamController || controller is _BroadcastStreamController); var eventSink = controller;
     eventSink._addError(error, stackTrace);
     timer = zone.createTimer(timeLimit, DEVC$RT.cast(timeout, Function, __t101, "CastGeneral", """line 1227, column 43 of dart:async/stream.dart: """, timeout is __t101, false));
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
      onTimeout = zone.registerUnaryCallback(DEVC$RT.wrap((void f(EventSink<dynamic> __u102)) {
        void c(EventSink<dynamic> x0) => f(DEVC$RT.cast(x0, dynamic, DEVC$RT.type((EventSink<dynamic> _) {
          }
        ), "CastParam", """line 1245, column 48 of dart:async/stream.dart: """, x0 is EventSink<dynamic>, true));
         return f == null ? null : c;
        }
      , onTimeout, __t103, __t51, "Wrap", """line 1245, column 48 of dart:async/stream.dart: """, onTimeout is __t51));
       _ControllerEventSinkWrapper wrapper = new _ControllerEventSinkWrapper(null);
       timeout = () {
        wrapper._sink = controller;
         zone.runUnaryGuarded(DEVC$RT.wrap((void f(EventSink<dynamic> __u105)) {
          void c(EventSink<dynamic> x0) => f(DEVC$RT.cast(x0, dynamic, DEVC$RT.type((EventSink<dynamic> _) {
            }
          ), "CastParam", """line 1250, column 32 of dart:async/stream.dart: """, x0 is EventSink<dynamic>, true));
           return f == null ? null : c;
          }
        , onTimeout, __t103, __t51, "Wrap", """line 1250, column 32 of dart:async/stream.dart: """, onTimeout is __t51), wrapper);
         wrapper._sink = null;
        }
      ;
      }
     subscription = this.listen(onData, onError: onError, onDone: onDone);
     timer = zone.createTimer(timeLimit, DEVC$RT.cast(timeout, Function, __t101, "CastGeneral", """line 1256, column 43 of dart:async/stream.dart: """, timeout is __t101, false));
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
     timer = zone.createTimer(timeLimit, DEVC$RT.cast(timeout, Function, __t101, "CastGeneral", """line 1275, column 53 of dart:async/stream.dart: """, timeout is __t101, false));
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
 typedef EventSink<dynamic> __t40(EventSink<dynamic> __u41);
 typedef EventSink<dynamic> __t42<T>(EventSink<T> __u43);
 typedef void __t45(StreamSubscription<dynamic> __u46);
 typedef void __t47<T>(StreamSubscription<T> __u48);
 typedef dynamic __t51(dynamic __u52);
 typedef dynamic __t53<T>(T __u54);
 typedef dynamic __t56(dynamic __u57, StackTrace __u58);
 typedef dynamic __t62(bool __u63);
 typedef bool __t76(dynamic __u77);
 typedef bool __t78<T>(T __u79);
 typedef bool __t86(dynamic __u87, dynamic __u88);
 typedef bool __t89<T>(T __u90, T __u91);
 typedef void __t101();
 typedef void __t103(EventSink<dynamic> __u104);
