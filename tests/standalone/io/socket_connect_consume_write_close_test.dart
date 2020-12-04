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

void main() {
  // Connect socket write some data immediate close the consumer
  // without listening on the stream.
  asyncStart();
  ServerSocket.bind(InternetAddress.loopbackIPv4, 0).then((server) {
    late Socket ref;
    server.listen((socket) {
      // Create a reference to the connected socket so it's not prematurely
      // collected.
      ref = socket;
    });
    Socket.connect("127.0.0.1", server.port).then((socket) {
      socket.add([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
      socket.close();
      socket.done.then((_) {
        socket.destroy();
        server.close();
        asyncEnd();
      });
    });
  });
}
