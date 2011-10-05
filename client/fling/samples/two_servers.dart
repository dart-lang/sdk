// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('two_servers');

#import('../fling.dart');

void main() {
  int count = 0;
  HttpRequestHandler handler = (HttpRequest req, HttpResponse res) {
    res.setHeader('Content-Type', 'text/plain');
    res.write('count: '.concat(count.toString()));
    res.finish();
    count++;
  };

  HttpServer a = new HttpServer();
  a.handle('/', handler);
  a.listen(9191);

  HttpServer b = new HttpServer();
  b.handle('/', handler);
  b.listen(9292);

  Fling.goForth();
}
