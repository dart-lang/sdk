// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write

// A reason phrase containing CR, LF or NUL would let an application inject
// extra lines into the response status line (response splitting). Setting one
// must be rejected, while a valid custom phrase still reaches the client.

import "dart:async";
import "dart:io";

import "package:expect/expect.dart";

Future<void> reasonPhraseValidation() async {
  final server = await HttpServer.bind("127.0.0.1", 0);
  server.listen((request) {
    final response = request.response;
    for (final phrase in [
      "OK\r\nX-Injected: yes",
      "OK\nX-Injected: yes",
      "OK\rX-Injected: yes",
      "OK\x00bad",
    ]) {
      Expect.throws<ArgumentError>(() => response.reasonPhrase = phrase);
    }
    // A valid custom phrase is still accepted.
    response.reasonPhrase = "Totally Fine";
    response.close();
  });

  final client = HttpClient();
  final request = await client.getUrl(
    Uri.parse("http://127.0.0.1:${server.port}/"),
  );
  final response = await request.close();
  Expect.equals("Totally Fine", response.reasonPhrase);
  // None of the rejected phrases reached the wire, so no header was injected.
  Expect.isNull(response.headers["x-injected"]);
  await response.drain();
  client.close();
  await server.close();
}

void main() async {
  await reasonPhraseValidation();
}
