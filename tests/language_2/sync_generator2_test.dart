// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Simple test program for sync* generator functions.

import "package:expect/expect.dart";
import "dart:async";

var sync = "topLevelSync";
var async = "topLevelAync";
var await = "topLevelAwait";
var yield = "topLevelYield";

test01() sync* {
  var yield = 0; // //# 01: compile-time error
  var await = 0; // //# 02: compile-time error
  var async = 0; // //# 03: compile-time error
  bool yield() => false; //# 04: compile-time error
  bool await() => false; //# 05: compile-time error
  bool async() => false; //# 06: compile-time error

  var x1 = sync;
  var x2 = async; // //# 07: compile-time error
  var x3 = await; // //# 08: compile-time error
  var x4 = await 55; // //# 09: compile-time error
  var x4 = yield; // //# 10: compile-time error

  var stream = new Stream.fromIterable([1, 2, 3]);
  await for (var e in stream) print(e); //  //# 11: compile-time error
}

test02() sync* {
  yield 12321;
  return null; // //# 20: compile-time error
}

test03() sync* => null; //  //# 30: compile-time error

get test04 sync* => null; // //# 40: compile-time error
set test04(a) sync* { print(a); } // //# 41: compile-time error

class K {
  K() sync* {}; // //# 50: compile-time error
  get nix sync* {}
  get garnix sync* => null; // //# 51: compile-time error
  set etwas(var z) sync* { } // //# 52: compile-time error
  sync() sync* {
    yield sync; // Yields a tear-off of the sync() method.
  }
}

main() {
  var x;
  x = test01();
  Expect.equals("()", x.toString());
  x = test02();
  test03(); //# 30: continued
  Expect.equals("(12321)", x.toString());
  x = test04; // //# 40: continued
  test04 = x; // //# 41: continued
  x = new K();
  print(x.garnix); //# 51: continued
  x.etwas = null; //# 52: continued
  print(x.sync().toList());
  Expect.equals(1, x.sync().length);
//  Expect.isTrue(x.sync().single is Function);
}
