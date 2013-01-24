// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test merging streams.
library merge_stream_test;

import "dart:async";
import '../../../pkg/unittest/lib/unittest.dart';
import 'event_helper.dart';

testSupercedeStream() {
  { // Simple case of superceding lower priority streams.
    StreamController s1 = new StreamController.broadcast();
    StreamController s2 = new StreamController.broadcast();
    StreamController s3 = new StreamController.broadcast();
    Stream merge = new Stream.superceding([s1.stream, s2.stream, s3.stream]);
    Events expected = new Events()..add(1)..add(2)..add(3)..add(4)..close();
    Events actual = new Events.capture(merge);
    s1.add(1);
    s2.add(2);
    s1.add(1);  // Ignored.
    s2.add(3);
    s3.add(4);
    s2.add(3);  // Ignored.
    s3.close();
    Expect.listEquals(expected.events, actual.events);
  }

  { // Superceding more than one stream at a time.
    StreamController s1 = new StreamController.broadcast();
    StreamController s2 = new StreamController.broadcast();
    StreamController s3 = new StreamController.broadcast();
    Stream merge = new Stream.superceding([s1.stream, s2.stream, s3.stream]);
    Events expected = new Events()..add(1)..add(2)..close();
    Events actual = new Events.capture(merge);
    s1.add(1);
    s3.add(2);
    s1.add(1);  // Ignored.
    s2.add(1);  // Ignored.
    s3.close();
    Expect.listEquals(expected.events, actual.events);
  }

  { // Closing a stream before superceding it.
    StreamController s1 = new StreamController.broadcast();
    StreamController s2 = new StreamController.broadcast();
    StreamController s3 = new StreamController.broadcast();
    Stream merge = new Stream.superceding([s1.stream, s2.stream, s3.stream]);
    Events expected = new Events()..add(1)..add(2)..add(3)..close();
    Events actual = new Events.capture(merge);
    s1.add(1);
    s1.close();
    s3.close();
    s2.add(2);
    s2.add(3);
    s2.close();
    Expect.listEquals(expected.events, actual.events);
  }

  { // Errors from all non-superceded streams are forwarded.
    StreamController s1 = new StreamController.broadcast();
    StreamController s2 = new StreamController.broadcast();
    StreamController s3 = new StreamController.broadcast();
    Stream merge = new Stream.superceding([s1.stream, s2.stream, s3.stream]);
    Events expected =
        new Events()..add(1)..error("1")..error("2")..error("3")
                    ..add(3)..error("6")..add(4)..close();
    Events actual = new Events.capture(merge);
    s1.add(1);
    s1.signalError(new AsyncError("1"));
    s2.signalError(new AsyncError("2"));
    s3.signalError(new AsyncError("3"));
    s3.add(3);
    s1.signalError(new AsyncError("4"));
    s2.signalError(new AsyncError("5"));
    s3.signalError(new AsyncError("6"));
    s1.close();
    s2.close();
    s3.add(4);
    s3.close();
    Expect.listEquals(expected.events, actual.events);
  }

  test("Pausing on a superceding stream", () {
    StreamController s1 = new StreamController.broadcast();
    StreamController s2 = new StreamController.broadcast();
    StreamController s3 = new StreamController.broadcast();
    Stream merge = new Stream.superceding([s1.stream, s2.stream, s3.stream]);
    Events expected = new Events()..add(1)..add(2)..add(3);
    Events actual = new Events.capture(merge);
    s1.add(1);
    s2.add(2);
    s2.add(3);
    Expect.listEquals(expected.events, actual.events);
    actual.pause();  // Pauses the stream that feeds the actual Events.
    Events expected2 = expected.copy();
    expected..add(5)..add(6)..close();
    expected2..add(6)..close();
    s1.add(4);
    s2.add(5);  // May or may not arrive before '6' when resuming.
    s3.add(6);
    s3.close();
    actual.onDone(expectAsync0(() {
      if (expected.events.length == actual.events.length) {
        Expect.listEquals(expected.events, actual.events);
      } else {
        Expect.listEquals(expected2.events, actual.events);
      }
    }));
    actual.resume();
  });
}

void testCyclicStream() {
  test("Simple case of superceding lower priority streams", () {
    StreamController s1 = new StreamController.broadcast();
    StreamController s2 = new StreamController.broadcast();
    StreamController s3 = new StreamController.broadcast();
    Stream merge = new Stream.cyclic([s1.stream, s2.stream, s3.stream]);
    Events expected =
        new Events()..add(1)..add(2)..add(3)..add(4)..add(5)..add(6)..close();
    Events actual = new Events.capture(merge);
    Expect.isFalse(s1.isPaused);
    Expect.isTrue(s2.isPaused);
    Expect.isTrue(s3.isPaused);
    s3.add(3);
    s1.add(1);
    s1.add(4);
    s1.add(6);
    s1.close();
    s2.add(2);
    s2.add(5);
    s2.close();
    s3.close();
    actual.onDone(expectAsync0(() {
      Expect.listEquals(expected.events, actual.events);
    }));
  });

  test("Cyclic merge with errors", () {
    StreamController s1 = new StreamController.broadcast();
    StreamController s2 = new StreamController.broadcast();
    StreamController s3 = new StreamController.broadcast();
    Stream merge = new Stream.cyclic([s1.stream, s2.stream, s3.stream]);
    Events expected =
        new Events()..add(1)..error("1")..add(2)..add(3)..error("2")
                    ..add(4)..add(5)..error("3")..add(6)..close();
    Events actual = new Events.capture(merge);
    Expect.isFalse(s1.isPaused);
    Expect.isTrue(s2.isPaused);
    Expect.isTrue(s3.isPaused);
    s3.add(3);
    s3.signalError(new AsyncError("3"));  // Error just before a "done".
    s1.add(1);
    s1.signalError(new AsyncError("2"));  // Error between events.
    s1.add(4);
    s1.add(6);
    s1.close();
    s2.signalError(new AsyncError("1"));  // Error as first event.
    s2.add(2);
    s2.add(5);
    s2.close();
    s3.close();
    actual.onDone(expectAsync0(() {
      Expect.listEquals(expected.events, actual.events);
    }));
  });
}

main() {
  testSupercedeStream();
  testCyclicStream();
}
