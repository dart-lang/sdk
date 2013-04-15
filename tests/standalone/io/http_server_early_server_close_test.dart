// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "dart:async";
import "dart:io";
import "dart:isolate";

class Server {
  static Future<int> start() {
    return HttpServer.bind("127.0.0.1", 0).then((server) {
      server.listen((HttpRequest request) {
            Timer.run(server.close);
          }, onError: (e) {
            String msg = "No server errors expected: $e";
            var trace = getAttachedStackTrace(e);
            if (trace != null) msg += "\nStackTrace: $trace";
            Expect.fail(msg);
          });
      return server.port;
    });
  }
}

class Client {
  Client(int port) {
    ReceivePort r = new ReceivePort();
    HttpClient client = new HttpClient();
    client.get("127.0.0.1", port, "/")
        .then((HttpClientRequest request) {
          return request.close();
        })
        .then((HttpClientResponse response) {
          Expect.fail(
              "Response should not be given, as not data was returned.");
        })
        .catchError((e) {
          r.close();
        });
  }
}

main() {
  Server.start().then((port) {
    new Client(port);
  });
}
