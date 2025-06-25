// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import "dart:io";

import "package:expect/expect.dart";

Future testCustomPortIPv4() {
  String host = "127.0.0.1";
  int customLocalPort = 50988;
  String customAddress = host;

  return testCustomPort(host, customAddress, customLocalPort);
}

Future testCustomPortIPv6() {
  String host = "::1";
  int customLocalPort = 50989;
  String customAddress = host;

  return testCustomPort(host, customAddress, customLocalPort);
}

Future testCustomPortIPv4NoSourceAddress() {
  String host = "127.0.0.1";
  int customLocalPort = 50990;
  String expectedClientAddress = host;

  return testCustomPortNoSourceAddress(
    host,
    expectedClientAddress,
    customLocalPort,
  );
}

Future testCustomPortIPv6NoSourceAddress() {
  String host = "::1";
  int customLocalPort = 50991;
  String expectedClientAddress = host;

  return testCustomPortNoSourceAddress(
    host,
    expectedClientAddress,
    customLocalPort,
  );
}

Future testNoCustomPortIPv4() {
  String host = "127.0.0.1";
  String clientAddress = host;

  return testNoCustomPort(host, clientAddress);
}

Future testNoCustomPortIPv6() {
  String host = "::1";
  String clientAddress = host;

  return testNoCustomPort(host, clientAddress);
}

Future testNoCustomPortNoSourceAddressIPv4() {
  String host = "127.0.0.1";
  String expectedAddress = host;

  return testNoCustomPortNoSourceAddress(host, expectedAddress);
}

Future testNoCustomPortNoSourceAddressIPv6() {
  String host = "::1";
  String expectedAddress = host;

  return testNoCustomPortNoSourceAddress(host, expectedAddress);
}

// Core functionality

Future testCustomPort(String host, String sourceAddress, int sourcePort) async {
  final serverTestDone = Completer();
  final server = await ServerSocket.bind(host, 0);
  server.listen((Socket client) async {
    Expect.equals(client.remotePort, sourcePort);
    Expect.equals(client.address.address, sourceAddress);
    await (client.close(), client.drain()).wait;
    serverTestDone.complete();
  });
  final client = await Socket.connect(
    host,
    server.port,
    sourceAddress: sourceAddress,
    sourcePort: sourcePort,
  );
  await (client.close(), client.drain()).wait;
  await serverTestDone.future;
  await server.close();
}

Future testCustomPortNoSourceAddress(
  String host,
  String expectedAddress,
  int sourcePort,
) async {
  final serverTestDone = Completer();
  final server = await ServerSocket.bind(host, 0);
  server.listen((Socket client) async {
    Expect.equals(client.remotePort, sourcePort);
    Expect.equals(client.address.address, expectedAddress);
    await (client.close(), client.drain()).wait;
    serverTestDone.complete();
  });
  final client = await Socket.connect(
    host,
    server.port,
    sourcePort: sourcePort,
  );
  await (client.close(), client.drain()).wait;
  await serverTestDone.future;
  await server.close();
}

Future testNoCustomPort(String host, String sourceAddress) async {
  final serverTestDone = Completer();
  final server = await ServerSocket.bind(host, 0);
  server.listen((Socket client) async {
    Expect.equals(client.address.address, sourceAddress);
    await (client.close(), client.drain()).wait;
    serverTestDone.complete();
  });
  final client = await Socket.connect(
    host,
    server.port,
    sourceAddress: sourceAddress,
  );
  await (client.close(), client.drain()).wait;
  await serverTestDone.future;
  await server.close();
}

Future testNoCustomPortNoSourceAddress(
  String host,
  String expectedAddress,
) async {
  final serverTestDone = Completer();
  final server = await ServerSocket.bind(host, 0);
  server.listen((Socket client) async {
    Expect.equals(client.address.address, expectedAddress);
    await (client.close(), client.drain()).wait;
    serverTestDone.complete();
  });
  final client = await Socket.connect(host, server.port);
  await (client.close(), client.drain()).wait;
  await serverTestDone.future;
  await server.close();
}

Future main() async {
  await testCustomPortIPv4();
  await testCustomPortIPv6();

  await testCustomPortIPv4NoSourceAddress();
  await testCustomPortIPv6NoSourceAddress();

  await testNoCustomPortIPv4();
  await testNoCustomPortIPv6();

  await testNoCustomPortNoSourceAddressIPv4();
  await testNoCustomPortNoSourceAddressIPv6();
}
