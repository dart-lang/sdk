// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "dart:io";
import "dart:typed_data";

import "package:expect/expect.dart";

void testHostAndPort() {
  ServerSocket.bind("::1", 0).then((server) {
    Socket.connect("::1", server.port).then((clientSocket) {
      server.listen((socket) {
        Expect.equals(socket.port, server.port);
        Expect.equals(clientSocket.port, socket.remotePort);
        Expect.equals(clientSocket.remotePort, socket.port);
        Expect.equals(socket.remoteAddress.address, "::1");
        Expect.equals(socket.remoteAddress.type, InternetAddressType.IPv6);
        Expect.listEquals(socket.remoteAddress.rawAddress,
            [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1]);
        Expect.equals(clientSocket.remoteAddress.address, "::1");
        Expect.equals(
            clientSocket.remoteAddress.type, InternetAddressType.IPv6);
        Expect.listEquals(clientSocket.remoteAddress.rawAddress,
            [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1]);
        socket.destroy();
        clientSocket.destroy();
        server.close();
      });
    });
  });
}

Future<void> testRawAddress() async {
  var list =
      Uint8List.fromList([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1]);
  var addr = '::1';
  var address = InternetAddress.fromRawAddress(list);
  Expect.equals(address.address, addr);
  var server = await ServerSocket.bind(address, 0);
  var client = await Socket.connect(address, server.port);
  var completer = Completer<void>();
  server.listen((socket) async {
    Expect.equals(socket.port, server.port);
    Expect.equals(client.port, socket.remotePort);
    Expect.equals(client.remotePort, socket.port);

    Expect.equals(client.remoteAddress, address);
    socket.destroy();
    client.destroy();
    await server.close();
    completer.complete();
  });
  await completer.future;
}

void main() async {
  testHostAndPort();
  await testRawAddress();
}
