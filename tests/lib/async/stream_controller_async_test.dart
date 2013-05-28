// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test the basic StreamController and StreamController.singleSubscription.
library stream_controller_async_test;

import "package:expect/expect.dart";
import 'dart:async';
import 'dart:isolate';
import '../../../pkg/unittest/lib/unittest.dart';
import 'event_helper.dart';

testController() {
  // Test fold
  test("StreamController.fold", () {
    StreamController c = new StreamController();
    Stream stream = c.stream.asBroadcastStream();
    stream.fold(0, (a,b) => a + b)
     .then(expectAsync1((int v) {
        Expect.equals(42, v);
    }));
    c.add(10);
    c.add(32);
    c.close();
  });

  test("StreamController.fold throws", () {
    StreamController c = new StreamController();
    Stream stream = c.stream.asBroadcastStream();
    stream.fold(0, (a,b) { throw "Fnyf!"; })
     .catchError(expectAsync1((error) { Expect.equals("Fnyf!", error); }));
    c.add(42);
  });
}

testSingleController() {
  test("Single-subscription StreamController.fold", () {
    StreamController c = new StreamController();
    Stream stream = c.stream;
    stream.fold(0, (a,b) => a + b)
    .then(expectAsync1((int v) { Expect.equals(42, v); }));
    c.add(10);
    c.add(32);
    c.close();
  });

  test("Single-subscription StreamController.fold throws", () {
    StreamController c = new StreamController();
    Stream stream = c.stream;
    stream.fold(0, (a,b) { throw "Fnyf!"; })
            .catchError(expectAsync1((e) { Expect.equals("Fnyf!", e); }));
    c.add(42);
  });

  test("Single-subscription StreamController events are buffered when"
       " there is no subscriber",
       () {
    StreamController c = new StreamController();
    EventSink sink = c.sink;
    Stream stream = c.stream;
    int counter = 0;
    sink.add(1);
    sink.add(2);
    sink.close();
    stream.listen(
      (data) {
        counter += data;
      },
      onDone: expectAsync0(() {
        Expect.equals(3, counter);
      }));
  });
}

testExtraMethods() {
  Events sentEvents = new Events()..add(7)..add(9)..add(13)..add(87)..close();

  test("forEach", () {
    StreamController c = new StreamController();
    Events actualEvents = new Events();
    Future f = c.stream.forEach(actualEvents.add);
    f.then(expectAsync1((_) {
      actualEvents.close();
      Expect.listEquals(sentEvents.events, actualEvents.events);
    }));
    sentEvents.replay(c);
  });

  test("forEachError", () {
    Events sentEvents = new Events()..add(7)..error("bad")..add(87)..close();
    StreamController c = new StreamController();
    Events actualEvents = new Events();
    Future f = c.stream.forEach(actualEvents.add);
    f.catchError(expectAsync1((error) {
      Expect.equals("bad", error);
      Expect.listEquals((new Events()..add(7)).events, actualEvents.events);
    }));
    sentEvents.replay(c);
  });

  test("forEachError2", () {
    Events sentEvents = new Events()..add(7)..add(9)..add(87)..close();
    StreamController c = new StreamController();
    Events actualEvents = new Events();
    Future f = c.stream.forEach((x) {
      if (x == 9) throw "bad";
      actualEvents.add(x);
    });
    f.catchError(expectAsync1((error) {
      Expect.equals("bad", error);
      Expect.listEquals((new Events()..add(7)).events, actualEvents.events);
    }));
    sentEvents.replay(c);
  });

  test("firstWhere", () {
    StreamController c = new StreamController();
    Future f = c.stream.firstWhere((x) => (x % 3) == 0);
    f.then(expectAsync1((v) { Expect.equals(9, v); }));
    sentEvents.replay(c);
  });

  test("firstWhere 2", () {
    StreamController c = new StreamController();
    Future f = c.stream.firstWhere((x) => (x % 4) == 0);
    f.catchError(expectAsync1((e) {}));
    sentEvents.replay(c);
  });

  test("firstWhere 3", () {
    StreamController c = new StreamController();
    Future f = c.stream.firstWhere((x) => (x % 4) == 0, defaultValue: () => 999);
    f.then(expectAsync1((v) { Expect.equals(999, v); }));
    sentEvents.replay(c);
  });


  test("lastWhere", () {
    StreamController c = new StreamController();
    Future f = c.stream.lastWhere((x) => (x % 3) == 0);
    f.then(expectAsync1((v) { Expect.equals(87, v); }));
    sentEvents.replay(c);
  });

  test("lastWhere 2", () {
    StreamController c = new StreamController();
    Future f = c.stream.lastWhere((x) => (x % 4) == 0);
    f.catchError(expectAsync1((e) {}));
    sentEvents.replay(c);
  });

  test("lastWhere 3", () {
    StreamController c = new StreamController();
    Future f = c.stream.lastWhere((x) => (x % 4) == 0, defaultValue: () => 999);
    f.then(expectAsync1((v) { Expect.equals(999, v); }));
    sentEvents.replay(c);
  });

  test("singleWhere", () {
    StreamController c = new StreamController();
    Future f = c.stream.singleWhere((x) => (x % 9) == 0);
    f.then(expectAsync1((v) { Expect.equals(9, v); }));
    sentEvents.replay(c);
  });

  test("singleWhere 2", () {
    StreamController c = new StreamController();
    Future f = c.stream.singleWhere((x) => (x % 3) == 0);  // Matches 9 and 87..
    f.catchError(expectAsync1((error) { Expect.isTrue(error is StateError); }));
    sentEvents.replay(c);
  });

  test("first", () {
    StreamController c = new StreamController();
    Future f = c.stream.first;
    f.then(expectAsync1((v) { Expect.equals(7, v);}));
    sentEvents.replay(c);
  });

  test("first empty", () {
    StreamController c = new StreamController();
    Future f = c.stream.first;
    f.catchError(expectAsync1((error) { Expect.isTrue(error is StateError); }));
    Events emptyEvents = new Events()..close();
    emptyEvents.replay(c);
  });

  test("first error", () {
    StreamController c = new StreamController();
    Future f = c.stream.first;
    f.catchError(expectAsync1((error) { Expect.equals("error", error); }));
    Events errorEvents = new Events()..error("error")..close();
    errorEvents.replay(c);
  });

  test("first error 2", () {
    StreamController c = new StreamController();
    Future f = c.stream.first;
    f.catchError(expectAsync1((error) { Expect.equals("error", error); }));
    Events errorEvents = new Events()..error("error")..error("error2")..close();
    errorEvents.replay(c);
  });

  test("last", () {
    StreamController c = new StreamController();
    Future f = c.stream.last;
    f.then(expectAsync1((v) { Expect.equals(87, v);}));
    sentEvents.replay(c);
  });

  test("last empty", () {
    StreamController c = new StreamController();
    Future f = c.stream.last;
    f.catchError(expectAsync1((error) { Expect.isTrue(error is StateError); }));
    Events emptyEvents = new Events()..close();
    emptyEvents.replay(c);
  });

  test("last error", () {
    StreamController c = new StreamController();
    Future f = c.stream.last;
    f.catchError(expectAsync1((error) { Expect.equals("error", error); }));
    Events errorEvents = new Events()..error("error")..close();
    errorEvents.replay(c);
  });

  test("last error 2", () {
    StreamController c = new StreamController();
    Future f = c.stream.last;
    f.catchError(expectAsync1((error) { Expect.equals("error", error); }));
    Events errorEvents = new Events()..error("error")..error("error2")..close();
    errorEvents.replay(c);
  });

  test("elementAt", () {
    StreamController c = new StreamController();
    Future f = c.stream.elementAt(2);
    f.then(expectAsync1((v) { Expect.equals(13, v);}));
    sentEvents.replay(c);
  });

  test("elementAt 2", () {
    StreamController c = new StreamController();
    Future f = c.stream.elementAt(20);
    f.catchError(expectAsync1((error) { Expect.isTrue(error is StateError); }));
    sentEvents.replay(c);
  });

  test("drain", () {
    StreamController c = new StreamController();
    Future f = c.stream.drain();
    f.then(expectAsync1((v) { Expect.equals(null, v);}));
    sentEvents.replay(c);
  });

  test("drain error", () {
    StreamController c = new StreamController();
    Future f = c.stream.drain();
    f.catchError(expectAsync1((error) { Expect.equals("error", error); }));
    Events errorEvents = new Events()..error("error")..error("error2")..close();
    errorEvents.replay(c);
  });

}

testPause() {
  test("pause event-unpause", () {
    StreamController c = new StreamController();
    Events actualEvents = new Events.capture(c.stream);
    Events expectedEvents = new Events();
    expectedEvents.add(42);
    c.add(42);
    Expect.listEquals(expectedEvents.events, actualEvents.events);
    Completer completer = new Completer();
    actualEvents.pause(completer.future);
    c..add(43)..add(44)..close();
    Expect.listEquals(expectedEvents.events, actualEvents.events);
    completer.complete();
    expectedEvents..add(43)..add(44)..close();
    actualEvents.onDone(expectAsync0(() {
      Expect.listEquals(expectedEvents.events, actualEvents.events);
    }));
  });

  test("pause twice event-unpause", () {
    StreamController c = new StreamController();
    Events actualEvents = new Events.capture(c.stream);
    Events expectedEvents = new Events();
    expectedEvents.add(42);
    c.add(42);
    Expect.listEquals(expectedEvents.events, actualEvents.events);
    Completer completer = new Completer();
    Completer completer2 = new Completer();
    actualEvents.pause(completer.future);
    actualEvents.pause(completer2.future);
    c..add(43)..add(44)..close();
    Expect.listEquals(expectedEvents.events, actualEvents.events);
    completer.complete();
    Expect.listEquals(expectedEvents.events, actualEvents.events);
    completer2.complete();
    expectedEvents..add(43)..add(44)..close();
    actualEvents.onDone(expectAsync0((){
      Expect.listEquals(expectedEvents.events, actualEvents.events);
    }));
  });

  test("pause twice direct-unpause", () {
    StreamController c = new StreamController();
    Events actualEvents = new Events.capture(c.stream);
    Events expectedEvents = new Events();
    expectedEvents.add(42);
    c.add(42);
    Expect.listEquals(expectedEvents.events, actualEvents.events);
    actualEvents.pause();
    actualEvents.pause();
    c.add(43);
    c.add(44);
    c.close();
    Expect.listEquals(expectedEvents.events, actualEvents.events);
    actualEvents.resume();
    Expect.listEquals(expectedEvents.events, actualEvents.events);
    expectedEvents..add(43)..add(44)..close();
    actualEvents.onDone(expectAsync0(() {
      Expect.listEquals(expectedEvents.events, actualEvents.events);
    }));
    actualEvents.resume();
  });

  test("pause twice direct-event-unpause", () {
    StreamController c = new StreamController();
    Events actualEvents = new Events.capture(c.stream);
    Events expectedEvents = new Events();
    expectedEvents.add(42);
    c.add(42);
    Expect.listEquals(expectedEvents.events, actualEvents.events);
    Completer completer = new Completer();
    actualEvents.pause(completer.future);
    actualEvents.pause();
    c.add(43);
    c.add(44);
    c.close();
    Expect.listEquals(expectedEvents.events, actualEvents.events);
    actualEvents.resume();
    Expect.listEquals(expectedEvents.events, actualEvents.events);
    expectedEvents..add(43)..add(44)..close();
    actualEvents.onDone(expectAsync0(() {
      Expect.listEquals(expectedEvents.events, actualEvents.events);
    }));
    completer.complete();
  });

  test("pause twice direct-unpause", () {
    StreamController c = new StreamController();
    Events actualEvents = new Events.capture(c.stream);
    Events expectedEvents = new Events();
    expectedEvents.add(42);
    c.add(42);
    Expect.listEquals(expectedEvents.events, actualEvents.events);
    Completer completer = new Completer();
    actualEvents.pause(completer.future);
    actualEvents.pause();
    c.add(43);
    c.add(44);
    c.close();
    Expect.listEquals(expectedEvents.events, actualEvents.events);
    completer.complete();
    Expect.listEquals(expectedEvents.events, actualEvents.events);
    expectedEvents..add(43)..add(44)..close();
    actualEvents.onDone(expectAsync0(() {
      Expect.listEquals(expectedEvents.events, actualEvents.events);
    }));
    actualEvents.resume();
  });
}

class TestError { const TestError(); }

testRethrow() {
  TestError error = const TestError();


  testStream(name, streamValueTransform) {
    test("rethrow-$name-value", () {
      StreamController c = new StreamController();
      Stream s = streamValueTransform(c.stream, (v) { throw error; });
      s.listen((_) { Expect.fail("unexpected value"); }, onError: expectAsync1(
          (e) { Expect.identical(error, e); }));
      c.add(null);
      c.close();
    });
  }

  testStreamError(name, streamErrorTransform) {
    test("rethrow-$name-error", () {
      StreamController c = new StreamController();
      Stream s = streamErrorTransform(c.stream, (e) { throw error; });
      s.listen((_) { Expect.fail("unexpected value"); }, onError: expectAsync1(
          (e) { Expect.identical(error, e); }));
      c.addError(null);
      c.close();
    });
  }

  testFuture(name, streamValueTransform) {
    test("rethrow-$name-value", () {
      StreamController c = new StreamController();
      Future f = streamValueTransform(c.stream, (v) { throw error; });
      f.then((v) { Expect.fail("unreachable"); },
             onError: expectAsync1((e) { Expect.identical(error, e); }));
      // Need two values to trigger compare for reduce.
      c.add(0);
      c.add(1);
      c.close();
    });
  }

  testStream("where", (s, act) => s.where(act));
  testStream("map", (s, act) => s.map(act));
  testStream("expand", (s, act) => s.expand(act));
  testStream("where", (s, act) => s.where(act));
  testStreamError("handleError", (s, act) => s.handleError(act));
  testStreamError("handleTest", (s, act) => s.handleError((v) {}, test: act));
  testFuture("forEach", (s, act) => s.forEach(act));
  testFuture("every", (s, act) => s.every(act));
  testFuture("any", (s, act) => s.any(act));
  testFuture("reduce", (s, act) => s.reduce((a,b) => act(b)));
  testFuture("fold", (s, act) => s.fold(0, (a,b) => act(b)));
  testFuture("drain", (s, act) => s.drain().then(act));
}

void testBroadcastController() {
  test("broadcast-controller-basic", () {
    StreamController<int> c = new StreamController.broadcast(
      onListen: expectAsync0(() {}),
      onCancel: expectAsync0(() {})
    );
    Stream<int> s = c.stream;
    s.listen(expectAsync1((x) { expect(x, equals(42)); }));
    c.add(42);
    c.close();
  });

  test("broadcast-controller-listen-twice", () {
    StreamController<int> c = new StreamController.broadcast(
      onListen: expectAsync0(() {}),
      onCancel: expectAsync0(() {})
    );
    c.stream.listen(expectAsync1((x) { expect(x, equals(42)); }, count: 2));
    c.add(42);
    c.stream.listen(expectAsync1((x) { expect(x, equals(42)); }));
    c.add(42);
    c.close();
  });

  test("broadcast-controller-listen-twice-non-overlap", () {
    StreamController<int> c = new StreamController.broadcast(
      onListen: expectAsync0(() {}, count: 2),
      onCancel: expectAsync0(() {}, count: 2)
    );
    var sub = c.stream.listen(expectAsync1((x) { expect(x, equals(42)); }));
    c.add(42);
    sub.cancel();
    c.stream.listen(expectAsync1((x) { expect(x, equals(42)); }));
    c.add(42);
    c.close();
  });

  test("broadcast-controller-individual-pause", () {
    StreamController<int> c = new StreamController.broadcast(
      onListen: expectAsync0(() {}),
      onCancel: expectAsync0(() {})
    );
    var sub1 = c.stream.listen(expectAsync1((x) { expect(x, equals(42)); }));
    var sub2 = c.stream.listen(expectAsync1((x) { expect(x, equals(42)); },
                                            count: 3));
    c.add(42);
    sub1.pause();
    c.add(42);
    sub1.cancel();
    var sub3 = c.stream.listen(expectAsync1((x) { expect(x, equals(42)); }));
    c.add(42);
    c.close();
  });
}

main() {
  testController();
  testSingleController();
  testExtraMethods();
  testPause();
  testRethrow();
  testBroadcastController();
}
