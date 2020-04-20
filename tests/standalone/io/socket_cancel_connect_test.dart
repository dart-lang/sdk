// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
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
  asyncStart();
  Duration timeout = new Duration(milliseconds: 20);
  Socket.startConnect("8.8.8.7", 80).then((task) {
    task.socket.timeout(timeout, onTimeout: () {
      task.cancel();
      return task.socket;
    });
    task.socket.then((socket) {
      Expect.fail("Unexpected connection made.");
      asyncEnd();
    }).catchError((e) {
      print(e);
      Expect.isTrue(e is SocketException);
      asyncEnd();
    });
  });
}
