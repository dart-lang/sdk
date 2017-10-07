// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:io';

void main() {
  HttpServer.bind('127.0.0.1', 0).then((server) {
    server.listen((request) {
      request.response
        ..reasonPhrase = ''
        ..close();
    });

    HttpClient client = new HttpClient();
    client.get("127.0.0.1", server.port, "/").then((HttpClientRequest request) {
      return request.close();
    }).then((HttpClientResponse response) {
      Expect.equals("", response.reasonPhrase);
      server.close();
      client.close();
    });
  });
}
