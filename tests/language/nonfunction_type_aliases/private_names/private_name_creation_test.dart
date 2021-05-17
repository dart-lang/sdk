// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// Test that private names exported via public typedefs allow creation.

import "package:expect/expect.dart";

import "private_name_library.dart";

void test1() {
  // Test that a private class can be created via an exported public name using
  // an unnamed constructor.
  var p = PublicClass();
  Expect.equals(privateLibrarySentinel, p.x);
  Expect.equals(privateLibrarySentinel, p.instanceMethod());
  Expect.equals(privateLibrarySentinel, callPrivateInstanceMethod(p));
}

void test2() {
  // Test that a private class can be created via an exported public name using
  // a named constructor.
  var p = AlsoPublicClass.named(1);
  Expect.equals(1, p.x);
  Expect.equals(privateLibrarySentinel, p.instanceMethod());
  Expect.equals(privateLibrarySentinel, callPrivateInstanceMethod(p));
}

void test3() {
  // Test that a private class can be created as const via an exported public
  // name.
  const c1 = PublicClass();
  const c2 = AlsoPublicClass();
  Expect.identical(c1, c2);
}

void main() {
  test1();
  test2();
  test3();
}
