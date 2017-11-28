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
  Expect.isTrue(new C1<bool>() is Foo, 'new C1<bool>() is Foo');
  Expect.isTrue(new C1<bool>() is Bar, 'new C1<bool>() is Bar');
  Expect.isFalse(new C1<bool>() is Baz, 'new C1<bool>() is Baz');
  Expect.isTrue(new C1<bool>() is Boz, 'new C1<bool>() is Boz');

  Expect.isTrue(new C1<int>() is Foo, 'new C1<int>() is Foo');
  Expect.isTrue(new C1<int>() is Bar, 'new C1<int>() is Bar');
  Expect.isFalse(new C1<int>() is Baz, 'new C1<int>() is Baz');
  Expect.isTrue(new C1<int>() is Boz, 'new C1<int>() is Boz');

  Expect.isTrue(new C1() is Foo, 'new C1() is Foo');
  Expect.isTrue(new C1() is Bar, 'new C1() is Bar');
  Expect.isFalse(new C1() is Baz, 'new C1() is Baz');
  Expect.isTrue(new C1() is Boz, 'new C1() is Boz');

  Expect.isFalse(new C2<bool>() is Foo, 'new C2<bool>() is Foo');
  Expect.isFalse(new C2<bool>() is Bar, 'new C2<bool>() is Bar');
  Expect.isTrue(new C2<bool>() is Baz, 'new C2<bool>() is Baz');
  Expect.isTrue(new C2<bool>() is Boz, 'new C2<bool>() is Boz');

  Expect.isFalse(new C2<int>() is Foo, 'new C2<int>() is Foo');
  Expect.isFalse(new C2<int>() is Bar, 'new C2<int>() is Bar');
  Expect.isTrue(new C2<int>() is Baz, 'new C2<int>() is Baz');
  Expect.isTrue(new C2<int>() is Boz, 'new C2<int>() is Boz');

  Expect.isFalse(new C2() is Foo, 'new C2() is Foo');
  Expect.isFalse(new C2() is Bar, 'new C2() is Bar');
  Expect.isTrue(new C2() is Baz, 'new C2() is Baz');
  Expect.isTrue(new C2() is Boz, 'new C2() is Boz');
}
