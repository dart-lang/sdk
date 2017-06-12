// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart2js produced a statement in an expression context for this test.

class A {
  var foo = "foo";
  bar(x) {
    if (foo == 3) return;
    var t = x;
    if (x == 0) t = foo;
    foo = t;
  }

  toto(x) => x;
  titi() {
    foo = 0;
    for (int i = 0; i < 3; i++) bar(i);
  }
}

main() => new A().titi();
