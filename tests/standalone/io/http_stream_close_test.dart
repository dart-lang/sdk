// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//

import "dart:io";

main() {
  bool serverOnClosed = false;
  bool clientOnClosed = false;
  bool requestOnClosed = false;

  HttpServer.bind("127.0.0.1", 0).then((server) {
    var client = new HttpClient();

    checkDone() {
      if (serverOnClosed && clientOnClosed && requestOnClosed) {
        server.close();
        client.close();
      }
    }

    server.listen((request) {
      request.listen((_) {}, onDone: () {
        request.response.done.then((_) {
          serverOnClosed = true;
          checkDone();
        });
        request.response.write("hello!");
        request.response.close();
      });
    });

    client
        .postUrl(Uri.parse("http://127.0.0.1:${server.port}"))
        .then((request) {
      request.contentLength = "hello!".length;
      request.done.then((_) {
        clientOnClosed = true;
        checkDone();
      });
      request.write("hello!");
      return request.close();
    }).then((response) {
      response.listen((_) {}, onDone: () {
        requestOnClosed = true;
        checkDone();
      });
    });
  });
}
