// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  f([x]) {}
  foo(a, [x, y]) {}
}

class C extends A {
  f() {}
  // [error column 3, length 1]
  // [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE
  // [cfe] The method 'C.f' has fewer positional arguments than those of overridden method 'A.f'.
  foo(a, [x]) {}
  // [error column 3, length 3]
  // [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE
  // [cfe] The method 'C.foo' has fewer positional arguments than those of overridden method 'A.foo'.
}

main() {
  new A().foo(2);
  new C().foo(1);
}
