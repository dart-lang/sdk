// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "dart:async";
import "dart:io";
import "dart:isolate";

class TestConsumer implements StreamConsumer {
  final List expected;
  final List received = [];

  var closePort;

  int addStreamCount = 0;
  int expcetedAddStreamCount;

  TestConsumer(this.expected,
               {close: true,
                this.expcetedAddStreamCount: -1}) {
    if (close) closePort = new ReceivePort();
  }

  Future addStream(Stream stream) {
    addStreamCount++;
    return stream.fold(
        received,
        (list, value) {
          list.addAll(value);
          return list;
        })
        .then((_) {});
  }

  Future close() {
    return new Future.value()
      .then((_) {
        if (closePort != null) closePort.close();
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

void testAddStreamClose() {
  {
    var sink = new IOSink(new TestConsumer([0]));
    var controller = new StreamController();
    sink.addStream(controller.stream)
        .then((_) {
          sink.close();
        });
    controller.add([0]);
    controller.close();
  }
  {
    var sink = new IOSink(new TestConsumer([0, 1, 2]));
    var controller = new StreamController();
    sink.addStream(controller.stream)
        .then((_) {
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
    var controller = new StreamController();
    sink.addStream(controller.stream)
        .then((_) {
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
  testAddStreamClose();
  testAddStreamAddClose();
}
