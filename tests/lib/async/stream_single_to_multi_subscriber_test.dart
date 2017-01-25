// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test the basic StreamController and StreamController.singleSubscription.
library stream_single_test;

import 'dart:async';
import 'package:test/test.dart';
import 'event_helper.dart';

main() {
  test("tomulti 1", () {
    StreamController c = new StreamController<int>(sync: true);
    Stream<int> multi = c.stream.asBroadcastStream();
    // Listen twice.
    multi.listen(expectAsync((v) => expect(42, equals(v))));
    multi.listen(expectAsync((v) => expect(42, equals(v))));
    c.add(42);
  });

  test("tomulti 2", () {
    StreamController c = new StreamController<int>(sync: true);
    Stream<int> multi = c.stream.asBroadcastStream();
    Events expected = new Events.fromIterable([1, 2, 3, 4, 5]);
    Events actual1 = new Events.capture(multi);
    Events actual2 = new Events.capture(multi);
    actual1.onDone(expectAsync(() {
      expect(expected.events, equals(actual1.events));
    }));
    actual2.onDone(expectAsync(() {
      expect(expected.events, equals(actual2.events));
    }));
    expected.replay(c);
  });

  test("tomulti no-op", () {
    StreamController c = new StreamController<int>(sync: true);
    Stream<int> multi = c.stream.asBroadcastStream();
    Events expected = new Events.fromIterable([1, 2, 3, 4, 5]);
    Events actual1 = new Events.capture(multi);
    Events actual2 = new Events.capture(multi);
    actual1.onDone(expectAsync(() {
      expect(expected.events, equals(actual1.events));
    }));
    actual2.onDone(expectAsync(() {
      expect(expected.events, equals(actual2.events));
    }));
    expected.replay(c);
  });
}
