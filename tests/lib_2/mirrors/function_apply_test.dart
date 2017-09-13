// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library lib;

@MirrorsUsed(targets: "lib")
import "dart:mirrors";

import "package:expect/expect.dart";

class A {
  call(int x) => 123 + x;
  bar(int y) => 321 + y;
}

foo(int y) => 456 + y;

main() {
  // Static function.
  ClosureMirror f1 = reflect(foo);
  Expect.equals(1456, f1.apply([1000]).reflectee);

  // Local declaration.
  chomp(int z) => z + 42;
  ClosureMirror f2 = reflect(chomp);
  Expect.equals(1042, f2.apply([1000]).reflectee);

  // Local expression.
  ClosureMirror f3 = reflect((u) => u + 987);
  Expect.equals(1987, f3.apply([1000]).reflectee);

  // Instance property extraction.
  ClosureMirror f4 = reflect(new A().bar);
  Expect.equals(1321, f4.apply([1000]).reflectee);

  // Instance implementing Function via call method.
  ClosureMirror f5 = reflect(new A());
  Expect.equals(1123, f5.apply([1000]).reflectee);
}
