// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=nonfunction-type-aliases

// Test that private names exported via public typedefs allow extension.

import "package:expect/expect.dart";

import "private_name_library.dart";

class Derived extends PublicClass {
  Derived() : super(0);
}

class AlsoDerived extends AlsoPublicClass {
  AlsoDerived() : super.named(0);
  int instanceMethod() => 0;
  int _privateInstanceMethod() => 0;
}

/// Test that inherited methods work correctly.
void test1() {
  {
    PublicClass p = Derived();
    Expect.equals(3, p.instanceMethod());
    Expect.throwsNoSuchMethodError(() => (p as dynamic)._privateInstanceMethod());
  }
}

/// Test that inherited methods work correctly.
void test2() {
  {
    var p = AlsoDerived();
    Expect.equals(0, p.instanceMethod());
    Expect.equals(0, p._privateInstanceMethod());
    Expect.equals(0, (p as dynamic)._privateInstanceMethod());
  }
}

void main() {
  test1();
  test2();
}
