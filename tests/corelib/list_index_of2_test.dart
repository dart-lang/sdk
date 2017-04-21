// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  const A();
}

class B extends A {
  const B();
}

void test(List<B> list) {
  // Test that the list accepts a different type for indexOf.
  //   List<B>.indexOf(A)
  Expect.equals(-1, list.indexOf(const A()));
  Expect.equals(-1, list.lastIndexOf(const A()));
}

main() {
  var list = new List<B>(1);
  list[0] = const B();
  test(list);
  var list2 = new List<B>();
  list2.add(const B());
  test(list2);
  test(<B>[const B()]);
  test(const <B>[]);
  test(<B>[const B()].toList());
}
