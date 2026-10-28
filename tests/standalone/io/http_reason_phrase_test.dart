// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that HttpResponse.reasonPhrase rejects characters that cannot appear
// in a status line.

import "dart:io";

import "package:expect/expect.dart";

const invalidPhrases = [
  "OK\r\nX-Injected: 1",
  "OK\nX-Injected: 1",
  "OK\r",
  "OK\u0000",
  "OK\u007f",
  // Written as one byte per code unit, so these would become CR LF.
  "OK\u010d\u010aX-Injected: 1",
];

void main() async {
  var server = await HttpServer.bind("127.0.0.1", 0);
  server.listen((request) {
    var response = request.response;
    for (var phrase in invalidPhrases) {
      Expect.throwsFormatException(() => response.reasonPhrase = phrase);
    }
    response.reasonPhrase = "Custom\tReason \u00e9";
    response.close();
  });

  var client = HttpClient();
  var request = await client.get("127.0.0.1", server.port, "/");
  var response = await request.close();
  Expect.equals(200, response.statusCode);
  Expect.equals("Custom\tReason \u00e9", response.reasonPhrase);
  Expect.isNull(response.headers.value("x-injected"));
  await response.drain();
  client.close();
  await server.close();
}
