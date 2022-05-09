// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Tests that generic functions are spawned with correct type arguments

// @dart = 2.9

import 'dart:isolate';
import 'package:expect/expect.dart';

void func<T>(T o) {
  print("$o:$T");
  Expect.equals("int", "$T");
}

void call4(dynamic f) {
  f(4);
}

void main() async {
  void Function(int) to = func;
  {
    final rp = ReceivePort();
    Isolate.spawn(to, 3, onExit: rp.sendPort);
    await rp.first;
  }
  {
    final rp = ReceivePort();
    Isolate.spawn(call4, to, onExit: rp.sendPort);
    await rp.first;
  }
}
