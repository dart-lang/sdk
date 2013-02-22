// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write

import "dart:async";
import "dart:io";
import "dart:isolate";


void main() {
  List<int> message = "GET / HTTP/1.0\r\nHost: www.google.dk\r\n\r\n".charCodes;
  int written = 0;
  List<String> chunks = <String>[];
  SecureSocket.initialize();
  // TODO(3593): Use a Dart HTTPS server for this test.
  RawSecureSocket.connect("www.google.dk", 443).then((socket) {
    socket.listen((RawSocketEvent event) {
      switch (event) {
        case RawSocketEvent.READ:
          var data = socket.read();
          var received = new String.fromCharCodes(data);
          chunks.add(received);
          break;
        case RawSocketEvent.WRITE:
          written +=
              socket.write(message, written, message.length - written);
          if (written < message.length) {
            socket.writeEventsEnabled = true;
          } else {
            socket.shutdown(SocketDirection.SEND);
          }
          break;
        case RawSocketEvent.READ_CLOSED:
          String fullPage = chunks.join();
          Expect.isTrue(fullPage.contains('</body></html>'));
          break;
        default: throw "Unexpected event $event";
      }
    }, onError: (AsyncError a) {
      Expect.fail("onError handler of RawSecureSocket stream hit: $a");
    });
  });
}
