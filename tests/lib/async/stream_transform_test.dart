// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library stream_transform_test;

import "package:expect/expect.dart";
import 'dart:async';
import '../../../pkg/unittest/lib/unittest.dart';
import 'event_helper.dart';


main() {
  // Regression tests for http://dartbug.com/8310 and 8311

  test("simpleDone", () {
    StreamController c = new StreamController();
    Stream out = c.stream.handleError((x){}).handleError((x){});
    out.listen((v){}, onDone: expectAsync0(() {}));
    // Should not throw.
    c.close();
  });

  test("with events", () {
    StreamController c = new StreamController();
    Events expected = new Events.fromIterable([10, 12]);
    Events input = new Events.fromIterable([1, 2, 3, 4, 5, 6, 7]);
    Events actual = new Events.capture(
        c.stream.map((x) => x * 2).where((x) => x > 5).skip(2).take(2));
    actual.onDone(expectAsync0(() {
      Expect.listEquals(expected.events, actual.events);
    }));
    input.replay(c);
  });

  test("paused events", () {
    StreamController c = new StreamController();
    Events expected = new Events.fromIterable([10, 12]);
    Events input = new Events.fromIterable([1, 2, 3, 4, 5, 6, 7]);
    Events actual = new Events.capture(
        c.stream.map((x) => x * 2).where((x) => x > 5).skip(2).take(2));
    actual.onDone(expectAsync0(() {
      Expect.listEquals(expected.events, actual.events);
    }));
    actual.pause();
    input.replay(c);
    actual.resume();
  });

  test("closing after done", () {
    var controller = new StreamController();
    controller.stream.map((e) => e).transform(new StreamTransformer(
        handleData: (element, sink) { sink.add(element); },
        handleDone: (sink) { sink.close(); })
    ).listen(expectAsync1((e) => expect(e, equals("foo"))));

    controller.add("foo");
    // Should not crash.
    controller.close();
  });
}
