// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Cancelling a SecureSocket connection task after TCP has connected, while
// the TLS handshake is stalled, must close the socket. Otherwise the socket
// leaks and keeps the isolate alive, and this test times out.

import "dart:async";
import "dart:io";

import "package:expect/async_helper.dart";
import "package:expect/expect.dart";

Future<void> main() async {
  asyncStart();
  // A server that accepts TCP connections and never speaks, so the client's
  // TLS handshake never completes.
  final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final accepted = Completer<Socket>();
  server.listen(accepted.complete);

  final task = await SecureSocket.startConnect(
    InternetAddress.loopbackIPv4,
    server.port,
  );
  final serverSide = await accepted.future;

  // The first bytes the server receives are the ClientHello, so once they
  // arrive the client has connected and started the handshake.
  final clientHelloReceived = Completer<void>();
  final clientClosed = Completer<void>();
  serverSide.listen(
    (_) {
      if (!clientHelloReceived.isCompleted) clientHelloReceived.complete();
    },
    onError: (_) {},
    onDone: clientClosed.complete,
  );
  await clientHelloReceived.future;

  task.cancel();

  Object? error;
  try {
    await task.socket;
  } catch (e) {
    error = e;
  }
  Expect.isTrue(error is SocketException, "Expected SocketException: $error");

  // The client end must be closed, which the server sees as end of stream.
  await clientClosed.future;
  serverSide.destroy();
  await server.close();
  asyncEnd();
}
