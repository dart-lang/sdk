// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

import 'package:expect/expect.dart';
import 'dart:isolate';

funcFoo(x) => x + 2;

foo() {
  stream.single.then((msg) {
    IsolateSink sink = msg;
    sink.add(499);
    sink.close();
  });
}

main() {
  var box = new MessageBox();
  var snd = streamSpawnFunction(foo);
  var caught_exception = false;
  try {
    snd.add(funcFoo);
  } catch (e) {
    caught_exception = true;
  }
  snd.add(box.sink);
  snd.close();

  box.stream.single.then((msg) {
    Expect.equals(499, msg);
  });
}
