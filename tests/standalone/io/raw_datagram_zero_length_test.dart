// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "dart:io";
import "dart:typed_data";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

main() async {
  asyncStart();
  var address = InternetAddress.loopbackIPv4;
  var sender = await RawDatagramSocket.bind(address, 0);
  var receiver = await RawDatagramSocket.bind(address, 0);

  var sub;
  sub = receiver.listen((event) {
    if (event == RawSocketEvent.read) {
      Expect.isNull(receiver.receive());
    }
    receiver.close();
    sub.cancel();
    asyncEnd();
  });

  sender.send(Uint8List(0), address, receiver.port);
  sender.close();
}
