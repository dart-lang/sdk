// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A<T> {
  bar() => new List<T>();
}

main() {
  check(new List(), true, true, true);
  check(new List<int>(), true, true, false);
  check(new A().bar(), true, true, true);
  check(new A<double>().bar(), true, false, true);
  check(new Object(), false, false, false);
}

check(val, expectList, expectListInt, expectListDouble) {
  Expect.equals(expectList, val is List);
  Expect.equals(expectListInt, val is List<int>);
  Expect.equals(expectListDouble, val is List<double>);
}
