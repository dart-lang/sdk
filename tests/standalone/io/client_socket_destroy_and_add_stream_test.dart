// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that adding a stream to a `Socket` that has been `destroy`ed returns
// a `Future` that completes.

import "dart:async";
import "dart:io";

import "package:expect/async_helper.dart";
import "package:expect/expect.dart";

void main() async {
  asyncStart();

  final server = await ServerSocket.bind("127.0.0.1", 0);
  late final Socket connectedSocket;
  server.listen((socket) {
    // Note: must keep socket alive for the duration of the test.
    // Otherwise GC might collect it and and shutdown this side of socket
    // which would cause writing to abort.
    connectedSocket = socket;
    // Passive block data by not subscribing to socket.
  });

  final client = await Socket.connect("127.0.0.1", server.port);
  client.listen((data) {}, onDone: server.close);
  client.add(new List.filled(1024 * 1024, 0));
  client.destroy();
  await client.addStream(Stream.fromIterable([
    [1, 2, 3, 4]
  ]));
  asyncEnd();
}
