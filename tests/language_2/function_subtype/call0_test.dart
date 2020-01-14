// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for constructors and initializers.

// Check function subtyping for classes with call functions.

import 'package:expect/expect.dart';

typedef void Foo(bool a, [String b]);
typedef void Bar(bool a, [String b]);
typedef void Baz(bool a, {String b});
typedef void Boz(bool a);

class C1 {
  void call(bool a, [String b]) {}
}

class C2 {
  void call(bool a, {String b}) {}
}

class C3 {
  void call(bool a, {int b}) {}
}

main() {
  Function c1 = new C1(); // implicit tearoff of `call`
  Expect.isTrue(c1 is Foo, 'c1 is Foo');
  Expect.isTrue(c1 is Bar, 'c1 is Bar');
  Expect.isFalse(c1 is Baz, 'c1 is Baz');
  Expect.isTrue(c1 is Boz, 'c1 is Boz');
  Expect.isFalse(c1 is C1, 'c1 is C1');

  Function c2 = new C2(); // implicit tearoff of `call`
  Expect.isFalse(c2 is Foo, 'c2 is Foo');
  Expect.isFalse(c2 is Bar, 'c2 is Bar');
  Expect.isTrue(c2 is Baz, 'c2 is Baz');
  Expect.isTrue(c2 is Boz, 'c2 is Boz');
  Expect.isFalse(c2 is C2, 'c2 is C2');

  Function c3 = new C3(); // implicit tearoff of `call`
  Expect.isFalse(c3 is Foo, 'c3 is Foo');
  Expect.isFalse(c3 is Bar, 'c3 is Bar');
  Expect.isFalse(c3 is Baz, 'c3 is Baz');
  Expect.isTrue(c3 is Boz, 'c3 is Boz');
  Expect.isFalse(c3 is C3, 'c3 is C3');

  expectIsNotFunction(new C1());
  expectIsNotFunction(new C2());
  expectIsNotFunction(new C3());
}

expectIsNotFunction(Object obj) {
  Expect.isFalse(obj is Function, '$obj should not be a Function');
  Expect.isFalse(obj is Foo, '$obj should not be a Foo');
  Expect.isFalse(obj is Bar, '$obj should not be a Bar');
  Expect.isFalse(obj is Baz, '$obj should not be a Baz');
  Expect.isFalse(obj is Boz, '$obj should not be a Boz');
}
