// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:isolate";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

Uri toDartDataUri(String source) {
  return Uri.parse("data:application/dart;charset=utf-8,"
      "${Uri.encodeComponent(source)}");
}

main() {
  String source = """
import "dart:isolate";
main(List args, SendPort replyPort) {
replyPort.send(42);
}
""";

  RawReceivePort receivePort;
  asyncStart();
  receivePort = new RawReceivePort((message) {
    Expect.equals(message, 42);
    receivePort.close();
    asyncEnd();
  });
  Isolate.spawnUri(toDartDataUri(source), [], receivePort.sendPort);
}
