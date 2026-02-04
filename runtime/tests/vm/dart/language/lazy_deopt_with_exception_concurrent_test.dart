// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test deoptimization on an optimistically hoisted smi check.
// VMOptions=--optimization-counter-threshold=10  --no-background-compilation

// Test that lazy deoptimization works if the program returns to a function
// that is scheduled for lazy deoptimization via an exception, even under
// heavy concurrent load.

import 'dart:async';
import 'dart:isolate';

import 'package:expect/expect.dart';

class C {
  dynamic x = 42;
}

@pragma('vm:never-inline')
AA(C c, bool b) {
  if (b) {
    c.x = 2.5;
    throw 123;
  }
}

@pragma('vm:never-inline')
T1(C c, bool b) {
  try {
    AA(c, b);
  } on dynamic {}
  return c.x + 1;
}

@pragma('vm:never-inline')
T2(C c, bool b) {
  try {
    AA(c, b);
  } on String {
    Expect.isTrue(false);
  } on int catch (e) {
    Expect.equals(e, 123);
    Expect.equals(b, true);
    Expect.equals(c.x, 2.5);
  }
  return c.x + 1;
}

main() async {
  const count = 10;

  final rp = ReceivePort();
  for (int i = 0; i < count; ++i) {
    Isolate.spawn(entry, i, onExit: rp.sendPort);
  }
  final si = StreamIterator(rp);
  int j = 0;
  while (await si.moveNext()) {
    j++;
    if (j == count) break;
  }
  print('done');

  if (j != count) throw 'a';
  si.cancel();
  rp.close();
  print('done');
}

void entry(_) {
  var c = new C();
  for (var i = 0; i < 100000; ++i) {
    T1(c, false);
    T2(c, false);
  }
  Expect.equals(43, T1(c, false));
  Expect.equals(43, T2(c, false));
  Expect.equals(3.5, T1(c, true));
  Expect.equals(3.5, T2(c, true));
}
