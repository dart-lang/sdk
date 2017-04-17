// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:isolate';
import "package:expect/expect.dart";

class FromChildIsolate {
  String toString() => 'from child isolate';
}

main(List<String> args, message) {
  var receivePort = new ReceivePort();
  var sendPort = message;
  sendPort.send(receivePort.sendPort);
  receivePort.listen((msg) {
    Expect.isTrue(msg is SendPort);
    try {
      msg.send(new FromChildIsolate());
    } catch (error) {
      Expect.isTrue(error is ArgumentError);
      msg.send("Invalid Argument(s).");
    }
  }, onError: (e) => print('$e'));
}
