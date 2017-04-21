// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Checks that we can correctly typecheck multi-variable declarations on fields
/// and top-levels. This is also a regression test for Issue 27401.

class A {}

A a = new A(), b = new A();

class B {
  A a = new A(), b = new A();
}

main() => [a, b, new B().a, new B().b];
