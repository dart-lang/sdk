// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that sockets belonging to an isolate are properly cleaned up
// when the isolate shuts down abnormally. If the socket is not properly cleaned
// up, the test will time out.

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:_internal'; // ignore: import_internal_library, unused_import

import "package:expect/async_helper.dart";
import "package:expect/expect.dart";

ConnectorIsolate(Object portObj) async {
  int port = portObj as int;
  Socket socket = await Socket.connect("127.0.0.1", port);
  socket.listen((_) {});
}

main() async {
  asyncStart();
  ServerSocket server = await ServerSocket.bind("127.0.0.1", 0);
  Isolate isolate = await Isolate.spawn(ConnectorIsolate, server.port);
  Completer<Null> completer = new Completer<Null>();
  server.listen((Socket socket) {
    socket.listen(
      (_) {},
      onDone: () {
        print("Socket closed normally");
        completer.complete(null);
        socket.close();
      },
      onError: (e) {
        Expect.fail("Socket error $e");
      },
    );

    final port = ReceivePort();
    port.listen((_) {
      print("Isolate exited - triggering GC");
      // Cause a GC to collect the [socket] from [connectorIsolate].
      VMInternalsForTesting.collectAllGarbage(); // ignore: undefined_identifier
      port.close();
    });
    isolate.addOnExitListener(port.sendPort);

    isolate.kill();
  });
  await completer.future;
  await server.close();
  asyncEnd();
}
