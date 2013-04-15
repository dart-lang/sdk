// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test the basic StreamController and StreamController.singleSubscription.
library stream_controller_test;

import "package:expect/expect.dart";
import 'dart:async';
import 'event_helper.dart';

testMultiController() {
  // Test normal flow.
  var c = new StreamController();
  Events expectedEvents = new Events()
      ..add(42)
      ..add("dibs")
      ..error("error!")
      ..error("error too!")
      ..close();
  Events actualEvents = new Events.capture(c.stream.asBroadcastStream());
  expectedEvents.replay(c);
  Expect.listEquals(expectedEvents.events, actualEvents.events);

  // Test automatic unsubscription on error.
  c = new StreamController();
  expectedEvents = new Events()..add(42)..error("error");
  actualEvents = new Events.capture(c.stream.asBroadcastStream(),
                                    cancelOnError: true);
  Events sentEvents =
      new Events()..add(42)..error("error")..add("Are you there?");
  sentEvents.replay(c);
  Expect.listEquals(expectedEvents.events, actualEvents.events);

  // Test manual unsubscription.
  c = new StreamController();
  expectedEvents = new Events()..add(42)..error("error")..add(37);
  actualEvents = new Events.capture(c.stream.asBroadcastStream(),
                                    cancelOnError: false);
  expectedEvents.replay(c);
  actualEvents.subscription.cancel();
  c.add("Are you there");  // Not sent to actualEvents.
  Expect.listEquals(expectedEvents.events, actualEvents.events);

  // Test filter.
  c = new StreamController();
  expectedEvents = new Events()
    ..add("a string")..add("another string")..close();
  sentEvents = new Events()
    ..add("a string")..add(42)..add("another string")..close();
  actualEvents = new Events.capture(c.stream
    .asBroadcastStream()
    .where((v) => v is String));
  sentEvents.replay(c);
  Expect.listEquals(expectedEvents.events, actualEvents.events);

  // Test map.
  c = new StreamController();
  expectedEvents = new Events()..add("abab")..error("error")..close();
  sentEvents = new Events()..add("ab")..error("error")..close();
  actualEvents = new Events.capture(c.stream
    .asBroadcastStream()
    .map((v) => "$v$v"));
  sentEvents.replay(c);
  Expect.listEquals(expectedEvents.events, actualEvents.events);

  // Test handleError.
  c = new StreamController();
  expectedEvents = new Events()..add("ab")..error("[foo]");
  sentEvents = new Events()..add("ab")..error("foo")..add("ab")..close();
  actualEvents = new Events.capture(c.stream
    .asBroadcastStream()
    .handleError((error) {
        if (error is String) {
          // TODO(floitsch): this test originally changed the stacktrace.
          throw "[${error}]";
        }
      }), cancelOnError: true);
  sentEvents.replay(c);
  Expect.listEquals(expectedEvents.events, actualEvents.events);

  // reduce is tested asynchronously and therefore not in this file.

  // Test expand
  c = new StreamController();
  sentEvents = new Events()..add(3)..add(2)..add(4)..close();
  expectedEvents = new Events()..add(1)..add(2)..add(3)
                               ..add(1)..add(2)
                               ..add(1)..add(2)..add(3)..add(4)
                               ..close();
  actualEvents = new Events.capture(c.stream.asBroadcastStream().expand((v) {
    var l = [];
    for (int i = 0; i < v; i++) l.add(i + 1);
    return l;
  }));
  sentEvents.replay(c);
  Expect.listEquals(expectedEvents.events, actualEvents.events);

  // Test transform.
  c = new StreamController();
  sentEvents = new Events()..add("a")..error(42)..add("b")..close();
  expectedEvents =
      new Events()..error("a")..add(42)..error("b")..add("foo")..close();
  actualEvents = new Events.capture(c.stream.asBroadcastStream().transform(
      new StreamTransformer(
          handleData: (v, s) { s.addError(v); },
          handleError: (e, s) { s.add(e); },
          handleDone: (s) {

            s.add("foo");

            s.close();

          })));
  sentEvents.replay(c);
  Expect.listEquals(expectedEvents.events, actualEvents.events);

  // Test multiple filters.
  c = new StreamController();
  sentEvents = new Events()..add(42)
                           ..add("snugglefluffy")
                           ..add(7)
                           ..add("42")
                           ..error("not FormatException")  // Unsubscribes.
                           ..close();
  expectedEvents = new Events()..add(42)..error("not FormatException");
  actualEvents = new Events.capture(
      c.stream.asBroadcastStream().where((v) => v is String)
       .map((v) => int.parse(v))
       .handleError((error) {
          if (error is! FormatException) throw error;
        })
       .where((v) => v > 10),
      cancelOnError: true);
  sentEvents.replay(c);
  Expect.listEquals(expectedEvents.events, actualEvents.events);

  // Test subscription changes while firing.
  c = new StreamController();
  var sink = c.sink;
  var stream = c.stream.asBroadcastStream();
  var counter = 0;
  var subscription = stream.listen(null);
  subscription.onData((data) {
    counter += data;
    subscription.cancel();
    stream.listen((data) {
      counter += 10 * data;
    });
    var subscription2 = stream.listen(null);
    subscription2.onData((data) {
      counter += 100 * data;
      if (data == 4) subscription2.cancel();
    });
  });
  sink.add(1); // seen by stream 1
  sink.add(2); // seen by stream 10 and 100
  sink.add(3); // -"-
  sink.add(4); // -"-
  sink.add(5); // seen by stream 10
  Expect.equals(1 + 20 + 200 + 30 + 300 + 40 + 400 + 50, counter);
}

testSingleController() {
  // Test normal flow.
  var c = new StreamController();
  Events expectedEvents = new Events()
      ..add(42)
      ..add("dibs")
      ..error("error!")
      ..error("error too!")
      ..close();
  Events actualEvents = new Events.capture(c.stream);
  expectedEvents.replay(c);
  Expect.listEquals(expectedEvents.events, actualEvents.events);

  // Test automatic unsubscription on error.
  c = new StreamController();
  expectedEvents = new Events()..add(42)..error("error");
  actualEvents = new Events.capture(c.stream, cancelOnError: true);
  Events sentEvents =
      new Events()..add(42)..error("error")..add("Are you there?");
  sentEvents.replay(c);
  Expect.listEquals(expectedEvents.events, actualEvents.events);

  // Test manual unsubscription.
  c = new StreamController();
  expectedEvents = new Events()..add(42)..error("error")..add(37);
  actualEvents = new Events.capture(c.stream, cancelOnError: false);
  expectedEvents.replay(c);
  actualEvents.subscription.cancel();
  c.add("Are you there");  // Not sent to actualEvents.
  Expect.listEquals(expectedEvents.events, actualEvents.events);

  // Test filter.
  c = new StreamController();
  expectedEvents = new Events()
    ..add("a string")..add("another string")..close();
  sentEvents = new Events()
    ..add("a string")..add(42)..add("another string")..close();
  actualEvents = new Events.capture(c.stream.where((v) => v is String));
  sentEvents.replay(c);
  Expect.listEquals(expectedEvents.events, actualEvents.events);

  // Test map.
  c = new StreamController();
  expectedEvents = new Events()..add("abab")..error("error")..close();
  sentEvents = new Events()..add("ab")..error("error")..close();
  actualEvents = new Events.capture(c.stream.map((v) => "$v$v"));
  sentEvents.replay(c);
  Expect.listEquals(expectedEvents.events, actualEvents.events);

  // Test handleError.
  c = new StreamController();
  expectedEvents = new Events()..add("ab")..error("[foo]");
  sentEvents = new Events()..add("ab")..error("foo")..add("ab")..close();
  actualEvents = new Events.capture(c.stream.handleError((error) {
        if (error is String) {
          // TODO(floitsch): this error originally changed the stack trace.
          throw "[${error}]";
        }
      }), cancelOnError: true);
  sentEvents.replay(c);
  Expect.listEquals(expectedEvents.events, actualEvents.events);

  // reduce is tested asynchronously and therefore not in this file.

  // Test expand
  c = new StreamController();
  sentEvents = new Events()..add(3)..add(2)..add(4)..close();
  expectedEvents = new Events()..add(1)..add(2)..add(3)
                               ..add(1)..add(2)
                               ..add(1)..add(2)..add(3)..add(4)
                               ..close();
  actualEvents = new Events.capture(c.stream.expand((v) {
    var l = [];
    for (int i = 0; i < v; i++) l.add(i + 1);
    return l;
  }));
  sentEvents.replay(c);
  Expect.listEquals(expectedEvents.events, actualEvents.events);

  // test contains.
  {
    c = new StreamController();
    // Error after match is not important.
    sentEvents = new Events()..add("a")..add("x")..error("FAIL")..close();
    Future<bool> contains = c.stream.contains("x");
    contains.then((var c) {
      Expect.isTrue(c);
    });
    sentEvents.replay(c);
  }

  {
    c = new StreamController();
    // Not matching is ok.
    sentEvents = new Events()..add("a")..add("x")..add("b")..close();
    Future<bool> contains = c.stream.contains("y");
    contains.then((var c) {
      Expect.isFalse(c);
    });
    sentEvents.replay(c);
  }

  {
    c = new StreamController();
    // Error before match makes future err.
    sentEvents = new Events()..add("a")..error("FAIL")..add("b")..close();
    Future<bool> contains = c.stream.contains("b");
    contains.then((var c) {
      Expect.fail("no value expected");
    }).catchError((error) {
      Expect.equals("FAIL", error);
    });
    sentEvents.replay(c);
  }

  // Test transform.
  c = new StreamController();
  sentEvents = new Events()..add("a")..error(42)..add("b")..close();
  expectedEvents =
      new Events()..error("a")..add(42)..error("b")..add("foo")..close();
  actualEvents = new Events.capture(c.stream.transform(
      new StreamTransformer(
          handleData: (v, s) { s.addError(v); },
          handleError: (e, s) { s.add(e); },
          handleDone: (s) {
            s.add("foo");
            s.close();
          })));
  sentEvents.replay(c);
  Expect.listEquals(expectedEvents.events, actualEvents.events);

  // Test multiple filters.
  c = new StreamController();
  sentEvents = new Events()..add(42)
                           ..add("snugglefluffy")
                           ..add(7)
                           ..add("42")
                           ..error("not FormatException")  // Unsubscribes.
                           ..close();
  expectedEvents = new Events()..add(42)..error("not FormatException");
  actualEvents = new Events.capture(
      c.stream.where((v) => v is String)
       .map((v) => int.parse(v))
       .handleError((error) {
          if (error is! FormatException) throw error;
        })
       .where((v) => v > 10),
      cancelOnError: true);
  sentEvents.replay(c);
  Expect.listEquals(expectedEvents.events, actualEvents.events);

  // Test that only one subscription is allowed.
  c = new StreamController();
  var sink = c.sink;
  var stream = c.stream;
  var counter = 0;
  var subscription = stream.listen((data) { counter += data; });
  Expect.throws(() => stream.listen(null), (e) => e is StateError);
  sink.add(1);
  Expect.equals(1, counter);
  c.close();
}

testExtraMethods() {
  Events sentEvents = new Events()..add(1)..add(2)..add(3)..close();

  var c = new StreamController();
  Events expectedEvents = new Events()..add(3)..close();
  Events actualEvents = new Events.capture(c.stream.skip(2));
  sentEvents.replay(c);
  Expect.listEquals(expectedEvents.events, actualEvents.events);

  c = new StreamController();
  expectedEvents = new Events()..close();
  actualEvents = new Events.capture(c.stream.skip(3));
  sentEvents.replay(c);
  Expect.listEquals(expectedEvents.events, actualEvents.events);

  c = new StreamController();
  expectedEvents = new Events()..close();
  actualEvents = new Events.capture(c.stream.skip(7));
  sentEvents.replay(c);
  Expect.listEquals(expectedEvents.events, actualEvents.events);

  c = new StreamController();
  expectedEvents = sentEvents;
  actualEvents = new Events.capture(c.stream.skip(0));
  sentEvents.replay(c);
  Expect.listEquals(expectedEvents.events, actualEvents.events);


  c = new StreamController();
  expectedEvents = new Events()..add(3)..close();
  actualEvents = new Events.capture(c.stream.skipWhile((x) => x <= 2));
  sentEvents.replay(c);
  Expect.listEquals(expectedEvents.events, actualEvents.events);


  c = new StreamController();
  expectedEvents = new Events()..add(1)..add(2)..close();
  actualEvents = new Events.capture(c.stream.take(2));
  sentEvents.replay(c);
  Expect.listEquals(expectedEvents.events, actualEvents.events);


  c = new StreamController();
  expectedEvents = new Events()..add(1)..add(2)..close();
  actualEvents = new Events.capture(c.stream.takeWhile((x) => x <= 2));
  sentEvents.replay(c);
  Expect.listEquals(expectedEvents.events, actualEvents.events);


  c = new StreamController();
  sentEvents = new Events()
      ..add(1)..add(1)..add(2)..add(1)..add(2)..add(2)..add(2)..close();
  expectedEvents = new Events()
      ..add(1)..add(2)..add(1)..add(2)..close();
  actualEvents = new Events.capture(c.stream.distinct());
  sentEvents.replay(c);
  Expect.listEquals(expectedEvents.events, actualEvents.events);


  c = new StreamController();
  sentEvents = new Events()
      ..add(5)..add(6)..add(4)..add(6)..add(8)..add(3)..add(4)..add(1)..close();
  expectedEvents = new Events()
      ..add(5)..add(4)..add(3)..add(1)..close();
  // Use 'distinct' as a filter with access to the previously emitted event.
  actualEvents = new Events.capture(c.stream.distinct((a, b) => a < b));
  sentEvents.replay(c);
  Expect.listEquals(expectedEvents.events, actualEvents.events);
}

testClosed() {
  StreamController c = new StreamController();
  Expect.isFalse(c.isClosed);
  c.add(42);
  Expect.isFalse(c.isClosed);
  c.addError("bad");
  Expect.isFalse(c.isClosed);
  c.close();
  Expect.isTrue(c.isClosed);
}

main() {
  testMultiController();
  testSingleController();
  testExtraMethods();
  testClosed();
}
