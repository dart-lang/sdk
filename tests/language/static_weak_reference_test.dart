// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test 'weak-tearoff-reference' pragma.

import "package:expect/expect.dart";

@pragma('weak-tearoff-reference')
Function? weakRef(Function? x) => x;

int used1() => 10;
int used2() => 20;
int unused1() => 30;
int unused2() => 40;

void test(int expectedResult, bool isUsed, Function? ref) {
  print(ref);
  if (isUsed) {
    Expect.isNotNull(ref);
    Expect.equals(expectedResult, ref!());
  } else {
    Expect.isNull(ref);
  }
}

class A {
  int foo1() => used1() + 1;
  Function foo2() => used2;
  int bar1() => unused1() + 1;
  Function bar2() => unused2;
}

main() {
  test(10, true, weakRef(used1));
  test(20, true, weakRef(used2));
  test(30, false, weakRef(unused1));
  test(40, false, weakRef(unused2));

  A a = A();
  a.foo1();
  a.foo2();
}
