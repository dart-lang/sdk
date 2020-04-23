// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--enable-isolate-groups
// VMOptions=--no-enable-isolate-groups

import "dart:async";
import "dart:isolate";
import "dart:typed_data";
import "package:expect/expect.dart";

const large = 1 << 30;

void child(replyPort) {
  print("Child start");

  print("Child Uint8List");
  dynamic x = new Uint8List(large);
  for (int i = 0; i < 4; i++) {
    x[i] = i;
  }
  for (int i = x.length - 4; i < x.length; i++) {
    x[i] = x.length - i;
  }
  replyPort.send(x);
  x = null;

  // Too slow.
  // print("Child Array");
  // x = new List(large);
  // for (int i = 0; i < 4; i++) {
  //   x[i] = i;
  // }
  // replyPort.send(x);
  // x = null;

  print("Child OneByteString");
  x = null;
  x = "Z";
  while (x.length < large) {
    x = x * 2;
  }
  replyPort.send(x);
  x = null;

  print("Child done");
}

Future<void> main(List<String> args) async {
  print("Parent start");

  ReceivePort port = new ReceivePort();
  Isolate.spawn(child, port.sendPort);
  StreamIterator<dynamic> incoming = new StreamIterator<dynamic>(port);

  print("Parent Uint8");
  Expect.isTrue(await incoming.moveNext());
  dynamic x = incoming.current;
  Expect.isTrue(x is Uint8List);
  Expect.equals(large, x.length);
  for (int i = 0; i < 4; i++) {
    Expect.equals(i, x[i]);
  }
  for (int i = x.length - 4; i < x.length; i++) {
    Expect.equals(x.length - i, x[i]);
  }
  x = null;

  // Too slow.
  // print("Parent Array");
  // Expect.isTrue(await incoming.moveNext());
  // x = incoming.current;
  // Expect.isTrue(x is List);
  // Expect.equals(large, x.length);
  // for (int i = 0; i < 4; i++) {
  //   Expect.equals(i, x[i]);
  // }
  // x = null;

  print("Parent OneByteString");
  Expect.isTrue(await incoming.moveNext());
  x = incoming.current;
  Expect.isTrue(x is String);
  Expect.equals(large, x.length);
  for (int i = 0; i < 4; i++) {
    Expect.equals("Z", x[i]);
  }
  for (int i = x.length - 4; i < x.length; i++) {
    Expect.equals("Z", x[i]);
  }
  x = null;

  port.close();
  print("Parent done");
}
