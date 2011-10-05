// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('lil_server');

#import('../fling.dart');

void main() {
  // Create a new server.
  HttpServer server = new HttpServer();
  server.handle("/good", (HttpRequest req, HttpResponse res) {
    res.setHeader("Content-Type", "text/plain");
    res.write("path: ".concat(req.requestedPath).concat(", prefix: ").concat(req.prefix));
    res.finish();
  });
  server.handle("/bad", (HttpRequest req, HttpResponse res) {
    res.setStatusCode(500);
    res.finish();
  });
  server.handle("/app/", ClientApp.create("static"));
  server.listen(9090);

  print("Started server at http://localhost:9090/");

  // Runs the message loop.
  Fling.goForth();
}
