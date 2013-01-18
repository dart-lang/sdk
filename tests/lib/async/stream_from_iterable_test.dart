// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test merging streams.
library dart.test.stream_from_iterable;

import "dart:async";
import '../../../pkg/unittest/lib/unittest.dart';
import 'event_helper.dart';

class IterableTest<T> {
  static int counter = 0;
  Iterable<T> iterable;
  IterableTest(this.iterable);
  void run() {
    test("stream from iterable ${counter++}", () {
      Events expected = new Events.fromIterable(iterable);
      Stream<T> stream = new Stream<T>.fromIterable(iterable);
      Events actual = new Events.capture(stream);
      actual.onDone(expectAsync0(() {
        Expect.listEquals(expected.events, actual.events);
      }));
    });
  }
}

main() {
  new IterableTest([]).run();
  new IterableTest([1]).run();
  new IterableTest([1, "two", true, null]).run();
  new IterableTest<int>([1, 2, 3, 4]).run();
  new IterableTest<String>(["one", "two", "three", "four"]).run();
  new IterableTest<int>(new Iterable<int>.generate(1000, (i) => i)).run();
  new IterableTest<String>(new Iterable<int>.generate(1000, (i) => i)
                                            .mappedBy((i) => "$i")).run();

  Iterable<int> iter = new Iterable.generate(25, (i) => i * 2);

  test("iterable-toList", () {
    new Stream.fromIterable(iter).toList().then(expectAsync1((actual) {
      List expected = iter.toList();
      Expect.equals(25, expected.length);
      Expect.listEquals(expected, actual);
    }));
  });

  test("iterable-mapped-toList", () {
    new Stream.fromIterable(iter)
      .mappedBy((i) => i * 3)
      .toList()
      .then(expectAsync1((actual) {
         List expected = iter.mappedBy((i) => i * 3).toList();
         Expect.listEquals(expected, actual);
      }));
  });

  test("iterable-paused", () {
    Stream stream = new Stream.fromIterable(iter);
    Events actual = new Events();
    StreamSubscription subscription;
    subscription = stream.listen((int value) {
      actual.add(value);
      // Do a 10 ms pause during the playback of the iterable.
      if (value == 20) { subscription.pause(new Future.delayed(10, () {})); }
    }, onDone: expectAsync0(() {
      actual.close();
      Events expected = new Events.fromIterable(iter);
      Expect.listEquals(expected.events, actual.events);
    }));
  });
}
