// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  f([var x]) {}
  foo(var a, [x, y]) {}
}

class C extends A {
  f() {}
//^
// [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE
// [cfe] The method 'C.f' has fewer positional arguments than those of overridden method 'A.f'.
  foo(var a, [x]) {}
//^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE
// [cfe] The method 'C.foo' has fewer positional arguments than those of overridden method 'A.foo'.
}

main() {
  new A().foo(2);
  new C().foo(1);
}
