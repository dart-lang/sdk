// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for VM's IfConverted pass not keeping graph structure and
// use lists in sync.

// VMOptions=--optimization-counter-threshold=10 --no-background-compilation

class A {
  int x;
}

f() {
  var a = new A();
  a.x = (true ? 2 : 4);
  return a.x;
}

main() {
  for (var i = 0; i < 20; i++) f();
}
