// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--enable-isolate-groups
// VMOptions=--no-enable-isolate-groups

library CountTest;

import 'dart:isolate';
import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

void countMessages(replyTo) {
  int count = 0;
  var port = new ReceivePort();
  replyTo.send(["init", port.sendPort]);
  port.listen((_message) {
    int message = _message;
    if (message == -1) {
      Expect.equals(count, 10);
      replyTo.send(["done"]);
      port.close();
      return;
    }
    count++;
    Expect.equals(message, count);
    replyTo.send(["count", message * 2]);
  });
}

void main([args, port]) {
  //testRemote(main, port);
  ReceivePort local = new ReceivePort();
  Isolate.spawn(countMessages, local.sendPort);
  SendPort remote;
  int count = 0;
  asyncStart();
  local.listen((msg) {
    switch (msg[0]) {
      case "init":
        Expect.equals(remote, null);
        remote = msg[1];
        remote.send(++count);
        break;
      case "count":
        Expect.equals(msg[1], count * 2);
        if (count == 10) {
          remote.send(-1);
        } else {
          remote.send(++count);
        }
        break;
      case "done":
        Expect.equals(count, 10);
        local.close();
        asyncEnd();
        break;
      default:
        Expect.fail("unreachable: ${msg[0]}");
    }
  });
}
