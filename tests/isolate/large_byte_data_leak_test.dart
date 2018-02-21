// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "dart:isolate";
import "dart:typed_data";
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
  });

  replyPort.send("Done");

  print("Child done");
}

Future<void> main(List<String> args) async {
  print("Parent start");

  ReceivePort port = new ReceivePort();
  Isolate.spawn(child, port.sendPort);
  StreamIterator<dynamic> incoming = new StreamIterator<dynamic>(port);

  Expect.isTrue(await incoming.moveNext());
  dynamic x = incoming.current;
  Expect.equals("Done", x);

  port.close();
  print("Parent done");
}
