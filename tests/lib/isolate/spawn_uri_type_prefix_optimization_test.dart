// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "dart:io";
import "dart:isolate";

import "package:expect/expect.dart";

class Unsendable {}

Future<void> main(args, message) async {
  if (args.contains("child")) {
    var sendPort = message as SendPort;

    var bad = <String, Unsendable?>{"a": null, "b": null};
    Expect.throwsArgumentError(() => sendPort.send(bad));

    var good = bad.keys.toList();
    sendPort.send(good);

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
