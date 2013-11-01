// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library illegal_msg_function_test;

import "package:expect/expect.dart";
import "dart:isolate";
import "dart:async" show Future;
import "package:async_helper/async_helper.dart";

funcFoo(x) => x + 2;

echo(sendPort) {
  var port = new ReceivePort();
  sendPort.send(port.sendPort);
  port.listen((msg) {
    sendPort.send("echoing ${msg(1)}}");
  });
}

main() {
  var function = funcFoo;

  ReceivePort port = new ReceivePort();
  Future spawn = Isolate.spawn(echo, port.sendPort);
  var caught_exception = false;
  var stream = port.asBroadcastStream();
  asyncStart();
  stream.first.then((snd) {
    try {
      snd.send(function);
    } catch (e) {
      caught_exception = true;
    }

    if (caught_exception) {
      port.close();
    } else {
      asyncStart();
      stream.first.then((msg) {
        print("from worker ${msg}");
        asyncEnd();
      });
    }
    Expect.isTrue(caught_exception);
    asyncEnd();
  });
}
