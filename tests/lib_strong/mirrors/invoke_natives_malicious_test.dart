// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.invoke_natives;

import 'dart:mirrors';
import 'package:expect/expect.dart';

test(name, action) {
  print(name);
  Expect.throws(action, (e) => true, name);
  print("done");
}

main() {
  LibraryMirror dartcore = reflectClass(Object).owner;

  test('List_copyFromObjectArray', () {
    var receiver = new List(3);
    var selector = MirrorSystem.getSymbol('_copyFromObjectArray', dartcore);
    var src = new List(3);
    var srcStart = 10;
    var dstStart = 10;
    var count = 10;
    reflect(receiver).invoke(selector, [src, srcStart, dstStart, count]);
  });
}
