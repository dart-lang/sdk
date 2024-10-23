// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test writing to unreachable udp socket doesn't cause problems.

import 'dart:typed_data';
import 'dart:io';

import "package:expect/expect.dart";

main() async {
  var _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 9099);
  _socket.listen((RawSocketEvent event) {
    print("event: $event");
    switch (event) {
      case RawSocketEvent.read:
        Datagram? d = _socket.receive();
        if (d != null) {
          print("recv: $d, all done");
          _socket.close();
        }
        break;
      case RawSocketEvent.write:
        print('received write event $event');
        break;
    }
  }, onError: (e) {
    Expect.fail('Should be no exceptions, but got $e');
  });

  for (int i = 0; i < 100; i++) {
    _socket.send(Uint8List(10), InternetAddress("127.0.0.1"), 9100);
  }
  _socket.send(Uint8List(10), InternetAddress("127.0.0.1"), 9099);
}
