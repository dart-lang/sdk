// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('http_server');

#import('dart:io');
#import('dart:isolate');
#import('test_suite.dart');  // For TestUtils.

HttpServer _httpServer;

// TODO(ager): Get rid of this when we get the Mac to behave.
int _retries = 10;

Future<bool> startHttpServer(String host, int port) {
  var completer = new Completer();
  var basePath = TestUtils.dartDir();
  _httpServer = new HttpServer();
  _httpServer.onError = (e) {
    // Consider errors in the builtin http server fatal.
    // Intead of just throwing the exception we print
    // a message that makes it clearer what happened.
    print('Test http server error: $e');
    exit(1);
  };
  _httpServer.defaultRequestHandler = (request, resp) {
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
          // Allow loading from localhost in browsers.
          resp.headers.set("Access-Control-Allow-Origin", "*");
          file.openInputStream().pipe(resp.outputStream);
        } else {
          resp.statusCode = HttpStatus.NOT_FOUND;
          resp.outputStream.close();
        }
      });
    }
  };

  // TODO(ager): Get rid of this when we get the mac to behave.
  // Even though we have set the SO_REUSEADDR the mac is not
  // happy and gives us address alread in use errors.
  try {
    _httpServer.listen(host, port);
    completer.complete(true);
  } catch (e) {
    if (_retries-- == 0) {
      completer.completeException(e);
    }
    new Timer(1000, (t) {
      startHttpServer(host, port).then((r) => completer.complete(r));
    });
  }
  return completer.future;
}

terminateHttpServer() {
  _httpServer.close();
}
