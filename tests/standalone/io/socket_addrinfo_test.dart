// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:expect/expect.dart';
import 'package:expect/async_helper.dart';
import 'package:path/path.dart' as p;

void main() async {
  asyncStart();
  ServerSocket? socket;
  var client = HttpClient();
  try {
    var loopbackAddresses = await InternetAddress.lookup(
      '127.0.0.1',
      type: .IPv4,
    );
    var loopbackAddress = loopbackAddresses.first;
    Expect.isTrue(loopbackAddress.isLoopback);
    Expect.equals(InternetAddressType.IPv4, loopbackAddress.type);

    var server = socket = await ServerSocket.bind(loopbackAddress, 0);
    var httpServer = HttpServer.listenOn(server);

    int serverHits = 0;

    var subscription = httpServer.listen((request) async {
      serverHits++;
      await request.drain();
      request.response
        ..write("ok")
        ..close();
    });

    Expect.equals(0, serverHits);
    var request = await client.getUrl(
      Uri.parse('http://127.0.0.1:${server.port}'),
    );
    var response = await request.close();
    var content = await response.transform(utf8.decoder).join();
    Expect.equals('ok', content);

    Expect.equals(1, serverHits);

    // Legacy inet_aton accepted numeric aliases.
    for (var loopbackAlias in [
      '0x7f.0.0.1',
      '127.0x0.0.1',
      '127.0x0.0.0x1',
      '0x7f.0.1',
      '0x7f.1',
      '127.0.1',
      '127.1',
      '0177.0.0.1',
      '0177.0.1',
      '0177.1',
      '177.0.0.01',
      '177.0.00.1',
      '2130706431',
      '0x7f000001',
    ]) {
      await asyncExpectThrows<SocketException>(
        InternetAddress.lookup(loopbackAlias, type: .IPv4),
        'lookup $loopbackAlias',
      );

      await asyncExpectThrows<SocketException>(
        client.getUrl(Uri.parse('http://$loopbackAlias:${server.port}/')),
        'getUrl $loopbackAlias',
      );
    }

    Expect.equals(1, serverHits);
  } finally {
    client.close(force: true);
    // Test don't need to wait for this,
    // just closing to not keep isolate alive.
    socket?.close().ignore();
  }
  asyncEnd();
}
