// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Tests socket exceptions.

import "dart:async";
import "dart:io";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

void serverSocketExceptionTest() {
  bool exceptionCaught = false;
  bool wrongExceptionCaught = false;

  ServerSocket.bind("127.0.0.1", 0).then((server) {
    Expect.isNotNull(server);
    server.close();
    try {
      server.close();
    } on SocketException catch (ex) {
      exceptionCaught = true;
    } catch (ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(false, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);

    // Test invalid host.
    ServerSocket.bind("__INVALID_HOST__", 0).then((server) {
      Expect.fail('Connection succeeded.');
    }).catchError((e) => Expect.isTrue(e is SocketException));
  });
}

main() {
  asyncStart();
  serverSocketExceptionTest();
  asyncEnd();
}
