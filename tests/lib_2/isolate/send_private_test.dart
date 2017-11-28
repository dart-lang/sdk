// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:isolate";
import "package:expect/expect.dart";

class _Private {
  String data;
  _Private(this.data);
}

void child(message) {
  print("Got message: $message");
  SendPort replyPort = message[0];
  _Private object = message[1];
  Expect.isTrue(object is _Private);
  Expect.equals("XYZ", object.data);
  replyPort.send(object);
}

void main() {
  var port;
  port = new RawReceivePort((message) {
    print("Got reply: $message");
    Expect.isTrue(message is _Private);
    Expect.equals("XYZ", message.data);
    port.close();
  });

  Isolate.spawn(child, [port.sendPort, new _Private("XYZ")]);
}
