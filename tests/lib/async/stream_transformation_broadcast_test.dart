// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that transformations like `map` and `where` preserve broadcast flag.
library stream_join_test;

import 'dart:async';
import 'event_helper.dart';
import 'package:unittest/unittest.dart';
import "package:expect/expect.dart";

void testStream(String name,
                StreamController create(),
                Stream getStream(controller)) {
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
    var t = new StreamTransformer.fromHandlers(
        handleData: (value, EventSink sink) { sink.add(value); }
    );
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
}

main() {
  testStream("singlesub", () => new StreamController(), (c) => c.stream);
  testStream("broadcast", () => new StreamController.broadcast(),
                          (c) => c.stream);
  testStream("asBroadcast", () => new StreamController(),
                            (c) => c.stream.asBroadcastStream());
  testStream("broadcast.asBroadcast", () => new StreamController.broadcast(),
                                      (c) => c.stream.asBroadcastStream());
}
