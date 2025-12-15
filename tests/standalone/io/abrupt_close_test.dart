// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that Socket.setOption does not crash when socket closes due to
// an error.

import 'dart:async';
import 'dart:io';

import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';

void main(List<String> args) async {
  var clientDone = false;
  var serverDone = false;

  asyncStart();
  // Start the server which will accept a connection and then immediately
  // shutdown itself and the incoming connection.
  final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  late final StreamSubscription serverSub;
  serverSub = server.listen((socket) async {
    socket.destroy();
    serverSub.cancel();
    server.close();
    serverDone = true;
  });

  // Connect to the server and trigger a socket error by writing into a closed
  // socket (because server shuts down immediately after accepting the
  // connection).
  final socket = await Socket.connect(
    InternetAddress.loopbackIPv4,
    server.port,
  );
  final clientSub = socket.listen(
    (_) {},
    onDone: () {
      clientDone = true;
    },
    onError: (e) {},
  );
  socket.add([0]);
  socket.flush().ignore(); // Ignore write error, otherwise it will be uncaught.

  // Now repeat
  await Future.delayed(Duration(milliseconds: 10));
  for (var i = 0; i < 1000; i++) {
    try {
      socket.setOption(SocketOption.tcpNoDelay, true);
    } on SocketException catch (e) {
      // We expect SocketException.closed() but no other error.
      if (e.message != SocketException.closed().message) {
        rethrow;
      }
    }

    await Future.delayed(Duration(milliseconds: 1));
  }
  Expect.isTrue(clientDone);
  Expect.isTrue(serverDone);
  socket.destroy();
  asyncEnd();
}
