// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test case for http://dartbug.com/23244
import 'dart:async';
import 'dart:isolate';
import 'package:async_helper/async_helper.dart';

enum Fisk {
  torsk,
}

isolate1(SendPort port) {
  port.send(Fisk.torsk);
}

isolate2(SendPort port) {
  port.send([Fisk.torsk]);
}

isolate3(SendPort port) {
  var x = new Map<int, Fisk>();
  x[0] = Fisk.torsk;
  x[1] = Fisk.torsk;
  port.send(x);
}

main() async {
  var port = new ReceivePort();
  asyncStart();
  await Isolate.spawn(isolate1, port.sendPort);
  Completer completer1 = new Completer();
  port.listen((message) {
    print("Received $message");
    port.close();
    expectTorsk(message);
    completer1.complete();
  });
  await completer1.future;
  Completer completer2 = new Completer();
  port = new ReceivePort();
  await Isolate.spawn(isolate2, port.sendPort);
  port.listen((message) {
    print("Received $message");
    port.close();
    expectTorsk(message[0]);
    completer2.complete();
  });
  await completer2.future;
  port = new ReceivePort();
  await Isolate.spawn(isolate3, port.sendPort);
  port.listen((message) {
    print("Received $message");
    port.close();
    expectTorsk(message[0]);
    expectTorsk(message[1]);
    asyncEnd();
  });
}

expectTorsk(Fisk fisk) {
  if (fisk != Fisk.torsk) {
    throw "$fisk isn't a ${Fisk.torsk}";
  }
}
