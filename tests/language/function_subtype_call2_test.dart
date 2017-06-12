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

class D1<S, T> extends C1<T> {}

class C2<T> {
  void call(T a, {String b}) {}
}

class D2<S, T> extends C2<T> {}

main() {
  Expect.isTrue(new D1<String, bool>() is Foo, 'new D1<String, bool>() is Foo');
  Expect.isTrue(new D1<String, bool>() is Bar, 'new D1<String, bool>() is Bar');
  Expect.isFalse(
      new D1<String, bool>() is Baz, 'new D1<String, bool>() is Baz');
  Expect.isTrue(new D1<String, bool>() is Boz, 'new D1<String, bool>() is Boz');

  Expect.isFalse(new D1<bool, int>() is Foo, 'new D1<bool, int>() is Foo');
  Expect.isFalse(new D1<bool, int>() is Bar, 'new D1<bool, int>() is Bar');
  Expect.isFalse(new D1<bool, int>() is Baz, 'new D1<bool, int>() is Baz');
  Expect.isFalse(new D1<bool, int>() is Boz, 'new D1<bool, int>() is Boz');

  Expect.isTrue(new D1() is Foo, 'new D1() is Foo');
  Expect.isTrue(new D1() is Bar, 'new D1() is Bar');
  Expect.isFalse(new D1() is Baz, 'new D1() is Baz');
  Expect.isTrue(new D1() is Boz, 'new D1() is Boz');

  Expect.isFalse(
      new D2<String, bool>() is Foo, 'new D2<String, bool>() is Foo');
  Expect.isFalse(
      new D2<String, bool>() is Bar, 'new D2<String, bool>() is Bar');
  Expect.isTrue(new D2<String, bool>() is Baz, 'new D2<String, bool>() is Baz');
  Expect.isTrue(new D2<String, bool>() is Boz, 'new D2<String, bool>() is Boz');

  Expect.isFalse(new D2<bool, int>() is Foo, 'new D2<bool, int>() is Foo');
  Expect.isFalse(new D2<bool, int>() is Bar, 'new D2<bool, int>() is Bar');
  Expect.isFalse(new D2<bool, int>() is Baz, 'new D2<bool, int>() is Baz');
  Expect.isFalse(new D2<bool, int>() is Boz, 'new D2<bool, int>() is Boz');

  Expect.isFalse(new D2() is Foo, 'new D2() is Foo');
  Expect.isFalse(new D2() is Bar, 'new D2() is Bar');
  Expect.isTrue(new D2() is Baz, 'new D2() is Baz');
  Expect.isTrue(new D2() is Boz, 'new D2() is Boz');
}
