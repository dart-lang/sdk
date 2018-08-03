// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:unittest/unittest.dart';

main() {
  const ms5 = const Duration(milliseconds: 5);
  const twoSecs = const Duration(seconds: 2);

  test("stream timeout", () {
    StreamController c = new StreamController();
    Stream tos = c.stream.timeout(ms5);
    expect(tos.isBroadcast, false);
    tos.handleError(expectAsync((e, s) {
      expect(e, new isInstanceOf<TimeoutException>());
      expect(s, null);
    })).listen((v) {
      fail("Unexpected event");
    });
  });

  test("stream timeout add events", () {
    StreamController c = new StreamController();
    Stream tos = c.stream.timeout(ms5, onTimeout: (sink) {
      sink.add(42);
      sink.addError("ERROR");
      sink.close();
    });
    expect(tos.isBroadcast, false);
    tos.listen(expectAsync((v) {
      expect(v, 42);
    }), onError: expectAsync((e, s) {
      expect(e, "ERROR");
    }), onDone: expectAsync(() {}));
  });

  test("stream no timeout", () {
    StreamController c = new StreamController();
    Stream tos = c.stream.timeout(twoSecs);
    int ctr = 0;
    tos.listen((v) {
      expect(v, 42);
      ctr++;
    }, onError: (e, s) {
      fail("No error expected");
    }, onDone: expectAsync(() {
      expect(ctr, 2);
    }));
    expect(tos.isBroadcast, false);
    c
      ..add(42)
      ..add(42)
      ..close(); // Faster than a timeout!
  });

  test("stream timeout after events", () {
    StreamController c = new StreamController();
    Stream tos = c.stream.timeout(twoSecs);
    expect(tos.isBroadcast, false);
    int ctr = 0;
    tos.listen((v) {
      expect(v, 42);
      ctr++;
    }, onError: expectAsync((e, s) {
      expect(ctr, 2);
      expect(e, new isInstanceOf<TimeoutException>());
    }));
    c..add(42)..add(42); // No close, timeout after two events.
  });

  test("broadcast stream timeout", () {
    StreamController c = new StreamController.broadcast();
    Stream tos = c.stream.timeout(ms5);
    expect(tos.isBroadcast, true);
    tos.handleError(expectAsync((e, s) {
      expect(e, new isInstanceOf<TimeoutException>());
      expect(s, null);
    })).listen((v) {
      fail("Unexpected event");
    });
  });

  test("asBroadcast stream timeout", () {
    StreamController c = new StreamController.broadcast();
    Stream tos = c.stream.asBroadcastStream().timeout(ms5);
    expect(tos.isBroadcast, true);
    tos.handleError(expectAsync((e, s) {
      expect(e, new isInstanceOf<TimeoutException>());
      expect(s, null);
    })).listen((v) {
      fail("Unexpected event");
    });
  });

  test("mapped stream timeout", () {
    StreamController c = new StreamController();
    Stream tos = c.stream.map((x) => 2 * x).timeout(ms5);
    expect(tos.isBroadcast, false);
    tos.handleError(expectAsync((e, s) {
      expect(e, new isInstanceOf<TimeoutException>());
      expect(s, null);
    })).listen((v) {
      fail("Unexpected event");
    });
  });

  test("events prevent timeout", () {
    Stopwatch sw = new Stopwatch();
    StreamController c = new StreamController();
    Stream tos = c.stream.timeout(twoSecs, onTimeout: (_) {
      int elapsed = sw.elapsedMilliseconds;
      if (elapsed > 250) {
        // This should not happen, but it does occasionally.
        // Starving the periodic timer has made the test useless.
        print("Periodic timer of 5 ms delayed $elapsed ms.");
        return;
      }
      fail("Timeout not prevented by events");
      throw "ERROR";
    });
    // Start the periodic timer before we start listening to the stream.
    // This should reduce the flakiness of the test.
    int ctr = 200; // send this many events at 5ms intervals. Then close.
    new Timer.periodic(ms5, (timer) {
      sw.reset();
      c.add(42);
      if (--ctr == 0) {
        timer.cancel();
        c.close();
      }
    });
    sw.start();

    tos.listen((v) {
      expect(v, 42);
    }, onDone: expectAsync(() {}));
  });

  test("errors prevent timeout", () {
    Stopwatch sw = new Stopwatch();
    StreamController c = new StreamController();
    Stream tos = c.stream.timeout(twoSecs, onTimeout: (_) {
      int elapsed = sw.elapsedMilliseconds;
      if (elapsed > 250) {
        // This should not happen, but it does occasionally.
        // Starving the periodic timer has made the test useless.
        print("Periodic timer of 5 ms delayed $elapsed ms.");
        return;
      }
      fail("Timeout not prevented by errors");
    });

    // Start the periodic timer before we start listening to the stream.
    // This should reduce the flakiness of the test.
    int ctr = 200; // send this many error events at 5ms intervals. Then close.
    new Timer.periodic(ms5, (timer) {
      sw.reset();
      c.addError("ERROR");
      if (--ctr == 0) {
        timer.cancel();
        c.close();
      }
    });
    sw.start();

    tos.listen((_) {}, onError: (e, s) {
      expect(e, "ERROR");
    }, onDone: expectAsync(() {}));
  });

  test("closing prevents timeout", () {
    StreamController c = new StreamController();
    Stream tos = c.stream.timeout(twoSecs, onTimeout: (_) {
      fail("Timeout not prevented by close");
    });
    tos.listen((_) {}, onDone: expectAsync(() {}));
    c.close();
  });

  test("pausing prevents timeout", () {
    StreamController c = new StreamController();
    Stream tos = c.stream.timeout(ms5, onTimeout: (_) {
      fail("Timeout not prevented by close");
    });
    var subscription = tos.listen((_) {}, onDone: expectAsync(() {}));
    subscription.pause();
    new Timer(twoSecs, () {
      c.close();
      subscription.resume();
    });
  });
}
