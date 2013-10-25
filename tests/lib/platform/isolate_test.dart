// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:platform" as platform;

import "dart:isolate";
import "package:unittest/unittest.dart";

sendReceive(SendPort port, msg) {
  var response = new ReceivePort();
  port.send([msg, response.sendPort]);
  return response.first;
}

main() {
  test("platform in isolate", () {
    var response = new ReceivePort();
    Isolate.spawn(f, response.sendPort);
    response.first.then(expectAsync1((sendPort) {
      expect(sendReceive(sendPort, "platform.executable"),
            completion(platform.executable));
      if (platform.script != null) {
        expect(sendReceive(sendPort, "platform.script").then((s) => s.path),
              completion(endsWith('tests/lib/platform/isolate_test.dart')));
      }
      expect(sendReceive(sendPort, "platform.packageRoot"),
            completion(platform.packageRoot));
      expect(sendReceive(sendPort, "platform.executableArguments"),
            completion(platform.executableArguments));
    }));
  });
}

void f(initialReplyTo) {
  var port = new ReceivePort();
  initialReplyTo.send(port.sendPort);
  int count = 0;
  port.listen((msg) {
    var data = msg[0];
    var replyTo = msg[1];
    if (data == "platform.executable") {
      replyTo.send(platform.executable);
    }
    if (data == "platform.script") {
      replyTo.send(platform.script);
    }
    if (data == "platform.packageRoot") {
      replyTo.send(platform.packageRoot);
    }
    if (data == "platform.executableArguments") {
      replyTo.send(platform.executableArguments);
    }
    count++;
    if (count == 4) {
      port.close();
    }
  });
}
