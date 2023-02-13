// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:isolate';

import 'package:expect/expect.dart';

main() async {
  final original = List<C>.unmodifiable([C()]);
  final copy = await sendReceive(original);
  Expect.notIdentical(original, copy);

  original[0].field = 1;
  Expect.equals(1, original[0].field);
  Expect.equals(0, copy[0].field);
}

Future<T> sendReceive<T>(T arg) async {
  final rp = ReceivePort();
  rp.sendPort.send(arg);
  return (await rp.first) as T;
}

class C {
  int field = 0;
}
