// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--enable_fast_object_copy=true
// VMOptions=--enable_fast_object_copy=false

import 'dart:io';
import "dart:isolate";
import 'dart:typed_data';

import "package:expect/expect.dart";

main() async {
  final port = ReceivePort();
  await Isolate.spawn(
    runHelper,
    port.sendPort,
  );
  final message = await port.first;

  final weakRef1copy = message[0] as WeakReference<Uint8List>;
  final weakRef2copy = message[1] as WeakReference<Uint8List>;
  final weakRef3copy = message[3] as WeakReference<Uint8List>;
  final weakRef4copy = message[5] as WeakReference<Uint8List>;
  Expect.isNull(weakRef1copy.target);
  Expect.equals(2, weakRef2copy.target?.length);
  Expect.isNull(weakRef3copy.target);
  Expect.equals(4, weakRef4copy.target?.length);

  port.close();
}

Future<void> runHelper(SendPort port) async {
  final object1 = Uint8List(1);
  final weakRef1 = WeakReference(object1);
  final object2 = Uint8List(2);
  final weakRef2 = WeakReference(object2);
  final object3 = Uint8List(3);
  final weakRef3 = WeakReference(object3);
  final object4 = Uint8List(4);
  final weakRef4 = WeakReference(object4);

  final key3 = Object();
  final expando3 = Expando();
  expando3[key3] = object3;
  final key4 = Object();
  final expando4 = Expando();
  expando4[key4] = object4;

  final message = <dynamic>[
    weakRef1, // Does not have its target included.
    weakRef2, // Has its target included later than itself.
    object2,
    weakRef3, // Does not have its target included.
    expando3,
    weakRef4, // Has its target included due to expando.
    expando4,
    key4,
  ];
  port.send(message);
}

class Nonce {
  final int value;

  Nonce(this.value);

  String toString() => 'Nonce($value)';
}
