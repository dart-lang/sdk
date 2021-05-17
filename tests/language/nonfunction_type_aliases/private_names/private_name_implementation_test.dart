// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// Test that private names exported via public typedefs allow implementation

import "package:expect/expect.dart";

import "private_name_library.dart";

class Derived implements PublicClass {
  int x;
  Derived(this.x);
  int instanceMethod() => publicLibrarySentinel;
  int _privateInstanceMethod() => publicLibrarySentinel;
}

void test1() {
  PublicClass _ = Derived(publicLibrarySentinel);
  var p = Derived(publicLibrarySentinel);
  Expect.equals(publicLibrarySentinel, p.instanceMethod());
  // Calling the private instance method from this library should succeed.
  Expect.equals(publicLibrarySentinel, p._privateInstanceMethod());
  // Calling the private instance method from the other library should fail.
  Expect.throwsNoSuchMethodError(() => callPrivateInstanceMethod(p));
}

void main() {
  test1();
}
