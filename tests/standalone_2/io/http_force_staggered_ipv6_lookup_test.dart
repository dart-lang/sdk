// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// SharedOptions=-Ddart.library.io.force_staggered_ipv6_lookup=true
//

// @dart = 2.9

import "dart:io";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

const sampleData = <int>[1, 2, 3, 4, 5];

void testBadHostName() {
  asyncStart();
  HttpClient client = new HttpClient();
  client.get("some.bad.host.name.7654321", 0, "/").then((request) {
    Expect.fail("Should not open a request on bad hostname");
  }).catchError((error) {
    asyncEnd(); // We expect onError to be called, due to bad host name.
  }, test: (error) => error is! String);
}

void testConnect(InternetAddress loopback, {int expectedElapsedMs: 0}) async {
  asyncStart();
  final max = 10;
  final servers = <ServerSocket>[];
  for (var i = 0; i < max; i++) {
    final server = await ServerSocket.bind(loopback, 0);
    server.listen((Socket socket) {
      socket.add(sampleData);
      socket.destroy();
    });
    servers.add(server);
  }
  final sw = Stopwatch()..start();
  var got = 0;
  for (var i = 0; i < max; i++) {
    final client = await Socket.connect('localhost', servers[i].port,
        sourceAddress: loopback);
    client.listen((received) {
      Expect.listEquals(sampleData, received);
    }, onError: (e) {
      Expect.fail('Unexpected failure $e');
    }, onDone: () {
      client.close();
      got++;
      if (got == max) {
        // Test that no stack overflow happens.
        for (final server in servers) {
          server.close();
        }
        Expect.isTrue(sw.elapsedMilliseconds > expectedElapsedMs);
        asyncEnd();
      }
    });
  }
}

void main() async {
  asyncStart();
  testBadHostName();
  var localhosts = await InternetAddress.lookup('localhost');
  if (localhosts.contains(InternetAddress.loopbackIPv4)) {
    testConnect(InternetAddress.loopbackIPv4);
  }
  if (localhosts.contains(InternetAddress.loopbackIPv6)) {
    // matches value in socket_patch.dart
    const concurrentLookupDelay = Duration(milliseconds: 10);
    testConnect(InternetAddress.loopbackIPv6,
        expectedElapsedMs: concurrentLookupDelay.inMilliseconds);
  }
  asyncEnd();
}
