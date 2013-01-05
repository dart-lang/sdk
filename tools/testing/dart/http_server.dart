// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library http_server;

import 'dart:io';
import 'dart:isolate';
import 'test_suite.dart';  // For TestUtils.

HttpServer startHttpServer(String host, [int allowedPort = -1]) {
  var basePath = TestUtils.dartDir();
  var httpServer = new HttpServer();
  httpServer.onError = (e) {
    // Consider errors in the builtin http server fatal.
    // Intead of just throwing the exception we print
    // a message that makes it clearer what happened.
    print('Test http server error: $e');
    exit(1);
  };
  httpServer.defaultRequestHandler = (request, resp) {
    var requestPath = new Path(request.path).canonicalize();
    if (!requestPath.isAbsolute) {
      resp.statusCode = HttpStatus.NOT_FOUND;
      resp.outputStream.close();
    } else {
      var path = basePath;
      requestPath.segments().forEach((s) => path = path.append(s));
      var file = new File(path.toNativePath());
      file.exists().then((exists) {
        if (exists) {
          if (allowedPort != -1) {
            // Allow loading from localhost:$allowedPort in browsers.
            resp.headers.set("Access-Control-Allow-Origin",
                "http://127.0.0.1:$allowedPort");
            resp.headers.set('Access-Control-Allow-Credentials', 'true');
          } else {
            // No allowedPort specified. Allow from anywhere (but cross-origin
            // requests *with credentials* will fail because you can't use "*").
            resp.headers.set("Access-Control-Allow-Origin", "*");
          }
          if (path.toNativePath().endsWith('.html')) {
            resp.headers.set('Content-Type', 'text/html');
          } else if (path.toNativePath().endsWith('.js')) {
            resp.headers.set('Content-Type', 'application/javascript');
          } else if (path.toNativePath().endsWith('.dart')) {
            resp.headers.set('Content-Type', 'application/dart');
          }
          file.openInputStream().pipe(resp.outputStream);
        } else {
          resp.statusCode = HttpStatus.NOT_FOUND;
          resp.outputStream.close();
        }
      });
    }
  };

  // Echos back the contents of the request as the response data.
  httpServer.addRequestHandler((req) => req.path == "/echo", (request, resp) {
    resp.headers.set("Access-Control-Allow-Origin", "*");

    request.inputStream.pipe(resp.outputStream);
  });

  httpServer.listen(host, 0);
  return httpServer;
}

terminateHttpServers(List<HttpServer> servers) {
  for (var server in servers) server.close();
}
