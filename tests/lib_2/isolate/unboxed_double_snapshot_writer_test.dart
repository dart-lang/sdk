// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:expect/expect.dart';

double getDoubleWithHeapObjectTag() {
  final bd = ByteData(8);
  bd.setUint64(0, 0x8000000000000001, Endian.host);
  final double v = bd.getFloat64(0, Endian.host);
  return v;
}

class Foo {
  final double x = getDoubleWithHeapObjectTag();
  final String name = "Foo Class";
  Foo();
}

main(args) async {
  final receivePort = new ReceivePort();

  receivePort.sendPort.send(Foo());
  final it = StreamIterator(receivePort);
  Expect.isTrue(await it.moveNext());
  final Foo receivedFoo = it.current as Foo;
  Expect.equals(receivedFoo.x, getDoubleWithHeapObjectTag());
  Expect.equals(receivedFoo.name, "Foo Class");
  await it.cancel();
}
