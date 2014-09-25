// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library illegal_msg_function_test;

import "dart:isolate";
import "dart:async" show Future;
import "package:unittest/unittest.dart";
import "remote_unittest_helper.dart";

echo(sendPort) {
  var port = new ReceivePort();
  sendPort.send(port.sendPort);
  port.listen((msg) {
    sendPort.send("echoing ${msg(1)}}");
  });
}

void main([args, port]) {
  if (testRemote(main, port)) return;
  test("msg_function", () {
    var function = (x) => x + 2;
    ReceivePort port = new ReceivePort();
    Future spawn = Isolate.spawn(echo, port.sendPort);
    var caught_exception = false;
    var stream = port.asBroadcastStream();
    stream.first.then(expectAsync((snd) {
      try {
        snd.send(function);
      } catch (e) {
        caught_exception = true;
      }

      if (caught_exception) {
        port.close();
      } else {
        stream.first.then(expectAsync((msg) {
          print("from worker ${msg}");
        }));
      }
      expect(caught_exception, isTrue);
    }));
  });
}
