// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=non-nullable
import 'package:expect/expect.dart';

class C {
  bool operator *(Type t) => true;
}

main() {
  // { a as bool ? - 3 : 3 } is parsed as a set literal { (a as bool) ? - 3 : 3 }.
  dynamic a = true;
  var x1 = {a as bool ? -3 : 3};
  Expect.type<Set<dynamic>>(x1);
  Set<dynamic> y1 = x1;

  // { a is int ? -3 : 3 } is parsed as a set literal { (a is int) ? -3 : 3 }.
  a = 0;
  var x2 = {a is int ? -3 : 3};
  Expect.type<Set<dynamic>>(x2);
  Set<dynamic> y2 = x2;

  // { a * int ? -3 : 3 } is parsed as a set literal { (a * int) ? -3 : 3 }.
  a = C();
  var x3 = {a * int ? -3 : 3};
  Expect.type<Set<dynamic>>(x3);
  Set<dynamic> y3 = x3;

  // { a is bool ? ? - 3 : 3 } is parsed as a set literal { (a is bool?) ? - 3 : 3 }.
  a = true;
  var x4 = {a is bool ? ? -3 : 3};
  Expect.type<Set<dynamic>>(x4);
  Set<dynamic> y4 = x4;

  // { a is bool ?? true : 3 } is parsed as a map literal { ((a is bool) ?? true) : 3 }.
  a = true;
  var x5 = {a is bool ?? true : 3};
  //          ^
  // [cfe] Operand of null-aware operation '??' has type 'bool' which excludes null.
  //                     ^^^^
  // [analyzer] STATIC_WARNING.DEAD_NULL_AWARE_EXPRESSION
  Expect.type<Map<dynamic, dynamic>>(x5);
  Map<dynamic, dynamic> y5 = x5;
}
