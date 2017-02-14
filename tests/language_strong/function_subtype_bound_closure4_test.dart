// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for constructors and initializers.

// Check function subtyping for generic bound closures.

import 'package:expect/expect.dart';

typedef void Foo(bool a, [String b]);
typedef void Bar(bool a, [String b]);
typedef void Baz(bool a, {String b});
typedef int Boz(bool a);

class C<T> {
  void foo(T a, [String b]) {}
  void baz(T a, {String b}) {}

  void test(String nameOfT, bool expectedResult) {
    Expect.equals(expectedResult, foo is Foo, 'C<$nameOfT>.foo is Foo');
    Expect.equals(expectedResult, foo is Bar, 'C<$nameOfT>.foo is Bar');
    Expect.isFalse(foo is Baz, 'C<$nameOfT>.foo is Baz');
    Expect.isFalse(foo is Boz, 'C<$nameOfT>.foo is Boz');

    Expect.isFalse(baz is Foo, 'C<$nameOfT>.baz is Foo');
    Expect.isFalse(baz is Bar, 'C<$nameOfT>.baz is Bar');
    Expect.equals(expectedResult, baz is Baz, 'C<$nameOfT>.baz is Baz');
    Expect.isFalse(baz is Boz, 'C<$nameOfT>.baz is Boz');
  }
}

class D<S, T> extends C<T> {}

main() {
  new D<String, bool>().test('bool', true);
  new D<bool, int>().test('int', false);
  new D().test('dynamic', true);
}
