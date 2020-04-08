// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that we are accessing the right field in a method of a super
// class, when that field is overridden.

import "package:expect/expect.dart";

class A {
  final a = [42]; /*@compile-error=unspecified*/
  foo() => a[0];
}

class B extends A {
  final a = new Map();
}

main() {
  Expect.equals(null, new B().foo());
  Expect.equals(42, new A().foo());
}
