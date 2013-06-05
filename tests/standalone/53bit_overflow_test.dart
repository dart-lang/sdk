// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--throw_on_javascript_int_overflow


import "package:expect/expect.dart";
import 'dart:typed_data';


int double_to_int_throws() {
  double d = 1.9e16;
  return d.toInt();
}


int integer_add_throws() {
  return (1 << 52) + (1 << 52);
}


int i64list_throws() {
  var i64l = new Int64List(16);
  i64l[0] = (1 << 54);
  return i64l[0];
}


int double_to_int() {
  double d = 1.9e14;
  return d.toInt();
}


int integer_add() {
  return (1 << 50) + (1 << 50);
}


main() {
  Expect.throws(double_to_int_throws, (e) => e is FiftyThreeBitOverflowError);
  Expect.throws(integer_add_throws, (e) => e is FiftyThreeBitOverflowError);
  Expect.throws(i64list_throws, (e) => e is FiftyThreeBitOverflowError);
  Expect.equals(190000000000000, double_to_int());
  Expect.equals(1 << 51, integer_add());
}
