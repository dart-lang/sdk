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

main() {
  new C<bool>().test('bool', true);
  new C<int>().test('int', false);
  new C().test('dynamic', true);
}
