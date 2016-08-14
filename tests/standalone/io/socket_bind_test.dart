// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

testBindShared(String host, bool v6Only) {
  asyncStart();
  ServerSocket.bind(
      host, 0, v6Only: v6Only, shared: true).then((socket) {
    Expect.isTrue(socket.port > 0);

    asyncStart();
    return ServerSocket.bind(
        host, socket.port, v6Only: v6Only, shared: true).then((socket2) {
      Expect.equals(socket.address.address, socket2.address.address);
      Expect.equals(socket.port, socket2.port);
      socket.close().whenComplete(asyncEnd);
      socket2.close().whenComplete(asyncEnd);
    });
  });
}

negTestBindSharedMismatch(String host, bool v6Only) {
  asyncStart();
  ServerSocket.bind(host, 0, v6Only: v6Only).then((ServerSocket socket) {
    Expect.isTrue(socket.port > 0);

    asyncStart();
    return ServerSocket.bind(
        host, socket.port, v6Only: v6Only).catchError((error) {
      Expect.isTrue(error is SocketException);
      Expect.isTrue('$error'.contains('shared flag'));
      socket.close().whenComplete(asyncEnd);
      asyncEnd();
    });
  });
}

negTestBindV6OnlyMismatch(String host, bool v6Only) {
  asyncStart();
  ServerSocket.bind(
      host, 0, v6Only: v6Only, shared: true).then((ServerSocket socket) {
    Expect.isTrue(socket.port > 0);

    asyncStart();
    return ServerSocket.bind(
        host, socket.port, v6Only: !v6Only, shared: true)
        .catchError((error) {
      Expect.isTrue(error is SocketException);
      Expect.isTrue('$error'.contains('v6Only flag'));
      socket.close().whenComplete(asyncEnd);
      asyncEnd();
    });
  });
}

Future testBindDifferentAddresses(InternetAddress addr1,
                                  InternetAddress addr2,
                                  bool addr1V6Only,
                                  bool addr2V6Only) async {
  int freePort = await freeIPv4AndIPv6Port();

  var socket = await ServerSocket.bind(
      addr1, freePort, v6Only: addr1V6Only, shared: false);

  try {
    Expect.isTrue(socket.port > 0);

    var socket2 = await ServerSocket.bind(
        addr2, freePort, v6Only: addr2V6Only, shared: false);
    try {
      Expect.equals(socket.port, socket2.port);
    } finally {
      await socket2.close();
    }
  } finally {
    await socket.close();
  }
}

testListenCloseListenClose(String host) async {
  asyncStart();

  ServerSocket socket =
      await ServerSocket.bind(host, 0, shared: true);
  ServerSocket socket2 =
      await ServerSocket.bind(host, socket.port, shared: true);

  var subscription = socket.listen((_) { throw 'error'; });
  subscription.cancel();
  await socket.close();

  // The second socket should have kept the OS socket alive. We can therefore
  // test if it is working correctly.
  asyncStart();
  socket2.first.then((socket) async {
    await socket.drain();
    await socket.close();
    asyncEnd();
  });

  Socket client = await Socket.connect(host, socket2.port);
  await client.close();
  await client.drain();

  asyncEnd();
}

Future<int> freeIPv4AndIPv6Port() async {
  var socket =
    await ServerSocket.bind(InternetAddress.ANY_IP_V6, 0, v6Only: false);
  int port = socket.port;
  await socket.close();
  return port;
}

Future retry(Future fun(), {int maxCount: 10}) async {
  for (int i = 0; i < maxCount; i++) {
    try {
      // If there is no exception this will simply return, otherwise we keep
      // trying.
      return await fun();
    } catch (_) {}
    print("Failed to execute test closure in attempt $i "
          "(${maxCount - i} retries left).");
  }
  return await fun();
}

main() async {
  asyncStart();

  await retry(() async {
    await testBindDifferentAddresses(InternetAddress.ANY_IP_V6,
                                     InternetAddress.ANY_IP_V4,
                                     true,
                                     false);
  });
  await retry(() async {
    await testBindDifferentAddresses(InternetAddress.ANY_IP_V4,
                                     InternetAddress.ANY_IP_V6,
                                     false,
                                     true);
  });

  for (var host in ['127.0.0.1', '::1']) {
    testBindShared(host, false);
    testBindShared(host, true);

    negTestBindSharedMismatch(host, false);
    negTestBindSharedMismatch(host, true);

    negTestBindV6OnlyMismatch(host, true);
    negTestBindV6OnlyMismatch(host, false);

    testListenCloseListenClose(host);
  }
  asyncEnd();
}
