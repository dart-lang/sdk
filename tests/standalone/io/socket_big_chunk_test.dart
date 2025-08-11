// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";
import "dart:typed_data";

import "package:expect/async_helper.dart";
import "package:expect/expect.dart";

Future<void> main() async {
  asyncStart();

  Uint8List data = new Uint8List(100 * 1024 * 1024);
  final HttpServer server = await HttpServer.bind('127.0.0.1', 0);
  print("Listening on 127.0.0.1:${server.port}");

  server.listen((HttpRequest request) {
    print("Handling request...");
    final HttpResponse response = request.response;
    response.add(data);
    response.close();
  });

  HttpClient client = new HttpClient();
  HttpClientRequest clientResult = await client.get(
    '127.0.0.1',
    server.port,
    'foo',
  );
  HttpClientResponse response = await clientResult.close();
  print("Client result closed");
  int totalLength = 0;
  await for (List<int> data in response) {
    totalLength += data.length;
    print(
      "Got chunk of size ${data.length}. "
      "Total received is now $totalLength.",
    );
  }
  print("Client done.");
  Expect.equals(data.length, totalLength);

  client.close();
  await server.close();

  asyncEnd();
}
