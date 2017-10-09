// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "dart:io";
import "dart:typed_data";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

void testClientRequest(Future handler(request)) {
  HttpServer.bind("127.0.0.1", 0).then((server) {
    server.listen((request) {
      request.drain().then((_) => request.response.close()).catchError((_) {});
    });

    var client = new HttpClient();
    client
        .get("127.0.0.1", server.port, "/")
        .then((request) {
          return handler(request);
        })
        .then((response) => response.drain())
        .catchError((_) {})
        .whenComplete(() {
          client.close();
          server.close();
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
  asyncStart();
  testClientRequest((request) {
    request.contentLength = 0;
    request.add([0]);
    request.close();
    request.done.catchError((error) {
      asyncEnd();
    }, test: (e) => e is HttpException);
    return request.done;
  });

  asyncStart();
  testClientRequest((request) {
    request.contentLength = 5;
    request.add([0, 0, 0]);
    request.add([0, 0, 0]);
    request.close();
    request.done.catchError((error) {
      asyncEnd();
    }, test: (e) => e is HttpException);
    return request.done;
  });

  asyncStart();
  testClientRequest((request) {
    request.contentLength = 0;
    request.add(new Uint8List(64 * 1024));
    request.add(new Uint8List(64 * 1024));
    request.add(new Uint8List(64 * 1024));
    request.close();
    request.done.catchError((error) {
      asyncEnd();
    }, test: (e) => e is HttpException);
    return request.done;
  });
}

void testBadResponseClose() {
  asyncStart();
  testClientRequest((request) {
    request.contentLength = 5;
    request.close();
    request.done.catchError((error) {
      asyncEnd();
    }, test: (e) => e is HttpException);
    return request.done;
  });

  asyncStart();
  testClientRequest((request) {
    request.contentLength = 5;
    request.add([0]);
    request.close();
    request.done.catchError((error) {
      asyncEnd();
    }, test: (e) => e is HttpException);
    return request.done;
  });
}

void main() {
  testResponseDone();
  testBadResponseAdd();
  testBadResponseClose();
}
