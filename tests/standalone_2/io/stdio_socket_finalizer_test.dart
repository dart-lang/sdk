// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This test checks that stdin is *not* closed when an Isolate leaks it.

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

void ConnectorIsolate(Object sendPortObj) {
  SendPort sendPort = sendPortObj;
  stdin;
  sendPort.send(true);
}

main() async {
  asyncStart();
  ReceivePort receivePort = new ReceivePort();
  Isolate isolate = await Isolate.spawn(ConnectorIsolate, receivePort.sendPort);
  Completer<Null> completer = new Completer<Null>();
  receivePort.listen((msg) {
    Expect.isTrue(msg is bool);
    Expect.isTrue(msg);
    isolate.kill();
    completer.complete(null);
  });
  await completer.future;
  stdin.listen((_) {}).cancel();
  receivePort.close();
  asyncEnd();
}
