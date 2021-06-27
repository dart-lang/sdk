// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests const constructors with a body which are enabled with const functions.

import "package:expect/expect.dart";

const printString = "print";
const var1 = Simple(printString);
class Simple {
  final String name;

  const Simple(this.name) {
    assert(this.name == printString);
  }
}

const var2 = A();
class A {
  const A() {
    return;
  }
}

const var3 = fn();
A fn() => A();

void main() {
  Expect.equals(var1.name, printString);
}
