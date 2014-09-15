// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "dart:io";
import "dart:typed_data";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";


main() {
  asyncStart();
  var address = InternetAddress.LOOPBACK_IP_V4;
  RawDatagramSocket.bind(address, 0).then((producer) {
    RawDatagramSocket.bind(address, 0).then((receiver) {
      int sent = 0;
      new Timer.periodic(const Duration(microseconds: 1), (timer) {
        producer.send([0], address, receiver.port);
        sent++;
        if (sent == 100) {
          timer.cancel();
          producer.close();
        }
      });
      var timer;
      receiver.listen((event) {
        if (event != RawSocketEvent.READ) return;
        var datagram = receiver.receive();
        Expect.listEquals([0], datagram.data);
        if (timer != null) timer.cancel();
        timer = new Timer(const Duration(milliseconds: 200), () {
          Expect.isNull(receiver.receive());
          receiver.close();
          asyncEnd();
        });
      });
    });
  });
}

