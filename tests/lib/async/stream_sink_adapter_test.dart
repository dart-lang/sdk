// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import 'dart:async';


class TestStreamConsumer implements StreamConsumer {
  final List expectedEvents;
  final List events = [];

  TestStreamConsumer(this.expectedEvents);

  Future addStream(Stream stream) {
    return stream.listen(events.add).asFuture();
  }

  Future close() {
    check();
    return new Future.value();
  }

  void check() {
    Expect.listEquals(expectedEvents, events);
  }
}


// Test several adds follewed by a close.
void testAddClose() {
  asyncStart();
  var sink = new StreamSinkAdapter(new TestStreamConsumer([1, 2, 3]));
  sink.add(1);
  sink.add(2);
  sink.add(3);
  sink.close().then((_) {
    asyncEnd();
  });
}


// Test several adds follewed by a flush.
void testAddFlush() {
  asyncStart();
  var consumer = new TestStreamConsumer([1, 2, 3]);
  var sink = new StreamSinkAdapter(consumer);
  sink.add(1);
  sink.add(2);
  sink.add(3);
  sink.flush().then((_) {
    consumer.check();
    asyncEnd();
  });
  // Not valid during flush.
  Expect.throws(() => sink.add(4));
  Expect.throws(() => sink.addError("error"));
  Expect.throws(() => sink.addStream(new Stream.fromIterable([])));
  Expect.throws(() => sink.close());
  sink.done; // No error.
}


// Test addStream followed by close (pipe).
void testAddStreamClose() {
  asyncStart();
  var list = [1, 2, 3];
  var sink = new StreamSinkAdapter(new TestStreamConsumer(list));
  new Stream.fromIterable(list).pipe(sink).then((_) {
    asyncEnd();
  });
  // Not valid during addStream.
  Expect.throws(() => sink.add(4));
  Expect.throws(() => sink.addError("error"));
  Expect.throws(() => sink.addStream(new Stream.fromIterable([])));
  Expect.throws(() => sink.close());
  sink.done; // No error.
}


// Test several adds followed by addStream and close (pipe).
void testAddAddStreamClose() {
  asyncStart();
  var list = [1, 2, 3, 4, 5, 6];
  var sink = new StreamSinkAdapter(new TestStreamConsumer(list));
  sink.add(1);
  sink.add(2);
  sink.add(3);
  new Stream.fromIterable(list.skip(3)).pipe(sink).then((_) {
    asyncEnd();
  });
  // Not valid during addStream.
  Expect.throws(() => sink.add(4));
  Expect.throws(() => sink.addError("error"));
  Expect.throws(() => sink.addStream(new Stream.fromIterable([])));
  Expect.throws(() => sink.close());
  sink.done; // No error.
}


// Test addError.
void testAddError() {
  asyncStart();
  var sink = new StreamSinkAdapter(new TestStreamConsumer([]));
  new Future.error("error").asStream().pipe(sink).catchError((error) {
    Expect.equals("error", error);
    sink.close();
    asyncEnd();
  });
}


void main() {
  asyncStart();
  testAddClose();
  testAddFlush();
  testAddStreamClose();
  testAddAddStreamClose();
  testAddError();
  asyncEnd();
}
