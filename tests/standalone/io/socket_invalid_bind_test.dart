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
  // Bind to a unknown DNS name.
  asyncStart();
  ServerSocket.bind("ko.faar.__hest__", 0).then((_) {
    Expect.fail("Failure expected");
  }).catchError((error) {
    Expect.isTrue(error is SocketException);
    asyncEnd();
  });

  // Bind to an unavaliable IP-address.
  asyncStart();
  ServerSocket.bind("8.8.8.8", 0).then((_) {
    Expect.fail("Failure expected");
  }).catchError((error) {
    Expect.isTrue(error is SocketException);
    asyncEnd();
  });

  // Bind to a port already in use.
  asyncStart();
  ServerSocket.bind("127.0.0.1", 0).then((s) {
    ServerSocket.bind("127.0.0.1", s.port).then((t) {
      Expect.fail("Multiple listens on same port");
    }).catchError((error) {
      Expect.isTrue(error is SocketException);
      s.close();
      asyncEnd();
    });
  });
}
