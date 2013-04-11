// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "dart:io";
import "dart:isolate";
import "dart:typeddata";

void testClientRequest(void handler(request)) {
  HttpServer.bind().then((server) {
    server.listen((request) {
      request.listen((_) {}, onDone: () {
        request.response.close();
      }, onError: (e) {});
    });

    var client = new HttpClient();
    client.get("127.0.0.1", server.port, "/")
      .then((request) {
        return handler(request);
      })
      .then((response) {
        response.listen((_) {}, onDone: () {
          client.close();
          server.close();
        });
      })
      .catchError((error) {
        server.close();
        client.close();
      });
  });
}

void testResponseDone() {
  testClientRequest((request) {
    request.close().then((res1) {
      request.done.then((res2) {
        Expect.equals(res1, res2);
      });
    });
    return request.done;
  });
}

void testBadResponseAdd() {
  testClientRequest((request) {
    var port = new ReceivePort();
    request.contentLength = 0;
    request.add([0]);
    request.close();
    request.done.catchError((error) {
      port.close();
    }, test: (e) => e is HttpException);
    return request.done;
  });

  testClientRequest((request) {
    var port = new ReceivePort();
    request.contentLength = 5;
    request.add([0, 0, 0]);
    request.add([0, 0, 0]);
    request.close();
    request.done.catchError((error) {
      port.close();
    }, test: (e) => e is HttpException);
    return request.done;
  });

  testClientRequest((request) {
    var port = new ReceivePort();
    request.contentLength = 0;
    request.add(new Uint8List(64 * 1024));
    request.add(new Uint8List(64 * 1024));
    request.add(new Uint8List(64 * 1024));
    request.close();
    request.done.catchError((error) {
      port.close();
    }, test: (e) => e is HttpException);
    return request.done;
  });
}

void testBadResponseClose() {
  testClientRequest((request) {
    var port = new ReceivePort();
    request.contentLength = 5;
    request.close();
    request.done.catchError((error) {
      port.close();
    }, test: (e) => e is HttpException);
    return request.done;
  });

  testClientRequest((request) {
    var port = new ReceivePort();
    request.contentLength = 5;
    request.add([0]);
    request.close();
    request.done.catchError((error) {
      port.close();
    }, test: (e) => e is HttpException);
    return request.done;
  });
}

void main() {
  testResponseDone();
  testBadResponseAdd();
  testBadResponseClose();
}
