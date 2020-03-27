// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "dart:io";
import "package:expect/expect.dart";

test(String header, value) async {
  final connect = "CONNECT";
  var server = await HttpServer.bind("127.0.0.1", 0);
  server.listen((HttpRequest request) {
    Expect.equals(connect, request.method);
    request.response.statusCode = 200;
    request.response.headers.add(header, value);
    request.response.close();
  });

  var completer = Completer();
  HttpClient client = HttpClient();
  client
      .open(connect, "127.0.0.1", server.port, "/")
      .then((HttpClientRequest request) {
    return request.close();
  }).then((HttpClientResponse response) {
    Expect.isTrue(response.statusCode == 200);
    Expect.isNull(response.headers[header]);
    client.close();
    server.close();
    completer.complete();
  });

  await completer.future;
}

main() async {
  await test(HttpHeaders.contentLengthHeader, 0);
  await test(HttpHeaders.transferEncodingHeader, 'chunked');
}
