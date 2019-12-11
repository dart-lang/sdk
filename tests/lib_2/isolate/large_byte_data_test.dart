// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--enable-isolate-groups
// VMOptions=--no-enable-isolate-groups

import "dart:async";
import "dart:isolate";
import "dart:typed_data";
import "package:expect/expect.dart";

const large = 2 * 1024 * 1024;

void child(replyPort) {
  print("Child start");

  print("Child ByteData");
  dynamic x = new ByteData(large);
  for (int i = 0; i < 4; i++) {
    x.setInt8(i, i);
  }
  replyPort.send(x);

  print("Child Uint8List");
  x = new Uint8List(large);
  for (int i = 0; i < 4; i++) {
    x[i] = i;
  }
  replyPort.send(x);

  print("Child Int8List");
  x = new Int8List(large);
  for (int i = 0; i < 4; i++) {
    x[i] = i;
  }
  replyPort.send(x);

  print("Child Uint16List");
  x = new Uint16List(large);
  for (int i = 0; i < 4; i++) {
    x[i] = i;
  }
  replyPort.send(x);

  print("Child Int16List");
  x = new Int16List(large);
  for (int i = 0; i < 4; i++) {
    x[i] = i;
  }
  replyPort.send(x);

  print("Child Uint32List");
  x = new Uint32List(large);
  for (int i = 0; i < 4; i++) {
    x[i] = i;
  }
  replyPort.send(x);

  print("Child Int32List");
  x = new Int32List(large);
  for (int i = 0; i < 4; i++) {
    x[i] = i;
  }
  replyPort.send(x);

  print("Child Uint64List");
  x = new Uint64List(large);
  for (int i = 0; i < 4; i++) {
    x[i] = i;
  }
  replyPort.send(x);

  print("Child Int64List");
  x = new Int64List(large);
  for (int i = 0; i < 4; i++) {
    x[i] = i;
  }
  replyPort.send(x);

  print("Child done");
}

Future<void> main(List<String> args) async {
  print("Parent start");

  ReceivePort port = new ReceivePort();
  Isolate.spawn(child, port.sendPort);
  StreamIterator<dynamic> incoming = new StreamIterator<dynamic>(port);

  print("Parent ByteData");
  Expect.isTrue(await incoming.moveNext());
  dynamic x = incoming.current;
  Expect.isTrue(x is ByteData);
  Expect.equals(large, x.lengthInBytes);
  for (int i = 0; i < 4; i++) {
    Expect.equals(i, x.getUint8(i));
  }

  print("Parent Uint8");
  Expect.isTrue(await incoming.moveNext());
  x = incoming.current;
  Expect.isTrue(x is Uint8List);
  Expect.equals(large, x.length);
  for (int i = 0; i < 4; i++) {
    Expect.equals(i, x[i]);
  }

  print("Parent Int8");
  Expect.isTrue(await incoming.moveNext());
  x = incoming.current;
  Expect.isTrue(x is Int8List);
  Expect.equals(large, x.length);
  for (int i = 0; i < 4; i++) {
    Expect.equals(i, x[i]);
  }

  print("Parent Uint16");
  Expect.isTrue(await incoming.moveNext());
  x = incoming.current;
  Expect.isTrue(x is Uint16List);
  Expect.equals(large, x.length);
  for (int i = 0; i < 4; i++) {
    Expect.equals(i, x[i]);
  }

  print("Parent Int16");
  Expect.isTrue(await incoming.moveNext());
  x = incoming.current;
  Expect.isTrue(x is Int16List);
  Expect.equals(large, x.length);
  for (int i = 0; i < 4; i++) {
    Expect.equals(i, x[i]);
  }

  print("Parent Uint32");
  Expect.isTrue(await incoming.moveNext());
  x = incoming.current;
  Expect.isTrue(x is Uint32List);
  Expect.equals(large, x.length);
  for (int i = 0; i < 4; i++) {
    Expect.equals(i, x[i]);
  }

  print("Parent Int32");
  Expect.isTrue(await incoming.moveNext());
  x = incoming.current;
  Expect.isTrue(x is Int32List);
  Expect.equals(large, x.length);
  for (int i = 0; i < 4; i++) {
    Expect.equals(i, x[i]);
  }

  print("Parent Uint64");
  Expect.isTrue(await incoming.moveNext());
  x = incoming.current;
  Expect.isTrue(x is Uint64List);
  Expect.equals(large, x.length);
  for (int i = 0; i < 4; i++) {
    Expect.equals(i, x[i]);
  }

  print("Parent Int64");
  Expect.isTrue(await incoming.moveNext());
  x = incoming.current;
  Expect.isTrue(x is Int64List);
  Expect.equals(large, x.length);
  for (int i = 0; i < 4; i++) {
    Expect.equals(i, x[i]);
  }

  port.close();
  print("Parent done");
}
