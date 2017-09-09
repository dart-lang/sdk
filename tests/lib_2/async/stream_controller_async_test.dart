// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test the basic StreamController and StreamController.broadcast.
library stream_controller_async_test;

import 'dart:async';
import "package:expect/expect.dart";
import 'package:test/test.dart';
import 'event_helper.dart';
import 'stream_state_helper.dart';

void cancelSub(StreamSubscription sub) {
  sub.cancel();
}

testController() {
  // Test fold
  test("StreamController.fold", () {
    StreamController c = new StreamController();
    Stream stream = c.stream.asBroadcastStream(onCancel: cancelSub);
    stream.fold(0, (a, b) => a + b).then(expectAsync((int v) {
      Expect.equals(42, v);
    }));
    c.add(10);
    c.add(32);
    c.close();
  });

  test("StreamController.fold throws", () {
    StreamController c = new StreamController();
    Stream stream = c.stream.asBroadcastStream(onCancel: cancelSub);
    stream.fold(0, (a, b) {
      throw "Fnyf!";
    }).catchError(expectAsync((error) {
      Expect.equals("Fnyf!", error);
    }));
    c.add(42);
  });
}

testSingleController() {
  test("Single-subscription StreamController.fold", () {
    StreamController c = new StreamController();
    Stream stream = c.stream;
    stream.fold(0, (a, b) => a + b).then(expectAsync((int v) {
      Expect.equals(42, v);
    }));
    c.add(10);
    c.add(32);
    c.close();
  });

  test("Single-subscription StreamController.fold throws", () {
    StreamController c = new StreamController();
    Stream stream = c.stream;
    stream.fold(0, (a, b) {
      throw "Fnyf!";
    }).catchError(expectAsync((e) {
      Expect.equals("Fnyf!", e);
    }));
    c.add(42);
  });

  test(
      "Single-subscription StreamController events are buffered when"
      " there is no subscriber", () {
    StreamController c = new StreamController();
    EventSink sink = c.sink;
    Stream stream = c.stream;
    int counter = 0;
    sink.add(1);
    sink.add(2);
    sink.close();
    stream.listen((data) {
      counter += data;
    }, onDone: expectAsync(() {
      Expect.equals(3, counter);
    }));
  });
}

testExtraMethods() {
  Events sentEvents = new Events()
    ..add(7)
    ..add(9)
    ..add(13)
    ..add(87)
    ..close();

  test("forEach", () {
    StreamController c = new StreamController();
    Events actualEvents = new Events();
    Future f = c.stream.forEach(actualEvents.add);
    f.then(expectAsync((_) {
      actualEvents.close();
      Expect.listEquals(sentEvents.events, actualEvents.events);
    }));
    sentEvents.replay(c);
  });

  test("forEachError", () {
    Events sentEvents = new Events()
      ..add(7)
      ..error("bad")
      ..add(87)
      ..close();
    StreamController c = new StreamController();
    Events actualEvents = new Events();
    Future f = c.stream.forEach(actualEvents.add);
    f.catchError(expectAsync((error) {
      Expect.equals("bad", error);
      Expect.listEquals((new Events()..add(7)).events, actualEvents.events);
    }));
    sentEvents.replay(c);
  });

  test("forEachError2", () {
    Events sentEvents = new Events()
      ..add(7)
      ..add(9)
      ..add(87)
      ..close();
    StreamController c = new StreamController();
    Events actualEvents = new Events();
    Future f = c.stream.forEach((x) {
      if (x == 9) throw "bad";
      actualEvents.add(x);
    });
    f.catchError(expectAsync((error) {
      Expect.equals("bad", error);
      Expect.listEquals((new Events()..add(7)).events, actualEvents.events);
    }));
    sentEvents.replay(c);
  });

  test("firstWhere", () {
    StreamController c = new StreamController();
    Future f = c.stream.firstWhere((x) => (x % 3) == 0);
    f.then(expectAsync((v) {
      Expect.equals(9, v);
    }));
    sentEvents.replay(c);
  });

  test("firstWhere 2", () {
    StreamController c = new StreamController();
    Future f = c.stream.firstWhere((x) => (x % 4) == 0);
    f.catchError(expectAsync((e) {}));
    sentEvents.replay(c);
  });

  test("firstWhere 3", () {
    StreamController c = new StreamController();
    Future f =
        c.stream.firstWhere((x) => (x % 4) == 0, defaultValue: () => 999);
    f.then(expectAsync((v) {
      Expect.equals(999, v);
    }));
    sentEvents.replay(c);
  });

  test("lastWhere", () {
    StreamController c = new StreamController();
    Future f = c.stream.lastWhere((x) => (x % 3) == 0);
    f.then(expectAsync((v) {
      Expect.equals(87, v);
    }));
    sentEvents.replay(c);
  });

  test("lastWhere 2", () {
    StreamController c = new StreamController();
    Future f = c.stream.lastWhere((x) => (x % 4) == 0);
    f.catchError(expectAsync((e) {}));
    sentEvents.replay(c);
  });

  test("lastWhere 3", () {
    StreamController c = new StreamController();
    Future f = c.stream.lastWhere((x) => (x % 4) == 0, defaultValue: () => 999);
    f.then(expectAsync((v) {
      Expect.equals(999, v);
    }));
    sentEvents.replay(c);
  });

  test("singleWhere", () {
    StreamController c = new StreamController();
    Future f = c.stream.singleWhere((x) => (x % 9) == 0);
    f.then(expectAsync((v) {
      Expect.equals(9, v);
    }));
    sentEvents.replay(c);
  });

  test("singleWhere 2", () {
    StreamController c = new StreamController();
    Future f = c.stream.singleWhere((x) => (x % 3) == 0); // Matches 9 and 87..
    f.catchError(expectAsync((error) {
      Expect.isTrue(error is StateError);
    }));
    sentEvents.replay(c);
  });

  test("first", () {
    StreamController c = new StreamController();
    Future f = c.stream.first;
    f.then(expectAsync((v) {
      Expect.equals(7, v);
    }));
    sentEvents.replay(c);
  });

  test("first empty", () {
    StreamController c = new StreamController();
    Future f = c.stream.first;
    f.catchError(expectAsync((error) {
      Expect.isTrue(error is StateError);
    }));
    Events emptyEvents = new Events()..close();
    emptyEvents.replay(c);
  });

  test("first error", () {
    StreamController c = new StreamController();
    Future f = c.stream.first;
    f.catchError(expectAsync((error) {
      Expect.equals("error", error);
    }));
    Events errorEvents = new Events()
      ..error("error")
      ..close();
    errorEvents.replay(c);
  });

  test("first error 2", () {
    StreamController c = new StreamController();
    Future f = c.stream.first;
    f.catchError(expectAsync((error) {
      Expect.equals("error", error);
    }));
    Events errorEvents = new Events()
      ..error("error")
      ..error("error2")
      ..close();
    errorEvents.replay(c);
  });

  test("last", () {
    StreamController c = new StreamController();
    Future f = c.stream.last;
    f.then(expectAsync((v) {
      Expect.equals(87, v);
    }));
    sentEvents.replay(c);
  });

  test("last empty", () {
    StreamController c = new StreamController();
    Future f = c.stream.last;
    f.catchError(expectAsync((error) {
      Expect.isTrue(error is StateError);
    }));
    Events emptyEvents = new Events()..close();
    emptyEvents.replay(c);
  });

  test("last error", () {
    StreamController c = new StreamController();
    Future f = c.stream.last;
    f.catchError(expectAsync((error) {
      Expect.equals("error", error);
    }));
    Events errorEvents = new Events()
      ..error("error")
      ..close();
    errorEvents.replay(c);
  });

  test("last error 2", () {
    StreamController c = new StreamController();
    Future f = c.stream.last;
    f.catchError(expectAsync((error) {
      Expect.equals("error", error);
    }));
    Events errorEvents = new Events()
      ..error("error")
      ..error("error2")
      ..close();
    errorEvents.replay(c);
  });

  test("elementAt", () {
    StreamController c = new StreamController();
    Future f = c.stream.elementAt(2);
    f.then(expectAsync((v) {
      Expect.equals(13, v);
    }));
    sentEvents.replay(c);
  });

  test("elementAt 2", () {
    StreamController c = new StreamController();
    Future f = c.stream.elementAt(20);
    f.catchError(expectAsync((error) {
      Expect.isTrue(error is RangeError);
    }));
    sentEvents.replay(c);
  });

  test("drain", () {
    StreamController c = new StreamController();
    Future f = c.stream.drain();
    f.then(expectAsync((v) {
      Expect.equals(null, v);
    }));
    sentEvents.replay(c);
  });

  test("drain error", () {
    StreamController c = new StreamController();
    Future f = c.stream.drain();
    f.catchError(expectAsync((error) {
      Expect.equals("error", error);
    }));
    Events errorEvents = new Events()
      ..error("error")
      ..error("error2")
      ..close();
    errorEvents.replay(c);
  });
}

testPause() {
  test("pause event-unpause", () {
    StreamProtocolTest test = new StreamProtocolTest();
    Completer completer = new Completer();
    test
      ..expectListen()
      ..expectData(42, () {
        test.pause(completer.future);
      })
      ..expectPause(() {
        completer.complete(null);
      })
      ..expectData(43)
      ..expectData(44)
      ..expectCancel()
      ..expectDone(test.terminate);
    test.listen();
    test.add(42);
    test.add(43);
    test.add(44);
    test.close();
  });

  test("pause twice event-unpause", () {
    StreamProtocolTest test = new StreamProtocolTest();
    Completer completer = new Completer();
    Completer completer2 = new Completer();
    test
      ..expectListen()
      ..expectData(42, () {
        test.pause(completer.future);
        test.pause(completer2.future);
      })
      ..expectPause(() {
        completer.future.then(completer2.complete);
        completer.complete(null);
      })
      ..expectData(43)
      ..expectData(44)
      ..expectCancel()
      ..expectDone(test.terminate);
    test
      ..listen()
      ..add(42)
      ..add(43)
      ..add(44)
      ..close();
  });

  test("pause twice direct-unpause", () {
    StreamProtocolTest test = new StreamProtocolTest();
    test
      ..expectListen()
      ..expectData(42, () {
        test.pause();
        test.pause();
      })
      ..expectPause(() {
        test.resume();
        test.resume();
      })
      ..expectData(43)
      ..expectData(44)
      ..expectCancel()
      ..expectDone(test.terminate);
    test
      ..listen()
      ..add(42)
      ..add(43)
      ..add(44)
      ..close();
  });

  test("pause twice direct-event-unpause", () {
    StreamProtocolTest test = new StreamProtocolTest();
    Completer completer = new Completer();
    test
      ..expectListen()
      ..expectData(42, () {
        test.pause();
        test.pause(completer.future);
        test.add(43);
        test.add(44);
        test.close();
      })
      ..expectPause(() {
        completer.future.then((v) => test.resume());
        completer.complete(null);
      })
      ..expectData(43)
      ..expectData(44)
      ..expectCancel()
      ..expectDone(test.terminate);
    test
      ..listen()
      ..add(42);
  });
}

class TestError {
  const TestError();
}

testRethrow() {
  TestError error = const TestError();

  testStream(name, streamValueTransform) {
    test("rethrow-$name-value", () {
      StreamController c = new StreamController();
      Stream s = streamValueTransform(c.stream, (v) {
        throw error;
      });
      s.listen((_) {
        Expect.fail("unexpected value");
      }, onError: expectAsync((e) {
        Expect.identical(error, e);
      }));
      c.add(null);
      c.close();
    });
  }

  testStreamError(name, streamErrorTransform) {
    test("rethrow-$name-error", () {
      StreamController c = new StreamController();
      Stream s = streamErrorTransform(c.stream, (e) {
        throw error;
      });
      s.listen((_) {
        Expect.fail("unexpected value");
      }, onError: expectAsync((e) {
        Expect.identical(error, e);
      }));
      c.addError("SOME ERROR");
      c.close();
    });
  }

  testFuture(name, streamValueTransform) {
    test("rethrow-$name-value", () {
      StreamController c = new StreamController();
      Future f = streamValueTransform(c.stream, (v) {
        throw error;
      });
      f.then((v) {
        Expect.fail("unreachable");
      }, onError: expectAsync((e) {
        Expect.identical(error, e);
      }));
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
  testFuture("reduce", (s, act) => s.reduce((a, b) => act(b)));
  testFuture("fold", (s, act) => s.fold(0, (a, b) => act(b)));
  testFuture("drain", (s, act) => s.drain().then(act));
}

void testBroadcastController() {
  test("broadcast-controller-basic", () {
    StreamProtocolTest test = new StreamProtocolTest.broadcast();
    test
      ..expectListen()
      ..expectData(42)
      ..expectCancel()
      ..expectDone(test.terminate);
    test
      ..listen()
      ..add(42)
      ..close();
  });

  test("broadcast-controller-listen-twice", () {
    StreamProtocolTest test = new StreamProtocolTest.broadcast();
    test
      ..expectListen()
      ..expectData(42, () {
        test.listen();
        test.add(37);
        test.close();
      })
      // Order is not guaranteed between subscriptions if not sync.
      ..expectData(37)
      ..expectData(37)
      ..expectDone()
      ..expectCancel()
      ..expectDone(test.terminate);
    test.listen();
    test.add(42);
  });

  test("broadcast-controller-listen-twice-non-overlap", () {
    StreamProtocolTest test = new StreamProtocolTest.broadcast();
    test
      ..expectListen(() {
        test.add(42);
      })
      ..expectData(42, () {
        test.cancel();
      })
      ..expectCancel(() {
        test.listen();
      })
      ..expectListen(() {
        test.add(37);
      })
      ..expectData(37, () {
        test.close();
      })
      ..expectCancel()
      ..expectDone(test.terminate);
    test.listen();
  });

  test("broadcast-controller-individual-pause", () {
    StreamProtocolTest test = new StreamProtocolTest.broadcast();
    var sub1;
    test
      ..expectListen()
      ..expectData(42)
      ..expectData(42, () {
        sub1.pause();
      })
      ..expectData(43, () {
        sub1.cancel();
        test.listen();
        test.add(44);
        test.expectData(44);
        test.expectData(44, test.terminate);
      });
    sub1 = test.listen();
    test.listen();
    test.add(42);
    test.add(43);
  });

  test("broadcast-controller-add-in-callback", () {
    StreamProtocolTest test = new StreamProtocolTest.broadcast();
    test.expectListen();
    var sub = test.listen();
    test.add(42);
    sub.expectData(42, () {
      test.add(87);
      sub.cancel();
    });
    test.expectCancel(() {
      test.add(37);
      test.terminate();
    });
  });
}

void testAsBroadcast() {
  test("asBroadcast-not-canceled", () {
    StreamProtocolTest test = new StreamProtocolTest.asBroadcast();
    var sub;
    test
      ..expectListen()
      ..expectBroadcastListen((_) {
        test.add(42);
      })
      ..expectData(42, () {
        sub.cancel();
      })
      ..expectBroadcastCancel((_) {
        sub = test.listen();
      })
      ..expectBroadcastListen((_) {
        test.terminate();
      });
    sub = test.listen();
  });

  test("asBroadcast-canceled", () {
    StreamProtocolTest test = new StreamProtocolTest.asBroadcast();
    var sub;
    test
      ..expectListen()
      ..expectBroadcastListen((_) {
        test.add(42);
      })
      ..expectData(42, () {
        sub.cancel();
      })
      ..expectBroadcastCancel((originalSub) {
        originalSub.cancel();
      })
      ..expectCancel(test.terminate);
    sub = test.listen();
  });

  test("asBroadcast-pause-original", () {
    StreamProtocolTest test = new StreamProtocolTest.asBroadcast();
    var sub;
    test
      ..expectListen()
      ..expectBroadcastListen((_) {
        test.add(42);
        test.add(43);
      })
      ..expectData(42, () {
        sub.cancel();
      })
      ..expectBroadcastCancel((originalSub) {
        originalSub.pause(); // Pause before sending 43 from original sub.
      })
      ..expectPause(() {
        sub = test.listen();
      })
      ..expectBroadcastListen((originalSub) {
        originalSub.resume();
      })
      ..expectData(43)
      ..expectResume(() {
        test.close();
      })
      ..expectCancel()
      ..expectDone()
      ..expectBroadcastCancel((_) => test.terminate());
    sub = test.listen();
  });
}

void testSink({bool sync, bool broadcast, bool asBroadcast}) {
  String type = "${sync?"S":"A"}${broadcast?"B":"S"}${asBroadcast?"aB":""}";
  test("$type-controller-sink", () {
    var done = expectAsync(() {});
    var c = broadcast
        ? new StreamController.broadcast(sync: sync)
        : new StreamController(sync: sync);
    var expected = new Events()
      ..add(42)
      ..error("error")
      ..add(1)
      ..add(2)
      ..add(3)
      ..add(4)
      ..add(5)
      ..add(43)
      ..close();
    var actual = new Events.capture(
        asBroadcast ? c.stream.asBroadcastStream() : c.stream);
    var sink = c.sink;
    sink.add(42);
    sink.addError("error");
    sink.addStream(new Stream.fromIterable([1, 2, 3, 4, 5])).then((_) {
      sink.add(43);
      return sink.close();
    }).then((_) {
      Expect.listEquals(expected.events, actual.events);
      done();
    });
  });

  test("$type-controller-sink-canceled", () {
    var done = expectAsync(() {});
    var c = broadcast
        ? new StreamController.broadcast(sync: sync)
        : new StreamController(sync: sync);
    var expected = new Events()
      ..add(42)
      ..error("error")
      ..add(1)
      ..add(2)
      ..add(3);
    var stream = asBroadcast ? c.stream.asBroadcastStream() : c.stream;
    var actual = new Events();
    var sub;
    // Cancel subscription after receiving "3" event.
    sub = stream.listen((v) {
      if (v == 3) sub.cancel();
      actual.add(v);
    }, onError: actual.error);
    var sink = c.sink;
    sink.add(42);
    sink.addError("error");
    sink.addStream(new Stream.fromIterable([1, 2, 3, 4, 5])).then((_) {
      Expect.listEquals(expected.events, actual.events);
      // Close controller as well. It has no listener. If it is a broadcast
      // stream, it will still be open, and we read the "done" future before
      // closing. A normal stream is already done when its listener cancels.
      Future doneFuture = sink.done;
      sink.close();
      return doneFuture;
    }).then((_) {
      // No change in events.
      Expect.listEquals(expected.events, actual.events);
      done();
    });
  });

  test("$type-controller-sink-paused", () {
    var done = expectAsync(() {});
    var c = broadcast
        ? new StreamController.broadcast(sync: sync)
        : new StreamController(sync: sync);
    var expected = new Events()
      ..add(42)
      ..error("error")
      ..add(1)
      ..add(2)
      ..add(3)
      ..add(4)
      ..add(5)
      ..add(43)
      ..close();
    var stream = asBroadcast ? c.stream.asBroadcastStream() : c.stream;
    var actual = new Events();
    var sub;
    var pauseIsDone = false;
    sub = stream.listen((v) {
      if (v == 3) {
        sub.pause(new Future.delayed(const Duration(milliseconds: 15), () {
          pauseIsDone = true;
        }));
      }
      actual.add(v);
    }, onError: actual.error, onDone: actual.close);
    var sink = c.sink;
    sink.add(42);
    sink.addError("error");
    sink.addStream(new Stream.fromIterable([1, 2, 3, 4, 5])).then((_) {
      sink.add(43);
      return sink.close();
    }).then((_) {
      if (asBroadcast || broadcast) {
        // The done-future of the sink completes when it passes
        // the done event to the asBroadcastStream controller, which is
        // before the final listener gets the event.
        // Wait for the done event to be *delivered* before testing the
        // events.
        actual.onDone(() {
          Expect.listEquals(expected.events, actual.events);
          done();
        });
      } else {
        Expect.listEquals(expected.events, actual.events);
        done();
      }
    });
  });

  test("$type-controller-addstream-error-stop", () {
    // Check that addStream defaults to ending after the first error.
    var done = expectAsync(() {});
    StreamController c = broadcast
        ? new StreamController.broadcast(sync: sync)
        : new StreamController(sync: sync);
    Stream stream = asBroadcast ? c.stream.asBroadcastStream() : c.stream;
    var actual = new Events.capture(stream);

    var source = new Events();
    source
      ..add(1)
      ..add(2)
      ..error("BAD")
      ..add(3)
      ..error("FAIL")
      ..close();

    var expected = new Events()
      ..add(1)
      ..add(2)
      ..error("BAD")
      ..close();
    StreamController sourceController = new StreamController();
    c.addStream(sourceController.stream).then((_) {
      c.close().then((_) {
        Expect.listEquals(expected.events, actual.events);
        done();
      });
    });

    source.replay(sourceController);
  });

  test("$type-controller-addstream-error-forward", () {
    // Check that addStream with cancelOnError:false passes all data and errors
    // to the controller.
    var done = expectAsync(() {});
    StreamController c = broadcast
        ? new StreamController.broadcast(sync: sync)
        : new StreamController(sync: sync);
    Stream stream = asBroadcast ? c.stream.asBroadcastStream() : c.stream;
    var actual = new Events.capture(stream);

    var source = new Events();
    source
      ..add(1)
      ..add(2)
      ..addError("BAD")
      ..add(3)
      ..addError("FAIL")
      ..close();

    StreamController sourceController = new StreamController();
    c.addStream(sourceController.stream, cancelOnError: false).then((_) {
      c.close().then((_) {
        Expect.listEquals(source.events, actual.events);
        done();
      });
    });

    source.replay(sourceController);
  });

  test("$type-controller-addstream-twice", () {
    // Using addStream twice on the same stream
    var done = expectAsync(() {});
    StreamController c = broadcast
        ? new StreamController.broadcast(sync: sync)
        : new StreamController(sync: sync);
    Stream stream = asBroadcast ? c.stream.asBroadcastStream() : c.stream;
    var actual = new Events.capture(stream);

    // Streams of five events, throws on 3.
    Stream s1 = new Stream.fromIterable([1, 2, 3, 4, 5])
        .map((x) => (x == 3 ? throw x : x));
    Stream s2 = new Stream.fromIterable([1, 2, 3, 4, 5])
        .map((x) => (x == 3 ? throw x : x));

    Events expected = new Events();
    expected
      ..add(1)
      ..add(2)
      ..error(3);
    expected
      ..add(1)
      ..add(2)
      ..error(3)
      ..add(4)
      ..add(5);
    expected..close();

    c.addStream(s1).then((_) {
      c.addStream(s2, cancelOnError: false).then((_) {
        c.close().then((_) {
          Expect.listEquals(expected.events, actual.events);
          done();
        });
      });
    });
  });
}

main() {
  testController();
  testSingleController();
  testExtraMethods();
  testPause();
  testRethrow();
  testBroadcastController();
  testAsBroadcast();
  testSink(sync: true, broadcast: false, asBroadcast: false);
  testSink(sync: true, broadcast: false, asBroadcast: true);
  testSink(sync: true, broadcast: true, asBroadcast: false);
  testSink(sync: false, broadcast: false, asBroadcast: false);
  testSink(sync: false, broadcast: false, asBroadcast: true);
  testSink(sync: false, broadcast: true, asBroadcast: false);
}
