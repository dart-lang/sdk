// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--enable-isolate-groups
// VMOptions=--no-enable-isolate-groups

import "dart:async";
import "dart:developer" show UserTag;
import "dart:isolate" show Isolate, ReceivePort;
import "dart:typed_data" show ByteData;
import "package:expect/expect.dart";

const large = 2 * 1024 * 1024;

void child(replyPort) {
  print("Child start");

  Expect.throws(() {
    replyPort.send([
      new ByteData(large),
      new UserTag("User tags are not allowed in isolate messages"),
      new ByteData(large),
    ]);
    replyPort.send("Not reached");
  }, (e) {
    return e.toString().contains("Illegal argument in isolate message");
  });

  replyPort.send("Done");

  print("Child done");
}

Future<void> main(List<String> args) async {
  print("Parent start");

  ReceivePort port = new ReceivePort();
  Isolate.spawn(child, port.sendPort);

  Expect.equals("Done", await port.first);

  print("Parent done");
}
