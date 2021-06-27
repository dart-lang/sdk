// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests erroneous const constructors with a body which are enabled with const
// functions.

import "package:expect/expect.dart";

const printString = "print";

const var1 = Simple(printString);
class Simple {
  final String name;

  const Simple(this.name) {
    assert(this.name != printString);
  }
}

const var2 = Simple2(printString);
class Simple2 {
  final String name;

  const Simple2(this.name) {
    return Simple2(this.name);
  }
}

const var3 = B();
class A {
  const A() {
    assert(1 == 2);
  }
}

class B extends A {
  const B() : super();
}

const var4 = C();
class C {
  int? x;
}

void main() {}
