// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test optimization of modulo operator on Smi.
// VMOptions=--optimization-counter-threshold=10 --no-use-osr

import "package:expect/expect.dart";


main() {
  // Prime IC cache.
  noDom(1);
  noDom(-1);
  for (int i = -30; i < 30; i++) {
    Expect.equals(i % 256, foo(i));
    Expect.equals(i % -256, boo(i));
    Expect.throws(() => hoo(i), (e) => e is IntegerDivisionByZeroException);
    
    Expect.equals(i ~/ 254 + i % 254, fooTwo(i));
    Expect.equals(i ~/ -254 + i % -254, booTwo(i));
    Expect.throws(() => hooTwo(i), (e) => e is IntegerDivisionByZeroException);
    if (i > 0) {
      Expect.equals(i % 10, noDom(i));
    } else {
      Expect.equals(i ~/ 10, noDom(i));
    }
    Expect.equals((i ~/ 10) + (i ~/ 10) + (i % 10), threeOp(i));
    Expect.equals((i ~/ 10) + (i ~/ 12) + (i % 10) + (i % 12), fourOp(i));
  }
}

foo(i) => i % 256;  // This will get optimized to AND instruction.
boo(i) => i % -256;
hoo(i) => i % 0;

fooTwo(i) => i ~/ 254 + i % 254;
booTwo(i) => i ~/ -254 + i % -254;
hooTwo(i) => i ~/ 0 + i % 0;

noDom(a) {
  var x;
  if (a > 0) {
    x = a % 10;
  } else {
    x = a ~/ 10;
  }
  return x;
}

threeOp(a) {
  var x = a ~/ 10;
  var y = a ~/ 10;
  var z = a % 10;
  return x + y + z;
}


fourOp(a) {
  var x0 = a ~/ 10;
  var x1 = a ~/ 12;
  var y0 = a % 10; 
  var y1 = a % 12;
  return x0 + x1 + y0 + y1;
}