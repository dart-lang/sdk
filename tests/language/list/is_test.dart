// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A<T> {
  bar() => new List<T>.empty();
}

main() {
  check(new List.empty(), true, false, false);
  check(new List<int>.empty(), true, true, false);
  check(new List<double>.empty(), true, false, true);
  check(new A().bar(), true, false, false);
  check(new A<int>().bar(), true, true, false);
  check(new A<double>().bar(), true, false, true);
  check(new Object(), false, false, false);
}

check(val, expectList, expectListInt, expectListDouble) {
  Expect.equals(expectList, val is List);
  Expect.equals(expectListInt, val is List<int>);
  Expect.equals(expectListDouble, val is List<double>);
}
