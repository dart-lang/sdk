// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class Super<T extends num> {}
class Malbounded1 implements Super
  <String>  //# 00: compile-time error
  {}
class Malbounded2 extends Super
  <String>  //# 01: compile-time error
  {}

main() {
  var m = new Malbounded1();
  Expect.throws(() => m as Super<int>, (e) => e is CastError);
  var s = new Super<int>();
  Expect.throws(() => s as Malbounded1, (e) => e is CastError);
  Expect.throws(() => s as Malbounded2, (e) => e is CastError);
  s as Super
      <String> //# 02: compile-time error
      ;
}
