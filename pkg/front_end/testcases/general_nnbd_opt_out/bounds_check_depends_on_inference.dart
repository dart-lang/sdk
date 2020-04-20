// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

// This testcase checks an implementation detail in the bounds checking
// mechanism.  Here String passed into bar should be checked against the bound
// that depends on the result of type inference for expression `B.foo()`.

class A<X> {
  bar<Y extends X>() => null;
}

class B {
  static A<Y> foo<Y extends Object>() => null;
}

baz() {
  B.foo().bar<String>();
}

main() {}
