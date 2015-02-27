part of dart.async;
 abstract class Stream<T> {Stream();
 factory Stream.fromFuture(Future<T> future) {
  _StreamController<T> controller = ((__x37) => DDC$RT.cast(__x37, DDC$RT.type((StreamController<T> _) {
    }
  ), DDC$RT.type((_StreamController<T> _) {
    }
  ), "CastExact", """line 87, column 39 of dart:async/stream.dart: """, __x37 is _StreamController<T>, false))(new StreamController<T>(sync: true));
   future.then((value) {
    controller._add(DDC$RT.cast(value, dynamic, T, "CastGeneral", """line 89, column 25 of dart:async/stream.dart: """, value is T, false));
     controller._closeUnchecked();
    }
  , onError: (error, stackTrace) {
    controller._addError(error, DDC$RT.cast(stackTrace, dynamic, StackTrace, "CastGeneral", """line 93, column 37 of dart:async/stream.dart: """, stackTrace is StackTrace, true));
     controller._closeUnchecked();
    }
  );
   return controller.stream;
  }
 factory Stream.fromIterable(Iterable<T> data) {
  return new _GeneratedStreamImpl<T>(() => new _IterablePendingEvents<T>(data));
  }
 factory Stream.periodic(Duration period, [T computation(int computationCount)]) {
  if (computation == null) computation = ((__x44) => DDC$RT.wrap((dynamic f(dynamic __u39)) {
    dynamic c(dynamic x0) => ((__x38) => DDC$RT.cast(__x38, Null, T, "CastResult", """line 126, column 44 of dart:async/stream.dart: """, __x38 is T, false))(f(x0));
     return f == null ? null : c;
    }
  , __x44, __t42, DDC$RT.type((__t40<T> _) {
    }
  ), "Wrap", """line 126, column 44 of dart:async/stream.dart: """, __x44 is __t40<T>))(((i) => null));
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
  return ((__x45) => DDC$RT.cast(__x45, DDC$RT.type((_BoundSinkStream<dynamic, dynamic> _) {
    }
  ), DDC$RT.type((Stream<T> _) {
    }
  ), "CastExact", """line 216, column 12 of dart:async/stream.dart: """, __x45 is Stream<T>, false))(new _BoundSinkStream(source, DDC$RT.wrap((EventSink<dynamic> f(EventSink<T> __u46)) {
    EventSink<dynamic> c(EventSink<T> x0) => f(DDC$RT.cast(x0, DDC$RT.type((EventSink<dynamic> _) {
      }
    ), DDC$RT.type((EventSink<T> _) {
      }
    ), "CastParam", """line 216, column 41 of dart:async/stream.dart: """, x0 is EventSink<T>, false));
     return f == null ? null : c;
    }
  , mapSink, DDC$RT.type((__t49<T> _) {
    }
  ), __t47, "Wrap", """line 216, column 41 of dart:async/stream.dart: """, mapSink is __t47)));
  }
 bool get isBroadcast => false;
 Stream<T> asBroadcastStream({
  void onListen(StreamSubscription<T> subscription), void onCancel(StreamSubscription<T> subscription)}
) {
  return new _AsBroadcastStream<T>(this, DDC$RT.wrap((void f(StreamSubscription<T> __u51)) {
    void c(StreamSubscription<T> x0) => f(DDC$RT.cast(x0, DDC$RT.type((StreamSubscription<dynamic> _) {
      }
    ), DDC$RT.type((StreamSubscription<T> _) {
      }
    ), "CastParam", """line 248, column 44 of dart:async/stream.dart: """, x0 is StreamSubscription<T>, false));
     return f == null ? null : c;
    }
  , onListen, DDC$RT.type((__t54<T> _) {
    }
  ), __t52, "Wrap", """line 248, column 44 of dart:async/stream.dart: """, onListen is __t52), DDC$RT.wrap((void f(StreamSubscription<T> __u56)) {
    void c(StreamSubscription<T> x0) => f(DDC$RT.cast(x0, DDC$RT.type((StreamSubscription<dynamic> _) {
      }
    ), DDC$RT.type((StreamSubscription<T> _) {
      }
    ), "CastParam", """line 248, column 54 of dart:async/stream.dart: """, x0 is StreamSubscription<T>, false));
     return f == null ? null : c;
    }
  , onCancel, DDC$RT.type((__t54<T> _) {
    }
  ), __t52, "Wrap", """line 248, column 54 of dart:async/stream.dart: """, onCancel is __t52));
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
    , onError: DDC$RT.cast(addError, dynamic, Function, "CastGeneral", """line 338, column 20 of dart:async/stream.dart: """, addError is Function, true), onDone: controller.close);
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
    , onError: DDC$RT.cast(eventSink._addError, dynamic, Function, "CastGeneral", """line 395, column 20 of dart:async/stream.dart: """, eventSink._addError is Function, true), onDone: controller.close);
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
      _runUserCode(() => combine(value, element), ((__x62) => DDC$RT.wrap((dynamic f(T __u57)) {
        dynamic c(T x0) => f(DDC$RT.cast(x0, dynamic, T, "CastParam", """line 500, column 24 of dart:async/stream.dart: """, x0 is T, false));
         return f == null ? null : c;
        }
      , __x62, DDC$RT.type((__t60<T> _) {
        }
      ), __t58, "WrapLiteral", """line 500, column 24 of dart:async/stream.dart: """, __x62 is __t58))((T newValue) {
        value = newValue;
        }
      ), ((__x66) => DDC$RT.cast(__x66, dynamic, __t63, "CastGeneral", """line 501, column 24 of dart:async/stream.dart: """, __x66 is __t63, false))(_cancelAndErrorClosure(subscription, result)));
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
    , ((__x67) => DDC$RT.cast(__x67, dynamic, __t63, "CastGeneral", """line 534, column 11 of dart:async/stream.dart: """, __x67 is __t63, false))(_cancelAndErrorClosure(subscription, result)));
    }
  , onError: (e, st) {
    result._completeError(e, DDC$RT.cast(st, dynamic, StackTrace, "CastGeneral", """line 538, column 34 of dart:async/stream.dart: """, st is StackTrace, true));
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
    _runUserCode(() => (element == needle), ((__x71) => DDC$RT.wrap((dynamic f(bool __u68)) {
      dynamic c(bool x0) => f(DDC$RT.cast(x0, dynamic, bool, "CastParam", """line 597, column 13 of dart:async/stream.dart: """, x0 is bool, true));
       return f == null ? null : c;
      }
    , __x71, __t69, __t58, "WrapLiteral", """line 597, column 13 of dart:async/stream.dart: """, __x71 is __t58))((bool isMatch) {
      if (isMatch) {
        _cancelAndValue(subscription, future, true);
        }
      }
    ), ((__x72) => DDC$RT.cast(__x72, dynamic, __t63, "CastGeneral", """line 602, column 13 of dart:async/stream.dart: """, __x72 is __t63, false))(_cancelAndErrorClosure(subscription, future)));
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
    , ((__x73) => DDC$RT.cast(__x73, dynamic, __t63, "CastGeneral", """line 628, column 13 of dart:async/stream.dart: """, __x73 is __t63, false))(_cancelAndErrorClosure(subscription, future)));
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
    _runUserCode(() => test(element), ((__x75) => DDC$RT.wrap((dynamic f(bool __u74)) {
      dynamic c(bool x0) => f(DDC$RT.cast(x0, dynamic, bool, "CastParam", """line 652, column 13 of dart:async/stream.dart: """, x0 is bool, true));
       return f == null ? null : c;
      }
    , __x75, __t69, __t58, "WrapLiteral", """line 652, column 13 of dart:async/stream.dart: """, __x75 is __t58))((bool isMatch) {
      if (!isMatch) {
        _cancelAndValue(subscription, future, false);
        }
      }
    ), ((__x76) => DDC$RT.cast(__x76, dynamic, __t63, "CastGeneral", """line 657, column 13 of dart:async/stream.dart: """, __x76 is __t63, false))(_cancelAndErrorClosure(subscription, future)));
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
    _runUserCode(() => test(element), ((__x78) => DDC$RT.wrap((dynamic f(bool __u77)) {
      dynamic c(bool x0) => f(DDC$RT.cast(x0, dynamic, bool, "CastParam", """line 689, column 13 of dart:async/stream.dart: """, x0 is bool, true));
       return f == null ? null : c;
      }
    , __x78, __t69, __t58, "WrapLiteral", """line 689, column 13 of dart:async/stream.dart: """, __x78 is __t58))((bool isMatch) {
      if (isMatch) {
        _cancelAndValue(subscription, future, true);
        }
      }
    ), ((__x79) => DDC$RT.cast(__x79, dynamic, __t63, "CastGeneral", """line 694, column 13 of dart:async/stream.dart: """, __x79 is __t63, false))(_cancelAndErrorClosure(subscription, future)));
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
  return ((__x80) => DDC$RT.cast(__x80, DDC$RT.type((_TakeStream<dynamic> _) {
    }
  ), DDC$RT.type((Stream<T> _) {
    }
  ), "CastExact", """line 819, column 12 of dart:async/stream.dart: """, __x80 is Stream<T>, false))(new _TakeStream(this, count));
  }
 Stream<T> takeWhile(bool test(T element)) {
  return ((__x81) => DDC$RT.cast(__x81, DDC$RT.type((_TakeWhileStream<dynamic> _) {
    }
  ), DDC$RT.type((Stream<T> _) {
    }
  ), "CastExact", """line 841, column 12 of dart:async/stream.dart: """, __x81 is Stream<T>, false))(new _TakeWhileStream(this, DDC$RT.wrap((bool f(T __u82)) {
    bool c(T x0) => f(DDC$RT.cast(x0, dynamic, T, "CastParam", """line 841, column 39 of dart:async/stream.dart: """, x0 is T, false));
     return f == null ? null : c;
    }
  , test, DDC$RT.type((__t85<T> _) {
    }
  ), __t83, "Wrap", """line 841, column 39 of dart:async/stream.dart: """, test is __t83)));
  }
 Stream<T> skip(int count) {
  return ((__x87) => DDC$RT.cast(__x87, DDC$RT.type((_SkipStream<dynamic> _) {
    }
  ), DDC$RT.type((Stream<T> _) {
    }
  ), "CastExact", """line 852, column 12 of dart:async/stream.dart: """, __x87 is Stream<T>, false))(new _SkipStream(this, count));
  }
 Stream<T> skipWhile(bool test(T element)) {
  return ((__x88) => DDC$RT.cast(__x88, DDC$RT.type((_SkipWhileStream<dynamic> _) {
    }
  ), DDC$RT.type((Stream<T> _) {
    }
  ), "CastExact", """line 868, column 12 of dart:async/stream.dart: """, __x88 is Stream<T>, false))(new _SkipWhileStream(this, DDC$RT.wrap((bool f(T __u89)) {
    bool c(T x0) => f(DDC$RT.cast(x0, dynamic, T, "CastParam", """line 868, column 39 of dart:async/stream.dart: """, x0 is T, false));
     return f == null ? null : c;
    }
  , test, DDC$RT.type((__t85<T> _) {
    }
  ), __t83, "Wrap", """line 868, column 39 of dart:async/stream.dart: """, test is __t83)));
  }
 Stream<T> distinct([bool equals(T previous, T next)]) {
  return ((__x90) => DDC$RT.cast(__x90, DDC$RT.type((_DistinctStream<dynamic> _) {
    }
  ), DDC$RT.type((Stream<T> _) {
    }
  ), "CastExact", """line 885, column 12 of dart:async/stream.dart: """, __x90 is Stream<T>, false))(new _DistinctStream(this, DDC$RT.wrap((bool f(T __u91, T __u92)) {
    bool c(T x0, T x1) => f(DDC$RT.cast(x0, dynamic, T, "CastParam", """line 885, column 38 of dart:async/stream.dart: """, x0 is T, false), DDC$RT.cast(x1, dynamic, T, "CastParam", """line 885, column 38 of dart:async/stream.dart: """, x1 is T, false));
     return f == null ? null : c;
    }
  , equals, DDC$RT.type((__t96<T> _) {
    }
  ), __t93, "Wrap", """line 885, column 38 of dart:async/stream.dart: """, equals is __t93)));
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
   T result = ((__x99) => DDC$RT.cast(__x99, Null, T, "CastLiteral", """line 936, column 16 of dart:async/stream.dart: """, __x99 is T, false))(null);
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
   T result = ((__x100) => DDC$RT.cast(__x100, Null, T, "CastLiteral", """line 970, column 16 of dart:async/stream.dart: """, __x100 is T, false))(null);
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
    _runUserCode(() => test(value), ((__x102) => DDC$RT.wrap((dynamic f(bool __u101)) {
      dynamic c(bool x0) => f(DDC$RT.cast(x0, dynamic, bool, "CastParam", """line 1031, column 11 of dart:async/stream.dart: """, x0 is bool, true));
       return f == null ? null : c;
      }
    , __x102, __t69, __t58, "WrapLiteral", """line 1031, column 11 of dart:async/stream.dart: """, __x102 is __t58))((bool isMatch) {
      if (isMatch) {
        _cancelAndValue(subscription, future, value);
        }
      }
    ), ((__x103) => DDC$RT.cast(__x103, dynamic, __t63, "CastGeneral", """line 1036, column 11 of dart:async/stream.dart: """, __x103 is __t63, false))(_cancelAndErrorClosure(subscription, future)));
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
   T result = ((__x104) => DDC$RT.cast(__x104, Null, T, "CastLiteral", """line 1064, column 16 of dart:async/stream.dart: """, __x104 is T, false))(null);
   bool foundResult = false;
   StreamSubscription subscription;
   subscription = this.listen((T value) {
    _runUserCode(() => true == test(value), ((__x106) => DDC$RT.wrap((dynamic f(bool __u105)) {
      dynamic c(bool x0) => f(DDC$RT.cast(x0, dynamic, bool, "CastParam", """line 1071, column 11 of dart:async/stream.dart: """, x0 is bool, true));
       return f == null ? null : c;
      }
    , __x106, __t69, __t58, "WrapLiteral", """line 1071, column 11 of dart:async/stream.dart: """, __x106 is __t58))((bool isMatch) {
      if (isMatch) {
        foundResult = true;
         result = value;
        }
      }
    ), ((__x107) => DDC$RT.cast(__x107, dynamic, __t63, "CastGeneral", """line 1077, column 11 of dart:async/stream.dart: """, __x107 is __t63, false))(_cancelAndErrorClosure(subscription, future)));
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
   T result = ((__x108) => DDC$RT.cast(__x108, Null, T, "CastLiteral", """line 1108, column 16 of dart:async/stream.dart: """, __x108 is T, false))(null);
   bool foundResult = false;
   StreamSubscription subscription;
   subscription = this.listen((T value) {
    _runUserCode(() => true == test(value), ((__x110) => DDC$RT.wrap((dynamic f(bool __u109)) {
      dynamic c(bool x0) => f(DDC$RT.cast(x0, dynamic, bool, "CastParam", """line 1115, column 11 of dart:async/stream.dart: """, x0 is bool, true));
       return f == null ? null : c;
      }
    , __x110, __t69, __t58, "WrapLiteral", """line 1115, column 11 of dart:async/stream.dart: """, __x110 is __t58))((bool isMatch) {
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
    ), ((__x111) => DDC$RT.cast(__x111, dynamic, __t63, "CastGeneral", """line 1129, column 11 of dart:async/stream.dart: """, __x111 is __t63, false))(_cancelAndErrorClosure(subscription, future)));
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
     timer = zone.createTimer(timeLimit, DDC$RT.cast(timeout, Function, __t112, "CastGeneral", """line 1219, column 43 of dart:async/stream.dart: """, timeout is __t112, false));
    }
   void onError(error, StackTrace stackTrace) {
    timer.cancel();
     assert (controller is _StreamController || controller is _BroadcastStreamController); var eventSink = controller;
     eventSink._addError(error, stackTrace);
     timer = zone.createTimer(timeLimit, DDC$RT.cast(timeout, Function, __t112, "CastGeneral", """line 1227, column 43 of dart:async/stream.dart: """, timeout is __t112, false));
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
      onTimeout = zone.registerUnaryCallback(DDC$RT.wrap((void f(EventSink<dynamic> __u113)) {
        void c(EventSink<dynamic> x0) => f(DDC$RT.cast(x0, dynamic, DDC$RT.type((EventSink<dynamic> _) {
          }
        ), "CastParam", """line 1245, column 48 of dart:async/stream.dart: """, x0 is EventSink<dynamic>, true));
         return f == null ? null : c;
        }
      , onTimeout, __t114, __t58, "Wrap", """line 1245, column 48 of dart:async/stream.dart: """, onTimeout is __t58));
       _ControllerEventSinkWrapper wrapper = new _ControllerEventSinkWrapper(null);
       timeout = () {
        wrapper._sink = controller;
         zone.runUnaryGuarded(DDC$RT.wrap((void f(EventSink<dynamic> __u116)) {
          void c(EventSink<dynamic> x0) => f(DDC$RT.cast(x0, dynamic, DDC$RT.type((EventSink<dynamic> _) {
            }
          ), "CastParam", """line 1250, column 32 of dart:async/stream.dart: """, x0 is EventSink<dynamic>, true));
           return f == null ? null : c;
          }
        , onTimeout, __t114, __t58, "Wrap", """line 1250, column 32 of dart:async/stream.dart: """, onTimeout is __t58), wrapper);
         wrapper._sink = null;
        }
      ;
      }
     subscription = this.listen(onData, onError: onError, onDone: onDone);
     timer = zone.createTimer(timeLimit, DDC$RT.cast(timeout, Function, __t112, "CastGeneral", """line 1256, column 43 of dart:async/stream.dart: """, timeout is __t112, false));
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
     timer = zone.createTimer(timeLimit, DDC$RT.cast(timeout, Function, __t112, "CastGeneral", """line 1275, column 53 of dart:async/stream.dart: """, timeout is __t112, false));
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
 typedef T __t40<T>(int __u41);
 typedef dynamic __t42(dynamic __u43);
 typedef EventSink<dynamic> __t47(EventSink<dynamic> __u48);
 typedef EventSink<dynamic> __t49<T>(EventSink<T> __u50);
 typedef void __t52(StreamSubscription<dynamic> __u53);
 typedef void __t54<T>(StreamSubscription<T> __u55);
 typedef dynamic __t58(dynamic __u59);
 typedef dynamic __t60<T>(T __u61);
 typedef dynamic __t63(dynamic __u64, StackTrace __u65);
 typedef dynamic __t69(bool __u70);
 typedef bool __t83(dynamic __u84);
 typedef bool __t85<T>(T __u86);
 typedef bool __t93(dynamic __u94, dynamic __u95);
 typedef bool __t96<T>(T __u97, T __u98);
 typedef void __t112();
 typedef void __t114(EventSink<dynamic> __u115);
