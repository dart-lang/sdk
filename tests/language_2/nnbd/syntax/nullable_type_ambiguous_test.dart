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
  Expect.isTrue(x1 is Set<dynamic>);
  Set<dynamic> y1 = x1;

  // { a is int ? -3 : 3 } is parsed as a set literal { (a is int) ? -3 : 3 }.
  a = 0;
  var x2 = {a is int ? -3 : 3};
  Expect.isTrue(x2 is Set<dynamic>);
  Set<dynamic> y2 = x2;

  // { a * int ? -3 : 3 } is parsed as a set literal { (a * int) ? -3 : 3 }.
  a = C();
  var x3 = {a * int ? -3 : 3};
  Expect.isTrue(x3 is Set<dynamic>);
  Set<dynamic> y3 = x3;
}
