// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Tests socket exceptions.

// @dart = 2.9

import "dart:async";
import "dart:io";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

void main() async {
  asyncStart();

  final server = await ServerSocket.bind("127.0.0.1", 0);
  Socket connectedSocket;
  server.listen((socket) {
    // Note: must keep socket alive for the duration of the test.
    // Otherwise GC might collect it and and shutdown this side of socket
    // which would cause writing to abort.
    connectedSocket = socket;
    // Passive block data by not subscribing to socket.
  }, onDone: asyncEnd);

  final client = await Socket.connect("127.0.0.1", server.port);
  client.listen((data) {}, onDone: server.close);
  client.add(new List.filled(1024 * 1024, 0));
  client.destroy();
}
