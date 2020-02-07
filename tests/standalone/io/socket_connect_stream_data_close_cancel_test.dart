// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write

import "dart:async";
import "dart:io";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

void testConnectStreamDataCloseCancel(bool useDestroy) {
  List<int> sendData = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
  asyncStart();
  ServerSocket.bind(InternetAddress.loopbackIPv4, 0).then((server) {
    server.listen((client) {
      client.add(sendData);
      if (useDestroy) {
        client.destroy();
      } else {
        client.close();
      }
      client.done.then((_) {
        if (!useDestroy) client.destroy();
      }).catchError((e) {/* can happen with short writes */});
    });
    Socket.connect("127.0.0.1", server.port).then((socket) {
      List<int> data = [];
      bool onDoneCalled = false;
      var subscription;
      subscription = socket.listen((_) {
        subscription.cancel();
        socket.close();
        server.close();
        asyncEnd();
      }, onDone: () {
        Expect.fail("Unexpected pipe completion");
      });
    });
  });
}

main() {
  testConnectStreamDataCloseCancel(true);
  testConnectStreamDataCloseCancel(false);
}
