// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--enable-isolate-groups
// VMOptions=--no-enable-isolate-groups
//
// This test checks that sockets belonging to an isolate are properly cleaned up
// when the isolate shuts down abnormally. If the socket is not properly cleaned
// up, the test will time out.

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

connectorIsolate(Object portObj) async {
  int port = portObj;
  Socket socket = await Socket.connect("127.0.0.1", port);
  socket.listen((_) {});
}

main() async {
  asyncStart();
  ServerSocket server = await ServerSocket.bind("127.0.0.1", 0);
  Isolate isolate = await Isolate.spawn(connectorIsolate, server.port);
  Completer<Null> completer = new Completer<Null>();
  server.listen((Socket socket) {
    socket.listen((_) {}, onDone: () {
      print("Socket closed normally");
      completer.complete(null);
      socket.close();
    }, onError: (e) {
      Expect.fail("Socket error $e");
    });
    isolate.kill();

    // Cause a GC to collect the [socket] from [connectorIsolate].
    for (int i = 0; i < 100000; ++i) {
      produceGarbage();
    }
  });
  await completer.future;
  await server.close();
  asyncEnd();
}

@pragma('vm:never-inline')
produceGarbage() => all.add(List(1024));

final all = [];
