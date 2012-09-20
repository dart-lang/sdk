// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This file runs a trivial HTTP server to serve locale data files from the
 * intl/lib/src/data directory. The code is primarily copied from the dart:io
 * example at http://www.dartlang.org/articles/io/
 */

#import('dart:io');
#import('dart:isolate');

var server = new HttpServer();

_send404(HttpResponse response) {
  response.statusCode = HttpStatus.NOT_FOUND;
  response.outputStream.close();
}

startServer(String basePath) {
  server.listen('127.0.0.1', 8000);
  server.defaultRequestHandler = (HttpRequest request, HttpResponse response) {
    var path = request.path;
    if (path == '/terminate') {
      server.close();
      return;
    }
    final File file = new File('${basePath}${path}');
    file.exists().then((bool found) {
      if (found) {
        // Set the CORS header to allow us to issue requests to localhost when
        // the HTML was opened from a file.
        response.headers.set("Access-Control-Allow-Origin", "*");
        file.fullPath().then((String fullPath) {
            file.openInputStream().pipe(response.outputStream);
        });
      } else {
        _send404(response);
      }
    });
  };
}

main() {
  // Compute base path for the request based on the location of the
  // script and then start the server.
  File script = new File(new Options().script);
  script.directory().then((Directory d) {
    startServer('${d.path}/../lib/src/data');
  });
  // After 60 seconds, if we haven't already been told to terminate, shut down
  // the server, at which point the program exits.
  new Timer(60000, (t) {server.close();});
}