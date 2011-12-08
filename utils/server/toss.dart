// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import('../lib/node/node.dart');

void main() {
  http.createServer((req, res) {
    res.statusCode = 200;
    res.setHeader('Content-Type', 'text/plain');
    res.end('Hello World\n');
  }).listen(1337, "127.0.0.1");
  print('Server running at http://127.0.0.1:1337/');
}
