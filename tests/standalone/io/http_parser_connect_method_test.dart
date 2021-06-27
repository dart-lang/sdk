// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "dart:io";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

Future<void> test(String header, value) async {
  final connect = "CONNECT";
  final server = await HttpServer.bind("127.0.0.1", 0);
  server.listen((HttpRequest request) {
    Expect.equals(connect, request.method);
    request.response.statusCode = 200;
    request.response.headers.add(header, value);
    request.response.close();
  });

  final completer = Completer<void>();
  HttpClient client = HttpClient();
  client
      .open(connect, "127.0.0.1", server.port, "/")
      .then((HttpClientRequest request) {
    return request.close();
  }).then((HttpClientResponse response) {
    Expect.equals(200, response.statusCode);
    // Headers except Content-Length and Transfer-Encoding header will be read.
    if (header == HttpHeaders.contentLengthHeader ||
        header == HttpHeaders.transferEncodingHeader) {
      Expect.isNull(response.headers[header]);
    } else {
      final list = response.headers[header];
      Expect.isNotNull(list);
      Expect.equals(1, list!.length);
      Expect.equals(value, list[0]);
    }

    client.close(force: true);
    server.close();
    completer.complete();
  });

  await completer.future;
}

Future<void> runTests() async {
  await test(HttpHeaders.contentLengthHeader, 0);
  await test(HttpHeaders.transferEncodingHeader, 'chunked');
  await test('testHeader', 'testValue');
}

main() {
  asyncTest(runTests);
}
