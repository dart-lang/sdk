// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Tests that CR*LF sequence works as well as CRLF in http client parser.

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

import "dart:async";
import "dart:convert";
import "dart:io";
import "dart:isolate";

Future testHttpClient(header) {
  final completer = Completer();
  ServerSocket.bind("127.0.0.1", 0).then((server) async {
    server.listen((socket) async {
      int port = server.port;
      socket.write(header);
      await socket.flush();
      completer.future.catchError((_) {}).whenComplete(() {
        socket.destroy();
      });
    });

    await runZonedGuarded(() {
      var client = new HttpClient();
      client.userAgent = null;
      client
          .get("127.0.0.1", server.port, "/")
          .then((request) => request.close())
          .then((response) {
        response.transform(utf8.decoder).listen((contents) {
          completer.complete();
        }, onDone: () {
          client.close(force: true);
          server.close();
        });
      });
    }, (e, st) {
      server.close();
      completer.completeError(e, st);
    });
  });
  return completer.future;
}

void main() async {
  const good = <String>[
    "HTTP/1.1 200 OK\n\nTest!",
    "HTTP/1.1 200 OK\r\n\nTest!",
    "HTTP/1.1 200 OK\n\r\nTest!",
    "HTTP/1.1 200 OK\r\n\r\nTest!",
  ];
  asyncStart();
  for (final header in good) {
    await testHttpClient(header);
  }
  const bad = <String>[
    "HTTP/1.1 200 OK\n\rTest!",
    "HTTP/1.1 200 OK\r\r\n\nTest!",
    "HTTP/1.1 200 OK\r\rTest!",
    "HTTP/1.1 200 OK\rTest!",
  ];
  for (final header in bad) {
    var caught;
    try {
      await testHttpClient(header);
    } catch (e, st) {
      caught = e;
    }
    Expect.isTrue(caught is HttpException);
  }
  asyncEnd();
}
