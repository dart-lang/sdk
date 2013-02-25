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
  List<int> message = "GET / HTTP/1.0\r\nHost: www.google.dk\r\n\r\n".codeUnits;
  int written = 0;
  List<String> chunks = <String>[];
  SecureSocket.initialize();
  // TODO(whesse): Use a Dart HTTPS server for this test.
  // The Dart HTTPS server works on bleeding-edge, but not on IOv2.
  // When we use a Dart HTTPS server, allow --short_socket_write. The flag
  // causes fragmentation of the client hello message, which doesn't seem to
  // work with www.google.dk.
  RawSecureSocket.connect("www.google.dk", 443).then((socket) {
    StreamSubscription subscription;
    bool paused = false;
    bool readEventsTested = false;
    bool readEventsPaused = false;

    void runPauseTest() {
      subscription.pause();
      paused = true;
      new Timer(500, (_) {
          paused = false;
          subscription.resume();
      });
    }

    void runReadEventTest() {
      if (readEventsTested) return;
      readEventsTested = true;
      socket.readEventsEnabled = false;
      readEventsPaused = true;
      new Timer(500, (_) {
        readEventsPaused = false;
        socket.readEventsEnabled = true;
      });
    }

    subscription = socket.listen((RawSocketEvent event) {
      Expect.isFalse(paused);
      switch (event) {
        case RawSocketEvent.READ:
          Expect.isFalse(readEventsPaused);
          runReadEventTest();
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
            runPauseTest();
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
