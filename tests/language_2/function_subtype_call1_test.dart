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

class C1<T> {
  void call(T a, [String b]) {}
}

class C2<T> {
  void call(T a, {String b}) {}
}

main() {
  Function c1_bool = new C1<bool>(); // implicit tearoff of `call`
  Expect.isTrue(c1_bool is Foo, 'c1_bool is Foo');
  Expect.isTrue(c1_bool is Bar, 'c1_bool is Bar');
  Expect.isFalse(c1_bool is Baz, 'c1_bool is Baz');
  Expect.isTrue(c1_bool is Boz, 'c1_bool is Boz');

  Function c1_int = new C1<int>(); // implicit tearoff of `call`
  Expect.isTrue(c1_int is Foo, 'c1_int is Foo');
  Expect.isTrue(c1_int is Bar, 'c1_int is Bar');
  Expect.isFalse(c1_int is Baz, 'c1_int is Baz');
  Expect.isTrue(c1_int is Boz, 'c1_int is Boz');

  Function c1 = new C1(); // implicit tearoff of `call`
  Expect.isTrue(c1 is Foo, 'c1 is Foo');
  Expect.isTrue(c1 is Bar, 'c1 is Bar');
  Expect.isFalse(c1 is Baz, 'c1 is Baz');
  Expect.isTrue(c1 is Boz, 'c1 is Boz');

  Function c2_bool = new C2<bool>(); // implicit tearoff of `call`
  Expect.isFalse(c2_bool is Foo, 'c2_bool is Foo');
  Expect.isFalse(c2_bool is Bar, 'c2_bool is Bar');
  Expect.isTrue(c2_bool is Baz, 'c2_bool is Baz');
  Expect.isTrue(c2_bool is Boz, 'c2_bool is Boz');

  Function c2_int = new C2<int>(); // implicit tearoff of `call`
  Expect.isFalse(c2_int is Foo, 'c2_int is Foo');
  Expect.isFalse(c2_int is Bar, 'c2_int is Bar');
  Expect.isTrue(c2_int is Baz, 'c2_int is Baz');
  Expect.isTrue(c2_int is Boz, 'c2_int is Boz');

  Function c2 = new C2(); // implicit tearoff of `call`
  Expect.isFalse(c2 is Foo, 'c2 is Foo');
  Expect.isFalse(c2 is Bar, 'c2 is Bar');
  Expect.isTrue(c2 is Baz, 'c2 is Baz');
  Expect.isTrue(c2 is Boz, 'c2 is Boz');
}
