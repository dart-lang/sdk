// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write

import "dart:isolate";
import "dart:io";

void main() {
  ReceivePort keepAlive = new ReceivePort();
  SecureSocket.initialize();
  List<String> chunks = <String>[];
  SecureSocket.connect("www.google.dk", 443).then((socket) {
    socket.add("GET / HTTP/1.0\r\nHost: www.google.dk\r\n\r\n".charCodes);
    socket.close();
    socket.listen(
      (List<int> data) {
        var received = new String.fromCharCodes(data);
        chunks.add(received);
      },
      onDone: () {
        String fullPage = chunks.join();
        Expect.isTrue(fullPage.contains('</body></html>'));
        keepAlive.close();
      },
      onError: (e) => Expect.fail("Unexpected error $e"));
  });
}
