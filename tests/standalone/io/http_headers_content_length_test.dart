// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";

import "package:expect/expect.dart";

Future<void> main() async {
  final server = await HttpServer.bind("localhost", 0);
  final request = await HttpClient().get("localhost", server.port, "/");
  final headers = request.headers;
  headers.contentLength = 100;
  headers.set('Content-Length', 100);
  Expect.equals('100', headers['Content-Length']?[0]);
  try {
    await request.close();
  } catch (e) {
    server.close();
  }
}
