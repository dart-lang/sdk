// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Regression test for http://code.google.com/p/dart/issues/detail?id=6393.

import "dart:io";
import "dart:uri";

var client = new HttpClient();
var clientRequest;

void main() {
  HttpServer.bind("127.0.0.1", 0)
      .then((server) {
        server.listen(
            (req) {
              req.pipe(req.response);
            });

        client.openUrl("POST", Uri.parse("http://localhost:${server.port}/"))
            .then((request) {
              // Keep a reference to the client request object.
              clientRequest = request;
              request.writeBytes([0]);
              return request.response;
            })
            .then((response) {
              // Wait with closing the client request until the response headers
              // are done.
              clientRequest.close();
              response.listen(
                  (_) {},
                  onDone: () {
                    client.close();
                    server.close();
                  });
            });
      });
}
