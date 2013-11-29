// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library illegal_msg_mirror_test;

import "dart:isolate";
import "dart:async" show Future;
@MirrorsUsed(targets: "Class")
import "dart:mirrors";
import "package:unittest/unittest.dart";
import "remote_unittest_helper.dart";

class Class {
  method() {}
}

echo(sendPort) {
  var port = new ReceivePort();
  sendPort.send(port.sendPort);
  port.listen((msg) {
    sendPort.send("echoing ${msg(1)}}");
  });
}

void main([args, port]) {
  if (testRemote(main, port)) return;
  test("msg-mirror", () {
    var methodMirror = reflectClass(Class).declarations[#method];

    ReceivePort port = new ReceivePort();
    Future spawn = Isolate.spawn(echo, port.sendPort);
    var caught_exception = false;
    var stream = port.asBroadcastStream();
    stream.first.then(expectAsync1((snd) {
      try {
        snd.send(methodMirror);
      } catch (e) {
        caught_exception = true;
      }

      if (caught_exception) {
        port.close();
      } else {
        stream.first.then(expectAsync1((msg) {
          print("from worker ${msg}");
        }));
      }
      expect(caught_exception, isTrue);
    }));
  });
}
