// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This test ensures that one can't send user dart objects to
// an isolate spawned via spawnUri.

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:expect/expect.dart';
import "package:test/test.dart";

class Foo {
  var bar = 123;
}

Future<void> main(args, message) async {
  if (message == null) {
    final receivePort = ReceivePort();
    final isolate = await Isolate.spawnUri(
        Platform.script, <String>[], <SendPort>[receivePort.sendPort],
        errorsAreFatal: true);
    final result = await receivePort.first;
    Expect.equals("done", result);
    return;
  }

  if (args.length > 0) {
    Expect.equals("worker", args[0]);
    final SendPort sendPort = message[0] as SendPort;
    Expect.throws(() => sendPort.send(Foo()));
    sendPort.send("done");
  } else {
    final SendPort sendPort = message[0] as SendPort;

    final receivePort = ReceivePort();
    try {
      final isolate = await Isolate.spawnUri(
          Platform.script, <String>["worker"], <SendPort>[receivePort.sendPort],
          errorsAreFatal: true);
      final result = await receivePort.first;
      Expect.equals("done", result);
      sendPort.send("done");
    } catch (_) {
      sendPort.send("fail");
    }

    sendPort.send("done");
  }
}
