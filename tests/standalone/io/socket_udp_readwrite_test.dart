// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test writing to unreachable udp socket doesn't cause problems.

import 'dart:async';
import 'dart:typed_data';
import 'dart:io';

import "package:expect/expect.dart";

main() async {
  final _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
  final port = _socket.port;
  final allDone = Completer<bool>()
    ..future.whenComplete(() {
      _socket.close();
    });
  _socket.listen(
    (RawSocketEvent event) {
      print("event: $event");
      switch (event) {
        case RawSocketEvent.read:
          _socket.receive();
          break;
        case RawSocketEvent.write:
          print('received write event $event');
          allDone.complete(true);
          break;
      }
    },
    onError: (e) {
      Expect.fail('Should be no exceptions, but got $e');
    },
  );

  for (int i = 0; i < 100; i++) {
    // Sending data to some non-existent reserved port to trigger
    // the condition.
    _socket.send(Uint8List(10), InternetAddress("127.0.0.1"), 1024);
  }
  _socket.send(Uint8List(10), InternetAddress("127.0.0.1"), port);
}
