// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(51557): Decide if the mixins being applied in this test should be
// "mixin", "mixin class" or the test should be left at 2.19.
// @dart=2.19

class B {}

class C {}

class D {}

class E extends B with C implements D {}

class F extends E {}

// M is mixed onto E which implements B, C and D.
mixin M //
  on B //# 01: ok
  on C //# 02: ok
  on D //# 03: ok
  on E //# 04: ok
  on F //# 05: compile-time error
{}

class A = E with M;

main() {
  new A();
}
