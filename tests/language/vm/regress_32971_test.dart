// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(51557): Decide if the mixins being applied in this test should be
// "mixin", "mixin class" or the test should be left at 2.19.
// @dart=2.19

// Test verifying that default switch cast is cloned correctly by the
// mixin transformation.

import "package:expect/expect.dart";

void main() {
  final o = new A();
  Expect.isTrue(o.f());
  Expect.isTrue(o.g());
}

class A extends B with M {}

class B {
  bool f() {
    switch (true) {
      default:
        return true;
    }
    return false;
  }
}

class M {
  bool g() {
    switch (true) {
      default:
        return true;
    }
    return false;
  }
}
