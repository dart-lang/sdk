// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "dart:io";
import "dart:isolate";

import "package:expect/expect.dart";

class Foo {}

Type getType<T>() => T;

Future<void> main(args, message) async {
  if (args.contains("child")) {
    var sendPort = message as SendPort;

    sendPort.send(getType<void>());
    sendPort.send(Never);
    sendPort.send(Object);
    sendPort.send(dynamic);

    sendPort.send(Null);
    sendPort.send(bool);

    sendPort.send(int);
    sendPort.send(double);
    sendPort.send(num);

    sendPort.send(String);

    sendPort.send(List);
    sendPort.send(Map);
    sendPort.send(Set);

    sendPort.send(SendPort);
    sendPort.send(Capability);

    sendPort.send(TransferableTypedData);

    Expect.throwsArgumentError(() => sendPort.send(Foo));
    Expect.throwsArgumentError(() => sendPort.send(Socket));
    Expect.throwsArgumentError(() => sendPort.send(getType<List<Foo>>()));

    sendPort.send("done");
    return;
  }

  final receivePort = RawReceivePort();
  receivePort.handler = (msg) {
    if (msg == "done") receivePort.close();
  };
  await Isolate.spawnUri(
      Platform.script, <String>["child"], receivePort.sendPort,
      errorsAreFatal: true);
}
