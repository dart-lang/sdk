// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:async';

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";
import "test_utils.dart" show retry;

const ANY = InternetAddressType.ANY;

Future testIPv6toIPv6() {
  asyncStart();
  return InternetAddress.lookup("::0", type: ANY).then((serverAddr) {
    return InternetAddress.lookup("::1", type: ANY).then((clientAddr) {
      return ServerSocket.bind(serverAddr.first, 0).then((server) {
        Expect.equals('::0', server.address.host);
        Expect.equals('::', server.address.address);
        server.listen((socket) {
          socket.destroy();
          server.close();
          asyncEnd();
        });
        return Socket.connect(clientAddr.first, server.port).then((socket) {
          socket.destroy();
        });
      });
    });
  });
}

Future testIPv4toIPv6() {
  asyncStart();
  return InternetAddress.lookup("::0", type: ANY).then((serverAddr) {
    return ServerSocket.bind(serverAddr.first, 0).then((server) {
      Expect.equals('::0', server.address.host);
      Expect.equals('::', server.address.address);
      server.listen((socket) {
        socket.destroy();
        server.close();
        asyncEnd();
      });
      return Socket.connect("127.0.0.1", server.port).then((socket) {
        socket.destroy();
      });
    });
  });
}

Future testIPv6toIPv4() {
  asyncStart();
  return InternetAddress.lookup("::1", type: ANY).then((clientAddr) {
    return ServerSocket.bind("127.0.0.1", 0).then((server) {
      Expect.equals('127.0.0.1', server.address.host);
      Expect.equals('127.0.0.1', server.address.address);
      server.listen((socket) {
        throw "Unexpected socket";
      });
      return Socket.connect(clientAddr.first, server.port).then((socket) {
        socket.destroy();
        throw "Unexpected connect";
      }, onError: (e) {}).whenComplete(() {
        server.close();
        asyncEnd();
      });
    });
  });
}

Future testIPv4toIPv4() {
  asyncStart();
  return ServerSocket.bind("127.0.0.1", 0).then((server) {
    Expect.equals('127.0.0.1', server.address.host);
    Expect.equals('127.0.0.1', server.address.address);
    server.listen((socket) {
      socket.destroy();
      server.close();
      asyncEnd();
    });
    return Socket.connect("127.0.0.1", server.port).then((socket) {
      socket.destroy();
    });
  });
}

Future testIPv6Lookup() {
  asyncStart();
  return InternetAddress.lookup("::0", type: ANY).then((list) {
    if (list.length < 0) throw "no address";
    for (var entry in list) {
      if (entry.type != InternetAddressType.IP_V6) {
        throw "Wrong IP type";
      }
    }
    asyncEnd();
  });
}

Future testIPv4Lookup() {
  asyncStart();
  return InternetAddress.lookup("127.0.0.1").then((list) {
    if (list.length < 0) throw "no address";
    for (var entry in list) {
      if (entry.type != InternetAddressType.IP_V4) {
        throw "Wrong IP type";
      }
    }
    asyncEnd();
  });
}

Future testIPv4toIPv6_IPV6Only() {
  asyncStart();
  return InternetAddress.lookup("::0", type: ANY).then((serverAddr) {
    return ServerSocket.bind(serverAddr.first, 0, v6Only: true).then((server) {
      server.listen((socket) {
        throw "Unexpected socket";
      });
      return Socket.connect("127.0.0.1", server.port).then((socket) {
        socket.destroy();
        throw "Unexpected connect";
      }, onError: (e) {}).whenComplete(() {
        server.close();
        asyncEnd();
      });
    });
  });
}

main() async {
  await testIPv6toIPv6(); //               //# 01: ok
  await testIPv4toIPv6(); //               //# 02: ok
  await testIPv4toIPv4(); //               //# 03: ok
  await testIPv6Lookup(); //               //# 04: ok
  await testIPv4Lookup(); //               //# 05: ok

  await retry(testIPv6toIPv4); //          //# 06: ok
  await retry(testIPv4toIPv6_IPV6Only); // //# 07: ok
}
