// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:isolate";
import "package:unittest/unittest.dart";

Uri toDartDataUri(String source) {
  return Uri.parse("data:application/dart;charset=utf-8,"
      "${Uri.encodeComponent(source)}");
}

main() {
  test('Simple response', () {
    String source = """
import "dart:isolate";
main(List args, SendPort replyPort) {
  replyPort.send(42);
}
""";

    RawReceivePort receivePort;
    receivePort = new RawReceivePort(expectAsync((message) {
      expect(message, equals(42));
      receivePort.close();
    }));
    Isolate.spawnUri(toDartDataUri(source), [], receivePort.sendPort);
  });
}
