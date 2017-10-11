// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A<T> {
  const A();
  toString() => "a";
}

const a = const A<int>();
const b = const A<double>();

const list1 = const <int>[1, 2];
const list2 = const [1, 2];
main() {
  Expect.isFalse(identical(a, b));
  Expect.isFalse(identical(list1, list2));
}
