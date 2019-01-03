// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Testing that HttpClient throws an exception if a connection is opened after
// the client is closed. https://github.com/dart-lang/sdk/issues/31492

import "dart:io";
import "package:expect/expect.dart";

void main() {
  HttpServer.bind("127.0.0.1", 0).then((server) {
    server.listen((request) {
      request.listen((_) {});
    });
    var client = new HttpClient();
    client.close();
    Expect.throws<StateError>(() => client.post("127.0.0.1", server.port, "/"));
    server.close();
  });
}
