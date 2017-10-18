// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "dart:io";
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

class TestConsumer implements StreamConsumer<List<int>> {
  final List expected;
  final List received = [];

  int addStreamCount = 0;
  int expcetedAddStreamCount;
  bool expectClose;

  TestConsumer(this.expected,
      {this.expectClose: true, this.expcetedAddStreamCount: -1}) {
    if (expectClose) asyncStart();
  }

  Future addStream(Stream stream) {
    addStreamCount++;
    var sub = stream.listen((v) {
      received.addAll(v);
    });
    sub.pause();
    scheduleMicrotask(sub.resume);
    return sub.asFuture();
  }

  void matches(List list) {
    Expect.listEquals(list, received);
  }

  Future close() {
    return new Future.value().then((_) {
      if (expectClose) asyncEnd();
      Expect.listEquals(expected, received);
      if (expcetedAddStreamCount >= 0) {
        Expect.equals(expcetedAddStreamCount, addStreamCount);
      }
    });
  }
}

void testClose() {
  var sink = new IOSink(new TestConsumer([], expcetedAddStreamCount: 0));
  sink.close();
}

void testAddClose() {
  var sink = new IOSink(new TestConsumer([0]));
  sink.add([0]);
  sink.close();

  sink = new IOSink(new TestConsumer([0, 1, 2]));
  sink.add([0]);
  sink.add([1]);
  sink.add([2]);
  sink.close();
}

void testAddFlush() {
  var consumer = new TestConsumer([0, 1, 2]);
  var sink = new IOSink(consumer);
  sink.add([0]);
  sink.flush().then((s) {
    consumer.matches([0]);
    s.add([1]);
    s.add([2]);
    s.flush().then((s) {
      consumer.matches([0, 1, 2]);
      s.close();
    });
  });
}

void testAddStreamClose() {
  {
    var sink = new IOSink(new TestConsumer([0]));
    var controller = new StreamController(sync: true);
    sink.addStream(controller.stream).then((_) {
      sink.close();
    });
    controller.add([0]);
    controller.close();
  }
  {
    var sink = new IOSink(new TestConsumer([0, 1, 2]));
    var controller = new StreamController(sync: true);
    sink.addStream(controller.stream).then((_) {
      sink.close();
    });
    controller.add([0]);
    controller.add([1]);
    controller.add([2]);
    controller.close();
  }
}

void testAddStreamAddClose() {
  {
    var sink = new IOSink(new TestConsumer([0, 1]));
    var controller = new StreamController(sync: true);
    sink.addStream(controller.stream).then((_) {
      sink.add([1]);
      sink.close();
    });
    controller.add([0]);
    controller.close();
  }
}

void main() {
  testClose();
  testAddClose();
  testAddFlush();
  testAddStreamClose();
  testAddStreamAddClose();
}
