// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--enable-fast-object-copy

import "dart:isolate";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

echo(message) {
  var string = message[0] as String;
  var replyPort = message[1] as SendPort;
  replyPort.send(string);
}

main() {
  asyncStart();

  // This string is constructed at runtime, so it is not const and won't be
  // identical because of canonicalization. It will only be identical if it is
  // sent by pointer.
  var sentString = "xyz" * 2;

  var port;
  port = new RawReceivePort((message) {
    var receivedString = message as String;

    Expect.identical(sentString, receivedString);

    port.close();
    asyncEnd();
  });

  Isolate.spawn(echo, [sentString, port.sendPort]);
}
