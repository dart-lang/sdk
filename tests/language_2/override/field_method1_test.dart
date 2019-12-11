// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Overriding field with method.

class A {
  var foo;
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
