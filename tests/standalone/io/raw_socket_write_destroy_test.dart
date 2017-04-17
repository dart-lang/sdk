// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write

import "package:expect/expect.dart";
import "dart:async";
import "dart:io";
import "dart:isolate";

const SERVER_ADDRESS = "127.0.0.1";

void testWriteDestroyServer() {
  int WROTE = 100000;
  RawServerSocket.bind(SERVER_ADDRESS, 0).then((server) {
    server.listen((socket) {
      socket.writeEventsEnabled = false;

      var buffer = new List.filled(WROTE, 0);
      int offset = 0;
      void write() {
        int n = socket.write(buffer, offset, buffer.length - offset);
        offset += n;
        socket.writeEventsEnabled = true;
      }

      socket.listen((e) {
        if (e == RawSocketEvent.WRITE) {
          if (offset == buffer.length) {
            socket.close();
          } else {
            write();
          }
        }
      });
      write();
    });
    RawSocket.connect(SERVER_ADDRESS, server.port).then((socket) {
      var bytes = 0;
      socket.listen((e) {
        if (e == RawSocketEvent.READ) {
          bytes += socket.read().length;
        } else if (e == RawSocketEvent.READ_CLOSED) {
          Expect.equals(WROTE, bytes);
          socket.close();
          server.close();
        }
      });
    });
  });
}

void testWriteDestroyClient() {
  int WROTE = 100000;
  RawServerSocket.bind(SERVER_ADDRESS, 0).then((server) {
    server.listen((socket) {
      var bytes = 0;
      socket.listen((e) {
        if (e == RawSocketEvent.READ) {
          bytes += socket.read().length;
        } else if (e == RawSocketEvent.READ_CLOSED) {
          Expect.equals(WROTE, bytes);
          socket.close();
          server.close();
        }
      });
    });
    RawSocket.connect(SERVER_ADDRESS, server.port).then((socket) {
      socket.writeEventsEnabled = false;

      var buffer = new List.filled(WROTE, 0);
      int offset = 0;
      void write() {
        int n = socket.write(buffer, offset, buffer.length - offset);
        offset += n;
        socket.writeEventsEnabled = true;
      }

      socket.listen((e) {
        if (e == RawSocketEvent.WRITE) {
          if (offset == buffer.length) {
            socket.close();
          } else {
            write();
          }
        }
      });
      write();
    });
  });
}

void main() {
  testWriteDestroyServer();
  testWriteDestroyClient();
}
