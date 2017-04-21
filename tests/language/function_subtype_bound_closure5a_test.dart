// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for constructors and initializers.

// Check function subtyping for bound closures on generic type against generic
// typedefs.

import 'package:expect/expect.dart';

typedef int Foo<T>(T a, [String b]);
typedef int Bar<T>(T a, [String b]);
typedef int Baz<T>(T a, {String b});
typedef int Boz<T>(T a);
typedef int Biz<T>(T a, int b);

class C<T> {
  int foo(bool a, [String b]) => null;
  int baz(bool a, {String b}) => null;

  void test(String nameOfT, bool expectedResult) {
    Expect.equals(expectedResult, foo is Foo<T>, 'foo is Foo<$nameOfT>');
    Expect.equals(expectedResult, foo is Bar<T>, 'foo is Bar<$nameOfT>');
    Expect.isFalse(foo is Baz<T>, 'foo is Baz<$nameOfT>');
    Expect.equals(expectedResult, foo is Boz<T>, 'foo is Boz<$nameOfT>');
    Expect.isFalse(foo is Biz<T>, 'foo is Biz<$nameOfT>');

    Expect.isFalse(baz is Foo<T>, 'baz is Foo<$nameOfT>');
    Expect.isFalse(baz is Bar<T>, 'baz is Bar<$nameOfT>');
    Expect.equals(expectedResult, baz is Baz<T>, 'baz is Baz<$nameOfT>');
    Expect.equals(expectedResult, baz is Boz<T>, 'baz is Boz<$nameOfT>');
    Expect.isFalse(baz is Biz<T>, 'bar is Biz<$nameOfT>');
  }
}

class Cm<T> extends C<T> {}

class D<S, T> extends Cm<T> {}

main() {
  new D<String, bool>().test('bool', true);
  new D<bool, int>().test('int', false);
  new D().test('dynamic', true);
}
