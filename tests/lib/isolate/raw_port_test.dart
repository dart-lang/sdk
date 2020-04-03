// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--enable-isolate-groups
// VMOptions=--no-enable-isolate-groups

// Test RawReceivePort.

library raw_port_test;

import 'dart:async';
import 'dart:isolate';
import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

void remote(SendPort port) {
  port.send("reply");
}

void remote2(SendPort port) {
  port.send("reply 1");
  port.send("reply 2");
}

main([args, port]) async {
  // Raw receive
  asyncTest(() {
    final completer = Completer<void>();
    RawReceivePort port = new RawReceivePort();
    Isolate.spawn(remote, port.sendPort);
    port.handler = (v) {
      Expect.equals(v, "reply");
      port.close();
      completer.complete();
    };
    return completer.future;
  });

  // Raw receive hashCode
  {
    RawReceivePort port = new RawReceivePort();
    Expect.isTrue(port.hashCode is int);
    port.close();
  }

  // Raw receive twice - change handler
  asyncTest(() {
    final completer = Completer<void>();
    RawReceivePort port = new RawReceivePort();
    Isolate.spawn(remote2, port.sendPort);
    port.handler = (v) {
      Expect.equals(v, "reply 1");
      port.handler = (v) {
        Expect.equals(v, "reply 2");
        port.close();
        completer.complete();
      };
    };
    return completer.future;
  });

  // From raw port
  asyncTest(() {
    final completer = Completer<void>();
    RawReceivePort rawPort = new RawReceivePort();
    Isolate.spawn(remote, rawPort.sendPort);
    rawPort.handler = (v) {
      Expect.equals(v, "reply");
      ReceivePort port = new ReceivePort.fromRawReceivePort(rawPort);
      Isolate.spawn(remote, rawPort.sendPort);
      Isolate.spawn(remote, port.sendPort);
      int ctr = 2;
      port.listen(
        (v) {
          Expect.equals(v, "reply");
          ctr--;
          if (ctr == 0) port.close();
        },
        onDone: () => completer.complete(),
      );
    };
    return completer.future;
  });
}
