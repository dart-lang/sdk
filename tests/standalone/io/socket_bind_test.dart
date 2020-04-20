// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:expect/expect.dart';

import 'test_utils.dart' show retry, throws;

Future testBindShared(String host, bool v6Only) async {
  final socket = await ServerSocket.bind(host, 0, v6Only: v6Only, shared: true);
  Expect.isTrue(socket.port > 0);

  final socket2 =
      await ServerSocket.bind(host, socket.port, v6Only: v6Only, shared: true);

  Expect.equals(socket.address.address, socket2.address.address);
  Expect.equals(socket.port, socket2.port);

  await socket.close();
  await socket2.close();
}

Future negTestBindSharedMismatch(String host, bool v6Only) async {
  final socket = await ServerSocket.bind(host, 0, v6Only: v6Only);
  Expect.isTrue(socket.port > 0);

  await throws(() => ServerSocket.bind(host, socket.port, v6Only: v6Only),
      (error) => error is SocketException && '$error'.contains('shared flag'));
  await socket.close();
}

Future negTestBindV6OnlyMismatch(String host, bool v6Only) async {
  final socket = await ServerSocket.bind(host, 0, v6Only: v6Only, shared: true);
  Expect.isTrue(socket.port > 0);

  await throws(
      () => ServerSocket.bind(host, socket.port, v6Only: !v6Only, shared: true),
      (error) => error is SocketException && '$error'.contains('v6Only flag'));

  await socket.close();
}

Future testBindDifferentAddresses(InternetAddress addr1, InternetAddress addr2,
    bool addr1V6Only, bool addr2V6Only) async {
  var socket =
      await ServerSocket.bind(addr1, 0, v6Only: addr1V6Only, shared: false);

  try {
    Expect.isTrue(socket.port > 0);

    var socket2 = await ServerSocket.bind(addr2, socket.port,
        v6Only: addr2V6Only, shared: false);
    try {
      Expect.equals(socket.port, socket2.port);
    } finally {
      await socket2.close();
    }
  } finally {
    await socket.close();
  }
}

Future testListenCloseListenClose(String host) async {
  ServerSocket socket = await ServerSocket.bind(host, 0, shared: true);
  ServerSocket socket2 =
      await ServerSocket.bind(host, socket.port, shared: true);

  var subscription = socket.listen((_) {
    throw 'error';
  });
  subscription.cancel();
  await socket.close();

  // The second socket should have kept the OS socket alive. We can therefore
  // test if it is working correctly.

  // For robustness we ignore any clients unrelated to this test.
  final receivedClientPorts = <int>[];
  socket2.listen((Socket client) async {
    receivedClientPorts.add(client.remotePort);
    await Future.wait([client.drain(), client.close()]);
  });

  final client = await Socket.connect(host, socket2.port);
  final clientPort = client.port;
  await client.close();
  await client.drain();

  Expect.isTrue(receivedClientPorts.contains(clientPort));

  // Close the second server socket.
  await socket2.close();
}

main() async {
  await retry(() async {
    await testBindDifferentAddresses(
        InternetAddress.anyIPv6, InternetAddress.anyIPv4, true, false);
  });
  await retry(() async {
    await testBindDifferentAddresses(
        InternetAddress.anyIPv4, InternetAddress.anyIPv6, false, true);
  });

  for (var host in ['127.0.0.1', '::1']) {
    await testBindShared(host, false);
    await testBindShared(host, true);

    await negTestBindSharedMismatch(host, false);
    await negTestBindSharedMismatch(host, true);

    await negTestBindV6OnlyMismatch(host, true);
    await negTestBindV6OnlyMismatch(host, false);

    await testListenCloseListenClose(host);
  }
}
