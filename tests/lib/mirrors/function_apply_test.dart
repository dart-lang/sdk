// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:mirrors";

import "package:expect/expect.dart";

class A {
  call(int x) => 123 + x;
  bar(int y) => 321 + y;
}

int foo(int y) => 456 + y;

void main() {
  // Static function.
  ClosureMirror f1 = reflect(foo) as ClosureMirror;
  Expect.equals(1456, f1.apply([1000]).reflectee);

  // Local declaration.
  int chomp(int z) => z + 42;
  ClosureMirror f2 = reflect(chomp) as ClosureMirror;
  Expect.equals(1042, f2.apply([1000]).reflectee);

  // Local expression.
  ClosureMirror f3 = reflect((u) => u + 987) as ClosureMirror;
  Expect.equals(1987, f3.apply([1000]).reflectee);

  // Instance property extraction.
  ClosureMirror f4 = reflect(A().bar) as ClosureMirror;
  Expect.equals(1321, f4.apply([1000]).reflectee);
}
