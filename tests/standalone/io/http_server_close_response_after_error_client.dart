// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

void main(List<String> arguments) {
  int port = int.parse(arguments.first);
  var client = new HttpClient();
  const MAX = 64;
  int count = 0;
  void run() {
    if (count++ == MAX) exit(0);
    Socket.connect('127.0.0.1', port).then((socket) {
      socket.write("POST / HTTP/1.1\r\n");
      socket.write("Content-Length: 10\r\n");
      socket.write("\r\n");
      socket.write("LALALA");
      socket.destroy();
      socket.listen(null, onDone: run);
    });
  }

  for (int i = 0; i < 4; i++) run();
}
