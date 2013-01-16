// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library http_server;

import 'dart:io';
import 'dart:isolate';
import 'test_suite.dart';  // For TestUtils.

/**
 * Runs a set of servers that are initialized specifically for the needs of our
 * test framework, such as dealing with package-root.
 */
class TestingServerRunner {
  static List serverList = [];
  static Path _packageRootDir = null;

  // Added as a getter so that the function will be called again each time the
  // default request handler closure is executed.
  static Path get packageRootDir => _packageRootDir;

  static setPackageRootDir(Map configuration) {
    _packageRootDir = TestUtils.currentWorkingDirectory.join(
        new Path(TestUtils.buildDir(configuration)));
  }

  static startHttpServer(String host, {int allowedPort:-1, int port: 0}) {
    var basePath = TestUtils.dartDir();
    var httpServer = new HttpServer();
    var packagesDirName = 'packages';
    httpServer.onError = (e) {
      // TODO(ricow): Once we have a debug log we should write this out there.
      print('Test http server error: $e');
    };
    httpServer.defaultRequestHandler = (request, resp) {
      var requestPath = new Path(request.path.substring(1)).canonicalize();
      var path = basePath.join(requestPath);
      var file = new File(path.toNativePath());

      if (requestPath.segments().contains(packagesDirName)) {
        // Essentially implement the packages path rewriting, so we don't have
        // to pass environment variables to the browsers.
        var requestPathStr = requestPath.toNativePath().substring(
            requestPath.toNativePath().indexOf(packagesDirName));
        path = packageRootDir.append(requestPathStr);
        file = new File(path.toNativePath());
      }
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
          try {
            resp.outputStream.close();
          } catch (e) {
            if (e is StreamException) {
              print('Test http_server error closing the response stream: $e');
            } else {
              throw e;
            }
          }
        }
      });

    };

    // Echos back the contents of the request as the response data.
    httpServer.addRequestHandler((req) => req.path == "/echo", (request, resp) {
      resp.headers.set("Access-Control-Allow-Origin", "*");

      request.inputStream.pipe(resp.outputStream);
    });

    httpServer.listen(host, port);
    serverList.add(httpServer);
  }

  static terminateHttpServers() {
    for (var server in serverList) server.close();
  }
}
