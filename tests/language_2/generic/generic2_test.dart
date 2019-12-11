// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test is-tests with type variables.

import "package:expect/expect.dart";

class A<T> {
  foo(o) => o is T;
}

class B {}

class C extends A<int> {}

main() {
  Expect.isTrue(new A<Object>().foo(new B()));
  Expect.isTrue(new A<Object>().foo(1));
  Expect.isFalse(new A<int>().foo(new Object()));
  Expect.isFalse(new A<int>().foo('hest'));
  Expect.isTrue(new A<B>().foo(new B()));
  Expect.isFalse(new A<B>().foo(new Object()));
  Expect.isFalse(new A<B>().foo(1));
  Expect.isTrue(new C().foo(1));
  Expect.isFalse(new C().foo(new Object()));
  Expect.isFalse(new C().foo('hest'));
  Expect.isTrue(new A<List<int>>().foo(new List<int>()));
  Expect.isFalse(new A<List<int>>().foo(new List<String>()));
}
