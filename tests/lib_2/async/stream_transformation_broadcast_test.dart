// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that transformations like `map` and `where` preserve broadcast flag.
library stream_join_test;

import 'dart:async';

import 'package:expect/expect.dart';
import 'package:unittest/unittest.dart';

import 'event_helper.dart';

main() {
  testStream("singlesub", () => new StreamController(), (c) => c.stream);
  testStream(
      "broadcast", () => new StreamController.broadcast(), (c) => c.stream);
  testStream("asBroadcast", () => new StreamController(),
      (c) => c.stream.asBroadcastStream());
  testStream("broadcast.asBroadcast", () => new StreamController.broadcast(),
      (c) => c.stream.asBroadcastStream());
}

void testStream(
    String name, StreamController create(), Stream getStream(controller)) {
  test("$name-map", () {
    var c = create();
    var s = getStream(c);
    Stream newStream = s.map((x) => x + 1);
    Expect.equals(s.isBroadcast, newStream.isBroadcast);
    newStream.single.then(expectAsync((v) {
      Expect.equals(43, v);
    }));
    c.add(42);
    c.close();
  });
  test("$name-where", () {
    var c = create();
    var s = getStream(c);
    Stream newStream = s.where((x) => x.isEven);
    Expect.equals(s.isBroadcast, newStream.isBroadcast);
    newStream.single.then(expectAsync((v) {
      Expect.equals(42, v);
    }));
    c.add(37);
    c.add(42);
    c.add(87);
    c.close();
  });
  test("$name-handleError", () {
    var c = create();
    var s = getStream(c);
    Stream newStream = s.handleError((x, s) {});
    Expect.equals(s.isBroadcast, newStream.isBroadcast);
    newStream.single.then(expectAsync((v) {
      Expect.equals(42, v);
    }));
    c.addError("BAD1");
    c.add(42);
    c.addError("BAD2");
    c.close();
  });
  test("$name-expand", () {
    var c = create();
    var s = getStream(c);
    Stream newStream = s.expand((x) => x.isEven ? [x] : []);
    Expect.equals(s.isBroadcast, newStream.isBroadcast);
    newStream.single.then(expectAsync((v) {
      Expect.equals(42, v);
    }));
    c.add(37);
    c.add(42);
    c.add(87);
    c.close();
  });
  test("$name-transform", () {
    var c = create();
    var s = getStream(c);
    // TODO: find name of default transformer
    var t =
        new StreamTransformer.fromHandlers(handleData: (value, EventSink sink) {
      sink.add(value);
    });
    Stream newStream = s.transform(t);
    Expect.equals(s.isBroadcast, newStream.isBroadcast);
    newStream.single.then(expectAsync((v) {
      Expect.equals(42, v);
    }));
    c.add(42);
    c.close();
  });
  test("$name-take", () {
    var c = create();
    var s = getStream(c);
    Stream newStream = s.take(1);
    Expect.equals(s.isBroadcast, newStream.isBroadcast);
    newStream.single.then(expectAsync((v) {
      Expect.equals(42, v);
    }));
    c.add(42);
    c.add(37);
    c.close();
  });
  test("$name-takeWhile", () {
    var c = create();
    var s = getStream(c);
    Stream newStream = s.takeWhile((x) => x.isEven);
    Expect.equals(s.isBroadcast, newStream.isBroadcast);
    newStream.single.then(expectAsync((v) {
      Expect.equals(42, v);
    }));
    c.add(42);
    c.add(37);
    c.close();
  });
  test("$name-skip", () {
    var c = create();
    var s = getStream(c);
    Stream newStream = s.skip(1);
    Expect.equals(s.isBroadcast, newStream.isBroadcast);
    newStream.single.then(expectAsync((v) {
      Expect.equals(42, v);
    }));
    c.add(37);
    c.add(42);
    c.close();
  });
  test("$name-skipWhile", () {
    var c = create();
    var s = getStream(c);
    Stream newStream = s.skipWhile((x) => x.isOdd);
    Expect.equals(s.isBroadcast, newStream.isBroadcast);
    newStream.single.then(expectAsync((v) {
      Expect.equals(42, v);
    }));
    c.add(37);
    c.add(42);
    c.close();
  });
  test("$name-distinct", () {
    var c = create();
    var s = getStream(c);
    Stream newStream = s.distinct();
    Expect.equals(s.isBroadcast, newStream.isBroadcast);
    newStream.single.then(expectAsync((v) {
      Expect.equals(42, v);
    }));
    c.add(42);
    c.add(42);
    c.close();
  });
  test("$name-timeout", () {
    var c = create();
    var s = getStream(c);
    Stream newStream = s.timeout(const Duration(seconds: 1));
    Expect.equals(s.isBroadcast, newStream.isBroadcast);
    newStream.single.then(expectAsync((v) {
      Expect.equals(42, v);
    }));
    c.add(42);
    c.close();
  });
  test("$name-asyncMap", () {
    var c = create();
    var s = getStream(c);
    Stream newStream = s.asyncMap((x) => new Future.value(x + 1));
    Expect.equals(s.isBroadcast, newStream.isBroadcast);
    newStream.single.then(expectAsync((v) {
      Expect.equals(43, v);
    }));
    c.add(42);
    c.close();
  });
  test("$name-asyncExpand", () {
    var c = create();
    var s = getStream(c);
    Stream newStream = s.asyncExpand((x) => new Stream.fromIterable([x + 1]));
    Expect.equals(s.isBroadcast, newStream.isBroadcast);
    newStream.single.then(expectAsync((v) {
      Expect.equals(43, v);
    }));
    c.add(42);
    c.close();
  });

  // The following tests are only on broadcast streams, they require listening
  // more than once.
  if (name.startsWith("singlesub")) return;

  test("$name-skip-multilisten", () {
    if (name.startsWith("singlesub") || name.startsWith("asBroadcast")) return;
    var c = create();
    var s = getStream(c);
    Stream newStream = s.skip(5);
    // Listen immediately, to ensure that an asBroadcast stream is started.
    var sub = newStream.listen((_) {});
    int i = 0;
    var expect1 = 11;
    var expect2 = 21;
    var handler2 = expectAsync((v) {
      expect(v, expect2);
      expect2++;
    }, count: 5);
    var handler1 = expectAsync((v) {
      expect(v, expect1);
      expect1++;
    }, count: 15);
    var loop;
    loop = expectAsync(() {
      i++;
      c.add(i);
      if (i == 5) {
        scheduleMicrotask(() {
          newStream.listen(handler1);
        });
      }
      if (i == 15) {
        scheduleMicrotask(() {
          newStream.listen(handler2);
        });
      }
      if (i < 25) {
        scheduleMicrotask(loop);
      } else {
        sub.cancel();
        c.close();
      }
    }, count: 25);
    scheduleMicrotask(loop);
  });

  test("$name-take-multilisten", () {
    var c = create();
    var s = getStream(c);
    Stream newStream = s.take(10);
    // Listen immediately, to ensure that an asBroadcast stream is started.
    var sub = newStream.listen((_) {});
    int i = 0;
    var expect1 = 6;
    var expect2 = 11;
    var handler2 = expectAsync((v) {
      expect(v, expect2);
      expect(v <= 20, isTrue);
      expect2++;
    }, count: 10);
    var handler1 = expectAsync((v) {
      expect(v, expect1);
      expect(v <= 15, isTrue);
      expect1++;
    }, count: 10);
    var loop;
    loop = expectAsync(() {
      i++;
      c.add(i);
      if (i == 5) {
        scheduleMicrotask(() {
          newStream.listen(handler1);
        });
      }
      if (i == 10) {
        scheduleMicrotask(() {
          newStream.listen(handler2);
        });
      }
      if (i < 25) {
        scheduleMicrotask(loop);
      } else {
        sub.cancel();
        c.close();
      }
    }, count: 25);
    scheduleMicrotask(loop);
  });

  test("$name-skipWhile-multilisten", () {
    if (name.startsWith("singlesub") || name.startsWith("asBroadcast")) return;
    var c = create();
    var s = getStream(c);
    Stream newStream = s.skipWhile((x) => (x % 10) != 1);
    // Listen immediately, to ensure that an asBroadcast stream is started.
    var sub = newStream.listen((_) {});
    int i = 0;
    var expect1 = 11;
    var expect2 = 21;
    var handler2 = expectAsync((v) {
      expect(v, expect2);
      expect2++;
    }, count: 5);
    var handler1 = expectAsync((v) {
      expect(v, expect1);
      expect1++;
    }, count: 15);
    var loop;
    loop = expectAsync(() {
      i++;
      c.add(i);
      if (i == 5) {
        scheduleMicrotask(() {
          newStream.listen(handler1);
        });
      }
      if (i == 15) {
        scheduleMicrotask(() {
          newStream.listen(handler2);
        });
      }
      if (i < 25) {
        scheduleMicrotask(loop);
      } else {
        sub.cancel();
        c.close();
      }
    }, count: 25);
    scheduleMicrotask(loop);
  });

  test("$name-takeWhile-multilisten", () {
    var c = create();
    var s = getStream(c);
    Stream newStream = s.takeWhile((x) => (x % 10) != 5);
    // Listen immediately, to ensure that an asBroadcast stream is started.
    var sub = newStream.listen((_) {});
    int i = 0;
    // Non-overlapping ranges means the test must not remember its first
    // failure.
    var expect1 = 6;
    var expect2 = 16;
    var handler2 = expectAsync((v) {
      expect(v, expect2);
      expect(v <= 25, isTrue);
      expect2++;
    }, count: 9);
    var handler1 = expectAsync((v) {
      expect(v, expect1);
      expect(v <= 15, isTrue);
      expect1++;
    }, count: 9);
    var loop;
    loop = expectAsync(() {
      i++;
      c.add(i);
      if (i == 5) {
        scheduleMicrotask(() {
          newStream.listen(handler1);
        });
      }
      if (i == 15) {
        scheduleMicrotask(() {
          newStream.listen(handler2);
        });
      }
      if (i < 25) {
        scheduleMicrotask(loop);
      } else {
        sub.cancel();
        c.close();
      }
    }, count: 25);
    scheduleMicrotask(loop);
  });
}
