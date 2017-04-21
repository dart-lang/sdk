// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library isolate_current_test;

import "dart:isolate";
import "dart:async";
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

void main() {
  asyncStart();

  Expect.isNotNull(Isolate.current);

  // Sending controlPort and capabilities as list.
  testSend(i2l, l2i);
  testSpawnReturnVsCurrent(true);
  testSpawnReturnVsCurrent2(true);

  // Sending Isolate itself.
  testSend(id, id);
  testSpawnReturnVsCurrent(false);
  testSpawnReturnVsCurrent2(false);

  asyncEnd();
}

/** Test sending the isolate data or isolate through a [SendPort]. */
void testSend(i2l, l2i) {
  asyncStart();
  RawReceivePort p = new RawReceivePort();
  Isolate isolate = Isolate.current;
  p.handler = (list) {
    var isolate2 = l2i(list);
    Expect.equals(isolate.controlPort, isolate2.controlPort);
    Expect.equals(isolate.pauseCapability, isolate2.pauseCapability);
    Expect.equals(isolate.terminateCapability, isolate2.terminateCapability);
    p.close();
    asyncEnd();
  };
  p.sendPort.send(i2l(isolate));
}

/**
 * Test that the isolate returned by [Isolate.spawn] is the same as
 * the one returned by [Isolate.current] in the spawned isolate.
 * Checked in the spawning isolate.
 */
void testSpawnReturnVsCurrent(bool asList) {
  asyncStart();
  Function transform = asList ? l2i : id;
  Completer response = new Completer();
  var p = new RawReceivePort();
  p.handler = (v) {
    response.complete(transform(v));
    p.close();
  };

  Isolate.spawn(replyCurrent, [p.sendPort, asList]).then((Isolate isolate) {
    return response.future.then((Isolate isolate2) {
      expectIsolateEquals(isolate, isolate2);
      asyncEnd();
    });
  });
}

void replyCurrent(args) {
  SendPort responsePort = args[0];
  Function transform = args[1] ? i2l : id;
  responsePort.send(transform(Isolate.current));
}

/**
 * Test that the isolate returned by [Isolate.spawn] is the same as
 * the one returned by [Isolate.current] in the spawned isolate.
 * Checked in the spawned isolate.
 */
void testSpawnReturnVsCurrent2(bool asList) {
  asyncStart();
  Function transform = asList ? i2l : id;

  Completer response = new Completer();
  var p = new RawReceivePort();
  int state = 0;
  p.handler = (v) {
    switch (state) {
      case 0:
        response.complete(v);
        state++;
        break;
      case 1:
        p.close();
        Expect.isTrue(v);
        asyncEnd();
    }
  };

  Isolate.spawn(expectCurrent, [p.sendPort, asList]).then((Isolate isolate) {
    return response.future.then((SendPort port) {
      port.send(transform(isolate));
    });
  });
}

void expectCurrent(args) {
  SendPort responsePort = args[0];
  Function transform = args[1] ? l2i : id;
  RawReceivePort port = new RawReceivePort();
  port.handler = (isoData) {
    Isolate isolate2 = transform(isoData);
    port.close();
    Isolate isolate = Isolate.current;
    expectIsolateEquals(isolate, isolate2);
    responsePort.send(true);
  };
  responsePort.send(port.sendPort);
}

/** Convert isolate to list (of control port and capabilities). */
i2l(Isolate isolate) =>
    [isolate.controlPort, isolate.pauseCapability, isolate.terminateCapability];
/** Convert list to isolate. */
l2i(List list) => new Isolate(list[0],
    pauseCapability: list[1], terminateCapability: list[2]);

/** Identity transformation. */
id(Isolate isolate) => isolate;

void expectIsolateEquals(Isolate expect, Isolate actual) {
  Expect.equals(expect.controlPort, actual.controlPort);
  Expect.equals(expect.pauseCapability, actual.pauseCapability);
  Expect.equals(expect.terminateCapability, actual.terminateCapability);
}
