// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Overriding getter with method.

class A {
  get foo => 123;
}

class B extends A {
  foo() {}
//^^^
// [analyzer] COMPILE_TIME_ERROR.CONFLICTING_METHOD_AND_FIELD
// [cfe] Can't declare a member that conflicts with an inherited one.
}

main() {
  B().foo();
}
