// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

// Test that closing a large amount of servers will not lead to a stack
// overflow.
Future<void> main() async {
  final max = 10000;
  final servers = <ServerSocket>[];
  for (var i = 0; i < max; i++) {
    final server = await ServerSocket.bind("localhost", 0);
    server.listen((Socket socket) {});
    servers.add(server);
  }
  final client = HttpClient();
  var got = 0;
  for (var i = 0; i < max; i++) {
    new Future(() async {
      try {
        final request = await client
            .getUrl(Uri.parse("http://localhost:${servers[i].port}/"));
        got++;
        if (got == max) {
          // Test that no stack overflow happens.
          client.close(force: true);
          for (final server in servers) {
            server.close();
          }
        }
        final response = await request.close();
        response.drain();
      } on HttpException catch (_) {}
    });
  }
}
