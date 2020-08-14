// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test whether localhost connection succeeds even when insecure connections
// are banned by default.
// SharedOptions=-Ddart.library.io.may_insecurely_connect_to_all_domains=false

import 'dart:async';
import 'dart:io';

import "package:async_helper/async_helper.dart";

void testDisallowedConnectionByDefault() {
  asyncExpectThrows(
      () async => await Socket.connect("domain.invalid", 80),
      (e) =>
          e is SocketException &&
          e.message.contains(
              "Insecure socket connections are disallowed by platform"));
}

Future<void> testLocalhostConnection() async {
  ServerSocket server =
      await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  Socket? socket;
  try {
    server.listen((_) {});
    socket = await Socket.connect(InternetAddress.loopbackIPv4, server.port);
  } finally {
    server.close();
    if (socket != null) {
      socket.close();
      await socket.done;
      socket.destroy();
    }
  }
}

Future<void> test() async {
  testDisallowedConnectionByDefault();
  await testLocalhostConnection();
}

void main() {
  asyncStart();
  test().whenComplete(() => asyncEnd());
}
