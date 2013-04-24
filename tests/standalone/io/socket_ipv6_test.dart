// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:isolate';

void testIPv6toIPv6() {
  ServerSocket.bind("::0").then((server) {
    server.listen((socket) {
      socket.destroy();
      server.close();
    });
    Socket.connect("::1", server.port).then((socket) {
      socket.destroy();
    });
  });
}

void testIPv4toIPv6() {
  ServerSocket.bind("::0").then((server) {
    server.listen((socket) {
      socket.destroy();
      server.close();
    });
    Socket.connect("127.0.0.1", server.port).then((socket) {
      socket.destroy();
    });
  });
}

void testIPv6toIPv4() {
  ServerSocket.bind("127.0.0.1").then((server) {
    server.listen((socket) {
      throw "Unexpected socket";
    });
    Socket.connect("::1", server.port).catchError((e) {
      server.close();
    });
  });
}

void testIPv4toIPv4() {
  ServerSocket.bind("127.0.0.1").then((server) {
    server.listen((socket) {
      socket.destroy();
      server.close();
    });
    Socket.connect("127.0.0.1", server.port).then((socket) {
      socket.destroy();
    });
  });
}

void testIPv6Lookup() {
  var port = new ReceivePort();
  InternetAddress.lookup("::0").then((list) {
    if (list.length < 0) throw "no address";
    for (var entry in list) {
      if (entry.type != InternetAddressType.IPv6) {
        throw "Wrong IP type";
      }
    }
    port.close();
  });
}

void testIPv4Lookup() {
  var port = new ReceivePort();
  InternetAddress.lookup("127.0.0.1").then((list) {
    if (list.length < 0) throw "no addresse";
    for (var entry in list) {
      if (entry.type != InternetAddressType.IPv4) {
        throw "Wrong IP type";
      }
    }
    port.close();
  });
}

void main() {
  testIPv6toIPv6();
  testIPv4toIPv6();
  testIPv6toIPv4();
  testIPv4toIPv4();
  testIPv6Lookup();
  testIPv4Lookup();
}
