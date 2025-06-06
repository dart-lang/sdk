// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import "dart:io";

import "package:expect/expect.dart";

Future testCustomPortIPv4() {
  String clientAddress = "127.0.0.1";
  int customLocalPort = 50988;
  String serverAddress = clientAddress;
  int port = 50989;

  return testCustomPort(serverAddress, port, clientAddress, customLocalPort);
}

Future testCustomPortIPv6() {
  String clientAddress = "::1";
  int customLocalPort = 50988;
  String serverAddress = clientAddress;
  int port = 50989;

  return testCustomPort(serverAddress, port, clientAddress, customLocalPort);
}

Future testCustomPortIPv4NoSourceAddress() {
  String expectedClientAddress = "127.0.0.1";
  int customLocalPort = 50988;
  String serverAddress = expectedClientAddress;
  int port = 50989;

  return testCustomPort(
    serverAddress,
    port,
    expectedClientAddress,
    customLocalPort,
  );
}

Future testCustomPortIPv6NoSourceAddress() {
  String expectedClientAddress = "::1";
  int customLocalPort = 50988;
  String serverAddress = expectedClientAddress;
  int port = 50989;

  return testCustomPort(
    serverAddress,
    port,
    expectedClientAddress,
    customLocalPort,
  );
}

Future testNoCustomPortIPv4() {
  String host = "127.0.0.1";
  String clientAddress = host;
  int serverPort = 39998;

  return testNoCustomPortNoSourceAddress(host, serverPort, clientAddress);
}

Future testNoCustomPortIPv6() {
  String host = "::1";
  String clientAddress = host;
  int serverPort = 39998;

  return testNoCustomPortNoSourceAddress(host, serverPort, clientAddress);
}

Future testNoCustomPortNoSourceAddressIPv4() {
  String host = "127.0.0.1";
  String expectedAddress = host;
  int serverPort = 39998;

  return testNoCustomPortNoSourceAddress(host, serverPort, expectedAddress);
}

Future testNoCustomPortNoSourceAddressIPv6() {
  String host = "::1";
  String expectedAddress = host;
  int serverPort = 39998;

  return testNoCustomPortNoSourceAddress(host, serverPort, expectedAddress);
}

// Core functionality
Future testCustomPort(
  String host,
  int port,
  String sourceAddress,
  int sourcePort,
) async {
  var server = await ServerSocket.bind(host, port);
  server.listen((client) {
    Expect.equals(server.port, port);
    Expect.equals(client.remotePort, sourcePort);
    Expect.equals(client.address.address, sourceAddress);
    client.destroy();
  });

  Socket s = await Socket.connect(
    host,
    port,
    sourceAddress: sourceAddress,
    sourcePort: sourcePort,
  );
  s.destroy();
  await server.close();
}

Future testCustomPortNoSourceAddress(
  String host,
  int port,
  String expectedAddress,
  int sourcePort,
) async {
  Completer completer = new Completer();
  var server = await ServerSocket.bind(host, port);

  server.listen((client) {
    Expect.equals(server.port, port);
    Expect.equals(client.remotePort, sourcePort);
    Expect.equals(client.address.address, expectedAddress);
    client.destroy();
    completer.complete();
  });

  Socket s = await Socket.connect(host, port, sourcePort: sourcePort);
  s.destroy();
  await server.close();

  return completer.future;
}

Future testNoCustomPort(String host, int port, String sourceAddress) async {
  Completer serverCompleter = new Completer();
  Completer clientCompleter = new Completer();
  var server = await ServerSocket.bind(host, port);
  Socket.connect(host, port, sourceAddress: sourceAddress).then((
    clientSocket,
  ) async {
    server.listen((client) async {
      Expect.equals(server.port, port);
      Expect.equals(client.remotePort, clientSocket.port);
      Expect.equals(client.address.address, sourceAddress);

      client.destroy();
      clientCompleter.complete();
    });

    clientSocket.destroy();
    await server.close();
    serverCompleter.complete();
  });

  await serverCompleter.future;
  await clientCompleter.future;
}

Future testNoCustomPortNoSourceAddress(
  String host,
  int port,
  String expectedAddress,
) async {
  Completer completer = new Completer();
  var server = await ServerSocket.bind(host, port);
  Socket.connect(host, port).then((clientSocket) {
    server.listen((client) async {
      Expect.equals(server.port, port);
      Expect.equals(client.remotePort, clientSocket.port);
      Expect.equals(client.address.address, expectedAddress);
      clientSocket.destroy();
      client.destroy();
      await server.close();
      completer.complete();
    });
  });
  return completer.future;
}

Future main() async {
  await testCustomPortIPv4();
  await testCustomPortIPv6();

  await testNoCustomPortIPv4();
  await testNoCustomPortIPv6();

  await testNoCustomPortNoSourceAddressIPv4();
  await testNoCustomPortNoSourceAddressIPv6();
}
