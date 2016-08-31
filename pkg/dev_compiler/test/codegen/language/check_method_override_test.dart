// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  f([var x]) {}
  foo(var a, [x, y]) {}
}

class C extends A {
  f() {} /// 01: static type warning
  foo(var a, [x]) {} /// 02: static type warning
}

main() {
  new A().foo(2);
  new C().foo(1);
}