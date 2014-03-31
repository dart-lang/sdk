// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library RequestReplyTest;

import 'dart:isolate';
import 'package:unittest/unittest.dart';
import "remote_unittest_helper.dart";

void entry(initPort) {
  ReceivePort port = new ReceivePort();
  initPort.send(port.sendPort);
  port.listen((pair) {
    var message = pair[0];
    SendPort replyTo = pair[1];
    replyTo.send(message + 87);
    port.close();
  });
}

void main([args, port]) {
  if (testRemote(main, port)) return;
  test("send", () {
    ReceivePort init = new ReceivePort();
    Isolate.spawn(entry, init.sendPort);
    init.first.then(expectAsync((port) {
      ReceivePort reply = new ReceivePort();
      port.send([99, reply.sendPort]);
      reply.listen(expectAsync((message) {
        expect(message, 99 + 87);
        reply.close();
      }));
    }));
  });
}
