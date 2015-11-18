// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

// Spawn an isolate |foo| that will continue trying to spawn isolates even after
// the timer in |main| completes. This test ensures that the VM can shutdown
// correctly even while an isolate is attempting to spawn more isolates.

isolate1(sendPort) {
  var receivePort = new ReceivePort();
  sendPort.send(receivePort.sendPort);
  receivePort.listen((msg) {});
}

void foo(_) {
  while (true) {
    var receivePort = new ReceivePort();
    Isolate.spawn(isolate1, receivePort.sendPort);
    receivePort.listen((sendPort) {
      Isolate.spawn(isolate1,sendPort);
      receivePort.close();
    });
  }
}

void main() {
  Isolate.spawn(foo, null);
  new Timer(const Duration(seconds: 10), () {});
}
