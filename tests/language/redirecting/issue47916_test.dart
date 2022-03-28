// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Regression test for issue 47916. The CFE tear-off lowering for A.new
/// called the immediate target B.new (which is also a redirecting factory)
/// instead of the effective target C.new. This caused problem in backends
/// that don't support redirecting factories directly.

abstract class A {
  const factory A() = B;
}

abstract class B implements A {
  const factory B() = C;
}

class C implements B {
  const C();
}

main() {
  A.new;
}
